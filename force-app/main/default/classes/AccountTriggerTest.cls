@isTest
public class AccountTriggerTest {
    @testSetup static void setup() {
        Test.startTest();
        List<Account> rootAccList = new List<Account>();
        Account rootAcc = new Account();
        rootAcc.Name = 'Test Root Account';
        rootAcc.Source_Key__c = '6489';
        rootAcc.Store_Branch__c = 'CORP';
        rootAcc.ShippingState = 'AL';
        rootAcc.Timezone__c = 'CST';
        rootAccList.add(rootAcc);
        
        Account rootAcc2 = new Account();
        rootAcc2.Name = 'Test Root Account 2';
        rootAcc2.Source_Key__c = '657489';
        rootAcc2.ShippingState = 'AL';
        rootAcc2.Timezone__c = 'CST';
        rootAccList.add(rootAcc2);
        insert rootAccList;
        
        List<Account> accList = new List<Account>();
        Account parentAcc1 = new Account();
        parentAcc1.Name = 'Brand Account 1';
        parentAcc1.Source_Key__c = '12345';
        parentAcc1.ParentId = rootAcc.Id;
        parentAcc1.Store_Branch__c = 'Brand';
        parentAcc1.ShippingState = 'AL';
        accList.add(parentAcc1); 
        
        Account parentAcc2 = new Account();
        parentAcc2.Name = 'Brand Account 2';
        parentAcc2.Source_Key__c = '12346';
        parentAcc2.ParentId = rootAcc2.Id;
        parentAcc2.ShippingState = 'AL';
        accList.add(parentAcc2);
        insert accList;
        
        Account parentAcc1Check = [SELECT Id,Root_Account__c FROM Account WHERE Id =: parentAcc1.Id];
        System.assert(parentAcc1Check.Root_Account__c == rootAcc.Id);
        Account parentAcc2Check = [SELECT Id,Root_Account__c FROM Account WHERE Id =: parentAcc2.Id];
        System.assert(parentAcc2Check.Root_Account__c == rootAcc2.Id);
        
        List<Account> accList2 = new List<Account>();
        Account acc1 = new Account();
        acc1.Name = 'Store Account 1';
        acc1.ParentId = parentAcc1.Id;
        acc1.Source_Key__c = '12348';
        acc1.ShippingState = 'AL';
        accList2.add(acc1);
        
        Account acc2 = new Account();
        acc2.Name = 'Store Account 2';
        acc2.ParentId = parentAcc2.Id;
        acc2.Source_Key__c = '12349';
        acc2.ShippingState = 'AL';
        accList2.add(acc2);
        insert accList2;
        
        Account acc1Check = [SELECT Id,Root_Account__c FROM Account WHERE Id =: acc1.Id];
        System.assert(acc1Check.Root_Account__c == rootAcc.Id);
        Account acc2Check = [SELECT Id,Root_Account__c FROM Account WHERE Id =: acc2.Id];
        System.assert(acc2Check.Root_Account__c == rootAcc2.Id);
        Test.stopTest();
    }
    
    @isTest static void testMethod1(){
        Account rootAcc2 = [SELECT Id FROM Account WHERE Name = 'Test Root Account 2'];
        Account parentAcc2 = [SELECT Id FROM Account WHERE Name = 'Brand Account 2'];
        Account storeAcc1 = [SELECT Id FROM Account WHERE Name = 'Store Account 1'];

        Test.startTest();
        storeAcc1.ParentId = parentAcc2.Id;
        update storeAcc1;
        
        Account storeAcc1Check = [SELECT Id,Root_Account__c,ParentId FROM Account WHERE Id =: storeAcc1.Id];
        System.assert(storeAcc1Check.Root_Account__c == rootAcc2.Id);
        Test.stopTest();
    }
}