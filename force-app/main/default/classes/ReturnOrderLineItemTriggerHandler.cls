public class ReturnOrderLineItemTriggerHandler {
    public static void handleBeforeInsert(List<ReturnOrderLineItem> roliList) {
        createInventoryRecords(roliList);
    }

    public static void handleAfterInsert(List<ReturnOrderLineItem> roliList) {
        createProductTransfers(roliList);
    }
    
    public static void createInventoryRecords(List<ReturnOrderLineItem> roliList) {
        Set<Id> prodIds = new Set<Id>();
        Set<Id> vanLocIds = new Set<Id>();
        Set<Id> roIds = new Set<Id>();
        for(ReturnOrderLineItem roli : roliList){
            roIds.add(roli.ReturnOrderId);
            prodIds.add(roli.Product2Id);
            vanLocIds.add(roli.SourceLocationId);
        }
        Map<Id,ReturnOrder> roMap = new Map<Id,ReturnOrder>([SELECT Id,Work_Order__c,CaseId,ProductRequestId,SourceLocationId,Sales_Order__c,
                                                             DestinationLocationId ,OwnerId FROM ReturnOrder WHERE Id IN:roIds]);
        List<ProductRequestLineItem> prliList = new List<ProductRequestLineItem>();
        for(ReturnOrderLineItem roli : roliList){
            ProductRequestLineItem prli = new ProductRequestLineItem();
            prli.ParentId = roMap.get(roli.ReturnOrderId).ProductRequestId;
            prli.Product2Id = roli.Product2Id;
            prli.QuantityRequested = roli.QuantityReturned;
            prli.QuantityUnitOfMeasure = 'Each';
            prli.SourceLocationId = roMap.get(roli.ReturnOrderId).SourceLocationId;
            prli.DestinationLocationId = roMap.get(roli.ReturnOrderId).DestinationLocationId;
            prli.Status = 'draft';
            prli.WorkOrderId = roMap.get(roli.ReturnOrderId).Work_Order__c;
            prli.CaseId = roMap.get(roli.ReturnOrderId).CaseId;
            prliList.add(prli);
        }
        if(!prliList.isEmpty()){
            insert prliList;

            List<ProductItem> piList = [SELECT Id,Product2Id,LocationId FROM ProductItem WHERE Product2Id IN:prodIds AND LocationId IN:vanLocIds];
            for(ReturnOrderLineItem roli : roliList){
                for(ProductRequestLineItem prli : prliList){
                    if(prli.Id == null) continue;
                    if(prli.WorkOrderId != roMap.get(roli.ReturnOrderId).Work_Order__c) continue;
                    roli.ProductRequestLineItemId = prli.Id;
                    roli.SourceLocationId = prli.SourceLocationId;
                    roli.DestinationLocationId = prli.DestinationLocationId;
                    break;
                }
                for(ProductItem pi : piList){
                    if(pi.Product2Id != roli.Product2Id) continue;
                    if(pi.LocationId != roli.SourceLocationId) continue;
                    roli.ProductItemId = pi.Id;
                    break;
                }
            }
        }
    }

    public static void createProductTransfers(List<ReturnOrderLineItem> roliList) {
        Set<Id> roIds = new Set<Id>();
        for(ReturnOrderLineItem roli : roliList){
            roIds.add(roli.ReturnOrderId);
        }
        Map<Id,ReturnOrder> roMap = new Map<Id,ReturnOrder>([SELECT Id,Work_Order__c,CaseId,ProductRequestId,SourceLocationId,Sales_Order__c,
                                                             DestinationLocationId ,OwnerId FROM ReturnOrder WHERE Id IN:roIds]);
        List<ProductTransfer> ptList = new List<ProductTransfer>();
        for(ReturnOrderLineItem roli : roliList){
            ProductTransfer pt = new ProductTransfer();
            pt.ReturnOrderLineItemId = roli.Id;
            pt.Product2Id = roli.Product2Id;
            pt.ProductRequestLineItemId = roli.ProductRequestLineItemId;
            pt.quantitysent = roli.QuantityReturned;
            pt.Case__c = roMap.get(roli.ReturnOrderId).CaseId;
            pt.Work_Order__c = roMap.get(roli.ReturnOrderId).Work_Order__c;
            pt.QuantityUnitOfMeasure = 'Each';
            pt.SourceLocationId = roli.SourceLocationId;
            pt.DestinationLocationId = roli.DestinationLocationId;
            pt.Description = 'Returning Products To Warehouse Location.';
            pt.SourceProductItemId = roli.ProductItemId;
            pt.OwnerId = roMap.get(roli.ReturnOrderId).OwnerId;
            pt.Sales_Order__c = roMap.get(roli.ReturnOrderId).Sales_Order__c;
            ptList.add(pt);
        }
        if(!ptList.isEmpty()){
            insert ptList;
        }
    }
}