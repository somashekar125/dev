public class IncreamentDaysSinceApprovalBatch implements Database.Batchable<sObject>, Database.Stateful,Schedulable  {
    public void execute(SchedulableContext ctx){
        database.executebatch(new IncreamentDaysSinceApprovalBatch(), 1);
    }
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT ID, Days_Since_Approval_Raised__c,Approval_Requested_Date__c FROM WorkOrder Where Status = \'Approved\' and Approved__c = False'
        );
    }
    public void execute(Database.BatchableContext bc, List<WorkOrder> scope){
        for(WorkOrder wo : scope){
            wo.Days_Since_Approval_Raised__c = daysBetweenExcludingWeekends( wo.Approval_Requested_Date__c,System.today());
            System.debug('Days_Since_Approval_Raised__c-->' + wo.Days_Since_Approval_Raised__c);
        }
        update scope;
    }
    public static Integer daysBetweenExcludingWeekends(Datetime startDate, Datetime endDate) {
        Integer i = 0;
        while (startDate < endDate) {
            if (startDate.format('E') != 'Sat' && startDate.format('E') != 'Sun') {
                i++;
            }
            startDate = startDate.addDays(1);
        }
        return i;
    }
    public void finish(Database.BatchableContext bc){
    }

    /* Run this in deubg window to quick update.
    IncreamentDaysSinceApprovalBatch myBatchObject = new IncreamentDaysSinceApprovalBatch();
    Id batchId = Database.executeBatch(myBatchObject);
    OR...
    Id batchId = Database.executeBatch(myBatchObject, 100);
    */
}