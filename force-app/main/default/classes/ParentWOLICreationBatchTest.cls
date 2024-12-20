@isTest
public class ParentWOLICreationBatchTest {
    @isTest Static void testMenthod1(){
        Global_Settings__c gs = TestDataFactory.CreateGlobalSettings();
        insert gs;
        Account acc = TestDataFactory.createAccount();
        insert acc;
        ServiceContract sc = TestDataFactory.createServiceContract(acc);
        insert sc;
        Product2 prod = TestDataFactory.createProduct2(acc);
        insert prod;
        PricebookEntry standardPrice = TestDataFactory.createPricebookEntry(prod);
        insert standardPrice;
        Case cs = TestDataFactory.createCase(acc,sc);
        insert cs;
        
        List<Workorder> woList = new List<Workorder>();
        Workorder wo = TestDataFactory.createWorkOrder(cs,sc,acc);
        woList.add(wo);
        
        Workorder wo2 = TestDataFactory.createWorkOrder(cs,sc,acc);
        wo2.ParentWorkOrderId = wo.Id;
        woList.add(wo2);
        insert woList;
        
        List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
        WorkOrderLineItem wl = TestDataFactory.createWorkOrderLineItem(woList[1], standardPrice);
        wl.Description = cs.Description;
        wl.WorkOrderId = wo2.Id;
        woliList.add(wl);
        
        Test.startTest();
        ParentWOLICreationBatch pcb = new ParentWOLICreationBatch(woliList);
        Database.executeBatch(pcb,7);
        Test.stopTest();
        
        List<WorkOrderLineItem> woliListCheck = [SELECT Id FROM WorkOrderLineItem WHERE WorkOrderId =: wo2.Id];
        System.assert(woliListCheck != null);
    }
}