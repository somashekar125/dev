trigger AccountProductTrigger on Account_Product__c (before insert, before update, after update) {
    if(trigger.isInsert && trigger.isBefore){
        AccountProductTriggerHandler.handleBeforeInsert(trigger.new);
    }
    if(trigger.isUpdate && trigger.isBefore){
        AccountProductTriggerHandler.handleBeforeUpdate(trigger.newMap , trigger.oldMap);
    }
    if(trigger.isUpdate && trigger.isAfter){
        AccountProductTriggerHandler.handleAfterUpdate(trigger.newMap , trigger.oldMap);
    }
}