({
	getCaseRec : function(component, event, helper) {
		component.set("v.loadSpinner",true);
		console.log('Case Id-> ' + component.get("v.recordId"));
		var getCaseRec = component.get("c.getCaseRec");
		getCaseRec.setParams({
            'caseId': component.get("v.recordId")
        });
        getCaseRec.setCallback(this, function(response) {
            var State = response.getState();
            if (State == "SUCCESS") {
            	component.set("v.caseRec",response.getReturnValue());
                console.log('caseRec case Closing--> ' + JSON.stringify(component.get("v.caseRec")));
				helper.checkForProdTransfers(component,event,helper);
				setTimeout(() =>{
					component.set("v.loadSpinner",false);
				}, 1000)
            }
    	});
        $A.enqueueAction(getCaseRec);
	},

	checkForProdTransfers : function(component, event, helper) {
		console.log('checkForProdTransfers Case Id-> ' + component.get("v.recordId"));
		var checkForProductTransfers = component.get("c.checkForProductTransfers2");
		checkForProductTransfers.setParams({
            'caseId': component.get("v.recordId")
        });
        checkForProductTransfers.setCallback(this, function(response) {
            var State = response.getState();
            if (State == "SUCCESS") {
            	if(response.getReturnValue() == true){
					component.set("v.productTransferExists",true);
					var toastEvent = $A.get("e.force:showToast");
					toastEvent.setParams({
						title : 'Error',
						message : 'Unreceived product transfers found under this Case!',
						duration : ' 5000',
						key : 'info_alt',
						type : 'error',
						mode : 'pester'
					});
					toastEvent.fire();
					var dismissActionPanel = $A.get("e.force:closeQuickAction");
					dismissActionPanel.fire();
				}
            }
    	});
        $A.enqueueAction(checkForProductTransfers);
	},

	errorToast : function(component, message) {
		var toastEvent = $A.get("e.force:showToast");
		toastEvent.setParams({
			title : 'Error',
			message : message,
			duration : '3000',
			key : 'info_alt',
			type : 'error',
			mode : 'pester'
		});
		toastEvent.fire();
	},

	saveToast : function(component, message) {
		var toastEvent = $A.get("e.force:showToast");
		toastEvent.setParams({
			title : 'success',
			message : message,
			duration : '3000',
			key : 'info_alt',
			type : 'success',
			mode : 'pester'
		});
		toastEvent.fire();
	}
})