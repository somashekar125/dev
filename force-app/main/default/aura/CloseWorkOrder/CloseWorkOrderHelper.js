({
	getwoRec : function(component, event, helper) {
		component.set("v.loadSpinner",true);
		console.log('wo Id-> ' + component.get("v.recordId"));
		var getwoRec = component.get("c.getwoRec");
		getwoRec.setParams({
            'woId': component.get("v.recordId")
        });
        getwoRec.setCallback(this, function(response) {
            var State = response.getState();
            if (State == "SUCCESS") {
            	component.set("v.woRec",response.getReturnValue());
                console.log('woRec WO Closing--> ' + JSON.stringify(component.get("v.woRec")));
				var woRec = component.get("v.woRec");
				if(woRec.Record_Type_Name__c == 'Onsite Labor'){
					component.set("v.isOnsiteWO",true);
				} else {
					component.set("v.isOnsiteWO",false);
				}
				var caseId = component.get("v.woRec").CaseId;
				component.set("v.caseId" , caseId);
				helper.checkForProdTransfers(component,event,helper);
				helper.CheckIfLiftExists(component, event, helper);
				helper.getCaseRec(component, event, helper);
				setTimeout(() => {
					component.set("v.loadSpinner",false);
				}, 1500)
            }
    	});
        $A.enqueueAction(getwoRec);
	},

	getCaseRec : function(component, event, helper) {
		console.log('Case Id-> ' + component.get("v.caseId"));
		var getCaseRec = component.get("c.getCaseRec");
		getCaseRec.setParams({
            'caseId': component.get("v.caseId")
        });
        getCaseRec.setCallback(this, function(response) {
            var State = response.getState();
            if (State == "SUCCESS") {
            	component.set("v.caseRec",response.getReturnValue());
                console.log('caseRec case Closing--> ' + JSON.stringify(component.get("v.caseRec")));
            }
    	});
        $A.enqueueAction(getCaseRec);
	},

	checkForProdTransfers : function(component, event, helper) {
		console.log('checkForProdTransfers woId Id-> ' + component.get("v.recordId"));
		var checkForProductTransfers = component.get("c.checkForProductTransfers");
		checkForProductTransfers.setParams({
			'woId': component.get("v.recordId")
        });
        checkForProductTransfers.setCallback(this, function(response) {
            var State = response.getState();
            if (State == "SUCCESS") {
            	if(response.getReturnValue() == true){
					component.set("v.productTransferExists",true);
					var toastEvent = $A.get("e.force:showToast");
					toastEvent.setParams({
						title : 'Error',
						message : 'Unreceived product transfers found under this Work Order!',
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

	CheckIfLiftExists : function(component, event, helper) {
		var recordId = component.get("v.recordId");
		var checkForLiftWOLI = component.get("c.checkForLiftWOLI");
		checkForLiftWOLI.setParams({
			'woId' : recordId
        });
        checkForLiftWOLI.setCallback(this, function(response) {
            var  result = response.getReturnValue();
			console.log('checkForLiftWOLI state-> ' + response.getState());
            if (result == true) {
            	var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title : 'Warning',
                    message : 'Requested Lift(s) Found. You Can Return Lift(s) If Needed!',
                    duration : '5000',
                    key : 'info_alt',
                    type : 'warning',
                    mode : 'pester'
                });
                toastEvent.fire();
            }
    	});
        $A.enqueueAction(checkForLiftWOLI);
	},

	errorToast : function(component, message) {
		var toastEvent = $A.get("e.force:showToast");
		toastEvent.setParams({
			title : 'Error',
			message : message,
			duration : 1000,
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
			duration : 3000,
			key : 'info_alt',
			type : 'success',
			mode : 'pester'
		});
		toastEvent.fire();
	}
})