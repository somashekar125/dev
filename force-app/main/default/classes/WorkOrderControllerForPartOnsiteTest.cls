@isTest
private class WorkOrderControllerForPartOnsiteTest {
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
        pd1.Name = 'ServiceProduct1';
        pd1.Family = 'Service';
        productList.add(pd1);
        Product2 pd2 = TestDataFactory.createProduct2(rootAccount);
        pd2.Name = 'HardwareProduct1';
        productList.add(pd2);
        Product2 pd3 = TestDataFactory.createProduct2(rootAccount);
        pd3.Name = 'Test Stage Product1';
        pd3.Staging_Required__c = true;
        productList.add(pd3);
        Product2 pd4 = TestDataFactory.createProduct2(rootAccount);
        pd4.Name = 'ServiceProduct2';
        pd4.Family = 'Service';
        productList.add(pd4);
        Product2 pd5 = TestDataFactory.createProduct2(rootAccount);
        pd5.Name = 'HardwareProduct2';
        productList.add(pd5);
        
        
        insert productList;
        
        rootAccount.Staging_Product__c = pd3.Id;
        update rootAccount;
        
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 pricebook = new Pricebook2(Id = pricebookId, IsActive = true, Country__c = 'United States');
        update pricebook;
        
        //Create PricebookEntry
        List<PricebookEntry> pbeList = new List<PricebookEntry>();
        
        PricebookEntry pbe1 = TestDataFactory.createPricebookEntry(pd1);
        pbeList.add(pbe1);
        PricebookEntry pbe2 = TestDataFactory.createPricebookEntry(pd2);
        pbeList.add(pbe2);
        PricebookEntry pbe3 = TestDataFactory.createPricebookEntry(pd3);
        pbeList.add(pbe3);
        PricebookEntry pbe4 = TestDataFactory.createPricebookEntry(pd4);
        pbeList.add(pbe4);
        PricebookEntry pbe5 = TestDataFactory.createPricebookEntry(pd5);
        pbeList.add(pbe5);
        
        insert pbeList;
        
        //Creating perant service contracts
        List<ServiceContract> scList = new List<ServiceContract>();
        
        ServiceContract partOnsiteSC = TestDataFactory.createServiceContract(rootAccount);
        partOnsiteSC.Name = 'Part+OnsiteSC1';
        partOnsiteSC.Service_Type__c = 'Advance Exchange + Onsite';
        partOnsiteSC.AccountId = rootAccount.Id;
        partOnsiteSC.Country__c = 'United States';
        partOnsiteSC.Work_Order_Record_Type__c = 'Advance Exchange + Onsite';
        scList.add(partOnsiteSC);
        
        ServiceContract partOnsiteSC2 = TestDataFactory.createServiceContract(rootAccount);
        partOnsiteSC2.Name = 'Part+OnsiteSC2';
        partOnsiteSC2.Service_Type__c = 'Advance Exchange + Onsite';
        partOnsiteSC2.AccountId = rootAccount.Id;
        partOnsiteSC2.Country__c = 'United States';
        partOnsiteSC2.Work_Order_Record_Type__c = 'Advance Exchange + Onsite';
        partOnsiteSC2.Single_WO_For_Billing__c = true;
        scList.add(partOnsiteSC2);
        
        insert scList;
        
        
        // Create a test Service Contracts
        List<ServiceContract> scList1 = new List<ServiceContract>();
        
        ServiceContract partRequestSC = TestDataFactory.createServiceContract(rootAccount);
        partRequestSC.Name = 'PartRequesrSC';
        partRequestSC.ParentServiceContractId = partOnsiteSC.Id;
        partRequestSC.Service_Type__c = 'Advance Exchange (Depot Only)';
        partRequestSC.Number_Of_Technicians__c = 2;
        scList1.add(partRequestSC);
        ServiceContract onsiteSC = TestDataFactory.createServiceContract(rootAccount);
        onsiteSC.Name = 'OnsiteSC';
        onsiteSC.ParentServiceContractId = partOnsiteSC.Id;
        onsiteSC.Service_Type__c = 'Onsite Labor Only';
        onsiteSC.Work_Order_Record_Type__c = 'Onsite Labor';
        onsiteSC.Number_Of_Technicians__c = 2;
        scList1.add(onsiteSC);
        
