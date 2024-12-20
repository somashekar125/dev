trigger WorkOrderLineItemTrigger on WorkOrderLineItem (before insert, after insert,before update, after update, before delete, after delete) {
    if(trigger.isInsert && trigger.isBefore) {
        WorkOrderLineItemTriggerHandler.handleBeforeInsert(trigger.new);
    }

    if(trigger.isInsert && trigger.isAfter) {
        WorkOrderLineItemTriggerHandler.handleAfterInsert(trigger.newMap);
    }

    if(trigger.isUpdate && trigger.isBefore) {
        WorkOrderLineItemTriggerHandler.handlebeforeUpdate(trigger.newMap, trigger.oldMap);
    }
    
    if(trigger.isUpdate && trigger.isAfter) {
        WorkOrderLineItemTriggerHandler.handleAfterUpdate(trigger.newMap, trigger.oldMap);
    }

    if(trigger.isDelete && trigger.isBefore){
        WorkOrderLineItemTriggerHandler.handleBeforeDelete(trigger.oldMap);
    }

    if(trigger.isDelete && trigger.isAfter) {
        WorkOrderLineItemTriggerHandler.handleAfterDelete(trigger.oldMap);
    }
}