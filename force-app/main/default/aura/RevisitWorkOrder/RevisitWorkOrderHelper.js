({
	helperMethod : function(component, event, helper) {
		var callWo = component.get("c.getWO");
        var workordId = component.get("v.recordId");
        console.log('workordId:'+workordId);
        callWo.setParams({
            woId : workordId
        });
        callWo.setCallback(this, function(response){
            console.log('status callback:'+JSON.stringify(response.getError()));
            if(response.getState() == 'SUCCESS'){
                var retVal = response.getReturnValue();
                component.set("v.workOrderOld", retVal);
                component.set("v.workOrderNew", retVal);
                component.set("v.redHotWO", retVal);
                console.log('calling action...'+retVal.AccountId);
                helper.suprtNoteRecs(component, event, helper);
                helper.prodManagerHelper(component, event, helper);
                var timezone = $A.get("$Locale.timezone");
                component.set("v.timezone",timezone);
                console.log('workOrderOld:'+component.get("v.workOrderOld"));
                var wo = component.get("v.workOrderOld");
                if(wo!= null && wo.Id != null){
                    console.log('wo.Id:'+wo.Id);
                    component.set("v.AccId", wo.AccountId);
                }
                console.log('redHotWO:'+component.get("v.redHotWO"));
                var rho = component.get("v.redHotWO");
                if(rho!= null && rho.Id != null){
                    console.log('rho.Id:'+rho.Id);
                    component.set("v.AccId", rho.AccountId);
                }
            }
        });
        $A.enqueueAction(callWo);
	},
    
    prodManagerHelper : function(component, event, helper) {
        component.set("v.loadSpinner", true);
		var gtNewCL = component.get("c.newCaseLine");
        gtNewCL.setCallback(this, function(response){
            console.log('response:'+JSON.stringify(response.getError()));
            if(response.getState() == 'SUCCESS'){
                //var clList = component.get("v.CaseLineLst");
                var csLine = response.getReturnValue();
                var accId = component.get("v.AccId");
                if(accId != null && accId != '' && accId != undefined){
                    csLine.countId = accId;
                }
                var wo = component.get("v.workOrderOld");
                if(wo != null && wo.Id != null){
                    console.log('wo:'+JSON.stringify(wo));
                    //component.set("v.AccId", wo.AccountId);
                    //AccsLine.countId = accId;
                    if(wo.Case != undefined && wo.Case != null){
                        console.log('wo.Case.Account_Product__c:'+wo.Case.Account_Product__c);
                        csLine.Account_Product__c = wo.Case.Account_Product__c;
                    }
                    if(wo.ParentWorkOrderId != undefined && wo.ParentWorkOrderId != null && wo.ParentWorkOrder.Case != undefined && wo.ParentWorkOrder.Case != null){
                        console.log('wo.ParentWorkOrder.Case.Account_Product__c:'+wo.ParentWorkOrder.Case.Account_Product__c);
                        csLine.Account_Product__c = wo.ParentWorkOrder.Case.Account_Product__c;
                    }
                    csLine.AccountId = wo.AccountId;
                    csLine.ProductId = wo.Product__c;
                    helper.getAccountProduct(component, event, helper, wo.Product__c);
                    //console.log('csLine.Account_Product__c:'+csLine.Account_Product__c);
                }
                var rho = component.get("v.redHotWO");
                if(rho != null && rho.Id != null){
                    console.log('rho.Id:'+rho.Id);
                    //component.set("v.AccId", wo.AccountId);
                    //AccsLine.countId = accId;
                    console.log('rho.Product__c:'+rho.Product__c);
                    if(rho.Case != undefined && rho.Case != null){
                        console.log('rho.Case.Support_Team__c:'+rho.Case.Support_Team__c);
                        csLine.Support_Team__c = rho.Case.Support_Team__c;
                        csLine.Account_Product__c = rho.Case.Account_Product__c;
                    }
                    csLine.AccountId = rho.AccountId;
                    csLine.ProductId = rho.Product__c;
                    helper.getAccountProduct(component, event, helper, rho.Product__c);
                    //console.log('csLine.Account_Product__c:'+csLine.Account_Product__c);
                }
                //clList.push(csLine);
                component.set("v.CaseRec",csLine);
                //component.set("v.CaseLineLst", clList);
                component.set("v.loadSpinner", false);
            }
        });
        $A.enqueueAction(gtNewCL);
	},
    
    getAccountProduct : function(component, event, helper, proId) {
		var gtAccProdId = component.get("c.getAccProductId");
        gtAccProdId.setParams({
            ProdId : proId
        });
        gtAccProdId.setCallback(this, function(response){
            console.log('account Product response error:'+JSON.stringify(response.getError()));
            if(response.getState() == 'SUCCESS'){
                var retVal = response.getReturnValue();
                console.log('retval accprodId:'+retVal);
                var caseRec = component.get("v.CaseRec");
                //for(var i = 0; i < csLst.length; i++){
                    caseRec.Account_Product__c = retVal;
                //}
                component.set("v.CaseRec", caseRec);
            }
        });
        $A.enqueueAction(gtAccProdId);
	},
    
    prodHandlingCode : function(component, event, helper, productId){
        //var productId = event.getSource().get("v.value")[0];
        console.log('product id--->'+productId);
        //console.log('product id--->'+JSON.stringify(productId));
        if(productId != '' && productId != undefined){
            var hcMthd = component.get("c.prodtHdlCode");
            hcMthd.setParams({
                "prodId" : productId
            });
            hcMthd.setCallback(this, function(response){
                console.log('response status--->'+JSON.stringify(response.getError()));
                if(response.getState() == 'SUCCESS'){
                    var retVal = response.getReturnValue();
                    console.log('handle code--->'+retVal);
                    var caseRec = component.get("v.CaseRec");
                    //for(var i = 0; i < cases.length; i++){
                      //  if(cases[i].ProductId == productId){
                            caseRec.HandleCode = retVal;
                        //}
                    //}
                    component.set("v.CaseRec", cases);
                }
            });
            $A.enqueueAction(hcMthd);
        }
    },
    
    createCaseInstance : function(component, event, helper) {
		var gtNewCL = component.get("c.newCase");
        gtNewCL.setCallback(this, function(response){
            if(response.getState() == 'SUCCESS'){
                component.set("v.CaseRec1", response.getReturnValue());
                component.set("v.loadSpinner", false);
            }
        });
        $A.enqueueAction(gtNewCL);
	},
    
    suprtNoteRecs : function(component, event, helper){
        var getSprtNotes = component.get("c.getSupportTeamNotes");
        getSprtNotes.setCallback(this, function(response){
            if(response.getState() == 'SUCCESS'){
                component.set("v.supportTeams", response.getReturnValue());
                console.log('support team:'+JSON.stringify(response.getReturnValue()));
            }
        });
        $A.enqueueAction(getSprtNotes);
    },

    getProblemCodes : function(component, event, helper, prodId){
        console.log('getProblemCodes prodId:'+prodId);
        var getProdProbCodes = component.get("c.getProductProblemCodes");
        getProdProbCodes.setParams({"prodId":prodId});
        getProdProbCodes.setCallback(this, function(response){
            if(response.getState() == 'SUCCESS'){
                console.log('Problem Codes:'+JSON.stringify(response.getReturnValue()));
                component.set("v.ProblemCodeOptions", response.getReturnValue());
            } else {
                console.log('Error:'+JSON.stringify(response));
            }
        });
        $A.enqueueAction(getProdProbCodes);
    }
})