        ServiceContract singleWOpartRequestSC = TestDataFactory.createServiceContract(rootAccount);
        singleWOpartRequestSC.Name = 'singleWOpartRequestSC';
        singleWOpartRequestSC.ParentServiceContractId = partOnsiteSC2.Id;
        singleWOpartRequestSC.Service_Type__c = 'Advance Exchange (Depot Only)';
        singleWOpartRequestSC.Country__c = 'Canada';
        singleWOpartRequestSC.Single_WO_For_Billing__c = true;
        singleWOpartRequestSC.Number_Of_Technicians__c = 2;
        scList1.add(singleWOpartRequestSC);
        ServiceContract singleWOforOnsiteSC = TestDataFactory.createServiceContract(rootAccount);
        singleWOforOnsiteSC.Name = 'singleWOforOnsiteSC';
        singleWOforOnsiteSC.ParentServiceContractId = partOnsiteSC2.Id;
        singleWOforOnsiteSC.Service_Type__c = 'Onsite Labor Only';
        singleWOforOnsiteSC.Work_Order_Record_Type__c = 'Onsite Labor';
        singleWOforOnsiteSC.Country__c = 'Canada';
        singleWOforOnsiteSC.Single_WO_For_Billing__c = true;
        singleWOforOnsiteSC.Number_Of_Technicians__c = 2;
        scList1.add(singleWOforOnsiteSC);
        
        ServiceContract partRequestSC1 = TestDataFactory.createServiceContract(rootAccount);
        partRequestSC1.Name = 'PartShipmentSC';
        partRequestSC1.Service_Type__c = 'Advance Exchange (Depot Only)';
        scList1.add(partRequestSC1);
        
        insert scList1;
        
        // Create Contract Line Items
        List<ContractLineItem> cliList = new List<ContractLineItem>();
        
        ContractLineItem cli1 = TestDataFactory.createContractLineItem(partRequestSC, pbe1);
        cliList.add(cli1);
        ContractLineItem cli2 = TestDataFactory.createContractLineItem(partRequestSC, pbe2);
        cliList.add(cli2);
        
        ContractLineItem cli3 = TestDataFactory.createContractLineItem(onsiteSC, pbe1);
        cli3.Priority__c = 'Severity 2';
        cliList.add(cli3);
        ContractLineItem cli4 = TestDataFactory.createContractLineItem(onsiteSC, pbe2);
        cliList.add(cli4);
        
        ContractLineItem cli5 = TestDataFactory.createContractLineItem(singleWOpartRequestSC, pbe1);
        cli5.Number_Of_Technicians__c = 2;
        cliList.add(cli5);
        ContractLineItem cli6 = TestDataFactory.createContractLineItem(singleWOpartRequestSC, pbe4);
        cli6.Number_Of_Technicians__c = 2;
        cliList.add(cli6);
        ContractLineItem cli7 = TestDataFactory.createContractLineItem(singleWOpartRequestSC, pbe5);
        cli7.Include_In_WO_Type__c = 'Part Shipment';
        cliList.add(cli7);
        
        ContractLineItem cli8 = TestDataFactory.createContractLineItem(singleWOforOnsiteSC, pbe1);
        cli8.Number_Of_Technicians__c = 2;
        cliList.add(cli8);
        ContractLineItem cli9 = TestDataFactory.createContractLineItem(singleWOforOnsiteSC, pbe4);
        cli9.Number_Of_Technicians__c = 2;
        cliList.add(cli9);
        ContractLineItem cli10 = TestDataFactory.createContractLineItem(singleWOforOnsiteSC, pbe5);
        cli10.Include_In_WO_Type__c = 'Part Shipment';
        cliList.add(cli10);
        
