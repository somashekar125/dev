trigger ProjectProductTrigger on Project_Product__c (before insert, before update ) {
    if(trigger.isBefore){
        ProjectProductTriggerHandler.duplicateCheckPrimaryProduct(trigger.new);
    }
}