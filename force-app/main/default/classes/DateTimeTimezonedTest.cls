@isTest
public class DateTimeTimezonedTest {
    @testSetup static void setup() {
        Test.startTest();
        Account acc = TestDataFactory.createAccount();
        acc.Timezone__c = 'CST';
        insert acc;
        ServiceContract sc = TestDataFactory.createServiceContract(acc);
        insert sc;
        Test.stopTest();
    }
    
    @isTest static void testMehtod1(){
        Account acc = [SELECT Id FROM Account WHERE Name = 'test account' LIMIT 1];
        ServiceContract sc = [SELECT Id FROM ServiceContract WHERE Name = 'test ServiceContract' LIMIT 1];
		Case cs = TestDataFactory.createCase(acc, sc);
        cs.Expected_SLA_Exit_Date__c = System.now();
        cs.Part_Receipt_Due_DateTime__c = System.now();
        cs.Preferred_Time__c = System.now();
        cs.Technician_OnSite_ETA__c = System.now();
        insert cs;
        
        WorkOrder wo = TestDataFactory.createWorkOrder(cs, sc, acc);
        wo.SLA_Due_DateTime__c = System.now().addDays(1);
        wo.Time_Entries__c = '2023-02-06 00:00:00 - 2023-02-06 00:15:00 (00:15)';
        wo.Check_In_Time__c = System.now();
        wo.Check_Out_Time__c = System.now().addDays(1);
        wo.Technician_OnSite_ETA__c = System.now();
        wo.Preferred_Time_IMAC__c = System.now();
        insert wo;
        
        Test.startTest();
        Case csCheck = DateTimeTimezoned.getCaseRec(String.valueOf(cs.Id));
        DateTimeTimezoned.CorrectingDateTimesWrapper cdt = DateTimeTimezoned.correctingDateTimes(cs,false);
        DateTimeTimezoned.CorrectingDateTimesWrapper cdt2 = DateTimeTimezoned.correctingDateTimes(cs,true);
        
        WorkOrder woCheck = DateTimeTimezonedWO.getWORec(String.valueOf(wo.Id));
        DateTimeTimezonedWO.CorrectingDateTimesWrapper cdt3 = DateTimeTimezonedWO.correctingDateTimes(wo,false);
        DateTimeTimezonedWO.CorrectingDateTimesWrapper cdt4 = DateTimeTimezonedWO.correctingDateTimes(wo,true);
        List<String> timeEntryList = DateTimeTimezonedWO.getTimeEntries(wo);
        System.assert(csCheck != null);
        System.assert(woCheck != null);
        System.assert(timeEntryList != null);
        
        System.assert(cdt4.SLADateTimeValue != null);
        System.assert(cdt4.CheckInDateTimeValue != null);
        System.assert(cdt4.CheckOutDateTimeValue != null);
        System.assert(cdt4.TechDateTimeValue != null);
        System.assert(cdt4.PrefDateTimeValue != null);
        
        System.assert(cdt4.SLAdateStr != null);
        System.assert(cdt4.CheckIndateStr != null);
        System.assert(cdt4.CheckOutdateStr != null);
        System.assert(cdt4.TechdateStr != null);
        System.assert(cdt4.PrefdateStr != null);
        Test.stopTest();
    }
}