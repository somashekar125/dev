import { LightningElement, wire, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import checkForProductTransfers from '@salesforce/apex/ClosingProcess.checkForProductTransfers';
import checkForProductTransfers2 from '@salesforce/apex/ClosingProcess.checkForProductTransfers2';

export default class ProductTransferCheck extends LightningElement {
    @api recordId;

    connectedCallback() {
        console.log('connectedCallback for PT');
        console.log('recordId-> ' + this.recordId);
        if(this.recordId.includes("0WO")){
            console.log('calling checkProductTransfersInWO');
			this.checkProductTransfersInWO();
		}
		if(this.recordId.includes("500")){
            console.log('calling checkProductTransfersInCase');
            this.checkProductTransfersInCase();
        }
    }

    checkProductTransfersInWO(event){
        console.log('checkProductTransfersInWO');
        checkForProductTransfers({woId: this.recordId })
            .then((result) => {
                console.log('result-> ' + result);
                if(result == true){
                    const emptyList = new ShowToastEvent({
                        title: 'Error',
                        message: 'Unreceived product transfers found under this Work Order!',
                        variant: 'error',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(emptyList);
                }
            })
            .catch((error) => {
                console.log('checkProductTransfersInWO error-> ' + JSON.stringify(error));
                this.itemClassProdList = [];
            });
    }

    checkProductTransfersInCase(event){
        console.log('checkProductTransfersInCase');
        checkForProductTransfers2({caseId: this.recordId })
            .then((result) => {
                console.log('result-> ' + result);
                if(result == true){
                    const emptyList = new ShowToastEvent({
                        title: 'Error',
                        message: 'Unreceived product transfers found under this Case!',
                        variant: 'error',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(emptyList);
                }
            })
            .catch((error) => {
                console.log('checkProductTransfersInCase error-> ' + JSON.stringify(error));
                this.itemClassProdList = [];
            });
    }
}