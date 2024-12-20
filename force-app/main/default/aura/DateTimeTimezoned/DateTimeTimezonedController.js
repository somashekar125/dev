({
	myAction : function(component, event, helper) {
		var recordId = component.get("v.recordId");
		console.log('CaseId-> ' + recordId);
		var caseRec = component.get("c.getCaseRec");
        caseRec.setParams({
			caseId : recordId
		});
        caseRec.setCallback(this, function(response){
            if(response.getState() == 'SUCCESS'){
                console.log('caseRec: '+JSON.stringify(response.getReturnValue()));
                component.set("v.caseRec", response.getReturnValue());
				component.set("v.oldSLAdatetime",component.get("v.caseRec").Expected_SLA_Exit_Date__c);
				component.set("v.oldPartDate",component.get("v.caseRec").Part_Receipt_Due_DateTime__c);
				component.set("v.oldPrefDate",component.get("v.caseRec").Preferred_Time__c);
				component.set("v.oldTechOnsiteETA",component.get("v.caseRec").Technician_OnSite_ETA__c);
				helper.correctingDateTimes(component, event, helper);
            } else {
                console.log('Error: '+JSON.stringify(response));
            }
        });
        $A.enqueueAction(caseRec);
	},

	handleEdit : function(component, event, helper) {
		component.set("v.edit",true);
	},

	handleCancel : function(component, event, helper) {
		component.set("v.edit",false);
		var caseRec = component.get("v.caseRec");
		var sladatetime = component.get("v.oldSLAdatetime");
		caseRec.Expected_SLA_Exit_Date__c = sladatetime;
		var oldPartDate = component.get("v.oldPartDate");
		caseRec.Part_Receipt_Due_DateTime__c = oldPartDate;
		var oldPrefDate = component.get("v.oldPrefDate");
		caseRec.Preferred_Time__c = oldPrefDate;
		var oldTechOnsiteETA = component.get("v.oldTechOnsiteETA");
		caseRec.Technician_OnSite_ETA__c = oldTechOnsiteETA;
		component.set("v.caseRec",caseRec);
	},

	handleSave : function(component, event, helper) {
		var caseRec = component.get("v.caseRec");
		caseRec.Expected_SLA_Exit_Date__c = component.get("v.sladatetime");
		caseRec.Preferred_Time__c = component.get("v.prefDate");
		caseRec.Part_Receipt_Due_DateTime__c = component.get("v.partDate");
		caseRec.Technician_OnSite_ETA__c = component.get("v.techOnsiteETA");
		component.set("v.caseRec",caseRec);
		console.log('caseRec handleSLASave-> ' + JSON.stringify(component.get("v.caseRec")));
		var saveCaseRec = component.get("c.correctingDateTimes");
		saveCaseRec.setParams({
			caseRec : component.get("v.caseRec"),
			saveDate : true
		});
		saveCaseRec.setCallback(this, function(response){
			if(response.getState() == 'SUCCESS'){
				console.log('caseRec: '+JSON.stringify(response.getReturnValue()));
				var result = response.getReturnValue();
				component.set("v.sladatetimeStr", result.SLAdateStr);
				component.set("v.sladatetime",result.SLADateTimeValue);
				component.set("v.prefTimeStr", result.PrefdateStr);
				component.set("v.prefDate",result.PrefDateTimeValue);
				component.set("v.partshipTimeStr", result.PartdateStr);
				component.set("v.partDate",result.PartDateTimeValue);
				component.set("v.techOnsiteETAStr", result.TechdateStr);
				component.set("v.techOnsiteETA",result.TechDateTimeValue);
				component.set("v.saveDate",result.saveDate);
			} else {
                console.log('Error: '+JSON.stringify(response));
            }
		});
		$A.enqueueAction(saveCaseRec);
		component.set("v.edit",false);
	}
})