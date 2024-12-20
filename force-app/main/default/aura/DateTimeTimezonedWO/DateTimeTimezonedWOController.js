({
	myAction : function(component, event, helper) {
		var recordId = component.get("v.recordId");
		console.log('woId-> ' + recordId);
		var woRec = component.get("c.getWORec");
        woRec.setParams({
			woId : recordId
		});
        woRec.setCallback(this, function(response){
            if(response.getState() == 'SUCCESS'){
                console.log('woRec: '+JSON.stringify(response.getReturnValue()));
                component.set("v.woRec", response.getReturnValue());
				component.set("v.oldSLAdatetime",component.get("v.woRec").SLA_Due_DateTime__c);
				component.set("v.oldPrefDate",component.get("v.woRec").Preferred_Time_IMAC__c);
				component.set("v.oldCheckInTime",component.get("v.woRec").Check_In_Time__c);
				component.set("v.oldCheckOutTime",component.get("v.woRec").Check_Out_Time__c);
				component.set("v.oldTechOnsiteETA",component.get("v.woRec").Technician_OnSite_ETA__c);
				helper.correctingDateTimes(component, event, helper);
                helper.getTimeEntries(component, event, helper);
            } else {
                console.log('Error: '+JSON.stringify(response));
            }
        });
        $A.enqueueAction(woRec);
	},

	handleEdit : function(component, event, helper) {
		component.set("v.edit",true);
	},

	handleCancel : function(component, event, helper) {
		component.set("v.edit",false);
		var woRec = component.get("v.woRec");
		var oldSLAdatetime = component.get("v.oldSLAdatetime");
		woRec.SLA_Due_DateTime__c = oldSLAdatetime;
		var oldPrefDate = component.get("v.oldPrefDate");
		woRec.Preferred_Time_IMAC__c = oldPrefDate;
		var oldTechOnsiteETA = component.get("v.oldTechOnsiteETA");
		woRec.Technician_OnSite_ETA__c = oldTechOnsiteETA;
		var oldCheckInTime = component.get("v.oldCheckInTime");
		woRec.Check_In_Time__c = oldCheckInTime;
		var oldCheckOutTime = component.get("v.oldCheckOutTime");
		woRec.Check_Out_Time__c = oldCheckOutTime;
		component.set("v.woRec",woRec);
	},

	handleSave : function(component, event, helper) {
		var woRec = component.get("v.woRec");
		woRec.SLA_Due_DateTime__c = component.get("v.sladatetime");
		woRec.Preferred_Time_IMAC__c = component.get("v.prefDate");
		woRec.Technician_OnSite_ETA__c = component.get("v.techOnsiteETA");
		woRec.Check_In_Time__c = component.get("v.checkInTime");
		woRec.Check_Out_Time__c = component.get("v.checkOutTime");
		component.set("v.woRec",woRec);
		console.log('woRec saving-> ' + JSON.stringify(component.get("v.woRec")));
		var updateSLA = component.get("c.correctingDateTimes");
		updateSLA.setParams({
			woRec : component.get("v.woRec"),
			saveDate : true
		});
		updateSLA.setCallback(this, function(response){
			if(response.getState() == 'SUCCESS'){
				console.log('response-> '+JSON.stringify(response.getReturnValue()));
				var result = response.getReturnValue();
				component.set("v.sladatetimeStr", result.SLAdateStr);
				component.set("v.sladatetime",result.SLADateTimeValue);
				component.set("v.prefTimeStr", result.PrefdateStr);
				component.set("v.prefDate",result.PrefDateTimeValue);
				component.set("v.techOnsiteETAStr", result.TechdateStr);
				component.set("v.techOnsiteETA",result.TechDateTimeValue);
				component.set("v.checkInTimeStr", result.CheckIndateStr);
				component.set("v.checkInTime",result.CheckInDateTimeValue);
				component.set("v.checkOutTimeStr", result.CheckOutdateStr);
				component.set("v.checkOutTime",result.CheckOutDateTimeValue);
				component.set("v.saveDate",result.saveDate);
			} else {
                console.log('Error:'+JSON.stringify(response));
            }
		});
		$A.enqueueAction(updateSLA);
		component.set("v.edit",false);
	}
})