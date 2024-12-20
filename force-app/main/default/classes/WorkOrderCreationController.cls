public class WorkOrderCreationController {
    @AuraEnabled
    public static Case getCaseRec(String caseId){
        System.debug('caseId-> ' + caseId);
        return [SELECT Id,OwnerId, Description,AccountId,Priority,Root_Account__c,
                Incident__c,ProductId,Service_Type__c,ServiceContractId,
                ServiceContract.Pricebook2Id,Tech_Notes__c,POS_Register_Number__c,
                Equipment_Type__c,Problem_Type__c,Department2__c 
                FROM Case WHERE Id =:caseId];
    }

    @AuraEnabled
    public static RecordType getRecordType(){
        RecordType rt = [SELECT Id,Name,SobjectType FROM RecordType WHERE Name = 'Part Ordering' and SobjectType = 'WorkOrder'];
        System.debug('RecordType rt-> ' + rt);
        return rt;
    }

    @AuraEnabled
    public static ServiceContract getServiceContract(String ServiceContractId,Boolean onsiteSC){
        System.debug('ServiceContractId-> ' + ServiceContractId);
        System.debug('onsiteSC-> ' + onsiteSC);
        ServiceContract  sc = [SELECT Id, Name FROM ServiceContract WHERE Id =:ServiceContractId];
        ServiceContract scList1 = new ServiceContract();
        if(sc.Name.containsIgnoreCase('Part + Onsite')){
            if(onsiteSC == true){
                List<ServiceContract> scList = [SELECT Id,Name,ParentServiceContractId FROM ServiceContract WHERE ParentServiceContractId =:sc.Id 
                                                AND Work_Order_Record_Type__c = 'Onsite Labor'];
                if(!scList.isEmpty()){
                    scList1 = scList[0];
                }
                return scList1;
            } else {
                List<ServiceContract> scList = [SELECT Id,Name,ParentServiceContractId FROM ServiceContract WHERE ParentServiceContractId =:sc.Id 
                                                AND Work_Order_Record_Type__c = 'Part Shipment'];
                if(!scList.isEmpty()){
                    scList1 = scList[0];
                }
                System.debug('scList1 Name-> ' + scList1.Name);
                return scList1;
            }
        } else {
            return sc;
        }
    }
}