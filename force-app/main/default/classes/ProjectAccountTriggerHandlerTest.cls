@isTest
public with sharing class ProjectAccountTriggerHandlerTest {
    @isTest
    static void testDuplicateCheck() {
        // Setup test data
        Account rootAcc = TestDataFactory.createAccount();
        rootAcc.Name = 'Aldi Inc.';
        insert rootAcc;

        Account acc = TestDataFactory.createAccount();
        acc.Name = 'Test Account';
        acc.Source_Key__c = '23456789';
        acc.Root_Account__c = rootAcc.Id;
        insert acc;
        
        ServiceContract sc = TestDataFactory.createServiceContract(acc);
        sc.Visit_Order__c = 'Visit 1';
        insert sc;

        Account acc1 = TestDataFactory.createAccount();
        acc1.Name = 'Test Account 1';
        acc1.Source_Key__c = '234567891';
        acc1.Root_Account__c = rootAcc.Id;
        insert acc1;

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

        Project_Account__c prjAccDuplicate = new Project_Account__c();
        prjAccDuplicate.Name = 'Test PA Duplicate';
        prjAccDuplicate.Account__c = acc.Id; 
        prjAccDuplicate.Project__c = pro.Id; 

        Test.startTest();
        try {
            insert prjAccDuplicate;
            System.assert(false, 'Expected a duplicate error but none was thrown.');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('A Project Account with this Account already exists for this Project.'));
        }
        Test.stopTest();
    }

    @isTest
    static void testAccountChangeUpdate() {

        Account rootAcc = TestDataFactory.createAccount();
        rootAcc.Name = 'Aldi Inc.';
        insert rootAcc;

        Account acc = TestDataFactory.createAccount();
        acc.Name = 'Test Account';
        acc.Source_Key__c = '23456789';
        acc.Root_Account__c = rootAcc.Id;
        insert acc;

        ServiceContract sc = TestDataFactory.createServiceContract(acc);
        sc.Visit_Order__c = 'Visit 1';
        insert sc;
        
        Account acc1 = TestDataFactory.createAccount();
        acc1.Name = 'Test Account 1';
        acc1.Source_Key__c = '234567891';
        acc1.Root_Account__c = rootAcc.Id;
        insert acc1;

        Project__c pro = new Project__c();
        pro.Name = 'Test Project';
        pro.Client__c = acc.Id;
        pro.Applicable_on_Days__c = 'Monday;Tuesday;Wednesday;Thursday;Friday';
        pro.Number_of_visits__c = 3;
        pro.Visit_Offset__c = 1;
        Datetime dt = Datetime.now();
        pro.Start_Time__c = dt.time();
        pro.Service_Contract__c = sc.Id;
        insert pro;

        Project_Account__c prjAcc = new Project_Account__c();
        prjAcc.Name = 'Test PA 1';
        prjAcc.Account__c = acc.Id;
        prjAcc.Project__c = pro.Id;
        prjAcc.Visit_1__c = Datetime.now().addDays(2);
        insert prjAcc;

        Case c1 = new Case();
        c1.AccountId = acc.Id;
       	c1.Incident__c = 'TEST';
        c1.OwnerId = userInfo.getUserId();
        c1.Status = 'New';
       	c1.Priority = 'Severity 2';
        c1.ServiceContractId = sc.Id;
        c1.Project_Account__c = prjAcc.Id;
        c1.Service_Type__c = 'Advance Exchange (Depot Only)';
        c1.Project__c = pro.Id;
        insert c1;
        
        WorkOrder wo1 = new WorkOrder();
        wo1.AccountId = acc.Id;
        wo1.CaseId = c1.Id;
        wo1.ServiceContractId = sc.Id;
        wo1.No_Cost__c = true;
        wo1.Priority = 'Severity 1';
        wo1.status = 'New';
        wo1.FN_Status__c = 'Work Done';
        wo1.Technician_Status__c = 'Scheduling';
        insert wo1;
        
        prjAcc.Account__c = acc1.Id;

        Test.startTest();
        update prjAcc;
        Test.stopTest();

        Project_Account__c updatedPrjAcc = [SELECT Account__c FROM Project_Account__c WHERE Id = :prjAcc.Id];
        System.assertEquals(acc1.Id, updatedPrjAcc.Account__c, 'The Account should have been updated.');
    }

    @isTest
    static void testVisitUpdate() {
        Account rootAcc = TestDataFactory.createAccount();
        rootAcc.Name = 'Aldi Inc.';
        insert rootAcc;

        Account acc = TestDataFactory.createAccount();
        acc.Name = 'Test Account';
        acc.Source_Key__c = '23456789';
        acc.Root_Account__c = rootAcc.Id;
        insert acc;
        
        ServiceContract sc = TestDataFactory.createServiceContract(acc);
        sc.Visit_Order__c = 'Visit 1';
        insert sc;

        Project__c pro = new Project__c();
        pro.Name = 'Test Project';
        pro.Client__c = acc.Id;
        pro.Applicable_on_Days__c = 'Monday;Tuesday;Wednesday;Thursday;Friday';
        pro.Number_of_visits__c = 3;
        pro.Visit_Offset__c = 1;
        pro.Service_Contract__c = sc.Id;
        insert pro;

        Project_Account__c prjAcc = new Project_Account__c();
        prjAcc.Name = 'Test PA 1';
        prjAcc.Account__c = acc.Id;
        prjAcc.Project__c = pro.Id;
        prjAcc.Visit_1__c = Datetime.now().addDays(2);
        insert prjAcc;
        
        Case c = new Case();
        c.AccountId = acc.Id;
       	c.Incident__c = 'TEST';
        c.OwnerId = userInfo.getUserId();
        c.Status = 'New';
       	c.Priority = 'Severity 2';
        c.ServiceContractId = sc.Id;
        c.Project_Account__c = prjAcc.Id;
        c.Service_Type__c = 'Advance Exchange (Depot Only)';
        c.Project__c = pro.Id;
        insert c;
        
        WorkOrder wo = new WorkOrder();
        wo.AccountId = acc.Id;
        wo.CaseId = c.Id;
        wo.ServiceContractId = sc.Id;
        wo.No_Cost__c = true;
        wo.Priority = 'Severity 1';
        wo.status = 'New';
        wo.FN_Status__c = 'Work Done';
        wo.Technician_Status__c = 'Scheduling';
        insert wo;

        prjAcc.Visit_1__c = Datetime.now().addDays(5);

        Test.startTest();
        update prjAcc;
        Test.stopTest();

        Project_Account__c updatedPrjAcc = [SELECT Visit_1__c FROM Project_Account__c WHERE Id = :prjAcc.Id];
    }
}