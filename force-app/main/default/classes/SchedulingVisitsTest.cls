@isTest
public class SchedulingVisitsTest {

    @testSetup static void setup() {
        Global_Settings__c gs = TestDataFactory.CreateGlobalSettings();
        insert gs;

        Account rootAcc = TestDataFactory.createAccount();
        rootAcc.Name = 'Aldi Inc.';
        insert rootAcc;

        Account acc = TestDataFactory.createAccount();
        acc.Name = 'Test Account';
        acc.Source_Key__c = '23456789';
        acc.Root_Account__c = rootAcc.Id;
        insert acc;
        
        Account acc1 = TestDataFactory.createAccount();
        acc1.Name = 'Test Account1';
        acc1.Source_Key__c = '234567891';
        acc1.Root_Account__c = rootAcc.Id;
        insert acc1;
        
        Account acc2 = TestDataFactory.createAccount();
        acc2.Name = 'Test Account2';
        acc2.Source_Key__c = '234567892';
        acc2.Root_Account__c = rootAcc.Id;
        insert acc2;

        Project__c pro = new Project__c();
        pro.Name = 'Test Project';
        pro.Client__c = acc.Id;
        pro.Applicable_on_Days__c = 'Monday;Tuesday;Wednesday;Thursday;Friday';
        pro.Number_of_visits__c = 3;
        pro.Visit_Offset__c = 1;
        Datetime dt = Datetime.now();
        pro.Start_Time__c = dt.time();
        insert pro;

        Project_Account__c prjAcc = new Project_Account__c();
        prjAcc.Name = 'Test PA 1';
        prjAcc.Account__c = acc.Id;
        prjAcc.Project__c = pro.Id;
        prjAcc.Visit_1__c = Datetime.now().addDays(2);
        insert prjAcc;
        
        Project_Account__c prjAcc1 = new Project_Account__c();
        prjAcc1.Name = 'Test PA 2';
        prjAcc1.Account__c = acc1.Id;
        prjAcc1.Project__c = pro.Id;
        prjAcc1.Visit_2__c = Datetime.now().addDays(2);
        insert prjAcc1;

        Project_Account__c prjAcc2 = new Project_Account__c();
        prjAcc2.Name = 'Test PA 3';
        prjAcc2.Account__c = acc2.Id;
        prjAcc2.Project__c = pro.Id;
        prjAcc2.Visit_3__c = Datetime.now().addDays(3);
        insert prjAcc2;

        Test.startTest();
        ApexPages.StandardSetController controller = new ApexPages.StandardSetController(new List<Project_Account__c>{prjAcc,prjAcc1, prjAcc2});
        SchedulingVisits schedulingVisits = new SchedulingVisits(controller);
        
        Test.setCurrentPageReference(new PageReference('/apex/schedulingPage'));
        ApexPages.currentPage().getParameters().put('buttonName', 'Start Visit');
        ApexPages.currentPage().getParameters().put('selectedIds', String.join(new List<Id>{prjAcc1.Id, prjAcc2.Id}, ','));

        schedulingVisits.init();
        Test.stopTest();
    }

    @isTest
    static void testGetUserTimezone() {
        Test.startTest();
        String timezone = SchedulingVisits.getUserTimezone();
        System.assertNotEquals(null, timezone);
        Test.stopTest();
    }

    @isTest
    static void testGetProjectRecord() {
        Account acc = [SELECT Id,Name FROM Account WHERE Name LIKE '%Test%' LIMIT 1];
        Project__c project = new Project__c(Name = 'Test Project',Client__c = acc.Id, Applicable_on_Days__c = 'Monday;Tuesday;Wednesday;Thursday;Friday', Visit_Offset__c = 2, Start_Time__c = Time.newInstance(12, 30, 0, 0));
        insert project;

        Test.startTest();
        Project__c fetchedProject = SchedulingVisits.getProjectRecord(project.Id);
        System.assertNotEquals(null, fetchedProject);
        System.assertEquals('Test Project', fetchedProject.Name);
        Test.stopTest();
    }

