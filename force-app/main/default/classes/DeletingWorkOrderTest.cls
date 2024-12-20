@isTest
public class DeletingWorkOrderTest {
    @testSetup static void setup() {
        Account rootAcc = TestDataFactory.createAccount();
        rootAcc.Name = 'Aldi Inc.';
        insert rootAcc;
        Product2 stagProd = TestDataFactory.createProduct2(rootAcc);
        stagProd.Name = 'Test Verifone E355 3-Unit Gang Charger';
        insert stagProd;
        rootAcc.Staging_Product__c = stagProd.Id;
        update rootAcc;
        Account acc = TestDataFactory.createAccount();
        acc.Root_Account__c = rootAcc.Id;
        acc.Source_Key__c = '1265865';
        insert acc;
        ServiceContract sc = TestDataFactory.createServiceContract(rootAcc);
        insert sc;
        Case cs = TestDataFactory.createCase(acc, sc);
        insert cs;
    }
    @isTest public static void coverDeletingWorkOrder(){
        Account acc = [SELECT Id FROM Account WHERE Name LIKE: 'Aldi%' LIMIT 1];
        ServiceContract sc = [SELECT Id FROM ServiceContract WHERE AccountId =:acc.Id LIMIT 1];
        Case cs = [SELECT Id FROM Case WHERE ServiceContractId=:sc.Id LIMIT 1];
        
        List<WorkOrder> woList = new List<WorkOrder>();
        WorkOrder wo = TestDataFactory.createWorkOrder(cs, sc,acc);
        wo.NetsuiteId__c = '';
        woList.add(wo);
        WorkOrder wo2 = TestDataFactory.createWorkOrder(cs, sc,acc);
        wo2.NetsuiteId__c = '';
        woList.add(wo2);
        insert woList;
        
        Test.startTest();
        Map<Id,String> invalidWOMap = DeletingWorkOrder.getInvalidWOs(wo.Id);
        System.assert(invalidWOMap.size() == 0);
        
        List<WorkOrder> woListCheck = DeletingWorkOrder.retreiveRelatedWOs(wo.Id);
        System.assert(woListCheck != null);
        System.assert(woListCheck.size() == 2);
        
        Boolean isDeleted2 = DeletingWorkOrder.deleteCurrentWorkOrder(wo.Id);
        System.assert(isDeleted2 == true);
        List<WorkOrder> woListCheck3 = [SELECT Id FROM WorkOrder];
        System.assert(woListCheck3.size() == 1);
        
        Boolean areDeleted = DeletingWorkOrder.deleteAllWOsAndCase(wo2.Id);
        System.assert(areDeleted == true);
        List<WorkOrder> woListCheck4 = [SELECT Id FROM WorkOrder];
        System.assert(woListCheck4.size() == 0);
        Test.stopTest();
    }
    
    @isTest public static void coverDeletingWorkOrder2(){
        Account acc = [SELECT Id FROM Account WHERE Name LIKE: 'Aldi%' LIMIT 1];
        ServiceContract sc = [SELECT Id FROM ServiceContract WHERE AccountId =:acc.Id LIMIT 1];
        Case cs = [SELECT Id FROM Case WHERE ServiceContractId=:sc.Id LIMIT 1];
        
        WorkOrder wo = TestDataFactory.createWorkOrder(cs, sc,acc);
        wo.NetsuiteId__c = 'Test';
        insert wo;
        
        Test.startTest();
        Map<Id,String> invalidWOMap = DeletingWorkOrder.getInvalidWOs(wo.Id);
        System.assert(invalidWOMap != null);
        Boolean exceptionThrown = false;
        try {
            Boolean isDeleted2 = DeletingWorkOrder.deleteCurrentWorkOrder(wo.Id);
            System.assert(isDeleted2 == false);
            List<WorkOrder> woListCheck = [SELECT Id FROM WorkOrder];
            System.assert(woListCheck.size() == 1);
        } catch (Exception e) {
            exceptionThrown = true;
            Boolean expectedExceptionThrown =  (e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) ? true : false; 
            System.AssertEquals(true, expectedExceptionThrown, e.getMessage()); 
        }
        Test.stopTest();
    }
}