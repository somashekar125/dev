@isTest
public class SchedulingMapTest {
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
        prjAcc.Visit_1__c = Datetime.newInstance(2024, 7, 16, 08, 06, 0);
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

    }
    
    @isTest
    static void testGetUserTimezone() {
        String timezone = SchedulingMap.getUserTimezone();
        System.assert(!String.isBlank(timezone));
    }
    
    @isTest
    static void testGetProjAccts() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = 'Test Project' LIMIT 1];
        Map<String, Object> result = SchedulingMap.getProjAccts(project.Id, '2024-07-16', true, 0);
   
    }
    
    @isTest
    static void testScheduleVisit1() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = 'Test Project' LIMIT 1];
        Account acc = [SELECT Id,Name FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        SchedulingMap.scheduleVisit(acc.Id, project.Id, '2024-07-16 08:06');
        
        Project_Account__c projAcc = [SELECT Visit_1__c FROM Project_Account__c WHERE Account__c = :acc.Id AND Project__c = :project.Id LIMIT 1];
        System.assertNotEquals(null, projAcc.Visit_1__c, 'Visit_1__c should be updated');
    }
    
    @isTest
    static void testScheduleVisit2() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = 'Test Project' LIMIT 1];
        Account acc = [SELECT Id,Name FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        SchedulingMap.scheduleVisit(acc.Id, project.Id,'2024-07-16 08:06');
        
        Project_Account__c projAcc = [SELECT Visit_2__c FROM Project_Account__c WHERE Account__c = :acc.Id AND Project__c = :project.Id LIMIT 1];
        System.assertNotEquals(null, projAcc.Visit_2__c, 'Visit_2__c should be updated');
    }
    
    @isTest
    static void testScheduleVisit3() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = 'Test Project' LIMIT 1];
        Account acc = [SELECT Id,Name FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        SchedulingMap.scheduleVisit(acc.Id, project.Id,'2024-07-16 08:06');
        
        Project_Account__c projAcc = [SELECT Visit_3__c FROM Project_Account__c WHERE Account__c = :acc.Id AND Project__c = :project.Id LIMIT 1];
    }
    
    @isTest
    static void testGetVisitData() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = 'Test Project' LIMIT 1];
        Map<String, Map<String, Integer>> result = SchedulingMap.getVisitData('2024-07-16', project.Id, 1);
        System.assertNotEquals(null, result, 'Result should not be null');
    } 
    
    @isTest
    static void testGetAccountData() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = 'Test Project' LIMIT 1];
        Map<String, Integer> result = SchedulingMap.getAccountData('2024-07-16', project.Id, 1);
        System.assertNotEquals(null, result, 'Result should not be null');
    }
    
     @isTest
    static void testGetProjAccVisitsData() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = 'Test Project' LIMIT 1];
        List<Project_Account__c> result = SchedulingMap.getProjAccVisitsData('2024-07-16', project.Id, 1);
        System.assertNotEquals(null, result, 'Result should not be null');
    }
    
    @isTest
    static void testGetProjectaccounts() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = 'Test Project' LIMIT 1];
        List<Project_Account__c> result = SchedulingMap.getProjAccforDownload(project.Id);
        System.assertNotEquals(null, result, 'Result should not be null');
    }
    
    @isTest
    static void testUpdateProjectAccounts() {
        Project_Account__c projAcc1 = [SELECT Id, Visit_1__c FROM Project_Account__c WHERE Account__r.Name = 'Test Account' LIMIT 1];
        
        // Setup data for the update
        Map<Id, List<String>> data = new Map<Id, List<String>>();
        data.put(projAcc1.Id, new List<String>{'Visit_1__c'});
        
        List<Project_Account__c> originalList = new List<Project_Account__c>{projAcc1};
        List<Project_Account__c> updatedList = new List<Project_Account__c>{projAcc1};
        
        SchedulingMap.updateProjectAccounts(JSON.serialize(originalList), JSON.serialize(updatedList), data);
        
        Project_Account__c updatedProjAcc = [SELECT Visit_1__c FROM Project_Account__c WHERE Id = :projAcc1.Id LIMIT 1];
        System.assertNotEquals(projAcc1.Visit_1__c, updatedProjAcc.Visit_1__c, 'Visit_1__c should be updated');
    }
    
    @isTest
    static void testConvertToUserTimezone() {
        Datetime localDateTime = Datetime.newInstance(2023, 7, 10, 10, 0, 0);
        Datetime userDateTime = SchedulingMap.convertToUserTimezone(localDateTime);
        
        // Assuming the user timezone conversion should yield a different time
        System.assertNotEquals(localDateTime, userDateTime, 'User date time should not equal local date time');
    }
    
    @isTest
    static void testGetProject() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = 'Test Project' LIMIT 1];
        Project__c fetchedProject = SchedulingMap.getProject(project.Id);
        System.assertEquals(project.Id, fetchedProject.Id, 'Fetched project should match original');
    }
    
    @isTest
    static void testGetProjectAcc() {
        Project_Account__c projAcc1 = [SELECT Id FROM Project_Account__c WHERE Account__r.Name = 'Test Account' LIMIT 1];
        List<Project_Account__c> paList = new List<Project_Account__c>{projAcc1};
        String orderby = +' ORDER BY Account__r.Name ASC';
        Map<String, String> result = SchedulingMap.getProjectAcc(JSON.serialize(paList), orderby);
        System.assertNotEquals(null, result, 'Result should not be null');
    }

}