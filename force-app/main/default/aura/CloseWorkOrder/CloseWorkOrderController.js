({
	myAction : function(component, event, helper) {
		var recordId = component.get("v.recordId");
		component.set("v.allowSave" , true);
		if(recordId.includes("0WO")){
			helper.getwoRec(component, event, helper);
		}
	},

	handleSave: function (component, event, helper) {
        var outOfScopeValue = component.find("outOfScopeField").get("v.value");
        var reasonValue = component.find("reasonField").get("v.value");
		var resCodeField = component.find('resCode').get('v.value');
		var statusField = component.find('woStatus').get('v.value');

        if (outOfScopeValue && (!reasonValue || reasonValue.trim() === "")) {
			component.set("v.isOutOfScope", true);
			event.preventDefault();
			helper.errorToast(component, 'Please enter a reason for Out of Scope!');
        } else {
			component.set("v.isOutOfScope", false);
			if (!resCodeField && statusField == 'Closed') {
				component.set("v.isClosing", true);
				helper.errorToast(component, 'Please enter resolution code!');
				return;
			} else {
				component.set("v.isClosing", false);
				helper.saveToast(component, 'Saved Successfully!');
				$A.get('e.force:refreshView').fire();
				var dismissActionPanel = $A.get("e.force:closeQuickAction");
				dismissActionPanel.fire();
			}
        }
	},

	handleCancel : function(component, event, helper) {
		var dismissActionPanel = $A.get("e.force:closeQuickAction");
		dismissActionPanel.fire();
	}
})