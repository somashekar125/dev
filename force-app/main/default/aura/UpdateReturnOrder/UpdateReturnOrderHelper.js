({
	helperMethod : function(component,event,helper,recordId) {
		console.log('--helperMethod--');
		console.log('recordId-> ' + recordId);
		component.set("v.loadSpinner",true);
		//var recordId = component.get("v.recordId");
		var checkWOOwnerId = component.get("c.checkWOOwnerId");
		checkWOOwnerId.setParams({
			'woId' : recordId
        });
        checkWOOwnerId.setCallback(this, function(response) {
            var result = response.getReturnValue();
			console.log('checkWOOwnerId state-> ' + response.getState());
            if (result == true) {
            	console.log('SUCCESS');
				component.set("v.fieldTechOwnerExist",true);
            } else {
				console.log('Failed');
				component.set("v.fieldTechOwnerExist",false);
				var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
					title : 'Error',
					message : 'PLEASE ASSIGN FIELD TECH USER AS OWNER TO THIS THIS WORK ORDER TO ClOSE RETURN ORDER',
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
        $A.enqueueAction(checkWOOwnerId);
	},

	retreiveReturnOrder : function(component,event,helper,recordId) {
		console.log('--retreiveReturnOrder--');
		console.log('recordId-> ' + recordId);
		var getReturnOrder = component.get("c.getReturnOrder");
		getReturnOrder.setParams({
			'woId' : recordId
        });
        getReturnOrder.setCallback(this, function(response) {
            var result = response.getReturnValue();
			console.log('getReturnOrder state-> ' + response.getState());
            if (result.length > 0) {
            	console.log('SUCCESS');
				component.set("v.roRec",result[0]);
				component.set("v.roExists",true);
				console.log('roExists-> ' + component.get("v.roExists"));
				console.log('roRec-> ' + JSON.stringify(component.get("v.roRec")));
				helper.retreiveReturnOrderLineItems(component,event,helper);
				setTimeout(() => {
					component.set("v.loadSpinner",false);
				}, 1000)
            } else {
				console.log('Failed');
				component.set("v.roExists",false);
				var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
					title : 'Error',
					message : 'No Return Order Found / Is Already Shipped!',
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
        $A.enqueueAction(getReturnOrder);
	},

	retreiveReturnOrderLineItems : function(component,event,helper) {
		console.log('--retreiveReturnOrder--');
		var roRec = component.get("v.roRec");
		var getReturnOrderLineItems = component.get("c.getReturnOrderLineItems");
		getReturnOrderLineItems.setParams({
			'roRec' : roRec
        });
        getReturnOrderLineItems.setCallback(this, function(response) {
            var result = response.getReturnValue();
			console.log('getReturnOrderLineItems state-> ' + response.getState());
            if (result.length > 0) {
            	console.log('SUCCESS');
				component.set("v.roliList",result);
				component.set("v.roliExists",true);
				console.log('roliExists-> ' + component.get("v.roliExists"));
				console.log('roliList-> ' + JSON.stringify(component.get("v.roliList")));
            } else {
				console.log('Failed');
				component.set("v.roliExists",false);
				var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
					title : 'Error',
					message : 'No Returning Products Under Return Order!',
					duration : ' 2000',
					key : 'info_alt',
					type : 'error',
					mode : 'pester'
				});
				toastEvent.fire();
			}
    	});
        $A.enqueueAction(getReturnOrderLineItems);
	}
})