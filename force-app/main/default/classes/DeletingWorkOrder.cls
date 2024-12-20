public without sharing class DeletingWorkOrder {
    @AuraEnabled
    public static Map<Id,String> getInvalidWOs(String workOrderId){
        System.debug('workOrderId-> ' + workOrderId);
        Id partShipId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get( 'Part_Shipment' ).getRecordTypeId();
        Id onsiteLaborId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get( 'Onsite_Labor' ).getRecordTypeId();
        String partError = 'You cannot delete this work order, as it is already in production';
        String onsiteError = 'You cannot delete this work order, as a technician is already assigned to this work order';
        String partOnsiteError = 'This work order is child of a parent work order. You cannot delete child work orders. To delete child work orders, please delete parent work order';
        
        List<WorkOrder> woList = [SELECT Id,WorkOrderNumber,CaseId,NetsuiteId__c,RecordTypeId,Status,Service_Type__c,
                                  ParentWorkOrderId FROM WorkOrder WHERE Id =: workOrderId LIMIT 1];
        Map<Id,String> invalidWOMap = new Map<Id,String>();
        if(woList[0].RecordTypeId == partShipId && String.isNotBlank(woList[0].NetsuiteId__c) ){
            invalidWOMap.put(woList[0].Id,partError);
        } else if(woList[0].RecordTypeId == onsiteLaborId && woList[0].Status == 'Technician Scheduled / Assigned') {
            invalidWOMap.put(woList[0].Id,onsiteError);
        } else if(woList[0].Service_Type__c == 'Advance Exchange + Onsite' && woList[0].ParentWorkOrderId != null){
            invalidWOMap.put(woList[0].Id,partOnsiteError);
        }
        
        if(woList[0].CaseId != null){
            woList = [SELECT Id,WorkOrderNumber,CaseId,NetsuiteId__c,RecordTypeId,Status,Service_Type__c,
                                  ParentWorkOrderId FROM WorkOrder WHERE CaseId =: woList[0].CaseId];
            for(WorkOrder wo : woList){
                if(wo.Id == workOrderId) continue;
                if(wo.RecordTypeId == partShipId && String.isNotBlank(wo.NetsuiteId__c) ){
                    invalidWOMap.put(wo.Id,partError);
                } else if(wo.RecordTypeId == onsiteLaborId && wo.Status == 'Technician Scheduled / Assigned') {
                    invalidWOMap.put(wo.Id,onsiteError);
                } else if(wo.Service_Type__c == 'Advance Exchange + Onsite' && wo.ParentWorkOrderId != null){
                    invalidWOMap.put(wo.Id,partOnsiteError);
                }
            }
        }
        System.debug('invalidWOMap size-> ' + invalidWOMap.size());
        return invalidWOMap;
    }
    
    @AuraEnabled
    public static List<WorkOrder> retreiveRelatedWOs(String workOrderId){
        System.debug('workOrderId-> ' + workOrderId);
        List<WorkOrder> woList = [SELECT Id,WorkOrderNumber,CaseId,NetsuiteId__c FROM WorkOrder WHERE Id =: workOrderId LIMIT 1];
        if(woList[0].CaseId != null){
            woList = [SELECT Id,WorkOrderNumber,CaseId FROM WorkOrder WHERE CaseId =: woList[0].CaseId];
        }
        return woList;
    }
    
    @AuraEnabled
    public static Boolean deleteCurrentWorkOrder(String workOrderId){
        Boolean isDeleted = false;
        WorkOrder wo = [SELECT Id,Deleting_Current_WO__c FROM WorkOrder WHERE Id =: workOrderId];
        wo.Deleting_Current_WO__c = true;
        update wo;
        delete wo;
        isDeleted = true;
        return isDeleted;
    }
    
    @AuraEnabled
    public static Boolean deleteAllWOsAndCase(String workOrderId){
        Boolean areDeleted = false;
        /*List<Case> csList = [SELECT Id FROM Case WHERE Id IN (SELECT CaseId FROM WorkOrder WHERE Id =: workOrderId)];
        if(csList != null){
            delete csList;
            areDeleted = true;
        } else {
            delete [SELECT Id FROM WorkOrder WHERE Id =: workOrderId];
            areDeleted = true;
        }*/
        delete [SELECT Id FROM WorkOrder WHERE Id =: workOrderId];
        areDeleted = true;
        return areDeleted;
    }
}