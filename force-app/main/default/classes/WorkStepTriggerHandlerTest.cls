@isTest
public class WorkStepTriggerHandlerTest {
    @isTest static void testMehtod1(){
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
        insert ws;
        WorkStepTemplate wst = new WorkStepTemplate();
        wst.IsActive = true;
        wst.Name = 'Test Work Step';
        wst.Expected_Minutes_to_Complete__c = 10;
        insert wst;
        
        Test.startTest();
        ws.StartTime = System.now();
        update ws;
        //WorkStep wsCheck = [SELECT Id,Health_Status__c FROM WorkStep WHERE Id =: ws.Id];
        //System.assert(wsCheck.Health_Status__c == 'Green');
        ws.StartTime = System.now().addHours(-2);
        update ws;
        //WorkStep wsCheck3 = [SELECT Id,Health_Status__c FROM WorkStep WHERE Id =: ws.Id];
        //System.assert(wsCheck3.Health_Status__c == 'Red');
        Test.stopTest();
    }
}