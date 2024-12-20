({
	getUserType : function(component, event, helper){
        var callMethod = component.get("c.checkUserType");
        callMethod.setCallback(this, function(response){
            console.log('helper response.getState()::'+response.getState());
            if(response.getState() == 'SUCCESS'){
                console.log('response.getReturnValue()::'+JSON.stringify(response.getReturnValue()));
                if(response.getReturnValue() == true){
                    component.set("v.communityUser",'Community User');
                } else {
                    component.set("v.communityUser",'Internal User');
                }
                console.log('User-> '+component.get("v.communityUser"));
            }
        });
        $A.enqueueAction(callMethod);
    }
})