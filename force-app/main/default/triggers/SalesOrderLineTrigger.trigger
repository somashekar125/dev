trigger SalesOrderLineTrigger on Sales_Order_Line__c (before insert, before update, after insert, after update) {
    if(trigger.isInsert && trigger.isBefore){
        SalesOrderLineTriggerHandler.handlerBeforeInsert(trigger.new);
    }
    if(trigger.isUpdate && trigger.isBefore){
        SalesOrderLineTriggerHandler.handlerBeforeUpdate(trigger.new);
    }
    if(trigger.isInsert && trigger.isAfter){
        SalesOrderLineTriggerHandler.handlerAfterInsert(trigger.new);
    }
    if(trigger.isUpdate && trigger.isAfter){
        SalesOrderLineTriggerHandler.handlerAfterUpdate(trigger.newMap, trigger.oldMap);
    }
}