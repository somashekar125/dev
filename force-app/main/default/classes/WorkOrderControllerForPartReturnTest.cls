@isTest
private class WorkOrderControllerForPartReturnTest {
    
    @TestSetup
    static void makeData(){
        Test.startTest();
        
        Account rootAccount = TestDataFactory.createAccount();
        rootAccount.Name = 'Root Account1';
        
        insert rootAccount;
        
        Account acc = TestDataFactory.createAccount();
        acc.ShippingCountry = 'United States';
        acc.Root_Account__c = rootAccount.Id;
        acc.Source_Key__c = '5433';
        
        insert acc;
        
        // Create a test Products
        List<Product2> productList = new List<Product2>();
        
        Product2 pd1 = TestDataFactory.createProduct2(rootAccount);
        pd1.Name = 'HardwareProduct1';
        productList.add(pd1);
        
        insert productList;
        
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 pricebook = new Pricebook2(Id = pricebookId, IsActive = true, Country__c = 'United States');
        update pricebook;
        
        //Create PricebookEntry
        List<PricebookEntry> pbeList = new List<PricebookEntry>();
        
        PricebookEntry pbe1 = TestDataFactory.createPricebookEntry(pd1);
        pbeList.add(pbe1);
        
        insert pbeList;
        
        //Creating perant service contracts
        List<ServiceContract> scList = new List<ServiceContract>();
        
        ServiceContract partReturnSC = TestDataFactory.createServiceContract(rootAccount);
        partReturnSC.Name = 'Part Return';
        partReturnSC.Service_Type__c = 'Part Return';
        partReturnSC.AccountId = rootAccount.Id;
        partReturnSC.Country__c = 'United States';
        partReturnSC.Work_Order_Record_Type__c = 'Onsite Labor';
        scList.add(partReturnSC);
        
        insert scList;
        // Create Contract Line Items
        
        ContractLineItem cli1 = TestDataFactory.createContractLineItem(partReturnSC, pbe1);
        
        insert cli1;
        Test.stopTest();
    }
    
