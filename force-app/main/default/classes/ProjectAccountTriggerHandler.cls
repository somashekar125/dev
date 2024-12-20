public class ProjectAccountTriggerHandler {
    public static boolean runOnceAfterUpdate = true;
    public static void handleBeforeInsert(List<Project_Account__c> prjAccList) {
        checkForDuplicates(prjAccList);
    }

    public static void handleBeforeUpdate(Map<Id, Project_Account__c> newMap, Map<Id, Project_Account__c> oldMap) {
        List<Project_Account__c> accountChangedRecords = new List<Project_Account__c>();

        for (Project_Account__c newRecord : newMap.values()) {
            if (newRecord.Account__c != oldMap.get(newRecord.Id).Account__c && newRecord.Account__c != null) {
                accountChangedRecords.add(newRecord);
            }
        }
        
        if (!accountChangedRecords.isEmpty()) {
            checkForDuplicates(accountChangedRecords);
        }
    }

    public static void handleAfterUpdate(Map<Id, Project_Account__c> newMap, Map<Id, Project_Account__c> oldMap) {
        if(!runOnceAfterUpdate) return;
        List<Project_Account__c> visitChangedRecords = new List<Project_Account__c>();
        for (Id recordId : newMap.keySet()) {
            Project_Account__c newRecord = newMap.get(recordId);
            Project_Account__c oldRecord = oldMap.get(recordId);

            if (newRecord.Visit_1__c != oldRecord.Visit_1__c || newRecord.Visit_2__c != oldRecord.Visit_2__c || newRecord.Visit_3__c != oldRecord.Visit_3__c) {
                visitChangedRecords.add(newRecord);
            }
        }

        if (!visitChangedRecords.isEmpty()) {
            updateCaseAndWorkOrder(visitChangedRecords);
        }
    }

    public static void checkForDuplicates(List<Project_Account__c> prjAccList) {
        Set<Id> projectIds = new Set<Id>();
        for (Project_Account__c pac : prjAccList) {
            if (pac.Project__c != null) {
                projectIds.add(pac.Project__c);
            }
        }

        Map<Id, Set<Id>> existingAccountsByProject = new Map<Id, Set<Id>>();
        List<Project_Account__c> existingList = [
            SELECT Id, Project__c, Account__c 
            FROM Project_Account__c 
            WHERE Project__c IN :projectIds
        ];

        for (Project_Account__c pa : existingList) {
            if (!existingAccountsByProject.containsKey(pa.Project__c)) {
                existingAccountsByProject.put(pa.Project__c, new Set<Id>());
            }
            existingAccountsByProject.get(pa.Project__c).add(pa.Account__c);
        }

        for (Project_Account__c pac : prjAccList) {
            if (pac.Project__c != null && pac.Account__c != null) {
                if (existingAccountsByProject.containsKey(pac.Project__c) && existingAccountsByProject.get(pac.Project__c).contains(pac.Account__c)) {
                    pac.addError('A Project Account with this Account already exists for this Project.');
                }
            }
        }
    }

    public static void updateCaseAndWorkOrder(List<Project_Account__c> visitChangedRecords) {
        Set<Id> projectAccountIds = new Set<Id>();
        for (Project_Account__c pac : visitChangedRecords) {
            projectAccountIds.add(pac.Id);
        }
        List<Case> relatedCaseList = [SELECT Id, Preferred_Time__c,ServiceContractId, ServiceContract.Visit_Order__c, Project_Account__c, 
                                      (SELECT Id, Preferred_Time_IMAC__c, Project_Account__c,ServiceContract.Visit_Order__c FROM WorkOrders WHERE Project_Account__c IN :projectAccountIds) 
                                      FROM Case WHERE Project_Account__c IN :projectAccountIds AND Status NOT IN ('Tech Checked In','Revisit Required','Onsite Work Completed','Part Shipped','Closed','Cancelled','Approved','Merged')];
        List<Case> casesToUpdateList = new List<Case>();
        List<WorkOrder> workOrdersToUpdateList = new List<WorkOrder>();

        for (Project_Account__c projectAccount : visitChangedRecords) {
            for (Case c : relatedCaseList) {
                if (c.Project_Account__c != projectAccount.Id) continue;
                Boolean toCaseUpdate = false;
                if (c.ServiceContract.Visit_Order__c == 'Visit 3' && projectAccount.Visit_3__c != null) {
                    c.Preferred_Time__c = projectAccount.Visit_3__c;
                    toCaseUpdate = true;
                } else if (c.ServiceContract.Visit_Order__c == 'Visit 2' && projectAccount.Visit_2__c != null) {
                    c.Preferred_Time__c = projectAccount.Visit_2__c;
                    toCaseUpdate = true;
                } else if (c.ServiceContract.Visit_Order__c == 'Visit 1' && projectAccount.Visit_1__c != null) {
                    c.Preferred_Time__c = projectAccount.Visit_1__c;
                    toCaseUpdate = true;
                }
                if(toCaseUpdate) casesToUpdateList.add(c);

                for (WorkOrder wo : c.WorkOrders) {
                    Boolean toWorkorderUpdate = false;
                    if (wo.ServiceContract.Visit_Order__c == 'Visit 3' && projectAccount.Visit_3__c != null) {
                        wo.Preferred_Time_IMAC__c = projectAccount.Visit_3__c;
                        toWorkorderUpdate = true;
                    } else if (wo.ServiceContract.Visit_Order__c == 'Visit 2' && projectAccount.Visit_2__c != null) {
                        wo.Preferred_Time_IMAC__c = projectAccount.Visit_2__c;
                        toWorkorderUpdate = true;
                    } else if (wo.ServiceContract.Visit_Order__c == 'Visit 1' && projectAccount.Visit_1__c != null) {
                        wo.Preferred_Time_IMAC__c = projectAccount.Visit_1__c;
                        toWorkorderUpdate = true;
                    }
                    if(toWorkorderUpdate) workOrdersToUpdateList.add(wo);
                }
            }
        }

        if (!casesToUpdateList.isEmpty()) {
            update casesToUpdateList;
        }
        if (!workOrdersToUpdateList.isEmpty()) {
            WorkOrderTriggerHandler.runOnceBeforeUpdate = false;
            WorkOrderTriggerHandler.runOnceAfterUpdate = false;
            update workOrdersToUpdateList;
        }
    }
}