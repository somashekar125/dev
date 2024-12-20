({
	myAction : function(component, event, helper) {
		
	},
    
    createSev2WO : function(component, event, helper){
        component.set("v.loadSpinner", true);
        var sev1Id = component.get("v.recordId");
        console.log('sev 1 id--->'+sev1Id);
        var callAction = component.get("c.CreateSev2Wo");
        callAction.setParams({
            sev1WOId : sev1Id
        });
        callAction.setCallback(this, function(response){
            console.log('save error--->'+JSON.stringify(response.getError()));
            if(response.getState() == 'SUCCESS'){
                var retVal = response.getReturnValue();
                console.log('return value--->'+retVal.length+'-----'+retVal);
                if((retVal.length == 18) || (retVal.length == 15)){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title : 'Success',
                        message : 'Severity 2 Work Order has been created!',
                        duration : ' 5000',
                        key : 'info_alt',
                        type : 'success',
                        mode : 'pester'
                    });
                    toastEvent.fire();
                    location.href = '/'+retVal;
                    //location.reload();
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
                }
                component.set("v.loadSpinner", false);
            }
        });
        $A.enqueueAction(callAction);
    }
})