public with sharing class WorkStepHealthStatusCheckBatch implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id,Name,Health_Status__c,StartTime,Status,WorkOrderId FROM WorkStep');
    }
    public void execute(Database.BatchableContext BC, List<sObject> scope){
        List<WorkStep> wsList = new List<WorkStep>();
        for(SObject sobj : scope) {
            WorkStep  ws = (WorkStep) sobj;
            wsList.add(ws);
        }
        Set<String> wsNames = new Set<String>();
        for(WorkStep ws : wsList){
            wsNames.add(ws.Name);
        }
        List<WorkStepTemplate> wstList = [SELECT Id,Name,Expected_Minutes_to_Complete__c FROM WorkStepTemplate WHERE Name IN: wsNames AND Expected_Minutes_to_Complete__c != null];
        List<WorkStep> wsListToUpdate = new List<WorkStep>();
        List<WorkOrder> woList = new List<WorkOrder>();
        for(WorkStep ws : wsList){
            for(WorkStepTemplate wst : wstList){
                ws.Health_Status__c = 'Not Started';
                if(ws.Name != wst.Name || ws.StartTime == null || wst.Expected_Minutes_to_Complete__c == null) continue;
                Long timeDifferenceMillis = System.now().getTime() - ws.StartTime.getTime();
                Long timeDifferenceSeconds = timeDifferenceMillis / 1000;
                Integer elapsedMins = Integer.valueOf(timeDifferenceSeconds / 60);
                if(elapsedMins <= wst.Expected_Minutes_to_Complete__c && ws.Health_Status__c != 'Green'){
                    ws.Health_Status__c = 'Green';
                }
                if(elapsedMins > wst.Expected_Minutes_to_Complete__c && ws.Health_Status__c != 'Red'){
                    ws.Health_Status__c = 'Red';
                }
            }
            wsListToUpdate.add(ws);
            if(ws.Status == 'In Progress'){
                WorkOrder wo = new WorkOrder(Id = ws.WorkOrderId, Work_Step__c = ws.Id);
                woList.add(wo);
            }
        }
        if(!wsListToUpdate.isEmpty()){
            update wsListToUpdate;
        }
        if(!woList.isEmpty()){
            update woList;
        }
    }
    public void finish(Database.BatchableContext BC){
        if(!test.isRunningTest()){
            System.scheduleBatch(new WorkStepHealthStatusCheckBatch(), 'WorkStep Health Status Check Batch', 1, 30);
        }
    }
}