@isTest
public class SalesOrderLineTriggerHandlerTest {
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
        
        WorkOrder wo = TestDataFactory.createWorkOrder(cs, sc, acc);
        insert wo;
        
        Sales_Order__c so = new Sales_Order__c();
        so.Name = '123456';
        so.Work_Order__c = wo.Id;
        so.Account__c = acc.Id;
        insert so;
        
        list<Product2> prodList = new list<Product2>();
        Product2 prod = TestDataFactory.createProduct2(acc);
        prodList.add(prod);
        Product2 prod2 = TestDataFactory.createProduct2(acc);
        prod2.Name = 'Test prod 2';
        prodList.add(prod2);
        insert prodList;
        
        list<PricebookEntry> pbeList = new list<PricebookEntry>();
        PricebookEntry standardPrice = TestDataFactory.createPricebookEntry(prodList[0]);
        pbeList.add(standardPrice);
        PricebookEntry standardPrice2 = TestDataFactory.createPricebookEntry(prodList[1]);
        pbeList.add(standardPrice2);
        insert pbeList;
        
        List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
        WorkOrderLineItem woli1 = new WorkOrderLineItem();
        woli1.Status = 'New';
        woli1.Subject = 'Test 1';
        woli1.Quantity = 2;
        woli1.WorkOrderId = wo.Id;
        woli1.PricebookEntryId = pbeList[0].Id;
        woli1.SOLI_Serial_Number__c = null;
        woliList.add(woli1);
        
