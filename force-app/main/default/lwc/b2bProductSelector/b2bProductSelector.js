import { LightningElement, api } from 'lwc';
// Import the OmniScript base mixin. This enables the LWC to communicate seamlessly with an OmniScript,
// allowing us to read data passed in and send data back out while controlling the OmniScript navigation.
import { OmniscriptBaseMixin } from 'omnistudio/omniscriptBaseMixin';

export default class B2bProductSelector extends OmniscriptBaseMixin(LightningElement) {
    // This property can receive data from the OmniScript JSON. 
    // Usually, you pass a variable from OmniScript to the LWC in the designer properties.
    @api customerName; 

    /**
     * @description Provides the options for the base software packages that the user can select from.
     * In a real-world scenario, this might come from an Apex callout to retrieve active products.
     */
    get productOptions() {
        return [
            { label: 'Starter CRM Package', value: 'CRM_START' },
            { label: 'Professional CRM Package', value: 'CRM_PRO' },
            { label: 'Enterprise Suite', value: 'ENT_SUITE' }
        ];
    }

    /**
     * @description Provides the options for additional add-on modules.
     * These represent optional features a business could add to their base package.
     */
    get moduleOptions() {
        return [
            { label: 'Advanced Analytics', value: 'MOD_ANALYTICS' },
            { label: 'Marketing Automation', value: 'MOD_MKTG' },
            { label: 'Dedicated Support', value: 'MOD_SUPPORT' },
            { label: 'AI Insights', value: 'MOD_AI' }
        ];
    }

    // Properties to store user selections
    selectedProduct = ''; // Holds the single selected base product value
    selectedModules = []; // Holds an array of selected add-on module values

    /**
     * @description Event handler for when the user selects a base product from the combobox.
     * @param {Event} event The change event from the lightning-combobox
     */
    handleProductChange(event) {
        this.selectedProduct = event.target.value;
    }

    /**
     * @description Event handler for when the user selects/deselects add-on modules.
     * @param {Event} event The change event from the lightning-checkbox-group
     */
    handleModuleChange(event) {
        // Since checkbox-group can have multiple selections, event.detail.value provides an array.
        // We use the spread operator to create a fresh array copy of selected choices.
        this.selectedModules = [...event.detail.value];
    }

    /**
     * @description Computes whether the submit button should be disabled.
     * The business rule here requires at least a base product to proceed.
     */
    get isSubmitDisabled() {
        // If selectedProduct is an empty string, this returns true, disabling the button.
        return !this.selectedProduct;
    }

    /**
     * @description Called when the user clicks the "Confirm Selection & Proceed" button.
     * It packages the user's selections and signals the OmniScript to save the data and move to the next step.
     */
    sendDataToOmni() {
        // Logging for debugging purposes (visible in browser console)
        console.log('Selected Product :: ' + this.selectedProduct);
        console.log('Selected Add-on Modules :: ' + JSON.stringify(this.selectedModules));
        
        // This payload defines the JSON structure that will be injected into the OmniScript data JSON.
        // It creates a node called "orderSelection" containing the chosen product and modules.
        const payload = {
            orderSelection: {
                baseProduct: this.selectedProduct,
                addOnModules: this.selectedModules
            }
        };

        // this.omniApplyCallResp updates the OmniScript JSON with our constructed payload.
        this.omniApplyCallResp(payload);
        
        // this.omniNextStep programmatically triggers the OmniScript engine to proceed to the next element/step.
        this.omniNextStep();
    }
}
