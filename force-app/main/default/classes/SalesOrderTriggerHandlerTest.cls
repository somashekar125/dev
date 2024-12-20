@isTest
public class SalesOrderTriggerHandlerTest {
    @testSetup static void setup() {
        Test.startTest();
        Global_Settings__c gs = TestDataFactory.CreateGlobalSettings();
        insert gs;

        Account acc = new Account(Name = 'test',Source_Key__c='24435');
        insert acc;
        
        ServiceContract sc = TestDataFactory.createServiceContract(acc);
        sc.Service_Type__c = 'Onsite IMAC';
        insert sc;
        
        Case cs = TestDataFactory.createCase(acc, sc);
        cs.Service_Type__c = 'Onsite IMAC';
        insert cs;
        
        WorkOrder wo = new WorkOrder();
        wo.Status = 'Technician Scheduled / Assigned';
        wo.CaseId = cs.Id;
        insert wo;
        
        ServiceAppointment sa = TestDataFactory.createServiceAppointment(wo);
        insert sa;
        Test.stopTest();
    }
    
    @isTest static void testMethod1(){
        Test.startTest();
        Case cs = [SELECT Id FROM Case LIMIT 1];
        WorkOrder wo = [SELECT Id FROM WorkOrder WHERE CaseId =: cs.Id LIMIT 1];
        
        Sales_Order__c so = new Sales_Order__c();
        so.Order_Status__c = 'Closed';
        so.Work_Order__c = wo.Id;
        so.Outbound_Tracking_Numbers__c = '111 222';
        insert so;
        
		Sales_Order__c saleOrd = [SELECT Id, Order_Status__c, Outbound_Tracking_Numbers__c, Case__c FROM Sales_Order__c WHERE Id=: so.Id];
        System.assert(saleOrd.Order_Status__c == 'Closed');
        System.assert(saleOrd.Outbound_Tracking_Numbers__c == '111,222');
        System.assert(saleOrd.Case__c == cs.Id);
        
        so.Outbound_Tracking_Numbers__c = '111 222 333';
        update so;
        
        Sales_Order__c saleOrd2 = [SELECT Id, Outbound_Tracking_Numbers__c FROM Sales_Order__c WHERE Id=: so.Id];
        System.assert(saleOrd2.Outbound_Tracking_Numbers__c == '111,222,333');
        
        Test.stopTest();
    }
}