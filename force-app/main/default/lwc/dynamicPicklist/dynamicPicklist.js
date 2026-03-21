import { LightningElement, api, wire } from 'lwc';
import getPicklistValues from '@salesforce/apex/DynamicPicklistController.getPicklistValues';

export default class DynamicPicklist extends LightningElement {
    @api recordId;

    options = [];
    value;

    @wire(getPicklistValues, { recordId: '$recordId' })
    wiredValues({ error, data }) {
        if (data) {
            this.options = data.map(item => {
                return {
                    label: item,
                    value: item
                };
            });
        } else if (error) {
            console.error('Error fetching picklist values', error);
        }
    }

    handleChange(event) {
        this.value = event.detail.value;
    }
}