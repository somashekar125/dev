import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createCaseAndWorkorderRecords from '@salesforce/apex/CreateCaseAndWorkorderController.createCaseAndWorkorderRecords';
import getProjectAccounts from '@salesforce/apex/CreateCaseAndWorkorderController.getProjectAccounts';
import searchProjectAccounts from '@salesforce/apex/CreateCaseAndWorkorderController.searchProjectAccounts';
import getServiceContract from '@salesforce/apex/CreateCaseAndWorkorderController.getServiceContract';
import getUserTimezone from '@salesforce/apex/CreateCaseAndWorkorderController.getUserTimezone';
import getServiceContractVisitOrder from '@salesforce/apex/CreateCaseAndWorkorderController.getServiceContractVisitOrder';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class CreateCaseAndWorkorder extends LightningElement {
    @api recordId;
    @track showSpinner = false;
    @track projectAccList = [];
    @track selectedProjectAccounts = [];
    @track selectedProjAccountIds = [];
    @track recordsPresent = false;
    @track recordsListOnSearch = [];
    @track servicecon = true;
    @track massSelect = 'Add All';
    @track searchKey = '';
    @track userTimezone;

    @track projectAccNoFrom = '';
    @track projectAccNoTo = '';

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
            console.log('this.recordId-> ' + this.recordId);
        }
        this.getProjectAccountsList();
    }

    @wire(getUserTimezone)
    wiredTimezone({ error, data }) {
        if (data) {
            this.userTimezone = data;
            console.log('this.userTimezone-->' + this.userTimezone);
        } else if (error) {
            console.error('Error fetching user timezone: ', error);
        }
    }

    getProjectAccountsList() {
        this.showSpinner = true;
        let index = 0;
        getProjectAccounts({ recordId: this.recordId, searchKeyFrom: this.projectAccNoFrom, searchKeyTo: this.projectAccNoTo})
            .then((result) => {
                console.log('result-->'+JSON.stringify(result));
                if (result.length == 0) {
                    this.nullErrorToast();
                }
                this.projectAccList = (result || []);
                for (let pa of this.projectAccList) {
                    pa.serialNo = index + 1;
                    index++;
                    if (pa.Cases__r != null) {
                        pa.count = pa.Cases__r.length;
                    } else {
                        pa.count = 0;
                    }
                }
                this.showSpinner = false;
                console.log('this.projectAccList -->', JSON.stringify(this.projectAccList));
            })
            .catch((error) => {
                console.error('Error retrieving project list:', error);
                this.showSpinner = false;
            });
    }

    handleKeyChange(event) {
        console.log('handleKeyChange---');
        this.searchKey = event.currentTarget.value;
        this.recordsListOnSearch = [];
        this.recordsPresent = false;

        if (this.searchKey !== '' && this.searchKey !== null) {
            console.log('handleKeyChange this.searchKey-> ' + this.searchKey);
            searchProjectAccounts({ searchKey: this.searchKey, recordId: this.recordId })
                .then((result) => {
                    if (result.length === 0) {
                        this.recordsListOnSearch = [];
                        this.recordsPresent = false;
                    } else {
                        this.recordsPresent = true;
                        this.recordsListOnSearch = result;
                        console.log('Searched Account Retrieved-> ' + JSON.stringify(result));
                    }
                })
                .catch((error) => {
                    console.log('handleKeyChange error-> ' + JSON.stringify(error));
                    this.recordsListOnSearch = [];
                });
        } else {
            this.recordsListOnSearch = [];
            this.recordsPresent = false;
        }
    }

    resetSearchBar() {
        this.objectName = 'Project Account';
        this.recordsPresent = false;
        var searchKey = this.template.querySelector('[data-name="searchAccInput"]');
        searchKey.value = '';
        this.searchKey = '';
        console.log('this.searchKey-->' + this.searchKey);
        this.recordsListOnSearch = [];
    }

    onRecordSelection(event) {
        console.log('OnRecordSelection');
        const selectedRecordIndex = event.currentTarget.dataset.index;
        const selectedRecordId = event.currentTarget.dataset.id;
        var dataName = event.currentTarget.dataset.name;

        var newPAcc = true;
        for (var a = 0; a < this.selectedProjectAccounts.length; a++) {
            if (this.selectedProjectAccounts[a].Id == selectedRecordId) {
                newPAcc = false;
            }
        }
        if (newPAcc) {
            if (dataName == 'fromSearchBar') {
                this.selectedProjectAccounts.push(this.recordsListOnSearch[selectedRecordIndex]);
                for (var acc = 0; acc < this.projectAccList.length; acc++) {
                    if (this.projectAccList[acc].Id == selectedRecordId) {
                        this.projectAccList[acc].isSelected = true;
                        break;
                    }
                }
            } else if (dataName == 'fromProjectAccountList') {
                this.projectAccList[selectedRecordIndex].isSelected = true;
                this.selectedProjectAccounts.push(this.projectAccList[selectedRecordIndex]);
            }
        }
        this.recordsPresent = false;
        this.resetSearchBar();
    }

    onRemovingSelected(event) {
        console.log('onRemovingSelected');
        const selectedRecordId = event.currentTarget.dataset.id;
        this.projectAccList.forEach((projAcc, index) => {
            if (projAcc.Id === selectedRecordId) {
                projAcc.isSelected = false;
                this.selectedProjectAccounts = this.selectedProjectAccounts.filter(selectedAcc => selectedAcc.Id !== selectedRecordId);
            }
        });
        console.log('selectedProjectAccounts after splice--> ', JSON.stringify(this.selectedProjectAccounts));
        if (this.selectedProjectAccounts.length == 0) {
            this.massSelect = 'Add All';
        }
    }

    handleMassSelect() {
        if (this.massSelect === 'Add All') {
            this.massSelect = 'Remove All';

            this.projectAccList.forEach(pa => {
                if (!this.selectedProjectAccounts.some(selectedAcc => selectedAcc.Id === pa.Id)) {
                    pa.isSelected = true;
                    this.selectedProjectAccounts.push(pa);
                    console.log('selectedProjectAccounts size:', this.selectedProjectAccounts.length);
                }               
            });
        } else {
            this.massSelect = 'Add All';
            this.projectAccList.forEach(pa => pa.isSelected = false);
            this.selectedProjectAccounts = [];
        }
    }   

    handleRangeChange(event) {
        const field = event.target.name;
        if (field === 'projectAccNoFrom') {
            this.projectAccNoFrom = event.target.value.trim();
        } else if (field === 'projectAccNoTo') {
            this.projectAccNoTo = event.target.value.trim();
        }
        console.log('Range filter From-->' + this.projectAccNoFrom);
        console.log('Range filter To-->' + this.projectAccNoTo);
        if(this.projectAccNoFrom == '' || this.projectAccNoTo == '') {
            this.massSelect = 'Add All';
        }
        this.getProjectAccountsList();
    }      

    createCaseAndShowToast() {
        this.showSpinner = true;
        for (let pa of this.selectedProjectAccounts) {
            if (!pa.Project__r.Service_Contract__c) {
                this.servicecon = false;
                this.showToast('Error!', 'Please choose a Service Contract in the Project!', 'error');
                this.showSpinner = false;
                return;
            }
        }
        if (this.selectedProjectAccounts && this.selectedProjectAccounts.length > 0) {
            getServiceContract({ recordId: this.recordId })
                .then((result) => {
                    if (!result) {
                        this.showToast('Error!', 'Please choose a Visit Order in the Service Contract!', 'error');
                        this.showSpinner = false;
                    } else {
                        getServiceContractVisitOrder({ recordId: this.recordId, selectedProjAccList: this.selectedProjectAccounts })
                            .then((result) => {
                                console.log('result-->'+JSON.stringify(result));
                                if (result === false) {
                                    this.showToast('Error!', 'The selected project account visit date does not match the service contract visit order.', 'error');
                                    this.showSpinner = false;
                                } else {
                                    createCaseAndWorkorderRecords({ recordId: this.recordId, projAccList: this.selectedProjectAccounts })
                                        .then(() => {
                                            this.massSelect = 'Add All';
                                            if (this.selectedProjectAccounts.length > 30) {
                                                this.showToast('Success!', 'Cases will be created in few seconds!.', 'success');
                                                this.getProjectAccountsList();
                                                this.selectedProjectAccounts = [];
                                            } else {
                                                this.showToast('Success!', 'Cases created successfully.', 'success');
                                                setTimeout(() => {
                                                    this.getProjectAccountsList();
                                                    this.selectedProjectAccounts = [];
                                                }, 3000);
                                            }
                                        })
                                        .catch((error) => {
                                            this.showToast('Error!', error.body.message, 'error');
                                            this.showSpinner = false;
                                        });
                                }
                            })
                            .catch((error) => {
                                this.showToast('Error!', error.body.message, 'error');
                                this.showSpinner = false;
                            });
                    }
                })
                .catch((error) => {
                    this.showToast('Error!', error.body.message, 'error');
                    this.showSpinner = false;
                });
        } else {
            this.showToast('Error!', 'Please select a Project Account!', 'error');
            this.showSpinner = false;
        }
    }

    get isButtonDisabled() {
        return !this.showSuccessIcon;
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    nullErrorToast() {
        this.showToast('Error!', 'Project Accounts are not available for this account!', 'error');
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}