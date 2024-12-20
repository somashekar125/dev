@isTest
public class BundleWorkOrdersTest {
    @testSetup static void setup() {
        Test.startTest();
        Account acc = TestDataFactory.createAccount();
        insert acc;
        ServiceContract sc = TestDataFactory.createServiceContract(acc);
        insert sc;
        Case cs = TestDataFactory.createCase(acc, sc);
        insert cs;
        
        Test.stopTest();
    }
    
    @isTest static void testMethod1(){
        Account acc = [SELECT Id FROM Account WHERE Name = 'test account' LIMIT 1];
        ServiceContract sc = [SELECT Id FROM ServiceContract WHERE Name = 'test ServiceContract' LIMIT 1];
        Case cs = [SELECT Id FROM Case WHERE AccountId =: acc.Id AND Service_Type__c = 'Advance Exchange (Depot Only)' LIMIT 1];
        Id bndlRT = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Bundle_Work_Order').getRecordTypeId();
        
        list<WorkOrder> woList = new list<WorkOrder>();
        WorkOrder wo = TestDataFactory.createWorkOrder(cs, sc, acc);
        wo.RecordTypeId = bndlRT;
        woList.add(wo);
        
        WorkOrder wo2 = TestDataFactory.createWorkOrder(cs, sc, acc);
        woList.add(wo2);
        insert woList;
        
        Test.startTest();
        list<WorkOrder> woCheckList = BundleWorkorders.totAccWorkOrders(acc.Id, 'sjdhflaksdjh');
        list<WorkOrder> woCheckList2 = BundleWorkorders.bndlWOs('ajshdljslkdj', woList[0].Id);
        WorkOrder woCheck = BundleWorkorders.bndlWordOrdr(woList[0].Id);
        String saveStatus = BundleWorkorders.saveToBndl(woList);
        
        System.assert(woCheckList != null);
        System.assert(woCheckList2 != null);
        System.assert(woCheck != null);
        System.assert(String.isNotBlank(saveStatus));
        System.assert(saveStatus == 'success');
        Test.stopTest();
    }
}