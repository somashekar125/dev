@isTest
public class WorkOrderLineItemBatchTest {
    @isTest static void testMethod1(){
        Global_Settings__c gs = TestDataFactory.CreateGlobalSettings();
        insert gs;
        Account acc = TestDataFactory.createAccount();
        insert acc;
        Product2 prod = TestDataFactory.createProduct2(acc);
        prod.Name = 'ES-ONSITE-EQUIPMENT-RENTAL-COST';
        insert prod;
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(prod);
        insert pbe;
        Id pricebookId = Test.getStandardPricebookId();
        WorkOrder wo = new WorkOrder();
        wo.Status = 'New';
        wo.Pricebook2Id = pricebookId;
        insert wo;
        
        WorkOrderLineItem woli = new WorkOrderLineItem();
        woli.WorkOrderId = wo.Id;
        woli.Status = 'New';
        woli.StartDate = System.now().addDays(-1);
        woli.EndDate = System.now();
        woli.PricebookEntryId = pbe.Id;
        woli.Quantity = 1;
        woli.UnitPrice = 10;
        insert woli;
        
        Test.startTest();
        WorkOrderLineItemBatch woliBatch = new WorkOrderLineItemBatch();
        Database.executeBatch(woliBatch,5);
        Test.stopTest();
        
        WorkOrderLineItem woliCheck = [SELECT Id,Status FROM WorkOrderLineItem WHERE Id =: woli.Id];
        System.assert(woliCheck.Status == 'Pickup Requested - Auto');
    }
}