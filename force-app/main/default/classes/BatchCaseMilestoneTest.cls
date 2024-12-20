@isTest(SeeAllData=true)
public class BatchCaseMilestoneTest {
    @isTest static void testMethod1(){
        Account acc = TestDataFactory.createAccount();
        acc.Source_Key__c = '8665751293';
        insert acc;
        ServiceContract sc = TestDataFactory.createServiceContract(acc);
        insert sc;
        List<Case> csList = new List<Case>();
        Case cs = TestDataFactory.createCase(acc, sc);
        cs.Preferred_Time__c = System.now()-5;
        cs.Expected_SLA_Exit_Date__c = System.now()-5;
        cs.SLA_Violated__c = false;
        cs.SLA_Exception_Reason__c = null;
        cs.status = 'Part Shipped';
        cs.Description = 'Test Class Part Case';
        csList.add(cs);

        Case cs1 = TestDataFactory.createCase(acc, sc);
        cs1.Service_Type__c = 'Onsite Labor Only';
        cs1.Preferred_Time__c = System.now()-5;
        cs1.Expected_SLA_Exit_Date__c = System.now()-5;
        cs1.SLA_Violated__c = false;
        cs1.SLA_Exception_Reason__c = null;
        cs1.status = 'Tech Checked In';
        cs.Description = 'Test Class Onsite Case';
        csList.add(cs1);
        
        Test.startTest();
        insert csList;
        BatchCaseMilestones bmc = new BatchCaseMilestones();
        Database.executeBatch(bmc, 100);
        Case csCheck = [SELECT Id, SLA_Violated__c,Part_Shipment_SLA_Violated__c,Description FROM Case WHERE Id =: csList[0].Id];
        Case csCheck2 = [SELECT Id, SLA_Violated__c,Part_Shipment_SLA_Violated__c,Description FROM Case WHERE Id =: csList[1].Id];
        System.debug('csCheck-> ' + csCheck);
        System.debug('csCheck2-> ' + csCheck2);
        Test.stopTest();
        System.assert(csCheck.SLA_Violated__c == false);
        System.assert(csCheck.Part_Shipment_SLA_Violated__c == false);
        System.assert(csCheck2.SLA_Violated__c == false);
        System.assert(csCheck2.Part_Shipment_SLA_Violated__c == false);
    }
}