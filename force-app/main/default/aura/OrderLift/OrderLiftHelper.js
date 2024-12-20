({
    helperMethod : function(component, event, helper, recordId) {
        component.set("v.loadSpinner",true);
        var checkForExistingWOLI = component.get("c.checkForExistingWOLI");
        checkForExistingWOLI.setParams({
            'woId' : recordId
        });
        checkForExistingWOLI.setCallback(this, function(response) {
            var state = response.getState();
            var  result = response.getReturnValue();
            console.log('checkForExistingWOLI state-> ' + response.getState());
            if (result == true) {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title : 'Error',
                    message : 'Lift is already requested!',
                    duration : ' 2000',
                    key : 'info_alt',
                    type : 'error',
                    mode : 'pester'
                });
                toastEvent.fire();
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
            } else {
                component.set("v.loadSpinner",false);
                helper.getwoRec(component, event, helper);
            }
        });
        $A.enqueueAction(checkForExistingWOLI);
    }, 
    
    getwoRec: function(component, event, helper) {
        console.log('wo Id-> ' + component.get("v.recordId"));
        var getwoRec = component.get("c.getwoRec");
        getwoRec.setParams({
            'woId': component.get("v.recordId")
        });
        getwoRec.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var woRec = response.getReturnValue();
                component.set("v.woRec", woRec);
                console.log('woRec-> ' + JSON.stringify(woRec));
                
                if (woRec.Preferred_Time_IMAC__c) {
                    var prefDateIMACString = woRec.Preferred_Time_IMAC__c.split('T')[0];
                    component.set("v.prefDate", prefDateIMACString);
                    console.log('prefDate-> ' + component.get("v.prefDate"));
                }
            }
        });
        $A.enqueueAction(getwoRec);
    }
})