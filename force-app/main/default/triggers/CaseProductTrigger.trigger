trigger CaseProductTrigger on Case_Product__c (after insert,before insert) {
    if(trigger.isAfter && trigger.isInsert){
        CaseProductTriggerHandler.handleAfterInsert(trigger.new);
    }
    if(trigger.isBefore && trigger.isInsert){
        CaseProductTriggerHandler.handleBeforeInsert(trigger.new);
    }
}