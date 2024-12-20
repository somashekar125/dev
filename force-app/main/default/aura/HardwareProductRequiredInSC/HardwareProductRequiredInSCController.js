({
	doInit : function(component, event, helper) {
		var error = "Please complete the required information.";
        component.set('v.validate',function(){
            if(component.get("v.required") && !component.get("v.value")){
                return{
                    isValid: false,
                    errorMessage : error
                }
            }
        });
	}
})