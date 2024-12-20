trigger WorkStepTrigger on WorkStep (before update) {
    if(trigger.isUpdate && trigger.isBefore){
        WorkStepTriggerHandler.handleBeforeUpdate(trigger.newMap, trigger.oldMap);
    }
}