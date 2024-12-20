({
	myAction : function(component, event, helper) {
		var recordId = component.get("v.recordId");
		component.set("v.allowSave" , true);
		if(recordId.includes("500")){
			helper.getCaseRec(component, event, helper);
		}
	},

	handleSave: function (component, event, helper) {
        var resCodeField = component.find('resCode').get('v.value');
		var statusField = component.find('caseStatus').get('v.value');
		if (!resCodeField && statusField == 'Closed') {
			component.set("v.isClosing" , true);
			helper.errorToast(component, 'Please enter resolution code!');
			return;
		} else {
			component.set("v.isClosing" , true);
			helper.saveToast(component, 'Saved Successfully!');
			$A.get('e.force:refreshView').fire();
			var dismissActionPanel = $A.get("e.force:closeQuickAction");
			dismissActionPanel.fire();
		}
	},

	handleCancel : function(component, event, helper) {
		var dismissActionPanel = $A.get("e.force:closeQuickAction");
		dismissActionPanel.fire();
	}
})