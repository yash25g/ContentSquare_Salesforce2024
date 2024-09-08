import { LightningElement, api } from 'lwc';
import OpenRecordMsg from '@salesforce/label/c.OpenRecordMsg';
import { NavigationMixin } from 'lightning/navigation';

export default class GenericNavigateToRecordPage extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectName;
    @api objectApiName;
    openRecordMsg = OpenRecordMsg;

    //function to navigate to the record page
    handleNavigation() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: this.objectApiName,
                actionName: 'view'
            }
        });
    }
}