trigger SalesOrderTrigger on Sales_Order__c (before insert, after update, before update) {
    
    if(trigger.isInsert && trigger.isBefore) {
        SalesOrderTriggerHandler.handleBeforeInsert(trigger.new);
    }
    if(trigger.isUpdate && trigger.isBefore) {
        SalesOrderTriggerHandler.handleBeforeUpdate(trigger.newMap, trigger.oldMap);
    }
    
    if(trigger.isUpdate && trigger.isAfter) {
        SalesOrderTriggerHandler.handleAfterUpdate(trigger.newMap, trigger.oldMap);
    }
}