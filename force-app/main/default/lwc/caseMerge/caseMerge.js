import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import searchCases from '@salesforce/apex/CaseMergeController.searchCases';
import getCaseDetails from '@salesforce/apex/CaseMergeController.getCaseDetails';
import mergeCases from '@salesforce/apex/CaseMergeController.mergeCases';

// Datatable columns for search results
const SEARCH_COLUMNS = [
    {
        label: 'Case Number',
        fieldName: 'caseUrl',
        type: 'url',
        typeAttributes: { label: { fieldName: 'caseNumber' }, target: '_blank' }
    },
    { label: 'Subject', fieldName: 'subject', type: 'text' },
    { label: 'Status', fieldName: 'status', type: 'text' },
    { label: 'Priority', fieldName: 'priority', type: 'text' },
    { label: 'Contact', fieldName: 'contactName', type: 'text' },
    { label: 'Account', fieldName: 'accountName', type: 'text' },
    {
        label: 'Created',
        fieldName: 'createdDate',
        type: 'date',
        typeAttributes: {
            year: 'numeric',
            month: 'short',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit'
        }
    }
];

export default class CaseMerge extends NavigationMixin(LightningElement) {
    @api recordId;

    // Step management
    @track currentStep = '1';

    // Step 1: Search & Select
    searchTerm = '';
    @track searchResults = [];
    @track selectedCases = []; // Array of { caseId, caseNumber, subject, pillLabel }
    isSearching = false;
    searchPerformed = false;
    _debounceTimer;

    // Auto-select record when opened as Quick Action
    async connectedCallback() {
        if (this.recordId) {
            try {
                const details = await getCaseDetails({ caseIds: [this.recordId] });
                if (details && details.length > 0) {
                    const c = details[0];
                    this.selectedCases = [{
                        caseId: c.caseId,
                        caseNumber: c.caseNumber,
                        subject: c.subject,
                        pillLabel: c.caseNumber + ' — ' + (c.subject || 'No Subject')
                    }];
                }
            } catch (error) {
                console.error('Error loading initial case:', error);
            }
        }
    }

    // Step 2: Choose Master
    @track caseDetails = [];
    masterCaseId = null;
    isLoadingDetails = false;

    // Step 3 & Merge
    isMerging = false;
    mergeComplete = false;
    mergeResultMessage = '';
    mergeResultMasterCaseId = null;
    mergeResultTotalMerged = 0;

    // Columns
    get searchColumns() {
        return SEARCH_COLUMNS;
    }

    // ====== Step Visibility Getters ======

    get isStep1() {
        return this.currentStep === '1' && !this.mergeComplete;
    }
    get isStep2() {
        return this.currentStep === '2' && !this.mergeComplete;
    }
    get isStep3() {
        return this.currentStep === '3' && !this.mergeComplete;
    }

    // ====== Step 1 Getters ======

    get hasSearchResults() {
        return this.searchResults.length > 0 && !this.isSearching;
    }

    get noResults() {
        return this.searchResults.length === 0 && this.searchPerformed && !this.isSearching;
    }

    get hasSelectedCases() {
        return this.selectedCases.length > 0;
    }

    get selectedCaseCount() {
        return this.selectedCases.length;
    }

    get selectedCaseIds() {
        return this.selectedCases.map((c) => c.caseId);
    }

    get isNextDisabled() {
        return this.selectedCases.length < 2;
    }

    // ====== Step 2 Getters ======

    get isMasterNotSelected() {
        return !this.masterCaseId;
    }

    // ====== Step 3 Getters ======

    get masterCaseDetail() {
        return this.caseDetails.find((d) => d.caseId === this.masterCaseId) || {};
    }

    get duplicateCaseDetails() {
        return this.caseDetails
            .filter((d) => d.caseId !== this.masterCaseId)
            .map((d) => ({
                ...d,
                totalRelated:
                    d.commentCount + d.emailCount + d.taskCount + d.attachmentCount + d.childCaseCount
            }));
    }

    get duplicateCaseCount() {
        return this.duplicateCaseDetails.length;
    }

    get totalComments() {
        return this._sumField('commentCount');
    }
    get totalEmails() {
        return this._sumField('emailCount');
    }
    get totalTasks() {
        return this._sumField('taskCount');
    }
    get totalAttachments() {
        return this._sumField('attachmentCount');
    }
    get totalChildCases() {
        return this._sumField('childCaseCount');
    }

    // ====== Search Handler ======

    handleSearchChange(event) {
        const value = event.target.value;
        this.searchTerm = value;

        // Debounce search
        clearTimeout(this._debounceTimer);
        if (value && value.length >= 2) {
            this._debounceTimer = setTimeout(() => {
                this._performSearch();
            }, 300);
        } else {
            this.searchResults = [];
            this.searchPerformed = false;
        }
    }

    async _performSearch() {
        this.isSearching = true;
        this.searchPerformed = true;
        try {
            const results = await searchCases({ searchTerm: this.searchTerm });
            this.searchResults = results.map((c) => ({
                ...c,
                caseUrl: '/' + c.caseId
            }));
        } catch (error) {
            this._showToast('Error', this._reduceErrors(error), 'error');
            this.searchResults = [];
        } finally {
            this.isSearching = false;
        }
    }

    // ====== Row Selection ======

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;

        // Build a map of currently selected cases for fast lookup
        const existingMap = new Map(this.selectedCases.map((c) => [c.caseId, c]));

