import { LightningElement, wire, api, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import populateCheckOutTime from '@salesforce/apex/FslQuickActions.populateCheckOutTime';

export default class FslCheckOutTime extends LightningElement {
    recordId;
    @track checkedOut;
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
        this.updateCheckOutTime();
    }
    
    updateCheckOutTime(){
        populateCheckOutTime({ServiceAppointmentId: this.recordId})
        .then(result => {
            console.log('SUCCESS');
            this.checkedOut = true;
        })
        .catch(error => {
            console.log('error-> '+ JSON.stringify(error));
        })
    }
}