        insert cliList;
        Test.stopTest();
    }
    
    @isTest
    static void testCreateWOforPartRequest() {
        Account testAccount = [SELECT Id, Name, Root_Account__c, ShippingCountry FROM Account WHERE Name = 'test account' LIMIT 1];
        ServiceContract sc = [SELECT Id, Service_Type__c, Pricebook2Id, Account.Staging_Product__c
                              FROM ServiceContract WHERE AccountId = :testAccount.Root_Account__c AND Name = 'PartRequesrSC'
                              AND Service_Type__c = 'Advance Exchange (Depot Only)' AND Status = 'Active' AND Single_WO_For_Billing__c = false LIMIT 1];
        List<ContractLineItem> cliList = [SELECT Id, ServiceContractId, PricebookEntryId, PricebookEntry.Product2Id, UnitPrice, Quantity 
                                          FROM ContractLineItem WHERE ServiceContractId = :sc.Id];
        
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
        Map<Id, PricebookEntry> pbeMap = new Map<Id, PricebookEntry>([SELECT Id, Product2Id, Product2.Name, Product2.Family, 
                                                                      UnitPrice FROM PricebookEntry WHERE Product2Id IN:prodIds]);
        
        csMap.put(c.Id, c);
        String csMapStr = JSON.serialize(csMap);
        WorkOrderController.createWOThroughServiceContract(csMapStr);
        
        Test.stopTest();
        
        Id partShipId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Part_Shipment').getRecordTypeId();
        Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>([SELECT Id, AccountId, Service_Type__c, RecordTypeId, ContactId, CaseId, 
                                                           Department__c, Department2__c, Pricebook2Id, OwnerId, Description, Equipment_Type__c, 
                                                           Incident__c, NetsuiteId__c, POS_Register_Number__c, PO__c, Preferred_Time_IMAC__c, 
                                                           Priority, Problem_Type__c, Product_Quantity__c, Product__c, Project__c, Approved__c,
                                                           (SELECT Id, WorkOrderId, UnitPrice, Quantity, PricebookEntryId, PricebookEntry.Product2Id, 
                                                            PricebookEntry.Product2.Name FROM WorkOrderLineItems), 
                                                           ServiceContractId, Root_Account__c, Status, Tech_Notes__c FROM WorkOrder WHERE CaseId =: c.Id]);
        
        System.assert(woMap.size() == 1);
        
        System.assert(woMap.values()[0].Service_Type__c == 'Advance Exchange (Depot Only)');
        System.assert(woMap.values()[0].AccountId == c.AccountId);
        System.assert(woMap.values()[0].CaseId == c.Id);
        System.assert(woMap.values()[0].ContactId == c.ContactId);
        System.assert(woMap.values()[0].Pricebook2Id == sc.Pricebook2Id);
        System.assert(woMap.values()[0].RecordTypeId == partShipId);
        System.assert(woMap.values()[0].Department__c == c.Department__c);
        System.assert(woMap.values()[0].Department2__c == c.Department2__c);
        System.assert(woMap.values()[0].OwnerId == c.OwnerId);
        System.assert(woMap.values()[0].Description == c.Description);
        System.assert(woMap.values()[0].Equipment_Type__c == c.Equipment_Type__c);
        System.assert(woMap.values()[0].Incident__c == c.Incident__c);
        System.assert(woMap.values()[0].NetsuiteId__c == 'TEST CASE');
        System.assert(woMap.values()[0].POS_Register_Number__c == c.POS_Register_Number__c);
        System.assert(woMap.values()[0].PO__c == c.PO_Number__c);
        System.assert(woMap.values()[0].Preferred_Time_IMAC__c == c.Preferred_Time__c);
        System.assert(woMap.values()[0].Priority == c.Priority);
        System.assert(woMap.values()[0].Problem_Type__c == c.Problem_Type__c);
        System.assert(woMap.values()[0].Product_Quantity__c == c.Product_Quantity__c);
        System.assert(woMap.values()[0].Product__c == c.ProductId);
        System.assert(woMap.values()[0].Project__c == c.Project__c);
        System.assert(woMap.values()[0].Root_Account__c == c.Root_Account__c);
        System.assert(woMap.values()[0].ServiceContractId == sc.Id);
        System.assert(woMap.values()[0].Status == c.Status);
        System.assert(woMap.values()[0].Approved__c == false);
        System.assert(woMap.values()[0].Tech_Notes__c == c.Tech_Notes__c);
        System.assert(woMap.values()[0].Service_Type__c == sc.Service_Type__c);
        
        for(WorkOrderLineItem woli : woMap.values()[0].WorkOrderLineItems) {
            if(!pbeMap.containsKey(woli.PricebookEntryId)) continue;
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
        
        //datetime slaDatime = BusinessHours.add(c.BusinessHoursId, System.now(), 1440 * 60 * 1000);
        //System.debug('Part_Receipt_Due_DateTime__c date-> ' + c.Part_Receipt_Due_DateTime__c.date());
        //System.debug('slaDatime.date -> ' + slaDatime.date());
        //System.assert(c.Part_Receipt_Due_DateTime__c.date() == slaDatime.date());
    }
    
    @isTest
    static void testCreateWOforOnsite() {
        Account testAccount = [SELECT Id, Root_Account__c, ShippingCountry FROM Account WHERE Name = 'test account' LIMIT 1];
        ServiceContract sc = [SELECT Id, Name, Service_Type__c, Pricebook2Id, Account.Staging_Product__c, 
                              (SELECT Id, Priority__c, PricebookEntryId, Quantity, UnitPrice FROM ContractLineItems) 
                              FROM ServiceContract WHERE AccountId = :testAccount.Root_Account__c AND Name = 'OnsiteSC'
                              AND Service_Type__c = 'Onsite Labor Only' AND Single_WO_For_Billing__c = false LIMIT 1];
        List<ContractLineItem> cliList = [SELECT Id, ServiceContractId, PricebookEntryId, PricebookEntry.Product2Id, UnitPrice, Quantity 
                                          FROM ContractLineItem WHERE ServiceContractId = :sc.Id];
        Map<Id, Product2> prodMap = new Map<Id, Product2>([SELECT Id, Name FROM Product2 WHERE Family = 'Hardware' AND Account_Item_Belongs_To__c = :testAccount.Root_Account__c]);
        Set<Id> prodIds = new Set<Id>();
        Set<Id> cliProdIds = new Set<Id>();
        for(ContractLineItem cli: cliList){
            prodIds.add(cli.PricebookEntry.Product2Id);
            cliProdIds.add(cli.PricebookEntry.Product2Id);
        } 
        
        Map<Id, ServiceContract> childSCMap = new Map<ID, ServiceContract>(sc.ChildServiceContracts);
        Test.startTest();
        Map<Id, Case> csMap = new Map<Id, Case>();
        Case c = TestDataFactory.createCase(testAccount, sc);
        c.Service_Type__c = 'Onsite Labor Only';
        c.Root_Account__c = testAccount.Root_Account__c;
        c.Include_Part__c = true;
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
        
        Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>([SELECT Id, Service_Type__c, Record_Type_Name__c, AccountId, 
                                                           (SELECT Id, WorkOrderId, UnitPrice, Quantity, PricebookEntryId, PricebookEntry.Product2Id, 
                                                            PricebookEntry.Product2.Name FROM WorkOrderLineItems), 
                                                           CaseId, ContactId, Pricebook2Id, Department__c, Department2__c, 
                                                           OwnerId, Description, Equipment_Type__c, Incident__c, NetsuiteId__c, 
                                                           POS_Register_Number__c, PO__c, Preferred_Time_IMAC__c, Priority, Problem_Type__c, 
                                                           Product_Quantity__c, Product__c, Project__c, Root_Account__c, ServiceContractId, 
                                                           Status, Approved__c, Tech_Notes__c FROM WorkOrder WHERE CaseId =: c.Id]);
        
        System.assert(woMap.size() == 2);
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
            System.assert(wo.Priority == 'Severity 2');
            System.assert(wo.Problem_Type__c == c.Problem_Type__c);
            System.assert(wo.Product_Quantity__c == c.Product_Quantity__c);
            System.assert(wo.Product__c == c.ProductId);
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
    static void testCreateWOforPartOnsite() {
        Account testAccount = [SELECT Id, Root_Account__c, ShippingCountry FROM Account WHERE Name = 'test account' LIMIT 1];
        ServiceContract sc = [SELECT Id, Service_Type__c, Pricebook2Id, Account.Staging_Product__c, 
                              (SELECT Id, Service_Type__c FROM ChildServiceContracts) 
                              FROM ServiceContract WHERE AccountId = :testAccount.Root_Account__c 
                              AND Service_Type__c = 'Advance Exchange + Onsite' AND Single_WO_For_Billing__c = false LIMIT 1];
        Map<Id, ServiceContract> childSCMap = new Map<ID, ServiceContract>(sc.ChildServiceContracts);
        List<ContractLineItem> cliList = [SELECT Id, ServiceContractId, PricebookEntryId, PricebookEntry.Product2Id, UnitPrice, Quantity 
                                          FROM ContractLineItem WHERE ServiceContractId = :sc.Id OR ServiceContract.ParentServiceContractId = :sc.Id];
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
        c.Service_Type__c = 'Advance Exchange + Onsite';
        c.Root_Account__c = testAccount.Root_Account__c;
        c.Create_Work_Order__c = false;
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
        Map<Id,PricebookEntry> pbeMap = new Map<Id,PricebookEntry>([SELECT Id, Product2Id, Product2.Name, Product2.Family, UnitPrice FROM PricebookEntry WHERE Product2Id IN:prodIds]);
        String csMapStr = JSON.serialize(csMap);
        WorkOrderController.createWOThroughServiceContract(csMapStr);
        Test.stopTest();
        
        Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>([SELECT Id, Service_Type__c, Record_Type_Name__c, AccountId, 
                                                           (SELECT Id, UnitPrice, Quantity, PricebookEntryId, 
                                                            PricebookEntry.Product2Id FROM WorkOrderLineItems), 
                                                           CaseId, ContactId, Pricebook2Id, Department__c, Department2__c, 
                                                           OwnerId, Description, Equipment_Type__c, Incident__c, NetsuiteId__c, 
                                                           POS_Register_Number__c, PO__c, Preferred_Time_IMAC__c, Priority, Problem_Type__c, 
                                                           Product_Quantity__c, Product__c, Project__c, Root_Account__c, ServiceContractId, 
                                                           Status, Approved__c, Tech_Notes__c FROM WorkOrder WHERE CaseId =: c.Id]);
        
        //System.assert(woMap.size() == 4);
        System.debug('woMap size --> '+woMap.size());
        for(WorkOrder wo: woMap.values()) {
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
            System.assert(wo.Product__c == c.ProductId);
            System.assert(wo.Project__c == c.Project__c);
            System.assert(wo.Root_Account__c == c.Root_Account__c);
            System.assert(wo.Status == c.Status);
            System.assert(wo.Approved__c == false);
            System.assert(wo.Tech_Notes__c == c.Tech_Notes__c);
            
            for(WorkOrderLineItem woli : wo.WorkOrderLineItems) {
                if(!pbeMap.containsKey(woli.PricebookEntryId)) continue;
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
    static void testCreateWOforPartRequest2() {
        Account testAccount = [SELECT Id, Root_Account__c, ShippingCountry FROM Account WHERE Name = 'test account' LIMIT 1];
        ServiceContract sc = [SELECT Id, Service_Type__c, Pricebook2Id, Account.Staging_Product__c
                              FROM ServiceContract WHERE AccountId = :testAccount.Root_Account__c 
                              AND Service_Type__c = 'Advance Exchange (Depot Only)' AND Status = 'Active' AND Single_WO_For_Billing__c = true LIMIT 1];
        List<ContractLineItem> cliList = [SELECT Id, ServiceContractId, PricebookEntryId, PricebookEntry.Product2Id, UnitPrice, Quantity 
                                          FROM ContractLineItem WHERE ServiceContractId = :sc.Id];
        
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
        
        Map<Id, PricebookEntry> pbeMap = new Map<Id, PricebookEntry>([SELECT Id, Product2Id, Product2.Name, Product2.Family, 
                                                                      UnitPrice FROM PricebookEntry WHERE Product2Id IN:prodIds]);
        
        csMap.put(c.Id, c);
        String csMapStr = JSON.serialize(csMap);
        WorkOrderController.createWOThroughServiceContract(csMapStr);
        
        Test.stopTest();
        
        Id partShipId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Part_Shipment').getRecordTypeId();
        Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>([SELECT Id, AccountId, Service_Type__c, RecordTypeId, ContactId, CaseId, 
                                                           Department__c, Department2__c, Pricebook2Id, OwnerId, Description, Equipment_Type__c, 
                                                           Incident__c, NetsuiteId__c, POS_Register_Number__c, PO__c, Preferred_Time_IMAC__c, 
                                                           Priority, Problem_Type__c, Product_Quantity__c, Product__c, Project__c, Approved__c,
                                                           (SELECT Id, WorkOrderId, UnitPrice, Quantity, PricebookEntryId, PricebookEntry.Product2Id, 
                                                            PricebookEntry.Product2.Name FROM WorkOrderLineItems), 
                                                           ServiceContractId, Root_Account__c, Status, Tech_Notes__c FROM WorkOrder WHERE CaseId =: c.Id]);
        
        System.assert(woMap.size() == 2);
        System.debug('woMap.size() --> ' + woMap.size());
        System.assert(woMap.values()[0].Service_Type__c == 'Advance Exchange (Depot Only)');
        System.assert(woMap.values()[0].AccountId == c.AccountId);
        System.assert(woMap.values()[0].CaseId == c.Id);
        System.assert(woMap.values()[0].ContactId == c.ContactId);
        System.assert(woMap.values()[0].Pricebook2Id == sc.Pricebook2Id);
        System.assert(woMap.values()[0].RecordTypeId == partShipId);
        System.assert(woMap.values()[0].Department__c == c.Department__c);
        System.assert(woMap.values()[0].Department2__c == c.Department2__c);
        System.assert(woMap.values()[0].OwnerId == c.OwnerId);
        System.assert(woMap.values()[0].Description == c.Description);
        System.assert(woMap.values()[0].Equipment_Type__c == c.Equipment_Type__c);
        System.assert(woMap.values()[0].Incident__c == c.Incident__c);
        System.assert(woMap.values()[0].NetsuiteId__c == 'TEST CASE');
        System.assert(woMap.values()[0].POS_Register_Number__c == c.POS_Register_Number__c);
        System.assert(woMap.values()[0].PO__c == c.PO_Number__c);
        System.assert(woMap.values()[0].Preferred_Time_IMAC__c == c.Preferred_Time__c);
        System.assert(woMap.values()[0].Priority == c.Priority);
        System.assert(woMap.values()[0].Problem_Type__c == c.Problem_Type__c);
        System.assert(woMap.values()[0].Product_Quantity__c == c.Product_Quantity__c);
        System.assert(woMap.values()[0].Product__c == c.ProductId);
        System.assert(woMap.values()[0].Project__c == c.Project__c);
        System.assert(woMap.values()[0].Root_Account__c == c.Root_Account__c);
        System.assert(woMap.values()[0].ServiceContractId == sc.Id);
        System.assert(woMap.values()[0].Status == c.Status);
        System.assert(woMap.values()[0].Approved__c == false);
        System.assert(woMap.values()[0].Tech_Notes__c == c.Tech_Notes__c);
        System.assert(woMap.values()[0].Service_Type__c == sc.Service_Type__c);
        
        for(WorkOrderLineItem woli : woMap.values()[0].WorkOrderLineItems) {
            if(!pbeMap.containsKey(woli.PricebookEntryId)) continue;
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
    
    @isTest
    static void testCreateWOforOnsite2() {
        Account testAccount = [SELECT Id, Root_Account__c, ShippingCountry FROM Account WHERE Name = 'test account' LIMIT 1];
        ServiceContract sc = [SELECT Id, Name, Service_Type__c, Pricebook2Id, Account.Staging_Product__c, 
                              (SELECT Id, Priority__c, PricebookEntryId, Quantity, UnitPrice FROM ContractLineItems) 
                              FROM ServiceContract WHERE AccountId = :testAccount.Root_Account__c AND Name = 'singleWOforOnsiteSC'
                              AND Service_Type__c = 'Onsite Labor Only' AND Single_WO_For_Billing__c = true LIMIT 1];
        List<ContractLineItem> cliList = [SELECT Id, ServiceContractId, PricebookEntryId, PricebookEntry.Product2Id, UnitPrice, Quantity 
                                          FROM ContractLineItem WHERE ServiceContractId = :sc.Id];
        Map<Id, Product2> prodMap = new Map<Id, Product2>([SELECT Id, Name FROM Product2 WHERE Family = 'Hardware' AND Account_Item_Belongs_To__c = :testAccount.Root_Account__c]);
        Set<Id> prodIds = new Set<Id>();
        Set<Id> cliProdIds = new Set<Id>();
        for(ContractLineItem cli: cliList){
            prodIds.add(cli.PricebookEntry.Product2Id);
            cliProdIds.add(cli.PricebookEntry.Product2Id);
        } 
        
        Map<Id, ServiceContract> childSCMap = new Map<ID, ServiceContract>(sc.ChildServiceContracts);
        Test.startTest();
        Map<Id, Case> csMap = new Map<Id, Case>();
        Case c = TestDataFactory.createCase(testAccount, sc);
        c.Service_Type__c = 'Onsite Labor Only';
        c.Root_Account__c = testAccount.Root_Account__c;
        c.Include_Part__c = true;
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
        
        Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>([SELECT Id, Service_Type__c, Record_Type_Name__c, AccountId, 
                                                           (SELECT Id, WorkOrderId, UnitPrice, Quantity, PricebookEntryId, PricebookEntry.Product2Id, 
                                                            PricebookEntry.Product2.Name FROM WorkOrderLineItems), 
                                                           CaseId, ContactId, Pricebook2Id, Department__c, Department2__c, 
                                                           OwnerId, Description, Equipment_Type__c, Incident__c, NetsuiteId__c, 
                                                           POS_Register_Number__c, PO__c, Preferred_Time_IMAC__c, Priority, Problem_Type__c, 
                                                           Product_Quantity__c, Product__c, Project__c, Root_Account__c, ServiceContractId, 
                                                           Status, Approved__c, Tech_Notes__c FROM WorkOrder WHERE CaseId =: c.Id]);
        
        //System.assert(woMap.size() == 2);
        System.debug('woMap size --> '+ woMap.size());
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
            System.assert(wo.Priority == 'Severity 2');
            System.assert(wo.Problem_Type__c == c.Problem_Type__c);
            System.assert(wo.Product_Quantity__c == c.Product_Quantity__c);
            System.assert(wo.Product__c == c.ProductId);
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
    static void testCreateWOforPartOnsite2() {
        Account testAccount = [SELECT Id, Root_Account__c, ShippingCountry FROM Account WHERE Name = 'test account' LIMIT 1];
        ServiceContract sc = [SELECT Id, Service_Type__c, Pricebook2Id, Account.Staging_Product__c, 
                              (SELECT Id, Service_Type__c FROM ChildServiceContracts) 
                              FROM ServiceContract WHERE AccountId = :testAccount.Root_Account__c
                              AND Service_Type__c = 'Advance Exchange + Onsite' AND Single_WO_For_Billing__c = true LIMIT 1];
        Map<Id, ServiceContract> childSCMap = new Map<ID, ServiceContract>(sc.ChildServiceContracts);
        List<ContractLineItem> cliList = [SELECT Id, ServiceContractId, PricebookEntryId, PricebookEntry.Product2Id, UnitPrice, Quantity 
                                          FROM ContractLineItem WHERE ServiceContractId = :sc.Id OR ServiceContract.ParentServiceContractId = :sc.Id];
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
        c.Service_Type__c = 'Advance Exchange + Onsite';
        c.Root_Account__c = testAccount.Root_Account__c;
        c.Create_Work_Order__c = false;
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
        Map<Id,PricebookEntry> pbeMap = new Map<Id,PricebookEntry>([SELECT Id, Product2Id, Product2.Name, Product2.Family, UnitPrice FROM PricebookEntry WHERE Product2Id IN:prodIds]);
        String csMapStr = JSON.serialize(csMap);
        WorkOrderController.createWOThroughServiceContract(csMapStr);
        Test.stopTest();
        
        Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>([SELECT Id, Service_Type__c, Record_Type_Name__c, AccountId, 
                                                           (SELECT Id, UnitPrice, Quantity, PricebookEntryId, 
                                                            PricebookEntry.Product2Id FROM WorkOrderLineItems), 
                                                           CaseId, ContactId, Pricebook2Id, Department__c, Department2__c, 
                                                           OwnerId, Description, Equipment_Type__c, Incident__c, NetsuiteId__c, 
                                                           POS_Register_Number__c, PO__c, Preferred_Time_IMAC__c, Priority, Problem_Type__c, 
                                                           Product_Quantity__c, Product__c, Project__c, Root_Account__c, ServiceContractId, 
                                                           Status, Approved__c, Tech_Notes__c FROM WorkOrder WHERE CaseId =: c.Id]);
        
        System.assert(woMap.size() == 3);
        for(WorkOrder wo: woMap.values()) {
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
            System.assert(wo.Product__c == c.ProductId);
            System.assert(wo.Project__c == c.Project__c);
            System.assert(wo.Root_Account__c == c.Root_Account__c);
            System.assert(wo.Status == c.Status);
            System.assert(wo.Approved__c == false);
            System.assert(wo.Tech_Notes__c == c.Tech_Notes__c);
            
            for(WorkOrderLineItem woli : wo.WorkOrderLineItems) {
                if(!pbeMap.containsKey(woli.PricebookEntryId)) continue;
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
    static void testCreateWOforPartRequestNoCLI() {
        Account testAccount = [SELECT Id, Root_Account__c, ShippingCountry FROM Account WHERE Name = 'test account' LIMIT 1];
        ServiceContract sc = [SELECT Id, Name, Service_Type__c, Pricebook2Id, Account.Staging_Product__c
                              FROM ServiceContract WHERE AccountId = :testAccount.Root_Account__c 
                              AND Name = 'PartShipmentSC' LIMIT 1];
        
        Map<Id, Product2> prodMap = new Map<Id, Product2>([SELECT Id, Name FROM Product2 WHERE Family = 'Hardware' AND Account_Item_Belongs_To__c = :testAccount.Root_Account__c]);
        
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
            cpList.add(cp);
        }
        insert cpList;
        Map<Id, PricebookEntry> pbeMap = new Map<Id, PricebookEntry>([SELECT Id, Product2Id, Product2.Name, Product2.Family, 
                                                                      UnitPrice FROM PricebookEntry WHERE Product2Id IN:prodMap.keySet()]);
        
        csMap.put(c.Id, c);
        String csMapStr = JSON.serialize(csMap);
        WorkOrderController.createWOThroughServiceContract(csMapStr);
        
        Test.stopTest();
        
        Id partShipId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Part_Shipment').getRecordTypeId();
        Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>([SELECT Id, AccountId, Service_Type__c, RecordTypeId, ContactId, CaseId, 
                                                           Department__c, Department2__c, Pricebook2Id, OwnerId, Description, Equipment_Type__c, 
                                                           Incident__c, NetsuiteId__c, POS_Register_Number__c, PO__c, Preferred_Time_IMAC__c, 
                                                           Priority, Problem_Type__c, Product_Quantity__c, Product__c, Project__c, Approved__c,
                                                           (SELECT Id, WorkOrderId, UnitPrice, Quantity, PricebookEntryId, PricebookEntry.Product2Id, 
                                                            PricebookEntry.Product2.Name FROM WorkOrderLineItems), 
                                                           ServiceContractId, Root_Account__c, Status, Tech_Notes__c FROM WorkOrder WHERE CaseId =: c.Id]);
        
        System.assert(woMap.size() == 1);
        
        System.assert(woMap.values()[0].Service_Type__c == 'Advance Exchange (Depot Only)');
        System.assert(woMap.values()[0].AccountId == c.AccountId);
        System.assert(woMap.values()[0].CaseId == c.Id);
        System.assert(woMap.values()[0].ContactId == c.ContactId);
        System.assert(woMap.values()[0].Pricebook2Id == sc.Pricebook2Id);
        System.assert(woMap.values()[0].RecordTypeId == partShipId);
        System.assert(woMap.values()[0].Department__c == c.Department__c);
        System.assert(woMap.values()[0].Department2__c == c.Department2__c);
        System.assert(woMap.values()[0].OwnerId == c.OwnerId);
        System.assert(woMap.values()[0].Description == c.Description);
        System.assert(woMap.values()[0].Equipment_Type__c == c.Equipment_Type__c);
        System.assert(woMap.values()[0].Incident__c == c.Incident__c);
        System.assert(woMap.values()[0].NetsuiteId__c == 'TEST CASE');
        System.assert(woMap.values()[0].POS_Register_Number__c == c.POS_Register_Number__c);
        System.assert(woMap.values()[0].PO__c == c.PO_Number__c);
        System.assert(woMap.values()[0].Preferred_Time_IMAC__c == c.Preferred_Time__c);
        System.assert(woMap.values()[0].Priority == c.Priority);
        System.assert(woMap.values()[0].Problem_Type__c == c.Problem_Type__c);
        System.assert(woMap.values()[0].Product_Quantity__c == c.Product_Quantity__c);
        System.assert(woMap.values()[0].Product__c == c.ProductId);
        System.assert(woMap.values()[0].Project__c == c.Project__c);
        System.assert(woMap.values()[0].Root_Account__c == c.Root_Account__c);
        System.assert(woMap.values()[0].ServiceContractId == sc.Id);
        System.assert(woMap.values()[0].Status == c.Status);
        System.assert(woMap.values()[0].Approved__c == false);
        System.assert(woMap.values()[0].Tech_Notes__c == c.Tech_Notes__c);
        System.assert(woMap.values()[0].Service_Type__c == sc.Service_Type__c);
        
        for(WorkOrderLineItem woli : woMap.values()[0].WorkOrderLineItems) {
            if(!pbeMap.containsKey(woli.PricebookEntryId)) continue;
            PricebookEntry pbe = pbeMap.get(woli.PricebookEntryId);
            for(Case_Product__c cp : cpList) {
                if(cp.Product__c != woli.PricebookEntry.Product2Id || cp.CLI_Product__c) continue;
                System.assert(woli.Quantity == cp.Quantity__c);
                System.assert(woli.UnitPrice == pbe.UnitPrice);
            }
        }
    }  
    
}