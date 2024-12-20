public without sharing class ClosingProcess {
    @AuraEnabled
    public static Boolean checkForLiftWOLI(String woId) {
        Boolean existWOLI = false;
        List<Product_Mapping__mdt> costProductList = Product_Mapping__mdt.getAll().values();
        System.debug('costProductList: ' + costProductList);
        set<String> ProdName = new set<String>();
        for(Product_Mapping__mdt pm : costProductList){
            if(pm.Field_API_Name__c != 'Equipment_Rental_Cost__c') continue;
            if(pm.Charge_Product_Name__c != null) ProdName.add(pm.Charge_Product_Name__c);
            if(pm.Cost_Product_Name__c != null) ProdName.add(pm.Cost_Product_Name__c);
        }
        list<WorkOrderLineItem> existingLineItem = new list<WorkOrderLineItem>();
        if(!ProdName.isEmpty()){
            existingLineItem = [SELECT Id FROM WorkOrderLineItem WHERE WorkOrderId =:woId AND PricebookEntry.Product2.Name IN :ProdName 
                                AND Created_For_Field__c = 'Equipment_Rental_Cost__c' AND Status = 'Lift Ordered'];
        }
        if(!existingLineItem.isEmpty()){
            existWOLI = true;
        }
        return existWOLI;
    }

	@AuraEnabled
    public static WorkOrder getwoRec(Id woId){
        return [SELECT Id, CaseId, Record_Type_Name__c, Status, Resolution_Code__c, Resolution_Notes__c, Missed_SLA_Reason__c, SLA_Exception_Code__c, 
                Onsite_Manager_Name__c, Help_Desk_Contact__c, No_Cost__c, Closing_Process__c FROM WorkOrder WHERE Id =: woId];
    }

    @AuraEnabled
    public static Case getCaseRec(Id caseId){
        return [SELECT Id, SLA_Violated__c, Part_Shipment_SLA_Violated__c, Closing_Process__c FROM Case WHERE Id =: caseId];
    }

    @AuraEnabled
    public static Boolean checkForProductTransfers(Id woId){
        Boolean productTransferExists = false;
        List<ProductTransfer> ptList = [SELECT Id FROM ProductTransfer WHERE IsReceived = false AND Work_Order__c =: woId];
        if(!ptList.isEmpty()){
            productTransferExists = true;
        }
        return productTransferExists;
    }

    @AuraEnabled
    public static Boolean checkForProductTransfers2(Id caseId){
        Boolean productTransferExists = false;
        List<ProductTransfer> ptList = [SELECT Id FROM ProductTransfer WHERE IsReceived = false AND Case__c =: caseId];
        if(!ptList.isEmpty()){
            productTransferExists = true;
        }
        return productTransferExists;
    }
}