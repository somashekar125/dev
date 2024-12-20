public class ReturnOrderTriggerHandler {
    public static void handleBeforeInsert(List<ReturnOrder> roList) {
        setCaseId(roList);
        createInventoryRecords(roList);
    }
    
    public static void handleBeforeUpdate(Map<Id,ReturnOrder> newMap, Map<Id,ReturnOrder> oldMap) {
        setCaseId(newMap.values());
    }
    
    public static void setCaseId(List<ReturnOrder> roList) {
        Set<Id> soIds = new Set<Id>();
        for(ReturnOrder ro : roList){
            if(ro.CaseId != null) continue;
            soIds.add(ro.Sales_Order__c);
        }                                                            
        Map<Id,Sales_Order__c> soMap = new Map<Id,Sales_Order__c>([SELECT Id,Case__c FROM Sales_Order__c 
                                                                   WHERE Case__c != NULL AND Id IN :soIds]);
        for(ReturnOrder ro : roList){
            if(ro.CaseId != NULL) continue;
            if(!soMap.containsKey(ro.Sales_Order__c)) continue;
            ro.CaseId = soMap.get(ro.Sales_Order__c).Case__c;
        }
    }

    public static void createInventoryRecords(List<ReturnOrder> roList) {
        Set<Id> soIds = new Set<Id>();
        for(ReturnOrder ro : roList){
            soIds.add(ro.Sales_Order__c);
        }
        Map<Id,Sales_Order__c> soMap = new Map<Id,Sales_Order__c>([SELECT Id,Work_Order__c,Work_Order__r.OwnerId FROM Sales_Order__c 
                                                                   WHERE Id IN:soIds]);
        Set<Id> ownerIds = new Set<Id>();
        for(Sales_Order__c so : soMap.values()){
            ownerIds.add(so.Work_Order__r.OwnerId);
        }
        List<ServiceResource> srList = [SELECT Id,LocationId,RelatedRecordId FROM ServiceResource 
                                        WHERE RelatedRecordId IN: ownerIds];
        Map<Id,Id> woLocMap = new Map<Id,Id>();
        for(Sales_Order__c so : soMap.values()){
            for(ServiceResource sr : srList){
                if(so.Work_Order__r.OwnerId != sr.RelatedRecordId) continue;
                woLocMap.put(so.Work_Order__c,sr.LocationId);
            }
        }
        List<Schema.Location> locList = [SELECT Id,Name,LocationType,(SELECT Id,Product2Id FROM ProductItems) FROM Location 
                                         WHERE (Name LIKE 'IWCR%' AND LocationType = 'Warehouse') LIMIT 1];
        Id whseLocId;
        if(!locList.isEmpty()){
            whseLocId = locList[0].Id;
        }
        List<ProductRequest> prList = new List<ProductRequest>();
        for(ReturnOrder ro : roList){
            ProductRequest pr = new ProductRequest();
            pr.AccountId = ro.AccountId;
            pr.CaseId = ro.CaseId;
            pr.WorkOrderId = soMap.get(ro.Sales_Order__c).Work_Order__c;
            pr.SourceLocationId = woLocMap.get(soMap.get(ro.Sales_Order__c).Work_Order__c);
            pr.DestinationLocationId = whseLocId;
            pr.OwnerId = soMap.get(ro.Sales_Order__c).Work_Order__r.OwnerId;
            pr.Description = 'Returning Products To Warehouse Location.';
            pr.Status = 'Draft';
            prList.add(pr);
        }
        if(!prList.isEmpty()){
            insert prList;

            for(ProductRequest pr : prList){
                if(pr.Id == null) continue;
                for(ReturnOrder ro : roList){
                    if(pr.WorkOrderId != soMap.get(ro.Sales_Order__c).Work_Order__c) continue;
                    ro.ProductRequestId = pr.Id;
                    ro.SourceLocationId = pr.SourceLocationId;
                    ro.DestinationLocationId = pr.DestinationLocationId;
                    ro.Work_Order__c = soMap.get(ro.Sales_Order__c).Work_Order__c;
                }
            }
        }
    }
}