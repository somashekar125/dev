public class WorkOrderQueueable implements Queueable {
    private List<WorkOrder> woList;
    
    public WorkOrderQueueable(List<WorkOrder> woList) {
        this.woList = woList;
    }
    
    public void execute(QueueableContext context) {
        List<WorkOrder> toUpdateList = new List<WorkOrder>();
        for(WorkOrder wo : woList) {
            Boolean isUpdated = false;
            if(wo.RecordTypeId == System.Label.Part_Request_WO_RT_Id && wo.OwnerId != System.Label.Part_Request_Queue_Id) {
                wo.OwnerId = System.Label.Part_Request_Queue_Id;
                isUpdated = true;
            } else if(wo.RecordTypeId == System.Label.Onsite_Labor_WO_RT_Id && wo.OwnerId != System.Label.Onsite_Labor_Queue_Id) {
                wo.OwnerId = System.Label.Onsite_Labor_Queue_Id;
                isUpdated = true;
            }
            System.debug('wo.OwnerId-> ' + wo.OwnerId);
            if(isUpdated) toUpdateList.add(wo);
        }
        WorkOrderTriggerHandler.runOnceBeforeUpdate = false;
        WorkOrderTriggerHandler.runOnceAfterUpdate = false;
        Database.update(toUpdateList, false);
    }
}