@isTest
public class WorkOrderControllerForNewStoreTest {
    //for new store installation and relocation
    @testSetup
    static void testSetup() {
        Test.startTest();
        
        Account rootAccount = TestDataFactory.createAccount();
        rootAccount.Name = 'Root Account1';
        insert rootAccount;
        
        Account acc = TestDataFactory.createAccount();
        acc.ShippingCountry = 'United States';
        acc.Root_Account__c = rootAccount.Id;
        acc.Source_Key__c = '5437';
        
        insert acc;
        
        // Create a test Products
        List<Product2> productList = new List<Product2>();
        
        Product2 serviceProd1 = TestDataFactory.createProduct2(rootAccount);
        serviceProd1.Name = 'ServiceProduct1';
        serviceProd1.Family = 'Service';
        productList.add(serviceProd1);
        Product2 serviceProd2 = TestDataFactory.createProduct2(rootAccount);
        serviceProd2.Name = 'ServiceProduct2';
        serviceProd2.Family = 'Service';
        productList.add(serviceProd2);
        Product2 serviceProd3 = TestDataFactory.createProduct2(rootAccount);
        serviceProd3.Name = 'ServiceProduct3';
        serviceProd3.Family = 'Service';
        productList.add(serviceProd3);
        Product2 hardwareProd1 = TestDataFactory.createProduct2(rootAccount);
        hardwareProd1.Name = 'HardwareProduct1';
        productList.add(hardwareProd1);
        Product2 stagingProd = TestDataFactory.createProduct2(rootAccount);
        stagingProd.Name = 'Test Stage Product1';
        stagingProd.Staging_Required__c = true;
        productList.add(stagingProd);
        Product2 removeProd = TestDataFactory.createProduct2(rootAccount);
        removeProd.Family = 'Service';
        removeProd.Name = 'ProdToBeRemoved';
        productList.add(removeProd);
        
        insert productList;
        
        rootAccount.Staging_Product__c = stagingProd.Id;
        update rootAccount;
        
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 Pricebook1 = new Pricebook2(Id = pricebookId, IsActive = true, Country__c = 'United States');
        update Pricebook1;
        
        //Create PricebookEntry
        List<PricebookEntry> pbeList = new List<PricebookEntry>();
        
        PricebookEntry pbe1 = TestDataFactory.createPricebookEntry(serviceProd1);
        pbeList.add(pbe1);
        PricebookEntry pbe2 = TestDataFactory.createPricebookEntry(serviceProd2);
        pbeList.add(pbe2);
        PricebookEntry pbe3 = TestDataFactory.createPricebookEntry(hardwareProd1);
        pbeList.add(pbe3);
        PricebookEntry pbe4 = TestDataFactory.createPricebookEntry(stagingProd);
        pbeList.add(pbe4);
        PricebookEntry pbe5 = TestDataFactory.createPricebookEntry(serviceProd3);
        pbeList.add(pbe5);
        PricebookEntry pbe6 = TestDataFactory.createPricebookEntry(removeProd);
        pbeList.add(pbe6);
        
        insert pbeList;
        ServiceContract newStoreSC = TestDataFactory.createServiceContract(rootAccount);
        newStoreSC.Create_Work_Order_For__c = 'Contract Line Item';
        newStoreSC.Service_Type__c = 'New Store Install';
        newStoreSC.Work_Order_Record_Type__c = 'Onsite Labor';
        insert newStoreSC;
        
        // Create test Service Contracts
        List<ServiceContract> scList1 = new List<ServiceContract>();
        
        ServiceContract singleWOnewStoreSC = TestDataFactory.createServiceContract(rootAccount);
        singleWOnewStoreSC.Name = 'testServiceContract';
        singleWOnewStoreSC.Create_Work_Order_For__c = 'Contract Line Item';
        singleWOnewStoreSC.Service_Type__c = 'New Store Install';
        singleWOnewStoreSC.Work_Order_Record_Type__c = 'Onsite Labor';
        singleWOnewStoreSC.Priority__c = 'Severity 2';
        singleWOnewStoreSC.Single_WO_For_Billing__c = true;
        scList1.add(singleWOnewStoreSC);
        
        ServiceContract storeRelocationSC = TestDataFactory.createServiceContract(rootAccount);
        storeRelocationSC.ParentServiceContractId = newStoreSC.Id;
        storeRelocationSC.Create_Work_Order_For__c = 'Contract Line Item';
        storeRelocationSC.Service_Type__c = 'Store Relocation';
        storeRelocationSC.Work_Order_Record_Type__c = 'Onsite Labor';
        storeRelocationSC.Priority__c = 'Severity 2';
        scList1.add(storeRelocationSC);
        
        insert scList1;
        
        // Create Contract Line Items
        List<ContractLineItem> cliList = new List<ContractLineItem>();
        
        ContractLineItem cli1 = TestDataFactory.createContractLineItem(storeRelocationSC, pbe1);
        cli1.Number_Of_Technicians__c = 2;
        cliList.add(cli1);
        ContractLineItem cli2 = TestDataFactory.createContractLineItem(storeRelocationSC, pbe3);
        cliList.add(cli2);
        
        ContractLineItem cli3 = TestDataFactory.createContractLineItem(singleWOnewStoreSC, pbe1);
        cli3.Number_Of_Technicians__c = 2;
        cliList.add(cli3);
        ContractLineItem cli4 = TestDataFactory.createContractLineItem(singleWOnewStoreSC, pbe2);
        cli4.Number_Of_Technicians__c = 2;
        cliList.add(cli4);
        ContractLineItem cli5 = TestDataFactory.createContractLineItem(singleWOnewStoreSC, pbe3);
        cliList.add(cli5);
        ContractLineItem cli6 = TestDataFactory.createContractLineItem(singleWOnewStoreSC, pbe5);
        cli6.Include_In_WO_Type__c = 'Part Shipment';
        cli6.Work_Order_Record_Type__c = 'Part Shipment';
        cliList.add(cli6);
        ContractLineItem cli7 = TestDataFactory.createContractLineItem(singleWOnewStoreSC, pbe6);
        cliList.add(cli7);
        
        insert cliList;
        Test.stopTest();
    }
    
