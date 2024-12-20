trigger AccountDupicateCheck on Account (before insert, before update) {
    set<string> accNames = new set<string>();
    for(Account ac : trigger.new){
        accNames.add(ac.Name);
    }
    System.debug('account names--->'+accNames);
    list<Account> accLst = [select Id, Name from Account where Name IN : accNames];
    System.debug('accounts with dup names--->'+accLst.size());
    if(trigger.isInsert){
        for(Account acc : trigger.new){
            if(accLst.size() != 0){
                acc.addError('Account with this name is already exist!');
            }
        }
    }
    if(trigger.isUpdate){
        for(Account a : trigger.new){
            for(Account acct : accLst){
                if((a.Name != Trigger.oldMap.get(a.Id).Name) && (a.Name == acct.Name)){
                    a.addError('Account with this name is already exist!');
                }
            }
        }
    }
}