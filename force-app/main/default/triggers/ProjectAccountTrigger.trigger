trigger ProjectAccountTrigger on Project_Account__c  (before insert, before update, after update) {
    
    if(trigger.isInsert && trigger.isBefore) {
        ProjectAccountTriggerHandler.handleBeforeInsert(Trigger.new);
    }

    if(trigger.isUpdate && trigger.isBefore) {
        ProjectAccountTriggerHandler.handleBeforeUpdate(Trigger.newMap, Trigger.oldMap);
    }
    if(trigger.isUpdate && trigger.isAfter) {
        ProjectAccountTriggerHandler.handleAfterUpdate(Trigger.newMap, Trigger.oldMap);
    }
}