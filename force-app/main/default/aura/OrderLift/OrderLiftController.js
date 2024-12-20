({
    myAction : function(component, event, helper) {
        var recordId = component.get("v.recordId");
		console.log('recordId-> ' + recordId);        
		helper.helperMethod(component, event, helper, recordId);
    },
    
    requestLift : function(component, event, helper){
        component.set("v.loadSpinner",true);
        console.log('loadSpinner-> ' + component.get("v.loadSpinner"));
        var recordId = component.get("v.recordId");
        var prefDate = component.get("v.prefDate");
        var prefTime = component.get("v.prefTime");
        var vendor = component.get("v.vendor");
        console.log('prefDate-> ' + prefDate);
        console.log('prefTime-> ' + prefTime);
        console.log('vendor-> ' + vendor);
        
		var orderingLift = component.get("c.orderingLift");
		orderingLift.setParams({
			'woId' : recordId,
            'vendor' : vendor,
            'prefDate' : prefDate,
            'prefTime' : prefTime
        });
        orderingLift.setCallback(this, function(response) {
            var state = response.getState();
            var  result = response.getReturnValue();
			console.log('orderingLift state-> ' + response.getState());
             if (result == true) {
            	console.log('SUCCESS');
				var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
					title : 'Success',
					message : 'Lift Requested!',
					duration : ' 1000',
					key : 'info_alt',
					type : 'success',
					mode : 'pester'
				});
				toastEvent.fire();
                component.set("v.loadSpinner",false);
                $A.get('e.force:refreshView').fire();
				var dismissActionPanel = $A.get("e.force:closeQuickAction");
				dismissActionPanel.fire();
            } else {
                console.log('Error-> ' + JSON.stringify(response.getError()));
                component.set("v.loadSpinner",false);
            }
    	});
        $A.enqueueAction(orderingLift);
	}
})