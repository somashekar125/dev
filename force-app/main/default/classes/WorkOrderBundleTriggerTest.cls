@isTest
public class WorkOrderBundleTriggerTest {
    @isTest static void testMthod1(){
        Global_Settings__c gs = TestDataFactory.CreateGlobalSettings();
        insert gs;
        Id wokId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Bundle_Work_Order').getRecordTypeId();
        WorkOrder wo = new WorkOrder();
        wo.RecordTypeId = wokId;
        Test.startTest();
        insert wo;
        Test.stopTest();
    }
}