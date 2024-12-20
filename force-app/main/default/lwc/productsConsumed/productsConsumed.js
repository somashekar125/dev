import { LightningElement, wire, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import checkWOOwnerId from '@salesforce/apex/ProductsConsumed.checkWOOwnerId';
import retrieveWorkOrder from '@salesforce/apex/ProductsConsumed.retrieveWorkOrder';
import getWOLIs from '@salesforce/apex/ProductsConsumed.getWOLIs';
import consumeProducts from '@salesforce/apex/ProductsConsumed.consumeProducts';
import getOpenOnsiteWOs from '@salesforce/apex/ProductsConsumed.getOpenOnsiteWOs';
import getVanStock from '@salesforce/apex/ProductsConsumed.getVanStock';
import retriveSearhedProducts from '@salesforce/apex/ProductsConsumed.retriveSearhedProducts';
import retriveSearhedWOs from '@salesforce/apex/ProductsConsumed.retriveSearhedWOs';
//import markingWOReadyForInvoice from '@salesforce/apex/ProductsConsumed.markingWOReadyForInvoice';
//import checkForConsumptionWO from '@salesforce/apex/ProductsConsumed.checkForConsumptionWO';

export default class ProductsConsumed extends LightningElement {
    @api recordId;
    @track workOrderId = '';
    @track woRec = {};
    @track fieldTechOwnerExist = false;
    @track caseId = '';
    @track woRecordPage = false;
    @track showSpinner = false;
    @track searchKey = '';
    @track workOrderIndex = '';
    @track woList = [];
    @track showAllWOs = false;
    @track woliList = [];
    @track woExists = false;
    @track woliExists = false;
    @track showBackButton = false;
    @track refreshButtonTitle = 'RefreshWOs';
    @track consumePartsList = [];
    @track consumingPartsExists = false;
    @track workordernumber = '';
    @track showVanParts = false;
    @track vanPartsList = [];
    @track buttonLabel = 'Show Van Stock';
    @track woliSection = false;
    @track recordsListOnSearch = [];
    @track recordsPresent = false;
    @track showConfirmationPopUp = false;
    @track woRecordsListOnSearch = [];
    @track woRecordsPresent = false;
    @track woDataName = '';
    @track showCompleteConsumptionPopUp = false;
    @track allConsumptionDone = false;
    @track disbaleAllConsumptionDoneBtn = false;
    @track showListOfWOsWithSearch = false;
    @track showSpinnerOnRefresh = false;

    connectedCallback() {
        console.log('---connectedCallback---');
        console.log('this.recordId-> ' + this.recordId);
        if(this.recordId != null && this.recordId != 'Undefined'){
            this.workOrderId = this.recordId;
            this.showAllWOs = false;
            this.woRecordPage = true;
            this.checkOwnerId();
            this.getWorkOrder();
            this.searchKey = '';
            this.woRecordsPresent = false;
        } else {
            this.fieldTechOwnerExist = true;
            this.getAllWOs();
            this.woRecordPage = false;
        }
        this.disablePullToRefresh();
    }

    checkOwnerId(event){
        checkWOOwnerId({workorderId: this.workOrderId })
            .then((result) => {
                if (result == true) {
                    this.fieldTechOwnerExist = true;
                } else {
                    this.fieldTechOwnerExist = false;
                }
                console.log('fieldTechOwnerExist-> ' + this.fieldTechOwnerExist);
            })
            .catch((error) => {
                console.log('checkOwnerId error-> ' + JSON.stringify(error));
            });
    }

    getWorkOrder(event){
        this.woliSection = true;
        this.showAllWOs = false;
        if(this.woRecordPage == false){
            this.showBackButton = true;
        }
        retrieveWorkOrder({workOrderId : this.workOrderId})
            .then((result) =>{
                if(result != null){
                    this.woRec = result;
                    this.workordernumber = this.woRec.WorkOrderNumber;
                    this.caseId = this.woRec.CaseId;
                    console.log('this.woRec-> ' + JSON.stringify(this.woRec));
                    this.findWOLIs();
                    this.getVanParts();
                }
            })
    }

    getAllWOs(event){
        this.showSpinnerOnRefresh = true;
        this.fieldTechOwnerExist = true;
        this.showListOfWOsWithSearch = true;
        this.woRecordPage = false;
        this.searchKey = '';
        this.recordsListOnSearch = [];
        this.woRecordsPresent = false;
        console.log('---getAllWOs---');
        getOpenOnsiteWOs({})
            .then((result) =>{
                this.woList = result;
                if(this.woList.length > 0 ){
                    this.showAllWOs = true;
                    this.woExists = true;
                } else {
                    this.showAllWOs = false;
                    this.woExists = false;
                }
                this.woList.forEach((item, index) => {
                    item.woSerialNo = index + 1;
                });
                console.log('this.woList size-> ' + this.woList.length);
                this.showSpinnerOnRefresh = false;
            })
            .catch((error) => {
                console.log('getAllWOs error-> ' + JSON.stringify(error));
                this.showSpinnerOnRefresh = false;
            });
    }

    getVanParts(event){
        console.log('--getVanParts--');
        this.showSpinnerOnRefresh = true;
        getVanStock({woRec : this.woRec})
            .then((result) =>{
                if(result.length == 0){
                    this.isDisabled = true;
                } else {
                    this.isDisabled = false;
                }
                this.vanPartsList = result;
                this.vanPartsList.forEach((item, index) => {
                    item.vanSerialNo = index + 1;
                    item.isSelected = false;
                    item.isVanPart = true;
                    item.originalQty = item.QuantityOnHand;
                });
                console.log('this.vanPartsList size-> ' + this.vanPartsList.length);
                for (var vp = 0; vp < this.consumePartsList.length; vp++) {
                    if(this.consumePartsList[vp].isVanPart){
                        for (var p = 0; p < this.vanPartsList.length; p++) {
                            if (this.vanPartsList[p].Product2Id == this.consumePartsList[vp].Product2Id){
                                this.vanPartsList[p].isSelected = true;
                            }
                        }
                    } else {
                        for (var p = 0; p < this.vanPartsList.length; p++) {
                            if (this.vanPartsList[p].Product2Id == this.consumePartsList[vp].PricebookEntry.Product2Id){
                                this.vanPartsList[p].isSelected = true;
                            }
                        }
                    }
                }
                for (var vp = 0; vp < this.woliList.length; vp++) {
                    if(this.woliList[vp].isVanPart){
                        for (var p = 0; p < this.vanPartsList.length; p++) {
                            if (this.vanPartsList[p].Product2Id == this.woliList[vp].Product2Id){
                                this.vanPartsList[p].isSelected = true;
                            }
                        }
                    } else {
                        for (var p = 0; p < this.vanPartsList.length; p++) {
                            if (this.vanPartsList[p].Product2Id == this.woliList[vp].PricebookEntry.Product2Id){
                                this.vanPartsList[p].isSelected = true;
                            }
                        }
                    }
                }
                this.showSpinnerOnRefresh = false;
            })
            .catch((error) => {
                console.log('getVanParts error-> ' + JSON.stringify(error));
                this.showSpinnerOnRefresh = false;
                this.isDisabled = true;
            });
    }

    handleShowAllProducts(event){
        console.log('handleShowAllProducts');
        if(this.showVanParts == false){
            this.buttonLabel = 'Hide Van Stock';
            this.showVanParts = true;
        } else {
            this.buttonLabel = 'Show Van Stock';
            this.showVanParts = false;
        }
    }

    refreshLists(event){
        if(this.allConsumptionDone == false){
            var title = event.currentTarget.title;
            console.log('title-> ' + title);
            if(title == 'RefreshWOs' && this.woRecordPage == false){
                this.getAllWOs();
            } else if(title == 'RefreshWOLIs'){
                this.findWOLIs();
                this.getVanParts();
            }
        }
    }

    goBackToWOList(event){
        this.showBackButton = false;
        this.refreshButtonTitle = 'RefreshWOs';
        this.woliExists = false;
        this.woliSection = false;
        this.buttonLabel = 'Show Van Stock';
        this.showVanParts = false;
        this.workOrderIndex = '';
        this.workOrderId = '';
        this.woDataName = '';
        this.searchKey = '';
        this.recordsListOnSearch = [];
        this.woRecordsPresent = false;
        this.woliList = [];
        this.consumePartsList = [];
        this.vanPartsList = [];
        this.allConsumptionDone = false;
        if(this.woRecordPage == false){
            this.getAllWOs();
        }
    }

    getWOLIsAndVanParts(event){
        console.log('--getWOLIsAndVanParts--');
        if(this.woRecordPage == false){
            this.workOrderId = event.currentTarget.dataset.id;
            this.workOrderIndex = event.currentTarget.dataset.index;
            this.woDataName = event.currentTarget.dataset.name;
            if(this.woDataName == 'listedWOs'){
                this.workordernumber = this.woList[this.workOrderIndex].WorkOrderNumber;
            } else if (this.woDataName == 'searhedWOs'){
                this.workordernumber = this.woRecordsListOnSearch[this.workOrderIndex].WorkOrderNumber;
            }
            this.getWorkOrder();
        }
        console.log('getWOLIsAndVanParts workOrderId -> ' + this.workOrderId);
        console.log('getWOLIsAndVanParts workOrderIndex -> ' + this.workOrderIndex);
        console.log('getWOLIsAndVanParts woDataName-> ' + this.woDataName);
        this.searchKey = '';
        this.woRecordsPresent = false;
    }

    /*checkForConsumptionPartWO(event){
        checkForConsumptionWO({caseId : this.caseId})
            .then((result) => {
                if(result == true){
                    this.disbaleAllConsumptionDoneBtn = true;
                    this.allConsumptionDone = true;
                } else {
                    this.disbaleAllConsumptionDoneBtn = false;
                }
            })
            .catch((error) => {
                console.log('checkForConsumptionPartWO error-> ' + JSON.stringify(error));
            });
    }*/

    findWOLIs(event){
        console.log('--findWOLIs--');
        this.woliSection = true;
        this.woliExists = false;
        this.showAllWOs = false;
        this.recordsPresent = false;
        this.searchKey = '';
        this.recordsListOnSearch = [];
        if(this.woRecordPage == false){
            this.showBackButton = true;
        }
        this.refreshButtonTitle = 'RefreshWOLIs';
        this.consumePartsList = [];
        for(var prod = 0; prod < this.woliList.length; prod++){
            if(this.woliList[prod].isSelected == true){
                this.consumePartsList.push(this.woliList[prod]);
            }
        }
        this.woliList = [];
        this.woList.forEach((item, index) => {
            if(item.Id == this.workOrderId && item.Ready_For_Invoice__c == true){
                this.allConsumptionDone = true;
                this.disbaleAllConsumptionDoneBtn = true;
            }
        });
        if(this.allConsumptionDone == false){
            getWOLIs({woRec: this.woRec })
                .then((result) => {
                    if(result.length != 0){
                        this.woliExists = true;
                        this.woliList = result;
                        console.log('this.woliList-> ' + JSON.stringify(this.woliList));
                        console.log('this.woliExists-> ' + this.woliExists);
                        this.woliList.forEach((item, index) => {
                            item.woliSerialNo = index + 1;
                            item.isSelected = true;
                            item.isVanPart = false;
                            item.originalQty = item.Quantity;
                        });
                        for (var vp = 0; vp < this.consumePartsList.length; vp++) {
                            var newProd = true;
                            if(this.consumePartsList[vp].isVanPart){
                                for (var p = 0; p < this.woliList.length; p++) {
                                    if(this.woliList[p].isVanPart){
                                        if (this.woliList[p].Product2Id == this.consumePartsList[vp].Product2Id){
                                            newProd = false;
                                            this.woliList[p].QuantityOnHand = this.consumePartsList[vp].QuantityOnHand;
                                        }
                                    } else {
                                        if (this.woliList[p].PricebookEntry.Product2Id == this.consumePartsList[vp].Product2Id) {
                                            newProd = false;
                                            this.woliList[p].Quantity = this.consumePartsList[vp].QuantityOnHand;
                                        }
                                        
                                    }
                                }
                            } else {
                                for (var p = 0; p < this.woliList.length; p++) {
                                    if(this.woliList[p].isVanPart){
                                        if (this.woliList[p].Product2Id == this.consumePartsList[vp].PricebookEntry.Product2Id){
                                            newProd = false;
                                            this.woliList[p].QuantityOnHand = this.consumePartsList[vp].Quantity;
                                        }
                                    } else {
                                        if (this.woliList[p].PricebookEntry.Product2Id == this.consumePartsList[vp].PricebookEntry.Product2Id) {
                                            newProd = false;
                                            this.woliList[p].Quantity = this.consumePartsList[vp].Quantity;
                                        }
                                        
                                    }
                                }
                            }
                            if(newProd){
                                this.woliList.push(this.consumePartsList[vp]);
                            }
                        }
                        for (var vp = 0; vp < this.woliList.length; vp++) {
                            if(this.woliList[vp].isVanPart){
                                for (var p = 0; p < this.vanPartsList.length; p++) {
                                    if (this.vanPartsList[p].Product2Id == this.woliList[vp].Product2Id){
                                        this.vanPartsList[p].isSelected = true;
                                    }
                                }
                            } else {
                                for (var p = 0; p < this.vanPartsList.length; p++) {
                                    if (this.vanPartsList[p].Product2Id == this.woliList[vp].PricebookEntry.Product2Id){
                                        this.vanPartsList[p].isSelected = true;
                                    }
                                }
                            }
                        }
                    } else {
                        if(this.consumePartsList.length != 0){
                            this.woliList = this.consumePartsList;
                            this.woliExists = true;
                            this.woliList.forEach((item, index) => {
                                item.woliSerialNo = index + 1;
                                item.isSelected = true;
                            });
                            for (var vp = 0; vp < this.woliList.length; vp++) {
                                if(this.woliList[vp].isVanPart){
                                    for (var p = 0; p < this.vanPartsList.length; p++) {
                                        if (this.vanPartsList[p].Product2Id == this.woliList[vp].Product2Id){
                                            this.vanPartsList[p].isSelected = true;
                                        }
                                    }
                                } else {
                                    for (var p = 0; p < this.vanPartsList.length; p++) {
                                        if (this.vanPartsList[p].Product2Id == this.woliList[vp].PricebookEntry.Product2Id){
                                            this.vanPartsList[p].isSelected = true;
                                        }
                                    }
                                }
                            }
                        } else {
                            this.woliExists = false;
                        }
                    }
                })
                .catch((error) => {
                    console.log('findWOLIs error-> ' + JSON.stringify(error));
                });
        }
    }

    handleKeyChangeForWO(event) {
        console.log('handleKeyChangeForWO---');
        this.searchKey = event.currentTarget.value;

        if (this.searchKey !== '' && this.searchKey !== null) {
            console.log('handleKeyChangeForWO this.searchKey-> ' + this.searchKey);
            retriveSearhedWOs({ searchKey: this.searchKey })
            .then((result) => {
                if (result.length === 0) {
                    this.woRecordsListOnSearch = [];
                    this.woRecordsPresent = false;
                } else {
                    this.woRecordsPresent = true;
                    this.woRecordsListOnSearch = result;
                    console.log('Searched WOs Retrieved-> ' + JSON.stringify(result));
                }
            })
            .catch((error) => {
                console.log('handleKeyChangeForWO error-> ' + JSON.stringify(error));
                this.woRecordsListOnSearch = [];
            });
        } else {
            this.woRecordsListOnSearch = [];
            this.woRecordsPresent = false;
        }
    }

    handleKeyChange(event) {
        console.log('handleKeyChange---');
        this.searchKey = event.currentTarget.value;
        if(this.vanPartsList.length > 0){
            this.showVanParts = true;
            this.isDisabled = false;
        } else {
            this.showVanParts = false;
            this.isDisabled = true;
        }
        if (this.searchKey !== '' && this.searchKey !== null) {
            console.log('handleKeyChange this.searchKey-> ' + this.searchKey);
            console.log('this.woRec-> ' + JSON.stringify(this.woRec));
            retriveSearhedProducts({ searchKey: this.searchKey, woRec: this.woRec })
            .then((result) => {
                if (result.length === 0) {
                    this.recordsListOnSearch = [];
                    this.recordsPresent = false;
                } else {
                    this.recordsPresent = true;
                    this.recordsListOnSearch = result;
                    console.log('Searched Product Retrieved-> ' + JSON.stringify(result));
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
    
    onRecordSelection(event){
        console.log('---onRecordSelection---');
        var selectedProdId = event.currentTarget.dataset.id;
        var selectedRecordIndex = event.currentTarget.dataset.index;
        var dataName = event.currentTarget.dataset.name;
        console.log('dataName-> ' + dataName);
        var newProd = true;
        for (var p = 0; p < this.woliList.length; p++) {
            if(this.woliList[p].isVanPart){
                if (this.woliList[p].Product2Id == selectedProdId){
                    newProd = false;
                    console.log('Existing Van Product');
                }
            } else {
                if(dataName == 'consumePart'){
                    if (this.woliList[p].PricebookEntry.Product2Id == selectedProdId && this.woliList[selectedRecordIndex].isSelected == true) {
                        newProd = false;
                        console.log('Existing woli Product');
                    }
                } else {
                    if (this.woliList[p].PricebookEntry.Product2Id == selectedProdId) {
                        newProd = false;
                        console.log('Existing woli Product');
                    }
                }
            }
        }
        if(!newProd){
            const existingProd = new ShowToastEvent({
                title: 'warning',
                message: 'Product is already added!',
                variant: 'warning',
                mode: 'dismissable'
            });
            this.dispatchEvent(existingProd);
        }
        if(newProd){
            this.woliExists = true;
            if(dataName == 'consumePart'){
                this.woliList[selectedRecordIndex].isSelected = true;
                this.woliList[selectedRecordIndex].isVanPart = false;
                for(var vprod = 0; vprod < this.vanPartsList.length; vprod++){
                    if(this.vanPartsList[vprod].Product2Id != selectedProdId) continue;
                    this.vanPartsList[vprod].isSelected = true;
                }
            } else if(dataName == 'consumeVanPart'){
                this.vanPartsList[selectedRecordIndex].isVanPart = true;
                this.vanPartsList[selectedRecordIndex].isSelected = true;
                this.vanPartsList[selectedRecordIndex].QuantityOnHand = 1;
                this.woliList.push(this.vanPartsList[selectedRecordIndex]);
                
            } else if(dataName == 'searhedProducts'){
                this.recordsListOnSearch[selectedRecordIndex].isVanPart = true;
                this.recordsListOnSearch[selectedRecordIndex].isSelected = true;
                this.recordsListOnSearch[selectedRecordIndex].QuantityOnHand = 1;
                this.woliList.push(this.recordsListOnSearch[selectedRecordIndex]);
                for(var vprod = 0; vprod < this.vanPartsList.length; vprod++){
                    if(this.vanPartsList[vprod].Product2Id != selectedProdId) continue;
                    this.vanPartsList[vprod].isSelected = true;
                }
            }
            this.consumePartsList = [];
            for(var prod = 0; prod < this.woliList.length; prod++){
                if(this.woliList[prod].isSelected == true){
                    this.consumePartsList.push(this.woliList[prod]);
                }
            }
            const addedNewProd = new ShowToastEvent({
                title: 'Success!',
                message: 'Product is added!.',
                variant: 'success',
                mode: 'dismissable'
            });
            this.dispatchEvent(addedNewProd);
        }
        this.vanPartsList.forEach((item, index) => {
            item.vanSerialNo = index + 1;
        });
        this.woliList.forEach((item, index) => {
            item.woliSerialNo = index + 1;
        });
        console.log('this.woliList-> ' + JSON.stringify(this.woliList));
        this.recordsPresent = false;
        this.searchKey = '';
        this.recordsListOnSearch = [];
        //var searchKey = this.template.querySelector('[data-name="searchProdInput"]');
        //console.log('searchKey value-> ' + searchKey.value);
        //searchKey.value = '';
    }

    onRemovingSelected(event){
        console.log('---onRemovingSelected---');
        var dataId = event.currentTarget.dataset.id;
        console.log('dataId-> ' + dataId);
        for(var prod = 0; prod < this.woliList.length; prod++){
            if(this.woliList[prod].isVanPart == true){
                if(this.woliList[prod].Product2Id == dataId){
                    this.woliList.splice(prod,1);
                    prod--;
                }
            } else if(this.woliList[prod].isVanPart == false){
                if(this.woliList[prod].PricebookEntry.Product2Id == dataId){
                    this.woliList[prod].isSelected = false;
                }
            }
        }
        for(var vprod = 0; vprod < this.vanPartsList.length; vprod++){
            if(this.vanPartsList[vprod].Product2Id != dataId) continue;
            this.vanPartsList[vprod].isSelected = false;
        }
        console.log('this.woliList.length-> ' + this.woliList.length);
        if(this.woliList.length == 0){
            this.woliExists = false;
        } else {
            this.woliExists = true;
            this.woliList.forEach((item, index) => {
                item.woliSerialNo = index + 1;
            });
        }
        this.consumePartsList = [];
        for(var prod = 0; prod < this.woliList.length; prod++){
            if(this.woliList[prod].isSelected == true){
                this.consumePartsList.push(this.woliList[prod]);
            }
        }
    }

    populateQuantity(event){
        var dataId = event.currentTarget.dataset.id;
        //var dataIndex = event.currentTarget.dataset.index;
        var dataName = event.currentTarget.dataset.name;
        var vanQty = 0;
        for(var prod = 0; prod < this.woliList.length; prod++){
            if(this.woliList[prod].isVanPart == true){
                if(this.woliList[prod].Product2Id != dataId) continue;
                for(var vprod = 0; vprod < this.vanPartsList.length; vprod++){
                    if(this.vanPartsList[vprod].Product2Id == this.woliList[prod].Product2Id){
                        vanQty = this.vanPartsList[vprod].originalQty;
                    }
                }
            } else if(this.woliList[prod].isVanPart == false){
                if(this.woliList[prod].PricebookEntry.Product2Id != dataId) continue;
                for(var vprod = 0; vprod < this.vanPartsList.length; vprod++){
                    if (this.vanPartsList[vprod].Product2Id == this.woliList[prod].PricebookEntry.Product2Id){
                        vanQty = this.vanPartsList[vprod].originalQty;
                    }
                }
            }
            console.log('vanQty-> ' + vanQty);
            console.log('dataName-> ' + dataName);
            console.log('this.woliList[prod].isVanPart-> ' + this.woliList[prod].isVanPart);
            if(this.woliList[prod].isVanPart == true){
                if(dataName == 'decreaseVanQty'){
                    if(this.woliList[prod].QuantityOnHand == 0) continue;
                    this.woliList[prod].QuantityOnHand = this.woliList[prod].QuantityOnHand - 1;
                } else if(dataName == 'increaseVanQty'){
                    if(this.woliList[prod].QuantityOnHand == vanQty) continue;
                    this.woliList[prod].QuantityOnHand = this.woliList[prod].QuantityOnHand + 1;
                }
            } else if(this.woliList[prod].isVanPart == false){
                if(dataName == 'decreaseWOLIQty'){
                    if(this.woliList[prod].Quantity == 0) continue;
                    this.woliList[prod].Quantity = this.woliList[prod].Quantity - 1;
                } else if (dataName == 'increaseWOLIQty'){
                    if(this.woliList[prod].Quantity == vanQty) continue;
                    this.woliList[prod].Quantity = this.woliList[prod].Quantity + 1;
                }
            }
        }
        console.log('this.woliList after-> ' + JSON.stringify(this.woliList));
    }

    openConfirmationPopUp(event){
        this.showConfirmationPopUp = true;
    }

    closeConfirmationPopup(event){
        this.showConfirmationPopUp = false;
    }

    openCompleteConsumptionPopUp(event){
        this.showCompleteConsumptionPopUp = true;
    }

    closeCompleteConsumptionPopup(event){
        this.showCompleteConsumptionPopUp = false;
    }

    handleSubmit(event){
        console.log('handleSubmit');
        this.showConfirmationPopUp = false;
        for(var prod = 0; prod < this.woliList.length; prod++){
            if(this.woliList[prod].isSelected == false) continue;
            this.woliList[prod].hasVanStock = false;
            for(var vprod = 0; vprod < this.vanPartsList.length; vprod++){
                if(this.woliList[prod].isVanPart){
                    if(this.woliList[prod].Product2Id == this.vanPartsList[vprod].Product2Id){
                        this.woliList[prod].hasVanStock = true;
                    }
                } else {
                    if(this.woliList[prod].PricebookEntry.Product2Id == this.vanPartsList[vprod].Product2Id){
                        this.woliList[prod].hasVanStock = true;
                    }
                }
            }
        }
        var invalidProdName = '';
        var invalidProd = false;
        for(var prod = 0; prod < this.woliList.length; prod++){
            if(this.woliList[prod].isSelected == false) continue;
            if(this.woliList[prod].hasVanStock == false){
                invalidProd = true;
                if(this.woliList[prod].isVanPart){
                    invalidProdName = this.woliList[prod].Product2.Name;
                } else {
                    invalidProdName = this.woliList[prod].PricebookEntry.Product2.Name;
                }
                break;
            }
        }
        if(invalidProd){
            var msg = '"' + invalidProdName + '" is not in Van to consume!';
            const invalidQuantity = new ShowToastEvent({
                title: 'Error',
                message: msg,
                variant: 'error',
                mode: 'dismissable'
            });
            this.dispatchEvent(invalidQuantity);
        }
        if(!invalidProd){
            var invalidQuantity = false;
            for(var prod = 0; prod < this.woliList.length; prod++){
                if(this.woliList[prod].isSelected == false) continue;
                if(this.woliList[prod].QuantityOnHand == 0 || this.woliList[prod].Quantity == 0){
                    invalidQuantity = true;
                }
            }
            if(invalidQuantity){
                const invalidQuantity = new ShowToastEvent({
                    title: 'Error',
                    message: 'Please specify valid quantity!.',
                    variant: 'error',
                    mode: 'dismissable'
                });
                this.dispatchEvent(invalidQuantity);
            }
            if(!invalidQuantity){
                var vanPartsToConsumeList = [];
                var woliPartsToConsumeList = [];
                var insufficientQty = false;
                for(var prod = 0; prod < this.woliList.length; prod++){
                    if(this.woliList[prod].isSelected == false) continue;
                    if(this.woliList[prod].isVanPart){
                        vanPartsToConsumeList.push(this.woliList[prod]);
                    } else {
                        woliPartsToConsumeList.push(this.woliList[prod]);
                    }
                    for(var vprod = 0; vprod < this.vanPartsList.length; vprod++){
                        if(this.woliList[prod].isVanPart){
                            if(this.vanPartsList[vprod].Product2Id != this.woliList[prod].Product2Id) continue;
                            if(this.vanPartsList[vprod].QuantityOnHand < this.woliList[prod].QuantityOnHand){
                                insufficientQty = true;
                            }
                        } else {
                            if(this.vanPartsList[vprod].Product2Id != this.woliList[prod].PricebookEntry.Product2Id) continue;
                            if(this.vanPartsList[vprod].QuantityOnHand < this.woliList[prod].Quantity){
                                insufficientQty = true;
                            }
                        }
                    }
                }
                console.log('handleSubmit woliPartsToConsumeList -> ' + JSON.stringify(woliPartsToConsumeList));
                console.log('handleSubmit vanPartsToConsumeList -> ' + JSON.stringify(vanPartsToConsumeList));
                if(vanPartsToConsumeList.length > 0 || woliPartsToConsumeList.length > 0){
                    if(insufficientQty){
                        const invalidQuantity = new ShowToastEvent({
                            title: 'Error',
                            message: 'Consuming quantity cannot be greater than van quantity!. ',
                            variant: 'error',
                            mode: 'dismissable'
                        });
                        this.dispatchEvent(invalidQuantity);
                    }
                    if(!insufficientQty){
                        this.showSpinner = true;
                        consumeProducts({woRec : this.woRec, woliConsumePartsList : woliPartsToConsumeList, vanPartsToConsumeList : vanPartsToConsumeList})
                        .then((result) => {
                            console.log('SUCCESS');
                            const consumed = new ShowToastEvent({
                                title: 'Success!',
                                message: 'Products are consumed!',
                                variant: 'success',
                                mode: 'dismissable'
                            });
                            this.dispatchEvent(consumed);
                            this.showSpinner = false;
                            this.woliList = [];
                            this.consumePartsList = [];
                            this.findWOLIs();
                            this.getVanParts();
                        })
                        .catch((error) => {
                            console.log('handleSubmit error-> ' + JSON.stringify(error));
                        });
                    }
                } else {
                    const emptyList = new ShowToastEvent({
                        title: 'Error',
                        message: 'Please add atleast one product!.',
                        variant: 'error',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(emptyList);
                }
            }
        }
    }

    /*markReadyForInvoice(event){
        this.showCompleteConsumptionPopUp = false;
        this.disbaleAllConsumptionDoneBtn = true;
        this.allConsumptionDone = true;
        markingWOReadyForInvoice({caseId : this.caseId})
            .then((result) => {
                console.log('SUCCESS');
                const consumptionDone = new ShowToastEvent({
                    title: 'Success!',
                    message: 'Marked "All Consumptions Done"',
                    variant: 'success',
                    mode: 'dismissable'
                });
                this.dispatchEvent(consumptionDone);
                this.allConsumptionDone = true;
            })
            .catch((error) => {
                console.log('markReadyForInvioce error-> ' + JSON.stringify(error));
            });
    }*/

    disablePullToRefresh() {
        // CustomEvent is standard JavaScript. See:
        // https://developer.mozilla.org/en-US/docs/Web/API/CustomEvent/CustomEvent
        const disable_ptr_event = new CustomEvent("updateScrollSettings", {
            detail: {
                isPullToRefreshEnabled: false,
            },
            bubbles: true,
            composed: true,
        });
        this.dispatchEvent(disable_ptr_event);
    }
}