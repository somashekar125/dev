({
	helperMethod : function(component, event, helper) {
		var recordId = component.get("v.recordId");
        console.log('recordId::'+recordId);

        var getWOLIAction = component.get("c.getWOLI");
        getWOLIAction.setParams({
            woliId : recordId
        });
        getWOLIAction.setCallback(this, function(response){
            console.log('response--->'+response.getState());
            if(response.getState() == 'SUCCESS'){
                console.log('documents::'+JSON.stringify(response.getReturnValue()));
                var woli = response.getReturnValue();
                if(woli.Status == 'Inspected'){
                    var inspectType = component.get("v.inspectTypeToUpdate");
                    console.log('inspectType query::'+inspectType);
                    var callAction = component.get("c.getFiles");
                    callAction.setParams({
                        recId : recordId,
                        inspectType : inspectType
                    });
                    callAction.setCallback(this, function(response){
                        console.log('response--->'+response.getState());
                        if(response.getState() == 'SUCCESS'){
                            console.log('documents::'+JSON.stringify(response.getReturnValue()));
                            component.set("v.documentList", response.getReturnValue());
                        }
                    });
                    $A.enqueueAction(callAction);
                }
            }
        });
        $A.enqueueAction(getWOLIAction);
        /*var inspectType = component.get("v.inspectTypeToUpdate");
        console.log('inspectType query::'+inspectType);
        var callAction = component.get("c.getFiles");
        callAction.setParams({
            recId : recordId,
            inspectType : inspectType
        });
        callAction.setCallback(this, function(response){
            console.log('response--->'+response.getState());
            if(response.getState() == 'SUCCESS'){
                console.log('documents::'+JSON.stringify(response.getReturnValue()));
                component.set("v.documentList", response.getReturnValue());
            }
        });
        $A.enqueueAction(callAction);*/
        
	},
    getDocuments : function(component, event, helper) {
        var recordId = component.get("v.recordId");
        console.log('recordId::'+recordId);
        var inspectType = component.get("v.inspectTypeToUpdate");
        console.log('inspectType query::'+inspectType);
        var callAction = component.get("c.getFiles");
        callAction.setParams({
            recId : recordId,
            inspectType : inspectType
        });
        callAction.setCallback(this, function(response){
            console.log('response--->'+response.getState());
            if(response.getState() == 'SUCCESS'){
                console.log('documents::'+JSON.stringify(response.getReturnValue()));
                component.set("v.documentList", response.getReturnValue());
            }
        });
        $A.enqueueAction(callAction);
    },

    renameFileName : function(component, event, helper, docIds) {
        var callAction = component.get("c.updateFileNames");
        var inspectType = component.get("v.inspectTypeToUpdate");
        callAction.setParams({
            documentIds : docIds,
            inspectionType : inspectType
        });
        callAction.setCallback(this, function(response){
            console.log('response--->'+response.getState());
            if(response.getState() == 'SUCCESS'){
                helper.getDocuments(component, event, helper);
            }
        });
        $A.enqueueAction(callAction);
	}
})