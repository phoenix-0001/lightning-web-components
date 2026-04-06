import { LightningElement,api } from 'lwc';

/**
 * @description LWC designed to be placed on a Screen Flow screen.
 * It redirects the user to a specific record page using window.location.href.
 * The targetRecordId is passed as an input parameter from the Flow.
 */
export default class FlowNavigateToRecord extends LightningElement {

    // Public property to receive the record Id from Screen Flow
    @api targetRecordId;

    // Controls the visibility of the loading spinner
    @api showSpinner=false;

    /**
     * @description Lifecycle hook that fires when the component is inserted into the DOM.
     * Immediately redirects the browser to the record detail page.
     * Note: This uses a full page reload approach via window.location.href
     */
    connectedCallback(){
        this.showSpinner=true;

        // Construct the record URL and force a full page redirect
        window.location.href = "/"+this.targetRecordId;

        this.showSpinner=false;

    }
}