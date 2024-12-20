({
    myAction : function(component, event, helper) {        
        helper.getCaseRec(component,event, helper);
    },
    createNewOnsiteWorkOrder : function(component,event,helper){
        component.set("v.onsiteSC",true);
        helper.getServiceContract(component,event, helper);
	},
    createNewPartWorkOrder : function(component,event,helper){
        component.set("v.onsiteSC",false);
        helper.getServiceContract(component,event, helper);
	}
})