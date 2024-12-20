@isTest
public class CreateCaseAndWorkorderControllerTest {
    
    static Project__c project1;
    
    @isTest
    static void testmethod1() {
        
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
        acc2.Account_Rep__c = UserInfo.getUserId();
        acc2.Timezone__c = 'EST';
        acc2.ShippingState = 'Canada';
        acc2.Source_Key__c = '12865';
        accList.add(acc2);
        insert accList;
        List<ServiceContract> scList = new List<ServiceContract>();
        ServiceContract sc = TestDataFactory.createServiceContract(accList[0]);
        sc.Priority__c = 'Severity 2';
        sc.Name = 'TEST';
        scList.add(sc);
        ServiceContract sc1 = TestDataFactory.createServiceContract(accList[0]);
        sc1.Service_Type__c = 'Onsite IMAC';
        scList.add(sc1);
        ServiceContract sc2 = TestDataFactory.createServiceContract(accList[0]);
        sc2.Service_Type__c = 'Onsite Labor Only';
        sc2.Name = 'Test 1';
        scList.add(sc2);
        insert scList;
        ServiceContract sc3 = TestDataFactory.createServiceContract(accList[0]);
        sc3.Priority__c = 'Severity 1';
        sc3.ParentServiceContractId = sc2.Id;
        insert sc3;
        
        List<ServiceContract> childSCList = new List<ServiceContract>();
        ServiceContract childSC = TestDataFactory.createServiceContract(accList[0]);
        childSC.Service_Type__c = 'Onsite IMAC';
        childSC.ParentServiceContractId = scList[0].Id;
        childSCList.add(childSC);
        ServiceContract childSC1 = TestDataFactory.createServiceContract(accList[0]);
        childSC1.Service_Type__c = 'Onsite IMAC';
        childSC1.ParentServiceContractId = scList[2].Id;
        childSCList.add(childSC1);
        ServiceContract childSC2 = TestDataFactory.createServiceContract(accList[0]);
        childSC2.Service_Type__c = 'Onsite IMAC';
        childSC2.ParentServiceContractId = scList[2].Id;
        childSCList.add(childSC2);
        insert childSCList;
        
        List<Product2> prodList = new List<Product2>();
        Product2 prod = TestDataFactory.createProduct2(accList[0]);
        prod.Handling_Code__c = 'Consumable';
        prodList.add(prod);
        Product2 prod2 = TestDataFactory.createProduct2(accList[0]);
        prod2.Name = 'TesProduct';
        prod2.Source_Key__c = '22222';
        prodList.add(prod2);
        Product2 prod3 = TestDataFactory.createProduct2(accList[0]);
        prod3.Name = 'TestProduct';
        prod3.Source_Key__c = '212';
        prod3.Family = 'Service';
        prodList.add(prod3);
        insert prodList;
        
        List<PricebookEntry> pbeList = new List<PricebookEntry>();
        PricebookEntry standardPrice = TestDataFactory.createPricebookEntry(prod);
        pbeList.add(standardPrice);
        PricebookEntry standardPrice2 = TestDataFactory.createPricebookEntry(prod2);
        pbeList.add(standardPrice2);
        PricebookEntry standardPrice3 = TestDataFactory.createPricebookEntry(prod3);
        pbeList.add(standardPrice3);
        insert pbeList;
        
        List<ContractLineItem> cliList = new List<ContractLineItem>();
        ContractLineItem cli = new ContractLineItem();
        cli.ServiceContractId = scList[0].Id;
        cli.PricebookEntryId = standardPrice2.Id;
        cli.UnitPrice = 100;
        cli.Quantity =1 ;
        cli.Priority__c = 'Severity 1' ;
        cli.Applicable_on_Days__c = 'Monday;Tuesday;Wednesday;Thursday;Friday';
        cli.Applicable_After_Total_Hours__c = 4;
        cli.Applicable_If_IMAC_Due_Hours_Within__c = 30;
        cliList.add(cli);
        ContractLineItem cli2 = new ContractLineItem();
        cli2.ServiceContractId = scList[0].Id;
        cli2.PricebookEntryId = standardPrice3.Id;
        cli2.UnitPrice = 100;
        cli2.Quantity =1 ;
        cli2.Applicable_on_Days__c = 'Monday;Tuesday;Wednesday;Thursday;Friday';
        cli2.Priority__c = 'Severity 1' ;
        cli2.Applicable_After_Total_Hours__c = 4;
        cli2.Applicable_If_IMAC_Due_Hours_Exceeding__c = 2;
        cliList.add(cli2);
        ContractLineItem cli3 = new ContractLineItem();
        cli3.ServiceContractId = childSC.Id;
        cli3.Applicable_on_Days__c = 'Monday;Tuesday;Wednesday;Thursday;Friday';
        cli3.PricebookEntryId = standardPrice.Id;
        cli3.UnitPrice = 100;
        cli3.Quantity =1 ;
        cli3.Priority__c = 'Severity 1' ;
        cli3.Applicable_After_Total_Hours__c = 4;
        cli3.Applicable_If_IMAC_Due_Hours_Within__c = null;
        cli3.Applicable_If_IMAC_Due_Hours_Exceeding__c = null;
        cliList.add(cli3);
        insert cliList;
        
        Support_Team__c st = new Support_Team__c();
        st.Name = 'PBS TEST SUPPORT TEAM 2';
        st.Account__c = rootAcc.Id;
		insert st;
        
        project1 = new Project__c();
        project1.Name = 'testProject';
        project1.Client__c = rootAcc.Id;
        project1.Project_Status__c = 'Active';
        project1.Customer_ID__c = '1265865';
        project1.Description__c = 'testProject';
        project1.Service_Contract__c = sc.Id;
        project1.Support_Team__c = st.Id;
        insert project1;        
        
        Project_Account__c projAcc1 = new Project_Account__c(Project__c = project1.Id,Quantity_of_Devices__c = 2, Account__c = acc.Id, Visit_1__c = DateTime.now());
        Project_Account__c projAcc2 = new Project_Account__c(Project__c = project1.Id,Quantity_of_Devices__c = 2, Account__c = acc.Id);
        insert new List<Project_Account__c>{projAcc1, projAcc2};
        List<Project_Account__c> projAccList = CreateCaseAndWorkorderController.getProjectAccounts(project1.Id, 'Test','Test');
    }
    
