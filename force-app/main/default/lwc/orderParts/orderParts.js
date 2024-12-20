import { LightningElement, wire, api, track } from 'lwc';
import checkWOOwnerId from '@salesforce/apex/OrderParts.checkWOOwnerId';
import retriveItemClassProducts from '@salesforce/apex/OrderParts.retriveItemClassProducts';
import retriveSearhedProducts from '@salesforce/apex/OrderParts.retriveSearhedProducts';
import retriveAllCUBProducts from '@salesforce/apex/OrderParts.retriveAllCUBProducts';
import createWOLIs from '@salesforce/apex/OrderParts.createWOLIs';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class OrderParts extends LightningElement {
    @api recordId;
    @track searchKey = '';
    @track recordsListOnSearch = [];
    @track addedProductList = [];
    @track itemClassProdList = [];
    @track allCubProductList = [];
    @track iconName = 'products';
    @track itemClassProductsExists = false;
    @track recordsPresent = false;
    @track showAllProducts = false;
    @track addedProdExists = false;
    @track buttonLabel = 'Show All Products For This Customer';
    @track showSubmitSpinner = false;
    @track showAllProdsSpinner = false;
    @track fieldTechOwnerExist = false;
    @track isDisabled = false;
    @track limitNumber = 200;

    connectedCallback() {
        console.log('connectedCallback called');
        console.log('recordId connectedCallback-> ' + this.recordId);
        this.checkOwnerId();
        this.getItemClassProducts();
        this.getAllCUBProducts();
    }

    checkOwnerId(event){
        checkWOOwnerId({workorderId: this.recordId })
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

    getItemClassProducts(event){
        retriveItemClassProducts({workorderId: this.recordId })
            .then((result) => {
                if (result.length === 0) {
                    this.itemClassProdList = [];
                    console.log('No MPN Records-> ' + JSON.stringify(result));
                } else {
                    this.itemClassProductsExists = true;
                    setTimeout(() => {
                        this.itemClassProdList = result;
                        for(var prod = 0; prod < this.itemClassProdList.length; prod++){
                            if(this.itemClassProdList[prod].ProductItems == null) continue;
                            var prodItems = this.itemClassProdList[prod].ProductItems;
                            for(var p = 0; p < prodItems.length; p++){
                                console.log('Location.LocationType-> ' + prodItems[p].Location.LocationType);
                                console.log('Location.Name-> ' + prodItems[p].Location.Name);
                                if(prodItems[p].Location.LocationType == 'Van'){
                                    prodItems[p].isVanLocation = true;
                                } else {
                                    prodItems[p].isVanLocation = false;
                                }
                                if(prodItems[p].Location.LocationType == 'Site'){
                                    prodItems[p].isTechWarehouse = true;
                                } else {
                                    prodItems[p].isTechWarehouse = false;
                                }
                                if(prodItems[p].Location.LocationType == 'Warehouse' && prodItems[p].Location.Name.includes('IWCR')){
                                    prodItems[p].isIWCRWarehouse = true;
                                } else {
                                    prodItems[p].isIWCRWarehouse = false;
                                }
                            }
                            this.itemClassProdList[prod].ProductItems = prodItems;
                            console.log('this.itemClassProdList[prod].ProductItems-> ' + JSON.stringify(this.itemClassProdList[prod].ProductItems));
                        }
                        this.itemClassProdList.forEach((item, index) => {
                            item.itemSerialNo = index + 1;
                        });
                        console.log('MPN Products Retrieved-> ' + JSON.stringify(this.itemClassProdList));
                        //Matching with what was added earlier.
                        for (var p = 0; p < this.addedProductList.length; p++) {
                            for (var i = 0; i < this.itemClassProdList.length; i++) {
                                if (this.itemClassProdList[i].Id == this.addedProductList[p].Id) {
                                    this.itemClassProdList[i].isSelected = true;
                                    this.itemClassProdList[i].Quantity__c = this.addedProductList[p].Quantity__c;
                                }
                            }
                        }
                    }, 400)
                }
            })
            .catch((error) => {
                console.log('getItemClassProducts error-> ' + JSON.stringify(error));
                this.itemClassProdList = [];
            });
    }

    handleClickMore(event){
        this.limitNumber = this.limitNumber + 200;
        this.getAllCUBProducts();
    }

    getAllCUBProducts(event){
        console.log('getAllCUBProducts');
        this.showAllProdsSpinner = true;
        retriveAllCUBProducts({workorderId: this.recordId, limitNumber: this.limitNumber })
            .then((result) => {
                if (result.length === 0) {
                    this.allCubProductList = [];
                    this.isDisabled = true;
                    this.showAllProdsSpinner = false;
                } else {
                    this.isDisabled = false;
                    setTimeout(() => {
                        this.allCubProductList = result;
                        console.log('All CUB Products Retrieved-> ' + JSON.stringify(result));
                        for(var prod = 0; prod < this.allCubProductList.length; prod++){
                            if(this.allCubProductList[prod].ProductItems == null) continue;
                            var prodItems = this.allCubProductList[prod].ProductItems;
                            for(var p = 0; p < prodItems.length; p++){
                                console.log('Location.LocationType-> ' + prodItems[p].Location.LocationType);
                                console.log('Location.Name-> ' + prodItems[p].Location.Name);
                                if(prodItems[p].Location.LocationType == 'Warehouse' && prodItems[p].Location.Name.includes('IWCR')){
                                    prodItems[p].isIWCRWarehouse = true;
                                } else {
                                    prodItems[p].isIWCRWarehouse = false;
                                }
                                if(prodItems[p].Location.LocationType == 'Site'){
                                    prodItems[p].isTechWarehouse = true;
                                } else {
                                    prodItems[p].isTechWarehouse = false;
                                }
                                if(prodItems[p].Location.LocationType == 'Van'){
                                    prodItems[p].isVanLocation = true;
                                } else {
                                    prodItems[p].isVanLocation = false;
                                }
                            }
                            this.allCubProductList[prod].ProductItems = prodItems;
                        }
                        this.allCubProductList.forEach((item, index) => {
                            item.allCubSerialNo = index + 1;
                        });
                        //Matching with what was added earlier.
                        for (var p = 0; p < this.addedProductList.length; p++) {
                            for (var a = 0; a < this.allCubProductList.length; a++) {
                                if (this.allCubProductList[a].Id == this.addedProductList[p].Id) {
                                    this.allCubProductList[a].isSelected = true;
                                    this.allCubProductList[a].Quantity__c = this.addedProductList[p].Quantity__c;
                                }
                            }
                        }
                    }, 400)
                    this.showAllProdsSpinner =  false;
                }
            })
            .catch((error) => {
                console.log('retriveAllCUBProducts error-> ' + JSON.stringify(error));
                this.allCubProductList = [];
                this.showAllProdsSpinner =  false;
            });
    }

    refreshLists(event){
        this.getAllCUBProducts();
        this.getItemClassProducts();
    }

    handleShowAllProducts(event){
        if(this.showAllProducts == false){
            this.buttonLabel = 'Hide';
            this.showAllProducts = true;
        } else {
            this.buttonLabel = 'Show All Products For This Customer';
            this.showAllProducts = false;
        }
    }

    handleKeyChange(event) {
        console.log('handleKeyChange---');
        this.searchKey = event.currentTarget.value;

        if (this.searchKey !== '' && this.searchKey !== null) {
            console.log('handleKeyChange this.searchKey-> ' + this.searchKey);
            retriveSearhedProducts({ searchKey: this.searchKey, workorderId: this.recordId })
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

    onRecordSelection(event) {
        console.log('---onRecordSelection---');
        var selectedRecordIndex = event.currentTarget.dataset.index;
        var selectedRecordId = event.currentTarget.dataset.id;
        var dataName = event.currentTarget.dataset.name;
        console.log('selectedRecordIndex-> ' + selectedRecordIndex);
        console.log('selectedRecordId-> ' + selectedRecordId);
        console.log('dataName-> ' + dataName);
        console.log('this.addedProductList-> ' + JSON.stringify(this.addedProductList));
        console.log('this.allCubProductList-> ' + JSON.stringify(this.allCubProductList));
        console.log('this.itemClassProdList-> ' + JSON.stringify(this.itemClassProdList));
        var newProd = true;
        for (var p = 0; p < this.addedProductList.length; p++) {
            if (this.addedProductList[p].Id == selectedRecordId) {
                newProd = false;
            }
        }
        console.log('newProd-> ' + newProd);
        if (newProd) {
            if(dataName == 'searhedProducts'){
                this.addedProductList.push(this.recordsListOnSearch[selectedRecordIndex]);
            } else if(dataName == 'allProducts'){
                this.addedProductList.push(this.allCubProductList[selectedRecordIndex]);
            } else if(dataName == 'itemClassProducts'){
                this.addedProductList.push(this.itemClassProdList[selectedRecordIndex]);
            }
            //Marking Selected in both lists
            for(var prod = 0; prod < this.allCubProductList.length; prod++){
                if(this.allCubProductList[prod].Id == selectedRecordId){
                    this.allCubProductList[prod].isSelected = true;
                }
            }
            for(var prod = 0; prod < this.itemClassProdList.length; prod++){
                if(this.itemClassProdList[prod].Id == selectedRecordId){
                    this.itemClassProdList[prod].isSelected = true;
                }
            }
            for(var prod = 0; prod < this.addedProductList.length; prod++){
                if(this.addedProductList[prod].ProductItems == null) continue;
                var prodItems = this.addedProductList[prod].ProductItems;
                for(var p = 0; p < prodItems.length; p++){
                    console.log('Location.LocationType-> ' + prodItems[p].Location.LocationType);
                    console.log('Location.Name-> ' + prodItems[p].Location.Name);
                    if(prodItems[p].Location.LocationType == 'Van'){
                        prodItems[p].isVanLocation = true;
                    } else {
                        prodItems[p].isVanLocation = false;
                    }
                    if(prodItems[p].Location.LocationType == 'Site'){
                        prodItems[p].isTechWarehouse = true;
                    } else {
                        prodItems[p].isTechWarehouse = false;
                    }
                    if(prodItems[p].Location.LocationType == 'Warehouse' && prodItems[p].Location.Name.includes('IWCR')){
                        prodItems[p].isIWCRWarehouse = true;
                    } else {
                        prodItems[p].isIWCRWarehouse = false;
                    }
                }
                this.addedProductList[prod].ProductItems = prodItems;
            }
            console.log('this.addedProductList.length-> ' + this.addedProductList.length);
            if(this.addedProductList.length != 0){
                this.addedProdExists = true;
            }
            this.addedProductList.forEach((item, index) => {
                item.addedProdSerialNo = index + 1;
            });
        }
        console.log('this.addedProductList-> ' + JSON.stringify(this.addedProductList));
        this.recordsPresent = false;
        var searchKey = this.template.querySelector('[data-name="searchProdInput"]');
        console.log('searchKey value-> ' + searchKey.value);
        searchKey.value = '';
        this.searchKey = '';
    }

    onRemovingSelected(event){
        var dataId = event.currentTarget.dataset.id;
        for(var prod = 0; prod < this.addedProductList.length; prod++){
            if(this.addedProductList[prod].Id == dataId){
                this.addedProductList.splice(prod, 1);
            }
        }
        if (this.addedProductList.length == 0) {
            this.addedProdExists = false;
        } else {
            this.addedProductList.forEach((item, index) => {
                item.addedProdSerialNo = index + 1;
            });
        }
        for(var prod = 0; prod < this.allCubProductList.length; prod++){
            if(this.allCubProductList[prod].Id == dataId){
                this.allCubProductList[prod].isSelected = false;
                this.allCubProductList[prod].Quantity__c = 0;
            }
        }
        for(var prod = 0; prod < this.itemClassProdList.length; prod++){
            if(this.itemClassProdList[prod].Id == dataId){
                this.itemClassProdList[prod].isSelected = false;
                this.itemClassProdList[prod].Quantity__c = 0;
            }
        }
    }

    handleRemove(event) {
        var targetIndex = event.currentTarget.title;
        var dataName = event.currentTarget.dataset.name;
        var dataId = event.currentTarget.dataset.id;
        console.log('targetIndex-> ' + targetIndex);
        console.log('dataName-> ' + dataName);
        console.log('dataId-> ' + dataId);
        if(dataName == 'addedProducts'){
            this.addedProductList.splice(targetIndex, 1);
            this.addedProductList.forEach((item, index) => {
                item.addedProdSerialNo = index + 1;
            });
            //Marking unselected as it is removed from added list
            for(var prod = 0; prod < this.allCubProductList.length; prod++){
                if(this.allCubProductList[prod].Id == dataId){
                    this.allCubProductList[prod].isSelected = false;
                    this.allCubProductList[prod].Quantity__c = 0;
                }
            }
            for(var prod = 0; prod < this.itemClassProdList.length; prod++){
                if(this.itemClassProdList[prod].Id == dataId){
                    this.itemClassProdList[prod].isSelected = false;
                    this.itemClassProdList[prod].Quantity__c = 0;
                }
            }
        } else if(dataName == 'allProducts'){
            this.allCubProductList.splice(targetIndex, 1);
            this.allCubProductList.forEach((item, index) => {
                item.allCubSerialNo = index + 1;
            });
        } else if(dataName == 'itemClassProducts'){
            this.itemClassProdList.splice(targetIndex, 1);
            this.itemClassProdList.forEach((item, index) => {
                item.itemSerialNo = index + 1;
            });
        }
        console.log('this.addedProductList after splice-> ' + JSON.stringify(this.addedProductList));
        console.log('this.allCubProductList after splice-> ' + JSON.stringify(this.allCubProductList));
        console.log('this.itemClassProdList after splice-> ' + JSON.stringify(this.itemClassProdList));
        if (this.addedProductList.length == 0) {
            this.addedProdExists = false;
        }
        if(this.allCubProductList.length == 0){
            this.showAllProducts = false;
            this.buttonLabel = 'Show All Products For This Customer';
            this.isDisabled = true;
        } else {
            this.isDisabled = false;
        }
        if(this.itemClassProdList.length == 0){
            this.itemClassProductsExists = false;
        }
    }

    populateQuantity(event){
        //var selectedRecordIndex = event.currentTarget.dataset.index;
        //this.addedProductList[selectedRecordIndex].Quantity__c = quantity;
        var dataId = event.currentTarget.dataset.id;
        var quantity = event.currentTarget.value;
        for(var prod = 0; prod < this.addedProductList.length; prod++){
            if(this.addedProductList[prod].Id == dataId){
                this.addedProductList[prod].Quantity__c = quantity;
            }
        }
        for(var prod = 0; prod < this.allCubProductList.length; prod++){
            if(this.allCubProductList[prod].Id == dataId){
                this.allCubProductList[prod].Quantity__c = quantity;
            }
        }
        for(var prod = 0; prod < this.itemClassProdList.length; prod++){
            if(this.itemClassProdList[prod].Id == dataId){
                this.itemClassProdList[prod].Quantity__c = quantity;
            }
        }
    }

    handleSubmit(event) {
        if(this.addedProductList.length != 0){
            var invalidQuantity = false;
            for(var prod = 0; prod < this.addedProductList.length; prod++){
                if(this.addedProductList[prod].Quantity__c == 0){
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
                this.showSubmitSpinner = true;
                console.log('Ordering parts: ' + JSON.stringify(this.addedProductList));
                if (this.addedProductList.length !== 0) {
                    createWOLIs({ prodList: this.addedProductList, workorderId: this.recordId })
                    .then(result => {
                        console.log('orderPartsStatus-> ' + result);
                        const orderDone = new ShowToastEvent({
                            title: 'Success!',
                            message: 'Parts are ordered!',
                            variant: 'success',
                            mode: 'dismissable'
                        });
                        this.dispatchEvent(orderDone);
                        this.showSubmitSpinner = false;
                        //Resetting All
                        for (var p = 0; p < this.addedProductList.length; p++) {
                            for (var i = 0; i < this.itemClassProdList.length; i++) {
                                if (this.itemClassProdList[i].Id == this.addedProductList[p].Id) {
                                    this.itemClassProdList[i].isSelected = false;
                                    this.itemClassProdList[i].Quantity__c = 0;
                                }
                            }
                            for (var a = 0; a < this.allCubProductList.length; a++) {
                                if (this.allCubProductList[a].Id == this.addedProductList[p].Id) {
                                    this.allCubProductList[a].isSelected = false;
                                    this.allCubProductList[a].Quantity__c = 0;
                                }
                            }
                        }
                        this.addedProductList = [];
                        this.addedProdExists = false;
                    })
                    .catch(error => {
                        console.error('handleSubmit Error: ' + JSON.stringify(error));
                        this.showSubmitSpinner = false;
                    });
                }
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