({
	correctingDateTimes : function(component, event,helper){
		var caseRec = component.get("v.caseRec");
		console.log('caseRec DateTimes Retrieve-> ' + JSON.stringify(caseRec));
		var correctingDateTimes = component.get("c.correctingDateTimes");
		correctingDateTimes.setParams({
			caseRec : caseRec,
			saveDate : false
		});
		correctingDateTimes.setCallback(this, function(response){
			if(response.getState() == 'SUCCESS'){
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
		$A.enqueueAction(correctingDateTimes);
	}
})