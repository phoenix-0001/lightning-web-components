import { LightningElement, api, wire } from 'lwc';
import { 
    FlowNavigationNextEvent, 
    FlowNavigationFinishEvent 
} from 'lightning/flowSupport';

import getProducts from '@salesforce/apex/ProductSelectorController.getProducts';

export default class ProductSelector extends LightningElement {
    // Expose the selected product value to Flow
    @api selectedProductId;

    // Flow injects available actions at runtime (NEXT, BACK, FINISH)
    @api availableActions = [];

    // Holds the list of products returned from Apex
    products = [];

    /**
     * Fetch products using @wire.
     * Cacheable Apex keeps performance high inside screen flows.
     */
    @wire(getProducts)
    wiredProducts({ data, error }) {
        if (data) {
            // Format the returned records so the template is simple to read
            this.products = data.map(item => ({
                Id: item.Id,
                Name: item.Name,
                Description: item.Description
            }));
        } else if (error) {
            // Always log wire errors for debugging
            console.error('Error fetching products: ', error);
        }
    }

    /**
     * Triggered when a user selects a product radio button.
     * Stores the selected Id and then moves the flow forward.
     */
    handleSelect(event) {
        this.selectedProductId = event.currentTarget.value;
        this.navigateNextOrFinish();
    }

    /**
     * Decides which navigation event to fire.
     * Flow determines available actions based on your screen footer.
     *
     * Examples:
     * - If this is NOT the last screen, "NEXT" is available.
     * - If this IS the last screen, only "FINISH" is available.
     *
     * This logic prevents the common "NEXT is not supported" Flow error.
     */
    navigateNextOrFinish() {
        // Convert availableActions to array (safety)
        const actions = Array.isArray(this.availableActions) ? this.availableActions : [];

        // Preferred path: move forward in the flow
        if (actions.includes('NEXT')) {
            this.dispatchEvent(new FlowNavigationNextEvent());
            return;
        }

        // Fallback: finish the flow when NEXT isn't present
        if (actions.includes('FINISH')) {
            this.dispatchEvent(new FlowNavigationFinishEvent());
            return;
        }

        // If neither NEXT nor FINISH is available, nothing can be done
        // This usually indicates a misconfigured screen footer
        console.warn('No supported navigation actions available on this screen.');
    }
}
