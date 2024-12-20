import { LightningElement, wire, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getVanStock from '@salesforce/apex/ReturnParts.getVanStock';
import retriveAllProducts from '@salesforce/apex/ReturnParts.retriveAllProducts';
import retriveSearhedProducts from '@salesforce/apex/ReturnParts.retriveSearhedProducts';
import returnProductsToWarehouse from '@salesforce/apex/ReturnParts.returnProductsToWarehouse';

export default class ReturnParts extends LightningElement {
    @track searchKey = '';
    @track recordsListOnSearch = [];
    @track returnPartsList = [];
    @track isDisabled = false;
    @track vanPartsList = [];
    @track showSpinnerOnRefresh = false;
    @track returnPartsList = [];
    @track limitNumber = 200;
    @track allProductList = [];
    @track searchKey = '';
    @track showAllProducts = false;
    @track showVanParts = false;
    @track recordsPresent = false;
    @track returnProdExists = false;
    @track returnIsDisabled = true;
    @track buttonLabel = 'Show All Products For This Customer';
    @track hasVanParts = false;
    
    connectedCallback(){
        console.log('--connectedCallback1--');
        this.getVanParts();
        this.getAllProducts();
        this.disablePullToRefresh();
    }

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

    getVanParts(event){
        console.log('--getVanParts--');
        this.showSpinnerOnRefresh = true;
        getVanStock({})
            .then((result) =>{
                if(result.length != 0){
                    this.hasVanParts = true;
                } else {
                    this.hasVanParts = false;
                }
                this.vanPartsList = result;
                this.vanPartsList.forEach((item, index) => {
                    item.vanSerialNo = index + 1;
                    item.isSelected = false;
                    item.isVanPart = true;
                    item.originalQty = item.QuantityOnHand;
                    item.QuantityOnHand = 1;
                });
                console.log('this.vanPartsList size-> ' + this.vanPartsList.length);
                for (var vp = 0; vp < this.returnPartsList.length; vp++) {
                    if(this.returnPartsList[vp].isVanPart){
                        for (var p = 0; p < this.vanPartsList.length; p++) {
                            if (this.vanPartsList[p].Product2Id == this.returnPartsList[vp].Product2Id){
                                this.vanPartsList[p].isSelected = true;
                                this.vanPartsList[p].QuantityOnHand = this.returnPartsList[vp].QuantityOnHand;
                                break;
                            }
                        }
                    } else {
                        for (var p = 0; p < this.vanPartsList.length; p++) {
                            if (this.vanPartsList[p].Product2Id == this.returnPartsList[vp].Id){
                                this.vanPartsList[p].isSelected = true;
                                this.vanPartsList[p].QuantityOnHand = this.returnPartsList[vp].Quantity__c;
                                break;
                            }
                        }
                    }
                }
                this.showSpinnerOnRefresh = false;
            })
            .catch((error) => {
                console.log('getVanParts error-> ' + JSON.stringify(error));
                this.showSpinnerOnRefresh = false;
            });
    }

    getAllProducts(event){
        console.log('--getAllProducts--');
        this.showSpinnerOnRefresh = true;
        retriveAllProducts({limitNumber: this.limitNumber})
            .then((result) => {
                if (result.length === 0) {
                    this.allProductList = [];
                    this.isDisabled = true;
                    this.showSpinnerOnRefresh = false;
                } else {
                    this.isDisabled = false;
                    setTimeout(() => {
                        this.allProductList = result;
                        console.log('All CUB Products Retrieved-> ' + JSON.stringify(result));
                        for(var prod = 0; prod < this.allProductList.length; prod++){
                            this.allProductList[prod].Quantity__c = 1;
                            this.allProductList[prod].isVanPart = false;
                            if(this.allProductList[prod].ProductItems == null) continue;
                            var prodItems = this.allProductList[prod].ProductItems;
                            for(var p = 0; p < prodItems.length; p++){
                                prodItems[p].originalQty = prodItems[p].QuantityOnHand;
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
                            this.allProductList[prod].ProductItems = prodItems;
                        }
                        console.log('All Products-> ' + JSON.stringify(this.allProductList));
                        this.allProductList.forEach((item, index) => {
                            item.allProdSerialNo = index + 1;
                        });
                        for (var vp = 0; vp < this.returnPartsList.length; vp++) {
                            if(this.returnPartsList[vp].isVanPart){
                                for (var ap = 0; ap < this.allProductList.length; ap++) {
                                    if (this.allProductList[ap].Id == this.returnPartsList[vp].Product2Id){
                                        this.allProductList[ap].isSelected = true;
                                        this.allProductList[ap].Quantity__c = this.returnPartsList[vp].QuantityOnHand;
                                        break;
                                    }
                                }
                            } else {
                                for (var ap = 0; ap < this.allProductList.length; ap++) {
                                    if (this.allProductList[ap].Id == this.returnPartsList[vp].Id){
                                        this.allProductList[ap].isSelected = true;
                                        this.allProductList[ap].Quantity__c = this.returnPartsList[vp].Quantity__c;
                                        break;
                                    }
                                }
                            }
                        }
                    }, 400)
                    this.showSpinnerOnRefresh =  false;
                }
            })
            .catch((error) => {
                console.log('retriveAllProducts error-> ' + JSON.stringify(error));
                this.allProductList = [];
                this.showSpinnerOnRefresh =  false;
                this.isDisabled = true;
            });
    }

    handleKeyChange(event) {
        console.log('handleKeyChange---');
        this.searchKey = event.currentTarget.value;
        if(this.allProductList.length > 0){
            this.buttonLabel = 'Hide';
            this.showAllProducts = true;
        } else {
            this.buttonLabel = 'Show All Products For This Customer';
            this.showAllProducts = false;
        }
        if (this.searchKey !== '' && this.searchKey !== null) {
            console.log('handleKeyChange this.searchKey-> ' + this.searchKey);
            retriveSearhedProducts({ searchKey: this.searchKey})
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

    populateQuantity(event){
        var dataId = event.currentTarget.dataset.id;
        console.log('dataId-> ' + dataId);
        var dataName = event.currentTarget.dataset.name;
        console.log('dataName-> ' + dataName);
        var vanQty = 0;
        for(var vprod = 0; vprod < this.vanPartsList.length; vprod++){
            if(this.vanPartsList[vprod].Product2Id == dataId){
                vanQty = this.vanPartsList[vprod].originalQty;
                console.log('vanQty-> ' + vanQty);
                if(dataName == 'decreaseQty'){
                    if(this.vanPartsList[vprod].QuantityOnHand == 0) continue;
                    this.vanPartsList[vprod].QuantityOnHand = this.vanPartsList[vprod].QuantityOnHand - 1;
                } else if(dataName == 'increaseQty'){
                    if(this.vanPartsList[vprod].QuantityOnHand == vanQty) continue;
                    this.vanPartsList[vprod].QuantityOnHand = this.vanPartsList[vprod].QuantityOnHand + 1;
                }
                for(var prod = 0; prod < this.returnPartsList.length; prod++){
                    if(this.returnPartsList[prod].Product2Id != dataId) continue;
                    this.returnPartsList[prod].QuantityOnHand = this.vanPartsList[vprod].QuantityOnHand;
                }
            }
        }
        for(var prod = 0; prod < this.allProductList.length; prod++){
            if(this.allProductList[prod].Id == dataId){
                if(dataName == 'decreaseQty'){
                    if(this.allProductList[prod].Quantity__c == 0) continue;
                    this.allProductList[prod].Quantity__c = this.allProductList[prod].Quantity__c - 1;
                    break;
                } else if(dataName == 'increaseQty'){
                    if(this.allProductList[prod].Quantity__c == vanQty && vanQty != 0) continue;
                    this.allProductList[prod].Quantity__c = this.allProductList[prod].Quantity__c + 1;
                    break;
                }
                for(var prod = 0; prod < this.returnPartsList.length; prod++){
                    if(this.returnPartsList[prod].Product2Id != dataId) continue;
                    this.returnPartsList[prod].Quantity__c = this.allProductList[prod].Quantity__c;
                }
            }
        }
        console.log('this.returnPartsList after-> ' + JSON.stringify(this.returnPartsList));
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

    refreshLists(event){
        console.log('--refreshLists--');
        this.getVanParts();
        this.getAllProducts();
    }

    handleClickMore(event){
        this.limitNumber = this.limitNumber + 200;
        this.getAllProducts();
    }

    onRecordSelection(event) {
        console.log('---onRecordSelection---');
        var selectedRecordIndex = event.currentTarget.dataset.index;
        var selectedRecordId = event.currentTarget.dataset.id;
        var dataName = event.currentTarget.dataset.name;
        console.log('selectedRecordIndex-> ' + selectedRecordIndex);
        console.log('selectedRecordId-> ' + selectedRecordId);
        console.log('dataName-> ' + dataName);
        var newProd = true;
        for (var p = 0; p < this.returnPartsList.length; p++) {
            if(this.returnPartsList[p].isVanPart == true){
                if (this.returnPartsList[p].Product2Id == selectedRecordId) {
                    newProd = false;
                }
            } else {
                if (this.returnPartsList[p].Id == selectedRecordId) {
                    newProd = false;
                }
            }
        }
        debugger;
        console.log('newProd-> ' + newProd);
        if (newProd) {
            if(dataName == 'returnVanPart'){
                this.vanPartsList[selectedRecordIndex].isSelected = true;
                this.returnPartsList.push(this.vanPartsList[selectedRecordIndex]);
                for(var prod = 0; prod < this.allProductList.length; prod++){
                    if(selectedRecordId != this.allProductList[prod].Id) continue;
                    this.allProductList[prod].isSelected = true;
                    break;
                }
            } else if(dataName == 'returnNonVanPart'){
                this.allProductList[selectedRecordIndex].isSelected = true;
                this.returnPartsList.push(this.allProductList[selectedRecordIndex]);
                for(var vprod = 0; vprod < this.vanPartsList.length; vprod++){
                    if(selectedRecordId != this.vanPartsList[vprod].Product2Id) continue;
                    this.vanPartsList[vprod].isSelected = true;
                    break;
                }
            } else if(dataName == 'returnSearhedProduct'){
                var addedSearchProd = false;
                for(var vprod = 0; vprod < this.vanPartsList.length; vprod++){
                    if(selectedRecordId != this.vanPartsList[vprod].Product2Id) continue;
                    this.vanPartsList[vprod].isSelected = true;
                    this.returnPartsList.push(this.vanPartsList[vprod]);
                    addedSearchProd = true;
                    break;
                }
                for(var prod = 0; prod < this.allProductList.length; prod++){
                    if(selectedRecordId != this.allProductList[prod].Id) continue;
                    this.allProductList[prod].isSelected = true;
                    if(!addedSearchProd){
                        this.returnPartsList.push(this.allProductList[prod]);
                        addedSearchProd = true;
                    }
                    break;
                }
                if(!addedSearchProd){
                    this.recordsListOnSearch[selectedRecordIndex].isVanPart = false;
                    this.recordsListOnSearch[selectedRecordIndex].isSelected = true;
                    this.returnPartsList.push(this.recordsListOnSearch[selectedRecordIndex]);
                }
            }
            console.log('this.returnPartsList.length-> ' + this.returnPartsList.length);
        }
        console.log('this.returnPartsList-> ' + JSON.stringify(this.returnPartsList));
        if(this.returnPartsList.length == 0){
            this.returnIsDisabled = true;
            this.returnProdExists = false;
        } else {
            this.returnProdExists = true;
            this.returnIsDisabled = false;
            this.returnPartsList.forEach((item, index) => {
                item.returnSerialNo = index + 1;
            });
        }
        this.recordsPresent = false;
        this.searchKey = '';
        this.recordsListOnSearch = [];
        //var searchKey = this.template.querySelector('[data-name="searchProdInput"]');
        //searchKey.value = '';
    }

    onRemovingSelected(event){
        console.log('---onRemovingSelected---');
        var dataId = event.currentTarget.dataset.id;
        console.log('dataId-> ' + dataId);
        for(var prod = 0; prod < this.returnPartsList.length; prod++){
            if(this.returnPartsList[prod].isVanPart == true){
                if(this.returnPartsList[prod].Product2Id == dataId){
                    this.returnPartsList.splice(prod,1);
                    prod--;
                }
            } else if(this.returnPartsList[prod].isVanPart == false){
                if(this.returnPartsList[prod].Id == dataId){
                    this.returnPartsList.splice(prod,1);
                    prod--;
                }
            }
        }
        console.log('this.returnPartsList.length-> ' + this.returnPartsList.length);
        for(var vprod = 0; vprod < this.vanPartsList.length; vprod++){
            if(this.vanPartsList[vprod].Product2Id != dataId) continue;
            this.vanPartsList[vprod].isSelected = false;
            break;
        }
        for(var prod = 0; prod < this.allProductList.length; prod++){
            if(this.allProductList[prod].Id != dataId) continue;
            this.allProductList[prod].isSelected = false;
            break;
        }
        if(this.returnPartsList.length == 0){
            this.returnIsDisabled = true;
            this.returnProdExists = false;
        } else {
            this.returnProdExists = true;
            this.returnIsDisabled = false;
            this.returnPartsList.forEach((item, index) => {
                item.returnSerialNo = index + 1;
            });
        }
    }

    handleReturnParts(event){
        console.log('--handleReturnParts--');
        if(this.returnPartsList.length != 0){
            this.showSpinnerOnRefresh = true;
            var invalidQty = false;
            for(var p = 0; p< this.returnPartsList.length; p++){
                if(this.returnPartsList[p].QuantityOnHand == 0 || this.returnPartsList[p].Quantity__c == 0){
                    invalidQty = true;
                    break;
                }
            }
            if(invalidQty){
                const invalidQuantity = new ShowToastEvent({
                    title: 'Error',
                    message: 'Please specify valid quantity!.',
                    variant: 'error',
                    mode: 'dismissable'
                });
                this.dispatchEvent(invalidQuantity);
                this.showSpinnerOnRefresh = false;
            }
            if(!invalidQty){
                var prodList = [];
                for(var p = 0; p< this.returnPartsList.length; p++){
                    if(this.returnPartsList[p].isVanPart) continue;
                    prodList.push(this.returnPartsList[p]);
                    this.returnPartsList.splice(p,1);
                    p--;
                }
                console.log('prodList-> ' + JSON.stringify(prodList));
                console.log('this.returnPartsList-> ' + JSON.stringify(this.returnPartsList));
                returnProductsToWarehouse({ returnPartsList : this.returnPartsList, prodList: prodList}) .then((result) => {
                    console.log('SUCCESS');
                    const orderDone = new ShowToastEvent({
                        title: 'Success!',
                        message: 'Products are returned!',
                        variant: 'success',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(orderDone);
                    for(var p = 0; p< this.vanPartsList.length; p++){
                        this.vanPartsList[p].isSelected = false;
                        this.vanPartsList[p].QuantityOnHand = 1;
                    }
                    for(var ap = 0; ap< this.allProductList.length; ap++){
                        this.allProductList[ap].isSelected = false;
                        this.allProductList[ap].Quantity__c = 1;
                    }
                    this.returnPartsList = [];
                    prodList = [];
                    this.returnProdExists = false;
                    this.showSpinnerOnRefresh = false;
                })
                .catch((error) => {
                    console.log('handleReturnParts error-> ' + JSON.stringify(error));
                    this.showSpinnerOnRefresh = false;
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
            this.showSpinnerOnRefresh = false;
        }
    }
}