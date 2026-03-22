import { LightningElement, api, track } from 'lwc';
// OmniScript Base Mixin provides methods to communicate with the parent OmniScript:
//   - omniApplyCallResp(payload)   : Merges a payload into OmniScript data (on submit)
//   - omniNextStep()               : Navigates OmniScript to the next step
import { OmniscriptBaseMixin } from 'omnistudio/omniscriptBaseMixin';

/**
 * @description  customerFeedbackCapture – Post-Call Feedback Collection for OmniScript.
 *
 *  USE CASE:
 *  After a customer service interaction, the agent uses this component inside
 *  an OmniScript to collect a satisfaction rating, a reason, and comments.
 *  When the agent clicks "Submit Feedback", the LWC merges ALL the data into
 *  the OmniScript data JSON at once using `omniApplyCallResp`.
 *
 *  A downstream DataRaptor or Integration Procedure can then use the
 *  OmniScript data node  %customerFeedback:rating%  etc. to create a
 *  CustomerFeedback__c record or feed it into analytics.
 *
 *  KEY OMNISCRIPT METHOD DEMONSTRATED:
 *  ───────────────────────────────────
 *  this.omniApplyCallResp(payload)
 *     → Merges the payload into the OmniScript data JSON when explicitly
 *       called (typically on a button click).  Unlike omniUpdateDataJson,
 *       this does NOT push data on every keystroke — it is a one-time batch
 *       merge, ideal for form submissions.
 */
export default class CustomerFeedbackCapture extends OmniscriptBaseMixin(LightningElement) {

    // ── Public Properties (received from OmniScript) ──────────────────────────
    // The OmniScript can pass the customer's name into this property via the
    // component's "Custom LWC Properties" in the OmniScript Designer.
    @api customerName;

    // ── Tracked Properties (reactive state for the template) ──────────────────
    @track feedback = {
        rating: '',
        reason: '',
        comments: ''
    };

    // Tracks whether the feedback has been submitted (shows success message)
    isSubmitted = false;

    // ── Getter: Star Rating Options ───────────────────────────────────────────
    /**
     * @description Options for the satisfaction rating radio-button group.
     * Displayed as a horizontal button bar (1 = Very Poor → 5 = Excellent).
     */
    get ratingOptions() {
        return [
            { label: '1 – Very Poor', value: '1' },
            { label: '2 – Poor',      value: '2' },
            { label: '3 – Average',   value: '3' },
            { label: '4 – Good',      value: '4' },
            { label: '5 – Excellent', value: '5' }
        ];
    }

    // ── Getter: Reason Options ────────────────────────────────────────────────
    /**
     * @description Options for the feedback reason dropdown.
     * In production, these could be driven from Custom Metadata.
     */
    get reasonOptions() {
        return [
            { label: '-- Select Reason --',      value: '' },
            { label: 'Service Quality',           value: 'ServiceQuality' },
            { label: 'Response Time',             value: 'ResponseTime' },
            { label: 'Issue Resolution',          value: 'Resolution' },
            { label: 'Agent Professionalism',     value: 'AgentBehavior' },
            { label: 'Other',                     value: 'Other' }
        ];
    }

    // ── Getter: Validation ────────────────────────────────────────────────────
    /**
     * @description Returns true when any required field is empty.
     * Used to control the enabled / disabled state of the Submit button.
     */
    get isSubmitDisabled() {
        return !(this.feedback.rating && this.feedback.reason);
    }

    // ── Event Handlers ────────────────────────────────────────────────────────

    /**
     * @description Handles the rating radio-button group change.
     * Only updates LOCAL state — nothing is sent to OmniScript yet.
     */
    handleRatingChange(event) {
        this.feedback = { ...this.feedback, rating: event.detail.value };
    }

    /**
     * @description Handles the reason combobox change.
     * Only updates LOCAL state — nothing is sent to OmniScript yet.
     */
    handleReasonChange(event) {
        this.feedback = { ...this.feedback, reason: event.detail.value };
    }

    /**
     * @description Handles the comments textarea change.
     * Only updates LOCAL state — nothing is sent to OmniScript yet.
     */
    handleCommentsChange(event) {
        this.feedback = { ...this.feedback, comments: event.detail.value };
    }

    // ── Submit Feedback & Merge into OmniScript ──────────────────────────────
    /**
     * @description Called when the agent clicks "Submit Feedback".
     *
     *  Builds the payload and calls omniApplyCallResp to merge data into the
     *  OmniScript data JSON. The OmniScript data JSON will be updated with:
     *
     *  {
     *      "customerFeedback": {
     *          "rating": "4",
     *          "reason": "ServiceQuality",
     *          "comments": "Agent was very helpful and resolved the issue quickly.",
     *          "submittedAt": "2026-03-23T00:30:00.000Z"
     *      }
     *  }
     *
     *  Other OmniScript elements can reference:
     *    %customerFeedback:rating%
     *    %customerFeedback:reason%
     *    %customerFeedback:comments%
     *    %customerFeedback:submittedAt%
     */
    submitFeedback() {
        const payload = {
            customerFeedback: {
                rating:      this.feedback.rating,
                reason:      this.feedback.reason,
                comments:    this.feedback.comments,
                submittedAt: new Date().toISOString()
            }
        };

        // ★ THIS IS THE KEY METHOD ★
        // omniApplyCallResp merges the payload into the OmniScript's data JSON.
        // Unlike omniUpdateDataJson (which pushes on every change), this method
        // is called ONCE when the user explicitly submits the form.
        this.omniApplyCallResp(payload);

        console.log('Feedback submitted:', JSON.stringify(payload));

        // Show success state in the UI
        this.isSubmitted = true;
    }

    /**
     * @description Called when the agent clicks "Proceed to Next Step" after
     *  feedback has been submitted. Navigates the OmniScript forward.
     */
    proceedToNext() {
        this.omniNextStep();
    }
}
