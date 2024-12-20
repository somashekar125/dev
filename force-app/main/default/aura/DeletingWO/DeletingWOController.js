({
    myAction : function(component, event, helper) {
        var recordId = component.get("v.recordId");
        console.log('recordId-> ' + recordId);
        if(recordId.includes("0WO")){
            helper.checkInvalidWOs(component,event,helper);
            helper.getRelatedWOs(component,event,helper);
        }
    },
    
    deleteCurrentWO : function(component, event, helper) {
        component.set("v.loadSpinner",true);
        var recordId = component.get("v.recordId");
        var deleteCurrentWorkOrder = component.get("c.deleteCurrentWorkOrder");
        deleteCurrentWorkOrder.setParams({
            'workOrderId': recordId
        });
        deleteCurrentWorkOrder.setCallback(this, function(response) {
            var state = response.getState();
            console.log('state-> ' + state);
            var error = response.getError();
            console.log('error-> ' + JSON.stringify(error));
            var result = response.getReturnValue();
            if (result == true) {
                var msg = 'Work Order ' + component.get("v.workOrderNumber") + ' was deleted.';
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title : 'Success',
                    message : msg,
                    duration : ' 2000',
                    key : 'info_alt',
                    type : 'success',
                    mode : 'pester'
                });
                toastEvent.fire();
                //component.set("v.loadSpinner",false);
                var homeEvent = $A.get("e.force:navigateToObjectHome");
                homeEvent.setParams({
                    "scope": "WorkOrder"
                });
                homeEvent.fire();
            }
        });
        $A.enqueueAction(deleteCurrentWorkOrder);
    },
    
    deleteAll : function(component, event, helper) {
        component.set("v.loadSpinner",true);
        var recordId = component.get("v.recordId");
        var deleteAllWOsAndCase = component.get("c.deleteAllWOsAndCase");
        deleteAllWOsAndCase.setParams({
            'workOrderId': recordId
        });
        deleteAllWOsAndCase.setCallback(this, function(response) {
            var state = response.getState();
            console.log('state-> ' + state);
            var error = response.getError();
            console.log('error-> ' + JSON.stringify(error));
            var result = response.getReturnValue();
            if (result == true) {
                var msg = 'All sibling work orders & its case are deleted';
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title : 'Success',
                    message : msg,
                    duration : ' 2000',
                    key : 'info_alt',
                    type : 'success',
                    mode : 'pester'
                });
                toastEvent.fire();
                component.set("v.loadSpinner",false);
                var homeEvent = $A.get("e.force:navigateToObjectHome");
                homeEvent.setParams({
                    "scope": "WorkOrder"
                });
                homeEvent.fire();
            }
        });
        $A.enqueueAction(deleteAllWOsAndCase);
    },
    
    handleCancel : function(component, event, helper) {
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
		dismissActionPanel.fire();
    }
})