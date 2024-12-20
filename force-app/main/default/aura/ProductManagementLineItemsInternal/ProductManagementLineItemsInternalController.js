({
    myAction : function(component, event, helper) {
        component.set("v.caseProducts", []);
        helper.helperMethod(component, event, helper);
        helper.getHelpTexts(component, event, helper);
        helper.getCaseRT(component, event, helper);
        helper.getDepartments(component,event,helper);
        var timezone = $A.get("$Locale.timezone");
        component.set("v.timezone",timezone);
        var wo = component.get("v.workOrderOld");
        if(wo!= null && wo.Id != null){
            component.set("v.accId", wo.AccountId);
        }
        var rho = component.get("v.redHotWO");
        if(rho!= null && rho.Id != null){
            component.set("v.accId", rho.AccountId);
        }
        component.set("v.tchNotes", '');
        component.set("v.csNotes", '');
        component.set("v.isdisabled",false);
    },
    
    removeProduct : function(component, event, helper){
        component.set("v.isdisabled",false);
        var prodIndex = event.target.id;
        var caseProdList = component.get("v.caseProducts");
        // cp.customProductLookup will be added to caseProdList along with cp fields after caseProdList is Set.
        // caseProducts-> [{"Account_Product__c":"","Quantity__c":"1","Case__c":"","Product__c":"","Serial_Number__c":"","customProductLookup":{"Id":"01t6g0000052BxmAAE","Name":"Verifone E355 3-Unit Gang Charger"}},{"customProductLookup":{}}]
        // So only product and cp fields are deleted from list and pill in case form remains since customProductLookup{} isn't deleted from list.
        // So after onclick of remove and adding new product in same pill and clicking submit: the product will not be registered in list since 
        // caseProd[cProd].Product__c = caseProd[cProd].customProductLookup.Id; fails because 'Product__c' field is missing from list.
        // Below code is for last row or caseProdList.length-1 is to avoid 'At least one h/w product' toast and fix above issue.
        var removedLast = false;
        if(prodIndex == (caseProdList.length-1)){
            caseProdList.splice(prodIndex, 1);
            var newCaseProduct = {"Account_Product__c":'',"Quantity__c":'1',"Case__c":'',"Product__c":'','Serial_Number__c':'',"Subject":'standard:product'};
            caseProdList.push(newCaseProduct);
            removedLast = true;
        }
        if(removedLast == false){
            caseProdList.splice(prodIndex, 1);
        }
        component.set("v.caseProducts", caseProdList);
    },
    
    addProductLines : function(component, event, helper){
        var caseProducts = component.get("v.caseProducts");
        var newCaseProduct = {"Account_Product__c":'',"Quantity__c":'1',"Case__c":'',"Product__c":'','Serial_Number__c':'',"Subject":'standard:product'};
        caseProducts.push(newCaseProduct);
        if(caseProducts.length != 0){
            for(var cProd = 0; cProd < caseProducts.length; cProd++){
                if(caseProducts[cProd].customProductLookup != undefined && caseProducts[cProd].Product__c != null 
                    && caseProducts[cProd].customProductLookup.Id != null && caseProducts[cProd].customProductLookup.Id != ''){
                    caseProducts[cProd].Product__c = caseProducts[cProd].customProductLookup.Id;
                }
            }
        }
        component.set("v.caseProducts", caseProducts);
        helper.showProdPills(component, event);
        component.set("v.isdisabled",false);
    },

    /*handleOutOfScope : function(component, event, helper){
        var selectedProduct = event.getParam("recordByEvent");
        if(selectedProduct.Out_of_Scope__c == true){
            component.set("v.outOfScope" , true);
            component.set("v.outOfScopeIcon" , true);
        } else {
            component.set("v.outOfScope" , false);
        }
        var caseProdList = component.get("v.caseProducts");
        for(var i = 0; i < caseProdList.length; i++){
            if(caseProdList[i].customProductLookup.Out_of_Scope__c == true){
                caseProdList[i].Out_of_Scope__c = true;
            }
        }
        component.set("v.caseProducts", caseProdList);
    },

    closeOutOfScopeAlert : function(component, event, helper){
        component.set("v.outOfScope" , false);
    },*/
    
    oosPriorityChng : function(component, event, helper){
        var caseRec = component.get("v.caseRec");
        //for(var i = 0; i < cses.length; i++){
        if(caseRec.Out_Of_Scope__c){
            caseRec.Priority = 'Severity 2';
        }
        //}
        component.set("v.caseRec", caseRec);
        component.set("v.isdisabled",false);
    },
    
    openTechNotesPop : function(component, event, helper){
        var teamId = component.get("v.caseRec").Support_Team__c;
        var supportTeamRecs = component.get("v.supportTeams");
        for(var i = 0; i < supportTeamRecs.length; i++){
            if(supportTeamRecs[i].Id == teamId){
                component.set("v.tchNotes", supportTeamRecs[i].Tech_Notes__c);
            }
        }
        component.set("v.isdisabled",false);
    },
    
    openNotesPop : function(component, event, helper){
        component.set("v.csNotes", component.get("v.caseRec").Description);
    },
    
    enterTechNotes  : function(component, event, helper){
        var caseRec = component.get("v.caseRec");
        caseRec.Tech_Notes__c = component.get("v.tchNotes");
        component.set("v.caseRec", caseRec);
        component.set("v.isdisabled",false);
    },
    
    setTechNotes : function(component, event, helper){
        var supTeams = component.get("v.supportTeams");
        var caseRec = component.get("v.caseRec");
        if(caseRec.Support_Team__c != null){
            for(var i = 0; i < supTeams.length; i++){
                if(caseRec.Support_Team__c == supTeams[i].Id){
                    caseRec.Tech_Notes__c = supTeams[i].Tech_Notes__c;
                    component.set("v.tchNotes",supTeams[i].Tech_Notes__c);
                    caseRec.Customer_Notification_Email__c = supTeams[i].Email__c;
                }
            }
        }
        component.set("v.caseRec", caseRec);
        component.set("v.isdisabled",false);
    },
    
    enterNotes  : function(component, event, helper){
        var caseRec = component.get("v.caseRec");
        caseRec.Description = component.get("v.csNotes");
        component.set("v.caseRec", caseRec);
        component.set("v.isdisabled",false);
    },

    handleRootAccount : function (component, event, helper) {
        var caseRec = component.get("v.caseRec");
        var rootAcc = component.get("v.rootAcc");
        caseRec.Root_Account__c = rootAcc.Id;
        component.set("v.caseRec",caseRec);
        component.set("v.rootAccountId", rootAcc.Id);
        component.set("v.multipleStoreSelectionIsDone",false);
        component.set("v.addedStores",[]);
        component.set("v.caseServiceProducts",null);
        var caseProdList = [];
        var newCaseProduct = {"Account_Product__c":'',"Quantity__c":'1',"Case__c":'',"Product__c":'','Serial_Number__c':'',"Subject":'standard:product'};
        caseProdList.push(newCaseProduct);
        component.set("v.caseProducts", caseProdList);
        component.set("v.selectedServiceContract",null);
        component.set("v.serviceContractList",null);
        component.set("v.supportTeams",null);
        component.set("v.tchNotes",null);
		component.find("prodctsTabSet").set("v.selectedTabId",'hardwareProducts');
        
        //helper.getCaseTemplates(component, event, helper,rootAcc.Id);
        if(rootAcc.Id != null){
            if(rootAcc.Default_Service_Contract__c != null){
                if(rootAcc.Default_Service_Contract__r.Service_Type__c != null){
                    component.set("v.defaultServiceType", rootAcc.Default_Service_Contract__r.Service_Type__c);
                    component.set("v.hardwareRootAccountId",rootAcc.H_W_Root_Account__c);
                    var caseRec = component.get("v.caseRec");
                    caseRec.Service_Type__c = component.get("v.defaultServiceType");
                    component.set("v.caseRec",caseRec);
                }
            } else {
                component.set("v.defaultServiceType", null); //resetting
            }
            helper.checkForCUB(component, event, helper);
            if(rootAcc.ShippingCountry != null){
                helper.fetchServiceTypes(component, event, helper,rootAcc.Id,rootAcc.ShippingCountry);
            }
        }
        component.set("v.childAcc", null);
        component.set("v.selectedStoreId", null);
        component.set("v.isdisabled",false);
    },
    
    addAccInCases : function(component, event, helper){
        var childAcc = component.get("v.childAcc");
        var defaultServiceType = component.get("v.defaultServiceType");
        var defaultServiceContractRootLevel = false;
        if(childAcc.Id != null){
            var defaultServiceContract = false;
            if(childAcc.Parent.Default_Service_Contract__c != null && defaultServiceContractRootLevel == false){
                if(childAcc.Parent.Default_Service_Contract__r.Service_Type__c != null){
                    component.set("v.defaultServiceType", childAcc.Parent.Default_Service_Contract__r.Service_Type__c);
                    defaultServiceContract = true;
                }
            }
            if(defaultServiceContract == true){
                var caseRec = component.get("v.caseRec");
                var defaultServiceType = component.get("v.defaultServiceType");
                caseRec.Service_Type__c = defaultServiceType;
                component.set("v.caseRec",caseRec);
            }
            helper.supportNoteRecs(component, event, helper);
            helper.fetchServiceTypes(component, event, helper,childAcc.Id,childAcc.ShippingCountry);
            helper.getEquipmentTypes(component, event, helper, childAcc.ParentId);
        }
        component.set("v.isdisabled",false);
    },
    
    handleServiceType : function(component, event, helper){
        helper.serviceTypeCheck(component, event, helper);
    },
    
    setPriority : function(component, event, helper){
        var selectedServiceContract = component.get("v.selectedServiceContract");
        var caseRec = component.get("v.caseRec");
        if(caseRec.Preferred_Time__c != null && caseRec.Preferred_Time__c != '' && caseRec.Preferred_Time__c != undefined 
            && selectedServiceContract.Priority__c == null){
            
            var timezone = $A.get("$Locale.timezone");            
            var prefDt1 = new Date(caseRec.Preferred_Time__c);            
            function changeTimezone(date, ianatz) {
                // suppose the date is 12:00 UTC
                var invdate = new Date(date.toLocaleString('en-US', {
                    timeZone: ianatz
                }));
                // then invdate will be 07:00 in Toronto
                // and the diff is 5 hours
                var diff = date.getTime() - invdate.getTime();
                // so 12:00 in Toronto is 17:00 UTC
                return new Date(date.getTime() - diff); // needs to substract
            }
            
            var prefDt = changeTimezone(prefDt1, timezone);
            
            /*prefDt1.setTime(prefDt1.getTime()+prefDt1.getTimezoneOffset()*60*1000);
                var offset = -240; //Timezone offset for ORG wide in minutes.
                var prefDt = new Date(prefDt1.getTime() + (offset*60*1000));*/
            //var daysFrmNow = Math.ceil((prefDt.getTime() - dtNow.getTime())/ (1000 * 3600 * 24));
            var prefHour = prefDt.getHours();
            var prefDay = prefDt.getDay();
            if((prefDay == 0 || prefDay == 6) || ((prefDay > 0 && prefDay < 6) && (prefHour < 8 || prefHour >= 17))){
                caseRec.Priority = 'Severity 1';
            }else if((prefDay > 0 && prefDay < 6) && (prefHour >= 8 && prefHour < 17)){
                caseRec.Priority = 'Severity 2';
            }
            var wo = component.get("v.workOrderOld");
            if(wo != null && wo.Id != null){
                caseRec.Priority = 'Severity 2';
            }
            var timeNow = new Date();
            timeNow = changeTimezone(timeNow, timezone);
            timeNow.setSeconds(0);
            if(prefDt < timeNow){
                caseRec.Priority = '';
                caseRec.Preferred_Time__c = '';
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title : 'Error',
                    message : 'Preferred Time can not be in past!',
                    duration : ' 6000',
                    key : 'info_alt',
                    type : 'error',
                    mode : 'pester'
                });
                toastEvent.fire();
            }
        }
        if(caseRec.Include_Part__c){
            caseRec.Priority = 'Severity 2';
        }
        component.set("v.caseRec",caseRec);
        component.set("v.isdisabled",false);
    },

    partPriorityToSev2 : function(component, event, helper){
        var caseRec = component.get("v.caseRec");
        if(caseRec.Include_Part__c){
            caseRec.Priority = 'Severity 2';
        }
        component.set("v.caseRec",caseRec);
        component.set("v.isdisabled",false);
    },
    
    saveRecords : function(component, event, helper){
        component.set("v.loadSpinner", true);
        var caseProducts = component.get("v.caseProducts");
        var caseRec = component.get("v.caseRec");
        var addedStores = component.get("v.addedStores");
        if((caseRec.AccountId == null || caseRec.AccountId == '' || caseRec.AccountId == undefined) && addedStores == null){
            component.set("v.loadSpinner", false);
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title : 'Error',
                message : 'Please select the service Location!',
                duration : ' 5000',
                key : 'info_alt',
                type : 'error',
                mode : 'pester'
            });
            toastEvent.fire();
            return;
        }

        if((caseRec.Service_Type__c == 'Onsite Labor Only') && (caseRec.Priority == null || caseRec.Priority == '' || caseRec.Priority == undefined)){
            component.set("v.loadSpinner", false);
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title : 'Error',
                message : 'Please select the Priority!',
                duration : ' 5000',
                key : 'info_alt',
                type : 'error',
                mode : 'pester'
            });
            toastEvent.fire();
            return;
        }
        if(caseProducts.length != 0){
            for(var cProd = 0; cProd < caseProducts.length; cProd++){
                if(caseProducts[cProd].customProductLookup != undefined && caseProducts[cProd].Product__c != null 
                    && caseProducts[cProd].customProductLookup.Id != null && caseProducts[cProd].customProductLookup.Id != ''){
                    caseProducts[cProd].Product__c = caseProducts[cProd].customProductLookup.Id;
                }
            }
        }
        var supptTeams = component.get("v.supportTeams");
        var selectedServiceContract = component.get("v.selectedServiceContract");
        
        if(selectedServiceContract.Schedulable__c == true && selectedServiceContract.Create_Work_Order_For__c == 'Service Contract' && (caseRec.Preferred_Time__c == undefined || caseRec.Preferred_Time__c == '' || caseRec.Preferred_Time__c == null)){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title : 'Error',
                message : 'Please select Preferred Time!.',
                duration : ' 5000',
                key : 'info_alt',
                type : 'error',
                mode : 'pester'
            });
            toastEvent.fire();
            component.set("v.loadSpinner", false);
            return;
        }
        var caseServiceProducts = component.get("v.caseServiceProducts");
        var selectedServiceContract = component.get("v.selectedServiceContract");
        
        for(var i=0;i<caseServiceProducts.length;i++){
            if(selectedServiceContract.Show_CLIs_As_Service_Products__c == true && selectedServiceContract.Create_Work_Order_For__c == 'Contract Line Item' && selectedServiceContract.Schedulable__c == true && (caseServiceProducts[i].Dummy_Preferred_Time__c == undefined || caseServiceProducts[i].Dummy_Preferred_Time__c == '' || caseServiceProducts[i].Dummy_Preferred_Time__c == null)){
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title : 'Error',
                    message : 'Please specify preferred time on each type of task under service products tab.',
                    duration : ' 5000',
                    key : 'info_alt',
                    type : 'error',
                    mode : 'pester'
                });
                toastEvent.fire();
                component.set("v.loadSpinner", false);
                component.find("prodctsTabSet").set("v.selectedTabId",'serviceProducts');
                return;
            }
        }
        if(caseRec.Preferred_Time__c != null && caseRec.Preferred_Time__c != '' && caseRec.Preferred_Time__c != undefined){
            var timezone = $A.get("$Locale.timezone");
            var prefDt1 = new Date(caseRec.Preferred_Time__c);
            function changeTimezone(date, ianatz) {
                // suppose the date is 12:00 UTC
                var invdate = new Date(date.toLocaleString('en-US', {
                    timeZone: ianatz
                }));
                // then invdate will be 07:00 in Toronto
                // and the diff is 5 hours
                var diff = date.getTime() - invdate.getTime();
                // so 12:00 in Toronto is 17:00 UTC
                return new Date(date.getTime() - diff); // needs to substract
            }
            var prefDt = changeTimezone(prefDt1, timezone)
            var dtNow1 = new Date();
            var dtNow = changeTimezone(dtNow1, timezone);
            var daysFrmNow = Math.ceil((prefDt.getTime() - dtNow.getTime())/ (1000 * 3600 * 24));
            var prefHour = prefDt.getHours();
            //daysFrmNow <= 3 ||  - for 72 hours condition
            //at least 72 hours after current time and also the selected time
            if((prefHour < 8 || prefHour > 22)){
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title : 'Error',
                    message : 'selected time must be between 8am and 10pm',
                    duration : ' 6000',
                    key : 'info_alt',
                    type : 'error',
                    mode : 'pester'
                });
                toastEvent.fire();
                component.set("v.loadSpinner", false);
                return;
            }
        }
        if(caseRec.Support_Team__c != null){
            for(var k = 0; k < supptTeams.length; k++){
                if(supptTeams[k].Id == caseRec.Support_Team__c){
                    caseRec.Customer_Notification_Email__c = supptTeams[k].Email__c;
                }
            }
        }
        if(caseRec.OOS_Product__c != null){
            caseRec.ProductId = caseRec.OOS_Product__c;
        }
        var selectedServiceContract = component.get("v.selectedServiceContract");
        var validList = false;
        for(var i = 0; i < caseProducts.length; i++){
            if(caseProducts[i].Product__c != null && caseProducts[i].Product__c != '' && caseProducts[i].Product__c != undefined){
                validList = true;
            }
        }
        if(validList && selectedServiceContract.Include_Part__c && component.get("v.toMark") && !caseRec.Include_Part__c) {
            //Showing this warning only once on submit
            component.set("v.toMark",false);
            component.set("v.loadSpinner", false);
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title : 'Warning',
                message : 'Please mark "Include Part" if the added products need to be shipped!',
                duration : ' 5000',
                key : 'info_alt',
                type : 'Warning',
                mode : 'pester'
            });
            toastEvent.fire();
            return;
        }
        if(selectedServiceContract.Hardware_Product_Required__c && !validList){
            component.set("v.loadSpinner", false);
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title : 'Error',
                message : 'Please specify at least one hardware product!',
                duration : ' 5000',
                key : 'info_alt',
                type : 'error',
                mode : 'pester'
            });
            toastEvent.fire();
            return;
        }
        if(caseProducts.length != 0){
            for(var cProd = 0; cProd < caseProducts.length; cProd++){
                if(caseProducts[cProd].Quantity__c == null ||  caseProducts[cProd].Quantity__c == ''){
                    caseProducts[cProd].Quantity__c = 1;
                }
                if(caseProducts[cProd].customProductLookup != undefined && caseProducts[cProd].Product__c != null 
                    && caseProducts[cProd].customProductLookup.Id != null && caseProducts[cProd].customProductLookup.Id != ''){
                    caseProducts[cProd].Product__c = caseProducts[cProd].customProductLookup.Id;
                }
                delete caseProducts[cProd].customProductLookup;
            }
        }
        //deleting empty space left in case product list.
        if(caseProducts.length != 0){
            for(var k = 0; k < caseProducts.length; k++){
                if(caseProducts[k].Product__c == null || caseProducts[k].Product__c == '' || caseProducts[k].Product__c == undefined){
                    caseProducts.splice(k,1);
                    k--;
                }
            }
        }
        component.set("v.caseProducts",caseProducts);
        component.set("v.caseRec",caseRec);
        //Setting case.AccountId and Adding Multiple Cases
        var multipleStoreSelectionIsDone = component.get("v.multipleStoreSelectionIsDone");
        var addedStores = component.get("v.addedStores");
        var caseList = component.get("v.caseList");
        if(multipleStoreSelectionIsDone && addedStores != null){
            for(var acc = 0; acc < addedStores.length; acc++){
                var caseRec = JSON.parse(JSON.stringify(component.get("v.caseRec")));
                caseRec.AccountId = addedStores[acc].Id;
                caseList.push(caseRec);
            }
        } else {
            var caseRec = JSON.parse(JSON.stringify(component.get("v.caseRec")));
            var accId = component.get("v.childAcc");
            caseRec.AccountId = accId.Id;
            caseList.push(caseRec);
        }
        component.set("v.caseList",caseList);

        component.set("v.isdisabled",true);
        helper.saveServiceProducts(component, event, helper); 
        component.set("v.tchNotes", '');
        component.set("v.csNotes", '');
    },

    removeServiceProduct : function(component, event, helper){
        var index = event.target.id;
        var removedProdId = event.target.name;
        var existingSerProd = component.get("v.caseRec").Removed_Service_Product_IDs__c;
        if(existingSerProd != undefined && existingSerProd != null){
            existingSerProd += ','+removedProdId;
        } else {
            existingSerProd = removedProdId;
        }
        var caseRec = component.get("v.caseRec");
        caseRec.Removed_Service_Product_IDs__c = existingSerProd;
        component.set("v.caseRec", caseRec);        
        var caseProdList = component.get("v.caseServiceProducts");
        caseProdList.splice(index, 1);  
        component.set("v.caseServiceProducts", caseProdList);
    },

    serviceTypeDescriptions : function(component, event, helper){
        var serviceContractList = component.get("v.serviceContractList");
        var accId = component.get("v.childAcc");
        if(serviceContractList[0] && accId != null){
            component.set("v.showServiceTypeDescriptions", true);
        }
    },

    closeServiceDescriptionBox : function(component, event, helper){
        component.set("v.showServiceTypeDescriptions", false);
    },

    settingServiceType : function(component, event, helper){
        var scIndex = event.target.id;
        var serviceContractList = component.get("v.serviceContractList");
        var caseRec = component.get("v.caseRec");
        caseRec.Service_Type__c = serviceContractList[scIndex].Service_Type__c;
        component.set("v.caseRec", caseRec);
        var serviceTypeCheckAction = component.get("c.serviceTypeCheck");
        $A.enqueueAction(serviceTypeCheckAction);
    },

    setCaseTemplate : function(component, event, helper){
        var selectedTemplate = component.get("v.selectedTemplate");
        if(selectedTemplate){
            var convertedSelectedTemplate = {};
            var caseTemplateList = component.get("v.caseTemplates");
            for(var ct = 0; ct < caseTemplateList.length; ct++){
                if(caseTemplateList[ct].Name == selectedTemplate){
                    convertedSelectedTemplate = JSON.parse(caseTemplateList[ct].Template__c.replace(/&quot;/g, '"'));
                }
            }
            var caseRec = component.get("v.caseRec");
            caseRec.Service_Type__c = convertedSelectedTemplate.Service_Type__c;
            caseRec.POS_Register_Number__c = convertedSelectedTemplate.POS_Register_Number__c;
            caseRec.PO_Number__c = convertedSelectedTemplate.PO_Number__c;
            caseRec.Support_Team__c = convertedSelectedTemplate.Support_Team__c;
            caseRec.Serial_Numbers__c = convertedSelectedTemplate.Serial_Numbers__c;
            caseRec.Incident__c = convertedSelectedTemplate.Incident__c;
            caseRec.Description = convertedSelectedTemplate.Description;
            caseRec.Priority = convertedSelectedTemplate.Priority;
            caseRec.Onsite_Contact_Name__c = convertedSelectedTemplate.Onsite_Contact_Name__c;
            caseRec.Department2__c = convertedSelectedTemplate.Department2__c;
            caseRec.Equipment_Type__c = convertedSelectedTemplate.Equipment_Type__c;
            caseRec.Problem_Type__c = convertedSelectedTemplate.Problem_Type__c;
            component.set("v.caseRec",caseRec);
            component.set("v.csNotes",convertedSelectedTemplate.Description);
            
            var serviceTypeCheckAction = component.get("c.serviceTypeCheck");
            $A.enqueueAction(serviceTypeCheckAction);
            var setTechNotes = component.get("c.setTechNotes");
            $A.enqueueAction(setTechNotes);
        } else {
            var caseRec = component.get("v.caseRec");
            caseRec.Service_Type__c = null;
            caseRec.POS_Register_Number__c = null;
            caseRec.PO_Number__c = null;
            caseRec.Support_Team__c = null;
            caseRec.Serial_Numbers__c = null;
            caseRec.Incident__c = null;
            caseRec.Description = null;
            caseRec.Priority = null;
            caseRec.Onsite_Contact_Name__c = null;
            
            component.set("v.caseRec",caseRec);
            component.set("v.csNotes",null);
            component.set("v.tchNotes",null);
        }
    },

    saveThisTemplate : function(component, event, helper){
        component.set("v.saveTemplate" , true);
    },

    cancelSavingTemplate : function(component, event, helper){
        component.set("v.saveTemplate" , false);
    },

    createCaseTemplate : function(component, event, helper){
        var caseRec = component.get("v.caseRec");
        var caseJSONString = JSON.stringify(caseRec);
        var createNewTemplate = component.get("c.createNewTemplate");
        createNewTemplate.setParams({
            "RootAccountId" : caseRec.Root_Account__c,
            "selectedTemplate" : caseJSONString,
            "TemplateName" : component.get("v.newTemplateName")
        });
        $A.enqueueAction(createNewTemplate);
        component.set("v.selectedTemplate" , component.get("v.newTemplateName"));
        component.set("v.saveTemplate" , false);
        helper.getCaseTemplates(component, event, helper, caseRec.Root_Account__c);
    },

    selectStores : function(component, event, helper){
        var caseRec = component.get("v.caseRec");
        if(caseRec.Root_Account__c == null){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title : 'Error',
                message : 'Please select main store first',
                duration : ' 6000',
                key : 'info_alt',
                type : 'error',
                mode : 'pester'
            });
            toastEvent.fire();
        } else {
            component.set("v.multipleStoreSection",true);
        }
    },

    cancelMultipleStoreSelection : function(component, event, helper){
        component.set("v.multipleStoreSection",false);
        component.set("v.selectedStoreId",null);
    },

    resetStoreList : function(component, event, helper){
        component.set("v.addedStores",[]);
        component.set("v.selectedStoreId",null);
    },

    saveMultipleStoreSelected : function(component, event, helper){
        component.set("v.multipleStoreSection",false);
        var storeList = component.get("v.addedStores");
        if(storeList.length > 0){
            component.set("v.multipleStoreSelectionIsDone",true);
        } else {
            component.set("v.multipleStoreSelectionIsDone",false);
        }
    },

    addSelectedStore : function(component, event, helper){
        var selectedStoreId = component.get("v.selectedStoreId");
        if(selectedStoreId != null){
            var storeList = component.get("v.addedStores");
            var getSelectedStore = component.get("c.getChildAccount");
            getSelectedStore.setParams({"AccountId" : selectedStoreId.Id});
            getSelectedStore.setCallback(this, function(response){
                if(response.getState() == 'SUCCESS'){
                    var retVal = response.getReturnValue();
                    var valid = true;
                    if(storeList.length > 0){
                        for(var acc = 0; acc < storeList.length; acc++){
                            if(storeList[acc].Name == retVal.Name){
                                valid = false;
                            }
                        }
                    }
                    if(valid){
                        storeList.push(retVal);
                        component.set("v.addedStores",storeList);
                    }
                    var childCmp = component.find("childCmp");
                    if (childCmp) {
                        childCmp.clear(); // This will call the clear method in the child component
                    }
                    var addAccInCases = component.get("c.addAccInCases");
                    $A.enqueueAction(addAccInCases);
                }
            });
            $A.enqueueAction(getSelectedStore);
        }
    },

    removeStore: function(component, event, helper) {
        var storeList = component.get("v.addedStores");
        var accIndex = event.getSource().get("v.title");
        storeList.splice(accIndex, 1);
        component.set("v.addedStores", storeList);
    },

    populateEquipmentType : function(component, event, helper){
        var equipmentTypeList = component.get("v.equipmentTypeList");
        var equipmentTypeName = component.get("v.equipmentTypeName");
        var caseRec = component.get("v.caseRec");
        for(var et= 0; et < equipmentTypeList.length; et++){
            if(equipmentTypeList[et].Name == equipmentTypeName){
                caseRec.Equipment_Type__c = equipmentTypeList[et].Id;
                component.set("v.productGroupingId",equipmentTypeList[et].Product_Grouping__c);
                break;
            }
        }
        component.set("v.caseRec",caseRec);
        helper.getProblemTypes(component, event, helper);
    },

    populateProblemType : function(component, event, helper){
        var problemTypeName = component.get("v.problemTypeName");
        var problemTypeList = component.get("v.problemTypeList");
        var caseRec = component.get("v.caseRec");
        for(var pt= 0; pt < problemTypeList.length; pt++){
            if(problemTypeList[pt].Name == problemTypeName){
                caseRec.Problem_Type__c = problemTypeList[pt].Id;
                break;
            }
        }
        component.set("v.caseRec",caseRec);
    },

    handleProdSelect : function(component, event, helper){
        var selectedProdId = component.get("v.selectedProdId");
        if(selectedProdId == '' || selectedProdId == null) return;

        var scId = (component.get("v.selectedServiceContract") != null) ? component.get("v.selectedServiceContract").Id : '';
        var getBundleProds = component.get("c.getBundleProducts");
        getBundleProds.setParams({
            "scId" : scId,
            "parentProdId" : selectedProdId
        });
        getBundleProds.setCallback(this, function(response){
            if(response.getState() == 'SUCCESS'){
                var retVal = response.getReturnValue();
                var caseProdList = [];
                for(var i=0; i< retVal.length; i++){
                    var subject = (retVal[i].NS_Item_Class__c == 'Bundle Product') ? 'standard:order_item' : 'standard:product';
                    var newCaseProduct = {
                        "Account_Product__c": '',
                        "Quantity__c": retVal[i].Quantity__c,
                        "Case__c": '',
                        "Product__c": retVal[i].Id,
                        "Serial_Number__c": '',
                        "Subject": subject,
                        "customProductLookup": retVal[i]
                    };
                    caseProdList.push(newCaseProduct);
                }
                if(caseProdList.length != 0) {
                    var caseProds = component.get("v.caseProducts");
                    for(var cProd = 0; cProd < caseProds.length; cProd++){
                        if(caseProds[cProd].customProductLookup != undefined && caseProds[cProd].Product__c != null 
                            && caseProds[cProd].customProductLookup.Id != null && caseProds[cProd].customProductLookup.Id != ''){
                            caseProds[cProd].Product__c = caseProds[cProd].customProductLookup.Id;
                        } else {
                            delete caseProds[cProd].customProductLookup;
                            caseProds.splice(cProd,1);
                            cProd--;
                        }
                    }
                    if(caseProds.length != 0) {
                        for(var i=0; i<caseProdList.length; i++) {
                            for(var j=0; j<caseProds.length; j++) {
                                if(caseProds[j].Product__c != caseProdList[i].Product__c) continue;
                                delete caseProds[j].customProductLookup;
                                caseProds.splice(j,1);
                                j--;
                            }
                        }
                    }
                    var joinedList = caseProds.concat(caseProdList);
                    component.set("v.caseProducts", joinedList);
                    helper.showProdPills(component, event);

                    var caseProds1 = component.get("v.caseProducts");
                    for(var i=0; i<caseProds1.length; i++) {
                        if(caseProds1[i].Product__c == undefined && caseProds1[i].customProductLookup.length == undefined) {
                            caseProds1[i].Quantity__c = 1;
                            caseProds1[i].Product__c = '';
                            caseProds1[i].Account_Product__c = '';
                            caseProds1[i].Case__c = '';
                            caseProds1[i].Serial_Numbers__c = '';
                            caseProds1[i].Subject = 'standard:product';
                        }
                    }
                    component.set("v.caseProducts", caseProds1);
                    helper.showProdPills(component, event);
                    component.set("v.selectedProdId",'');
                }
            }
        });
        $A.enqueueAction(getBundleProds);
    }
})