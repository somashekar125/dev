@isTest
public class ASCENACaseMilestoneCalculaterTest {
    @testSetup static void setup() {
        Test.startTest();
        
        List<Account> acList = new List<Account>();
        Account acc = TestDataFactory.createAccount();
        acc.Timezone__c = 'EST';
        acc.ShippingState = 'NY';
        acList.add(acc);
        
        Account acc2 = TestDataFactory.createAccount();
        acc2.Name = 'SHOPPER - 001';
        acc2.Source_Key__c = '9853';
        acc2.Timezone__c = null;
        acc2.ShippingState = 'NY';
        acList.add(acc2);
        
        Account acc3 = TestDataFactory.createAccount();
        acc3.Name = 'CUB - 001';
        acc3.Source_Key__c = '985353';
        acc3.Timezone__c = 'EST';
        acc3.ShippingState = 'NY';
        acList.add(acc3);
        
        Account acc4 = TestDataFactory.createAccount();
        acc4.Name = '(JEI) - FLJSB';
        acc4.Source_Key__c = '5353';
        acc4.Timezone__c = 'CST';
        acc4.ShippingState = 'NH';
        acList.add(acc4);
        insert acList;
        
        List<BusinessHours> bhs = [SELECT Id FROM BusinessHours WHERE IsDefault = true];
        
        List<Entitlement> eList = new List<Entitlement>();
        eList.add(new Entitlement(Name = 'ASCENA Onsite Support', Type = 'Onsite IMAC', AccountId = acc.Id));
        eList.add(new Entitlement(Name = 'ASCENA Advance Exchange + Onsite', Type = 'Advance Exchange + Onsite', AccountId = acc.Id));
        eList.add(new Entitlement(Name = 'ASCENA Advance Exchange', Type = 'Advance Exchange (Depot Only)', AccountId = acc.Id));
        eList.add(new Entitlement(Name = 'ASCENA Onsite Labor Only', Type = 'Onsite Labor Only', AccountId = acc3.Id));
        insert eList;
        
        ServiceContract sc = TestDataFactory.createServiceContract(acc);
        insert sc;
        
        List<Case> caseList = new List<Case>();
        //PBS
        caseList.add(new Case(EntitlementId = eList[0].Id, AccountId = acc.Id, Service_Type__c = 'Onsite IMAC', Preferred_Time__c = DateTime.newInstance(2025,12,30,2,2,0), 
                    Priority = 'Severity 1', BusinessHoursId = bhs[0].Id, ServiceContractId = sc.Id, Description = 'PBS IMAC'));
        caseList.add(new Case(EntitlementId = eList[2].Id, AccountId = acc.Id, Service_Type__c = 'Advance Exchange + Onsite', Priority = 'Severity 2', 
                    BusinessHoursId = bhs[0].Id, ServiceContractId = sc.Id, Description = 'PBS Part + Onsite'));
        caseList.add(new Case(EntitlementId = eList[1].Id, AccountId = acc.Id, Priority = 'Severity 2', Service_Type__c = 'Advance Exchange (Depot Only)', 
                    BusinessHoursId = bhs[0].Id, ServiceContractId = sc.Id, Description = 'PBS Part Request'));
        caseList.add(new Case(EntitlementId = eList[3].Id, Priority = 'Severity 1', AccountId = acc.Id, Service_Type__c = 'Onsite Labor Only', 
                    BusinessHoursId = bhs[0].Id, ServiceContractId = sc.Id, Description = 'PBS Within Business Hours'));
        caseList.add(new Case(EntitlementId = eList[3].Id, Priority = 'Severity 1', AccountId = acc.Id, Service_Type__c = 'Onsite Labor Only', 
                    BusinessHoursId = bhs[0].Id, ServiceContractId = sc.Id, Description = 'PBS Not Within Business Hours'));
        caseList.add(new Case(EntitlementId = eList[3].Id, Priority = 'Severity 2', AccountId = acc.Id, Service_Type__c = 'Onsite Labor Only', 
                    BusinessHoursId = bhs[0].Id, ServiceContractId = sc.Id, Description = 'PBS Not Within Business Hours'));
        caseList.add(new Case(EntitlementId = eList[3].Id, Priority = 'Severity 2', AccountId = acc.Id, Service_Type__c = 'Onsite Labor Only', 
                    BusinessHoursId = bhs[0].Id, ServiceContractId = sc.Id, Description = 'PBS Before 3PM'));
        caseList.add(new Case(EntitlementId = eList[3].Id, Priority = 'Severity 2', AccountId = acc.Id, Service_Type__c = 'Onsite Labor Only', 
                    BusinessHoursId = bhs[0].Id, ServiceContractId = sc.Id, Description = 'PBS After 3PM'));
		//SHOPPER
        caseList.add(new Case(EntitlementId = eList[3].Id, Priority = 'Severity 1', AccountId = acc2.Id, Service_Type__c = 'Onsite Labor Only', 
                    BusinessHoursId = bhs[0].Id, ServiceContractId = sc.Id, Description = 'SHOPPER MissingTimezone'));
		//CUB
        caseList.add(new Case(EntitlementId = eList[3].Id, Priority = 'Severity 2', AccountId = acc3.Id, Service_Type__c = 'Onsite Labor Only', 
                    BusinessHoursId = bhs[0].Id, ServiceContractId = sc.Id, Description = 'CUB Before 8AM'));
        caseList.add(new Case(EntitlementId = eList[3].Id, Priority = 'Severity 2', AccountId = acc3.Id, Service_Type__c = 'Onsite Labor Only', 
                    BusinessHoursId = bhs[0].Id, ServiceContractId = sc.Id, Description = 'CUB Between 8AM - 2PM'));
        caseList.add(new Case(EntitlementId = eList[3].Id, Priority = 'Severity 2', AccountId = acc3.Id, Service_Type__c = 'Onsite Labor Only', 
                    BusinessHoursId = bhs[0].Id, ServiceContractId = sc.Id, Description = 'CUB After 2PM'));
        caseList.add(new Case(EntitlementId = eList[3].Id, Priority = 'Severity 3', AccountId = acc3.Id, Service_Type__c = 'Onsite Labor Only', 
                    BusinessHoursId = bhs[0].Id, ServiceContractId = sc.Id, Description = 'CUB Before 8AM'));
        caseList.add(new Case(EntitlementId = eList[3].Id, Priority = 'Severity 3', AccountId = acc3.Id, Service_Type__c = 'Onsite Labor Only', 
                    BusinessHoursId = bhs[0].Id, ServiceContractId = sc.Id, Description = 'CUB Between 8AM - 2PM'));
        caseList.add(new Case(EntitlementId = eList[3].Id, Priority = 'Severity 3', AccountId = acc3.Id, Service_Type__c = 'Onsite Labor Only', 
                    BusinessHoursId = bhs[0].Id, ServiceContractId = sc.Id, Description = 'CUB After 2PM'));
		//PBS
        caseList.add(new Case(EntitlementId = eList[0].Id, AccountId = acc.Id, Service_Type__c = 'Onsite IMAC', Preferred_Time__c = DateTime.newInstance(2025,12,30,2,2,0),
                    Priority = 'Severity 2', BusinessHoursId = bhs[0].Id, ServiceContractId = sc.Id, Description = 'PBS IMAC 001'));
        caseList.add(new Case(EntitlementId = eList[0].Id, AccountId = acc.Id, Service_Type__c = 'Onsite IMAC', Preferred_Time__c = null, Priority = 'Severity 2', 
                    BusinessHoursId = bhs[0].Id, ServiceContractId = sc.Id, Description = 'PBS IMAC 002'));
        caseList.add(new Case(EntitlementId = eList[1].Id, AccountId = acc.Id, Priority = 'Severity 2', Service_Type__c = 'Advance Exchange (Depot Only)', 
                    BusinessHoursId = bhs[0].Id, ServiceContractId = sc.Id, Description = 'PBS Part Request 03'));
        caseList.add(new Case(EntitlementId = eList[1].Id, AccountId = acc.Id, Priority = 'Severity 2', Service_Type__c = 'Advance Exchange (Depot Only)', 
                    BusinessHoursId = bhs[0].Id, ServiceContractId = sc.Id, Description = 'PBS Part Request 03'));
        //Jerry
        caseList.add(new Case(EntitlementId = eList[3].Id, Priority = 'Severity 1', AccountId = acc4.Id, Service_Type__c = 'Onsite Labor Only', 
                    BusinessHoursId = bhs[0].Id, ServiceContractId = sc.Id, Description = 'Jerry Sev1 Between 8AM - 12PM'));
        caseList.add(new Case(EntitlementId = eList[3].Id, Priority = 'Severity 1', AccountId = acc4.Id, Service_Type__c = 'Onsite Labor Only', 
                    BusinessHoursId = bhs[0].Id, ServiceContractId = sc.Id, Description = ' Sev1 After 12PM'));
        caseList.add(new Case(EntitlementId = eList[3].Id, Priority = 'Severity 2', AccountId = acc4.Id, Service_Type__c = 'Onsite Labor Only', 
                    BusinessHoursId = bhs[0].Id, ServiceContractId = sc.Id, Description = 'Jerry Sev2 Between 8AM - 2PM'));
        caseList.add(new Case(EntitlementId = eList[3].Id, Priority = 'Severity 2', AccountId = acc4.Id, Service_Type__c = 'Onsite Labor Only', 
                    BusinessHoursId = bhs[0].Id, ServiceContractId = sc.Id, Description = 'Jerry Sev2 After 2PM'));
        insert caseList;
        
        Test.stopTest();
    }
    
