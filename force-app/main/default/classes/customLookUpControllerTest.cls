@isTest
public class customLookUpControllerTest {
    @IsTest static void testMethod1(){
        Test.startTest();
        List<Account> rootAccList = new List<Account>();
        Account rootAcc = TestDataFactory.createAccount();
        rootAcc.Name = 'root account';
        rootAccList.add(rootAcc);
        Account rootAcc2 = TestDataFactory.createAccount();
        rootAcc2.Name = 'Premium Brands Services, LLC';
        rootAcc2.Source_Key__c = '567';
        rootAccList.add(rootAcc2);
        insert rootAccList;
        
        Account childAcc = TestDataFactory.createAccount();
        childAcc.Name = 'child Account';
        childAcc.ParentId = rootAccList[0].Id;
        childAcc.Root_Account__c = rootAccList[0].Id;
        childAcc.Source_Key__c = '45';
        insert childAcc;
        
        list<Product2> prodList = new list<Product2>();
        Product2 prod = TestDataFactory.createProduct2(rootAccList[0]);
        prod.Name = 'test1 Product (New)';
        prod.Source_Key__c = '56789';
        Product2 prod1 = TestDataFactory.createProduct2(rootAccList[0]);
        prod1.Name = 'test Product (Refurbished)';
        prod1.Source_Key__c = '5678989';
        Product2 prod2 = TestDataFactory.createProduct2(rootAccList[1]);
        prod2.Source_Key__c = '5673489';

        prodList.add(prod);
        prodList.add(prod1);
        prodList.add(prod2);
        insert prodList;
        
        List < sObject > prodList1 = customLookUpController.fetchLookUpValues('test', 'Product2', rootAccList[0].Id,null,5);
        List < sObject > prodList2 = customLookUpController.fetchLookUpValues('test1', 'Product2', rootAccList[0].Id,null,5);
        List < sObject > prodList3 = customLookUpController.fetchLookUpValues('test', 'Product2', rootAccList[1].Id,null,5);
        List < sObject > prodList4 = customLookUpController.fetchLookUpValues('test', 'Project__c', rootAccList[0].Id,null,5);
        List < sObject > prodList5 = customLookUpController.fetchLookUpValues('test', 'Account', rootAccList[0].Id,null,5);
        List < sObject > prodList6 = customLookUpController.fetchLookUpValues('root', 'RootAccounts', rootAccList[0].Id,null,5);
        List < sObject > prodList7 = customLookUpController.fetchLookUpValues('child', 'ChildAccounts', rootAccList[0].Id,null,5);
        
        System.assert(prodList1 != null);
        System.assert(prodList1.size() == 2);
        System.assert(prodList2 != null);
        System.assert(prodList2.size() == 1);
        System.assert(prodList3 != null);
        System.assert(prodList3.size() == 1);
        System.assert(prodList4.size() == 0);
        System.assert(prodList5.size() == 0);
        System.assert(prodList6 != null);
        System.assert(prodList6.size() == 1);
        System.assert(prodList7 != null);
        System.assert(prodList7.size() == 1);
        Test.stopTest();
    }
}