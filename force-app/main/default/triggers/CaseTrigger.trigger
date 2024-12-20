trigger CaseTrigger on Case (after insert, before insert,  before update, after update, before delete) {
    Trigger_Execution_Manager__mdt mc = Trigger_Execution_Manager__mdt.getInstance('Case');

    if(trigger.isInsert && trigger.isBefore) {
        if((mc == null) || (mc != null && mc.Execute_Before_Insert__c)) {
            CaseTriggerHandler.handleBeforeInsert(trigger.new);
        }
    }

    if(trigger.isInsert && trigger.isAfter) {
        if((mc == null) || (mc != null && mc.Execute_After_Insert__c)) {
            CaseTriggerHandler.handleAfterInsert(trigger.new);
        }
    }

    if(trigger.isUpdate && trigger.isBefore) {
        if((mc == null) || (mc != null && mc.Execute_Before_Update__c)) {
            CaseTriggerHandler.handleBeforeUpdate(trigger.newMap, trigger.oldMap);
        }
    }

    if(trigger.isUpdate && trigger.isAfter) {
        if((mc == null) || (mc != null && mc.Execute_After_Update__c)) {
            CaseTriggerHandler.handleAfterUpdate(trigger.newMap, trigger.oldMap);
        }
    }

    if(trigger.isDelete && trigger.isBefore){
        if(!System.isFuture() && ((mc == null) || (mc != null && mc.Execute_Before_Delete__c))) {
            CaseTriggerHandler.handleBeforeDelete(trigger.old);
        }
    }
}