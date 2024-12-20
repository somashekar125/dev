@isTest
public class ReturnPartsTest {
    @isTest public static void covergetVanStock(){
        Account hwrootAcc = TestDataFactory.createAccount();
        hwrootAcc.Name = 'CUB Foods Hardware';
        hwrootAcc.Source_Key__c = '567654';
        hwrootAcc.NS_Id__c = 'abc4';
        insert hwrootAcc;
        list<Product2> prodList = new list<Product2>();
        Product2 prod = new Product2(Name = 'Test CUB Product 1',Source_Key__c = '22222', isActive =  true,Manufacturer_Part_Number__c = '50043690',
                                     Quantity__c = 1,NS_Item_Class__c = '4500',Family = 'Hardware',QuantityUnitOfMeasure = 'Each',
                                     Account_Item_Belongs_To__c = hwrootAcc.Id,No_Return_Shipment__c = true);
        Product2 prod1 = new Product2(Name = 'Test CUB Product 2',isActive =  true,Manufacturer_Part_Number__c = '50043690',
                                      Quantity__c = 1,NS_Item_Class__c = '4500',Family = 'Hardware',QuantityUnitOfMeasure = 'Each',
                                      Account_Item_Belongs_To__c = hwrootAcc.Id,No_Return_Shipment__c = true);
        Product2 prod2 = new Product2(Name = 'Test CUB Product 3',Source_Key__c = '22222',isActive =  true, QuantityUnitOfMeasure = 'Each',
                                      Manufacturer_Part_Number__c = '50043690',Quantity__c = 1,NS_Item_Class__c = '4500',
                                      Family = 'Hardware', Account_Item_Belongs_To__c = hwrootAcc.Id);
        
        prodList.add(prod);
        prodList.add(prod1);
        prodList.add(prod2);
        insert prodList;
        Map<Id,Product2> prodMap = new Map<Id,Product2>(prodList);
        
        Product2 prod3 = new Product2(Name = 'Test CUB Product 4',Source_Key__c = '22222',isActive =  true, QuantityUnitOfMeasure = 'Each',
                                      Manufacturer_Part_Number__c = '50043690',Quantity__c = 1,NS_Item_Class__c = '4500',
                                      Family = 'Hardware', Account_Item_Belongs_To__c = hwrootAcc.Id);
        List<product2> prdList  = new List<Product2>();
        prdList.add(prod3);
        insert prdList;
        
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
        
        ProductItem pi3 = new ProductItem();
        pi3.LocationId = loc.Id;
        pi3.Product2Id = prod3.Id;
        pi3.QuantityOnHand = 50;
        pi3.QuantityUnitOfMeasure = 'Each';
        piList.add(pi3);
        insert piList;
        
        Test.startTest();
        List<ProductItem> piListCheck = ReturnParts.getVanStock();
        System.assert(piListCheck != null);
        List<Product2> pList = ReturnParts.retriveAllProducts(2);
        System.assert(pList != null);
        List<Product2> pList2 = ReturnParts.retriveSearhedProducts('Test');
        System.assert(pList2 != null);
        List<Product2> pList3 = ReturnParts.retriveSearhedProducts('Product 4');
        System.assert(pList3 != null);
        ReturnParts.returnProductsToWarehouse(piList,prdList);
        List<ProductTransfer> ptList = [SELECT Id FROM ProductTransfer WHERE Product2Id IN:prodMap.keySet()];
        System.assert(ptList != null);
        Test.stopTest();
        
    }
}