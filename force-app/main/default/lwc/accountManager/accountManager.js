import { LightningElement, wire, track } from 'lwc';
import { deleteRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { gql, graphql } from 'lightning/uiGraphQLApi';

const COLUMNS = [
    { label: 'Account Name', fieldName: 'Name' },
    { label: 'Industry', fieldName: 'Industry' },
    { label: 'Annual Revenue', fieldName: 'AnnualRevenue', type: 'currency' }
];

export default class AccountManager extends LightningElement {
    columns = COLUMNS;
    selectedRows = [];
    @track accounts = [];
    wiredAccountResult;

    // GraphQL to get Top 10 Accounts by Revenue without Apex
    @wire(graphql, {
        query: gql`
            query TopAccounts {
                uiapi {
                    query {
                        Account(first: 10, orderBy: { LastModifiedDate: { order: DESC } }) {
                            edges {
                                node {
                                    Id
                                    Name { value }
                                    Industry { value }
                                    AnnualRevenue { displayValue, value }
                                }
                            }
                        }
                    }
                }
            }
        `
    })
    wiredAccounts(result) {
        this.wiredAccountResult = result;
        if (result.data) {
            this.accounts = result.data.uiapi.query.Account.edges.map(edge => ({
                id: edge.node.Id,
                Name: edge.node.Name.value,
                Industry: edge.node.Industry.value,
                AnnualRevenue: edge.node.AnnualRevenue.value
            }));
        } else if (result.error) {
            console.error(result.error);
        }
    }

    get isDeleteDisabled() {
        return this.selectedRows.length === 0;
    }

    handleRowSelection(event) {
        this.selectedRows = event.detail.selectedRows;
    }

    async handleDelete() {
        const promises = this.selectedRows.map(row => deleteRecord(row.id));
        
        try {
            await Promise.all(promises);
            
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Selected accounts deleted',
                    variant: 'success'
                })
            );
            
            // Clear selection and refresh the list
            this.template.querySelector('lightning-datatable').selectedRows = [];
            return refreshApex(this.wiredAccountResult);
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error deleting records',
                    message: error.body.message,
                    variant: 'error'
                })
            );
        }
    }
}