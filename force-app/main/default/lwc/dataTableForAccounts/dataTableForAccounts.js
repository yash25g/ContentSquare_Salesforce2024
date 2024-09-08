import { LightningElement, api, track } from 'lwc';
import getAccountToDisplay from '@salesforce/apex/AdditionalContractSharingController.getAccountToDisplay';

const columns = [
    { label: 'Account Name', fieldName: 'accName', wrapText:true },
    { label: 'Record Type', fieldName: 'accRecordType', wrapText:true},
    { label: 'Account Status', fieldName: 'accStatus', wrapText:true },
    { label: 'Domain', fieldName: 'accDomain', wrapText:true},
    { label: 'Business Review Segment', fieldName: 'accBusinessReviewSegment', wrapText:true},
    { label: 'Billing Country', fieldName: 'accCountry', wrapText:true},
    { label: 'Region', fieldName: 'accRegion', wrapText:true },
];
export default class DataTableForAccounts extends LightningElement {

    @api rootAccountId;
    @api accIdsToExclude;
    @api recordType;
    @api billToAccountId;
    @api selectedAccs;
    @track accsToDisplay = {};      
    accsRetrieved = {};
    columns = columns;
    timer;
    accNameFilterValue;
    accCountryFilterValue;
    selectedRows = [];

    connectedCallback(){            
            this.getAccountToDisplay();
    }

    getAccountToDisplay(){        
        getAccountToDisplay({ rootAccId: this.rootAccountId,
                              recordTypeDeveloperName: this.recordType,
                              billToAccId: this.billToAccountId,
                              accIdsToExclude: this.accIdsToExclude})
        .then(result => {
            this.error = undefined;
            this.accsRetrieved = result;
            this.accsToDisplay = result;
        })
        .catch(error => {
            this.error = error;
        })
    }

    handleFilterChange(event){
        const {value} = event.target
        const {searchfield} = event.target
        this[searchfield === 'accCountry' ? 'accCountryFilterValue' : 'accNameFilterValue'] = value;
        window.clearTimeout(this.timer);
        if(this.accNameFilterValue || this.accCountryFilterValue){
            this.timer = window.setTimeout(()=>{
                this.accsToDisplay = this.accsRetrieved.filter(eachObj=>{
                    // add check to handle the null value so that filter works properly.
                    const matchesName = this.accNameFilterValue ? (eachObj.accName ? eachObj.accName.toLowerCase().includes(this.accNameFilterValue.toLowerCase()) : false) : true;
                    const matchesCountry = this.accCountryFilterValue ? (eachObj.accCountry ? eachObj.accCountry.toLowerCase().includes(this.accCountryFilterValue.toLowerCase()) : false) : true;
                    return matchesName && matchesCountry;
                })
                this.template.querySelector('[data-id="datatable"]').selectedRows = this.selectedRows;
            }, 500)
        } else {
            this.accsToDisplay = [...this.accsRetrieved];           
            this.template.querySelector('[data-id="datatable"]').selectedRows = this.selectedRows;
        }
    }

    get showNoDataMessage(){
        return this.accsToDisplay.length > 0 ? false : true; 
    }

    handleRowSelection(event){

        let updatedItemsSet = new Set();
        let selectedItemsSet = new Set(this.selectedRows);
        let loadedItemsSet = new Set();

        this.accsToDisplay.map((ele) => {
            loadedItemsSet.add(ele.accId);
        });

        if (event.detail.selectedRows) {
            event.detail.selectedRows.map((ele) => {
                updatedItemsSet.add(ele.accId);
            });

            // Add any new items to the selectedRows list
            updatedItemsSet.forEach((id) => {
                if (!selectedItemsSet.has(id)) {
                    selectedItemsSet.add(id);
                }
            });
        }

        loadedItemsSet.forEach((id) => {
            if (selectedItemsSet.has(id) && !updatedItemsSet.has(id)) {
                // Remove any items that were unselected.
                selectedItemsSet.delete(id);
            }
        });
        
        this.selectedRows = [...selectedItemsSet];

        this.selectedAccs = JSON.stringify(this.accsRetrieved.filter(eachObj=>{
            return this.selectedRows.includes(eachObj.accId);
        }));
    }
}