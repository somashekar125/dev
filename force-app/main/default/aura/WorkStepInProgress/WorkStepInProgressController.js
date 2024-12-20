({
	myAction : function(component, event, helper) {
		var recordId = component.get("v.recordId");
        console.log('WS In progress recordId-> ' + recordId);
        if(recordId.includes("0hF")){
            helper.markInProgress(component, event, helper);
        }
	}
})