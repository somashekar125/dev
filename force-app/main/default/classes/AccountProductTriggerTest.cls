@isTest
public class AccountProductTriggerTest {
	@isTest static void testMethod1(){
        Account acc = TestDataFactory.createAccount();
        insert acc;
        Product2 prod = TestDataFactory.createProduct2(acc);
        insert prod; 
        
        Test.startTest();
        Account_Product__c ap = new Account_Product__c();
        ap.Account__c = acc.Id;
        ap.Product__c = prod.Id;
        ap.Name = 'test';
        insert ap;
        Test.stopTest();
        
       	List<Account_Product__c> apList = [SELECT Id FROM Account_Product__c WHERE Product__c =: prod.Id];
        System.debug('apList-> ' + apList);
        System.assert(apList.size() == 2); //one from ProductTriggerHandler and one from above.
    }
}