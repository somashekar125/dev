trigger MaintenancePlanTrigger on MaintenancePlan (after update) {
    if(trigger.isUpdate && trigger.isAfter) {
        MaintenancePlanTriggerHandler.handleAfterUpdate(trigger.newMap, trigger.oldMap);
    }
}