@isTest
private class IncreamentDaysSinceApprovalTest {
    @testSetup
    static void setup() {
        Test.startTest();
        WorkOrder wo = new WorkOrder();
        wo.Approval_Requested_Date__c = System.today()-10;
        wo.Status ='Approved';
        wo.Approved__c =False;
        insert wo;
        Test.stopTest();
    }
    @isTest 
    static void test() {
        Test.startTest();
        WorkOrder wo = [SELECT Id,Days_Since_Approval_Raised__c FROM WorkOrder LIMIT 1];
        IncreamentDaysSinceApprovalBatch idp = new IncreamentDaysSinceApprovalBatch();
        Id batchId = Database.executeBatch(idp);
        Test.stopTest();
        WorkOrder woCheck = [SELECT Id,Days_Since_Approval_Raised__c FROM WorkOrder WHERE Id =:wo.Id];
        System.assert(woCheck.Days_Since_Approval_Raised__c != 0);
    }
}