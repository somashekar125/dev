public with sharing class ScheduledJobsCheck implements Database.Batchable<sObject>{
    public Database.QueryLocator start(Database.BatchableContext bc){
        String query = 'SELECT Id, CronJobDetailId, CronJobDetail.Name, NextFireTime, PreviousFireTime, State, StartTime, EndTime,'
                        + 'CronExpression, TimeZoneSidKey, OwnerId, TimesTriggered FROM CronTrigger WHERE (CronJobDetail.Name = \'Sales Order Batch\' OR'
                        + ' CronJobDetail.Name = \'BatchSendProductInventoryEmails\')';        
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext BC, List<sObject> scope){
        User u = [SELECT Id,Name FROM user WHERE Name = 'Vaibhav Patil' LIMIT 1];
        EmailTemplate et = [SELECT Id,Name FROM EmailTemplate WHERE developername ='SalesOrderBatch_Fail'];
        for(SObject sobj : scope){
            CronTrigger ct = (CronTrigger) sobj;
            Integer diff;
            System.debug('ct.StartTime.minute()-> ' + ct.StartTime.minute());
            System.debug('System.now().minute()-> ' + System.now().minute());
            diff = ct.StartTime.minute() - System.now().minute();
            if(test.isRunningTest()){
                diff = 20;
            }
            System.debug('diff-> ' + diff);
            System.debug('ct.CronJobDetail.Name-> ' + ct.CronJobDetail.Name);
            if(diff >= 20 && (ct.CronJobDetail.Name == 'Sales Order Batch' || ct.CronJobDetail.Name == 'BatchSendProductInventoryEmails')){
                System.debug('ct.CronJobDetail.Name Mail Sent-> ' + ct.CronJobDetail.Name);
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setTargetObjectId(u.Id);
                String[] sendingTo = new String[]{'vaibhavp@aspiresoftwareconsultancy.com'};
                mail.setToAddresses(sendingTo);
                //String[] sendingToBccAdd = new String[]{'vaibhav.patil@aspiresoftwareconsultancy.com'};
                //mail.setBccAddresses(sendingToBccAdd);
                mail.setTemplateId(et.id);
                mail.saveAsActivity = false;
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
            }
        }
    }
    public void finish(Database.BatchableContext BC){
        List<CronTrigger> ctList = [SELECT Id, CronJobDetail.Name, StartTime FROM CronTrigger WHERE (CronJobDetail.Name = 'Sales Order Batch'
                                    OR CronJobDetail.Name = 'BatchSendProductInventoryEmails')];
        List<String> jobList = new List<String>();
        for(CronTrigger ct : ctList){
            jobList.add(ct.CronJobDetail.Name);
            Integer diff;
            diff = ct.StartTime.minute() - System.now().minute();
            if(test.isRunningTest()){
                diff = 20;
            }
            if(diff >= 20 && (ct.CronJobDetail.Name == 'Sales Order Batch' || ct.CronJobDetail.Name == 'BatchSendProductInventoryEmails')){
                System.abortJob(ct.Id);
                if(ct.CronJobDetail.Name == 'Sales Order Batch'){
                    SalesOrderBatch soBatch = new SalesOrderBatch();
                    Database.executeBatch(soBatch,1);
                }
                if(ct.CronJobDetail.Name == 'BatchSendProductInventoryEmails'){
                    BatchSendProductInventoryEmails soBatch = new BatchSendProductInventoryEmails();
                    Database.executeBatch(soBatch,1);
                }
            }
        }
        System.debug('jobList-> ' + JSON.Serialize(jobList));
        if(!jobList.contains('Sales Order Batch')){
            SalesOrderBatch soBatch = new SalesOrderBatch();
            Database.executeBatch(soBatch,1);
        }
        if(!jobList.contains('BatchSendProductInventoryEmails')){
            BatchSendProductInventoryEmails emailBatch = new BatchSendProductInventoryEmails();
            Database.executeBatch(emailBatch,1);
        }
        if(!test.isRunningTest()){
            System.scheduleBatch(new ScheduledJobsCheck(), 'Scheduled Jobs Check', 10, 1);
        }
    }        
}