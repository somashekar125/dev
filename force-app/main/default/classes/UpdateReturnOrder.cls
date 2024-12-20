public without sharing class UpdateReturnOrder {
    @AuraEnabled
    public static Boolean checkWOOwnerId(String woId) {
        Boolean isFieldTech = false;
        List<WorkOrder> woList = [SELECT Id,OwnerId FROM WorkOrder WHERE Id =: woId];
        if(!woList.isEmpty()){
            if(String.valueOf(woList[0].OwnerId).startsWith('005')){
                isFieldTech = true;
            }
        }
        return isFieldTech;
    }

    @AuraEnabled
    public static List<ReturnOrder> getReturnOrder(String woId) {
        List<Sales_Order__c> soList = [SELECT Id,(SELECT Id,ReturnOrderNumber,Status,Return_Authorization__c,Return_Order_Tracking_Numbers__c,Sales_Order__c,Sales_Order__r.Name 
                                       FROM Return_Orders__r WHERE Status != 'Shipped' AND Work_Order__c =: woId ORDER BY Createddate DESC LIMIT 1) 
                                       FROM Sales_Order__c WHERE Work_Order__c=:woId LIMIT 1];
        List<ReturnOrder> roList = new List<ReturnOrder>();
        if(!soList.isEmpty()){
            roList = soList[0].Return_Orders__r;
        }
        return roList;
    }

    @AuraEnabled
    public static List<ReturnOrderLineItem> getReturnOrderLineItems(ReturnOrder roRec){
        List<ReturnOrderLineItem> roliList = new List<ReturnOrderLineItem>();
        roliList = [SELECT Id,Product2Id,Product2.Name,QuantityReturned,ProductItemId,ReturnOrderId FROM ReturnOrderLineItem 
                    WHERE ReturnOrderId =: roRec.Id ORDER BY ReturnOrderLineItemNumber];
        return  roliList;
    }

    @AuraEnabled
    public static Boolean shipReturnOrder(ReturnOrder roRec){
        Boolean isShipped = false;
        ReturnOrder ro = new ReturnOrder(Id = roRec.Id, Status = 'Shipped');
        update ro;
        isShipped = true;
        
        return isShipped;
    }
}