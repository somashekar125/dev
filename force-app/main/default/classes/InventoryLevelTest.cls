@isTest
public class InventoryLevelTest {
    @isTest public static void getInventoryProductsCover(){
        Account hwrootAcc = TestDataFactory.createAccount();
        hwrootAcc.Name = 'CUB Foods Hardware';
        hwrootAcc.Source_Key__c = '567654';
        hwrootAcc.NS_Id__c = 'abc5';
        insert hwrootAcc;
        Account rootAcc = TestDataFactory.createAccount();
        rootAcc.Name = 'CUB Foods';
        rootAcc.NS_Id__c = 'abc6';
        rootAcc.H_W_Root_Account__c = hwrootAcc.Id;
        insert rootAcc;
        
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
        List<PricebookEntry> pbeList = new list<PricebookEntry>();
        PricebookEntry standardPrice = TestDataFactory.createPricebookEntry(prodList[0]);
        PricebookEntry standardPrice1 = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prodList[1].Id,
            UnitPrice = 100, IsActive = true);
        PricebookEntry standardPrice2 = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prodList[2].Id,
            UnitPrice = 100, IsActive = true);
        
        pbeList.add(standardPrice);
        pbeList.add(standardPrice1);
        pbeList.add(standardPrice2);
        insert pbeList;
        
        List<Schema.Location> locList = new List<Schema.Location>();
        Schema.Location loc = new Schema.Location();
        loc.Name = 'IWCR Warehouse';
        loc.LocationType = 'Warehouse';
        loc.IsMobile = true;
        loc.IsInventoryLocation = true;
        locList.add(loc);

        Schema.Location loc2 = new Schema.Location();
        loc2.Name = 'Cub Van';
        loc2.LocationType = 'Van';
        loc2.IsMobile = true;
        loc2.IsInventoryLocation = true;
        locList.add(loc2);
        insert locList;
        
        ServiceResource sr = new ServiceResource();
        sr.Name = 'Field Tech 1';
        sr.IsActive = true;
        sr.ResourceType = 'T';
        sr.LocationId = loc2.Id;
        sr.RelatedRecordId = UserInfo.getUserId();
        insert sr;
        
        Account acc = new Account();
        acc.Source_Key__c = '564738';
        acc.Name = 'Field Tech 1 Vanstock';
        acc.NS_Id__c = 'abc4';
        insert acc;
        
        List<ProductItem> piList = new List<ProductItem>();
        ProductItem pi = new ProductItem();
        pi.LocationId = loc.Id;
        pi.Product2Id = prod.Id;
        pi.QuantityOnHand = 50;
        piList.add(pi);

        ProductItem pi2 = new ProductItem();
        pi2.LocationId = loc.Id;
        pi2.Product2Id = prod1.Id;
        pi2.QuantityOnHand = 50;
        piList.add(pi2);
        
        ProductItem pi3 = new ProductItem();
        pi3.LocationId = loc.Id;
        pi3.Product2Id = prod2.Id;
        pi3.QuantityOnHand = 50;
        piList.add(pi3);
        
        ProductItem pi4 = new ProductItem();
        pi4.LocationId = loc2.Id;
        pi4.Product2Id = prod.Id;
        pi4.QuantityOnHand = 50;
        pi4.Minimum_Quantity__c = 20;
        piList.add(pi4);

        ProductItem pi5 = new ProductItem();
        pi5.LocationId = loc2.Id;
        pi5.Product2Id = prod1.Id;
        pi5.QuantityOnHand = 50;
        pi5.Minimum_Quantity__c = 20;
        piList.add(pi5);
        
        ProductItem pi6 = new ProductItem();
        pi6.LocationId = loc2.Id;
        pi6.Product2Id = prod2.Id;
        pi6.QuantityOnHand = 50;
        pi6.Minimum_Quantity__c = 20;
        piList.add(pi6);
        insert piList;
        
        Test.startTest();
        List<Product2> prodListCheck = InventoryLevel.getInventoryProducts();
        System.assert(prodListCheck != null);
        List<ServiceResource> srListCheck = InventoryLevel.getActiveServiceResources();
        System.assert(!srListCheck.isEmpty());
        Map<Integer,List<Product2>> allProdMap = InventoryLevel.getAllProducts(10,sr.Id);
        System.assert(!allProdMap.isEmpty());
        System.assert(allProdMap.keySet().contains(3), 'Key 3 not found in map keyset');
        System.assert(allProdMap.values().size() == 1);
        System.assert(allProdMap.get(3).size() == 3);
        Map<Integer,List<Product2>> minQtyProdMap = InventoryLevel.getMinQtyProducts(10,sr.Id);
        System.assert(!minQtyProdMap.isEmpty());
        System.assert(minQtyProdMap.keySet().contains(3), 'Key 3 not found in map keyset');
        System.assert(minQtyProdMap.values().size() == 1);
        System.assert(minQtyProdMap.get(3).size() == 3);
        List<Product2> searchedProdList = InventoryLevel.retriveSearhedProducts('Test', sr.Id);
        System.assert(!searchedProdList.isEmpty());
        Boolean allGood = InventoryLevel.creatingReplenishmentWO(prodList,sr.Id);
        System.assert(allGood == true);
        String fieldTechId = InventoryLevel.getFieldTechId();
        System.assert(String.isBlank(fieldTechId));
        Test.stopTest();
    }
}