    @isTest static void testMethod1(){
        List<Case> csList = [SELECT Id,Description,Account_Name_For_Search__c,EntitlementId,Preferred_Time__c,
                             CreatedDate,priority,AccountId,Service_Type__c,BusinessHoursId,ServiceContractId,
                             Expected_SLA_Exit_Date__c,Part_Receipt_Due_DateTime__c,SLA_Calculation_Log__c FROM Case];
        list<MilestoneType> mtList = [SELECT Id, Name, RecurrenceType FROM MilestoneType LIMIT 3];
        
        System.runAs(new User(Id = UserInfo.getUserId())) {
            //PBS
            Test.setCreatedDate(csList[1].Id, DateTime.newInstance(2024, 6, 13, 18, 8, 16)); 
            Test.setCreatedDate(csList[2].Id, DateTime.newInstance(2024, 6, 13, 18, 8, 16));
            Test.setCreatedDate(csList[3].Id, DateTime.newInstance(2024, 6, 13, 10, 8, 16));
            Test.setCreatedDate(csList[4].Id, DateTime.newInstance(2024, 6, 13, 18, 8, 16));
            Test.setCreatedDate(csList[5].Id, DateTime.newInstance(2024, 6, 13, 6, 8, 16));
            Test.setCreatedDate(csList[6].Id, DateTime.newInstance(2024, 6, 13, 10, 8, 16));
            Test.setCreatedDate(csList[7].Id, DateTime.newInstance(2024, 6, 13, 18, 8, 16));
            
            //SHOPPER
            Test.setCreatedDate(csList[8].Id, DateTime.newInstance(2024, 6, 13, 6, 0, 0));
            //CUB
            Test.setCreatedDate(csList[9].Id, DateTime.newInstance(2024, 6, 13, 10, 0, 0));
            Test.setCreatedDate(csList[10].Id, DateTime.newInstance(2024, 6, 13, 15, 0, 0));
            Test.setCreatedDate(csList[11].Id, DateTime.newInstance(2024, 6, 13, 6, 0, 0));
            Test.setCreatedDate(csList[12].Id, DateTime.newInstance(2024, 6, 13, 10, 0, 0));
            Test.setCreatedDate(csList[13].Id, dateTime.newInstance(2024, 6, 13, 15, 0, 0));
            
            //PBS
            Test.setCreatedDate(csList[16].Id, DateTime.newInstance(2024, 6, 13, 9, 0, 0));
            Test.setCreatedDate(csList[17].Id, DateTime.newInstance(2024, 6, 13, 15, 0, 0));
            Test.setCreatedDate(csList[18].Id, DateTime.newInstance(2024, 6, 13, 9, 0, 0));
            
            //For Jerry
            Test.setCreatedDate(csList[19].Id, DateTime.newInstance(2024, 6, 13, 9, 0, 0));
            Test.setCreatedDate(csList[20].Id, DateTime.newInstance(2024, 6, 13, 15, 0, 0));
            Test.setCreatedDate(csList[21].Id, DateTime.newInstance(2024, 6, 13, 9, 0, 0));
            Test.setCreatedDate(csList[21].Id, DateTime.newInstance(2024, 6, 13, 15, 0, 0));
        }
        Test.startTest();
        
        ASCENACaseMilestoneCalculater ascMil = new ASCENACaseMilestoneCalculater();
        Integer triggerMinutes1;
        Integer triggerMinutes2;
        Integer triggerMinutes3;
        Integer triggerMinutes4;
        Integer triggerMinutes5;
        Integer triggerMinutes6;
        Integer triggerMinutes7;
        Integer triggerMinutes8;
        for(MilestoneType mt : mtList) {
            triggerMinutes1 = ascMil.calculateMilestoneTriggerTime(csList[0].Id, mt.Id);
            triggerMinutes2 = ascMil.calculateMilestoneTriggerTime(csList[1].Id, mt.Id);
            triggerMinutes3 = ascMil.calculateMilestoneTriggerTime(csList[2].Id, mt.Id);
            triggerMinutes4 = ascMil.calculateMilestoneTriggerTime(csList[3].Id, mt.Id);
            triggerMinutes5 = ascMil.calculateMilestoneTriggerTime(csList[4].Id, mt.Id);
            triggerMinutes6 = ascMil.calculateMilestoneTriggerTime(csList[5].Id, mt.Id);
            triggerMinutes7 = ascMil.calculateMilestoneTriggerTime(csList[6].Id, mt.Id);
            triggerMinutes8 = ascMil.calculateMilestoneTriggerTime(csList[15].Id, mt.Id);
        }
        System.assert(triggerMinutes1 != 1 && triggerMinutes1 != 0);
        System.assert(triggerMinutes2 != 1 && triggerMinutes2 != 0);
        System.assert(triggerMinutes3 != 1 && triggerMinutes3 != 0);
        System.assert(triggerMinutes4 != 1 && triggerMinutes4 != 0);
        System.assert(triggerMinutes5 != 1 && triggerMinutes5 != 0);
        System.assert(triggerMinutes6 != 1 && triggerMinutes6 != 0);
        System.assert(triggerMinutes7 != 1 && triggerMinutes7 != 0);
        System.assert(triggerMinutes8 != 1 && triggerMinutes8 != 0);
        
        Map<Id,Case> cMap = new Map<Id,Case>(csList);
        ASCENACaseMilestoneCalculater.assignSALEndDatetime(cMap.values());        
        for(case c : cMap.values()){
            if(c.Service_Type__c == 'Advance Exchange (Depot Only)'){
                System.assert(c.Part_Receipt_Due_DateTime__c != null);
            } else if(c.Service_Type__c == 'Advance Exchange + Onsite') {
                System.assert(c.Part_Receipt_Due_DateTime__c != null);
                System.assert(c.Expected_SLA_Exit_Date__c != null);
            } else {
                System.assert(c.Expected_SLA_Exit_Date__c != null);
            }
        }
        Test.stopTest();
    }
}