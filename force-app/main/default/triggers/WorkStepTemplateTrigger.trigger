trigger WorkStepTemplateTrigger on WorkStepTemplate (after update) {
    if(trigger.isUpdate && trigger.isAfter){
        WorkStepTemplateTriggerHandler.handleAfterUpdate(trigger.newMap, trigger.oldMap);
    }
}