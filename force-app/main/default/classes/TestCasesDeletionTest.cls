@isTest
public class TestCasesDeletionTest {
    @isTest Static void testMethod1(){
        Global_Settings__c gs = TestDataFactory.CreateGlobalSettings();
        insert gs;
        Account acc = TestDataFactory.createAccount();
        insert acc;
        ServiceContract sc = TestDataFactory.createServiceContract(acc);
        insert sc;
        Case cs = TestDataFactory.createCase(acc, sc);
        cs.Incident__c = 'TEST';
        insert cs;
        WorkOrder wo = TestDataFactory.createWorkOrder(cs, sc,acc);
        insert wo;
        
        Test.startTest();
        SchedulableContext sch = null;
        TestCasesDeletion tcd = new TestCasesDeletion();
        tcd.execute(sch);
        ServiceContract scCheck = [SELECT Id,(SELECT Id FROM Cases) FROM ServiceContract WHERE Id =: sc.Id];
        System.assert(scCheck.Cases.isEmpty());
        Test.stopTest();
        
    }
}