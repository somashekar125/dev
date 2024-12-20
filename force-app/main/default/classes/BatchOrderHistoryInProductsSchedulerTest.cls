@isTest
public class BatchOrderHistoryInProductsSchedulerTest {
    @isTest static void testMethod1(){
        Test.startTest();
        BatchOrderHistoryInProductsScheduler sch = new BatchOrderHistoryInProductsScheduler();
        string cronExp = '0 1 0 * * ?';
        System.schedule('scheduler class', cronExp, sch);
        List<CronTrigger> ctList = [SELECT Id, CronJobDetail.Name, StartTime FROM CronTrigger WHERE CronJobDetail.Name = 'Batch12WeeksOrderHistoryInProducts'];
        System.assert(ctList != null);
        Test.stopTest();
    }
}