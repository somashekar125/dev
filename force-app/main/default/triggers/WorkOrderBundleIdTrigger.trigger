trigger WorkOrderBundleIdTrigger on WorkOrder (before insert) {
    set<Id> recTypeIds = new set<Id>();
    for(WorkOrder wo : trigger.new){
        recTypeIds.add(wo.RecordTypeId);
    }
    list<RecordType> recLst = [select Id, Name, DeveloperName from RecordType where Id IN : recTypeIds];
    for(WorkOrder w : trigger.new){
        for(RecordType r : recLst){
            if((w.RecordTypeId == r.Id) && (r.DeveloperName == 'Bundle_Work_Order')){
                final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
                String randStr = '';
                while (randStr.length() < 15) {
                    Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
                    randStr += chars.substring(idx, idx+1);
                }
                System.debug('bundle id--->'+randStr);
                w.Bundle_Id__c = randStr;
            }
        }
    }
}