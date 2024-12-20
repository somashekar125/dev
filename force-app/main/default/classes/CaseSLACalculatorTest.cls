@isTest
public class CaseSLACalculatorTest {
    @isTest static void testMethod1(){
        List<Account> acList = new List<Account>();
        Account acc = TestDataFactory.createAccount();
        acc.Name = 'ALDI - 001';
        acList.add(acc);
        Account acc2 = TestDataFactory.createAccount();
        acc2.Name = 'ALDI - 002';
        acc2.Source_Key__c = '9853';
        acList.add(acc2);
        insert acList;
        List<BusinessHours> bhs=[SELECT Id FROM BusinessHours WHERE IsDefault = true];
        ServiceContract sc = TestDataFactory.createServiceContract(acc);
        insert sc;
        
        list<Case> caseList = new list<Case>();
        Case c = new Case();
        c.AccountId = acc.Id;
        c.Service_Type__c = 'Onsite IMAC';
        c.Preferred_Time__c = System.now().addHours(2);
        c.Priority = 'Severity 1';
        c.BusinessHoursId = bhs[0].Id;
        c.ServiceContractId = sc.Id;
        caseList.add(c);
        
        Case c2 = new Case();
        c2.AccountId = acc.Id;
        c2.Service_Type__c = 'Onsite IMAC';
        c2.Preferred_Time__c = DateTime.newInstance(2024, 02, 21, 09, 30, 2);
        c2.Priority = 'Severity 2';
        c2.BusinessHoursId = bhs[0].Id;
        c2.ServiceContractId = sc.Id;
        caseList.add(c2);
        
        Case c3 = new Case();
        c3.AccountId = acc.Id;
        c3.Preferred_Time__c = DateTime.newInstance(2024, 02, 21, 09, 30, 2);
        c2.Priority = 'Severity 3';
        c3.Service_Type__c = 'Advance Exchange + Onsite';
        c3.BusinessHoursId = bhs[0].Id;
        c3.ServiceContractId = sc.Id;
        caseList.add(c3);
        
        Case c4 = new Case();
        c4.AccountId = acc.Id;
        c4.Preferred_Time__c = DateTime.newInstance(2024, 02, 21, 09, 30, 2);
        c4.Service_Type__c = 'Advance Exchange + Onsite';
        c4.BusinessHoursId = bhs[0].Id;
        c4.ServiceContractId = sc.Id;
        caseList.add(c4);
        
        Case c5 = new Case();
        c5.AccountId = acc.Id;
        c5.Preferred_Time__c = DateTime.newInstance(2024, 02, 21, 09, 30, 2);
        c5.Service_Type__c = 'Advance Exchange (Depot Only)';
        c5.BusinessHoursId = bhs[0].Id;
        c5.ServiceContractId = sc.Id;
        caseList.add(c5);
        
        Case c6 = new Case();
        c6.AccountId = acc.Id;
        c6.Preferred_Time__c = DateTime.newInstance(2024, 02, 21, 09, 30, 2);
        c6.Service_Type__c = 'Advance Exchange (Depot Only)';
        c6.BusinessHoursId = bhs[0].Id;
        c6.ServiceContractId = sc.Id;
        caseList.add(c6);
        
        Case c7 = new Case();
        c7.priority = 'Severity 1';
        c7.AccountId = acc2.Id;
        c7.Preferred_Time__c = DateTime.newInstance(2024, 02, 21, 09, 30, 2);
        c7.Service_Type__c = 'Onsite Labor Only';
        c7.BusinessHoursId = bhs[0].Id;
        c7.ServiceContractId = sc.Id;
        caseList.add(c7);

        Case c8 = new Case();
        c8.priority = 'Severity 2';
        c8.AccountId = acc.Id;
        c8.Preferred_Time__c = DateTime.newInstance(2024, 02, 21, 09, 30, 2);
        c8.Service_Type__c = 'Onsite Labor Only';
        c8.BusinessHoursId = bhs[0].Id;
        c8.ServiceContractId = sc.Id;
        caseList.add(c8);
        
        Case c9 = new Case();
        c9.priority = 'Severity 2';
        c9.AccountId = acc2.Id;
        c9.Preferred_Time__c = DateTime.newInstance(2024, 02, 21, 09, 30, 2);
        c9.Service_Type__c = 'Onsite Labor Only';
        c9.BusinessHoursId = bhs[0].Id;
        c9.ServiceContractId = sc.Id;
        caseList.add(c9);
        
        Test.startTest();
        insert caseList;
        
        Case csCheck1 = [SELECT Id,Expected_SLA_Exit_Date__c FROM Case WHERE Id =: c.Id];
        Case csCheck2 = [SELECT Id,Expected_SLA_Exit_Date__c FROM Case WHERE Id =: c3.Id];
        Case csCheck3 = [SELECT Id,Expected_SLA_Exit_Date__c FROM Case WHERE Id =: c7.Id];
        Test.stopTest();
        System.assert(csCheck1.Expected_SLA_Exit_Date__c != null);
        System.assert(csCheck2.Expected_SLA_Exit_Date__c != null);
        System.assert(csCheck3.Expected_SLA_Exit_Date__c != null);
    }
}