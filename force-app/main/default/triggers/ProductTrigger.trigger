trigger ProductTrigger on Product2 (before insert, before update, after insert, after update, before delete) {
    if(trigger.isInsert && trigger.isBefore){
        productTriggerHandler.handleBeforeInsert(trigger.new);
    }
    
    if(trigger.isUpdate && trigger.isBefore){
        ProductTriggerHandler.handleBeforeUpdate(trigger.newMap, trigger.oldMap);
    }
    
    if(trigger.isInsert && trigger.isAfter){
        productTriggerHandler.handleAfterInsert(trigger.new);
    }
    
    if(trigger.isUpdate && trigger.isAfter){
        ProductTriggerHandler.handleAfterUpdate(trigger.newMap, trigger.oldMap);
    }
    
    if(trigger.isDelete && trigger.isBefore){
        ProductTriggerHandler.handleBeforeDelete(trigger.old);
    }
}