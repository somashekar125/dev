({
	myAction : function(component, event, helper) {
		var recordId = component.get("v.recordId");
		if(recordId.includes("0WO")){
            helper.getwoRec(component, event, helper);
			helper.CheckIfLiftExists(component, event, helper);
		}
	},
    
    handleSave: function (component, event, helper) {
        var woRec = component.get("v.woRec");
        if(woRec.Onsite_Manager_Name__c == '' || woRec.Resolution_Code__c == '' || woRec.Resolution_Notes__c == ''){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title : 'Error',
                message : 'Required fields must be completed!',
                duration : ' 3000',
                key : 'info_alt',
                type : 'error',
                mode : 'pester'
            });
            toastEvent.fire();
        } else {
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