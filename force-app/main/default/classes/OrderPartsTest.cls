@isTest
public class OrderPartsTest {
    @isTest public static void checkForCUBCover(){
        Global_Settings__c gs = TestDataFactory.CreateGlobalSettings();
        insert gs;
        Account hwrootAcc = TestDataFactory.createAccount();
        hwrootAcc.Name = 'CUB Foods Hardware';
        hwrootAcc.Source_Key__c = '567654';
        hwrootAcc.NS_Id__c = 'abc3';
        insert hwrootAcc;
        Account rootAcc = TestDataFactory.createAccount();
        rootAcc.Name = 'CUB Foods';
        rootAcc.NS_Id__c = 'abc4';
        rootAcc.H_W_Root_Account__c = hwrootAcc.Id;
        insert rootAcc;
        
        List<Account> accList = new List<Account>();
        Account acc = TestDataFactory.createAccount();
        acc.Name = 'CUB 001';
        acc.Root_Account__c = rootAcc.Id;
        acc.Source_Key__c = '1265865';
        acc.NS_Id__c = 'abc7';
        accList.add(acc);
        insert accList;
        
        ServiceContract sc = TestDataFactory.createServiceContract(accList[0]);
       	insert sc;
        Equipment_Type__c et = new Equipment_Type__c();
        et.Name = 'CASH DRAWER - ECRS - 2181';
        et.Item_Class__c = '4500';
        et.Manufacturer_Part_Number__c = '50043690';
        insert et;
        Case cs = TestDataFactory.createCase(acc, sc);
        cs.Equipment_Type__c = et.Id;
        insert cs;
        
        WorkOrder wo = TestDataFactory.createWorkOrder(cs, sc, acc);
        wo.Equipment_Type__c = et.Id;
        wo.Root_Account__c = rootAcc.Id;
        wo.OwnerId = UserInfo.getUserId();
        wo.Street = '4801 Marlboro Pike';
        wo.City = 'Coral Hills';
        wo.State = 'MD';
        wo.Country = 'United States';
        wo.PostalCode = '20743';
        insert wo;

        wo.OwnerId = UserInfo.getUserId();
        update wo;
        
        list<Product2> prodList = new list<Product2>();
        Product2 prod = new Product2(Name = 'Test CUB Product 1',Source_Key__c = '22222', isActive =  true,Manufacturer_Part_Number__c = '50043690',
                                     Quantity__c = 1,NS_Item_Class__c = '4500',Family = 'Hardware',QuantityUnitOfMeasure = 'Each',
                                     Account_Item_Belongs_To__c = hwrootAcc.Id,No_Return_Shipment__c = true);
        Product2 prod1 = new Product2(Name = 'Test CUB Product 2',isActive =  true,Manufacturer_Part_Number__c = '50043690',
                                      Quantity__c =1,NS_Item_Class__c = '4500',Family = 'Hardware',QuantityUnitOfMeasure = 'Each',
                                      Account_Item_Belongs_To__c = hwrootAcc.Id,No_Return_Shipment__c = true);
        Product2 prod2 = new Product2(Name = 'Test CUB Product 3',Source_Key__c = '22222',isActive =  true, QuantityUnitOfMeasure = 'Each',
                                      Manufacturer_Part_Number__c = '50043690',Quantity__c =1,NS_Item_Class__c = '4500',
                                      Family = 'Hardware', Account_Item_Belongs_To__c = hwrootAcc.Id);
        
        prodList.add(prod);
        prodList.add(prod1);
        prodList.add(prod2);
        insert prodList;
        
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
        pi.QuantityUnitOfMeasure = 'Each';
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
        pi2.QuantityUnitOfMeasure = 'Each';
        piList.add(pi2);

        insert piList;

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
    	
        Test.startTest();
    	Boolean isCubFieldTech = OrderParts.checkWOOwnerId(wo.Id);
        System.assert(isCubFieldTech == true);
        List<Product2> itemClassprodlist = OrderParts.retriveItemClassProducts(wo.Id);
        System.assert(itemClassprodlist != null);
        List<Product2> allCubProdList = OrderParts.retriveAllCUBProducts(wo.Id,5);
        System.assert(allCubProdList != null);
        List<Product2> searchedProdList = OrderParts.retriveSearhedProducts('Test',wo.Id);
        System.assert(searchedProdList != null);
        String status = OrderParts.createWOLIs(prodList,wo.Id);
        System.assert(status == 'Work Order & Inventory Records Are Created Successfully!.');
        Test.stopTest();
    }
}