    @isTest
    static void testGetUserTimezone() {
        Test.startTest();
        String timezone = CreateCaseAndWorkorderController.getUserTimezone();
        System.assertNotEquals(null, timezone, 'User timezone should not be null');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetServiceContract() {
        testmethod1();
        
        Project_Account__c projAcc = [SELECT Id,Visit_1__c,Visit_2__c,Visit_3__c,Account__c,Quantity_of_Devices__c FROM Project_Account__c WHERE Project__c = :project1.Id LIMIT 1];
        List<Project_Account__c> projAccList = new List<Project_Account__c>{projAcc};
            
            Boolean visitOrder = CreateCaseAndWorkorderController.getServiceContract(project1.Id);
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetServiceContractVisitOrderWithNullVisits() {
        testmethod1();
        
        Project_Account__c projAcc1 = new Project_Account__c(Project__c = project1.Id, Account__c = [SELECT Id FROM Account LIMIT 1].Id, Visit_1__c = null, Visit_2__c = null, Visit_3__c = null,Quantity_of_Devices__c = 1);
        insert projAcc1;
        List<Project_Account__c> projAccList = new List<Project_Account__c>{projAcc1};
            
            Project__c projectToUpdate = [SELECT Id, Service_Contract__c FROM Project__c WHERE Id = :project1.Id LIMIT 1];
        
        ServiceContract scToUpdate = [SELECT Id, Visit_Order__c FROM ServiceContract WHERE Id = :projectToUpdate.Service_Contract__c LIMIT 1];
        scToUpdate.Visit_Order__c = 'Visit 3';
        update scToUpdate;
        
        Boolean isValid = CreateCaseAndWorkorderController.getServiceContractVisitOrder(project1.Id, projAccList);
        scToUpdate.Visit_Order__c = 'Visit 2';
        update scToUpdate;
        
        isValid = CreateCaseAndWorkorderController.getServiceContractVisitOrder(project1.Id, projAccList);
        scToUpdate.Visit_Order__c = 'Visit 1';
        update scToUpdate;
        
        isValid = CreateCaseAndWorkorderController.getServiceContractVisitOrder(project1.Id, projAccList);
        Test.stopTest();
    }
    
    @isTest
    static void testSearchProjectAccounts() {
        testmethod1();
        List<Project_Account__c> result = CreateCaseAndWorkorderController.searchProjectAccounts('Visit', project1.Id);
        
        Test.stopTest();
    }
    
    
    
    @isTest
    static void getChildServiceContract() {
        testmethod1();
        Account rootAcc = [SELECT Id,Name FROM Account WHERE Name = 'Aldi Inc.'];
        ServiceContract sc = new ServiceContract();
        sc.Name = 'test ServiceContract';
        sc.AccountId = rootAcc.Id;
        sc.Create_Work_Order_For__c = 'Service Contract';
        sc.Invoice_Group__c = 'Field Service';
        sc.Service_Type__c = 'Advance Exchange (Depot Only)';
        sc.Work_Order_Record_Type__c = 'Part Shipment';
        sc.StartDate = System.now().Date();
        sc.Visit_Order__c = 'Visit 1';
        insert sc;
        Project__c project2 = new Project__c();
        project2.Name = 'testProject';
        project2.Client__c = rootAcc.Id;
        project2.Project_Status__c = 'Active';
        project2.Customer_ID__c = '1265865';
        project2.Description__c = 'testProject';
        project2.Service_Contract__c = sc.Id;
        insert project2;
        
        Project__c project = [SELECT Id, Service_Contract__c FROM Project__c WHERE Id = :project2.Id];
        Project_Account__c projAcc1 = new Project_Account__c(Project__c = project.Id, Account__c = [SELECT Id FROM Account LIMIT 1].Id, Visit_1__c = null, Visit_2__c = null, Visit_3__c = null,Quantity_of_Devices__c = 1);
        insert projAcc1;
        List<Project_Account__c> projAccList = new List<Project_Account__c>{projAcc1};
            
        Boolean isValid = CreateCaseAndWorkorderController.getServiceContractVisitOrder(project2.Id, projAccList);
    }
    
    @isTest
    static void testCreateCaseAndWorkorderRecords() {
        testmethod1();
        
        Project_Account__c projAcc = [SELECT Id,Project__c,Project__r.Service_Contract__r.Name,Project__r.Support_Team__r.Tech_Notes__c,Project__r.Support_Team__c,Project__r.Description__c,
                                      Project__r.Tech_Notes__c,Visit_1__c,Visit_2__c,Visit_3__c,Account__c,Quantity_of_Devices__c FROM Project_Account__c WHERE Project__c = :project1.Id LIMIT 1];
        List<Project_Account__c> projAccList = new List<Project_Account__c>{projAcc};
            
            CreateCaseAndWorkorderController.createCaseAndWorkorderRecords(project1.Id, projAccList);
        
        List<Case> cases = [SELECT Id, Service_Type__c FROM Case WHERE Project__c = :project1.Id];
        
        Test.stopTest();
    }
}