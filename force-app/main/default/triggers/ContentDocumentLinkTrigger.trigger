trigger ContentDocumentLinkTrigger on ContentDocumentLink (after insert, before insert) {
	if(trigger.isInsert && trigger.isAfter) {
        ContentDocumentLinkTriggerHandler.handleAfterInsert(trigger.new);
    }
    if(trigger.isInsert && trigger.isBefore) {
        ContentDocumentLinkTriggerHandler.handleBeforeInsert(trigger.new);
    }
}