@isTest
public class CheckInactiveProductsBatchTest {
    @isTest static void testMethod1(){
        Account acc = TestDataFactory.createAccount();
        insert acc;
        
        ServiceContract sc = TestDataFactory.createServiceContract(acc);
        insert sc;
        
        Product2 prod = TestDataFactory.createProduct2(acc);
        insert prod;
        
        PricebookEntry standardPrice = TestDataFactory.createPricebookEntry(prod);
        insert standardPrice;
        
        ContractLineItem cli = new ContractLineItem();
        cli.ServiceContractId = sc.Id;
        cli.PricebookEntryId = standardPrice.id;
        cli.UnitPrice = 100;
        cli.Quantity =1 ;
        insert cli;
        
        Test.startTest();
        CheckInactiveProductsBatch cipBatch = new CheckInactiveProductsBatch();
        Database.executeBatch(cipBatch,7);
        Test.stopTest();
        ServiceContract scCheck = [SELECT Id,Inactive_Products__c FROM ServiceContract WHERE Id =: sc.Id];
        System.assert(scCheck.Inactive_Products__c != null);
    }
}