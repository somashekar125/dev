public class BatchChangeDaylightTimezone implements Database.Batchable<sObject>, Schedulable {
    public Database.QueryLocator start(Database.BatchableContext bc){
        string query = 'SELECT Id, Timezone__c FROM Account WHERE Timezone__c IN (\'EST\', \'EDT\', \'CST\', \'CDT\', \'MST\', \'MDT\', \'PST\', \'PDT\')';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Account> scope){
        for(Account acc : scope){
            if(acc.Timezone__c == 'EST' || acc.Timezone__c == 'EDT'){
                acc.Timezone__c = (acc.Timezone__c == 'EST') ? 'EDT' : 'EST';
            }else if(acc.Timezone__c == 'CST' || acc.Timezone__c == 'CDT'){
                acc.Timezone__c = (acc.Timezone__c == 'CST') ? 'CDT' : 'CST';
            }else if(acc.Timezone__c == 'MST' || acc.Timezone__c == 'MDT'){
                acc.Timezone__c = (acc.Timezone__c == 'MST') ? 'MDT' : 'MST';
            }else if(acc.Timezone__c == 'PST' || acc.Timezone__c == 'PDT'){
                acc.Timezone__c = (acc.Timezone__c == 'PST') ? 'PDT' : 'PST';
            }
        }
        update scope;
    }
    
    public void finish(Database.BatchableContext bc){
        
    }
    
    public void execute(SchedulableContext sc){
        BatchChangeDaylightTimezone batchClass = new BatchChangeDaylightTimezone();
        Database.executeBatch(batchClass);
    }
}