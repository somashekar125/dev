({
	myAction : function(component, event, helper) {
		helper.helperMethod(component, event, helper);
	},
    
    openProdComponent : function(component, event, helper){
        component.set("v.revisitSelect", true);
    },
    
    prevProdComponent : function(component, event, helper){
        component.set("v.revisitSelect", false);
    },
    
    openComp : function(component, event, helper){
        component.set("v.openComponent", true);
    },
    
    openCompForRHO : function(component, event, helper){
        component.set("v.createRedHotOrder", true);
    },
    
    closeModel : function(component, event, helper){
        component.set("v.openComponent", false);
        component.set("v.createRedHotOrder", false);
        component.set("v.revisitSelect", false);
    },
    
    oosPriorityChng : function(component, event, helper){
        console.log('calling function...');
        var caseRec = component.get("v.CaseRec");
        //for(var i = 0; i < cses.length; i++){
            if(caseRec.Out_Of_Scope__c){
                console.log('caseRec.Out_Of_Scope__c:'+caseRec.Out_Of_Scope__c);
                caseRec.Priority = 'Severity 2';
            }
        //}
        component.set("v.CaseRec", caseRec);
    },
    
    openTechNotesPop : function(component, event, helper){
        //var idx = event.target.id;
        //console.log('index:'+idx);
        var teamId = component.get("v.CaseRec").Support_Team__c;
        console.log('component.get("v.CaseRec").Support_Team__c:'+component.get("v.CaseRec").Support_Team__c);
        var supportTeamRecs = component.get("v.supportTeams");
        for(var i = 0; i < supportTeamRecs.length; i++){
            if(supportTeamRecs[i].Id == teamId){
                component.set("v.tchNotes", supportTeamRecs[i].Tech_Notes__c);
                component.set("v.openTechNotes", true);
            }
        }
        if(component.get("v.revisitSelect")){
            component.set("v.revisitSelect", false);
            component.set("v.openComponent", false);
            component.set("v.WOType", 'Revisit');
        }else{
            component.set("v.createRedHotOrder", false);
            component.set("v.WOType", 'RedHot');
        }
        //component.set("v.indxTchNts",idx);
    },
    
    openNotesPop : function(component, event, helper){
        component.set("v.openNotes", true);
        //var idx = event.target.id;
        //console.log('index:'+idx);
        component.set("v.csNotes", component.get("v.CaseRec").Description);
        if(component.get("v.revisitSelect")){
            component.set("v.revisitSelect", false);
            component.set("v.openComponent", false);
            component.set("v.WOType", 'Revisit');
        }else{
            component.set("v.createRedHotOrder", false);
            component.set("v.WOType", 'RedHot');
        }
        //component.set("v.indxTchNts",idx);
    },
    
    closeModelNotes : function(component, event, helper){
        component.set("v.openTechNotes", false);
        component.set("v.openNotes", false);
        if(component.get("v.WOType") == 'Revisit'){
            component.set("v.revisitSelect", true);
            component.set("v.openComponent", true);
        }else{
            component.set("v.createRedHotOrder", true);
        }
        component.set("v.WOType", '');
    },
    
    enterTechNotes  : function(component, event, helper){
        var caseRec = component.get("v.CaseRec");
        var idxToSet = component.get("v.indxTchNts");
        var supTeams = component.get("v.supportTeams");
        for(var i = 0; i < supTeams.length; i++){
            if(supTeams[i].Id == caseRec.Support_Team__c){
                supTeams[i].Tech_Notes__c = component.get("v.tchNotes");
            }
        }
        console.log('index to set:'+idxToSet);
        caseRec.Tech_Notes__c = component.get("v.tchNotes");
        component.set("v.CaseRec", caseRec);
        component.set("v.tchNotes", '');
        component.set("v.indxTchNts", null);
        component.set("v.openTechNotes", false);
        if(component.get("v.WOType") == 'Revisit'){
            component.set("v.revisitSelect", true);
            component.set("v.openComponent", true);
        }else{
            component.set("v.createRedHotOrder", true);
        }
        component.set("v.WOType", '');
    },
    
    setTechNotes : function(component, event, helper){
        var supTeams = component.get("v.supportTeams");
        var caseRec = component.get("v.CaseRec");
        if(caseRec.Support_Team__c != null){
            for(var i = 0; i < supTeams.length; i++){
                if(caseRec.Support_Team__c == supTeams[i].Id){
                    caseRec.Tech_Notes__c = supTeams[i].Tech_Notes__c;
                }
            }
        }
        component.set("v.CaseRec", caseRec);
    },
    
    enterNotes  : function(component, event, helper){
        var caseRec = component.get("v.CaseRec");
        //console.log('component.get("v.indxTchNts"):'+component.get("v.indxTchNts"));
        //var idxToSet = component.get("v.indxTchNts");
        //console.log('idxToSet:'+idxToSet);
        caseRec.Description = component.get("v.csNotes");
        component.set("v.CaseRec", caseRec);
        component.set("v.csNotes", '');
        component.set("v.indxTchNts", null);
        component.set("v.openNotes", false);
        if(component.get("v.WOType") == 'Revisit'){
            component.set("v.revisitSelect", true);
            component.set("v.openComponent", true);
        }else{
            component.set("v.createRedHotOrder", true);
        }
        component.set("v.WOType", '');
    },
    
    addAccInCases : function(component, event, helper){
        var accId = component.get("v.AccId");
        var caseRec = component.get("v.CaseRec");
        //for(var i = 0; i < cases.length; i++){
            caseRec.AccountId = accId;
        //}
        component.set("v.CaseRec",caseRec);
    },
    
    serviceTypeCheck : function(component, event, helper){
        var caseRec = component.get("v.CaseRec");
        var chck = false;
        var chckIMAC = false;
        //for(var i = 0; i < prodItems.length; i++){
            if(caseRec.Service_Type__c == 'Advance Exchange (Depot Only)' || caseRec.Service_Type__c == 'Advance Exchange + Onsite'){
                chck = true;
                caseRec.Priority = 'Severity 2';
                console.log('AE chck:'+chck);
            }
            if(caseRec.Service_Type__c == 'Onsite IMAC'){
                chckIMAC = true;
            }
        //}
        component.set("v.repairItem", chck);
        component.set("v.imacChk", chckIMAC);
        component.set("v.CaseRec", prodItems);
        console.log('user timezone:'+component.get("v.timezone"));
    },
    
    setPriority : function(component, event, helper){
        console.log('calling function...');
        var caseRec = component.get("v.CaseRec");
        if(caseRec.Preferred_Time__c != null && caseRec.Preferred_Time__c != '' && caseRec.Preferred_Time__c != undefined){
            
            var timezone = $A.get("$Locale.timezone");
            console.log('Time Zone Preference in Salesforce ORG :'+timezone);
            
            var prefDt1 = new Date(caseRec.Preferred_Time__c);
            console.log('prefDt local timezone--->'+prefDt1);
            
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
            console.log('prefDt user timezone--->'+prefDt);
            
            /*console.log('prefDt1.getTimezoneOffset()--->'+prefDt1.getTimezoneOffset());
                prefDt1.setTime(prefDt1.getTime()+prefDt1.getTimezoneOffset()*60*1000);
                var offset = -240; //Timezone offset for ORG wide in minutes.
                var prefDt = new Date(prefDt1.getTime() + (offset*60*1000));
                console.log('prefDt ORG timezone--->'+prefDt);*/
                //var daysFrmNow = Math.ceil((prefDt.getTime() - dtNow.getTime())/ (1000 * 3600 * 24));
                //console.log('prefDt-dtNow:'+daysFrmNow);
                console.log('csLst[i].Preferred_Time__c:'+prefDt);
                var prefHour = prefDt.getHours();
                console.log('prefHour:'+prefHour);
                var prefDay = prefDt.getDay();
                console.log('prefDay:'+prefDay);
                /*
                if(daysFrmNow <= 3 || (prefHour < 8 || prefHour > 22)){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title : 'Error',
                        message : 'selected time must be at least 72 hours after current time and also the selected time between 8am and 10pm',
                        duration : ' 6000',
                        key : 'info_alt',
                        type : 'error',
                        mode : 'pester'
                    });
                    toastEvent.fire();
                    //return;
                }*/
                if((prefDay == 0 || prefDay == 6) || ((prefDay > 0 && prefDay < 6) && (prefHour < 8 || prefHour >= 17))){
                    caseRec.Priority = 'Severity 1';
                }else if((prefDay > 0 && prefDay < 6) && (prefHour >= 8 && prefHour < 17)){
                    caseRec.Priority = 'Severity 2';
                }
                var wo = component.get("v.workOrderOld");
                if(wo != null && wo.Id != null){
                    caseRec.Priority = 'Severity 2';
                }
            }
        component.set("v.CaseRec",csLst);
    },
    
    assginProducts : function(component, event, helper){
        var accproductId = event.getSource().get("v.value")[0];
        console.log('accproductId id--->'+accproductId);
        console.log('accproductId id--->'+JSON.stringify(accproductId));
        if(accproductId != '' && accproductId != undefined){
            var getProdId = component.get("c.getProductId");
            getProdId.setParams({
                "accProdId" : accproductId
            });
            getProdId.setCallback(this, function(response){
                console.log('response status--->'+JSON.stringify(response.getError()));
                if(response.getState() == 'SUCCESS'){
                    var retVal = response.getReturnValue();
                    console.log('Product id --->'+retVal);
                    var caseRec = component.get("v.CaseRec");
                    console.log('caseRec :'+JSON.stringify(component.get("v.CaseRec")));
                    //for(var i = 0; i < cases.length; i++){
                        if(caseRec.Account_Product__c == accproductId){
                            caseRec.ProductId = retVal;
                        }
                    //}
                    component.set("v.CaseRec", caseRec);
                    console.log('caseRec productId:'+JSON.stringify(component.get("v.CaseRec")));
                    helper.prodHandlingCode(component, event, helper, retVal);
                    helper.getProblemCodes(component, event, helper, retVal);
                }
            });
            $A.enqueueAction(getProdId);
        }
    },
    
    saveRecords : function(component, event, helper){
        component.set("v.loadSpinner", true);
        var casesToSave = component.get("v.CasesToSave");
        var caseRec = component.get("v.CaseRec");
        console.log('caseRec:'+JSON.stringify(component.get("v.CaseRec")));
        if(caseRec != undefined){
            var productIds = [];
            for(var i = 0; i < casesToSave.length; i++){
                productIds.push(casesToSave[i].Account_Product__c);
            }
            if(!productIds.includes(caseRec.Account_Product__c)){
                casesToSave.push(caseRec);
            }
            component.set("v.CasesToSave", casesToSave);
            console.log('caseRec:'+JSON.stringify(component.get("v.CaseRec")));
        }
        var acId = component.get("v.AccId");
        var clList = component.get("v.CasesToSave");
        var supptTeams = component.get("v.supportTeams");
        var clListSave = [];
        var supportTeam = {};
        if(clList.length != 0){
            for(var i = 0; i < clList.length; i++){
                console.log('clList[i].Preferred_Time__c--->'+clList[i].Preferred_Time__c);
                console.log('clList[i].AccountId:'+clList[i].AccountId);
                if(clList[i].Support_Team__c != null){
                    var suptTeams = component.get("v.supportTeams");
                    for(var s = 0; s < suptTeams.length; s++){
                        if(clList[i].Support_Team__c == suptTeams[s].Id){
                            supportTeam = suptTeams[s];
                        }
                    }
                }
                if(clList[i].Service_Type__c == 'Onsite IMAC' && (clList[i].Preferred_Time__c == undefined || clList[i].Preferred_Time__c == '' || clList[i].Preferred_Time__c == null)){
                     console.log('null preferred time...');
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title : 'Error',
                        message : 'Please select Preferred Time for Onsite IMAC products!',
                        duration : ' 5000',
                        key : 'info_alt',
                        type : 'error',
                        mode : 'pester'
                    });
                    toastEvent.fire();
                    component.set("v.loadSpinner", false);
                    return;
                }
                if(clList[i].Preferred_Time__c != null && clList[i].Preferred_Time__c != '' && clList[i].Preferred_Time__c != undefined){
                    var timezone = $A.get("$Locale.timezone");
                    console.log('Time Zone Preference in Salesforce ORG :'+timezone);
                    var prefDt1 = new Date(clList[i].Preferred_Time__c);
                    console.log('prefDt local timezone--->'+prefDt1);
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
                    /*
                    console.log('prefDt1.getTimezoneOffset()--->'+prefDt1.getTimezoneOffset());
                    prefDt1.setTime(prefDt1.getTime()+prefDt1.getTimezoneOffset()*60*1000);
                    var offset = -240; //Timezone offset for ORG wide in minutes.
                    var prefDt = new Date(prefDt1.getTime() + (offset*60*1000));*/
                    var prefDt = changeTimezone(prefDt1, timezone)
                    console.log('prefDt ORG timezone--->'+prefDt);
                    var dtNow1 = new Date();
                    console.log('dtNow1 local timezone--->'+dtNow1);
                    /*console.log('dtNow1.getTimezoneOffset()--->'+dtNow1.getTimezoneOffset());
                    dtNow1.setTime(dtNow1.getTime()+dtNow1.getTimezoneOffset()*60*1000);*/
                    var dtNow = changeTimezone(dtNow1, timezone);
                    var daysFrmNow = Math.ceil((prefDt.getTime() - dtNow.getTime())/ (1000 * 3600 * 24));
                    console.log('prefDt-dtNow:'+daysFrmNow);
                    console.log('csLst[i].Preferred_Time__c:'+prefDt);
                    var prefHour = prefDt.getHours();
                    console.log('prefHour:'+prefHour);
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
                if(clList[i].Support_Team__c != null){
                    console.log('entering support team...');
                    for(var k = 0; k < supptTeams.length; k++){
                        if(supptTeams[k].Id == clList[i].Support_Team__c){
                            clList[i].Customer_Notification_Email__c = supptTeams[k].Email__c;
                        }
                    }
                }
                if(clList[i].OOS_Product__c != null){
                    clList[i].ProductId = clList[i].OOS_Product__c;
                }
                if(clList[i].Product__c != null || clList[i].Asset_Number__c != null || clList[i].Service_Type__c != null || clList[i].Problem_Code__c != null || clList[i].Description != null){
                    clListSave.push(clList[i]);
                }
            }
        }
        if(acId != null && acId != '' && clListSave.lenght != 0){
            var oldWO = component.get("v.workOrderOld");
            var newWO = component.get("v.workOrderNew");
            var svRecs = component.get("c.CreateCaseRecs");
            var redHotOrder = component.get("v.createRedHotOrder");
            if(redHotOrder){
                oldWO = null;
                newWO = null;
            }
            svRecs.setParams({
                accId : acId,
                CsLines : clListSave,
                oldWorkOrder : oldWO,
                newWorkOrder : newWO,
                redHotOrder : redHotOrder
            });
            svRecs.setCallback(this, function(response){
                component.set("v.loadSpinner", false);
                console.log('response.get state--->'+response.getState());
                console.log('response.get state--->'+JSON.stringify(response.getError()));
                if(response.getState() == 'SUCCESS'){
                    var retVal = response.getReturnValue();
                    console.log('return value--->'+retVal);
                    if(retVal.length == 15 || retVal.length == 18){
                        /*component.set("v.saveMessage", 'Service items has been saved successfully!');
                        component.set("v.saveSuccess", true);
                        component.set("v.saveError", false);*/
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
                        //window.reload();
                        //location.reload();
                        window.open('/'+retVal, '_self');
                    }else{
                        /*component.set("v.saveMessage", retVal);
                        component.set("v.saveError", true);*/
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            title : 'Error',
                            message : retVal,
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
        }else{
            component.set("v.loadSpinner", false);
            //component.set("v.saveMessage", 'Please fill in location of the service and Product line items!');
            //component.set("v.saveError", true);
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title : 'Error',
                message : 'Please fill in location of the service and Product line items!',
                duration : ' 5000',
                key : 'info_alt',
                type : 'error',
                mode : 'pester'
            });
            toastEvent.fire();
        }
        
    },
    setProblemCode : function(component, event, helper){
        var caseName = event.getSource().get('v.name');
        console.log('caseName:'+caseName);
        var caseIndex = caseName.split('-')[1];
        console.log('caseIndex:'+caseIndex);
        //console.log(component.get("v.CaseLineLst").length);
        var Case = component.get("v.CaseRec");
        var prbCode = event.getSource().get('v.value')
        console.log('prbCode:'+prbCode);
        Case.Problem_Code__c = prbCode;
    }
})