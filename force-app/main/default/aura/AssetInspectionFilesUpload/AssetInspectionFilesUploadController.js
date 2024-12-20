({
	myAction : function(component, event, helper) {
		var inspectType = '';
        var inspectTypeFromComp = component.get("v.inspectType");
        if(inspectTypeFromComp == 'Before Inspect'){
            inspectType = 'Before';
        }else if(inspectTypeFromComp == 'After Inspect'){
            inspectType = 'After';
        }
		component.set("v.inspectTypeToUpdate", inspectType)
		helper.helperMethod(component, event, helper);
	},
    
    handleUploadFinished : function(component, event, helper) {
		var uploadedFiles = event.getParam("files");
		console.log('files length::'+uploadedFiles.length);
		var documentIds = [];
		for(var i = 0; i < uploadedFiles.length; i++){
			console.log('uploaded file ids--->'+uploadedFiles[i].documentId);
			documentIds.push(uploadedFiles[i].documentId);
		}
		helper.renameFileName(component, event, helper, documentIds);
	}
})