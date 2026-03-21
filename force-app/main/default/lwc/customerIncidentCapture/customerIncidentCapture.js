import { LightningElement, api, track } from 'lwc';
// OmniScript Base Mixin provides methods to communicate with the parent OmniScript:
//   - omniUpdateDataJson(payload)  : Updates OmniScript data JSON in REAL-TIME
//   - omniApplyCallResp(payload)   : Merges a payload into OmniScript data (on submit)
//   - omniNextStep()               : Navigates OmniScript to the next step
//   - omniPrevStep()               : Navigates OmniScript to the previous step
import { OmniscriptBaseMixin } from 'omnistudio/omniscriptBaseMixin';

/**
 * @description  customerIncidentCapture – Real-Time Incident Logging for OmniScript.
 *
 *  USE CASE:
 *  During a "Customer Support" OmniScript, a service agent logs a support
 *  incident while on a live call with the customer. Every field change is
 *  pushed back to the OmniScript data JSON in REAL-TIME using
 *  `omniUpdateDataJson`, enabling:
 *    • A Set Values element to auto-calculate SLA deadlines based on priority
 *    • An Integration Procedure to search the knowledge base as the subject is typed
 *    • A DataRaptor to pre-fill related case fields based on the selected category
 *
 *  KEY OMNISCRIPT METHOD DEMONSTRATED:
 *  ─────────────────────────────────
 *  this.omniUpdateDataJson(payload)
 *     → Pushes data into the OmniScript JSON instantly, without requiring a
 *       button click or step navigation. This is what makes it "real-time".
 */
export default class CustomerIncidentCapture extends OmniscriptBaseMixin(LightningElement) {

    // ── Public Properties (received from OmniScript) ──────────────────────────
    // The OmniScript can pass the agent's name into this property via the
    // component's "Custom LWC Properties" in the OmniScript Designer.
    @api agentName;

    // ── Tracked Properties (reactive state for the template) ──────────────────
    // @track is used so that nested object property changes are detected.
    @track incident = {
        subject: '',
        priority: '',
        category: '',
        description: '',
        contactMethod: ''
    };

    // ── Getter: Priority Options ──────────────────────────────────────────────
    /**
     * @description Options for the priority dropdown.
     * Maps to standard Salesforce Case Priority values.
     */
    get priorityOptions() {
        return [
            { label: '-- Select Priority --', value: '' },
            { label: 'Low', value: 'Low' },
            { label: 'Medium', value: 'Medium' },
            { label: 'High', value: 'High' },
            { label: 'Critical', value: 'Critical' }
        ];
    }

    // ── Getter: Category Options ──────────────────────────────────────────────
    /**
     * @description Options for the category dropdown.
     * In production, these could come from Custom Metadata or a picklist describe.
     */
    get categoryOptions() {
        return [
            { label: '-- Select Category --', value: '' },
            { label: 'Billing & Payments', value: 'Billing' },
            { label: 'Technical Support', value: 'Technical' },
            { label: 'Account Access', value: 'AccountAccess' },
            { label: 'Network / Connectivity', value: 'Network' },
            { label: 'Other', value: 'Other' }
        ];
    }

    // ── Getter: Contact Method Options ────────────────────────────────────────
    /**
     * @description Options for the preferred contact method radio group.
     */
    get contactMethodOptions() {
        return [
            { label: 'Phone', value: 'Phone' },
            { label: 'Email', value: 'Email' },
            { label: 'Chat', value: 'Chat' }
        ];
    }

    // ── Getter: Validation ────────────────────────────────────────────────────
    /**
     * @description Returns true when any required incident field is empty.
     * Used to control the enabled/disabled state of the "Log Incident" button.
     */
    get isSubmitDisabled() {
        return !(
            this.incident.subject &&
            this.incident.priority &&
            this.incident.category &&
            this.incident.description &&
            this.incident.contactMethod
        );
    }

    // ── Event Handlers ────────────────────────────────────────────────────────

    /**
     * @description Generic handler for text/combobox/textarea field changes.
     *  The `data-field` attribute on each input tells us WHICH property to update.
     *  After updating the local state, the updated incident data is immediately
     *  pushed back to the OmniScript JSON for real-time consumption.
     *
     * @param {Event} event – change event from lightning-input, lightning-combobox,
     *                         or lightning-textarea
     */
    handleFieldChange(event) {
        // Read the field name from the HTML data-field attribute
        const field = event.target.dataset.field;

        // lightning-input uses event.target.value;
        // lightning-combobox & lightning-textarea use event.detail.value.
        // We check event.detail.value first, then fall back to event.target.value.
        const value = event.detail.value !== undefined
            ? event.detail.value
            : event.target.value;

        // Update local state – create a new object to trigger reactive re-render
        this.incident = { ...this.incident, [field]: value };

        // ★ REAL-TIME UPDATE ★
        this._pushToOmniScript();
    }

    /**
     * @description Handles changes to the contact method radio group.
     *  lightning-radio-group fires event.detail.value directly.
     *
     * @param {Event} event – lightning-radio-group change event
     */
    handleContactMethodChange(event) {
        this.incident = { ...this.incident, contactMethod: event.detail.value };

        // ★ REAL-TIME UPDATE ★
        this._pushToOmniScript();
    }

    // ── Private Helper: Push data to OmniScript in real-time ──────────────────
    /**
     * @description Builds the payload and calls omniUpdateDataJson to push
     *  data into the OmniScript JSON in real-time (no button click needed).
     *
     *  The OmniScript data JSON will be updated with:
     *  {
     *      "incidentDetails": {
     *          "subject": "Unable to access billing portal",
     *          "priority": "High",
     *          "category": "Billing",
     *          "description": "Customer reports 403 error when...",
     *          "contactMethod": "Phone"
     *      }
     *  }
     *
     *  Other OmniScript elements can reference %incidentDetails:subject%,
     *  %incidentDetails:priority%, etc. to use this data instantly.
     */
    _pushToOmniScript() {
        const payload = {
            incidentDetails: {
                subject: this.incident.subject,
                priority: this.incident.priority,
                category: this.incident.category,
                description: this.incident.description,
                contactMethod: this.incident.contactMethod
            }
        };

        // ★ THIS IS THE KEY METHOD ★
        // omniUpdateDataJson merges the payload into the OmniScript's live data JSON.
        // Unlike omniApplyCallResp (which is typically used on submit), this method
        // updates the data IMMEDIATELY, making it available to subsequent OmniScript
        // elements in real-time.
        this.omniUpdateDataJson(payload);
    }

    // ── Log Incident & Navigate to Next Step ──────────────────────────────────
    /**
     * @description Called when the agent clicks "Log Incident & Proceed".
     *  Performs a final data push (safety net) and navigates forward.
     */
    logAndProceed() {
        // Final push to ensure the latest data is in OmniScript
        this._pushToOmniScript();

        console.log('Incident logged:', JSON.stringify(this.incident));

        // Navigate the OmniScript to the next step
        this.omniNextStep();
    }
}
