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
                var woRec = component.get("v.woRec");
                woRec.Technician_Status__c = 'Checked Out';
                component.set("v.woRec",woRec);
                console.log('woRec WO Closing--> ' + JSON.stringify(component.get("v.woRec")));
				setTimeout(() => {
					component.set("v.loadSpinner",false);
				}, 1300)
            }
    	});
        $A.enqueueAction(getwoRec);
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
	}
})