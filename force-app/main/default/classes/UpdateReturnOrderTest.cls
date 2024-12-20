@isTest
public class UpdateReturnOrderTest {
    @isTest public static void covercloseReturnOrder(){
        Global_Settings__c gs = TestDataFactory.CreateGlobalSettings();
        insert gs;
        Account hwrootAcc = TestDataFactory.createAccount();
        hwrootAcc.Name = 'CUB Foods Hardware';
        hwrootAcc.Source_Key__c = '567654';
        insert hwrootAcc;
        Account acc = TestDataFactory.createAccount();
        acc.Root_Account__c = hwrootAcc.Id;
        acc.Source_Key__c = '1265865';
        insert acc;
        
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
        
        ServiceContract sc = TestDataFactory.createServiceContract(hwrootAcc);
        insert sc;
        Case cs = TestDataFactory.createCase(acc, sc);
        insert cs;
        WorkOrder wo = TestDataFactory.createWorkOrder(cs, sc, acc);
        wo.OwnerId = userinfo.getuserId();
        insert wo;
        Sales_Order__c so = new Sales_Order__c();
        so.Case__c = cs.Id;
        so.Work_Order__c = wo.Id;
        insert so;
        
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
        
        ReturnOrder ro = new ReturnOrder();
        ro.Return_Authorization__c = 'Test';
        ro.Status = 'draft';
        ro.Sales_Order__c = so.Id;
        insert ro;
        ReturnOrderLineItem roli = new ReturnOrderLineItem();
        roli.ReturnOrderId = ro.Id;
        roli.Product2Id = prod.Id;
        roli.QuantityReturned = 2;
        insert roli;
        
        Test.startTest();
        Boolean isOwnerIdValid = UpdateReturnOrder.checkWOOwnerId(wo.Id);
        System.assert(isOwnerIdValid == true);
        List<ReturnOrder> roList = UpdateReturnOrder.getReturnOrder(wo.Id);
        System.assert(roList != null);
        List<ReturnOrderLineItem> roliList = UpdateReturnOrder.getReturnOrderLineItems(ro);
        System.assert(roliList != null);
        Boolean isShippedReturnOrder = UpdateReturnOrder.shipReturnOrder(ro);
        System.assert(isShippedReturnOrder == true);
        Test.stopTest();
    }
}