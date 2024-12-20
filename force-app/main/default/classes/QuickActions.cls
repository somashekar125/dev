public without sharing class QuickActions {
    @AuraEnabled
    public static WorkOrder getwoRec(Id woId){
        WorkOrder wo = [SELECT Id,Technician_Status__c,Onsite_Manager_Name__c,Resolution_Code__c,Help_Desk_Contact__c,
                Resolution_Notes__c,Return_Order_Tracking_Numbers__c,Reason_for_Revisit__c FROM WorkOrder WHERE Id =: woId];
        if(wo.Technician_Status__c == null){
            wo.Technician_Status__c = '';
        }
        if(wo.Onsite_Manager_Name__c == null){
            wo.Onsite_Manager_Name__c = '';
        }
        if(wo.Resolution_Code__c == null){
            wo.Resolution_Code__c = '';
        }
        if(wo.Help_Desk_Contact__c == null){
            wo.Help_Desk_Contact__c = '';
        }
        if(wo.Resolution_Notes__c == null){
            wo.Resolution_Notes__c = '';
        }
        if(wo.Return_Order_Tracking_Numbers__c == null){
            wo.Return_Order_Tracking_Numbers__c = '';
        }
        if(wo.Reason_for_Revisit__c == null){
            wo.Reason_for_Revisit__c = '';
        }
        return wo;
    }
    
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
    public static void updateWorkStep(String wsId) {
        WorkStep ws = new WorkStep(Id = wsId, Status = 'In Progress', StartTime = System.now());
        update ws;
    }
}