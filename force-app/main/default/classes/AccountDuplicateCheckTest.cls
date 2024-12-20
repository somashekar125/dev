@isTest
public class AccountDuplicateCheckTest {
    @isTest static void testMthod1(){
        list<account> acLst = new list<account>();
        Account ac = new Account();
        ac.Name = 'test asc account';
        ac.Account_Rep__c = userInfo.getUserId();
        ac.Source_Key__c = '5473';
        acLst.add(ac);
        
        Account ac2 = new Account();
        ac2.Name = 'test asc account';
        ac2.Account_Rep__c = userInfo.getUserId();
        ac2.Source_Key__c = '789875';
        acLst.add(ac2);
        
        Account ac3 = new Account();
        ac3.Name = 'test asc accou';
        ac3.Account_Rep__c = userInfo.getUserId();
        ac3.Source_Key__c = '125432';
        
        Test.startTest();
        insert acLst;
        ac.Name = 'test asc 1';
        update ac;
        insert ac3;
        ac3.Name = 'test asc 1';
        update ac3;
        Test.stopTest();
    }
}