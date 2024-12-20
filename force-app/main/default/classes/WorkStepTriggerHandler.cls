public without sharing class WorkStepTriggerHandler {
    public static void handleBeforeUpdate(Map<Id,WorkStep> newMap, Map<Id,WorkStep> oldMap){
        updateWorkStepHealth(newMap, oldMap);
    }

    public static void updateWorkStepHealth(Map<Id,WorkStep> newMap, Map<Id,WorkStep> oldMap){
        Set<String> wsNames = new Set<String>();
        List<WorkOrder> woList = new List<WorkOrder>();
        for(WorkStep ws : newMap.values()){
            wsNames.add(ws.Name);
            if(ws.Status != oldMap.get(ws.Id).Status && ws.Status == 'Completed'){
                ws.EndTime = System.now();
            }
        }
        List<WorkStepTemplate> wstList = [SELECT Id,Name,Expected_Minutes_to_Complete__c FROM WorkStepTemplate WHERE Name IN: wsNames AND Expected_Minutes_to_Complete__c != null];
        for(WorkStep ws : newMap.values()){
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
            if(ws.Status == 'In Progress'){
                WorkOrder wo = new WorkOrder(Id = ws.WorkOrderId, Work_Step__c = ws.Id);
                woList.add(wo);
            }
        }
        if(!woList.isEmpty()){
            update woList;
        }
    }
}