({
	myAction : function(component, event, helper) {
		var recordId = component.get("v.recordId");
		component.set("v.allowSave" , true);
		if(recordId.includes("0WO")){
			component.set("v.isWorkOrder" , true);
		}
		if(recordId.includes("500")){
			component.set("v.isCase" , true);
			component.set("v.caseId" , recordId);
			console.log('Case Id-> ' + component.get("v.caseId"));
		}
	},

	handleWOEdit : function(component, event, helper) {
		component.set("v.woEdit" , true);
		helper.getwoRec(component, event, helper);
	},

	handleCaseEdit : function(component, event, helper) {
		component.set("v.caseEdit" , true);
		helper.getCaseRec(component, event, helper);
	},

	handleSave: function (component, event, helper) {
		var recordId = component.get("v.recordId");
		var outOfScopeValue = component.find("outOfScopeField").get("v.value");
		var reasonValue = component.find("reasonField").get("v.value");
		var resCodeField = component.find('resCode').get('v.value');
		var statusField = component.find('woStatus').get('v.value');
	
		if (outOfScopeValue && (!reasonValue || reasonValue.trim() === "")) {
			component.set("v.isOutOfScope", true);
			helper.errorToast(component, 'Please enter a reason for Out of Scope!');
			return;
		} else {
			component.set("v.isOutOfScope", false);
		}
	
		if (!resCodeField && statusField === 'Closed') {
			component.set("v.isClosing", true);
			helper.errorToast(component, 'Please enter resolution code!');
			return;
		} else {
			component.set("v.isClosing", false);
		}
	
		helper.saveToast(component, 'Saved Successfully!');
		console.log('Form saved successfully');
	
		if (recordId.includes("0WO")) {
			helper.CheckIfLiftExists(component, event, helper, recordId);
		} else {
			var navEvt = $A.get("e.force:navigateToSObject");
			if (navEvt) {
				console.log('Navigating to SObject');
				navEvt.setParams({
					"recordId": recordId,
					"slideDevName": "related"
				});
				navEvt.fire();
			} else {
				console.log('Opening in new window');
				window.open("/" + recordId, "_parent");
			}
		}
	},		

	handleCancel : function(component, event, helper) {
		component.set("v.caseEdit" , false);
		component.set("v.woEdit" , false);
	}
})