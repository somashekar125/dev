({
	myAction : function(component, event, helper) {
        component.set('v.columns', [
            {label: 'Work Order', fieldName: 'woRecLink', type: 'url', typeAttributes :{
                label : {fieldName : 'WorkOrderNumber'},
                target : '_blank'
            }},
            {label: 'Account', fieldName: 'AccountName', type: 'text'},
            {label: 'Product', fieldName: 'ProductName', type: 'text'},
            {label: 'Service Type', fieldName: 'Service_Type__c', type: 'text'},
            {label: 'Created Date', fieldName: 'CreatedDate', type: 'date'},
            {label: 'Priority', fieldName: 'Priority', type: 'text'},
            {label: 'Action', type: "button", initialWidth: 100, typeAttributes: {
                label: 'Add',
                name: 'AddtoBundle',
                title: 'Add to Bundle',
                variant: 'brand'
            }}
        ]);
        component.set('v.columns2', [
            {label: 'Work Order', fieldName: 'woRecLink',  type: 'url', typeAttributes :{
                label : {fieldName : 'WorkOrderNumber'},
                target : '_blank'
            }},
            {label: 'Account', fieldName: 'AccountName', type: 'text'},
            {label: 'Product', fieldName: 'ProductName', type: 'text'},
            {label: 'Service Type', fieldName: 'Service_Type__c', type: 'text'},
            {label: 'Created Date', fieldName: 'CreatedDate', type: 'date'},
            {label: 'Priority', fieldName: 'Priority', type: 'text'},
            {label: 'Action', type: "button", initialWidth: 100, typeAttributes: {
                label: 'Remove',
                name: 'rmvFrmBundle',
                title: 'Remove From Bundle',
                variant: 'destructive-text'
            }}
        ]);
		helper.getWorkOrder(component, event, helper);
        //helper.getBndlWos(component, event, helper);
        //helper.getTotalWos(component, event, helper);
	},
    
    handleRowAction : function(component, event, helper){
        console.log('calling function....');
        component.set("v.loadSpinner", true);
        var action = event.getParam('action');
        var row = event.getParam('row');
        var bktWorkord = component.get("v.bundleWO");
        console.log('action--->'+action);
        switch (action.name) {
            case 'AddtoBundle':
                var rowId = row.Id;
                console.log('row id--->'+rowId);
                var wos = component.get("v.totalWOs");
                var addWo = [];
                for(var i = 0; i < wos.length; i++){
                    if(wos[i].Id == rowId){
                        wos[i].Bundle_Id__c = bktWorkord.Bundle_Id__c;
                        wos[i].Bundle_Work_Order__c = bktWorkord.Id;
                        addWo.push(wos[i]);
                    }
                }
                console.log('add wos--->'+addWo.length);
                if(addWo.length != 0){
                    helper.bndlAddRemove(component, event, helper, addWo);
                }else{
                    component.set("v.loadSpinner", false);
                }
                break;
            case 'rmvFrmBundle':
                var rowId = row.Id;
                console.log('row id rmv--->'+rowId);
                var bndlwos = component.get("v.bndlWOs");
                var rmvWo = [];
                for(var i = 0; i < bndlwos.length; i++){
                    if(bndlwos[i].Id == rowId){
                        bndlwos[i].Bundle_Id__c = '';
                        bndlwos[i].Bundle_Work_Order__c = null;
                        rmvWo.push(bndlwos[i]);
                    }
                }
                console.log('add wos--->'+rmvWo.length);
                if(rmvWo.length != 0){
                    helper.bndlAddRemove(component, event, helper, rmvWo);
                }else{
                    component.set("v.loadSpinner", false);
                }
                break;
        }
    },
    
    openRecord : function(component, event, helper){
        var opnId = event.target.id;
        console.log('record to open--->'+opnId);
        window.open('/'+opnId, '_blank');
    },
    
    handleSelect : function(component, event, helper) {
        /*
        var selectedRows = event.getParam('selectedRows'); 
        var setRows = component.get("v.woToSave");
        for ( var i = 0; i < selectedRows.length; i++ ) {
            setRows.push(selectedRows[i]);
        }
        console.log('save rows--->'+JSON.stringify(setRows));
        component.set("v.woToSave", setRows);
        */
        var bktWorkord = component.get("v.bundleWO");
        var selectedRows = event.getParam('selectedRows');
        console.log('selectedRows length-->'+selectedRows.length);
        console.log('selectedRows -->'+JSON.stringify(selectedRows));
        for(var i = 0; i < selectedRows.length; i++){
            console.log('bktWorkord--->'+bktWorkord.Bundle_Id__c);
            selectedRows[i].Bundle_Id__c = bktWorkord.Bundle_Id__c;
            console.log('bundle id--->'+selectedRows[i].Bundle_Id__c);
        }
        component.set('v.selectedRowsAdd', selectedRows);
    },
    
    handleRemvoeBndl : function(component, event, helper){
        var bktWorkord = component.get("v.bundleWO");
        var selectedRows = event.getParam('selectedRows');
        console.log('selectedRows length-->'+selectedRows.length);
        console.log('selectedRows -->'+JSON.stringify(selectedRows));
        for(var i = 0; i < selectedRows.length; i++){
            console.log('bktWorkord--->'+bktWorkord.Bundle_Id__c);
            selectedRows[i].Bundle_Id__c = '';
            console.log('bundle id--->'+selectedRows[i].Bundle_Id__c);
        }
        component.set('v.selectedRowsAdd', selectedRows);
    },
    
    saveTobucket : function(component, event, helper){
        component.set("v.loadSpinner", true);
        var bktWorkord = component.get("v.bundleWO");
        var bktWos = component.get("v.selectedRowsAdd");
        console.log('bktWos length-->'+bktWos.length);
        console.log('bktWos -->'+JSON.stringify(bktWos));
        /*
        var bktSave = [];
        if(bktWos.length != 0){
            for(var i = 0; i < bktWos.length; i++){
                bktWos[i].Bundle_Id__c = bktWorkord.Bundle_Id__c;
                bktSave.push(bktWos[i]);
            }
        }
        console.log('bts to save--->'+bktSave.length);
        */
        if(bktWos.length != 0){
            var savBkt = component.get("c.saveToBndl");
            savBkt.setParams({
                woLst : bktWos
            });
            savBkt.setCallback(this, function(response){
                console.log('response save--->'+JSON.stringify(response.getError()));
                if(response.getState() == 'SUCCESS'){
                    var retVal = response.getReturnValue();
                    console.log('return value--->'+retVal);
                    if(retVal == 'success'){
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            title : 'Success',
                            message : 'Work Orders successfully added to this bundle!',
                            duration : ' 5000',
                            key : 'info_alt',
                            type : 'success',
                            mode : 'pester'
                        });
                        toastEvent.fire();
                        component.set("v.selectedRows", []);
                        helper.getWorkOrder(component, event, helper);
                    }else{
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            title : 'Error',
                            message : retVal,
                            duration : ' 5000',
                            key : 'info_alt',
                            type : 'error',
                            mode : 'pester'
                        });
                        toastEvent.fire();
                        component.set("v.loadSpinner", false);
                    }
                }
            });
            $A.enqueueAction(savBkt);
        }
    }
})