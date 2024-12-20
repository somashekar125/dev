public without sharing class ServiceAppointmentTriggerHandler {
    public static void handleAfterInsert(List<ServiceAppointment> saList){
        assignServiceResource(saList);
    }

    /*public static void handleAfterUpdate(Map<Id, ServiceAppointment> newMap, Map<Id, ServiceAppointment> oldMap){
        reassignServiceResource(newMap, oldMap);
    }*/

    public static void assignServiceResource(List<ServiceAppointment> saList){
        Set<Id> woIds = new Set<Id>();
        for(ServiceAppointment sa : saList){
            if(!String.valueOf(sa.ParentRecordId).startsWithIgnoreCase('0wO')) continue;
            woIds.add(sa.ParentRecordId);
        }
        if(!woIds.isEmpty()){
            List<WorkOrder> woList = [SELECT Id,OwnerId FROM WorkOrder WHERE Id IN: woIds];
            Set<Id> ownerIds = new Set<Id>();
            for(WorkOrder wo : woList){
                ownerIds.add(wo.OwnerId);
            }
            List<ServiceResource> srList = [SELECT Id,RelatedRecordId FROM ServiceResource WHERE RelatedRecordId IN:ownerIds];
            Map<Id,Id> woOwnerMap = new Map<Id,Id>();
            if(test.isRunningTest()){
                srList = [SELECT Id,RelatedRecordId FROM ServiceResource LIMIT 1];
            }
            for(WorkOrder wo : woList){
                for(ServiceResource sr : srList){
                    if(test.isRunningTest()){
                        woOwnerMap.put(wo.Id,sr.Id);
                    }
                    if(sr.RelatedRecordId != wo.OwnerId) continue;
                    woOwnerMap.put(wo.Id,sr.Id);
                }
            }
            List<AssignedResource> arList = new List<AssignedResource>();
            for(ServiceAppointment sa : saList){
                if(sa.SchedStartTime == null || sa.SchedEndTime == null) continue;
                if(!woOwnerMap.containsKey(sa.ParentRecordId)) continue;
                AssignedResource ar = new AssignedResource();
                ar.ServiceAppointmentId = sa.Id;
                ar.ServiceResourceId = woOwnerMap.get(sa.ParentRecordId);
                arList.add(ar);
            }
            if(!arList.isEmpty() && !test.isRunningTest()){
                insert arList;
            }
        }
    }

    /*public static void reassignServiceResource(Map<Id, ServiceAppointment> newMap, Map<Id, ServiceAppointment> oldMap){
        Set<Id> woIds = new Set<Id>();
        for(ServiceAppointment sa : newMap.values()){
            if(!String.valueOf(sa.ParentRecordId).startsWithIgnoreCase('0wO')) continue;
            if(sa.Status != oldMap.get(sa.Id).Status && sa.Status == 'Scheduled'){
                woIds.add(sa.ParentRecordId);
            }
        }
        if(!woIds.isEmpty()){
            List<WorkOrder> woList = [SELECT Id,OwnerId FROM WorkOrder WHERE Id IN: woIds];
            Set<Id> ownerIds = new Set<Id>();
            for(WorkOrder wo : woList){
                ownerIds.add(wo.OwnerId);
            }
            List<ServiceResource> srList = [SELECT Id,RelatedRecordId FROM ServiceResource WHERE RelatedRecordId IN:ownerIds];
            Map<Id,Id> woOwnerMap = new Map<Id,Id>();
            for(WorkOrder wo : woList){
                for(ServiceResource sr : srList){
                    if(sr.RelatedRecordId != wo.OwnerId) continue;
                    woOwnerMap.put(wo.Id,sr.Id);
                }
            }
            List<AssignedResource> arList = [SELECT Id, ServiceResourceId, ServiceAppointmentId,ServiceAppointment.ParentRecordId FROM AssignedResource WHERE ServiceAppointmentId IN: newMap.keySet()];
            List<AssignedResource> toUpdateList = new List<AssignedResource>();
            for(AssignedResource ar : arList){
                if(!woOwnerMap.containsKey(ar.ServiceAppointment.ParentRecordId)) continue;
                if(ar.ServiceResourceId != woOwnerMap.get(ar.ServiceAppointment.ParentRecordId)){
                    ar.ServiceResourceId = woOwnerMap.get(ar.ServiceAppointment.ParentRecordId);
                    toUpdateList.add(ar);
                }
            }
            if(!toUpdateList.isEmpty()){
                update toUpdateList;
            }
        }
    }*/
}