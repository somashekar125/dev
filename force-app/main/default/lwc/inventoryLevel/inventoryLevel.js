import { LightningElement, wire, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getInventoryProducts from '@salesforce/apex/InventoryLevel.getInventoryProducts';
import retriveSearhedProducts from '@salesforce/apex/InventoryLevel.retriveSearhedProducts';
import getMinQtyProducts from '@salesforce/apex/InventoryLevel.getMinQtyProducts';
import getAllProducts from '@salesforce/apex/InventoryLevel.getAllProducts';
import creatingReplenishmentWO from '@salesforce/apex/InventoryLevel.creatingReplenishmentWO';
import getFieldTechId from '@salesforce/apex/InventoryLevel.getFieldTechId';
import getActiveServiceResources from '@salesforce/apex/InventoryLevel.getActiveServiceResources';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class InventoryLevel extends NavigationMixin(LightningElement) {
    @track searchKey = '';
    @track fieldTechId = '';
    @track selectedValue = '';
    @track iconName = 'products';
    @track buttonLabel = 'All Products';
    @track buttonLabel2 = 'Products w/ Min Qty';
    @track productList = [];
    @track recordsListOnSearch = [];
    @track addedProductList = [];
    @track allCubProductList = [];
    @track minQtyProdList = [];
    @track serviceResourceList = [];
    @track techNameList = [];
    @track showSpinnerOnRefresh = false;
    @track orderVanParts = false;
    @track recordsPresent = false;
    @track showAllProducts = false;
    @track addedProdExists = false;
    @track showSubmitSpinner = false;
    @track showAllProdsSpinner = false;
    @track fieldTechOwnerExist = true;
    @track isDisabled = false;
    @track isDisabled2 = true;
    @track showMinQtyProds = false;
    @track stillProdsExists = true;
    @track stillProdsExists2 = true;
    @track limitNumber = 200;
    @track limitNumber2 = 100;

    connectedCallback(){
        console.log('connectedCallback');
        this.getProductList();
        this.getActiveTechs();
        this.loggedInUserCheck();
        this.disablePullToRefresh();
    }

    disablePullToRefresh() {
        const disable_ptr_event = new CustomEvent("updateScrollSettings", {
            detail: {
                isPullToRefreshEnabled: false,
            },
            bubbles: true,
            composed: true,
        });
        this.dispatchEvent(disable_ptr_event);
    }

    getActiveTechs(event) {
        console.log('getActiveTechs');
        getActiveServiceResources({}) .then((result) => {
            if(result != null) {
                this.serviceResourceList = result;
                console.log('getFieldTechId result-> ' + JSON.stringify(result));
                var srList = [];
                for(var s = 0; s < result.length; s++){
                    srList.push({ label: result[s].Name, value: result[s].Name });
                }
                console.log('srList-> ' + JSON.stringify(srList));
                this.techNameList = srList;
                console.log('this.techNameList-> ' + JSON.stringify(this.techNameList));
            }
        })
        .catch((error) => {
            console.log('getActiveTechs error-> ' + JSON.stringify(error));
        });
    }

    setFieldTechId(event) {
        var techName = event.detail.value;
        console.log('techName-> ' + techName);
        for(var s = 0; s < this.serviceResourceList.length; s++){
            if(this.serviceResourceList[s].Name != techName) continue;
            this.fieldTechId = this.serviceResourceList[s].Id;
            break;
        }
        console.log('setFieldTechId this.fieldTechId-> ' + this.fieldTechId);
        this.getAllCUBProducts();
        if(this.fieldTechId != '' && this.fieldTechId != 'undefined') {
            this.retrieveMinQtyProds();
        }
    }

    loggedInUserCheck(event){
        console.log('loggedInUserCheck');
        getFieldTechId({})
            .then((result) => {
                if(result != null) {
                    console.log('getFieldTechId result-> ' + result);
                    this.fieldTechId = result;
                    for(var s = 0; s < this.serviceResourceList.length; s++){
                        if(this.serviceResourceList[s].Id != this.fieldTechId) continue;
                        this.selectedValue = this.serviceResourceList[s].Name;
                        break;
                    }
                    this.getAllCUBProducts();
                    if(this.fieldTechId != '' && this.fieldTechId != 'undefined') {
                        this.retrieveMinQtyProds();
                    }
                }
            })
            .catch((error) => {
                console.log('loggedInUserCheck error-> ' + JSON.stringify(error));
            });
    }

    handleNavigate() {
        this.orderVanParts = true;
        this.getAllCUBProducts();
    }

    handleClickMore(event){
        this.limitNumber = this.limitNumber + 200;
        this.getAllCUBProducts();
    }

    handleClickMore2(event){
        this.limitNumber2 = this.limitNumber2 + 200;
        this.retrieveMinQtyProds();
    }

    refreshLists(event){
        this.getActiveTechs();
        this.getAllCUBProducts();
        if(this.fieldTechId != '' && this.fieldTechId != 'undefined') {
            this.retrieveMinQtyProds();
        }
    }

    backToVanStock(event) {
        this.orderVanParts = false;
    }

    getProductList(event){
        this.showSpinnerOnRefresh = true;
        getInventoryProducts({})
            .then((result) => {
                var temp = JSON.stringify(result);
                this.productList = JSON.parse(temp);
                console.log('Inventory Products Retrieved-> ' + JSON.stringify(this.productList));
                for(var prod = 0; prod < this.productList.length; prod++){
                    if(this.productList[prod].ProductItems != null){
                        var prodItems = this.productList[prod].ProductItems;
                        for(var p = 0; p < prodItems.length; p++){
                            console.log('Location.LocationType-> ' + prodItems[p].Location.LocationType);
                            console.log('Location.Name-> ' + prodItems[p].Location.Name);
                            if(prodItems[p].Location.LocationType == 'Van'){
                                prodItems[p].isVanLocation = true;
                            } else {
                                prodItems[p].isVanLocation = false;
                            }
                        }
                        this.productList[prod].ProductItems = prodItems;
                        console.log('this.productList[prod].ProductItems-> ' + JSON.stringify(this.productList[prod].ProductItems));
                    }
                }
                this.productList.forEach((item, index) => {
                    item.serialNo = index + 1;
                });
                this.showSpinnerOnRefresh = false;
            })
            .catch((error) => {
                console.log('checkForCUBAccount error-> ' + JSON.stringify(error));
                this.showSpinnerOnRefresh = false;
            });
    }

    goToDetailPage(event){
        console.log('goToDetailPage');
        var recordId = event.currentTarget.dataset.id;
        console.log('recordId-> ' + recordId);
        /*var recordindex = event.currentTarget.dataset.index;
        console.log('recordindex-> ' + recordindex);
        var prodItemId;
        var prod = this.productList[recordindex];
        prodItemId = prod.ProductItems[0].Id;
        console.log('prodItemId-> ' + prodItemId);*/

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: 'Product2',
                actionName: 'view'
            }
        });            
    }

    getAllCUBProducts(event){
        console.log('getAllCUBProducts');
        console.log('this.fieldTechId-> ' + this.fieldTechId);
        if(this.fieldTechId == 'undefined') this.fieldTechId = '';
        this.showAllProdsSpinner = true;
        getAllProducts({limitNumber: this.limitNumber, fieldTechId : this.fieldTechId})
            .then((result) => {
                if (result.length === 0) {
                    this.allCubProductList = [];
                    this.isDisabled = true;
                    this.showAllProdsSpinner = false;
                } else {
                    this.isDisabled = false;
                    setTimeout(() => {
                        this.allCubProductList = Object.values(result)[0];
                        var totalProds = Object.keys(result)[0];
                        console.log('totalProds-> ' + totalProds);
                        console.log('All CUB Products Retrieved-> ' + JSON.stringify(this.allCubProductList));
                        if(totalProds == this.allCubProductList.length) this.stillProdsExists = false;

                        for(var prod = 0; prod < this.allCubProductList.length; prod++){
                            if(this.allCubProductList[prod].ProductItems == null) continue;
                            var prodItems = this.allCubProductList[prod].ProductItems;
                            for(var p = 0; p < prodItems.length; p++){
                                if(prodItems[p].Location.LocationType == 'Warehouse' && prodItems[p].Location.Name.includes('IWCR')){
                                    prodItems[p].isIWCRWarehouse = true;
                                } else {
                                    prodItems[p].isIWCRWarehouse = false;
                                }
                                if(prodItems[p].Location.LocationType == 'Van'){
                                    prodItems[p].isVanLocation = true;
                                    if(prodItems[p].Minimum_Quantity__c != 0 && prodItems[p].Minimum_Quantity__c > prodItems[p].QuantityOnHand) {
                                        this.allCubProductList[prod].Quantity__c = prodItems[p].Minimum_Quantity__c - prodItems[p].QuantityOnHand;
                                        console.log('Quantity To Order 1-> ' + this.allCubProductList[prod].Quantity__c);
                                    }
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
                        if(this.addedProductList.length != 0){
                            for (var p = 0; p < this.addedProductList.length; p++) {
                                for (var a = 0; a < this.allCubProductList.length; a++) {
                                    if (this.allCubProductList[a].Id == this.addedProductList[p].Id) {
                                        this.allCubProductList[a].isSelected = true;
                                        this.allCubProductList[a].Quantity__c = this.addedProductList[p].Quantity__c;
                                    }
                                }
                            }
                        }
                    }, 400)
                    this.showAllProdsSpinner = false;
                }
            })
            .catch((error) => {
                console.log('retriveAllCUBProducts error-> ' + JSON.stringify(error));
                this.allCubProductList = [];
                this.showAllProdsSpinner =  false;
            });
    }

    retrieveMinQtyProds(event) {
        console.log('retrieveMinQtyProds');
        this.showAllProdsSpinner = true;
        getMinQtyProducts({limitNumber: this.limitNumber2, fieldTechId : this.fieldTechId})
        .then((result) => {
            if (result.length === 0) {
                this.minQtyProdList = [];
                this.isDisabled2 = true;
                this.showAllProdsSpinner = false;
            } else {
                this.isDisabled2 = false;
                setTimeout(() => {
                    this.minQtyProdList = Object.values(result)[0];
                    var totalProds = Object.keys(result)[0];
                    console.log('totalProds-> ' + totalProds);
                    console.log('Min Qty Products Retrieved-> ' + JSON.stringify(this.minQtyProdList));
                    if(totalProds == this.minQtyProdList.length) this.stillProdsExists2 = false;

                    for(var prod = 0; prod < this.minQtyProdList.length; prod++){
                        if(this.minQtyProdList[prod].ProductItems == null) continue;
                        var prodItems = this.minQtyProdList[prod].ProductItems;
                        for(var p = 0; p < prodItems.length; p++){
                            if(prodItems[p].Location.LocationType == 'Warehouse' && prodItems[p].Location.Name.includes('IWCR')){
                                prodItems[p].isIWCRWarehouse = true;
                            } else {
                                prodItems[p].isIWCRWarehouse = false;
                            }
                            if(prodItems[p].Location.LocationType == 'Van'){
                                prodItems[p].isVanLocation = true;
                                if(prodItems[p].Minimum_Quantity__c != 0 && prodItems[p].Minimum_Quantity__c > prodItems[p].QuantityOnHand) {
                                    this.minQtyProdList[prod].Quantity__c = prodItems[p].Minimum_Quantity__c - prodItems[p].QuantityOnHand;
                                    console.log('Quantity To Order 2-> ' + this.minQtyProdList[prod].Quantity__c);
                                }
                            } else {
                                prodItems[p].isVanLocation = false;
                            }
                        }
                        this.minQtyProdList[prod].ProductItems = prodItems;
                    }
                    this.minQtyProdList.forEach((item, index) => {
                        item.minQtySerialNo = index + 1;
                    });
                    //Matching with what was added earlier.
                    if(this.addedProductList.length != 0){
                        for (var prod = 0; prod < this.addedProductList.length; prod++) {
                            for (var a = 0; a < this.minQtyProdList.length; a++) {
                                if (this.minQtyProdList[a].Id == this.addedProductList[prod].Id) {
                                    this.minQtyProdList[a].isSelected = true;
                                    this.minQtyProdList[a].Quantity__c = this.addedProductList[prod].Quantity__c;
                                }
                            }
                        }
                    }
                }, 400)
                this.showAllProdsSpinner = false;
            }
        })
        .catch((error) => {
            console.log('retrieveMinQtyProds error-> ' + JSON.stringify(error));
            this.minQtyProdList = [];
            this.showAllProdsSpinner =  false;
        });
    }

    handleShowAllProducts(event){
        if(this.showAllProducts == false){
            this.buttonLabel = 'Hide';
            this.showAllProducts = true;
            this.buttonLabel2 = 'Products w/ Min Qty';
            this.showMinQtyProds = false;
        } else {
            this.buttonLabel = 'All Products';
            this.showAllProducts = false;
        }
    }

    handleMinQtyProds(event){
        if(this.showMinQtyProds == false){
            this.buttonLabel2 = 'Hide';
            this.showMinQtyProds = true;
            this.buttonLabel = 'All Products';
            this.showAllProducts = false;
        } else {
            this.buttonLabel2 = 'Products w/ Min Qty';
            this.showMinQtyProds = false;
        }
    }

    handleKeyChange(event) {
        console.log('handleKeyChange---');
        this.searchKey = event.currentTarget.value;

        if (this.searchKey !== '' && this.searchKey !== null) {
            console.log('handleKeyChange this.searchKey-> ' + this.searchKey);
            retriveSearhedProducts({ searchKey: this.searchKey, fieldTechId : this.fieldTechId})
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
        var newProd = true;
        for (var p = 0; p < this.addedProductList.length; p++) {
            if (this.addedProductList[p].Id == selectedRecordId) {
                newProd = false;
            }
        }
        console.log('newProd-> ' + newProd);
        if (newProd) {
            if(dataName == 'searhedProducts'){
                var prodItems = this.recordsListOnSearch[selectedRecordIndex].ProductItems;
                for(var p = 0; p < prodItems.length; p++){
                    console.log('Location.LocationType-> ' + prodItems[p].Location.LocationType);
                    console.log('Location.Name-> ' + prodItems[p].Location.Name);
                    console.log('Product Item QOH-> ' + prodItems[p].QuantityOnHand);
                    console.log('Product Item Minimum_Quantity__c-> ' + prodItems[p].Minimum_Quantity__c);
                    if(prodItems[p].Location.LocationType == 'Van'){
                        if(prodItems[p].Minimum_Quantity__c != 0 && prodItems[p].Minimum_Quantity__c > prodItems[p].QuantityOnHand) {
                            this.recordsListOnSearch[selectedRecordIndex].Quantity__c = prodItems[p].Minimum_Quantity__c - prodItems[p].QuantityOnHand;
                            console.log('Quantity To Order-> ' + this.recordsListOnSearch[selectedRecordIndex].Quantity__c);
                        }
                    }
                }
                this.addedProductList.push(this.recordsListOnSearch[selectedRecordIndex]);
            } else if(dataName == 'allProducts'){
                this.addedProductList.push(this.allCubProductList[selectedRecordIndex]);
            } else if(dataName == 'minQtyProds') {
                this.addedProductList.push(this.minQtyProdList[selectedRecordIndex]);
            }
            //Marking Selected in both lists
            for(var prod = 0; prod < this.allCubProductList.length; prod++){
                if(this.allCubProductList[prod].Id == selectedRecordId){
                    this.allCubProductList[prod].isSelected = true;
                }
            }
            for(var prod = 0; prod < this.minQtyProdList.length; prod++){
                if(this.minQtyProdList[prod].Id == selectedRecordId){
                    this.minQtyProdList[prod].isSelected = true;
                }
            }
            for(var prod = 0; prod < this.addedProductList.length; prod++){
                if(this.addedProductList[prod].ProductItems == null) continue;
                var prodItems = this.addedProductList[prod].ProductItems;
                for(var p = 0; p < prodItems.length; p++){
                    if(prodItems[p].Location.LocationType == 'Van'){
                        prodItems[p].isVanLocation = true;
                    } else {
                        prodItems[p].isVanLocation = false;
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
                var prodItems = this.allCubProductList[prod].ProductItems;
                for(var p = 0; p < prodItems.length; p++){
                    if(prodItems[p].Location.LocationType != 'Van') continue;
                    if(prodItems[p].Minimum_Quantity__c != 0 && prodItems[p].Minimum_Quantity__c > prodItems[p].QuantityOnHand) {
                        this.allCubProductList[prod].Quantity__c = prodItems[p].Minimum_Quantity__c - prodItems[p].QuantityOnHand;
                    }
                }
            }
        }
        for(var prod = 0; prod < this.minQtyProdList.length; prod++){
            if(this.minQtyProdList[prod].Id == dataId){
                this.minQtyProdList[prod].isSelected = false;
                this.minQtyProdList[prod].Quantity__c = 0;
                var prodItems = this.minQtyProdList[prod].ProductItems;
                for(var p = 0; p < prodItems.length; p++){
                    if(prodItems[p].Minimum_Quantity__c != 0 && prodItems[p].Minimum_Quantity__c > prodItems[p].QuantityOnHand) {
                        this.minQtyProdList[prod].Quantity__c = prodItems[p].Minimum_Quantity__c - prodItems[p].QuantityOnHand;
                        
                    }
                }
            }
        }
    }

    populateQuantity(event){
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
        for(var prod = 0; prod < this.minQtyProdList.length; prod++){
            if(this.minQtyProdList[prod].Id == dataId){
                this.minQtyProdList[prod].Quantity__c = quantity;
            }
        }
    }

    handleSubmit(event) {
        if(this.addedProductList.length != 0){
            if(this.fieldTechId == null){
                const emptyFieldTech = new ShowToastEvent({
                    title: 'Error',
                    message: 'Please Specify Field Technician!.',
                    variant: 'error',
                    mode: 'dismissable'
                });
                this.dispatchEvent(emptyFieldTech);
            }
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
            if(!invalidQuantity && this.fieldTechId != null && this.fieldTechId != ''){
                this.showAllProdsSpinner = true;
                console.log('Ordering parts: ' + JSON.stringify(this.addedProductList));
                if (this.addedProductList.length !== 0) {
                    creatingReplenishmentWO({ prodList: this.addedProductList, fieldTechId: this.fieldTechId})
                    .then(result => {
                        console.log('orderPartsStatus-> ' + result);
                        if(result == true){
                            const orderDone = new ShowToastEvent({
                                title: 'Success!',
                                message: 'Parts are ordered!',
                                variant: 'success',
                                mode: 'dismissable'
                            });
                            this.dispatchEvent(orderDone);
                        } else {
                            const emptyList = new ShowToastEvent({
                                title: 'Error',
                                message: 'Failed To Order!.',
                                variant: 'error',
                                mode: 'dismissable'
                            });
                            this.dispatchEvent(emptyList);
                        }
                        this.showAllProdsSpinner = false;
                        //Resetting All
                        this.addedProdExists = false;
                        this.addedProductList = [];
                        this.getAllCUBProducts();
                        if(this.fieldTechId != '' && this.fieldTechId != 'undefined') {
                            this.retrieveMinQtyProds();
                        }
                    })
                    .catch(error => {
                        console.error('handleSubmit Error: ' + JSON.stringify(error));
                        this.showAllProdsSpinner = false;
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