({
    onfocus : function(component,event,helper){
        $A.util.addClass(component.find("mySpinner"), "slds-show");
        var forOpen = component.find("searchRes");
        $A.util.addClass(forOpen, 'slds-is-open');
        $A.util.removeClass(forOpen, 'slds-is-close');
        // Get Default 5 Records order by createdDate DESC  
        var getInputkeyWord = '';
        helper.searchHelper(component,event,getInputkeyWord);
    },
    
    keyPressController : function(component, event, helper) {
        // get the search Input keyword   
        var getInputkeyWord = component.get("v.SearchKeyWord");
        // check if getInputKeyWord size id more then 0 then open the lookup result List and 
        // call the helper 
        // else close the lookup result List part.   
        if( getInputkeyWord.length > 0 ){
            var forOpen = component.find("searchRes");
            $A.util.addClass(forOpen, 'slds-is-open');
            $A.util.removeClass(forOpen, 'slds-is-close');
            helper.searchHelper(component,event,getInputkeyWord);
        }
        else{  
            component.set("v.listOfSearchRecords", null ); 
            var forclose = component.find("searchRes");
            $A.util.addClass(forclose, 'slds-is-close');
            $A.util.removeClass(forclose, 'slds-is-open');
        }
    },

    selectRecord : function(component, event, helper){
        var listOfSearchRecords = component.get("v.listOfSearchRecords");
        console.log('listOfSearchRecords[event.currentTarget.name]-> ' + JSON.stringify(listOfSearchRecords[event.currentTarget.name]));
        var getSelectRecord = listOfSearchRecords[event.currentTarget.name];
        component.set("v.selectedRecord" , getSelectRecord);
        console.log('getSelectRecord.Name-> ' + getSelectRecord.Name);
        if(component.get("v.objectAPIName") == 'product2Hardware') {
            component.set("v.selectedProdId", getSelectRecord.Id);
        }

        var forclose = component.find("lookup-pill-container");
        $A.util.addClass(forclose, 'slds-show');
        $A.util.removeClass(forclose, 'slds-hide');
        
        var forclose = component.find("searchRes");
        $A.util.addClass(forclose, 'slds-is-close');
        $A.util.removeClass(forclose, 'slds-is-open');
        
        var lookUpTarget = component.find("lookupField");
        $A.util.addClass(lookUpTarget, 'slds-hide');
        $A.util.removeClass(lookUpTarget, 'slds-show');
    },
    
    handleValueChange :function(component,event,heplper){
        if(component.get("v.selectedRecord") == null){
            var pillTarget = component.find("lookup-pill-container");
            var lookUpTarget = component.find("lookupField"); 
            
            $A.util.addClass(pillTarget, 'slds-hide');
            $A.util.removeClass(pillTarget, 'slds-show');
            
            $A.util.addClass(lookUpTarget, 'slds-show');
            $A.util.removeClass(lookUpTarget, 'slds-hide');
            
            component.set("v.SearchKeyWord",null);
            component.set("v.listOfSearchRecords", null );
            component.set("v.selectedRecord", {} );   
        }
    },

     // function for clear the Record Selaction 
     clear :function(component,event,heplper){
        var pillTarget = component.find("lookup-pill-container");
        var lookUpTarget = component.find("lookupField"); 
        
        $A.util.addClass(pillTarget, 'slds-hide');
        $A.util.removeClass(pillTarget, 'slds-show');
        
        $A.util.addClass(lookUpTarget, 'slds-show');
        $A.util.removeClass(lookUpTarget, 'slds-hide');
        
        component.set("v.SearchKeyWord",null);
        component.set("v.listOfSearchRecords", null );
        component.set("v.selectedRecord", {} );   
    },

    // This function call when the end User Select any record from the result list.   
    /*handleComponentEvent : function(component, event, helper) {
        // get the selected Account record from the COMPONETN event 	 
        var selectedAccountGetFromEvent = event.getParam("recordByEvent");
        component.set("v.selectedRecord" , selectedAccountGetFromEvent);
        console.log('selectedAccountGetFromEvent->' + JSON.stringify(selectedAccountGetFromEvent));
        
        //var selectedAccountGetFromEvent = event.getParam("prodRecordByEvent");
        //component.set("v.selectedRecord" , selectedAccountGetFromEvent);
        
        var forclose = component.find("lookup-pill-container");
        $A.util.addClass(forclose, 'slds-show');
        $A.util.removeClass(forclose, 'slds-hide');
        
        var forclose = component.find("searchRes");
        $A.util.addClass(forclose, 'slds-is-close');
        $A.util.removeClass(forclose, 'slds-is-open');
        
        var lookUpTarget = component.find("lookupField");
        $A.util.addClass(lookUpTarget, 'slds-hide');
        $A.util.removeClass(lookUpTarget, 'slds-show');  
    },*/

    updateLimit : function(component, event, helper) {
        var limit = component.get("v.SearchLimit");
        component.set("v.SearchLimit",limit + 5);
        var getInputkeyWord = component.get("v.SearchKeyWord");
        if( getInputkeyWord.length > 0 ){
            helper.searchHelper(component,event,getInputkeyWord);
        }
    }
})