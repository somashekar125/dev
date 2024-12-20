({
    getCaseRec : function(component,event, helper) {
        console.log('recordID In getCaseRec-> ' + component.get("v.recordId"));
		var action = component.get("c.getCaseRec");
        action.setParams({
            'caseId': component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state == "SUCCESS") {
            	component.set("v.caseRec",response.getReturnValue());
                console.log('caseRec In getCaseRec-->' + JSON.stringify(component.get("v.caseRec")));
                helper.getRecordType(component,event, helper);
            }
    	});
        $A.enqueueAction(action);
	},
    getRecordType : function(component,event, helper) {
		var action = component.get("c.getRecordType");
        var caseRec = component.get("v.caseRec");
        console.log('caseRec.ServiceContractId-> ' + caseRec.ServiceContractId);
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state == "SUCCESS") {
            	component.set("v.recordType",response.getReturnValue());
                console.log('RecordType--> ' + JSON.stringify(component.get("v.recordType")));
            }
    	});
        $A.enqueueAction(action);
	},
    getServiceContract : function(component,event, helper) {
        var onsiteSC = component.get("v.onsiteSC");
        console.log('onsiteSC-> ' + onsiteSC);
		var action = component.get("c.getServiceContract");
        var caseRec = component.get("v.caseRec");
        console.log('caseRec.ServiceContractId-> ' + caseRec.ServiceContractId);
        action.setParams({
            'ServiceContractId': caseRec.ServiceContractId,
            'onsiteSC' : onsiteSC
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state == "SUCCESS") {
            	component.set("v.serviceConract",response.getReturnValue());
                console.log('serviceConract--> ' + JSON.stringify(component.get("v.serviceConract")));
                if(onsiteSC == true){
                    var serviceConract = component.get("v.serviceConract");
                    console.log('serviceConract createNewOnsiteWorkOrder-->' + serviceConract.Name);
                    console.log('caseRec-->' + JSON.stringify(component.get("v.caseRec")));
                    var serviceType = '';
                    if(caseRec.Service_Type__c == 'Advance Exchange + Onsite'){
                        serviceType = 'Onsite Labor Only';
                    } else{
                        serviceType = caseRec.Service_Type__c;
                    }
                    var createRecordEvent = $A.get("e.force:createRecord");
                    createRecordEvent.setParams({
                        "entityApiName": "WorkOrder",
                        "defaultFieldValues": {
                            'CaseId' : caseRec.Id,
                            'OwnerId' : caseRec.OwnerId,
                            'Description' : caseRec.Description,
                            'Tech_Notes__c' : caseRec.Tech_Notes__c,
                            'POS_Register_Number__c' : caseRec.POS_Register_Number__c,
                            'Priority' : caseRec.Priority,
                            'Incident__c' : caseRec.Incident__c,
                            'Service_Type__c' : serviceType,
                            'ServiceContractId' : serviceConract.Id,
                            'Pricebook2Id' : caseRec.ServiceContract.Pricebook2Id,
                            'AccountId' : caseRec.AccountId,
                            'Root_Account__c' : caseRec.Root_Account__c,
                            'Product__c' : caseRec.ProductId,
                            'Equipment_Type__c' : caseRec.Equipment_Type__c,
                            'Problem_Type__c' : caseRec.Problem_Type__c,
                            'Department2__c' : caseRec.Department2__c
                        },
                        "panelOnDestroyCallback": function(event) {
                            console.log('recordID In panelOnDestroyCallback-> ' + component.get("v.recordId"));
                            var urlEvent = $A.get("e.force:navigateToURL");
                            urlEvent.setParams({
                                "url": "/lightning/r/Case/"+component.get("v.recordId")+"/view"
                            });
                        urlEvent.fire();
                        }
                    });
                    createRecordEvent.fire();
                } else{
                    var serviceConract = component.get("v.serviceConract");
                    console.log('serviceConract createNewPartWorkOrder-->' + serviceConract.Name);
                    console.log('caseRec.ProductId-->' + caseRec.ProductId);
                    var recordType = component.get("v.recordType");
                    console.log('recordType ID-->' + recordType.Id);
                    console.log('caseRec-->' + JSON.stringify(component.get("v.caseRec")));
                    var createRecordEvent = $A.get("e.force:createRecord");
                    createRecordEvent.setParams({
                        "entityApiName": "WorkOrder",
                        'recordTypeId' : recordType.Id,
                        "defaultFieldValues": {
                            'CaseId' : caseRec.Id,
                            'OwnerId' : caseRec.OwnerId,
                            'Description' : caseRec.Description,
                            'Tech_Notes__c' : caseRec.Tech_Notes__c,
                            'POS_Register_Number__c' : caseRec.POS_Register_Number__c,
                            'Priority' : caseRec.Priority,
                            'Incident__c' : caseRec.Incident__c,
                            'Service_Type__c' : 'Advance Exchange (Depot Only)',
                            'ServiceContractId' : serviceConract.Id,
                            'Pricebook2Id' : caseRec.ServiceContract.Pricebook2Id,
                            'AccountId' : caseRec.AccountId,
                            'Root_Account__c' : caseRec.Root_Account__c,
                            'Product__c' : caseRec.ProductId,
                            'Equipment_Type__c' : caseRec.Equipment_Type__c,
                            'Problem_Type__c' : caseRec.Problem_Type__c,
                            'Department2__c' : caseRec.Department2__c
                        },
                        "panelOnDestroyCallback": function(event) {
                            console.log('recordID In panelOnDestroyCallback-> ' + component.get("v.recordId"));
                            var urlEvent = $A.get("e.force:navigateToURL");
                            urlEvent.setParams({
                                "url": "/lightning/r/Case/"+component.get("v.recordId")+"/view"
                            });
                        urlEvent.fire();
                        }
                    });
                    createRecordEvent.fire();
                }
            }
    	});
        $A.enqueueAction(action);
	}
})