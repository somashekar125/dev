@isTest
public class WorkStepTemplateTriggerHandlerTest {
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
        WorkStep ws = new WorkStep();
        ws.Name = 'Test Work Step';
        ws.WorkPlanId = wp.Id;
        ws.Health_Status__c = 'Not Started';
        ws.StartTime = System.now();
        insert ws;
        WorkStepTemplate wst = new WorkStepTemplate();
        wst.IsActive = true;
        wst.Name = 'Test Work Step';
        insert wst;
        
        WorkStep wsCheck = [SELECT Id,Health_Status__c FROM WorkStep WHERE Id =: ws.Id];
        System.assert(wsCheck.Health_Status__c == 'Not Started');
        
        Test.startTest();
        wst.Expected_Minutes_to_Complete__c = 60;
        update wst;
        Test.stopTest();
        //WorkStep wsCheck2 = [SELECT Id,Health_Status__c FROM WorkStep WHERE Id =: ws.Id];
        //System.assert(wsCheck2.Health_Status__c == 'Green');
    }
}