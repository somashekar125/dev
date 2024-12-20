import { LightningElement, api, track, wire } from 'lwc';
import getChildAccounts from '@salesforce/apex/CreateProjectAccounts.getChildAccounts';
import getExistingProjectAccounts from '@salesforce/apex/CreateProjectAccounts.getExistingProjectAccounts';
import { CurrentPageReference } from 'lightning/navigation';
import projectAccountCreation from '@salesforce/apex/CreateProjectAccounts.projectAccountCreation';
import deleteProjectAccount from '@salesforce/apex/CreateProjectAccounts.deleteProjectAccount';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import searchAccounts from '@salesforce/apex/CreateProjectAccounts.searchAccounts';
import searchProjectAccounts from '@salesforce/apex/CreateProjectAccounts.searchProjectAccounts';
import processCSVFile from '@salesforce/apex/CreateProjectAccounts.processCSVFile';
import { CloseActionScreenEvent } from 'lightning/actions';
import { RefreshEvent } from 'lightning/refresh';

export default class CreateProjectAccounts extends LightningElement {
    @api recordId;
    @track objectName = 'Account';
    @track accountList = [];
    @track selectedAccounts = [];
    @track massSelect = 'Add All';
    @track searchKey = '';
    @track recordsListOnSearch = [];
    @track recordsPresent = false;
    @track projAcctList = [];
    @track selectedProjAccountIds = [];
    @track massSelect2 = 'Add All';
    @track switchLayout = false;
    @track showSpinner = false;
    @track fileContent;
    @track fileName;
    @track isModalOpen = false;
    @track uploadProgress = 0;
    @track fileSize = 0;
    @track showProgress = false;
    @track showSuccessIcon = false;
    opacity = '';

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
            this.showSpinner = true;
            this.retrieveChildAccounts();
            this.retrieveExistingProjectAccounts();
        }
    }

    retrieveChildAccounts() {
        var index = 0;
        getChildAccounts({ projectId: this.recordId })
            .then((result) => {
                this.accountList = result || [];
                for (let acc of this.accountList) {
                    acc.serialNo1 = index + 1;
                    index++;
                }
                this.showSpinner = false;
            })
            .catch((error) => {
                console.error('Error retrieving project list:', error);
                this.showSpinner = false;
            });
    }

    retrieveExistingProjectAccounts() {
        getExistingProjectAccounts({ projectId: this.recordId })
        .then((result) => {
            this.projAcctList = result;
            console.log('this.projAcctList --> ', JSON.stringify(this.projAcctList));
            console.log('this.accountList.length-->'+this.accountList.length);
            this.childAccountListCheck();
            if(this.accountList.length == 0 && this.projAcctList.length == 0) this.nullErrorToast();
            this.showSpinner = false;
        })
        .catch((error) => {
            console.error('Error retrieving project accounts:', error);
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
            if(!this.switchLayout){
                searchAccounts({ searchKey: this.searchKey, projectId: this.recordId })
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
                searchProjectAccounts({ searchKey: this.searchKey, projectId: this.recordId })
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
            }
        } else {
            this.recordsListOnSearch = [];
            this.recordsPresent = false;
        }
    }

    onRecordSelection(event) {
        console.log('OnRecordSelection');
        const selectedRecordIndex = event.currentTarget.dataset.index;
        const selectedRecordId = event.currentTarget.dataset.id;
        var dataName = event.currentTarget.dataset.name;

        console.log('selectedRecordIndex --> ', selectedRecordIndex);
        console.log('selectedRecordId --> ', selectedRecordId);
        console.log('dataName --> ', dataName);
        if(!this.switchLayout){
            var newAcc = true;
            for (var a = 0; a < this.selectedAccounts.length; a++) {
                if (this.selectedAccounts[a].Id == selectedRecordId) {
                    newAcc = false;
                }
            }
            if(newAcc) {
                if(dataName == 'fromSearchBar') {
                    this.selectedAccounts.push(this.recordsListOnSearch[selectedRecordIndex]);
                    for(var acc=0; acc<this.accountList.length;acc++) {
                        if(this.accountList[acc].Id == selectedRecordId) {
                            this.accountList[acc].isSelected = true;
                            break;
                        }
                    }
                } else if(dataName == 'fromAccountList'){
                    this.accountList[selectedRecordIndex].isSelected = true;
                    this.selectedAccounts.push(this.accountList[selectedRecordIndex]);
                }
                console.log('selectedAccounts --> ', JSON.stringify(this.selectedAccounts));
            }
            this.recordsPresent = false;
            var searchKey = this.template.querySelector('[data-name="searchProjAccInput"]');
            console.log('searchKey value-> ' + searchKey.value);
            searchKey.value = '';
            this.searchKey = '';
        } else {
            var newAcc = true;
            for (var a = 0; a < this.selectedProjAccountIds.length; a++) {
                if (this.selectedProjAccountIds[a] == selectedRecordId) {
                    newAcc = false;
                }
            }
            if(newAcc) {
                if(dataName == 'fromSearchBar') {
                    this.selectedProjAccountIds.push(this.recordsListOnSearch[selectedRecordIndex].Id);
                    for(var acc=0; acc<this.projAcctList.length; acc++) {
                        if(this.projAcctList[acc].Id == selectedRecordId) {
                            this.projAcctList[acc].isSelectedToDelete = true;
                            break;
                        }
                    }
                } else if(dataName == 'fromProjAccountList'){
                    console.log('test');
                    this.projAcctList[selectedRecordIndex].isSelectedToDelete = true;
                    this.selectedProjAccountIds.push(this.projAcctList[selectedRecordIndex].Id);
                }
                console.log('selectedProjAccountIds --> '+ JSON.stringify(this.selectedProjAccountIds));
            }
            this.resetSearchBar();
        }
        
    }
    
    onRemovingSelected(event) {
        console.log('onRemovingSelected');
        if(!this.switchLayout){
            const selectedRecordId = event.currentTarget.dataset.id;
            this.accountList.forEach((acc, index) => {
                if (acc.Id === selectedRecordId) {
                    acc.isSelected = false;
                    this.selectedAccounts = this.selectedAccounts.filter(selectedAcc => selectedAcc.Id !== selectedRecordId);
                }
            });
            console.log('selectedAccounts after splice--> ', JSON.stringify(this.selectedAccounts));
            if(this.selectedAccounts.length == 0) {
                this.massSelect = 'Add All';
            }
        }
        else{
            const selectedRecordId = event.currentTarget.dataset.id;
            this.projAcctList.forEach((projAcc, index) => {
                if (projAcc.Id === selectedRecordId) {
                    projAcc.isSelectedToDelete = false;
                    this.selectedProjAccountIds = this.selectedProjAccountIds.filter(selectedProjAcc => selectedProjAcc !== selectedRecordId);
                }
            });
            console.log('selectedProjAccountIds after splice--> ', JSON.stringify(this.selectedProjAccountIds));
            if(this.selectedAccounts.length == 0) {
                this.massSelect2 = 'Add All';
            }
        }
       
    }

    handleMassSelect() {
        this.showSpinner = true;
        if (this.massSelect === 'Add All') {
            this.massSelect = 'Remove All';
            this.accountList.forEach(acc => {
                acc.isSelected = true;
                this.selectedAccounts.push(acc);
            });
            console.log('SelectedAccounts size:', this.selectedAccounts.length);
        } else {
            this.massSelect = 'Add All';
            this.accountList.forEach(acc => acc.isSelected = false);
            this.selectedAccounts = [];
        }
        this.showSpinner = false;
    }

    handleMassDelete() {
        this.showSpinner = true;
        console.log('selectedProjAccountIds size before:', this.selectedProjAccountIds.length);
        console.log('massSelect2 ', this.massSelect2);
        if (this.massSelect2 == 'Add All') {
            this.massSelect2 = 'Remove All';
            for(var pa=0; pa < this.projAcctList.length; pa++) {
                this.projAcctList[pa].isSelectedToDelete = true;
                this.selectedProjAccountIds.push(this.projAcctList[pa].Id);
            }
            console.log('selectedProjAccountIds size after:', this.selectedProjAccountIds.length);
        } else {
            this.massSelect2 = 'Add All';
            for(var pa=0; pa<this.projAcctList.length; pa++) {
                this.projAcctList[pa].isSelectedToDelete = false;
            }
            this.selectedProjAccountIds = [];
        }
        this.showSpinner = false;
    }

    showDeleteProjAcctLayout(event) {
        debugger;
        var index = 0;
        this.projectAccountListCheck();
        if(this.projAcctList.length != 0) {
            for (let pa of this.projAcctList) {
                pa.serialNo2 = index + 1;
                index++;
            }
            this.switchLayout = true;
        }
        this.resetSearchBar();
    }

    showCreateProjAcctLayout(event) {
        this.childAccountListCheck();
        if(this.accountList.length != 0) this.switchLayout = false;
        this.resetSearchBar();
    }

    projAccCreation() {
        this.showSpinner = true;
        console.log('selectedAccounts--> ', JSON.stringify(this.selectedAccounts));
        var index = 0;
        if (this.selectedAccounts.length === 0) {
            const errorToast = new ShowToastEvent({
                title: 'Error!',
                message: 'Please select at least one account!',
                variant: 'error',
                mode: 'dismissable'
            });
            this.dispatchEvent(errorToast);
            this.showSpinner = false;
        } else {
            projectAccountCreation({ accountList: this.selectedAccounts, projectId: this.recordId })
            .then((result) => {
                const successToast = new ShowToastEvent({
                    title: 'Success!',
                    message: 'Project account(s) created!',
                    variant: 'success',
                    mode: 'dismissable'
                });
                this.dispatchEvent(successToast);
                this.showSpinner = false;
                this.accountList = result;
                for (let acc of this.accountList) {
                    acc.serialNo1 = index + 1;
                    index++;
                }
                this.selectedAccounts = [];
                this.massSelect = 'Add All';
                this.retrieveExistingProjectAccounts();
                setTimeout(() => {
                    this.childAccountListCheck();
                }, 600);
                this.resetSearchBar();
                this.dispatchEvent(new RefreshEvent());
            })
            .catch((error) => {
                console.error('Error creating project accounts : ', error);
            });
        }
    }

    projAccDeletion() {
        this.showSpinner = true;
        var index = 0;
        console.log('projAcctList--> ', JSON.stringify(this.selectedProjAccountIds));
        if (this.selectedProjAccountIds.length === 0) {
            const errorToast = new ShowToastEvent({
                title: 'Error!',
                message: 'Please select at least one account!',
                variant: 'error',
                mode: 'dismissable'
            });
            this.dispatchEvent(errorToast);
            this.showSpinner = false;
        } else {
            deleteProjectAccount({projectId: this.recordId, projectAccountIds: this.selectedProjAccountIds})
            .then((result) => {
                const successToast = new ShowToastEvent({
                    title: 'Success!',
                    message: 'Project account(s) deleted!',
                    variant: 'success',
                    mode: 'dismissable'
                });
                this.dispatchEvent(successToast);
                this.showSpinner = false;
                this.projAcctList = result;
                for (let pa of this.projAcctList) {
                    pa.serialNo2 = index + 1;
                    index++;
                }
                this.selectedProjAccountIds = [];
                this.massSelect2 = 'Add All';
                this.retrieveChildAccounts();
                setTimeout(() => {
                    this.projectAccountListCheck();
                }, 600);
                this.resetSearchBar();
                this.dispatchEvent(new RefreshEvent());
            })
            .catch((error) => {
                console.error('Error fetching project accounts : ', error);
            });
        }
    }    

    projectAccountListCheck(){
        console.log('this.projAcctList.length-> ' + this.projAcctList.length);
        console.log('this.accountList.length-> ' + this.accountList.length);
        if(this.projAcctList.length == 0){
            const errorToast = new ShowToastEvent({
                title: 'Warning!',
                message: 'No existing project accounts found!',
                variant: 'warning',
                mode: 'dismissable'
            });
            this.dispatchEvent(errorToast);
            this.switchLayout = false;
        }
    }

    childAccountListCheck(){
        console.log('this.projAcctList.length--> ' + this.projAcctList.length);
        console.log('this.accountList.length--> ' + this.accountList.length);
        var index = 0;
        if(this.accountList.length == 0 && this.projAcctList.length != 0){
            for (let pa of this.projAcctList) {
                pa.serialNo2 = index + 1;
                index++;
            }
            const errorToast = new ShowToastEvent({
                title: 'Warning!',
                message: 'No accounts found!',
                variant: 'warning',
                mode: 'dismissable'
            });
            this.dispatchEvent(errorToast);
            this.switchLayout = true;
        }
    }

    resetSearchBar(){
        if(this.switchLayout) {
            this.objectName = 'Project Account';
        } else {
            this.objectName = 'Account';
        }
        this.recordsPresent = false;
        var searchKey = this.template.querySelector('[data-name="searchAccInput"]');
        searchKey.value = '';
        this.searchKey = '';
        this.recordsListOnSearch = [];
    }

    handleFilesChange(event) {
        const files = event.target.files;
        if (files && files.length > 0) {
            const file = files[0];
            const reader = new FileReader();
            reader.onload = (e) => {
                const fileContents = e.target.result;
                this.fileContent = fileContents;
                this.fileName = file.name;
                this.isModalOpen = true;
                this.uploadProgress = 0;
                this.fileSize = this.formatFileSize(file.size);
                this.showSpinner = false;
                this.showProgress = true;
                this.opacity = 'opacity:0.4';
                let interval = setInterval(() => {
                    if (this.uploadProgress >= 100) {
                        clearInterval(interval);
                        this.uploadProgress = 100;
                        this.showSuccessIcon = true;

                    } else {
                        this.uploadProgress += 10;
                    }
                }, 200);
            };
            reader.onerror = (event) => {
                console.error('FileReader error:', event.target.error);
            };
            reader.readAsText(file);
        }
    }
    
    formatFileSize(bytes) {
        if (bytes < 1024) return bytes + ' B';
        else if (bytes < 1048576) return (bytes / 1024).toFixed(1) + ' KB';
        else return (bytes / 1048576).toFixed(1) + ' MB';
    }
    
    uploadFile() {
        if (this.fileName && this.fileContent) {
            this.showSpinner = true;
            this.showProgress = true;
            processCSVFile({ projectId: this.recordId, fileContents: this.fileContent })
                .then((result) => {
                    console.log('result-->' + JSON.stringify(result));
                    if (result === 'Success') {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                message: 'CSV file processed successfully',
                                variant: 'success'
                            })
                        );
                        this.showSpinner = false;
                        window.history.back();
                    } else {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: result,
                                variant: 'error'
                            })
                        );
                        this.showSpinner = false;
                    }
                }) 
                .catch((error) => {
                    this.showProgress = false;
                    this.showSuccessIcon = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Error processing CSV file: ' + (error.body ? error.body.message : error.message),
                            variant: 'error'
                        })
                    );
                    this.showSpinner = false;
                    window.history.back();
                });
        } else {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'No file selected for upload',
                    variant: 'error'
                })
            );
            this.showSpinner = false;
        }
    }
    
    closeModal() {
        this.isModalOpen = false;
        this.fileName = '';
        this.fileContent = '';
        this.uploadProgress = 0;
        this.showProgress = false;
        this.opacity = '';
        this.showSuccessIcon = false;
    }    

    nullErrorToast(){
        const errorToast = new ShowToastEvent({
            title: 'Error!',
            message: 'No accounts found to create  or delete project account!',
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(errorToast);
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showTooltip(event) {
        const tooltip = event.currentTarget.nextElementSibling;
        tooltip.classList.remove('slds-hide');
    }
    
    hideTooltip(event) {
        const tooltip = event.currentTarget.nextElementSibling;
        tooltip.classList.add('slds-hide');
    }
}