    @isTest
    static void testGetSelectedList() {
        Account acc = [SELECT Id,Name FROM Account WHERE Name LIKE '%Test%' LIMIT 1];
        Project__c project = new Project__c(Name = 'Test Project',Client__c = acc.Id, Applicable_on_Days__c = 'Monday;Tuesday;Wednesday;Thursday;Friday', Visit_Offset__c = 2, Start_Time__c = Time.newInstance(12, 30, 0, 0));
        insert project;

        Project_Account__c prjAcc1 = new Project_Account__c();
        prjAcc1.Name = 'Test PA 1';
        prjAcc1.Project__c = project.Id;
        insert prjAcc1;

        Project_Account__c prjAcc2 = new Project_Account__c();
        prjAcc2.Name = 'Test PA 2';
        prjAcc2.Project__c = project.Id;
        insert prjAcc2;

        Test.startTest();
        List<Project_Account__c> result = SchedulingVisits.getSelectedList(new List<Id>{prjAcc1.Id}, project.Id, 'VISIT 1', 'ORDER BY Account__r.Name');
        System.assertEquals(1, result.size());
        System.assertEquals('Test PA 1', result[0].Name);
        Test.stopTest();
    }

    @isTest
    static void testSchedulingVisit() {
        Account acc = [SELECT Id,Name FROM Account WHERE Name LIKE '%Test%' LIMIT 1];
        Project__c project = new Project__c(Name = 'Test Project',Client__c = acc.Id, Applicable_on_Days__c = 'Monday;Tuesday;Wednesday;Thursday;Friday', Visit_Offset__c = 1,Start_Time__c = Time.newInstance(12, 30, 0, 0));
        insert project;

        Project_Account__c prjAcc = new Project_Account__c();
        prjAcc.Name = 'Test PA 1';
        prjAcc.Project__c = project.Id;
        insert prjAcc;

        Test.startTest();
        String newVisitJson = JSON.serialize(new List<Project_Account__c>{prjAcc});
        SchedulingVisits.SchedulingVisit(newVisitJson, null, 'VISIT 1');

        Project_Account__c updatedPA = [SELECT Visit_1__c FROM Project_Account__c WHERE Id = :prjAcc.Id];
        Test.stopTest();
    }

    @isTest
    static void testSchedulingVisitForVisit1() {
        Account acc = [SELECT Id,Name FROM Account WHERE Name LIKE '%Test%' LIMIT 1];
        Project__c project = new Project__c(Name = 'Test Project',Client__c = acc.Id, Applicable_on_Days__c = 'Monday;Tuesday;Wednesday;Thursday;Friday', Visit_Offset__c = 1, Start_Time__c = Time.newInstance(12, 30, 0, 0));
        insert project;

        Test.startTest();
        Project__c project1 = [SELECT Id FROM Project__c LIMIT 1];
        Project_Account__c projAcc = [SELECT Id, Visit_1__c FROM Project_Account__c WHERE Project__c = :project1.Id AND Name = 'Test PA 1'];

        String newVisitJson2 = JSON.serialize(new List<Project_Account__c>{projAcc});
        SchedulingVisits.SchedulingVisit(newVisitJson2, null, 'VISIT 1');

        Project_Account__c updatedPA1 = [SELECT Visit_1__c FROM Project_Account__c WHERE Id = :projAcc.Id];
        Test.stopTest();
    }

    @isTest
    static void testSchedulingVisitForVisit2() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        Project_Account__c projAcc = [SELECT Id, Visit_2__c FROM Project_Account__c WHERE Project__c = :project.Id AND Name = 'Test PA 2' LIMIT 1];

        Test.startTest();
        String newVisitJson = JSON.serialize(new List<Project_Account__c>{projAcc});
        SchedulingVisits.SchedulingVisit(newVisitJson, null, 'VISIT 2');

