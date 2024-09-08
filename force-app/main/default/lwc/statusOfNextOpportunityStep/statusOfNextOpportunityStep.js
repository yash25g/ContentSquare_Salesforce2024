import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import SET_NEXT_FIELD_STATUS from '@salesforce/schema/Opportunity.SetNextFieldStatus__c'; 

export default class StatusOfNextOpportunityStep extends LightningElement {
    showRedCircle = false;
    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields: [SET_NEXT_FIELD_STATUS] })
    wiredRecord({ data }) {
        if (data) {
            this.showRedCircle = data.fields.SetNextFieldStatus__c.value;
        }
    }

    get circleStyle() {
        return `height: 50px; width: 50px; background-color: ${this.showRedCircle ? 'red' : 'green'}; border-radius: 50%; display: inline-block;`;
    }   
}
