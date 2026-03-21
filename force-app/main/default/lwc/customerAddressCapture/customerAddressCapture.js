import { LightningElement, api, track } from 'lwc';
// OmniScript Base Mixin provides methods to communicate with the parent OmniScript:
//   - omniUpdateDataJson(payload)  : Updates OmniScript data JSON in REAL-TIME (no button click required)
//   - omniApplyCallResp(payload)   : Merges a payload into OmniScript data (typically on submit)
//   - omniNextStep()               : Navigates OmniScript to the next step
//   - omniPrevStep()               : Navigates OmniScript to the previous step
import { OmniscriptBaseMixin } from 'omnistudio/omniscriptBaseMixin';

/**
 * @description  customerAddressCapture – A real-world Customer Address Capture component.
 *
 *  USE CASE:
 *  During a "New Customer Onboarding" OmniScript, the agent collects the customer's
 *  shipping address. Every field change is pushed back to the OmniScript data JSON
 *  in REAL-TIME using `omniUpdateDataJson`, so other steps/elements in the same
 *  OmniScript can immediately react to the address data (e.g. run validation
 *  Integration Procedures, display dynamic messages, etc.).
 *
 *  KEY OMNISCRIPT METHOD DEMONSTRATED:
 *  ─────────────────────────────────
 *  this.omniUpdateDataJson(payload)
 *     → Pushes data into the OmniScript JSON instantly, without requiring a
 *       button click or step navigation. This is what makes it "real-time".
 */
export default class CustomerAddressCapture extends OmniscriptBaseMixin(LightningElement) {

    // ── Public Properties (received from OmniScript) ──────────────────────────
    // The OmniScript can pass the customer's name into this property via the
    // component's "Custom LWC Properties" in the OmniScript Designer.
    @api customerName;

    // ── Tracked Properties (reactive state for the template) ──────────────────
    // @track is used here so that nested object property changes are detected.
    @track address = {
        street: '',
        city: '',
        state: '',
        postalCode: '',
        country: ''
    };

    // Holds the type of address (Shipping or Billing)
    addressType = 'Shipping';

    // ── Getter: Address Type Options ──────────────────────────────────────────
    /**
     * @description Options for the address type dropdown.
     * In a real scenario this could also include 'PO Box', 'Warehouse', etc.
     */
    get addressTypeOptions() {
        return [
            { label: 'Shipping Address', value: 'Shipping' },
            { label: 'Billing Address', value: 'Billing' }
        ];
    }

    // ── Getter: US State Options ──────────────────────────────────────────────
    /**
     * @description A subset of US States for the state picklist.
     * In production you might load these from Custom Metadata or an Apex call.
     */
    get stateOptions() {
        return [
            { label: '-- Select State --', value: '' },
            { label: 'California', value: 'CA' },
            { label: 'New York', value: 'NY' },
            { label: 'Texas', value: 'TX' },
            { label: 'Florida', value: 'FL' },
            { label: 'Illinois', value: 'IL' },
            { label: 'Washington', value: 'WA' },
            { label: 'Georgia', value: 'GA' },
            { label: 'Ohio', value: 'OH' }
        ];
    }

    // ── Getter: Validation ────────────────────────────────────────────────────
    /**
     * @description Returns true when all required address fields have been filled.
     * Used to control the enabled/disabled state of the "Confirm" button.
     */
    get isSubmitDisabled() {
        return !(
            this.address.street &&
            this.address.city &&
            this.address.state &&
            this.address.postalCode &&
            this.address.country
        );
    }

    // ── Event Handlers ────────────────────────────────────────────────────────

    /**
     * @description Handles changes to the Address Type combobox.
     * @param {Event} event – lightning-combobox change event
     */
    handleAddressTypeChange(event) {
        this.addressType = event.detail.value;
        // Push the updated address type to OmniScript in real-time
        this._pushToOmniScript();
    }

    /**
     * @description Generic handler for any address field change.
     *  The `data-field` attribute on each input tells us WHICH property to update.
     *  After updating the local state, we immediately push the updated address
     *  back to the OmniScript JSON so other elements can consume it in real-time.
     *
     * @param {Event} event – lightning-input change event
     */
    handleFieldChange(event) {
        // Read the field name from the HTML data-field attribute (e.g. "street", "city")
        const field = event.target.dataset.field;

        // lightning-input uses event.target.value; lightning-combobox uses event.detail.value.
        // We check event.detail.value first (combobox), then fall back to event.target.value (input).
        const value = event.detail.value !== undefined ? event.detail.value : event.target.value;

        // Update local state – we create a new object to trigger reactive re-render
        this.address = { ...this.address, [field]: value };

        // ★ REAL-TIME UPDATE ★
        // Push updated address data to OmniScript immediately as the user types
        this._pushToOmniScript();
    }

    // ── Private Helper: Push data to OmniScript in real-time ──────────────────
    /**
     * @description Builds the payload and calls omniUpdateDataJson to push
     *  data into the OmniScript JSON in real-time (no button click needed).
     *
     *  The OmniScript data JSON will be updated with:
     *  {
     *      "customerAddress": {
     *          "addressType": "Shipping",
     *          "street": "123 Main St",
     *          "city": "San Francisco",
     *          "state": "CA",
     *          "postalCode": "94105",
     *          "country": "USA"
     *      }
     *  }
     *
     *  Other OmniScript elements (e.g. a Set Values, Formula, or another LWC)
     *  can reference %customerAddress:street% etc. to use this data instantly.
     */
    _pushToOmniScript() {
        const payload = {
            customerAddress: {
                addressType: this.addressType,
                street: this.address.street,
                city: this.address.city,
                state: this.address.state,
                postalCode: this.address.postalCode,
                country: this.address.country
            }
        };

        // ★ THIS IS THE KEY METHOD ★
        // omniUpdateDataJson merges the payload into the OmniScript's live data JSON.
        // Unlike omniApplyCallResp (which is typically used on submit), this method
        // updates the data IMMEDIATELY, making it available to subsequent OmniScript
        // elements in real-time.
        this.omniUpdateDataJson(payload);
    }

    // ── Confirm & Navigate to Next Step ───────────────────────────────────────
    /**
     * @description Called when the user clicks "Confirm Address & Proceed".
     *  Performs a final data push (as a safety net) and navigates forward.
     */
    confirmAndProceed() {
        // Final push to ensure the latest data is in OmniScript
        this._pushToOmniScript();

        console.log('Address confirmed:', JSON.stringify(this.address));

        // Navigate the OmniScript to the next step
        this.omniNextStep();
    }
}
