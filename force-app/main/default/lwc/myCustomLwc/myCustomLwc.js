import { LightningElement } from 'lwc';
import { OmniScriptBaseMixin } from 'omnistudio/omniscriptBaseMixin';

export default class MyCustomLwc extends OmniScriptBaseMixin(LightningElement) {

    handleSendData() {

        // Data you want to send back to OmniScript
        const data = {
            accountName: 'ABC Corporation',
            accountNumber: 'ACC-12345',
            isActive: true
        };

        // This updates the OmniScript JSON
        this.omniApplyCallResp(data);

        console.log('Data sent to OmniScript:', data);
    }
}