@isTest
public class ProductsConsumedTest {
    @IsTest static void covergetOpenOnsiteWOs(){
        Global_Settings__c gs = TestDataFactory.CreateGlobalSettings();
        insert gs;
        Account hwrootAcc = TestDataFactory.createAccount();
        hwrootAcc.Name = 'CUB Foods Hardware';
        hwrootAcc.Source_Key__c = '567654';
        hwrootAcc.NS_Id__c = 'abc1';
        insert hwrootAcc;
        Account rootAcc = TestDataFactory.createAccount();
        rootAcc.Name = 'CUB Foods';
        rootAcc.NS_Id__c = 'abc2';
        rootAcc.H_W_Root_Account__c = hwrootAcc.Id;
        insert rootAcc;
        Account acc = TestDataFactory.createAccount();
        acc.Name = 'CUB 001';
        acc.Source_Key__c = '1261865';
        acc.NS_Id__c = 'abc8';
        insert acc;
        
        ServiceContract sc = TestDataFactory.createServiceContract(rootAcc);
        insert sc;
        Case cs = TestDataFactory.createCase(acc, sc);
        cs.Service_Type__c = 'Onsite Labor Only';
        cs.Root_Account__c = rootAcc.Id;
        insert cs;
        List<WorkOrder> woList = new List<WorkOrder>();
        Id OnsiteRtId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Onsite_Labor').getRecordTypeId();
        WorkOrder wo = TestDataFactory.createWorkOrder(cs, sc, acc);
        wo.Root_Account__c = rootAcc.Id;
        wo.Service_Type__c = 'Onsite Labor Only';
        wo.RecordTypeId = OnsiteRtId;
        wo.OwnerId = UserInfo.getUserId();
        woList.add(wo);
        WorkOrder wo2 = TestDataFactory.createWorkOrder(cs, sc, acc);
        wo2.Root_Account__c = rootAcc.Id;
        wo2.OrderedPartWO__c = true;
        wo2.OwnerId = UserInfo.getUserId();
        woList.add(wo2);
        insert woList;
        
        list<Product2> prodList = new list<Product2>();
        Product2 prod = new Product2(Name = 'Test CUB Product 1',Source_Key__c = '22222', isActive =  true,Manufacturer_Part_Number__c = '50043690',
                                     Quantity__c = 1,NS_Item_Class__c = '4500',Family = 'Hardware',
                                     Account_Item_Belongs_To__c = hwrootAcc.Id,No_Return_Shipment__c = true);
        Product2 prod1 = new Product2(Name = 'Test CUB Product 2',isActive =  true,Manufacturer_Part_Number__c = '50043690',
                                      Quantity__c =1,NS_Item_Class__c = '4500',Family = 'Hardware',
                                      Account_Item_Belongs_To__c = hwrootAcc.Id,No_Return_Shipment__c = true);
        Product2 prod2 = new Product2(Name = 'Test CUB Product 3',Source_Key__c = '22222',isActive =  true, 
                                      Manufacturer_Part_Number__c = '50043690',Quantity__c =1,NS_Item_Class__c = '4500',
                                      Family = 'Hardware', Account_Item_Belongs_To__c = hwrootAcc.Id);
        
        prodList.add(prod);
        prodList.add(prod1);
        prodList.add(prod2);
        insert prodList;
        
        Id pricebookId = Test.getStandardPricebookId();
        list<PricebookEntry> pbeList = new list<PricebookEntry>();
        PricebookEntry standardPrice = TestDataFactory.createPricebookEntry(prodList[0]);
        PricebookEntry standardPrice1 = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prodList[1].Id,
            UnitPrice = 10000, IsActive = true);
        PricebookEntry standardPrice2 = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prodList[2].Id,
            UnitPrice = 10000, IsActive = true);
        pbeList.add(standardPrice);
        pbeList.add(standardPrice1);
        pbeList.add(standardPrice2);
        insert pbeList;
        
        List<WorkOrderlineItem> woliList = new List<WorkOrderlineItem>();
        WorkOrderlineItem woli = new WorkOrderlineItem();
        woli.PricebookEntryId = pbeList[0].Id;
        woli.Quantity = 2;
        woli.UnitPrice = 2;
        woli.WorkOrderId = wo2.Id;
        woliList.add(woli);
        insert woliList;
        
        List<Schema.Location> locList = new List<Schema.Location>();
        Schema.Location loc = new Schema.Location();
        loc.Name = 'IWCR Warehouse';
        loc.LocationType = 'Warehouse';
        loc.IsMobile = true;
        loc.IsInventoryLocation = true;
        locList.add(loc);

        Schema.Location loc2 = new Schema.Location();
        loc2.Name = 'Cub Hub';
        loc2.LocationType = 'Site';
        loc2.IsMobile = true;
        loc2.OwnerId = UserInfo.getUserId();
        loc2.IsInventoryLocation = true;
        locList.add(loc2);

        Schema.Location loc3 = new Schema.Location();
        loc3.Name = 'Cub Van';
        loc3.LocationType = 'Van';
        loc3.IsMobile = true;
        loc3.IsInventoryLocation = true;
        locList.add(loc3);
        insert locList;
        
        ServiceResource sr = new ServiceResource();
        sr.Name = 'Field Tech 1';
        sr.IsActive = true;
        sr.ResourceType = 'T';
        sr.LocationId = loc3.Id;
        sr.RelatedRecordId = UserInfo.getUserId();
        insert sr;
        
        List<ProductItem> piList = new List<ProductItem>();
        ProductItem pi = new ProductItem();
        pi.LocationId = loc.Id;
        pi.Product2Id = prod.Id;
        pi.QuantityOnHand = 50;
        piList.add(pi);

        ProductItem pi1 = new ProductItem();
        pi1.LocationId = loc2.Id;
        pi1.Product2Id = prod1.Id;
        pi1.QuantityOnHand = 50;
        piList.add(pi1);

        ProductItem pi2 = new ProductItem();
        pi2.LocationId = loc3.Id;
        pi2.Product2Id = prod2.Id;
        pi2.QuantityOnHand = 50;
        piList.add(pi2);
        insert piList;
        
        Test.startTest();
        Boolean ownerIdCheck = ProductsConsumed.checkWOOwnerId(wo.Id);
        System.assert(ownerIdCheck == false);
        WorkOrder woRec = ProductsConsumed.retrieveWorkOrder(wo.Id);
        System.assert(woRec != null);
        List<WorkOrder> woListCheck = ProductsConsumed.getOpenOnsiteWOs();
        System.assert(woListCheck != null);
        List<WorkOrderlineItem> woliListCheck = ProductsConsumed.getWOLIs(wo);
        System.assert(woliListCheck != null);
        /*Boolean hasConsumpitonWO = ProductsConsumed.checkForConsumptionWO(cs.Id);
        System.assert(hasConsumpitonWO == false);*/
        List<ProductItem> piListCheck = ProductsConsumed.getVanStock(wo);
        System.assert(piListCheck != null);
        List<WorkOrder> searchedWOs = ProductsConsumed.retriveSearhedWOs('00');
        System.assert(searchedWOs != null);
        List<ProductItem> piListCheck2= ProductsConsumed.retriveSearhedProducts('Test',wo);
        System.assert(piListCheck2 != null);
        ProductsConsumed.consumeProducts(wo2, woliList, piList);
        List<Schema.ProductConsumed> pcList = [SELECT Id FROM ProductConsumed WHERE WorkOrderId=: wo2.Id];
        System.assert(pcList != null);
        /*ProductsConsumed.markingWOReadyForInvoice(cs.Id);
        List<WorkOrder> invoiceReadyWO = [SELECT Id,NetsuiteId__c,Ready_For_Invoice__c,CaseId FROM WorkOrder WHERE CaseId =:caseId 
                                  AND ConsumptionPartWO__c = true AND Ready_For_Invoice__c = true LIMIT 1];
       	System.assert(invoiceReadyWO != null);*/
        
        
        Test.stopTest();
    }
}