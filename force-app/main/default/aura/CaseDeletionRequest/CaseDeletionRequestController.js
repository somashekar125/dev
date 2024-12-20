({
	myAction : function(component, event, helper) {
		var caseId = component.get("v.recordId");
        console.log('caseId:'+caseId);
        var caseRec = component.get("c.getCaseRecord");
        caseRec.setParams({
            caseId : caseId
        });
        caseRec.setCallback(this, function(response){
            console.log('response Error:'+response.getError());
            if(response.getState() == 'SUCCESS'){
                var retVal = response.getReturnValue();
                console.log('retVal:'+retVal);
                component.set("v.CaseRecord", retVal);
                if (retVal.Status == 'New' || retVal.Status == 'Acknowledged' || retVal.Status == 'Scheduling' || retVal.Status == 'Technician Scheduled / Assigned' || 
                    retVal.Status == 'Tech Checked In' || retVal.Status == 'Rescheduled' || retVal.Status == 'Revisit Required' || retVal.Status == 'Onsite Work Completed' ||
                    retVal.Status == 'Part Ordered' || retVal.Status == 'Part Shipped') {
                    component.set("v.showRequestButton", true);
                } else {
                    component.set("v.showRequestButton", false);
                }
            }
        });
        $A.enqueueAction(caseRec);
	},
    
    confirmSubmit : function(component, event, helper){
        component.set("v.confirmDelete", true);
    },
    
    closeModel : function(component, event, helper){
        component.set("v.confirmDelete", false);
    },
    
    submitDeletionReq : function(component, event, helper){
        component.set("v.loadSpinner", true);
        var caseId = component.get("v.recordId");
        console.log('caseId:'+caseId);
        var delCall = component.get("c.caseDeletionRequest");
        delCall.setParams({
            caseId : caseId
        });
        delCall.setCallback(this, function(response){
            if(response.getState() == 'SUCCESS'){
                var retVal = response.getReturnValue();
                if(retVal == 'success'){
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
                    
                    window.setTimeout(
                        $A.getCallback(function() {
                            component.set("v.confirmDelete", false);
                            component.set("v.loadSpinner", false);
                            location.reload();
                        }), 1000
                    );
                    
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
        $A.enqueueAction(delCall);
    },
    
    orderPart : function(component, event, helper) {
        return;
        component.set("v.loadSpinner", true);
		var caseId = component.get("v.recordId");
        var callMethod = component.get("c.includePartWO");
        callMethod.setParams({
            caseId : caseId
        });
        callMethod.setCallback(this, function(response){
            console.log('response.getState::'+response.getState());
            console.log('response.getError::'+JSON.stringify(response.getState()));
            if(response.getState() == 'SUCCESS'){
                var toastEvnt = $A.get("e.force:showToast");
                toastEvnt.setParams({
                    title : 'Success',
                    message : 'Part has been ordered successfully!',
                    duration : ' 5000',
                    key : 'info_alt',
                    type : 'success',
                    mode : 'pester'
                });
                toastEvnt.fire();
                component.set("v.loadSpinner", false);
                location.reload();
            }
        });
        $A.enqueueAction(callMethod);
	}
})