({
    myAction : function(component, event, helper) {
        var recordId = component.get("v.recordId");
		console.log('recordId-> ' + recordId);
		var returningLift = component.get("c.returningLift");
		returningLift.setParams({
			'woId' : recordId
        });
        returningLift.setCallback(this, function(response) {
            var state = response.getState();
            var  result = response.getReturnValue();
			console.log('returningLift state-> ' + response.getState());
            if (result == true) {
            	console.log('SUCCESS');
				var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
					title : 'Success',
					message : 'Return Lift Requested!',
					duration : ' 1000',
					key : 'info_alt',
					type : 'success',
					mode : 'pester'
				});
				toastEvent.fire();		
                $A.get('e.force:refreshView').fire();
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
				dismissActionPanel.fire();
            } else {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title : 'Error',
                    message : 'Return lift is already requested / Returning lifts not found!',
                    duration : ' 2000',
                    key : 'info_alt',
                    type : 'error',
                    mode : 'pester'
                });
                toastEvent.fire();
				var dismissActionPanel = $A.get("e.force:closeQuickAction");
				dismissActionPanel.fire();
            }
    	});
        $A.enqueueAction(returningLift);
    }
})