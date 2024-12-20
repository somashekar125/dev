trigger WorkOrderTrigger on WorkOrder (before insert, after insert, after update, before update, before delete) {
    Trigger_Execution_Manager__mdt mc = Trigger_Execution_Manager__mdt.getInstance('WorkOrder');

    if(trigger.isInsert && trigger.isBefore) {
        if((mc == null) || (mc != null && mc.Execute_Before_Insert__c)) {
            WorkOrderTriggerHandler.handleBeforeInsert(trigger.new);
        }
    }

    if(trigger.isInsert && trigger.isAfter) {
        if((mc == null) || (mc != null && mc.Execute_After_Insert__c)) {
            WorkOrderTriggerHandler.handleAfterInsert(trigger.new);
        }
    }
    
    if(trigger.isUpdate && trigger.isBefore) {
        if((mc == null) || (mc != null && mc.Execute_Before_Update__c)) {
            WorkOrderTriggerHandler.handleBeforeUpdate(trigger.newMap, trigger.oldMap);
        }
    }
    
    if(trigger.isUpdate && trigger.isAfter) {
        if((mc == null) || (mc != null && mc.Execute_After_Update__c)) {
            WorkOrderTriggerHandler.handleAfterUpdate(trigger.newMap, trigger.oldMap);
        }
    }
    
    if(trigger.isDelete && trigger.isBefore){
        if(!System.isFuture() && ((mc == null) || (mc != null && mc.Execute_Before_Delete__c))) {
            WorkOrderTriggerHandler.handleBeforeDelete(trigger.newMap, trigger.oldMap);
        }
    }
}