public with sharing class ParentWOLICreationBatch implements Database.Batchable<WorkOrderLineItem>{

    List<WorkOrderLineItem> woliList = null;
    public ParentWOLICreationBatch(List<WorkOrderLineItem> toInsert) {
        this.woliList = toInsert;
    }

    public Iterable<WorkOrderLineItem> start(Database.BatchableContext bc) {
        return woliList;
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope){
        insert scope;
    }
    public void finish(Database.BatchableContext BC){
        
    }
}