    @isTest
    static void testCreateWOforNewStore() {
        Account testAccount = [SELECT Id, Root_Account__c, ShippingCountry FROM Account WHERE Name = 'test account' LIMIT 1];
        ServiceContract sc = [SELECT Id, Service_Type__c, Pricebook2Id, Account.Staging_Product__c, Priority__c,
                              (SELECT Id, Service_Type__c, Pricebook2Id, Account.Staging_Product__c, Priority__c 
                               FROM ChildServiceContracts),
                              (SELECT Id, Priority__c, PricebookEntryId, Quantity, UnitPrice,Include_In_WO_Type__c FROM ContractLineItems) 
                              FROM ServiceContract WHERE AccountId = :testAccount.Root_Account__c AND ParentServiceContractId = null
                              AND Service_Type__c = 'New Store Install' AND Single_WO_For_Billing__c = false LIMIT 1];
        Map<Id, ServiceContract> childSCMap = new Map<Id, ServiceContract>(sc.ChildServiceContracts);
        List<ContractLineItem> cliList = [SELECT Id, ServiceContractId, PricebookEntryId, PricebookEntry.Product2Id,Include_In_WO_Type__c, UnitPrice, Quantity, 
                                          Priority__c FROM ContractLineItem WHERE ServiceContractId = :sc.Id 
                                          OR ServiceContractId IN :childSCMap.keySet()];
        Map<Id, Product2> prodMap = new Map<Id, Product2>([SELECT Id, Name FROM Product2 WHERE Family = 'Hardware' AND Account_Item_Belongs_To__c = :testAccount.Root_Account__c]);
        Set<Id> prodIds = new Set<Id>();
        Set<Id> cliProdIds = new Set<Id>();
        for(ContractLineItem cli: cliList){
            prodIds.add(cli.PricebookEntry.Product2Id);
            cliProdIds.add(cli.PricebookEntry.Product2Id);
        } 
        
        Test.startTest();
        Map<Id, Case> csMap = new Map<Id, Case>();
        Case c = TestDataFactory.createCase(testAccount, sc);
        c.Service_Type__c = 'New Store Install';
        c.Root_Account__c = testAccount.Root_Account__c;
        c.Include_Part__c = true;
        c.Priority = sc.Priority__c;
        c.Staging_Required_Count__c = 1;
        insert c;
        
        c = [SELECT Id, AccountId, Country__c, ContactId, Department__c, Department2__c, OwnerId, Description, Equipment_Type__c, 
             Incident__c, POS_Register_Number__c, PO_Number__c, Preferred_Time__c, Problem_Type__c, Product_Quantity__c, 
             ProductId, Project__c, Root_Account__c, Status, Tech_Notes__c, Service_Type__c, Staging_Required_Count__c, Priority, 
             ServiceContractId, Part_Receipt_Due_DateTime__c, Expected_SLA_Exit_Date__c FROM Case WHERE Id = :c.Id];
        
        csMap.put(c.Id, c);
        List<Case_Product__c> cpList = new List<Case_Product__c>();
        for(Product2 pd : prodMap.values()){
            if(sc.Account.Staging_Product__c == pd.Id) continue;
            Case_Product__c cp = new Case_Product__c(Name = pd.Name, Case__c =c.Id, Product__c = pd.Id, Quantity__c = 1);   
            cp.CLI_Product__c = (cliProdIds.contains(cp.Product__c)) ? true : false;
            cpList.add(cp);
            prodIds.add(cp.Product__c);
        }
        
        insert cpList;
        
        Map<Id,PricebookEntry> pbeMap = new Map<Id,PricebookEntry>([SELECT Id, Product2Id, Product2.Name, UnitPrice, Product2.Family FROM PricebookEntry WHERE Product2Id IN:prodIds]);
        
        String csMapStr = JSON.serialize(csMap);
        WorkOrderController.createWOThroughServiceContract(csMapStr);
        Test.stopTest();
        
        Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>([SELECT Id, Service_Type__c, Record_Type_Name__c, AccountId, Additional_Part_WO__c, 
                                                           (SELECT Id, WorkOrderId, UnitPrice, Quantity, PricebookEntryId, PricebookEntry.Product2Id, 
                                                            PricebookEntry.Product2.Name FROM WorkOrderLineItems), 
                                                           CaseId, ContactId, Pricebook2Id, Department__c, Department2__c, 
                                                           OwnerId, Description, Equipment_Type__c, Incident__c, NetsuiteId__c, 
                                                           POS_Register_Number__c, PO__c, Preferred_Time_IMAC__c, Priority, Problem_Type__c, 
                                                           Product_Quantity__c, Product__c, Project__c, Root_Account__c, ServiceContractId, 
                                                           Status, Approved__c, Tech_Notes__c FROM WorkOrder WHERE CaseId =: c.Id]);
        System.debug('work order size --> '+woMap.size());
        System.assert(woMap.size() == 3);
        for(WorkOrder wo : woMap.values()) {
            System.assert(wo.AccountId == testAccount.Id);
            System.assert(wo.CaseId == c.Id);
            System.assert(wo.ContactId == c.ContactId);
            System.assert(wo.Pricebook2Id == sc.Pricebook2Id);
            if(childSCMap.containsKey(wo.ServiceContractId)){
                System.assert(wo.Service_Type__c == childSCMap.get(wo.ServiceContractId).Service_Type__c);
            }
            System.assert(wo.Department__c == c.Department__c);
            System.assert(wo.Department2__c == c.Department2__c);
            System.assert(wo.OwnerId == c.OwnerId);
            System.assert(wo.Description == c.Description);
            System.assert(wo.Equipment_Type__c == c.Equipment_Type__c);
            System.assert(wo.Incident__c == c.Incident__c);
            System.assert(wo.NetsuiteId__c == 'TEST CASE');
            System.assert(wo.POS_Register_Number__c == c.POS_Register_Number__c);
            System.assert(wo.PO__c == c.PO_Number__c);
            System.assert(wo.Preferred_Time_IMAC__c == c.Preferred_Time__c);
            System.assert(wo.Priority == c.Priority);
            System.assert(wo.Problem_Type__c == c.Problem_Type__c);
            System.assert(wo.Product_Quantity__c == c.Product_Quantity__c);
            System.assert(wo.Project__c == c.Project__c);
            System.assert(wo.Root_Account__c == c.Root_Account__c);
            System.assert(wo.Status == c.Status);
            System.assert(wo.Approved__c == false);
            System.assert(wo.Tech_Notes__c == c.Tech_Notes__c);
            for(WorkOrderLineItem woli : wo.WorkOrderLineItems) {
                if(wo.Id != woli.WorkOrderId) continue;
                if(!pbeMap.containsKey(woli.PricebookEntryId)) continue;
                if(!wo.Additional_Part_WO__c) System.assert(wo.Product__c == woli.PricebookEntry.Product2Id);
                for(ContractLineItem cli : cliList) {
                    if(cli.PricebookEntryId != woli.PricebookEntryId) continue;
                    System.assert(woli.Quantity == cli.Quantity);
                    System.assert(woli.UnitPrice == cli.UnitPrice);
                }
                PricebookEntry pbe = pbeMap.get(woli.PricebookEntryId);
                for(Case_Product__c cp : cpList) {
                    if(cp.Product__c != woli.PricebookEntry.Product2Id || cp.CLI_Product__c) continue;
                    System.assert(woli.Quantity == cp.Quantity__c);
                    System.assert(woli.UnitPrice == pbe.UnitPrice);
                }
            }
        }
    }
    
