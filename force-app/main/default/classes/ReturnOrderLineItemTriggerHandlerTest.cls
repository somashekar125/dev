@isTest
public class ReturnOrderLineItemTriggerHandlerTest {
    @isTest static void testMethod1(){
        Global_Settings__c gs = TestDataFactory.CreateGlobalSettings();
        insert gs;
        
        Account acc = TestDataFactory.createAccount();
        insert acc;
        
        Product2 prod = new Product2(Name = 'Test CUB Product 1',Source_Key__c = '22222', isActive =  true,Manufacturer_Part_Number__c = '50043690',
                                     Quantity__c = 1,NS_Item_Class__c = '4500',Family = 'Hardware',QuantityUnitOfMeasure = 'Each',
                                     Account_Item_Belongs_To__c = acc.Id,No_Return_Shipment__c = true);
        insert prod;
        
        Schema.Location loc = new Schema.Location();
        loc.Name = 'Cub van';
        loc.LocationType = 'Van';
        loc.IsMobile = true;
        loc.IsInventoryLocation = true;
        insert loc;
        
        ProductItem pi = new ProductItem();
        pi.LocationId = loc.Id;
        pi.Product2Id = prod.Id;
        pi.QuantityOnHand = 50;
        pi.QuantityUnitOfMeasure = 'Each';
        insert pi;
        
        ServiceContract sc = TestDataFactory.createServiceContract(acc);
        insert sc;
        Case cs = TestDataFactory.createCase(acc, sc);
        insert cs;
        
        WorkOrder wo = TestDataFactory.createWorkOrder(cs, sc, acc);
        insert wo;
        
        Sales_Order__c so = new Sales_Order__c();
        so.Name = '123456';
        so.Work_Order__c = wo.Id;
        so.Account__c = acc.Id;
        insert so;
        
        ReturnOrder ro = new ReturnOrder();
        ro.Sales_Order__c = so.Id;
        insert ro;
        
        Test.startTest();
        ReturnOrderLineItem roli = new ReturnOrderLineItem();
        roli.ReturnOrderId = ro.Id;
        roli.Product2Id = prod.Id;
        roli.QuantityReturned = 2;
        insert roli;
        
        List<ProductRequestLineItem> prliList = [SELECT Id FROM ProductRequestLineItem WHERE WorkOrderId=:wo.Id];
        System.assert(prliList != null);
        List<ProductTransfer> ptList = [SELECT Id FROM ProductTransfer WHERE Work_Order__c=:wo.Id];
        System.assert(ptList != null);
        Test.stopTest();
    }
}