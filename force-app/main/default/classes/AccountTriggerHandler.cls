public class AccountTriggerHandler {
    public static boolean runOnceBeforeUpdate = true;
    public static boolean runOnceAfterUpdate = true;
    public static void handleBeforeInsert(List<Account> accList){
        populateTimeZone(accList); 
    }
    
    public static void handleAfterInsert(Map<Id,Account> newMap) {
        setRootAccount(newMap, null);
        setAccountType(newMap,null);
    }

    public static void handleBeforeUpdate(Map<Id, Account> newMap, Map<Id, Account> oldMap) {
        if(runOnceBeforeUpdate) populateTimeZone(newMap.values());
    }
    
    public static void handleAfterUpdate(Map<Id, Account> newMap, Map<Id, Account> oldMap) {
        if(runOnceAfterUpdate){
            setRootAccount(newMap, oldMap);
            setAccountType(newMap,oldMap);
        }
    }

    public static void populateTimeZone(List<Account> accList) {
        Set<String> stateSet = new Set<String>();
        for(Account acc : accList){
            if(String.isBlank(acc.Timezone__c) && !String.isBlank(acc.ShippingState)) stateSet.add(acc.ShippingState);
        }
        if(!stateSet.isEmpty()){
            List<Account> existAccList = [SELECT Id,ShippingState, Timezone__c FROM Account WHERE ShippingState =: stateSet ORDER BY ShippingState LIMIT 500];
            Map<String,Integer> tmzCountMap = new Map<String,Integer>();
            Map<String,Map<String,Integer>> stateTimezoneMap = new Map<String,Map<String,Integer>>();
            Map<String,String> stateTimezoneMap2 = new Map<String,String>();

            for(Account acc : existAccList){
                if(String.isBlank(acc.Timezone__c) || String.isBlank(acc.ShippingState)) continue;
                if(tmzCountMap.containsKey(acc.Timezone__c)) {
                    Integer count = tmzCountMap.get(acc.Timezone__c);
                    count++;
                    tmzCountMap.put(acc.Timezone__c,count);
                    stateTimezoneMap.put(acc.ShippingState,tmzCountMap);
                } else {
                    tmzCountMap.put(acc.Timezone__c,1);
                    stateTimezoneMap.put(acc.ShippingState,tmzCountMap);
                }
            }
            for(String st : stateTimezoneMap.keySet()){
                String tmz = null;
                Integer tmCount = 0;
                for(String s : stateTimezoneMap.get(st).keySet()) {
                    if(tmzCountMap.get(s) > tmCount) {
                        tmCount = tmzCountMap.get(s);
                        tmz = s;
                    }
                }
                if(tmz != null) stateTimezoneMap2.put(st,tmz);
            }

            for(Account acc : accList){
                if(!String.isBlank(acc.Timezone__c) || String.isBlank(acc.ShippingState)) continue;
                if(stateTimezoneMap2.containsKey(acc.ShippingState)) acc.Timezone__c = stateTimezoneMap2.get(acc.ShippingState);
            }
        }
    }
    
    public static void setAccountType(Map<Id,Account> newMap, Map<Id,Account> oldMap) {
        List<Account> accList = [SELECT Id, Name, Type, Store_Branch__c, ParentId, Parent.Name, Parent.ParentId, Parent.Type, Root_Account__c, 
                                 Root_Account__r.Name, Root_Account__r.Type,(SELECT Id FROM ChildAccounts) FROM Account WHERE Id IN : newMap.keySet() ORDER BY Name];
        Set<Id> parenRootIds = new Set<Id>();
        for(Account acc : accList){
            if(acc.ParentId != null) parenRootIds.add(acc.ParentId);
            if(acc.Root_Account__c != null && acc.ParentId != acc.Root_Account__c) parenRootIds.add(acc.Root_Account__c);
        }
        Map<Id,Account> parentRootAccMap = new Map<Id,Account>([SELECT Id, Name, Type FROM Account WHERE Id IN: parenRootIds ORDER BY Name]);
        Map<Id,Account> branRootAccountMap = new Map<Id,Account>();
        for(Account acc : accList){
            acc.Type = 'Store';
            if(acc.ParentId != null && acc.Root_Account__c != null && acc.ParentId == acc.Root_Account__c && acc.ChildAccounts.size() != 0) acc.Type = 'Brand';
            if(acc.ParentId == null && acc.Root_Account__c == null && acc.ChildAccounts.size() != 0) acc.Type = 'Corporate';

            if(!String.isBlank(acc.Store_Branch__c)) {
                List<String> tempList = acc.Store_Branch__c.split(' ');
                for(String s : tempList){
                    //Brandon
                    if(s.containsIgnoreCase('Brand') && s.length() == 5) acc.Type = 'Brand';
                    if(s.containsIgnoreCase('Brands') && s.length() == 6) acc.Type = 'Brand';

                    if(s.containsIgnoreCase('CORP') && s.length() == 4) acc.Type = 'Corporate';
                    if(s.containsIgnoreCase('CORPORATE')) acc.Type = 'Corporate';
                }
            }
            if(acc.ChildAccounts.size() == 0){
                List<String> tempList2 = acc.Name.split(' ');
                for(String s : tempList2){
                    if(s.containsIgnoreCase('Brand') && s.length() == 5) acc.Type = 'Brand';
                    if(s.containsIgnoreCase('Brands') && s.length() == 6) acc.Type = 'Brand';
                }
                if(acc.Name.containsIgnoreCase('CORPORATE')) acc.Type = 'Corporate';
            }
            branRootAccountMap.put(acc.Id,acc);
            if(acc.ParentId != null && parentRootAccMap.containsKey(acc.ParentId)) {
                Account parentAcct = new Account(Id = acc.ParentId);
                parentAcct.Type = (acc.Root_Account__c != null && acc.ParentId != acc.Root_Account__c) ? 'Brand' : 'Corporate';

                if(parentRootAccMap.get(acc.ParentId).Type != parentAcct.Type) branRootAccountMap.put(parentAcct.Id,parentAcct);
            }
            if(acc.Root_Account__c != null && acc.ParentId != acc.Root_Account__c && parentRootAccMap.containsKey(acc.Root_Account__c)) {
                Account rootAcct = new Account(Id = acc.Root_Account__c);
                rootAcct.Type = 'Corporate';
                if(parentRootAccMap.get(acc.Root_Account__c).Type != rootAcct.Type) branRootAccountMap.put(rootAcct.Id,rootAcct);
            }
        }
        runOnceBeforeUpdate = false;
        runOnceAfterUpdate = false;
        Database.update(branRootAccountMap.values(),false);
    }

    public static void setRootAccount(Map<Id,Account> newMap, Map<Id,Account> oldMap) {
        Set<Id> parentAcctIds = new Set<Id>();
        List<Account> toUpdateList = new List<Account>();
        for(Account acc : newMap.values()){
            
            if(acc.Root_Account__c == null && acc.ParentId != null) {
                parentAcctIds.add(acc.ParentId);
                System.debug('toUpdateList--> '+parentAcctIds);
            } else if(oldMap != null && acc.ParentId != oldMap.get(acc.Id).ParentId){
                parentAcctIds.add(acc.ParentId);
            }
        }
        if(!parentAcctIds.isEmpty()){
            List<Account> parentAcctList = [SELECT Id,Name,ParentId,Root_Account__c FROM Account WHERE Id IN: parentAcctIds];
            for(Account childAcc : newMap.values()){
                Id rootAccountId = null;
                Account toUpdateAcc = new Account(Id = childAcc.Id);
                for(Account parentAcc : parentAcctList){
                    if(parentAcc.Id != childAcc.ParentId) continue;
                    if(parentAcc.ParentId != null && rootAccountId == null) rootAccountId = parentAcc.ParentId;
                    if(parentAcc.Root_Account__c != null && rootAccountId == null) rootAccountId = parentAcc.Root_Account__c;
                    if(rootAccountId == null) rootAccountId = parentAcc.Id;
                    toUpdateAcc.Root_Account__c = rootAccountId;
                    if(toUpdateAcc.Root_Account__c != null) toUpdateList.add(toUpdateAcc);
                    break;
                }
            }
            if(!toUpdateList.isEmpty()){
                System.debug('toUpdateList-->'+toUpdateList);
                runOnceBeforeUpdate = false;
                runOnceAfterUpdate = false;
                Database.update(toUpdateList,false);
            }
        }
    }
}