import { LightningElement, api } from 'lwc';
import {OmniscriptBaseMixin} from 'omnistudio/omniscriptBaseMixin';

export default class PlanSelector extends OmniscriptBaseMixin(LightningElement) {
    @api customerInfo; // Data coming from Omniscript
    get options(){
        return [
            {label: 'Hotstar', value: 'IR'},
            {label: 'Netflix', value: 'NET'},
            {label: 'Data pack', value: 'RDP'}
        ];
    }
    get mobileOptions(){
        return [
            {label: 'Basic plan', value: 'Basic'},
            {label: 'Premium Plan', value: 'Premium'},
            {label: 'Unlimited', value: 'Unlimited'}
        ];
    }
    selectedPlan = '';
    selectedAddOns = [];

    handlePlanChange(event){
        this.selectedPlan = event.target.value;
    }

    handleAddOnChange(event){
        this.selectedAddOns = [...event.detail.value];
    }

    sendDataToOmni(){
        console.log('Selected Plan ::'+ this.selectedPlan);
        const payload = {
            customer: {
                plan: this.selectedPlan,
                addOns: this.selectedAddOns
            }
        };

        //Send Data back to Omniscript
        this.omniApplyCallResp(payload);
        this.omniNextStep();
    }

}