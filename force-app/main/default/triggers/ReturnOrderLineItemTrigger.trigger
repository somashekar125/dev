trigger ReturnOrderLineItemTrigger on ReturnOrderLineItem (before insert, after insert) {
	if(trigger.isInsert && trigger.isBefore) {
        ReturnOrderLineItemTriggerHandler.handleBeforeInsert(trigger.new);
    }

    if(trigger.isInsert && trigger.isAfter) {
        ReturnOrderLineItemTriggerHandler.handleAfterInsert(trigger.new);
    }
}