({
	markInProgress : function(component, event, helper) {
		component.set("v.loadSpinner",true);
		console.log('ws Id-> ' + component.get("v.recordId"));
		var updateWorkStep = component.get("c.updateWorkStep");
		updateWorkStep.setParams({
            'wsId': component.get("v.recordId")
        });
        updateWorkStep.setCallback(this, function(response) {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title : 'Success',
                message : 'The work step is in progress.',
                duration : ' 2000',
                key : 'info_alt',
                type : 'success',
                mode : 'pester'
            });
            toastEvent.fire();
            component.set("v.loadSpinner",false);
            $A.get('e.force:refreshView').fire();
            var dismissActionPanel = $A.get("e.force:closeQuickAction");
            dismissActionPanel.fire();
    	});
        $A.enqueueAction(updateWorkStep);
	}
})