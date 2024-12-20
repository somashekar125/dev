@isTest
public class ReturnOrderTriggerHandlerTest {
    @testSetup static void setup() {
        Test.startTest();
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
        
        Sales_Order__c so = new Sales_Order__c();
        so.Name = '123456';
        so.Work_Order__c = wo.Id;
        so.Account__c = acc.Id;
        insert so;
        Test.stopTest();
    }
    
    @isTest static void testMethod1(){
        Sales_Order__c so = [SELECT Id,Case__c,Work_Order__c FROM Sales_Order__c LIMIT 1];
        Test.startTest();
        ReturnOrder ro = new ReturnOrder();
        ro.Sales_Order__c = so.Id;
        insert ro;
        
        ReturnOrder roCheck = [SELECT Id,CaseId FROM ReturnOrder WHERE Id =: ro.Id];
        System.assert(roCheck.CaseId != null);
        
        List<ProductRequest> prList = [SELECT Id FROM ProductRequest WHERE WorkOrderId=:so.Work_Order__c];
        System.assert(prList != null);
        
        ro.CaseId = null;
        update ro;
		ReturnOrder roCheck2 = [SELECT Id,CaseId FROM ReturnOrder WHERE Id =: ro.Id];
        System.assert(roCheck2.CaseId != null);        
        Test.stopTest();
    }
}