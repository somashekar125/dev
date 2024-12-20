public without sharing class WorkStepTemplateTriggerHandler {
    public static void handleAfterUpdate(Map<Id,WorkStepTemplate> newMap, Map<Id,WorkStepTemplate> oldMap){
        updateWorkStepHealth(newMap, oldMap);
    }

    public static void updateWorkStepHealth(Map<Id,WorkStepTemplate> newMap, Map<Id,WorkStepTemplate> oldMap){
        Set<String> wstNames = new Set<String>();
        for(WorkStepTemplate wst : newMap.values()){
            if(wst.IsActive == false) continue;
            wstNames.add(wst.Name);
        }
        List<WorkStep> wsList = [SELECT Id,Name,StartTime,Health_Status__c,WorkOrderId,Status FROM WorkStep WHERE Name IN:wstNames];
        if(!wsList.isEmpty()){
            List<WorkStep> wsListToUpdate = new List<WorkStep>();
            List<WorkOrder> woList = new List<WorkOrder>();
            for(WorkStep ws : wsList){
                for(WorkStepTemplate wst : newMap.values()){
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
                    wsListToUpdate.add(ws);
                }
                if(ws.Status == 'In Progress'){
                    WorkOrder wo = new WorkOrder(Id = ws.WorkOrderId, Work_Step__c = ws.Id);
                    woList.add(wo);
                }
            }
            if(!wsListToUpdate.isEMpty()){
                update wsListToUpdate;
            }
            if(!woList.isEmpty()){
                update woList;
            }
        }
    }
}