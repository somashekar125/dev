@isTest
public class SalesOrderBatchTest {
    @testSetup static void setup() {
        Test.startTest();
        Global_Settings__c gs = TestDataFactory.CreateGlobalSettings();
        insert gs;
        
        User u = [SELECT Id FROM User WHERE isActive = true AND (UserName='illinoiswholesalecashregisterinc@nuageexperts.com' 
                  OR UserName='illinoiswholesalecashregisterinc@nuageexperts.com.svc') LIMIT 1];
        
        Account acc = TestDataFactory.createAccount();
        insert acc;
        
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
        
        ServiceContract sc = TestDataFactory.createServiceContract(acc);
        sc.Service_Type__c = 'New Store Install';
        insert sc;
        
        List<Case> csList = new List<Case>();
        Case cs = TestDataFactory.createCase(acc, sc);
        cs.Service_Type__c='New Store Install';
        csList.add(cs);
        insert csList;
        
        List<WorkOrder> woList = new List<WorkOrder>();
        WorkOrder wo = TestDataFactory.createWorkOrder(cs, sc, acc);
        wo.Service_Type__c = 'New Store Install';
        wo.Tracking_Numbers__c = null;
        woList.add(wo);
        WorkOrder wo1 = TestDataFactory.createWorkOrder(cs, sc, acc);
        wo1.Service_Type__c = 'New Store Install';
        wo1.Tracking_Numbers__c = null;
        wo1.Status = 'Closed';
        woList.add(wo1);
        insert woList;
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
        
        List<Sales_Order__c> soList = new List<Sales_Order__c>();
        Sales_Order__c so = new Sales_Order__c();
        so.Account__c = acc.Id;
        so.Order_Status__c = 'Closed';
        so.Work_Order__c = woList[0].Id;
        soList.add(so);
        Sales_Order__c so1 = new Sales_Order__c();
        so1.Account__c = acc.Id;
        so1.Order_Status__c = 'Closed';
        so1.Work_Order__c = woList[1].Id;
        soList.add(so1);
        insert soList;
        
        ReturnOrder ro = new ReturnOrder();
        ro.Sales_Order__c = so.Id;
        insert ro;
        
        ReturnOrder roCheck = [SELECT Id,CaseId FROM ReturnOrder WHERE Id =: ro.Id];
        System.assert(roCheck.CaseId != NULL);
        
        ro.CaseId = NULL;
        update ro;
		ReturnOrder roCheck2 = [SELECT Id,CaseId FROM ReturnOrder WHERE Id =: ro.Id];
        System.assert(roCheck2.CaseId != NULL);    
        
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
        
        Case cs1 = [SELECT Id,Serial_Numbers__c FROM Case WHERE Id =: wo.CaseId];
        System.assert(cs1.Serial_Numbers__c != null);
        Case cs2 = [SELECT Id,Serial_Numbers__c FROM Case WHERE Id =: wo.CaseId];
        System.assert(cs2.Serial_Numbers__c != null);
        
        sol3.Serial_Numbers__c = '523455464434534';
        update sol3;
        Test.stopTest();
        List<WorkOrderLineItem> woliListCheck = [SELECT Id,SOLI_Serial_Number__c FROM WorkOrderLineItem WHERE WorkOrderId =:wo.Id Order by Createddate desc];
        System.assert(woliListCheck[0].SOLI_Serial_Number__c == '7868976');
        System.assert(woliListCheck[1].SOLI_Serial_Number__c == '5234587876');
        System.assert(woliListCheck[2].SOLI_Serial_Number__c == '523455464434534');
        List<Asset> astFromSol = [SELECT Id,SerialNumber FROM Asset WHERE Product2Id =:solList[1].Product__c Order by Createddate desc];
        System.assert(astFromSol[0].SerialNumber == '5234587876');
        System.assert(astFromSol[1].SerialNumber == '7868976');
        List<Asset> astFromSol2 = [SELECT Id,SerialNumber FROM Asset WHERE Product2Id =:solList[2].Product__c Order by Createddate desc];
        System.assert(astFromSol2[0].SerialNumber == '523455464434534');
    }
    
