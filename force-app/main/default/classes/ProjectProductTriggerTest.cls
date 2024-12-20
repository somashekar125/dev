@isTest
public class ProjectProductTriggerTest {
    @isTest static void testMethod1(){
        Test.startTest();
        Project__c proj = new Project__c();
        proj.Name = 'test';
        insert proj;
        Project_Product__c pp = new Project_Product__c();
        pp.Primary_Product__c = true;
        pp.Project__c = proj.Id;
        insert pp;
        Test.stopTest();
    }
}