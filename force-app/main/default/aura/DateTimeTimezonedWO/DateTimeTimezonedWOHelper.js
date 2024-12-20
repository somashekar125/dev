({
	correctingDateTimes : function(component, event,helper){
		var woRec = component.get("v.woRec");
		console.log('woRec DateTimes Retrieve-> ' + JSON.stringify(woRec));
		var correctingDateTimes = component.get("c.correctingDateTimes");
		correctingDateTimes.setParams({
			woRec : woRec,
			saveDate : false
		});
		correctingDateTimes.setCallback(this, function(response){
			if(response.getState() == 'SUCCESS'){
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
                console.log('Error: '+JSON.stringify(response));
            }
		});
		$A.enqueueAction(correctingDateTimes);
	},
    
    getTimeEntries : function(component, event,helper){
		var woRec = component.get("v.woRec");
		var timeEntries = component.get("c.getTimeEntries");
		timeEntries.setParams({
			woRec : woRec
		});
		timeEntries.setCallback(this, function(response){
			if(response.getState() == 'SUCCESS'){
				component.set("v.timeEntriesList", response.getReturnValue());
				console.log('timeEntriesList-> ' + component.get("v.timeEntriesList"));
			} else {
                console.log('Error: '+JSON.stringify(response));
            }
		});
		$A.enqueueAction(timeEntries);
	}
})