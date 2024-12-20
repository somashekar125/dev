@isTest
public class BatchDeleteWOsFromFNTest{
    static testMethod void testMethod1(){
		Account acc = new Account();
        acc.Name = 'PBS-04';
        acc.Account_Rep__c = userInfo.getUserId();
        list<Timezone_Id__mdt> tzm = [SELECT MasterLabel, QualifiedApiName, Timezon_Id__c FROM Timezone_Id__mdt];
        acc.Timezone__c = tzm[0].MasterLabel;
        
        test.startTest();
        insert acc;
        Account acc2 = new Account();
        acc2.Name = 'Loft';
        acc2.ParentId = acc.Id;
        acc2.Account_Rep__c = userInfo.getUserId();
        insert acc2;
        
        Account acc3 = new Account();
        acc3.Name = 'test account';
        acc3.ParentId = acc2.Id;
        acc3.Account_Rep__c = userInfo.getUserId();
        insert acc3;
        
        BatchDeleteWOsFromFN delWOs = new BatchDeleteWOsFromFN();
        Database.ExecuteBatch(delWOs);
        
        test.stopTest();
    }
}