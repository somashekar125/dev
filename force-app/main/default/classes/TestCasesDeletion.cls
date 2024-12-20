global class TestCasesDeletion implements Schedulable{
    global void execute(SchedulableContext sc){
        list<Case> csList = [SELECT Id,(SELECT Id,NetsuiteId__c,Status,RecordTypeId,ParentWorkOrderId,Service_Type__c FROM WorkOrders) FROM Case WHERE Incident__c like '%TEST%'];
        Map<Id,Case> csMapToDelete = new Map<Id,Case>();
        Id partShipId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get( 'Part_Shipment' ).getRecordTypeId();
        Id onsiteLaborId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get( 'Onsite_Labor' ).getRecordTypeId();

        for(Case cs : csList){
            Set<Id> invalidCaseIds = new Set<Id>();
            for(WorkOrder wo : cs.WorkOrders){
                if(wo.RecordTypeId == partShipId && String.isNotBlank(wo.NetsuiteId__c)){
                    invalidCaseIds.add(cs.Id);
                }
                if(wo.RecordTypeId == onsiteLaborId && wo.Status == 'Technician Scheduled / Assigned') {
                    invalidCaseIds.add(cs.Id);
                }
                if(wo.Service_Type__c == 'Advance Exchange + Onsite' && wo.ParentWorkOrderId != null) {
                    invalidCaseIds.add(cs.Id);
                }
            }
            if(!invalidCaseIds.contains(cs.Id)){
                csMapToDelete.put(cs.Id,cs);
            }
        }
        Database.delete(csMapToDelete.values(), false);
    }
}