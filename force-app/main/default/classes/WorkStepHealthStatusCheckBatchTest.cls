@isTest
public class WorkStepHealthStatusCheckBatchTest {
    @isTest static void testMethod1(){
        Global_Settings__c gs = TestDataFactory.CreateGlobalSettings();
        insert gs;
        Account acc = TestDataFactory.createAccount();
        insert acc;
        ServiceContract sc = TestDataFactory.createServiceContract(acc);
        insert sc;
        Case cs = TestDataFactory.createCase(acc, sc);
        insert cs;
        WorkOrder wo = TestDataFactory.createWorkOrder(cs, sc, acc);
        insert wo;
        
        WorkPlan wp = new WorkPlan();
        wp.Name = 'Test Work Plan';
        wp.WorkOrderId = wo.Id;
        insert wp;
        
        Test.startTest();
        WorkStep ws = new WorkStep();
        ws.Name = 'Test Work Step';
        ws.WorkPlanId = wp.Id;
        ws.Health_Status__c = 'Not Started';
        ws.StartTime = System.now();
        insert ws;
        WorkStepTemplate wst = new WorkStepTemplate();
        wst.IsActive = true;
        wst.Name = 'Test Work Step';
        wst.Expected_Minutes_to_Complete__c = 10;
        insert wst;
        wst.Expected_Minutes_to_Complete__c = 20;
        update wst;
        
        WorkStepHealthStatusCheckBatch wjob = new WorkStepHealthStatusCheckBatch();
        Database.executeBatch(wjob,7);
        Test.stopTest();
    }
}