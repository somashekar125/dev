public class BundleWorkorders {
    @auraEnabled
    public static List<WorkOrder> totAccWorkOrders(String accId, String bndlId){
        System.debug('account Id--->'+accId);
        List<WorkOrder> woList = [SELECT Id, WorkOrderNumber, Bundle_Id__c, Priority, AccountId, Product__c, CreatedDate, Account.Name, Product__r.Name, Service_Type__c FROM WorkOrder WHERE AccountId =: accId AND (Bundle_Id__c !=: bndlId) AND RecordType.DeveloperName != 'Bundle_Work_Order' AND Status = 'New'];
        return woList;
    }
    
    @auraEnabled
    public static List<WorkOrder> bndlWOs(String bndlId, String bndWoId){
        System.debug('bundle Id--->'+bndlId);
        List<WorkOrder> woLst = [SELECT Id, WorkOrderNumber, Bundle_Id__c, AccountId, Priority, Product__c, CreatedDate, Account.Name, Product__r.Name, Service_Type__c FROM WorkOrder WHERE Bundle_Id__c =: bndlId AND Id != :bndWoId];
        System.debug('work order bundles-->'+woLst);
        return woLst;
    }
    
    @auraEnabled
    public static WorkOrder bndlWordOrdr(String bndlWoId){
        System.debug('bundle Id--->'+bndlWoId);
        WorkOrder woLst = [SELECT Id, WorkOrderNumber, Bundle_Id__c, AccountId, Product__c, Priority, CreatedDate, Account.Name, Product__r.Name, Service_Type__c FROM WorkOrder WHERE Id =: bndlWoId limit 1];
        System.debug('work order --->'+woLst);
        return woLst;
    }
    
    @auraEnabled
    public static String saveToBndl(List<WorkOrder> woLst){
        System.debug('workorder List to save --->'+woLst);
        String saveStatus = '';
        try{
            update woLst;
            saveStatus = 'success';
        }catch(DmlException ex){
            saveStatus = ex.getDmlMessage(0);
        }
        return saveStatus;
    }
}