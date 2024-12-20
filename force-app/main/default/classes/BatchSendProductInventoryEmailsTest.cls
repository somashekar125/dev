@isTest
public class BatchSendProductInventoryEmailsTest {
    @isTest static void testMethod1(){
        Account acc = TestDataFactory.createAccount();
        insert acc;
        
        contact con = new contact();
        con.LastName = 'test';
        con.AccountId = acc.Id;
        con.Email = 'test@asc.com';
        con.Receive_Inventory_Notifications__c = true;
        insert con;
        Product2 originalProduct = new Product2(Name = 'test RMA Return', Account_Item_Belongs_To__c = acc.Id, Portal_Access__c = true,
                                                Reorder_Point__c = 5, Critical_Quantity__c = 4, Inventory_Email_Sent__c = false, Critical_Email_Sent__c = false,
                                                Family = 'Hardware', IsActive = true, NS_Quantity_Available__c = 5, Quantity_Available__c = 4);
        insert originalProduct;
        Test.startTest();
        BatchSendProductInventoryEmails bpi = new BatchSendProductInventoryEmails();
        Database.executeBatch(bpi);
        Test.stopTest();
        Product2 prodCheck = [SELECT Id,Inventory_Email_Sent__c FROM Product2 WHERE Id =:originalProduct.Id];
        System.assert(prodCheck.Inventory_Email_Sent__c == true);
    }
}