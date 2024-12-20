@isTest
public class ServiceAppointmentTriggerHandlerTest {
    @IsTest static void testMethod1(){
        Test.startTest();
        Global_Settings__c gs = TestDataFactory.CreateGlobalSettings();
        insert gs;
        Account rootAcc = TestDataFactory.createAccount();
        rootAcc.Name = 'CUB Foods';
        insert rootAcc;

        Product2 stagProd = TestDataFactory.createProduct2(rootAcc);
        stagProd.Name = 'Test Verifone E355 3-Unit Gang Charger';
        insert stagProd;
        rootAcc.Staging_Product__c = stagProd.Id;
        update rootAcc;
        
        Account acc = TestDataFactory.createAccount();
        acc.Root_Account__c = rootAcc.Id;
        acc.Source_Key__c = '1265865';
        acc.Name = 'CUB 001';
        insert acc;
        
        ServiceContract sc = TestDataFactory.createServiceContract(acc);
        sc.Work_Order_Record_Type__c = 'Onsite Labor';
        insert sc;
        Case cs = TestDataFactory.createCase(acc,sc);
        cs.Service_Type__c = 'Onsite Labor Only';
        cs.Expected_SLA_Exit_Date__c = System.now().addHours(1);
        insert cs;
        WorkOrder wo = TestDataFactory.createWorkOrder(cs, sc, acc);
        wo.Service_Type__c = cs.Service_Type__c;
        wo.RecordTypeId = System.Label.Onsite_Labor_WO_RT_Id;
        wo.OwnerId = UserInfo.getUserId();
        insert wo;
        ServiceResource sr = new ServiceResource();
        sr.Name = 'Field Tech 1';
        sr.IsActive = true;
        sr.ResourceType = 'T';
        sr.RelatedRecordId = UserInfo.getUserId();
        insert sr;
        
        ServiceAppointment sa = new ServiceAppointment();
        sa.ParentRecordId = wo.Id;
        sa.EarliestStartTime = System.now().addHours(1);
        sa.DueDate = System.now().addHours(2);
        sa.SchedStartTime = System.now().addHours(1);
        sa.SchedEndTime = System.now().addHours(2);
        insert sa;
        
        Test.stopTest();
    }
}