    @isTest
    static void testSingleWOforNewStore() {
        Account testAccount = [SELECT Id, Root_Account__c, ShippingCountry FROM Account WHERE Name = 'test account' LIMIT 1];
        ServiceContract sc = [SELECT Id, Service_Type__c, Pricebook2Id, Single_WO_For_Billing__c, Account.Staging_Product__c, 
                              (SELECT Id, Priority__c, PricebookEntryId, Quantity, UnitPrice, Include_In_WO_Type__c FROM ContractLineItems), Priority__c 
                              FROM ServiceContract WHERE AccountId = :testAccount.Root_Account__c AND ParentServiceContractId = null
                              AND Service_Type__c = 'New Store Install' AND Single_WO_For_Billing__c = true LIMIT 1];
        List<ContractLineItem> cliList = [SELECT Id, ServiceContractId, PricebookEntryId, PricebookEntry.Product2Id, Include_In_WO_Type__c, UnitPrice, Quantity, 
                                          Number_Of_Technicians__c, Priority__c, PricebookEntry.Product2.Name FROM ContractLineItem WHERE ServiceContractId = :sc.Id];
        Map<Id, Product2> prodMap = new Map<Id, Product2>([SELECT Id, Name FROM Product2 WHERE Family = 'Hardware' AND Account_Item_Belongs_To__c = :testAccount.Root_Account__c]);
        Set<Id> prodIds = new Set<Id>();
        Set<Id> cliProdIds = new Set<Id>();
        Id removedProdId;
        for(ContractLineItem cli: cliList){
            prodIds.add(cli.PricebookEntry.Product2Id);
            cliProdIds.add(cli.PricebookEntry.Product2Id);
            if(cli.PricebookEntry.Product2.Name == 'ProdToBeRemoved'){
                removedProdId = cli.PricebookEntry.Product2Id;
            }
        } 
        
        Map<Id, ServiceContract> childSCMap = new Map<ID, ServiceContract>(sc.ChildServiceContracts);
        Test.startTest();
        Map<Id, Case> csMap = new Map<Id, Case>();
        Case c = TestDataFactory.createCase(testAccount, sc);
        c.Service_Type__c = 'New Store Install';
        c.Root_Account__c = testAccount.Root_Account__c;
        c.Include_Part__c = true;
        c.Priority = sc.Priority__c;
        c.Staging_Required_Count__c = 1;
        c.Removed_Service_Product_IDs__c = removedProdId;
        insert c;
        
        c = [SELECT Id, AccountId, Country__c, ContactId, Department__c, Department2__c, OwnerId, Description, Equipment_Type__c, 
             Incident__c, POS_Register_Number__c, PO_Number__c, Preferred_Time__c, Problem_Type__c, Product_Quantity__c, Priority,
             ProductId, Project__c, Root_Account__c, Status, Tech_Notes__c, Service_Type__c, Staging_Required_Count__c,
             ServiceContractId, Part_Receipt_Due_DateTime__c, Expected_SLA_Exit_Date__c, Removed_Service_Product_IDs__c FROM Case WHERE Id = :c.Id];
        
        csMap.put(c.Id, c);
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
        wos.Product__c = cliList[0].PricebookEntry.Product2Id;
        wos.case__c = c.Id;
        insert wos;
        Map<Id,PricebookEntry> pbeMap = new Map<Id,PricebookEntry>([SELECT Id, Product2Id, Product2.Name, UnitPrice, Product2.Family FROM PricebookEntry WHERE Product2Id IN:prodIds]);
        
        String csMapStr = JSON.serialize(csMap);
        WorkOrderController.createWOThroughServiceContract(csMapStr);
        Test.stopTest();
        
        Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>([SELECT Id, Service_Type__c, Record_Type_Name__c, AccountId, Additional_Part_WO__c, 
                                                           (SELECT Id, WorkOrderId, UnitPrice, Quantity, PricebookEntryId, PricebookEntry.Product2Id, 
                                                            PricebookEntry.Product2.Name FROM WorkOrderLineItems), 
                                                           CaseId, ContactId, Pricebook2Id, Department__c, Department2__c, 
                                                           OwnerId, Description, Equipment_Type__c, Incident__c, NetsuiteId__c, 
                                                           POS_Register_Number__c, PO__c, Preferred_Time_IMAC__c, Priority, Problem_Type__c, 
                                                           Product_Quantity__c, Product__c, Project__c, Root_Account__c, ServiceContractId, 
                                                           Status, Approved__c, Tech_Notes__c FROM WorkOrder WHERE CaseId =: c.Id]);
        
        System.assert(woMap.size() == 5);
        for(WorkOrder wo : woMap.values()) {
            System.assert(wo.AccountId == testAccount.Id);
            System.assert(wo.CaseId == c.Id);
            System.assert(wo.ContactId == c.ContactId);
            System.assert(wo.Pricebook2Id == sc.Pricebook2Id);
            if(childSCMap.containsKey(wo.ServiceContractId)){
                System.assert(wo.Service_Type__c == childSCMap.get(wo.ServiceContractId).Service_Type__c);
            }
            System.assert(wo.Department__c == c.Department__c);
            System.assert(wo.Department2__c == c.Department2__c);
            System.assert(wo.OwnerId == c.OwnerId);
            System.assert(wo.Description == c.Description);
            System.assert(wo.Equipment_Type__c == c.Equipment_Type__c);
            System.assert(wo.Incident__c == c.Incident__c);
            System.assert(wo.NetsuiteId__c == 'TEST CASE');
            System.assert(wo.POS_Register_Number__c == c.POS_Register_Number__c);
            System.assert(wo.PO__c == c.PO_Number__c);
            if(wo.Product__c == wos.Product__c){
                System.assert(wo.Preferred_Time_IMAC__c.date() == wos.Preferred_Time__c.date());
            } else {
                System.assert(wo.Preferred_Time_IMAC__c == c.Preferred_Time__c);
            }
            System.assert(wo.Priority == c.Priority);
            System.assert(wo.Problem_Type__c == c.Problem_Type__c);
            System.assert(wo.Product_Quantity__c == c.Product_Quantity__c);
            System.assert(wo.Project__c == c.Project__c);
            System.assert(wo.Root_Account__c == c.Root_Account__c);
            System.assert(wo.Status == c.Status);
            System.assert(wo.Approved__c == false);
            System.assert(wo.Tech_Notes__c == c.Tech_Notes__c);
            for(WorkOrderLineItem woli : wo.WorkOrderLineItems) {
                if(wo.Id != woli.WorkOrderId) continue;
                if(!pbeMap.containsKey(woli.PricebookEntryId)) continue;
                for(ContractLineItem cli : cliList) {
                    if(cli.PricebookEntryId != woli.PricebookEntryId) continue;
                    System.assert(woli.Quantity == cli.Quantity);
                    System.assert(woli.UnitPrice == cli.UnitPrice);
                    if(!wo.Additional_Part_WO__c && !sc.Single_WO_For_Billing__c) System.assert(wo.Product__c == woli.PricebookEntry.Product2Id);
                }
                PricebookEntry pbe = pbeMap.get(woli.PricebookEntryId);
                for(Case_Product__c cp : cpList) {
                    if(cp.Product__c != woli.PricebookEntry.Product2Id || cp.CLI_Product__c) continue;
                    System.assert(woli.Quantity == cp.Quantity__c);
                    System.assert(woli.UnitPrice == pbe.UnitPrice);
                }
            }
        }
    }
}