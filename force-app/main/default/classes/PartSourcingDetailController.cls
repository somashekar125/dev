public with sharing class PartSourcingDetailController {
    
    @AuraEnabled(cacheable=true)
    public static List<WorkOrderLineItem> getPartSourcingDetails(String saId) {
        List<ServiceAppointment> saList = [Select ParentRecordId from ServiceAppointment WHERE Id = :saId];
        if(saList.isEmpty()) {
            return null;
        }
        List<WorkOrder> woList = [SELECT CaseId FROM WorkOrder WHERE Id = :saList[0].ParentRecordId];
        if(woList.isEmpty()) {
            return null;
        }
        List<Case> cList = [SELECT Id, 
                                (
                                    SELECT Id FROM WorkOrders WHERE RecordType.Name = 'Part Shipment'
                                )
                            FROM Case
                            WHERE Id = :woList[0].CaseId];
        if(cList.isEmpty() || cList[0].WorkOrders.isEmpty()) {
            return null;
        }
        List<WorkOrderLineItem> woliList = [SELECT Id, PricebookEntry.Product2.Name,
                                                (
                                                    SELECT SourceLocation.Name,
                                                    SourceLocation.LocationType,
                                                    QuantityRequested
                                                    FROM ProductRequestLineItems
                                                )
                                            FROM WorkOrderLineItem
                                            WHERE WorkOrderId = :cList[0].WorkOrders[0].Id];
        return woliList;
    }
}