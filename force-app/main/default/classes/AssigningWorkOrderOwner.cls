public class AssigningWorkOrderOwner {
    @InvocableMethod(label='Assigning Owner')
    public static void callingQueuableClass(List<Id> woIds){
        List<WorkOrder> woList = [SELECT Id, OwnerId, RecordTypeId FROM WorkOrder WHERE Id IN: woIds];
        if(!woList.isEmpty()) System.enqueueJob(new WorkOrderQueueable(woList));
    }
}