({
    helperMethod : function(component, event, helper) {
        component.set("v.loadSpinner", true);
        var gtNewCL = component.get("c.newCaseLine");
        gtNewCL.setCallback(this, function(response){
            if(response.getState() == 'SUCCESS'){
                var csLine = response.getReturnValue();
                var wo = component.get("v.workOrderOld");
                if(wo != null && wo.Id != null){
                    csLine.AccountId = wo.AccountId;
                    csLine.ProductId = wo.Product__c;
                    csLine.Account_Product__c = wo.Case.Account_Product__c;
                }
                var rho = component.get("v.redHotWO");
                if(rho != null && rho.Id != null){
                    csLine.AccountId = rho.AccountId;
                    csLine.ProductId = rho.Product__c;
                    csLine.Support_Team__c = rho.Case.Support_Team__c;
                    csLine.Account_Product__c = rho.Case.Account_Product__c;
                }
                component.set("v.caseRec",csLine);
                var caseProdList = [];
                var newCaseProduct = {"Account_Product__c":'',"Quantity__c":'1',"Case__c":'',"Product__c":'',"Serial_Number__c":'',"Subject":'standard:product'};
                caseProdList.push(newCaseProduct);
                component.set("v.caseProducts", caseProdList);
                component.set("v.loadSpinner", false);
            }
        });
        $A.enqueueAction(gtNewCL);
    },
    
    getHelpTexts : function(component, event, helper, proId) {
        var getHelpTexts = component.get("c.getHelpTexts");
        getHelpTexts.setCallback(this, function(response){
            if(response.getState() == 'SUCCESS'){
                var retVal = response.getReturnValue();
                for(var key in retVal){
                    for(var key2 in retVal[key]){
                        if(key == 'AccountId'){
                            component.set("v.accountIdHelpText",retVal[key]);
                        }
                        if(key == 'Service_Type__c'){
                            component.set("v.serviceTypeHelpText",retVal[key]);
                        }
                        if(key == 'Preferred_Time__c'){
                            component.set("v.preferredTimeHelpText",retVal[key]);
                        }
                        if(key == 'Priority'){
                            component.set("v.priorityHelpText",retVal[key]);
                        }
                        if(key == 'POS_Register_Number__c'){
                            component.set("v.posRegisterNumberHelpText",retVal[key]);
                        }
                        if(key == 'PO_Number__c'){
                            component.set("v.poNumberHelpText",retVal[key]);
                        }
                        if(key == 'Incident__c'){
                            component.set("v.incidentHelpText",retVal[key]);
                        }
                        if(key == 'Support_Team__c'){
                            component.set("v.supportTeamHelpText",retVal[key]);
                        }
                        if(key == 'Tech_Notes__c'){
                            component.set("v.techNotesHelpText",retVal[key]);
                        }
                        if(key == 'Description'){
                            component.set("v.descriptionHelpText",retVal[key]);
                        }
                        if(key == 'Asset_Number__c'){
                            component.set("v.assetNumberHelpText",retVal[key]);
                        }
                        if(key == 'Onsite_Contact_Name__c'){
                            component.set("v.onsiteContactNameHelpText",retVal[key]);
                        }
                        if(key == 'Include_Part__c'){
                            component.set("v.includePartHelpText",retVal[key]);
                        }
                        if(key == 'Department2__c'){
                            component.set("v.departmentHelpText",retVal[key]);
                        }
                        if(key == 'Equipment_Type__c'){
                            component.set("v.equipmentTypeHelpText",retVal[key]);
                        }
                        if(key == 'Problem_Type__c'){
                            component.set("v.problemTypeHelpText",retVal[key]);
                        }
                    }
                }
            }
        });
        $A.enqueueAction(getHelpTexts);
    },
    
    getAccountProduct : function(component, event, helper, proId) {
        var gtAccProdId = component.get("c.getAccProductId");
        gtAccProdId.setParams({
            ProdId : proId
        });
        gtAccProdId.setCallback(this, function(response){
            if(response.getState() == 'SUCCESS'){
                var retVal = response.getReturnValue();
                var caseRec = component.get("v.caseRec");
                caseRec.Account_Product__c = retVal;
                component.set("v.caseRec", caseRec);
            }
        });
        $A.enqueueAction(gtAccProdId);
    },
    
    prodHandlingCode : function(component, event, helper, productId){
        if(productId != '' && productId != undefined){
            var hcMthd = component.get("c.prodtHdlCode");
            hcMthd.setParams({
                "prodId" : productId
            });
            hcMthd.setCallback(this, function(response){
                if(response.getState() == 'SUCCESS'){
                    var retVal = response.getReturnValue();
                    var caseRec = component.get("v.caseRec");
                    caseRec.HandleCode = retVal;
                    component.set("v.caseRec", cases);
                }
            });
            $A.enqueueAction(hcMthd);
        }
    },
    
    supportNoteRecs : function(component, event, helper){
        var childAcc = component.get("v.childAcc");
        var getSupportNotes = component.get("c.getSupportTeamNotes");
        getSupportNotes.setParams({
            'childAccount' : childAcc
        });
        getSupportNotes.setCallback(this, function(response){
            if(response.getState() == 'SUCCESS'){
                component.set("v.supportTeams", response.getReturnValue());
            }
        });
        $A.enqueueAction(getSupportNotes);
    },
    
    getCaseRT : function(component, event, helper){
        var getRT = component.get("c.getCaseRecordTypes");
        getRT.setCallback(this, function(response){
            if(response.getState() == 'SUCCESS'){
                component.set("v.caseRecordTypes", response.getReturnValue());
            }
        });
        $A.enqueueAction(getRT);
    },

    checkForCUB : function(component, event, helper){
        var rootAcc = component.get("v.rootAcc");
        var callAction = component.get("c.checkForCUB");
        callAction.setParams({"rootAccountId" : rootAcc.Id});
        
        callAction.setCallback(this, function(response){
            if(response.getState() == 'SUCCESS'){
                var retVal = response.getReturnValue();
                if(retVal == true){
                    component.set("v.isCUB",true);
                } else {
                    component.set("v.isCUB",false);
                }
            }
        });
        $A.enqueueAction(callAction);
    },

    getEquipmentTypes : function(component, event, helper, parentAccountId) {
        console.log('parentAccountId-> ' + parentAccountId);
        var getEquipmentTypes = component.get("c.getEquipmentTypes");
        getEquipmentTypes.setParams({"parentAccountId" : parentAccountId});
        getEquipmentTypes.setCallback(this, function(response){
            console.log('returned');
            console.log('response.getState()-> ' + response.getState());
            if(response.getState() == 'SUCCESS'){
                console.log('response.getReturnValue()-> ' + JSON.stringify(response.getReturnValue()));
                component.set("v.equipmentTypeList",response.getReturnValue());
            }
        });
        $A.enqueueAction(getEquipmentTypes);
    },

    getProblemTypes : function(component, event, helper) {
        var productGroupingId = component.get("v.productGroupingId");
        var getProblemTypes = component.get("c.getProblemTypes");
        getProblemTypes.setParams({"productGroupingId" : productGroupingId});
        getProblemTypes.setCallback(this, function(response){
            if(response.getState() == 'SUCCESS'){
                component.set("v.problemTypeList",response.getReturnValue());
            }
        });
        $A.enqueueAction(getProblemTypes);
    },

    getDepartments : function(component, event, helper) {
        var getDepartments = component.get("c.getDepartments");
        getDepartments.setCallback(this, function(response){
            if(response.getState() == 'SUCCESS'){
                component.set("v.caseDepartments",response.getReturnValue());
            }
        });
        $A.enqueueAction(getDepartments);
    },

    fetchServiceTypes : function(component, event, helper, accId,location){
        var getSvcTypes = component.get("c.getServiceContracts");
        getSvcTypes.setParams({
            "accountId" : accId,
            "location" : location
        });
        getSvcTypes.setCallback(this, function(response){
            if(response.getState() == 'SUCCESS'){
                component.set("v.serviceContractList", response.getReturnValue());
                helper.serviceTypeCheck(component, event, helper);
            }
        });
        $A.enqueueAction(getSvcTypes);
        
    },

    getCaseTemplates : function(component, event, helper, rootAccId){
        var getCaseTemplates = component.get("c.getCaseTemplates");
        getCaseTemplates.setParams({"RootAccountId" : rootAccId});
        getCaseTemplates.setCallback(this, function(response){
            if(response.getState() == 'SUCCESS'){
                component.set("v.caseTemplates" , response.getReturnValue());
            }
        });
        $A.enqueueAction(getCaseTemplates);
    },

    serviceTypeCheck : function(component, event, helper){
        //component.set("v.outOfScope" , false);
        //component.set("v.outOfScopeIcon" , false);
        
        var caseRec = component.get("v.caseRec");
        caseRec.Preferred_Time__c = null;
        caseRec.PO_Number__c = null;
        caseRec.Priority = '';
        caseRec.Removed_Service_Product_IDs__c = '';
        if(caseRec.Service_Type__c != undefined && caseRec.Service_Type__c != '' && caseRec.Service_Type__c != null){
            var serviceContractList = component.get("v.serviceContractList");
            for( var i = 0; i < serviceContractList.length; i++){
                if(caseRec.Service_Type__c == serviceContractList[i].Service_Type__c){
                    component.set("v.selectedServiceContract",component.get("v.serviceContractList")[i]);
                    break;
                }
            }
        }
        var selectedServiceContract = component.get("v.selectedServiceContract");
        if(selectedServiceContract != null) {
            helper.getServiceProductList(component, event, helper);
            if(selectedServiceContract.PO_Number__c != null) caseRec.PO_Number__c = selectedServiceContract.PO_Number__c;
        }
        if(caseRec.Service_Type__c != null){
            if(selectedServiceContract != null && selectedServiceContract.Priority__c != null){
                caseRec.Priority = selectedServiceContract.Priority__c;
            } else {
                if(caseRec.Service_Type__c != 'Onsite Labor Only' || caseRec.Service_Type__c != 'Onsite Break-Fix') caseRec.Priority = 'Severity 2';
            }
        }
        var recordTypes = component.get("v.caseRecordTypes");
        for(var i = 0; i < recordTypes.length; i++){
            if(recordTypes[i].DeveloperName == 'Part_Request' && (caseRec.Service_Type__c == 'Advance Exchange (Depot Only)')){
                caseRec.RecordTypeId = recordTypes[i].Id;
            }else if(recordTypes[i].DeveloperName == 'Part_Onsite' && (caseRec.Service_Type__c == 'Advance Exchange + Onsite')){
                caseRec.RecordTypeId = recordTypes[i].Id;
            }else if(recordTypes[i].DeveloperName == 'Onsite_Support' && (caseRec.Service_Type__c == 'Onsite IMAC' || caseRec.Service_Type__c == 'Onsite Labor Only')){
                caseRec.RecordTypeId = recordTypes[i].Id;
            }
        }
        if(selectedServiceContract != null) {
            caseRec.ServiceContractId = selectedServiceContract.Id;
            component.set("v.disableAddingHardwareProducts", selectedServiceContract.Disable_Adding_Hardware_Products__c);
        }
        component.set("v.caseRec", caseRec);
        component.set("v.showServiceTypeDescriptions", false);
        component.set("v.removedServiceProds", null);
        component.set("v.isdisabled",false);
        component.find("prodctsTabSet").set("v.selectedTabId",'hardwareProducts');
        helper.handlePriorityVisibility(component, event, helper);
    },

    handlePriorityVisibility: function (component, event, helper) {
        var severityOptions = [
            component.find('severitySelect'),
            component.find('severity1'),
            component.find('severity2'),
            component.find('severity3'),
            component.find('severity4'),
            component.find('severity5'),
            component.find('severity6'),
            component.find('severity7')
        ];
    
        var serviceType = component.get("v.caseRec.Service_Type__c");
        var workOrderOld = component.get("v.caseRec.workOrderOld");
        var isCUB = component.get("v.isCUB");
        var rootAccName = component.get("v.rootAcc.Name");
        var optionsToShow = [];
        
        if (rootAccName) {
            console.log('rootAccName -> ' + rootAccName);
        }
    
        if (serviceType !== 'Onsite Labor Only' && serviceType !== 'Onsite Break-Fix') {
            var priority = component.get("v.caseRec.Priority");
            console.log('priority -> ' + priority);
    
            if (priority) {
                severityOptions.forEach(option => {
                    if (option && option.getElement().value === priority) {
                        optionsToShow.push(option);
                    }
                });
            }
            if((serviceType === 'Advance Exchange + Onsite' || serviceType === 'Advance Exchange (Depot Only)') && rootAccName && rootAccName.includes('Premium Brands Services, LLC')) {
                optionsToShow.push(component.find('severity7'));
            }
        } else {
            if (workOrderOld == null) {
                optionsToShow.push(component.find('severitySelect'), component.find('severity1'), component.find('severity2'));
                
                if (isCUB) {
                    optionsToShow.push(component.find('severity3'));
                }
    
                if ((serviceType === 'Onsite Labor Only' || serviceType === 'Onsite Break-Fix' || serviceType === 'Advance Exchange + Onsite' || 
                    serviceType === 'Advance Exchange (Depot Only)') && rootAccName && rootAccName.includes('Premium Brands Services, LLC')) {
                    optionsToShow.push(component.find('severity7'));
                }
            }
        }
    
        severityOptions.forEach(function (option) {
            if (option) {
                if (optionsToShow.includes(option)) {
                    option.getElement().removeAttribute("style");
                } else {
                    option.getElement().setAttribute("style", "display: none;");
                }
            }
        });
    },    

    getServiceProductList : function(component, event, helper){
        var callServiceProducts = component.get("c.getServiceProdcuts");
        callServiceProducts.setParams({ServiceContractId : component.get("v.selectedServiceContract").Id});
        callServiceProducts.setCallback(this, function(response){
            if(response.getState() == 'SUCCESS'){
                var retVal = response.getReturnValue();
                var hardwareprods = new Array();
                //var outOfScope = false;
                for(var hprod = 0; hprod < retVal.length; hprod++){
                    /*if(retVal[hprod].Out_of_Scope__c == true){
                        outOfScope = true;
                    }*/
                    if(retVal[hprod].Family == 'Hardware'){
                        hardwareprods.push(retVal[hprod]);
                        retVal.splice(hprod,1);
                        hprod--;
                    }
                }
                /*if(outOfScope){
                    component.set("v.outOfScope" , true);
                    component.set("v.outOfScopeIcon" , true);
                }*/
                component.set("v.caseServiceProducts", retVal);
                var caseProducts = component.get("v.caseProducts");
                if(caseProducts.length != 0){
                    for(var cProd = 0; cProd < caseProducts.length; cProd++){
                        if(caseProducts[cProd].customProductLookup != undefined && caseProducts[cProd].Product__c != null 
                            && caseProducts[cProd].customProductLookup.Id != null && caseProducts[cProd].customProductLookup.Id != ''){
                            caseProducts[cProd].Product__c = caseProducts[cProd].customProductLookup.Id;
                        }
                    }
                }
                if(hardwareprods.length != 0) {
                    for(var cProd = 0; cProd < caseProducts.length; cProd++){
                        if(caseProducts[cProd].customProductLookup != undefined && caseProducts[cProd].Product__c != null 
                            && caseProducts[cProd].customProductLookup.Id != null && caseProducts[cProd].customProductLookup.Id != '') continue;
                        delete caseProducts[cProd].customProductLookup;
                        caseProducts.splice(cProd,1);
                        cProd--;
                    }
                    var caseProdList = [];
                    for(var i=0; i< hardwareprods.length; i++){
                        var subject = (hardwareprods[i].NS_Item_Class__c == 'Bundle Product') ? 'standard:order_item' : 'standard:product';
                        var newCaseProduct = {
                            "Account_Product__c":'',
                            "Quantity__c":hardwareprods[i].Quantity__c,
                            "Case__c":'',
                            "Product__c":hardwareprods[i].Id,
                            "Serial_Number__c":'',
                            "Subject": subject,
                            "customProductLookup": hardwareprods[i]};
                        caseProdList.push(newCaseProduct);
                    }
                    for(var i=0; i<caseProdList.length; i++) {
                        for(var j=0; j<caseProducts.length; j++) {
                            if(caseProducts[j].Product__c != caseProdList[i].Product__c) continue;
                            delete caseProducts[j].customProductLookup;
                            caseProducts.splice(j,1);
                            j--;
                        }
                    }
                    caseProducts = caseProducts.concat(caseProdList);
                }
                component.set("v.caseProducts", caseProducts);
                helper.showProdPills(component, event);

                var caseProds = component.get("v.caseProducts");
                for(var i=0; i<caseProds.length; i++) {
                    if(caseProds[i].Product__c == undefined && caseProds[i].customProductLookup.length == undefined) {
                        caseProds[i].Quantity__c = 1;
                        caseProds[i].Product__c = '';
                        caseProds[i].Account_Product__c = '';
                        caseProds[i].Case__c = '';
                        caseProds[i].Serial_Numbers__c = '';
                        caseProds[i].Subject = 'standard:product';
                    }
                }
                component.set("v.caseProducts", caseProds);
                helper.showProdPills(component, event);
                component.set("v.selectedProdId",'');
            }
        });
        $A.enqueueAction(callServiceProducts);
    },

    showProdPills : function(component, event){
        var childCmps = component.find("childCmp");
        if(Array.isArray(childCmps)) {
            childCmps.forEach(function(childCmp) {
                var pillLabel = childCmp.get("v.selectedRecord.Name");
                if(pillLabel != undefined) {
                    var lookuppillcontainer = childCmp.find("lookup-pill-container");
                    $A.util.addClass(lookuppillcontainer, 'slds-show');
                    $A.util.removeClass(lookuppillcontainer, 'slds-hide');
                    
                    var searchRes = childCmp.find("searchRes");
                    $A.util.addClass(searchRes, 'slds-is-close');
                    $A.util.removeClass(searchRes, 'slds-is-open');
                    
                    var lookupField = childCmp.find("lookupField");
                    $A.util.addClass(lookupField, 'slds-hide');
                    $A.util.removeClass(lookupField, 'slds-show');
                }
            });
        }
    },

    saveServiceProducts : function(component, event, helper){
        var caseProd = component.get("v.caseProducts");
        for(var cProd = 0; cProd < caseProd.length; cProd++){
            if(caseProd[cProd] == null){
                caseProd.splice(cProd,1); // deleting null element in array list.
            }
            if(caseProd[cProd].customProductLookup != undefined && caseProd[cProd].Product__c != null && 
                caseProd[cProd].customProductLookup.Id != null && caseProd[cProd].customProductLookup.Id != ''){
                caseProd[cProd].Product__c = caseProd[cProd].customProductLookup.Id;
            }
            delete caseProd[cProd].customProductLookup;
            if(caseProd[cProd].Product__c == null){
                caseProd.splice(cProd,1); // clearing out empty space in array list.
                cProd--;
            }
        }
        var oldWO = component.get("v.workOrderOld");
        var newWO = component.get("v.workOrderNew");
        var redHotOrder = component.get("v.createRedHotOrder");
        var caseList = component.get("v.caseList");

        var svRecs = component.get("c.CreateCaseProdLineitems");
        svRecs.setParams({
            caseList : caseList,
            caseProducts : caseProd,
            oldWorkOrder : oldWO,
            newWorkOrder : newWO,
            redHotOrder : redHotOrder,
            serviceProdList : component.get('v.caseServiceProducts')
        });
        svRecs.setCallback(this, function(response){
            component.set("v.loadSpinner", false);
            if(response.getState() == 'SUCCESS'){
                component.set("v.tchNotes", '');
                var retVal = response.getReturnValue();
                component.set("v.tchNotes", '');
                component.set("v.csNotes", '');
                if(retVal.length == 15 || retVal.length == 18){
                    var toastEvnt = $A.get("e.force:showToast");
                    toastEvnt.setParams({
                        title : 'Success',
                        message : 'Service items has been saved successfully!',
                        duration : ' 5000',
                        key : 'info_alt',
                        type : 'success',
                        mode : 'pester'
                    });
                    toastEvnt.fire();
                    window.open('/'+retVal, '_self');
                }else{
                    var message = 'Failed to raise case!.' + '\n' + JSON.stringify(response.getError());
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title : 'Error',
                        message : message,
                        duration : ' 5000',
                        key : 'info_alt',
                        type : 'error',
                        mode : 'pester'
                    });
                    toastEvent.fire();
                }
            }
        });
        $A.enqueueAction(svRecs);
    }
})