        Project_Account__c updatedPA = [SELECT Visit_2__c FROM Project_Account__c WHERE Id = :projAcc.Id];
        Test.stopTest();
    }

    @isTest
    static void testSchedulingVisitForVisit3() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        Project_Account__c projAcc = [SELECT Id, Visit_3__c FROM Project_Account__c WHERE Project__c = :project.Id  AND Name = 'Test PA 3' LIMIT 1];

        Test.startTest();
        String newVisitJson = JSON.serialize(new List<Project_Account__c>{projAcc});
        SchedulingVisits.SchedulingVisit(newVisitJson, null, 'VISIT 3');

        Project_Account__c updatedPA = [SELECT Visit_3__c FROM Project_Account__c WHERE Id = :projAcc.Id];
        Test.stopTest();
    }

    @isTest
    static void testTimeZoneConversionOnload() {
        Account acc = [SELECT Id,Name FROM Account WHERE Name LIKE '%Test%' LIMIT 1];
        Project__c project = new Project__c(Name = 'Test Project', Client__c = acc.Id, Applicable_on_Days__c = 'Monday;Tuesday;Wednesday;Thursday;Friday', Visit_Offset__c = 1, Start_Time__c = Time.newInstance(12, 30, 0, 0));
        insert project;
        
        List<Account> accList = [SELECT Id, Name, Root_Account__c FROM Account];

        Project_Account__c prjAcc = new Project_Account__c();
        prjAcc.Name = 'Test PA 1';
        prjAcc.Project__c = project.Id;
        prjAcc.Account__c = accList[0].Id;
        prjAcc.Visit_1__c = Datetime.now();
        insert prjAcc;

        Test.startTest();
        List<Project_Account__c> paList = [SELECT Id, Name,Start_Time__c,Project__c,Account__c,Visit_1__c,Visit_2__c,Visit_3__c,Project__r.Visit_Offset__c,Project__r.Number_of_visits__c,Project__r.Applicable_on_Days__c,Project__r.Start_Time__c FROM Project_Account__c WHERE Project__c = :project.Id];

        List<Project_Account__c> convertedList = SchedulingVisits.timeZoneConversionOnload(new List<Project_Account__c>{prjAcc}, 'VISIT 1', true);
        System.assertNotEquals(null, convertedList);
        System.assertEquals(1, convertedList.size());
        Test.stopTest();
    }

    @isTest
    static void testPopulateVisitsOnLoad() {
        List<Project__c> project1 = [SELECT Id,Start_Time__c,Name,Visit_Offset__c,Number_of_visits__c,Client__c,Applicable_on_Days__c FROM Project__c WHERE Name = 'Test Project' LIMIT 1];


        Project_Account__c projectAccount = new Project_Account__c(Project__c = project1[0].Id, Name = 'Test PA', Visit_1__c = Datetime.now());
        insert projectAccount;
        List<Project_Account__c> paList = [SELECT Id, Name,Start_Time__c,Project__c,Visit_1__c,Visit_2__c,Visit_3__c,Project__r.Visit_Offset__c,Project__r.Number_of_visits__c,Project__r.Applicable_on_Days__c,Project__r.Start_Time__c FROM Project_Account__c WHERE Project__c = :project1[0].Id];


        Test.startTest();
        List<Project_Account__c> result = SchedulingVisits.populateVisitsOnLoad(paList, 'VISIT 2');
        System.assertNotEquals(null, result);
        Test.stopTest();
    }

    @isTest
    static void testPopulateVisitsOnLoadForVisit3() {
        List<Project__c> project2 = [SELECT Id,Name,Visit_Offset__c,Start_Time__c,Number_of_visits__c,Client__c,Applicable_on_Days__c FROM Project__c WHERE Name = 'Test Project' LIMIT 1];

        List<Project_Account__c> paList = [SELECT Id, Name,Start_Time__c,Project__c,Visit_1__c,Visit_2__c,Visit_3__c,Project__r.Visit_Offset__c,Project__r.Number_of_visits__c,Project__r.Applicable_on_Days__c,Project__r.Start_Time__c FROM Project_Account__c WHERE Project__c = :project2[0].Id];
        
        Test.startTest();
        List<Project_Account__c> result = SchedulingVisits.populateVisitsOnLoad(paList, 'VISIT 3');
	    System.assertNotEquals(null, result);
        Test.stopTest();
    }
    
     @isTest
    static void testTimeZoneConversion() {
       	User currUser = [SELECT Id, TimeZoneSidKey FROM User WHERE Id = :UserInfo.getUserId()];
        String timezoneId = 'America/New_York';
        Datetime visit = Datetime.newInstance(2024, 7, 15, 12, 0, 0);
        
        Test.startTest();
        Datetime convertedTimeComponentTrue = SchedulingVisits.timeZoneConversionFromVisit(visit, timezoneId, currUser, true);
        Test.stopTest();
    }
    
    @isTest
    static void testTimeZoneEdgeCases() {
        User currUser = [SELECT Id, TimeZoneSidKey FROM User WHERE Id = :UserInfo.getUserId()];
        String timezoneId = 'America/Los_Angeles';
        Datetime visit = Datetime.newInstance(2024, 7, 15, 0, 0, 0);
        
         Test.startTest();
        Datetime convertedTime = SchedulingVisits.timeZoneConversionFromVisit(visit, timezoneId, currUser, true);
        Test.stopTest();
    }
}