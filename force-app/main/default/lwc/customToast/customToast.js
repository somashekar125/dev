import { LightningElement, api, track } from 'lwc';

export default class CustomToast extends LightningElement {
    @api title;
    @api message;
    @api variant; // 'success', 'error', 'warning', 'info'
    @track show = false;

    @api showToast() {
        this.show = true;
        setTimeout(() => {
            this.closeToast();
        }, 5000); // 5 seconds
    }

    closeToast() {
        //this.show = false;
    }
}