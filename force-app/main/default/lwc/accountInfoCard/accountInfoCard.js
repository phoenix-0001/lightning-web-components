import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

// Import fields
import NAME_FIELD from '@salesforce/schema/Account.Name';
import REVENUE_FIELD from '@salesforce/schema/Account.AnnualRevenue';
import INDUSTRY_FIELD from '@salesforce/schema/Account.Industry';
import TYPE_FIELD from '@salesforce/schema/Account.Type';
import PHONE_FIELD from '@salesforce/schema/Account.Phone';
import WEBSITE_FIELD from '@salesforce/schema/Account.Website';
import EMPLOYEES_FIELD from '@salesforce/schema/Account.NumberOfEmployees';

const FIELDS = [NAME_FIELD, REVENUE_FIELD, INDUSTRY_FIELD, TYPE_FIELD, PHONE_FIELD, WEBSITE_FIELD, EMPLOYEES_FIELD];

export default class AccountInfoCard extends LightningElement {
    @api recordId; // Omniscript will pass the AccountId here

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    account;

    get name() { return getFieldValue(this.account.data, NAME_FIELD); }
    get industry() { return getFieldValue(this.account.data, INDUSTRY_FIELD); }
    get type() { return getFieldValue(this.account.data, TYPE_FIELD); }
    get phone() { return getFieldValue(this.account.data, PHONE_FIELD); }
    get website() { return getFieldValue(this.account.data, WEBSITE_FIELD); }
    get numberOfEmployees() { return getFieldValue(this.account.data, EMPLOYEES_FIELD); }
    
    get annualRevenue() {
        const rev = getFieldValue(this.account.data, REVENUE_FIELD);
        return rev ? new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(rev) : 'N/A';
    }

    get accountInitials() {
        return this.name ? this.name.split(' ').map(n => n[0]).join('').substring(0, 2).toUpperCase() : '??';
    }
}