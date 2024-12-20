@isTest
public class CaseProcessorTest {
    
    @testSetup static void setupTestData() {
        
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
        scList.add(sc);
        ServiceContract sc1 = TestDataFactory.createServiceContract(accList[0]);
        sc1.Service_Type__c = 'Onsite IMAC';
        scList.add(sc1);
        insert scList;
        
        ServiceContract childSC = TestDataFactory.createServiceContract(accList[0]);
        childSC.Service_Type__c = 'Onsite IMAC';
        childSC.ParentServiceContractId = scList[0].Id;
        insert childSC;
        
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
        insert pbeList;
        
        List<ContractLineItem> cliList = new List<ContractLineItem>();
        ContractLineItem cli = new ContractLineItem();
        cli.ServiceContractId = scList[0].Id;
        cli.PricebookEntryId = standardPrice2.Id;
        cli.UnitPrice = 100;
        cli.Quantity = 1;
        cli.Priority__c = 'Severity 1';
        cli.Applicable_on_Days__c = 'Monday;Tuesday;Wednesday;Thursday;Friday';
        cli.Applicable_After_Total_Hours__c = 4;
        cli.Applicable_If_IMAC_Due_Hours_Within__c = 30;
        cliList.add(cli);
        ContractLineItem cli2 = new ContractLineItem();
        cli2.ServiceContractId = scList[0].Id;
        cli2.PricebookEntryId = standardPrice.Id;
        cli2.UnitPrice = 100;
        cli2.Quantity = 1;
        cli2.Applicable_on_Days__c = 'Monday;Tuesday;Wednesday;Thursday;Friday';
        cli2.Priority__c = 'Severity 1';
        cli2.Applicable_After_Total_Hours__c = 4;
        cli2.Applicable_If_IMAC_Due_Hours_Exceeding__c = 2;
        cliList.add(cli2);
        ContractLineItem cli3 = new ContractLineItem();
        cli3.ServiceContractId = childSC.Id;
        cli3.PricebookEntryId = standardPrice.Id;
        cli3.UnitPrice = 100;
        cli3.Quantity = 1;
        cli3.Applicable_on_Days__c = 'Monday;Tuesday;Wednesday;Thursday;Friday';
        cli3.Priority__c = 'Severity 1';
        cli3.Applicable_After_Total_Hours__c = 4;
        cli3.Applicable_If_IMAC_Due_Hours_Exceeding__c = 2;
        cliList.add(cli3);
        insert cliList;
        
        Project__c project1 = new Project__c();
        project1.Name = 'testProject';
        project1.Client__c = rootAcc.Id;
        project1.Project_Status__c = 'Active';
        project1.Customer_ID__c = '1265865';
        project1.Description__c = 'testProject';
        project1.Service_Contract__c = sc.Id;
        insert project1;
        
        Project_Account__c projAcc1 = new Project_Account__c(Project__c = project1.Id, Account__c = acc.Id, Visit_1__c = DateTime.now(),Quantity_of_Devices__c = 2);
        Project_Account__c projAcc2 = new Project_Account__c(Project__c = project1.Id, Account__c = acc.Id);
        insert new List<Project_Account__c>{projAcc1, projAcc2};
            }
    
    @isTest
    static void testCaseProcessor() {
        Map<Id,Decimal> projAccQuantityMap = new  Map<Id,Decimal>(); 
        Project__c project1 = [SELECT Id, Service_Contract__c FROM Project__c LIMIT 1];
        Account acc = [SELECT Id,Name,Source_Key__c FROM Account LIMIT 1];
        ServiceContract sc1 = [SELECT Id,Name,Create_Work_Order_For__c,Service_Type__c FROM ServiceContract LIMIT 1];
        List<Case> cases = new List<Case>();
        for (Project_Account__c projAcc : [SELECT Id,Project__c,Account__c,Quantity_of_Devices__c FROM Project_Account__c LIMIT 1]) {
            // cases.add(new Case(Project__c = project1.Id, Service_Type__c = 'Onsite IMAC'));
            projAccQuantityMap.put(projAcc.Id, projAcc.Quantity_of_Devices__c);
            case cs = TestDataFactory.createCase(acc, sc1);
            cases.add(cs);
         }
        
        Test.startTest();
        
        ServiceContract sc = [SELECT Id, Name, (SELECT Id, Product2Id, Product2.Name, Quantity FROM ContractLineItems) FROM ServiceContract WHERE Id = :project1.Service_Contract__c LIMIT 1];
        String serviceContractJson = JSON.serialize(sc);
        
        List<ServiceContract> childSCList = [SELECT Id, Name, (SELECT Id, Product2Id, Product2.Name, Quantity FROM ContractLineItems) FROM ServiceContract WHERE ParentServiceContractId = :sc.Id];
        System.debug('childSCList-->'+JSON.Serialize(childSCList));
        
        CaseProcessor processor = new CaseProcessor(cases, project1.Id, serviceContractJson, childSCList, projAccQuantityMap);
        System.enqueueJob(processor);
        Test.stopTest();
        
        List<Case_Product__c> caseProducts = [SELECT Id, Case__c, Product__c FROM Case_Product__c WHERE Case__c IN :cases];
        
        List<Case> updatedCases = [SELECT Id, Create_Work_Order__c FROM Case WHERE Id IN :cases];
        for (Case c : updatedCases) {           
            System.assertEquals(true, c.Create_Work_Order__c, 'Case Create_Work_Order__c should be set to true');
        }
        
        for (Case_Product__c cp : caseProducts) {
            System.assertNotEquals(null, cp.Product__c, 'Product__c should be set');
            System.assertNotEquals(null, cp.Case__c, 'Case__c should be set');
        }
    }
    
}