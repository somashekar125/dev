({
    checkInvalidWOs : function(component, event, helper) {
        console.log('--checkInvalidWOs--');
        component.set("v.loadSpinner",true);
        var recordId = component.get("v.recordId");
		var getInvalidWOs = component.get("c.getInvalidWOs");
		getInvalidWOs.setParams({
            'workOrderId': recordId
        });
        getInvalidWOs.setCallback(this, function(response) {
            var result = response.getReturnValue();
            console.log('Invalid WOs-> ' + JSON.stringify(result));
            var currWOErroMsg = '';
            for(var key in result){
                if(key == recordId){
                    console.log('Cannot delete Current WOId-> ' + key);
                    console.log('error msg-> ' + result[key]);
                    component.set("v.invalidWO",true);
                    currWOErroMsg = result[key];
                    break;
                } else {
                    console.log('Cannot delete Related WOs-> ' + result[key]);
                    component.set("v.invalidRelWOs",true);
                    break;
                }
            }
            var invalidWO = component.get("v.invalidWO");
            var invalidRelWOs = component.get("v.invalidRelWOs");
            if(invalidWO){
                var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
					title : 'Error',
					message : currWOErroMsg,
					duration : ' 2000',
					key : 'info_alt',
					type : 'error',
					mode : 'pester'
				});
				toastEvent.fire();
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
        		dismissActionPanel.fire();
            }
            /*if(!invalidWO && invalidRelWOs){
                var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
					title : 'Error',
					message : relWOErrorMsg,
					duration : ' 2000',
					key : 'info_alt',
					type : 'error',
					mode : 'pester'
				});
				toastEvent.fire();
            }*/
            component.set("v.loadSpinner",false);
    	});
        $A.enqueueAction(getInvalidWOs);
    },
    
	getRelatedWOs : function(component, event, helper) {
        component.set("v.loadSpinner",true);
        var recordId = component.get("v.recordId");
		var retreiveRelatedWOs = component.get("c.retreiveRelatedWOs");
		retreiveRelatedWOs.setParams({
            'workOrderId': recordId
        });
        retreiveRelatedWOs.setCallback(this, function(response) {
            var result = response.getReturnValue();
            if (result.length > 0) {
            	component.set("v.woList",response.getReturnValue());
                var woList = component.get("v.woList");
                for(var w=0; w< woList.length; w++){
                    if(woList[w].Id == recordId){
                        component.set("v.workOrderNumber",woList[w].WorkOrderNumber);
                    	console.log('WorkOrderNumber-> ' + component.get("v.workOrderNumber"));
                        break;
                    }
                }
                console.log('woList-> ' + JSON.stringify(component.get("v.woList")));
                component.set("v.loadSpinner",false);
            }
    	});
        $A.enqueueAction(retreiveRelatedWOs);
    },
})