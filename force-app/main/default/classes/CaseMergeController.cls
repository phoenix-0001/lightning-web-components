public with sharing class CaseMergeController {

    // Lightweight wrapper for case search results
    public class CaseSearchResult {
        @AuraEnabled public Id caseId;
        @AuraEnabled public String caseNumber;
        @AuraEnabled public String subject;
        @AuraEnabled public String status;
        @AuraEnabled public String priority;
        @AuraEnabled public String contactName;
        @AuraEnabled public String accountName;
        @AuraEnabled public Datetime createdDate;

        public CaseSearchResult(Case c) {
            this.caseId = c.Id;
            this.caseNumber = c.CaseNumber;
            this.subject = c.Subject;
            this.status = c.Status;
            this.priority = c.Priority;
            this.contactName = c.Contact != null ? c.Contact.Name : '';
            this.accountName = c.Account != null ? c.Account.Name : '';
            this.createdDate = c.CreatedDate;
        }
    }

    // Detailed wrapper including related record counts
    public class CaseDetail {
        @AuraEnabled public Id caseId;
        @AuraEnabled public String caseNumber;
        @AuraEnabled public String subject;
        @AuraEnabled public String status;
        @AuraEnabled public String priority;
        @AuraEnabled public String contactName;
        @AuraEnabled public String accountName;
        @AuraEnabled public String description;
        @AuraEnabled public Datetime createdDate;
        @AuraEnabled public Integer commentCount;
        @AuraEnabled public Integer emailCount;
        @AuraEnabled public Integer taskCount;
        @AuraEnabled public Integer attachmentCount;
        @AuraEnabled public Integer childCaseCount;

        public CaseDetail(Case c, Integer comments, Integer emails,
                          Integer tasks, Integer attachments, Integer childCases) {
            this.caseId = c.Id;
            this.caseNumber = c.CaseNumber;
            this.subject = c.Subject;
            this.status = c.Status;
            this.priority = c.Priority;
            this.contactName = c.Contact != null ? c.Contact.Name : '';
            this.accountName = c.Account != null ? c.Account.Name : '';
            this.description = c.Description;
            this.createdDate = c.CreatedDate;
            this.commentCount = comments;
            this.emailCount = emails;
            this.taskCount = tasks;
            this.attachmentCount = attachments;
            this.childCaseCount = childCases;
        }
    }

    // Result wrapper for merge operation
    public class MergeResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public Id masterCaseId;
        @AuraEnabled public Integer totalMerged;

        public MergeResult(Boolean success, String message, Id masterCaseId, Integer totalMerged) {
            this.success = success;
            this.message = message;
            this.masterCaseId = masterCaseId;
            this.totalMerged = totalMerged;
        }
    }

    /**
     * Search cases by Case Number, Subject, or Contact Name.
     * Returns up to 50 results.
     */
    @AuraEnabled(cacheable=true)
    public static List<CaseSearchResult> searchCases(String searchTerm) {
        if (String.isBlank(searchTerm) || searchTerm.length() < 2) {
            return new List<CaseSearchResult>();
        }

        String likeFilter = '%' + String.escapeSingleQuotes(searchTerm) + '%';
        List<Case> cases = [
            SELECT Id, CaseNumber, Subject, Status, Priority,
                   Contact.Name, Account.Name, CreatedDate
            FROM Case
            WHERE CaseNumber LIKE :likeFilter
               OR Subject LIKE :likeFilter
               OR Contact.Name LIKE :likeFilter
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];

        List<CaseSearchResult> results = new List<CaseSearchResult>();
        for (Case c : cases) {
            results.add(new CaseSearchResult(c));
        }
        return results;
    }

    /**
     * Retrieve detailed case information with related record counts.
     */
    @AuraEnabled
    public static List<CaseDetail> getCaseDetails(List<Id> caseIds) {
        if (caseIds == null || caseIds.isEmpty()) {
            return new List<CaseDetail>();
        }

        // Fetch case records
        Map<Id, Case> caseMap = new Map<Id, Case>([
            SELECT Id, CaseNumber, Subject, Status, Priority,
                   Contact.Name, Account.Name, Description, CreatedDate
            FROM Case
            WHERE Id IN :caseIds
        ]);

        // Count CaseComments
        Map<Id, Integer> commentCounts = countChildRecords(
            'CaseComment', 'ParentId', caseIds
        );

        // Count EmailMessages
        Map<Id, Integer> emailCounts = countChildRecords(
            'EmailMessage', 'ParentId', caseIds
        );

        // Count Tasks
        Map<Id, Integer> taskCounts = countChildRecords(
            'Task', 'WhatId', caseIds
        );

        // Count ContentDocumentLinks (attachments/files)
        Map<Id, Integer> attachmentCounts = countChildRecords(
            'ContentDocumentLink', 'LinkedEntityId', caseIds
        );

        // Count child Cases
        Map<Id, Integer> childCaseCounts = countChildRecords(
            'Case', 'ParentId', caseIds
        );

        List<CaseDetail> details = new List<CaseDetail>();
        for (Id caseId : caseIds) {
            Case c = caseMap.get(caseId);
            if (c != null) {
                details.add(new CaseDetail(
                    c,
                    commentCounts.containsKey(caseId) ? commentCounts.get(caseId) : 0,
                    emailCounts.containsKey(caseId) ? emailCounts.get(caseId) : 0,
                    taskCounts.containsKey(caseId) ? taskCounts.get(caseId) : 0,
                    attachmentCounts.containsKey(caseId) ? attachmentCounts.get(caseId) : 0,
                    childCaseCounts.containsKey(caseId) ? childCaseCounts.get(caseId) : 0
                ));
            }
        }
        return details;
    }

    /**
     * Merge multiple cases into a master case by manually reparenting all child
     * records and closing the duplicate cases.
     *
     * Unlike the Apex merge keyword (which deletes duplicates), this method
     * preserves duplicate cases for audit trail by:
     * - Setting Status to 'Closed'
     * - Prepending 'Merged - ' to the Subject
     * - Adding a hyperlink to the master case in the Description
     *
     * This approach also bypasses the 3-record merge limit since it does not
     * use the merge DML statement.
     */
    @AuraEnabled
    public static MergeResult mergeCases(Id masterCaseId, List<Id> duplicateCaseIds) {
        // Validate inputs
        if (masterCaseId == null) {
            return new MergeResult(false, 'Master Case ID is required.', null, 0);
        }
        if (duplicateCaseIds == null || duplicateCaseIds.isEmpty()) {
            return new MergeResult(false, 'At least one duplicate Case ID is required.', null, 0);
        }
        if (duplicateCaseIds.contains(masterCaseId)) {
            duplicateCaseIds.remove(duplicateCaseIds.indexOf(masterCaseId));
            if (duplicateCaseIds.isEmpty()) {
                return new MergeResult(false, 'Cannot merge a case with itself.', null, 0);
            }
        }

        Savepoint sp = Database.setSavepoint();
        Integer totalReparented = 0;

        try {
            // Get the master case number for reference in duplicate updates
            Case masterCase = [
                SELECT Id, CaseNumber FROM Case
                WHERE Id = :masterCaseId LIMIT 1
            ];

            // Build the Salesforce record URL for the master case
            String baseUrl = URL.getOrgDomainURL().toExternalForm();
            String masterCaseUrl = baseUrl + '/lightning/r/Case/' + masterCaseId + '/view';

            // 1. Reparent CaseComments (ParentId is not updateable, so we clone, insert, and delete)
            List<CaseComment> comments = [
                SELECT Id, ParentId, IsPublished, CommentBody FROM CaseComment
                WHERE ParentId IN :duplicateCaseIds
            ];
            if (!comments.isEmpty()) {
                List<CaseComment> newComments = new List<CaseComment>();
                for (CaseComment cc : comments) {
                    newComments.add(new CaseComment(
                        ParentId = masterCaseId,
                        IsPublished = cc.IsPublished,
                        CommentBody = cc.CommentBody
                    ));
                }
                insert newComments;
                delete comments;
                totalReparented += newComments.size();
            }

            // 2. Reparent EmailMessages
            List<EmailMessage> emails = [
                SELECT Id, ParentId FROM EmailMessage
                WHERE ParentId IN :duplicateCaseIds
            ];
            for (EmailMessage em : emails) {
                em.ParentId = masterCaseId;
            }
            if (!emails.isEmpty()) {
                update emails;
                totalReparented += emails.size();
            }

            // 3. Reparent Tasks
            List<Task> tasks = [
                SELECT Id, WhatId FROM Task
                WHERE WhatId IN :duplicateCaseIds
            ];
            for (Task t : tasks) {
                t.WhatId = masterCaseId;
            }
            if (!tasks.isEmpty()) {
                update tasks;
                totalReparented += tasks.size();
            }

            // 4. Reparent Events
            List<Event> events = [
                SELECT Id, WhatId FROM Event
                WHERE WhatId IN :duplicateCaseIds
            ];
            for (Event e : events) {
                e.WhatId = masterCaseId;
            }
            if (!events.isEmpty()) {
                update events;
                totalReparented += events.size();
            }

            // 5. Reparent ContentDocumentLinks (Files/Attachments)
            // ContentDocumentLink cannot be updated — must delete and re-insert
            List<ContentDocumentLink> existingLinks = [
                SELECT Id, ContentDocumentId, LinkedEntityId, ShareType, Visibility
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :duplicateCaseIds
            ];
            if (!existingLinks.isEmpty()) {
                // Collect ContentDocumentIds already linked to master to avoid duplicates
                Set<Id> masterDocIds = new Set<Id>();
                for (ContentDocumentLink cdl : [
                    SELECT ContentDocumentId FROM ContentDocumentLink
                    WHERE LinkedEntityId = :masterCaseId
                ]) {
                    masterDocIds.add(cdl.ContentDocumentId);
                }

                List<ContentDocumentLink> newLinks = new List<ContentDocumentLink>();
                for (ContentDocumentLink cdl : existingLinks) {
                    if (!masterDocIds.contains(cdl.ContentDocumentId)) {
                        newLinks.add(new ContentDocumentLink(
                            ContentDocumentId = cdl.ContentDocumentId,
                            LinkedEntityId = masterCaseId,
                            ShareType = cdl.ShareType,
                            Visibility = cdl.Visibility
                        ));
                        masterDocIds.add(cdl.ContentDocumentId);
                    }
                }
                delete existingLinks;
                if (!newLinks.isEmpty()) {
                    insert newLinks;
                    totalReparented += newLinks.size();
                }
            }

            // 6. Reparent child Cases (self-referencing ParentId)
            List<Case> childCases = [
                SELECT Id, ParentId FROM Case
                WHERE ParentId IN :duplicateCaseIds
            ];
            for (Case child : childCases) {
                child.ParentId = masterCaseId;
            }
            if (!childCases.isEmpty()) {
                update childCases;
                totalReparented += childCases.size();
            }

            // 7. Close duplicate cases and update Subject with 'Merged -' prefix
            //    and add a hyperlink to the master case in the Description
            List<Case> duplicates = [
                SELECT Id, Subject, Description FROM Case
                WHERE Id IN :duplicateCaseIds
            ];
            for (Case dup : duplicates) {
                dup.Status = 'Closed';
                // Prepend 'Merged - ' to the Subject
                dup.Subject = 'Merged - ' + (dup.Subject != null ? dup.Subject : '');
                // Append master case hyperlink to Description
                String mergeNote = '\n\n--- Merged into Master Case '
                    + masterCase.CaseNumber + ' ---'
                    + '\nMaster Case Link: ' + masterCaseUrl
                    + '\nMerged on: ' + Datetime.now().format('yyyy-MM-dd HH:mm:ss');
                dup.Description = (dup.Description != null ? dup.Description : '') + mergeNote;
            }
            update duplicates;

            return new MergeResult(
                true,
                'Successfully merged ' + duplicateCaseIds.size() + ' case(s) into master case '
                    + masterCase.CaseNumber + '. '
                    + totalReparented + ' related record(s) were reparented. '
                    + 'Duplicate cases have been closed.',
                masterCaseId,
                totalReparented
            );

        } catch (Exception ex) {
            Database.rollback(sp);
            return new MergeResult(
                false,
                'Merge failed: ' + ex.getMessage(),
                null,
                0
            );
        }
    }

    /**
     * Helper: count child records using dynamic SOQL.
     */
    private static Map<Id, Integer> countChildRecords(
        String objectName, String parentField, List<Id> parentIds
    ) {
        Map<Id, Integer> counts = new Map<Id, Integer>();
        String query = 'SELECT ' + parentField + ', COUNT(Id) cnt '
            + 'FROM ' + objectName + ' '
            + 'WHERE ' + parentField + ' IN :parentIds '
            + 'GROUP BY ' + parentField;

        for (AggregateResult ar : Database.query(query)) {
            Id parentId = (Id) ar.get(parentField);
            Integer cnt = (Integer) ar.get('cnt');
            counts.put(parentId, cnt);
        }
        return counts;
    }
}
