({
	getWorkOrder : function(component, event, helper) {
        var woRecId = component.get("v.recordId");
        console.log('work order id--->'+woRecId);
		var totWos = component.get("c.bndlWordOrdr");
        totWos.setParams({
            bndlWoId : woRecId
        });
        totWos.setCallback(this, function(response){
            console.log('error--->'+JSON.stringify(response.getError()));
            if(response.getState() == 'SUCCESS'){
                var retVal = response.getReturnValue();
                component.set("v.bundleWO", retVal);
                console.log('bundle work order--->'+JSON.stringify(retVal));
                console.log('account id--->'+retVal.AccountId);
                helper.getTotalWos(component, event, helper, retVal.AccountId, retVal.Bundle_Id__c);
                helper.getBndlWos(component, event, helper, retVal.Bundle_Id__c, retVal.Id);
            }
        });
        $A.enqueueAction(totWos);
	},
    
    getBndlWos : function(component, event, helper, bundlId, bwoId) {
        //var accntId = component.get("v.bundleWO").AccountId;
        console.log('bundlId id--->'+bundlId);
        if(bundlId != null){
            var totWos = component.get("c.bndlWOs");
            totWos.setParams({
                bndlId : bundlId,
                bndWoId : bwoId
            });
            totWos.setCallback(this, function(response){
                console.log('error bndls--->'+JSON.stringify(response.getError()));
                if(response.getState() == 'SUCCESS'){
                    var retVal = response.getReturnValue();
                    if(retVal.length != 0){
                        for(var i = 0; i < retVal.length; i++){
                            retVal[i].bndlChk = true;
                            retVal[i].woRecLink = '/'+retVal[i].Id;
                            if(retVal[i].Account != undefined){
                                console.log('retVal[i].Account.Name--->'+retVal[i].Account.Name);
                                retVal[i].AccountName = retVal[i].Account.Name;
                            }
                            if(retVal[i].Product__r != undefined){
                                console.log('retVal[i].Account.Name--->'+retVal[i].Product__r.Name);
                                retVal[i].ProductName = retVal[i].Product__r.Name;
                            }
                        }
                        console.log('bundle wos length--->'+retVal.length);
                        component.set("v.bndlWOs", retVal);
                        component.set("v.loadSpinner", false);
                    }
                }
            });
            $A.enqueueAction(totWos);
        }
	},
    
    getTotalWos : function(component, event, helper, accntId, bundleId) {
        //var accntId = component.get("v.bundleWO").AccountId;
        console.log('account id--->'+accntId);
		var totWos = component.get("c.totAccWorkOrders");
        totWos.setParams({
            accId : accntId,
            bndlId : bundleId
        });
        totWos.setCallback(this, function(response){
            if(response.getState() == 'SUCCESS'){
                var retVal = response.getReturnValue();
                if(retVal.length != 0){
                    for(var i = 0; i < retVal.length; i++){
                        retVal[i].bndlChk = false;
                        retVal[i].woRecLink = '/'+retVal[i].Id;
                        if(retVal[i].Account != undefined){
                            console.log('retVal[i].Account.Name--->'+retVal[i].Account.Name);
                            retVal[i].AccountName = retVal[i].Account.Name;
                        }
                        if(retVal[i].Product__r != undefined){
                            console.log('retVal[i].Account.Name--->'+retVal[i].Product__r.Name);
                            retVal[i].ProductName = retVal[i].Product__r.Name;
                        }
                    }
                    component.set("v.totalWOs", retVal);
                    component.set("v.loadSpinner", false);
                }
            }
        });
        $A.enqueueAction(totWos);
	},
    
    bndlAddRemove : function(component, event, helper, woLsts){
        console.log('wo list to add/remove'+woLsts.length)
        if(woLsts.length != 0){
            var savBkt = component.get("c.saveToBndl");
            savBkt.setParams({
                woLst : woLsts
            });
            savBkt.setCallback(this, function(response){
                console.log('response save--->'+JSON.stringify(response.getError()));
                if(response.getState() == 'SUCCESS'){
                    var retVal = response.getReturnValue();
                    console.log('return value--->'+retVal);
                    if(retVal == 'success'){
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            title : 'Success',
                            message : 'Work Order successfully added to this bundle!',
                            duration : ' 5000',
                            key : 'info_alt',
                            type : 'success',
                            mode : 'pester'
                        });
                        toastEvent.fire();
                        component.set("v.selectedRows", []);
                        helper.getWorkOrder(component, event, helper);
                    }else{
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
                        component.set("v.loadSpinner", false);
                    }
                }
            });
            $A.enqueueAction(savBkt);
        }
    }
})