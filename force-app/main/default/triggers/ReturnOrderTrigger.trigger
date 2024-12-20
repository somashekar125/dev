trigger ReturnOrderTrigger on ReturnOrder (before insert, before update) {
	 if(trigger.isInsert && trigger.isBefore) {
        ReturnOrderTriggerHandler.handleBeforeInsert(trigger.new);
    }
    
    if(trigger.isUpdate && trigger.isBefore) {
        ReturnOrderTriggerHandler.handleBeforeUpdate(trigger.newMap, trigger.oldMap);
    }
}