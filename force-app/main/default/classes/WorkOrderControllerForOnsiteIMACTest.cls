@isTest
private class WorkOrderControllerForOnsiteIMACTest {

    @testSetup
    static void setup() {
        Test.startTest();
        Account rootAccount = TestDataFactory.createAccount();
        rootAccount.Name = 'RootAccount1';
       
        insert rootAccount;
        
        Account acc = TestDataFactory.createAccount();
        acc.ShippingCountry = 'United States';
        acc.Root_Account__c = rootAccount.Id;
        acc.Source_Key__c = '1254';
       
        insert acc;
        
        // Create a test Products
        List<Product2> productList = new List<Product2>();
        
        Product2 srvcpd1 = TestDataFactory.createProduct2(rootAccount);
        srvcpd1.Name = 'ServiceProduct1';
        srvcpd1.Family = 'Service';
        productList.add(srvcpd1);
        Product2 srvcpd2 = TestDataFactory.createProduct2(rootAccount);
        srvcpd2.Name = 'ServiceProduct2';
        srvcpd2.Family = 'Service';
        productList.add(srvcpd2);
        Product2 hwpd1 = TestDataFactory.createProduct2(rootAccount);
        hwpd1.Name = 'HardwareProduct1';
        productList.add(hwpd1);
        Product2 stagepd = TestDataFactory.createProduct2(rootAccount);
        stagepd.Name = 'Test Stage Product';
        stagepd.Family = 'Hardware';
        stagepd.Staging_Required__c = true;
        productList.add(stagepd);

        insert productList;

        rootAccount.Staging_Product__c = stagepd.Id;
        update rootAccount;

        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 Pricebook2 = new Pricebook2(Id = pricebookId, IsActive = true, Country__c = 'United States');
        update Pricebook2;

        //Create PricebookEntry
        List<PricebookEntry> pbeList = new List<PricebookEntry>();
        
        PricebookEntry pbe1 = TestDataFactory.createPricebookEntry(srvcpd1);
        pbeList.add(pbe1);
        PricebookEntry pbe2 = TestDataFactory.createPricebookEntry(srvcpd2);
        pbeList.add(pbe2);
        PricebookEntry pbe3 = TestDataFactory.createPricebookEntry(hwpd1);
        pbeList.add(pbe3);
        PricebookEntry pbe4 = TestDataFactory.createPricebookEntry(stagepd);
        pbeList.add(pbe4);

        insert pbeList;

        //creating service contract
        ServiceContract onsiteIMACsc = TestDataFactory.createServiceContract(rootAccount);
        onsiteIMACsc.Service_Type__c = 'Onsite IMAC';
        onsiteIMACsc.Work_Order_Record_Type__c = 'Onsite Labor';
        onsiteIMACsc.Country__c = 'Canada';
        onsiteIMACsc.Number_Of_Technicians__c = 2;

        insert onsiteIMACsc;

        //createin ContractLineItems
        List<ContractLineItem> cliList = new List<ContractLineItem>();
        
        ContractLineItem cli1 = TestDataFactory.createContractLineItem(onsiteIMACsc, pbe1);
        cli1.Applicable_If_IMAC_Due_Hours_Exceeding__c = 72;
        cli1.Number_Of_Technicians__c = 2;
        cliList.add(cli1);
        ContractLineItem cli2 = TestDataFactory.createContractLineItem(onsiteIMACsc, pbe2);
        cli2.Applicable_If_IMAC_Due_Hours_Within__c = 72;
        cli2.Number_Of_Technicians__c = 2;
        cliList.add(cli2);
        ContractLineItem cli3 = TestDataFactory.createContractLineItem(onsiteIMACsc, pbe3);
        cli3.Include_In_WO_Type__c = 'Part Shipment';
        cliList.add(cli3);

        insert cliList;
        Test.stopTest();
    }

    @isTest
    static void testCreateWOforOnsiteIMAC1() {
        Account testAccount = [SELECT Id, Root_Account__c, ShippingCountry FROM Account WHERE Name = 'test account' LIMIT 1];
        ServiceContract sc = [SELECT Id, Service_Type__c, Pricebook2Id, Account.Staging_Product__c, 
                              (SELECT Id, Priority__c, PricebookEntryId, Quantity, UnitPrice FROM ContractLineItems) 
                              FROM ServiceContract WHERE AccountId = :testAccount.Root_Account__c 
                              AND Service_Type__c = 'Onsite IMAC' LIMIT 1];
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
        c.Service_Type__c = 'Onsite IMAC';
        c.Root_Account__c = testAccount.Root_Account__c;
        c.Include_Part__c = true;
        c.Preferred_Time__c = System.now().addDays(4);
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
    static void testCreateWOforOnsiteIMAC2() {
        Account testAccount = [SELECT Id, Root_Account__c, ShippingCountry FROM Account WHERE Name = 'test account' LIMIT 1];
        ServiceContract sc = [SELECT Id, Service_Type__c, Pricebook2Id, Account.Staging_Product__c, 
                              (SELECT Id, Priority__c, PricebookEntryId, Quantity, UnitPrice FROM ContractLineItems) 
                              FROM ServiceContract WHERE AccountId = :testAccount.Root_Account__c 
                              AND Service_Type__c = 'Onsite IMAC' LIMIT 1];
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
        c.Service_Type__c = 'Onsite IMAC';
        c.Root_Account__c = testAccount.Root_Account__c;
        c.Include_Part__c = true;
        c.Preferred_Time__c = System.now().addDays(2);
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
}