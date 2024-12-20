({
    searchHelper : function(component,event,getInputkeyWord) {
        // call the apex class method 
        console.log('SearchLimit-> ' + component.get("v.SearchLimit"));
        console.log('rootAccountId-> ' + component.get("v.rootAccountId"));
        console.log('hwRootAccountId-> ' + component.get("v.hwRootAccountId"));
        var action = component.get("c.fetchLookUpValues");
        // set param to method
        action.setParams({
            'searchKeyWord': getInputkeyWord,
            'objectAPIName' : component.get("v.objectAPIName"),
            'rootAccountId' : component.get("v.rootAccountId"),
            'hwRootAccountId' : component.get("v.hwRootAccountId"),
            'recordLimit' : component.get("v.SearchLimit")
        });
        // set a callBack    
        action.setCallback(this, function(response) {
            $A.util.removeClass(component.find("mySpinner"), "slds-show");
            var state = response.getState();
            if (state === "SUCCESS") {
                var storeResponse = response.getReturnValue();
                // if storeResponse size is equal 0 ,display No Result Found... message on screen.                }
                if (storeResponse.length == 0) {
                    component.set("v.Message", 'No Result Found...');
                } else {
                    component.set("v.Message", '');
                }
                // set searchResult list with return value from server.
                component.set("v.listOfSearchRecords", storeResponse);
            }
            
        });
        // enqueue the Action  
        $A.enqueueAction(action);
    }
})