        WorkOrderLineItem woli2 = new WorkOrderLineItem();
        woli2.Status = 'Completed';
        woli2.Subject = 'Test 2';
        woli2.WorkOrderId = wo.Id;
        woli2.PricebookEntryId = pbeList[1].Id;
        woli2.Quantity = 1;
        woli2.SOLI_Serial_Number__c = null;
        woliList.add(woli2);
        insert woliList;
        Test.stopTest();
    }
    
    @isTest static void testMethod1(){
        test.startTest();
        Account acc = [SELECT Id FROM Account WHERE Name = 'test account' LIMIT 1];
        WorkOrder wo = [SELECT Id, CaseId FROM WorkOrder WHERE AccountId =: acc.Id LIMIT 1];
        Sales_Order__c so = [SELECT Id FROM Sales_Order__c WHERE Account__c =: acc.Id LIMIT 1];
        Map<Id,Product2> prodMap = new Map<Id,Product2>([SELECT Id FROM Product2 WHERE Account_Item_Belongs_To__c =: acc.Id]);
        list<PricebookEntry> pbeList = [SELECT Id FROM PricebookEntry WHERE Product2Id IN:prodMap.keySet()];
        List<Product2> prodList = prodMap.values();
        
        List<Sales_Order_Line__c> solList = new List<Sales_Order_Line__c>();
        Sales_Order_Line__c sol1 = new Sales_Order_Line__c();
        sol1.Sales_Order__c = so.Id;
        sol1.Product__c = null;
        sol1.Quantity__c = 1;
        sol1.Description__c = 'Test prod 1';
        sol1.Line_Number__c = 1;
        sol1.Serial_Numbers__c = '523,45234';
        solList.add(sol1);
        Sales_Order_Line__c sol2 = new Sales_Order_Line__c();
        sol2.Sales_Order__c = so.Id;
        sol2.Product__c = prodList[0].Id;
        sol2.Line_Number__c = 2;
        sol2.Serial_Numbers__c = '5234587876,7868976';
        sol2.Quantity__c = 2;
        solList.add(sol2);
        Sales_Order_Line__c sol3 = new Sales_Order_Line__c();
        sol3.Sales_Order__c = so.Id;
        sol3.Product__c = prodList[1].Id;
        sol3.Line_Number__c = 3;
        sol3.Serial_Numbers__c = '52345,54644';
        sol3.Quantity__c = 1;
        solList.add(sol3);
        insert solList;
        
        Case cs = [SELECT Id,Serial_Numbers__c FROM Case WHERE Id =: wo.CaseId];
        System.assert(cs.Serial_Numbers__c != null);
        Case cs2 = [SELECT Id,Serial_Numbers__c FROM Case WHERE Id =: wo.CaseId];
        System.assert(cs2.Serial_Numbers__c != null);
        test.stopTest();
        
        List<WorkOrderLineItem> woliList = [SELECT Id,SOLI_Serial_Number__c,Subject FROM WorkOrderLineItem WHERE WorkOrderId =:wo.Id Order by Createddate desc];
        System.assert(woliList[0].SOLI_Serial_Number__c == '7868976');
        System.assert(woliList[1].SOLI_Serial_Number__c == '5234587876');
        List<Asset> astFromSol = [SELECT Id,SerialNumber FROM Asset WHERE Product2Id =:solList[1].Product__c Order by Createddate desc];
        System.assert(astFromSol[0].SerialNumber == '5234587876');
        System.assert(astFromSol[1].SerialNumber == '7868976');
        List<Asset> astFromSol2 = [SELECT Id,SerialNumber FROM Asset WHERE Product2Id =:solList[2].Product__c Order by Createddate desc];
        System.assert(astFromSol2[0].SerialNumber == '52345');
        System.assert(astFromSol2[1].SerialNumber == '54644');
    }
    
    @isTest static void testMethod2(){
        test.startTest();
        Account acc = [SELECT Id FROM Account WHERE Name = 'test account' LIMIT 1];
        WorkOrder wo = [SELECT Id, CaseId FROM WorkOrder WHERE AccountId =: acc.Id LIMIT 1];
        Sales_Order__c so = [SELECT Id FROM Sales_Order__c WHERE Account__c =: acc.Id LIMIT 1];
        Map<Id,Product2> prodMap = new Map<Id,Product2>([SELECT Id FROM Product2 WHERE Account_Item_Belongs_To__c =: acc.Id]);
        list<PricebookEntry> pbeList = [SELECT Id FROM PricebookEntry WHERE Product2Id IN:prodMap.keySet()];
        List<Product2> prodList = prodMap.values();
        
        List<Sales_Order_Line__c> solList = new List<Sales_Order_Line__c>();
        Sales_Order_Line__c sol1 = new Sales_Order_Line__c();
        sol1.Sales_Order__c = so.Id;
        sol1.Product__c = null;
        sol1.Quantity__c = 1;
        sol1.Description__c = 'Test prod 1';
        sol1.Line_Number__c = 1;
        sol1.Serial_Numbers__c = '523,45234';
        solList.add(sol1);
        Sales_Order_Line__c sol2 = new Sales_Order_Line__c();
        sol2.Sales_Order__c = so.Id;
        sol2.Product__c = prodList[0].Id;
        sol2.Line_Number__c = 2;
        sol2.Serial_Numbers__c = '5234587876,7868976';
        sol2.Quantity__c = 2;
        solList.add(sol2);
        Sales_Order_Line__c sol3 = new Sales_Order_Line__c();
        sol3.Sales_Order__c = so.Id;
        sol3.Product__c = prodList[1].Id;
        sol3.Line_Number__c = 3;
        sol3.Serial_Numbers__c = '52345,54644';
        sol3.Quantity__c = 1;
        solList.add(sol3);
        insert solList;

        sol3.Serial_Numbers__c = '523455464434534';
        update sol3;
        test.stopTest();
        
        List<WorkOrderLineItem> woliList = [SELECT Id,SOLI_Serial_Number__c FROM WorkOrderLineItem WHERE WorkOrderId =:wo.Id Order by Createddate desc];
        System.assert(woliList[0].SOLI_Serial_Number__c == '7868976');
        System.assert(woliList[1].SOLI_Serial_Number__c == '5234587876');
        System.assert(woliList[2].SOLI_Serial_Number__c == '523455464434534');
        List<Asset> astFromSol = [SELECT Id,SerialNumber FROM Asset WHERE Product2Id =:solList[1].Product__c Order by Createddate desc];
        System.assert(astFromSol[0].SerialNumber == '5234587876');
        System.assert(astFromSol[1].SerialNumber == '7868976');
        List<Asset> astFromSol2 = [SELECT Id,SerialNumber FROM Asset WHERE Product2Id =:solList[2].Product__c Order by Createddate desc];
        System.assert(astFromSol2[0].SerialNumber == '523455464434534');
    }
}