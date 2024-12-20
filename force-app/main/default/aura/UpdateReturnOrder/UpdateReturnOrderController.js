({
	myAction : function(component, event, helper) {
		var recordId = component.get("v.recordId");
		console.log('recordId-> ' + recordId);
		if(recordId.includes("0WO")){
			component.set("v.returnOrderEdit" , true);
			helper.helperMethod(component,event,helper,recordId);
			helper.retreiveReturnOrder(component,event,helper,recordId);
		}
	},

	refreshLists : function(component, event, helper) {
		var recordId = component.get("v.recordId");
		console.log('recordId-> ' + recordId);
		if(recordId.includes("0WO")){
			component.set("v.returnOrderEdit" , true);
			helper.helperMethod(component,event,helper,recordId);
			helper.retreiveReturnOrder(component,event,helper,recordId);
		}
	},

	handleSave : function(component, event,helper){
		component.set("v.loadSpinner",true);
		var roRec = component.get("v.roRec");
		var roliExists = component.get("v.roliExists");
		
		if(roliExists == true){
			var shipReturnOrder = component.get("c.shipReturnOrder");
			shipReturnOrder.setParams({
				'roRec' : roRec
			});
			shipReturnOrder.setCallback(this, function(response) {
				var result = response.getReturnValue();
				console.log('shipReturnOrder state-> ' + response.getState());
				if (result == true) {
					console.log('SUCCESS');
					var toastEvent = $A.get("e.force:showToast");
					toastEvent.setParams({
						title : 'success',
						message : 'Return Order is shipped!',
						duration : ' 2000',
						key : 'info_alt',
						type : 'success',
						mode : 'pester'
					});
					toastEvent.fire();
					var dismissActionPanel = $A.get("e.force:closeQuickAction");
					dismissActionPanel.fire();
				} else {
					console.log('Failed');
					var toastEvent = $A.get("e.force:showToast");
					toastEvent.setParams({
						title : 'Error',
						message : 'This Return Order Is Already Shipped!',
						duration : ' 2000',
						key : 'info_alt',
						type : 'error',
						mode : 'pester'
					});
					toastEvent.fire();
				}
				component.set("v.loadSpinner",false);
			});
			$A.enqueueAction(shipReturnOrder);
		} else if(!roliExists){
			var toastEvent = $A.get("e.force:showToast");
			toastEvent.setParams({
				title : 'Error',
				message : 'Products to be shipped are not found under this return order!',
				duration : ' 2000',
				key : 'info_alt',
				type : 'error',
				mode : 'pester'
			});
			toastEvent.fire();
			component.set("v.loadSpinner",false);
		}
	},

	handleCancel : function(component, event,helper){
		var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
	}
})