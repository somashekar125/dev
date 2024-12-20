@isTest
public class NoFilesWOLITest {
    @isTest static void testMethhod(){
        Global_Settings__c gs = TestDataFactory.CreateGlobalSettings();
        insert gs;
        Account acc = TestDataFactory.createAccount();
        acc.Name = 'BOSCOV Test';
        insert acc;
        ServiceContract sc = TestDataFactory.createServiceContract(acc);
        Case cs = TestDataFactory.createCase(acc, sc);
        Product2 prod = TestDataFactory.createProduct2(acc);
        insert prod;
        PricebookEntry standardPrice = TestDataFactory.createPricebookEntry(prod);
        insert standardPrice;
        WorkOrder wo = TestDataFactory.createWorkOrder(cs, sc, acc);
        insert wo;
        WorkOrderLineItem wl = new WorkOrderLineItem();
        wl.WorkOrderId = wo.Id;
        wl.PricebookEntryId = standardPrice.Id;
        wl.Quantity = 12;
        insert wl;
        
        Test.startTest();
        NoFilesWOLI.updateWOLI();
        Test.stopTest();
        WorkOrderLineItem woli = [SELECT Id,No_Images__c FROM WorkOrderLineItem WHERE Id =: wl.Id];
        System.assert(woli.No_Images__c == true);
    }
}