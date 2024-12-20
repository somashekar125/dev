import { LightningElement, wire, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import retreiveRelatedWOs from '@salesforce/apex/DeletingWorkOrder.retreiveRelatedWOs';
import deleteCurrentWorkOrder from '@salesforce/apex/DeletingWorkOrder.deleteCurrentWorkOrder';
import deleteAllWOsAndCase from '@salesforce/apex/DeletingWorkOrder.deleteAllWOsAndCase';

export default class DeletingWorkOrder extends NavigationMixin(LightningElement) {
    @api recordId;
    @track woList = [];
    @track woExists = false;
    @track showSpinner = false;
    @track workOrderNumber = '';

    connectedCallback(){
        console.log('DeletingWorkOrder recordId 1-> ' + this.recordId);
    }

    handleDeleteWO(event){
        retreiveRelatedWOs({workOrderId : this.recordId})
            .then((result) => {
                this.woList = result;
                this.woExists = true;
                this.woList.forEach((item, index) => {
                    if(item.Id == this.recordId){
                        this.workOrderNumber = item.WorkOrderNumber;
                    }
                });
                console.log('this.woList-> ' + JSON.stringify(this.woList));
            })
            .catch((error) => {
                console.log('handleDeleteWO error-> ' + JSON.stringify(error));
            });
    }

    handleCancel(event){
        this.woExists = false;
    }

    deleteCurrentWO(event){
        this.woExists = false;
        this.showSpinner = true;
        deleteCurrentWorkOrder({workOrderId : this.recordId})
        .then((result) => {
            console.log('SUCCESS');
            this.woDeletedToast();
            this.showSpinner = false;
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: 'WorkOrder',
                    actionName: 'list'
                },
                state: {
                    filterName: 'Recent'
                },
            });
            
        })
        .catch((error) => {
            console.log('deleteCurrentWO error-> ' + JSON.stringify(error));
            var msg = error.body.message;
            const regex = /.*?FIELD_CUSTOM_VALIDATION_EXCEPTION, (.+): \[\]/;
            const match = regex.exec(msg);
            if (match && match.length > 1) {
                msg = match[1];
            }
            console.log('msg-> ' + msg);
            const errorToast = new ShowToastEvent({
                title: 'Error',
                message: msg,
                variant: 'error',
                mode: 'dismissable'
            });
            this.dispatchEvent(errorToast);
            this.showSpinner = false;
        });
    }

    deleteAll(event){
        this.woExists = false;
        this.showSpinner = true;
        deleteAllWOsAndCase({workOrderId : this.recordId})
        .then((result) => {
            console.log('SUCCESS');
            this.woDeletedToast();
            this.showSpinner = false;
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: 'WorkOrder',
                    actionName: 'list'
                },
                state: {
                    filterName: 'Recent'
                },
            }); 
        })
        .catch((error) => {
            console.log('deleteAll error-> ' + JSON.stringify(error));
            var msg = error.body.message;
            const regex = /.*?FIELD_CUSTOM_VALIDATION_EXCEPTION, (.+): \[\]/;
            const match = regex.exec(msg);
            if (match && match.length > 1) {
                msg = match[1];
            }
            console.log('msg-> ' + msg);
            const errorToast = new ShowToastEvent({
                title: 'Error',
                message: msg,
                variant: 'error',
                mode: 'dismissable'
            });
            this.dispatchEvent(errorToast);
            this.showSpinner = false;
        });
    }

    woDeletedToast(event){
        var msg = 'Work Order ' + this.workOrderNumber + ' was deleted.';
        const consumptionDone = new ShowToastEvent({
            title: 'Success!',
            message: msg,
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(consumptionDone);
    }
}