        // Add newly selected rows
        selectedRows.forEach((row) => {
            if (!existingMap.has(row.caseId)) {
                existingMap.set(row.caseId, {
                    caseId: row.caseId,
                    caseNumber: row.caseNumber,
                    subject: row.subject,
                    pillLabel: row.caseNumber + ' — ' + (row.subject || 'No Subject')
                });
            }
        });

        // Get set of IDs from current search results
        const searchResultIds = new Set(this.searchResults.map((r) => r.caseId));

        // Get set of IDs that are currently selected in the datatable
        const selectedRowIds = new Set(selectedRows.map((r) => r.caseId));

        // Remove cases that are in current search results but were deselected
        const updatedCases = [];
        existingMap.forEach((caseObj, caseId) => {
            if (searchResultIds.has(caseId) && !selectedRowIds.has(caseId)) {
                // This case is visible in search results but not selected — remove it
                return;
            }
            updatedCases.push(caseObj);
        });

        this.selectedCases = updatedCases;
    }

    handleRemoveCase(event) {
        const caseIdToRemove = event.currentTarget.dataset.id;
        this.selectedCases = this.selectedCases.filter((c) => c.caseId !== caseIdToRemove);
    }

    // ====== Master Case Selection ======

    handleMasterSelection(event) {
        const caseId = event.currentTarget.dataset.id;
        this.masterCaseId = caseId;
        this._updateCaseCardClasses();
    }

    _updateCaseCardClasses() {
        this.caseDetails = this.caseDetails.map((d) => ({
            ...d,
            isMaster: d.caseId === this.masterCaseId,
            cardClass: d.caseId === this.masterCaseId ? 'case-card-selected' : 'case-card'
        }));
    }

    // ====== Navigation ======

    async handleNext() {
        if (this.currentStep === '1') {
            if (this.selectedCases.length < 2) {
                this._showToast('Warning', 'Please select at least 2 cases to merge.', 'warning');
                return;
            }
            // Move to step 2 and load details
            this.currentStep = '2';
            await this._loadCaseDetails();
        } else if (this.currentStep === '2') {
            if (!this.masterCaseId) {
                this._showToast('Warning', 'Please select a master case.', 'warning');
                return;
            }
            this.currentStep = '3';
        }
    }

    handleBack() {
        if (this.currentStep === '2') {
            this.currentStep = '1';
        } else if (this.currentStep === '3') {
            this.currentStep = '2';
        }
    }

    // ====== Load Case Details (Step 2) ======

    async _loadCaseDetails() {
        this.isLoadingDetails = true;
        try {
            const ids = this.selectedCases.map((c) => c.caseId);
            const details = await getCaseDetails({ caseIds: ids });
            this.caseDetails = details.map((d) => ({
                ...d,
                isMaster: d.caseId === this.masterCaseId,
                cardClass: d.caseId === this.masterCaseId ? 'case-card-selected' : 'case-card',
                commentLabel: d.commentCount + ' Comments',
                emailLabel: d.emailCount + ' Emails',
                taskLabel: d.taskCount + ' Tasks',
                attachmentLabel: d.attachmentCount + ' Files',
                childCaseLabel: d.childCaseCount + ' Child Cases'
            }));
        } catch (error) {
            this._showToast('Error', this._reduceErrors(error), 'error');
        } finally {
            this.isLoadingDetails = false;
        }
    }

    // ====== Merge Execution ======

    async handleMerge() {
        this.isMerging = true;
        try {
            const duplicateIds = this.selectedCases
                .map((c) => c.caseId)
                .filter((id) => id !== this.masterCaseId);

            const result = await mergeCases({
                masterCaseId: this.masterCaseId,
                duplicateCaseIds: duplicateIds
            });

            if (result.success) {
                this.mergeComplete = true;
                this.mergeResultMessage = result.message;
                this.mergeResultMasterCaseId = result.masterCaseId;
                this.mergeResultTotalMerged = result.totalMerged;
                this._showToast('Success', result.message, 'success');
            } else {
                this._showToast('Error', result.message, 'error');
            }
        } catch (error) {
            this._showToast('Error', this._reduceErrors(error), 'error');
        } finally {
            this.isMerging = false;
        }
    }

    // ====== Post-Merge Actions ======

    handleNavigateToMaster() {
        // Close quick action modal first if open
        this.dispatchEvent(new CloseActionScreenEvent());
        
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.mergeResultMasterCaseId,
                objectApiName: 'Case',
                actionName: 'view'
            }
        });
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleReset() {
        this.currentStep = '1';
        this.searchTerm = '';
        this.searchResults = [];
        this.selectedCases = [];
        this.searchPerformed = false;
        this.caseDetails = [];
        this.masterCaseId = null;
        this.mergeComplete = false;
        this.mergeResultMessage = '';
        this.mergeResultMasterCaseId = null;
        this.mergeResultTotalMerged = 0;
        
        // Auto-repopulate if we are inside a quick action
        if (this.recordId) {
            this.connectedCallback();
        }
    }

    // ====== Helpers ======

    _sumField(fieldName) {
        return this.caseDetails
            .filter((d) => d.caseId !== this.masterCaseId)
            .reduce((sum, d) => sum + (d[fieldName] || 0), 0);
    }

    _showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }

    _reduceErrors(error) {
        if (typeof error === 'string') {
            return error;
        }
        if (error?.body?.message) {
            return error.body.message;
        }
        if (error?.message) {
            return error.message;
        }
        if (Array.isArray(error?.body)) {
            return error.body.map((e) => e.message).join(', ');
        }
        return 'An unknown error occurred.';
    }
}
