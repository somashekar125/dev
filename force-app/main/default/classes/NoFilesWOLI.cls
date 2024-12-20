global without sharing class NoFilesWOLI {
    @AuraEnabled
    webservice static void updateWOLI(){
        list<WorkOrderLineItem> woliList = [SELECT Id,No_Images__c,(SELECT Id FROM ContentDocumentLinks) FROM WorkOrderLineItem
                                    WHERE WorkOrder.Account.Name LIKE 'BOSCOV%'];
        integer count = 1;
        list<WorkOrderLineItem> listToUpdate = new list<WorkOrderLineItem>();
        for(WorkOrderLineItem woli : woliList){
            if(woli.ContentDocumentLinks.size() == 0){
                woli.No_Images__c = true;
                listToUpdate.add(woli);
                System.debug('woliId: ' + woli.id + ' count:' + count);
                count+=1;
            }
        }
        update listToUpdate;
    }
}