    @isTest static void testMethod1(){
        User u = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name = 'test account' LIMIT 1];
        ServiceContract sc = [SELECT Id FROM ServiceContract WHERE Service_Type__c = 'New Store Install' LIMIT 1];
        Case cs = [SELECT Id FROM Case WHERE AccountId =: acc.Id AND Service_Type__c = 'New Store Install' LIMIT 1];
        WorkOrder wo = [SELECT Id From WorkOrder WHERE ServiceContractId =:sc.Id AND Status != 'Closed' limit 1];
        Sales_Order__c so = [SELECT Id,Order_Status__c FROM Sales_Order__c WHERE Work_Order__c =: wo.Id];
        System.runAs(u) {
            // The following code runs as user 'u'
            so.Outbound_Tracking_Numbers__c = '111';
            update so;
        }
        Test.startTest();
        SalesOrderBatch soBatch = new SalesOrderBatch();
        Database.executeBatch(soBatch,7);
        Test.stopTest();
        
        WorkOrder woCheck = [SELECT Id,CaseId,Tracking_Numbers__c FROM WorkOrder WHERE Id=:wo.Id];
        Sales_Order__c soCheck = [SELECT Id,Outbound_Tracking_Numbers__c FROM Sales_Order__c WHERE Work_Order__c =: woCheck.Id];
        System.assert(woCheck.Tracking_Numbers__c == soCheck.Outbound_Tracking_Numbers__c);
        Case cCheck = [SELECT Id,Tracking_Numbers__c FROM Case WHERE Id=: woCheck.CaseId];
        //System.assert(cCheck.Tracking_Numbers__c == soCheck.Outbound_Tracking_Numbers__c);
    }
    
    @isTest static void testMethod2(){
        User u = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name = 'test account' LIMIT 1];
        ServiceContract sc = [SELECT Id FROM ServiceContract WHERE Service_Type__c = 'New Store Install' LIMIT 1];
        Case cs = [SELECT Id FROM Case WHERE AccountId =: acc.Id AND Service_Type__c = 'New Store Install' LIMIT 1];
        WorkOrder wo = [SELECT Id From WorkOrder WHERE ServiceContractId =:sc.Id AND Status != 'Closed' limit 1];
        Sales_Order__c so = [SELECT Id,Order_Status__c FROM Sales_Order__c WHERE Work_Order__c =: wo.Id];
        System.runAs(u) {
            // The following code runs as user 'u'
            so.Return_Order_Tracking_Numbers__c = '222';
            update so;
        }
        Test.startTest();
        SalesOrderBatch soBatch = new SalesOrderBatch();
        Database.executeBatch(soBatch,7);
        Test.stopTest();
        
        WorkOrder woCheck = [SELECT Id,CaseId,Return_Order_Tracking_Numbers__c FROM WorkOrder WHERE Id=:wo.Id];
        Sales_Order__c soCheck = [SELECT Id,Return_Order_Tracking_Numbers__c FROM Sales_Order__c WHERE Work_Order__c =: woCheck.Id];
        System.assert(woCheck.Return_Order_Tracking_Numbers__c == soCheck.Return_Order_Tracking_Numbers__c);
        Case cCheck = [SELECT Id,Return_Tracking_Numbers__c FROM Case WHERE Id=: woCheck.CaseId];
        //System.assert(cCheck.Return_Tracking_Numbers__c == soCheck.Return_Order_Tracking_Numbers__c);
    }
    
    @isTest static void testMethod3(){
        User u = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name = 'test account' LIMIT 1];
        ServiceContract sc = [SELECT Id FROM ServiceContract WHERE Service_Type__c = 'New Store Install' LIMIT 1];
        Case cs = [SELECT Id FROM Case WHERE AccountId =: acc.Id AND Service_Type__c = 'New Store Install' LIMIT 1];
        WorkOrder wo = [SELECT Id From WorkOrder WHERE ServiceContractId =:sc.Id AND Status != 'Closed' limit 1];
        Sales_Order__c so = [SELECT Id,Order_Status__c FROM Sales_Order__c WHERE Work_Order__c =: wo.Id];
        System.runAs(u) {
            // The following code runs as user 'u'
            so.Return_Authorization__c = 'Test1';
            update so;
        }
        Test.startTest();
        SalesOrderBatch soBatch = new SalesOrderBatch();
        Database.executeBatch(soBatch,7);
        Test.stopTest();
        
        WorkOrder woCheck = [SELECT Id, CaseId,Return_Authorization__c FROM WorkOrder WHERE Id=:wo.Id];
        Sales_Order__c soCheck = [SELECT Id, Return_Authorization__c FROM Sales_Order__c WHERE Work_Order__c =: woCheck.Id];
        System.assert(woCheck.Return_Authorization__c == soCheck.Return_Authorization__c);
        Case cCheck = [SELECT Id,Return_Authorization__c FROM Case WHERE Id=: woCheck.CaseId];
        //System.assert(cCheck.Return_Authorization__c == soCheck.Return_Authorization__c);
    }
    
    @isTest static void testMethod4(){
        User u = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name = 'test account' LIMIT 1];
        ServiceContract sc = [SELECT Id FROM ServiceContract WHERE Service_Type__c = 'New Store Install' LIMIT 1];
        Case cs = [SELECT Id FROM Case WHERE AccountId =: acc.Id AND Service_Type__c = 'New Store Install' LIMIT 1];
        WorkOrder wo = [SELECT Id From WorkOrder WHERE ServiceContractId =:sc.Id AND Status != 'Closed' limit 1];
        Sales_Order__c so = [SELECT Id,Order_Status__c FROM Sales_Order__c WHERE Work_Order__c =: wo.Id];
        System.runAs(u) {
            // The following code runs as user 'u'
            so.Ship_Date__c = System.today().AddDays(4);
            update so;
        }
        Test.startTest();
        SalesOrderBatch soBatch = new SalesOrderBatch();
        Database.executeBatch(soBatch,7);
        Test.stopTest();
        
        WorkOrder woCheck = [SELECT Id, CaseId, Ship_Date__c FROM WorkOrder WHERE Id=:wo.Id];
        Sales_Order__c soCheck = [SELECT Id, Ship_Date__c FROM Sales_Order__c WHERE Work_Order__c =: woCheck.Id];
        System.assert(woCheck.Ship_Date__c == soCheck.Ship_Date__c.addDays(1));
        Case cCheck = [SELECT Id,Ship_Date__c FROM Case WHERE Id=: woCheck.CaseId];
        //System.assert(cCheck.Ship_Date__c == soCheck.Ship_Date__c.addDays(1));
    }
   
    @isTest static void testMethod5(){
        User u = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name = 'test account' LIMIT 1];
        ServiceContract sc = [SELECT Id FROM ServiceContract WHERE Service_Type__c = 'New Store Install' LIMIT 1];
        Case cs = [SELECT Id FROM Case WHERE AccountId =: acc.Id AND Service_Type__c = 'New Store Install' LIMIT 1];
        WorkOrder wo = [SELECT Id From WorkOrder WHERE ServiceContractId =:sc.Id AND Status != 'Closed' limit 1];
        Sales_Order__c so = [SELECT Id,Order_Status__c FROM Sales_Order__c WHERE Work_Order__c =: wo.Id];
        
        System.runAs(u) {
            // The following code runs as user 'u'
            System.debug('Current User: ' + UserInfo.getUserName());
            System.debug('Current Profile: ' + UserInfo.getProfileId());
            
            so.Order_Status__c = 'Pending Billing/Partially Fulfilled';
            so.Outbound_Tracking_Numbers__c = '1232';
            update so;
        }
        Test.startTest();
        SalesOrderBatch soBatch = new SalesOrderBatch();
        Database.executeBatch(soBatch,7);
        Test.stopTest();
        
        WorkOrder woCheck = [SELECT Id,Status FROM WorkOrder WHERE Id=:wo.Id];
        System.assert(woCheck.Status == 'Part Shipped');
    }
    
    @isTest static void testMethod6(){
        User u = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name = 'test account' LIMIT 1];
        ServiceContract sc = [SELECT Id FROM ServiceContract WHERE Service_Type__c = 'New Store Install' LIMIT 1];
        Case cs = [SELECT Id FROM Case WHERE AccountId =: acc.Id AND Service_Type__c = 'New Store Install' LIMIT 1];
        WorkOrder wo = [SELECT Id From WorkOrder WHERE ServiceContractId =:sc.Id AND Status != 'Closed' limit 1];
        Sales_Order__c so = [SELECT Id,Order_Status__c FROM Sales_Order__c WHERE Work_Order__c =: wo.Id];

        System.runAs(u) {
            // The following code runs as user 'u'
            so.Order_Status__c = 'Billed';
            so.Outbound_Tracking_Numbers__c = '123';
            update so;
        }
        Test.startTest();
        SalesOrderBatch soBatch = new SalesOrderBatch();
        Database.executeBatch(soBatch,7);
        Test.stopTest();
        
        WorkOrder woCheck = [SELECT Id,Status,Resolution_Code__c FROM WorkOrder WHERE Id=:wo.Id];
        System.assert(woCheck.Status == 'Closed');
        System.assert(woCheck.Resolution_Code__c == 'SHIPMENT COMPLETE');
    }
    
    @isTest static void testMethod7(){
        User u = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name = 'test account' LIMIT 1];
        ServiceContract sc = [SELECT Id FROM ServiceContract WHERE Service_Type__c = 'New Store Install' LIMIT 1];
        Case cs = [SELECT Id FROM Case WHERE AccountId =: acc.Id AND Service_Type__c = 'New Store Install' LIMIT 1];
        WorkOrder wo = [SELECT Id From WorkOrder WHERE ServiceContractId =:sc.Id AND Status != 'Closed' limit 1];
        Sales_Order__c so = [SELECT Id,Order_Status__c FROM Sales_Order__c WHERE Work_Order__c =: wo.Id];
        System.runAs(u) {
            // The following code runs as user 'u'
            so.Order_Status__c = 'Pending Approval';
            update so;
        }
        Test.startTest();
        SalesOrderBatch soBatch = new SalesOrderBatch();
        Database.executeBatch(soBatch,7);
        Test.stopTest();
        
        WorkOrder woCheck = [SELECT Id,Status FROM WorkOrder WHERE Id=:wo.Id];
        System.assert(woCheck.Status == 'Part Ordered');
    }
    
    @isTest static void testMethod8(){
        User u = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name = 'test account' LIMIT 1];
        ServiceContract sc = [SELECT Id FROM ServiceContract WHERE Service_Type__c = 'New Store Install' LIMIT 1];
        Case cs = [SELECT Id FROM Case WHERE AccountId =: acc.Id AND Service_Type__c = 'New Store Install' LIMIT 1];
        WorkOrder wo = [SELECT Id From WorkOrder WHERE ServiceContractId =:sc.Id AND Status = 'Closed' limit 1];
        Sales_Order__c so = [SELECT Id,Order_Status__c FROM Sales_Order__c WHERE Work_Order__c =: wo.Id];
        System.runAs(u) {
            // The following code runs as user 'u'
            so.Order_Status__c = 'Pending Billing/Partially Fulfilled';
            so.Outbound_Tracking_Numbers__c = '1232';
            so.SO_Order_Status__c = 'Hold';
            update so;
        }
        Test.startTest();
        SalesOrderBatch soBatch = new SalesOrderBatch();
        Database.executeBatch(soBatch,7);
        Test.stopTest();
        
        WorkOrder woCheck = [SELECT Id,Status FROM WorkOrder WHERE Id=:wo.Id];
        System.assert(woCheck.Status != 'Cannot Complete'); // returned before wo updates since wo is closed.
    }
    
    @isTest static void testMethod9(){
        User u = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name = 'test account' LIMIT 1];
        ServiceContract sc = [SELECT Id FROM ServiceContract WHERE Service_Type__c = 'New Store Install' LIMIT 1];
        Case cs = [SELECT Id FROM Case WHERE AccountId =: acc.Id AND Service_Type__c = 'New Store Install' LIMIT 1];
        WorkOrder wo = [SELECT Id From WorkOrder WHERE ServiceContractId =:sc.Id AND Status != 'Closed' limit 1];
        Sales_Order__c so = [SELECT Id,Order_Status__c FROM Sales_Order__c WHERE Work_Order__c =: wo.Id];
        System.runAs(u) {
            // The following code runs as user 'u'
            so.Order_Status__c = 'Pending Billing/Partially Fulfilled';
            so.Outbound_Tracking_Numbers__c = '12232';
            so.SO_Order_Status__c = 'Hold';
            update so;
        }
        Test.startTest();
        SalesOrderBatch soBatch = new SalesOrderBatch();
        Database.executeBatch(soBatch,7);
        Test.stopTest();
        
        WorkOrder woCheck = [SELECT Id,Status FROM WorkOrder WHERE Id=:wo.Id];
        System.assert(woCheck.Status == 'Cannot Complete'); 
    }
    
    @isTest static void testMethod10(){
        User u = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name = 'test account' LIMIT 1];
        ServiceContract sc = [SELECT Id FROM ServiceContract WHERE Service_Type__c = 'New Store Install' LIMIT 1];
        Case cs = [SELECT Id FROM Case WHERE AccountId =: acc.Id AND Service_Type__c = 'New Store Install' LIMIT 1];
        WorkOrder wo = [SELECT Id From WorkOrder WHERE ServiceContractId =:sc.Id AND Status != 'Closed' limit 1];
        Sales_Order__c so = [SELECT Id,Order_Status__c FROM Sales_Order__c WHERE Work_Order__c =: wo.Id];
        System.runAs(u) {
            // The following code runs as user 'u'
            so.Order_Status__c = 'Pending Billing/Partially Fulfilled';
            so.Outbound_Tracking_Numbers__c = null;
            so.SO_Order_Status__c = 'Hold';
            update so;
        }
        Test.startTest();
        SalesOrderBatch soBatch = new SalesOrderBatch();
        Database.executeBatch(soBatch,7);
        Test.stopTest();
        
        WorkOrder woCheck = [SELECT Id,Status FROM WorkOrder WHERE Id=:wo.Id];
        System.assert(woCheck.Status == 'Cannot Complete'); 
    }
    
    @isTest static void testMethod11(){
        User u = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name = 'test account' LIMIT 1];
        ServiceContract sc = [SELECT Id FROM ServiceContract WHERE Service_Type__c = 'New Store Install' LIMIT 1];
        Case cs = [SELECT Id FROM Case WHERE AccountId =: acc.Id AND Service_Type__c = 'New Store Install' LIMIT 1];
        WorkOrder wo = [SELECT Id From WorkOrder WHERE ServiceContractId =:sc.Id AND Status != 'Closed' limit 1];
        Sales_Order__c so = [SELECT Id,Order_Status__c FROM Sales_Order__c WHERE Work_Order__c =: wo.Id];
        System.runAs(u) {
            // The following code runs as user 'u'
            so.Order_Status__c = 'Pending Billing/Partially Fulfilled';
            so.Outbound_Tracking_Numbers__c = null;
            update so;
        }
        Test.startTest();
        SalesOrderBatch soBatch = new SalesOrderBatch();
        Database.executeBatch(soBatch,7);
        Test.stopTest();
        
        WorkOrder woCheck = [SELECT Id,Status FROM WorkOrder WHERE Id=:wo.Id];
        System.assert(woCheck.Status == 'Pending Fulfillment'); 
    }
    
    @isTest static void testMethod12(){
        User u = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name = 'test account' LIMIT 1];
        ServiceContract sc = [SELECT Id FROM ServiceContract WHERE Service_Type__c = 'New Store Install' LIMIT 1];
        Case cs = [SELECT Id FROM Case WHERE AccountId =: acc.Id AND Service_Type__c = 'New Store Install' LIMIT 1];
        WorkOrder wo = [SELECT Id From WorkOrder WHERE ServiceContractId =:sc.Id AND Status != 'Closed' limit 1];
        Sales_Order__c so = [SELECT Id,Order_Status__c FROM Sales_Order__c WHERE Work_Order__c =: wo.Id];
        System.runAs(u) {
            // The following code runs as user 'u'
            so.Order_Status__c = 'Partially Fulfilled';
            so.Outbound_Tracking_Numbers__c = null;
            update so;
        }
        Test.startTest();
        SalesOrderBatch soBatch = new SalesOrderBatch();
        Database.executeBatch(soBatch,7);
        Test.stopTest();
        
        WorkOrder woCheck = [SELECT Id,Status FROM WorkOrder WHERE Id=:wo.Id];
        System.assert(woCheck.Status == 'Partially Fulfilled'); 
    }
    
    @isTest static void testMethod13(){
        User u = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name = 'test account' LIMIT 1];
        ServiceContract sc = [SELECT Id FROM ServiceContract WHERE Service_Type__c = 'New Store Install' LIMIT 1];
        Case cs = [SELECT Id FROM Case WHERE AccountId =: acc.Id AND Service_Type__c = 'New Store Install' LIMIT 1];
        WorkOrder wo = [SELECT Id From WorkOrder WHERE ServiceContractId =:sc.Id AND Status != 'Closed' limit 1];
        Sales_Order__c so = [SELECT Id,Order_Status__c FROM Sales_Order__c WHERE Work_Order__c =: wo.Id];
        System.runAs(u) {
            // The following code runs as user 'u'
            so.Order_Status__c = 'Partially Fulfilled';
            so.Outbound_Tracking_Numbers__c = '213';
            update so;
        }
        Test.startTest();
        SalesOrderBatch soBatch = new SalesOrderBatch();
        Database.executeBatch(soBatch,7);
        Test.stopTest();
        
        WorkOrder woCheck = [SELECT Id,Status FROM WorkOrder WHERE Id=:wo.Id];
        System.assert(woCheck.Status == 'Part Shipped'); 
    }
    
    @isTest static void testMethod14(){
        User u = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name = 'test account' LIMIT 1];
        ServiceContract sc = [SELECT Id FROM ServiceContract WHERE Service_Type__c = 'New Store Install' LIMIT 1];
        Case cs = [SELECT Id FROM Case WHERE AccountId =: acc.Id AND Service_Type__c = 'New Store Install' LIMIT 1];
        WorkOrder wo = [SELECT Id From WorkOrder WHERE ServiceContractId =:sc.Id AND Status != 'Closed' limit 1];
        Sales_Order__c so = [SELECT Id,Order_Status__c FROM Sales_Order__c WHERE Work_Order__c =: wo.Id];
        System.runAs(u) {
            // The following code runs as user 'u'
            so.Order_Status__c = 'Pending Fulfillment';
            so.SO_Order_Status__c = 'Hold';
            update so;
        }
        Test.startTest();
        SalesOrderBatch soBatch = new SalesOrderBatch();
        Database.executeBatch(soBatch,7);
        Test.stopTest();
        
        WorkOrder woCheck = [SELECT Id,Status FROM WorkOrder WHERE Id=:wo.Id];
        System.assert(woCheck.Status == 'Cannot Complete'); 
    }
    
    @isTest static void testMethod15(){
        User u = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name = 'test account' LIMIT 1];
        ServiceContract sc = [SELECT Id FROM ServiceContract WHERE Service_Type__c = 'New Store Install' LIMIT 1];
        Case cs = [SELECT Id FROM Case WHERE AccountId =: acc.Id AND Service_Type__c = 'New Store Install' LIMIT 1];
        WorkOrder wo = [SELECT Id From WorkOrder WHERE ServiceContractId =:sc.Id AND Status != 'Closed' limit 1];
        Sales_Order__c so = [SELECT Id,Order_Status__c FROM Sales_Order__c WHERE Work_Order__c =: wo.Id];
        System.runAs(u) {
            // The following code runs as user 'u'
            so.Order_Status__c = 'Pending Fulfillment';
            update so;
        }
        Test.startTest();
        SalesOrderBatch soBatch = new SalesOrderBatch();
        Database.executeBatch(soBatch,7);
        Test.stopTest();
        
        WorkOrder woCheck = [SELECT Id,Status FROM WorkOrder WHERE Id=:wo.Id];
        System.assert(woCheck.Status == 'Pending Fulfillment'); 
    }
    
    @isTest static void testMethod16(){
        User u = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name = 'test account' LIMIT 1];
        ServiceContract sc = [SELECT Id FROM ServiceContract WHERE Service_Type__c = 'New Store Install' LIMIT 1];
        Case cs = [SELECT Id FROM Case WHERE AccountId =: acc.Id AND Service_Type__c = 'New Store Install' LIMIT 1];
        WorkOrder wo = [SELECT Id From WorkOrder WHERE ServiceContractId =:sc.Id AND Status != 'Closed' limit 1];
        Sales_Order__c so = [SELECT Id,Order_Status__c FROM Sales_Order__c WHERE Work_Order__c =: wo.Id];
        System.runAs(u) {
            // The following code runs as user 'u'
            so.Order_Status__c = 'Pending Approval';
            so.SO_Order_Status__c = 'Hold';
            update so;
        }
        Test.startTest();
        SalesOrderBatch soBatch = new SalesOrderBatch();
        Database.executeBatch(soBatch,7);
        Test.stopTest();
        
        WorkOrder woCheck = [SELECT Id,Status FROM WorkOrder WHERE Id=:wo.Id];
        System.assert(woCheck.Status == 'Cannot Complete'); 
    }
}