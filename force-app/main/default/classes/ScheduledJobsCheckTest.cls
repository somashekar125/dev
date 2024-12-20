@isTest
public class ScheduledJobsCheckTest {
	@isTest static void testMethod1(){
        Test.startTest();
        ScheduledJobsCheck sjob = new ScheduledJobsCheck();
        Database.executeBatch(sjob,7);
        Test.stopTest();
        List<CronTrigger> ctList = [SELECT Id, CronJobDetail.Name, StartTime FROM CronTrigger WHERE (CronJobDetail.Name = 'Sales Order Batch'
                                    OR CronJobDetail.Name = 'BatchSendProductInventoryEmails')];
        System.assert(ctList != null);
    }
}