trigger AccoountTrigger on Account (before insert, after insert, before update, after update) {
    if(trigger.isInsert && trigger.isBefore){
        AccountTriggerHandler.handleBeforeInsert(trigger.new);
    }
    if(trigger.isInsert && trigger.isAfter){
        AccountTriggerHandler.handleAfterInsert(trigger.newMap);
    }
    if(trigger.isUpdate && trigger.isBefore){
        AccountTriggerHandler.handleBeforeUpdate(trigger.newMap, trigger.oldMap);
    }
    if(trigger.isUpdate && trigger.isAfter){
        AccountTriggerHandler.handleAfterUpdate(trigger.newMap, trigger.oldMap);
    }
}