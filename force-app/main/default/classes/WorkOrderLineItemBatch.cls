public with sharing class WorkOrderLineItemBatch implements Database.Batchable<sObject>{
    public Database.QueryLocator start(Database.BatchableContext bc){
        String query = 'SELECT Id,Status,EndDate,Product2.Name FROM WorkOrderLineItem WHERE WorkOrder.Status != \'Closed\' AND ' + 
                       'Product2.Name LIKE \'%RENTAL-COST%\' AND EndDate != null AND Status NOT IN (\'Pickup Requested\', \'Picked Up\', \'Invoiced\', \'Returned\', \'Pickup Requested - Auto\', \'Closed\')';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<WorkOrderLineItem> scope){
        List<WorkOrderLineItem> toUpdateList = new List<WorkOrderLineItem>();
        for(WorkOrderLineItem woli : scope){
            System.debug('woli.EndDate-> ' + woli.EndDate);
            if(woli.EndDate.date() == System.now().date() && woli.EndDate.minute() == System.now().minute()){
                woli.Status = 'Pickup Requested - Auto';
                System.debug('Woli Id-> ' + woli.Id + ' Woli Status->' + woli.Status);
                toUpdateList.add(woli);
            }
        }
        System.debug('Updating To "Pickup Requested - Auto"' + toUpdateList.size());
        if(!toUpdateList.isEmpty()){
            update toUpdateList;
        }
    }

    public void finish(Database.BatchableContext BC){
        if(!test.isRunningTest()){
            System.scheduleBatch(new WorkOrderLineItemBatch(), 'Work Order Line Item Batch', 1, 10);
        }
    }
}