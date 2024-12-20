@isTest
public class WorkOrderLineItemTriggerTest {
    @testSetup static void setup() {
        Test.startTest();
        Global_Settings__c gs = TestDataFactory.CreateGlobalSettings();
        insert gs;
        Account acc = TestDataFactory.createAccount();
        insert acc;
        ServiceContract sc = TestDataFactory.createServiceContract(acc);
        insert sc;
        Case cs = TestDataFactory.createCase(acc, sc);
        insert cs;
        WorkOrder woParent = TestDataFactory.createWorkOrder(cs, sc, acc);
        insert woParent;
        Test.stopTest();
    }
    
    @isTest static void testMehtod1(){
        Test.startTest();
        Account acc = [SELECT Id FROM Account WHERE Name = 'test account' LIMIT 1];
        ServiceContract sc = [SELECT Id FROM ServiceContract WHERE Service_Type__c = 'Advance Exchange (Depot Only)' LIMIT 1];
        WorkOrder woParent = [SELECT Id From WorkOrder WHERE ServiceContractId =:sc.Id LIMIT 1];
        
        List<Product2> prodList = new List<Product2>();
        Product2 prod = new Product2(Name = 'Test prod 1',
                                     Family = 'Hardware', Account_Item_Belongs_To__c = acc.Id,Out_of_Scope__c = true);
        Product2 prod2 = new Product2(Name = 'Test prod 2',
                                     Family = 'Hardware', Account_Item_Belongs_To__c = acc.Id,Out_of_Scope__c = true);
        prodList.add(prod);
        prodList.add(prod2);
        insert prodList;
        
        List<PricebookEntry> pbList  = new List<PricebookEntry>();
        PricebookEntry standardPrice = TestDataFactory.createPricebookEntry(prodList[0]);
        PricebookEntry standardPrice2 = TestDataFactory.createPricebookEntry(prodList[1]);
        pbList.add(standardPrice);
        pbList.add(standardPrice2);
        insert pbList;
        
        Id pricebookId = Test.getStandardPricebookId();
        WorkOrder wo = new WorkOrder();
        wo.ParentWorkOrderId = woParent.Id;
        wo.NetSuite_Error__c = True;
        wo.Pricebook2Id = pricebookId;
        insert wo;
        
        WorkOrderLineItem woli = new WorkOrderLineItem();
        woli.PricebookEntryId = pbList[0].Id;
        woli.Description = 'Test';
        woli.Child_WOLI__c = null;
        woli.WorkOrderId = wo.Id;
        woli.quantity = 1;
        woli.unitprice = 10;
        //insert woli;
        
        WorkOrderLineItem woli2 = new WorkOrderLineItem();
        woli2.PricebookEntryId = pbList[1].Id;
        woli2.Description = 'Test1';
        woli2.Child_WOLI__c = woli.Id;
        woli2.WorkOrderId = wo.Id;
        woli2.quantity = 2;
        woli2.unitprice = 20;
        //woliList.add(woli2);
        insert woli2;
        
        woli2.PricebookEntryId = standardPrice2.Id;
        //Update woli2;
        Test.stopTest();
    }
    
    @isTest static void testMehtod2(){
        Test.startTest();
        Account acc = [SELECT Id FROM Account WHERE Name = 'test account' LIMIT 1];
        Case cs = [SELECT Id FROM Case WHERE AccountId =: acc.Id AND Service_Type__c = 'Advance Exchange (Depot Only)' LIMIT 1];
        
        Product2 prod = new Product2(Name = 'Test prod 1',
                                     Family = 'Hardware', Account_Item_Belongs_To__c = acc.Id,Out_of_Scope__c = true);
        insert prod;
        
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        
        WorkOrder wo = new WorkOrder();
        wo.AccountId = acc.Id;
        wo.caseId = cs.Id;
        wo.NetSuite_Error__c = True;
        wo.Pricebook2Id = pricebookId;
        insert wo;
        
        Product_Markup__c pm = new Product_Markup__c();
        pm.Product__c = prod.Id;
        pm.Markup__c = 10;
        pm.State__c = 'AK';
        pm.Country__c = 'United States';
        insert pm;
        
        List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
        WorkOrderLineItem woli = new WorkOrderLineItem();
        woli.PricebookEntryId = standardPrice.Id;
        woli.Description = 'Test';
        woli.Child_WOLI__c = null;
        woli.WorkOrderId = wo.Id;
        woli.quantity = 1;
        woli.unitprice = 10;
        insert woli;
        
        delete woli;
        Test.stopTest();
    }
}