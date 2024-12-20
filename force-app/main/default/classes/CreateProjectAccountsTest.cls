@isTest
private class CreateProjectAccountsTest {
    @IsTest
    static void testmethod1(){
        
        Test.startTest();
        
        Account rootAcc = TestDataFactory.createAccount();
        rootAcc.Name = 'Aldi Inc.';
        insert rootAcc;

        List<Account> accList = new List<Account>();
        Account acc = TestDataFactory.createAccount();
        acc.Root_Account__c = rootAcc.Id;
        acc.Source_Key__c = '1265865';
        accList.add(acc);
        Account acc2 = new Account();
        acc2.Name = 'test account2';
        acc2.Root_Account__c = rootAcc.Id;
        acc2.Account_Rep__c = userInfo.getUserId();
        acc2.Timezone__c = 'EST';
        acc2.ShippingState = 'Canada';
        acc2.Source_Key__c = '12865';
        accList.add(acc2);
        insert accList;


        Project__c project1 = new Project__c();
        project1.Name = 'testProject';
        project1.Client__c = rootAcc.Id;
        project1.Project_Status__c = 'Active';
        project1.Customer_ID__c = '1265865';
        project1.Description__c = 'testProject';
        insert project1;

        List<Account> accList1 = CreateProjectAccounts.getChildAccounts(project1.Id);

        List<Account> accList2 = CreateProjectAccounts.projectAccountCreation(accList1, project1.Id);

        List<Account> accList3 = CreateProjectAccounts.searchAccounts('test', project1.Id);

        Map<Id, Project_Account__c> projAccMap = new Map<Id, Project_Account__c>(CreateProjectAccounts.getExistingProjectAccounts(project1.Id));

        List<Project_Account__c> projAccList = CreateProjectAccounts.searchProjectAccounts('test', project1.Id);

        List<Id> projAccListIds = new List<Id>(projAccMap.keySet());

        List<Project_Account__c> projAccList1 = CreateProjectAccounts.deleteProjectAccount(project1.Id, projAccListIds);

        System.assertEquals(accList1.size(), 2);
        System.assertEquals(accList2.size(), 0);
        System.assertEquals(accList3.size(), 0);
        System.assertEquals(projAccMap.size(), 2);
        System.assertEquals(projAccList.size(), 2);
        System.assertEquals(projAccList1.size(), 0);

        Test.stopTest();      
    }
    
    @isTest
    static void testProcessCSVFile() {
        Id projectId = createTestProject();
        
        Account rootAcc = TestDataFactory.createAccount();
        rootAcc.Name = 'Test';
        insert rootAcc;
        
        Account acc3 = new Account();
        acc3.Name = 'test account3';
        acc3.Root_Account__c = rootAcc.Id;
        acc3.Account_Rep__c = UserInfo.getUserId();
        acc3.Timezone__c = 'EST';
        acc3.ShippingState = 'United States';
        acc3.Source_Key__c = '463543';
        insert acc3;
    
        Project_Account__c projAcc1 = new Project_Account__c();
        projAcc1.Name = 'Test Project Account';
        projAcc1.Project__c = projectId;
        projAcc1.Account__c = acc3.Id;
        insert projAcc1;
          
        String validCSV = 'Id,Name,Project,Account,Visit 1,Visit 1 Date,Visit 1 Time,Quantity of Devices,start time,precall complete\n' +
                          ',Test Project Account 1,' + projectId + ',' + acc3.Id + ',2024-10-03T08:00:00.000Z,2024-01-01,09:00 AM,1,08:00 AM,TRUE\n' +
							'Test Project Account 2,' + projectId + ',' + acc3.Id + ',2024-10-03T08:00:00.000Z,2024-01-02,10:00 AM,1,08:00 AM,TRUE\n';
    
        String result = CreateProjectAccounts.processCSVFile(projectId, validCSV);
    
        List<Project_Account__c> createdAccounts = [SELECT Id, Name FROM Project_Account__c WHERE Project__c = :projectId];
        System.assertEquals(1, createdAccounts.size(), 'One project account should be created.');
    
        String invalidCSVMissingId = 'Id,Name,Project,Account,Visit 1,Visit 1 Date,Visit 1 Time,Quantity of Devices,start time,precall complete\n' +
                                      ',Test Project Account 3,' + projectId + ',' + acc3.Id + ',2024-10-03T08:00:00.000Z,2024-01-03,11:00 AM,1,08:00 AM,TRUE\n';
        
        result = CreateProjectAccounts.processCSVFile(projectId, invalidCSVMissingId);

        String invalidCSVMissingId1 = 'Id,Name,ProjectId,AccountId,Visit 1,Visit 1 Date,Visit 1 Time,Quantity of Devices,start time,precall complete\n' +
                                      ',Test Project Account 3,' + projectId + ',' + acc3.Id + ',2024-10-03T08:00:00.000Z,2024-01-03,11:00 AM,1,08:00 AM,TRUE\n';
    
        result = CreateProjectAccounts.processCSVFile(projectId, invalidCSVMissingId1);
    
        String invalidCSVInvalidId = 'Id,Name,Project,Account,Visit 1,Visit 1 Date,Visit 1 Time,Quantity of Devices,start time,precall complete\n' +
                                      'invalidId,Test Project Account 4,' + projectId + ',' + acc3.Id + ',,2024-01-04,12:00 PM,1,08:00 AM,TRUE\n';
        
         result = CreateProjectAccounts.processCSVFile(projectId, invalidCSVInvalidId);
        
        String invalidCSVInvalidId1 = 'Id,Name,ProjectId,AccountId,Visit 1,Visit 1 Date,Visit 1 Time,Quantity of Devices,start time,precall complete\n' +
                                      'invalidId,Test Project Account 4,' + projectId + ',' + acc3.Id + ',,2024-01-04,12:00 PM,1,08:00 AM,TRUE\n';
    
        result = CreateProjectAccounts.processCSVFile(projectId, invalidCSVInvalidId1);
    
        String invalidCSVMissingProject = 'Id,Name,Project,Account,Visit 1,Visit 1 Date,Visit 1 Time,Quantity of Devices,start time,precall complete\n' +
                                           projAcc1.Id + ',Test Project Account 5,,' + acc3.Id + ',,2024-01-05,01:00 PM,1,08:00 AM,TRUE\n';
    
        result = CreateProjectAccounts.processCSVFile(projectId, invalidCSVMissingProject);
    
        String invalidCSVMissingAccount = 'Id,Name,Project,Account,Visit 1,Visit 1 Date,Visit 1 Time,Quantity of Devices,start time,precall complete\n' +
                                           projAcc1.Id + ',Test Project Account 6,' + projectId + ',,2024-10-03T08:00:00.000Z,2024-01-06,02:00 PM,1,08:00 AM,TRUE\n';
    
        result = CreateProjectAccounts.processCSVFile(projectId, invalidCSVMissingAccount);
    }
    
    static Id createTestProject() {
        Project__c testProject = new Project__c(Name = 'Test Project 1');
        insert testProject;
        return testProject.Id;
    }    
}