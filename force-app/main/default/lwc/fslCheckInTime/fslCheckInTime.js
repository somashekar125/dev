import { LightningElement, wire, api, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import populateCheckInTime from '@salesforce/apex/FslQuickActions.populateCheckInTime';


export default class FslCheckOutTime extends LightningElement {
    recordId;
    @track checkedIn;
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
            //alert('recordId wire--->' + this.recordId);
            console.log('recordId  currentPageReference-> ' + this.recordId);
        }
    }

    connectedCallback() {
        console.log('recordId connectedCallback -> ' + this.recordId);
        //alert('recordId--->' + this.recordId);
        this.updateCheckInTime();
    }
    
    updateCheckInTime(){
        populateCheckInTime({ServiceAppointmentId: this.recordId})
        .then(result => {
            console.log('SUCCESS');
            this.checkedIn = true;
            /*alert('updateCheckInTime--->');
            const pageReference = {
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId, // Pass the Work Order's record ID
                    objectApiName: 'ServiceAppointment', // Object API name for Work Orders
                    actionName: 'view',
                },
            };
            alert('pageReference--->' + JSON.stringify(pageReference));
            this[NavigationMixin.Navigate](pageReference);*/
            
            /*setTimeout(() => {
                this.dispatchEvent(new CloseActionScreenEvent());
            }, 1000);*/
        })
        .catch(error => {
            console.log('error-> '+ JSON.stringify(error));
        })
    }
}