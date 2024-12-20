public class BatchDeleteWOsFromFN implements Database.Batchable<sObject>{
    public Database.QueryLocator start(Database.BatchableContext bc){
        list<Account> accList = [SELECT Id, ParentId, (SELECT Id, Name FROM ChildAccounts) FROM Account WHERE Parent.Name = 'PBS-04'];
        set<Id> accIds = new set<Id>();
        if(accList.size() != 0){
            for(Account ac : accList){
                accIds.add(ac.Id);
                for(Account a : ac.ChildAccounts){
                    accIds.add(a.Id);
                }
            }
            accIds.add(accList[0].ParentId);
        }
        String query = 'SELECT Id, From_FN__c FROM WorkOrder WHERE AccountId IN : accIds AND Source__c = \'FieldNation\'';
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext bc, list<WorkOrder> scope){
        System.debug('Delete WO Scope:'+scope);
        delete scope;
    }
    public void finish(Database.BatchableContext bc){
        BatchDeleteWOsFromFN delWOs = new BatchDeleteWOsFromFN();
        if(!test.isRunningTest()){
            System.scheduleBatch(delWOs, 'BatchDeleteWOsFromFN', 5);
        }
    }
}