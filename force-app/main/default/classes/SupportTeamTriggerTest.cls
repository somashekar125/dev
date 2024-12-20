@isTest
public class SupportTeamTriggerTest {
    @isTest static void testMethod1(){
        Test.startTest();
        Support_Team__c st = new Support_Team__c();
        st.Tech_Notes__c = 'test';
        insert st;
        st.Tech_Notes__c = 'test 1234';
        update st;
        Support_Team__c stCheck = [SELECT Id,Tech_Notes__c FROM Support_Team__c WHERE Id =:st.Id];
        System.assert(stCheck.Tech_Notes__c == 'test 1234');
        Test.stopTest();
    }
}