    @isTest
    static void testCreateWOforPartRequest2() {
        Account testAccount = [SELECT Id, Root_Account__c, ShippingCountry FROM Account WHERE Name = 'test account' LIMIT 1];
        ServiceContract sc = [SELECT Id, Service_Type__c, Pricebook2Id, Account.Staging_Product__c,
                              (SELECT Id, ServiceContractId, PricebookEntryId, PricebookEntry.Product2Id, 
                               UnitPrice, Quantity FROM ContractLineItems)
                              FROM ServiceContract WHERE AccountId = :testAccount.Root_Account__c 
                              AND Service_Type__c = 'Part Return' AND Status = 'Active' AND Single_WO_For_Billing__c = false LIMIT 1];
        
        Map<Id, Product2> prodMap = new Map<Id, Product2>([SELECT Id, Name FROM Product2 WHERE Family = 'Hardware' AND Account_Item_Belongs_To__c = :testAccount.Root_Account__c]);
        Set<Id> prodIds = new Set<Id>();
        Set<Id> cliProdIds = new Set<Id>();
        for(ContractLineItem cli: sc.ContractLineItems){
            prodIds.add(cli.PricebookEntry.Product2Id);
            cliProdIds.add(cli.PricebookEntry.Product2Id);
        }        
        Test.startTest();
        
        Map<Id, Case> csMap = new Map<Id, Case>();
        Case c = TestDataFactory.createCase(testAccount, sc);
        c.Root_Account__c = testAccount.Root_Account__c;
        c.Preferred_Time__c = null;
        c.Staging_Required_Count__c = 1;
        insert c;
        c = [SELECT Id, AccountId, Country__c, ContactId, Department__c, Department2__c, OwnerId, Description, Equipment_Type__c, 
             Incident__c, POS_Register_Number__c, PO_Number__c, Preferred_Time__c, Problem_Type__c, Product_Quantity__c, 
             ProductId, Project__c, Root_Account__c, Status, Tech_Notes__c, Service_Type__c, Staging_Required_Count__c, Priority, 
             ServiceContractId, Part_Receipt_Due_DateTime__c, Expected_SLA_Exit_Date__c, BusinessHoursId FROM Case WHERE Id = :c.Id];
        
        List<Case_Product__c> cpList = new List<Case_Product__c>();
        for(Product2 pd : prodMap.values()){
            if(sc.Account.Staging_Product__c == pd.Id) continue;
            Case_Product__c cp = new Case_Product__c(Name = pd.Name, Case__c =c.Id, Product__c = pd.Id, Quantity__c = 1);   
            cp.CLI_Product__c = (cliProdIds.contains(cp.Product__c)) ? true : false;
            cpList.add(cp);
            prodIds.add(cp.Product__c);
        }
        insert cpList;
        WorkOrder_Schedule__c wos = new WorkOrder_Schedule__c();
        wos.Preferred_Time__c = System.now();
        wos.Product__c = sc.ContractLineItems[0].PricebookEntry.Product2Id;
        wos.case__c = c.Id;
        insert wos;
        Map<Id, PricebookEntry> pbeMap = new Map<Id, PricebookEntry>([SELECT Id, Product2Id, Product2.Name, Product2.Family, 
                                                                      UnitPrice FROM PricebookEntry WHERE Product2Id IN:prodIds]);
        
        csMap.put(c.Id, c);
        String csMapStr = JSON.serialize(csMap);
        WorkOrderController.createWOThroughServiceContract(csMapStr);
        
        Test.stopTest();
        
        Id onsiteLaborId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Onsite_Labor').getRecordTypeId();
        Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>([SELECT Id, AccountId, Service_Type__c, RecordTypeId, ContactId, CaseId, 
                                                           Department__c, Department2__c, Pricebook2Id, OwnerId, Description, Equipment_Type__c, 
                                                           Incident__c, NetsuiteId__c, POS_Register_Number__c, PO__c, Preferred_Time_IMAC__c, 
                                                           Priority, Problem_Type__c, Product_Quantity__c, Product__c, Project__c, Approved__c,
                                                           (SELECT Id, WorkOrderId, UnitPrice, Quantity, PricebookEntryId, PricebookEntry.Product2Id, 
                                                            PricebookEntry.Product2.Name FROM WorkOrderLineItems), 
                                                           ServiceContractId, Root_Account__c, Status, Tech_Notes__c FROM WorkOrder WHERE CaseId =: c.Id]);
        
        System.assert(woMap.size() == 2);
        System.debug('woMap.size() --> ' + woMap.size());
        System.assert(woMap.values()[0].Service_Type__c == 'Part Return');
        System.assert(woMap.values()[0].AccountId == c.AccountId);
        System.assert(woMap.values()[0].CaseId == c.Id);
        System.assert(woMap.values()[0].ContactId == c.ContactId);
        System.assert(woMap.values()[0].Pricebook2Id == sc.Pricebook2Id);
        System.assert(woMap.values()[0].RecordTypeId == onsiteLaborId);
        System.assert(woMap.values()[0].Department__c == c.Department__c);
        System.assert(woMap.values()[0].Department2__c == c.Department2__c);
        System.assert(woMap.values()[0].OwnerId == c.OwnerId);
        System.assert(woMap.values()[0].Description == c.Description);
        System.assert(woMap.values()[0].Equipment_Type__c == c.Equipment_Type__c);
        System.assert(woMap.values()[0].Incident__c == c.Incident__c);
        System.assert(woMap.values()[0].NetsuiteId__c == 'TEST CASE');
        System.assert(woMap.values()[0].POS_Register_Number__c == c.POS_Register_Number__c);
        System.assert(woMap.values()[0].PO__c == c.PO_Number__c);
        System.assert(woMap.values()[0].Preferred_Time_IMAC__c.date() == wos.Preferred_Time__c.date());
        System.assert(woMap.values()[0].Priority == c.Priority);
        System.assert(woMap.values()[0].Problem_Type__c == c.Problem_Type__c);
        System.assert(woMap.values()[0].Product_Quantity__c == c.Product_Quantity__c);
        System.assert(woMap.values()[0].Product__c == c.ProductId);
        System.assert(woMap.values()[0].Project__c == c.Project__c);
        System.assert(woMap.values()[0].Root_Account__c == c.Root_Account__c);
        System.assert(woMap.values()[0].ServiceContractId == sc.Id);
        System.assert(woMap.values()[0].Status == 'Approved');
        System.assert(woMap.values()[0].Approved__c == true);
        System.assert(woMap.values()[0].Tech_Notes__c == c.Tech_Notes__c);
        System.assert(woMap.values()[0].Service_Type__c == sc.Service_Type__c);
        
        for(WorkOrderLineItem woli : woMap.values()[0].WorkOrderLineItems) {
            if(!pbeMap.containsKey(woli.PricebookEntryId)) continue;
            for(ContractLineItem cli : sc.ContractLineItems) {
                if(cli.PricebookEntryId != woli.PricebookEntryId) continue;
                System.assert(woli.Quantity == cli.Quantity);
                System.assert(woli.UnitPrice == cli.UnitPrice);
            }
        }
    }
}