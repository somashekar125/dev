@isTest
public class BatchChangeDaylightTimezoneTest {
	@isTest static void testMethod1(){
        Account acc = new Account();
        acc.Name = 'test account';
        acc.Source_Key__c = '12345';
        acc.Account_Rep__c = userInfo.getUserId();
        acc.Timezone__c = 'PST';
        
        Test.startTest();
        insert acc;
        BatchChangeDaylightTimezone sch = new BatchChangeDaylightTimezone();
        string cronExp = '0 0 0 ? 3 SUN#2 *';
        System.schedule('scheduler class', cronExp, sch);
        Test.stopTest();
    }
}