// Extension to delete all of the selected objects
public with sharing class MassDeleteExtension {

    ApexPages.StandardSetController setCon;
    public String error { get; set; }
    public PageReference originalUrl { get; set; }

    public MassDeleteExtension(ApexPages.StandardSetController controller) {
        setCon = controller;
    }

    public String getMySelectedSize() {
        return setCon.getSelected().size() + '';
    }
    
    public PageReference deleteRecords(){
        originalUrl = setCon.cancel();
        List<sObject> objSelectedList = setCon.getSelected();
        List<WorkOrder> woListToUpdate = new List<WorkOrder>();
        system.debug('objSelectedList size-> ' + objSelectedList.size());
        system.debug('objSelectedList-> ' + JSON.Serialize(objSelectedList));
        for(sObject obj : objSelectedList){
            Id objId = obj.Id;
            String sObjName = objId.getSObjectType().getDescribe().getName();
            system.debug('sObjName-> ' + sObjName);
            if(sObjName == 'WorkOrder'){
                WorkOrder  wo = (WorkOrder) obj;
                wo.NetsuiteId__c = null;
                woListToUpdate.add(wo);
                system.debug('wo.NetsuiteId__c-> ' + wo.NetsuiteId__c);
            }
        }
        system.debug('woListToUpdate size-> ' + woListToUpdate.size());
        if(woListToUpdate.size() > 0){
            update woListToUpdate;
        }
        system.debug('setCon.getSelected()-> ' + setCon.getSelected());
        delete setCon.getSelected();
        return originalUrl;
    }

}