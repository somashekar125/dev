public class SalesOrderTriggerHandler {

    public static void handleBeforeInsert(List<Sales_Order__c> soList) {
        setCaseId(soList);
        correctTrackingNumb(soList);
    }

    public static void handleBeforeUpdate(Map<Id,Sales_Order__c> newMap, Map<Id,Sales_Order__c> oldMap) {
        correctTrackingNumb(newMap.values());
        setCaseId(newMap.values());
    }

    public static void handleAfterUpdate(Map<Id,Sales_Order__c> newMap, Map<Id,Sales_Order__c> oldMap) {
        setCaseIdInReturnOrders(newMap);
    }

    public static void correctTrackingNumb(List<Sales_Order__c> soList) {
        for(Sales_Order__c so : soList){
            if(so.Outbound_Tracking_Numbers__c != null && so.Outbound_Tracking_Numbers__c != ' ' && so.Outbound_Tracking_Numbers__c.contains(' ')){
                so.Outbound_Tracking_Numbers__c = so.Outbound_Tracking_Numbers__c.replaceAll(' ',',');
            }
        }
    }

    public static void setCaseId(List<Sales_Order__c> soList) {
        Set<Id> woIds = new Set<Id>();
        for(Sales_Order__c so :  soList) {
            woIds.add(so.Work_Order__c);
        }
        Map<Id,WorkOrder> woMap = new Map<Id,WorkOrder>([SELECT CaseId FROM WorkOrder WHERE CaseId != NULL AND Id IN :woIds]);
        for(Sales_Order__c so :  soList) {
            if(!woMap.containsKey(so.Work_Order__c)) continue;
            so.Case__c = woMap.get(so.Work_Order__c).CaseId;
        }
    }

    public static void setCaseIdInReturnOrders(Map<Id, Sales_Order__c> newMap) {
        List<ReturnOrder> roList = [SELECT Id,CaseId,Sales_Order__r.Case__c FROM ReturnOrder 
                                    WHERE CaseId = NULL AND Sales_Order__r.Case__c != NULL AND Sales_Order__c IN :newMap.keySet()];
        List<ReturnOrder> roUpdateList = new List<ReturnOrder>();
        for(ReturnOrder ro : roList){
            ro.CaseId = ro.Sales_Order__r.Case__c;
            roUpdateList.add(ro);
        }
        if(!roUpdateList.isEmpty()){
            update roUpdateList;
        }
    }

    /*
    public static void handleAfterInsert(map<id, Sales_Order__c> newMap){
        String jsonNewMap = JSON.serialize(Trigger.newMap);
        updateWOStatus(jsonNewMap, null);
    }
    
    public static void handleAfterUpdate(map<id, Sales_Order__c> newMap, map<id, Sales_Order__c> oldMap){
        String jsonNewMap = JSON.serialize(Trigger.newMap);
        String jsonOldMap = JSON.serialize(Trigger.oldMap);
        updateWOStatus(jsonNewMap, jsonOldMap);
    }

    @future
    public static void updateWOStatus(String strnewMap,String stroldMap){
        map<id, Sales_Order__c> oldMap = null;
        if(String.isNotBlank(stroldMap)) {
            oldMap = (Map<id, Sales_Order__c>) JSON.deserialize(stroldMap, map<id, Sales_Order__c>.class);
        }
        map<id, Sales_Order__c> newMap = (Map<id, Sales_Order__c>) JSON.deserialize(strnewMap, map<id, Sales_Order__c>.class);
        Set<Id> woIds = new Set<Id>();
        for(Sales_Order__c so : newMap.values()){
            woIds.add(so.Work_Order__c);
        }
        Map<Id, WorkOrder> woMap = new Map<Id,WorkOrder>([SELECT Status,CaseId,Tracking_Numbers__c, Return_Authorization__c,
                                                            Return_Order_Tracking_Numbers__c, Netsuite_Sales_Order__c,
                                                            Ship_Date__c
                                                            FROM WorkOrder WHERE id in :woIds]);
        
        list<WorkOrder> woList = new list<WorkOrder>();
        list<Case> caseList = new list<Case>();
        
        for(Sales_Order__c so : newMap.values()){
            
            System.debug('so.Outbound_Tracking_Numbers__c--> ' + so.Outbound_Tracking_Numbers__c);
            if(so.Work_Order__c == null) continue;

            WorkOrder wo = woMap.get(so.Work_Order__c);
            Case c = new Case(Id=wo.CaseId);
            
            System.debug('oldwo.Id--> ' + wo.Id + ' oldwo.status--> ' + wo.Status);

            boolean addWoToWoList = false;
            boolean addCaseToCaseList = false;

            if(wo.Netsuite_Sales_Order__c == null) {
                wo.Netsuite_Sales_Order__c = so.Id;
                addWoToWoList = true;
            }

            if(so.Tracking_Numbers__c != wo.Tracking_Numbers__c) {
                wo.Tracking_Numbers__c = so.Tracking_Numbers__c;
                addWoToWoList = true;

                c.Tracking_Numbers__c = so.Tracking_Numbers__c;
                addCaseToCaseList = true;
            }

            if(so.Ship_Date__c != wo.Ship_Date__c) {
                wo.Ship_Date__c = so.Ship_Date__c;
                addWoToWoList = true;
                
                c.Ship_Date__c = so.Ship_Date__c;
                addCaseToCaseList = true;
            }

            if(so.Return_Authorization__c  != wo.Return_Authorization__c) {
                wo.Return_Authorization__c = so.Return_Authorization__c;
                c.Return_Authorization__c = so.Return_Authorization__c;
                addWoToWoList = true;
                addCaseToCaseList = true;
            }

            if(so.Return_Order_Tracking_Numbers__c  != wo.Return_Order_Tracking_Numbers__c) {
                wo.Return_Order_Tracking_Numbers__c = so.Return_Order_Tracking_Numbers__c;
                c.Return_Tracking_Numbers__c = so.Return_Order_Tracking_Numbers__c;
                addWoToWoList = true;
                addCaseToCaseList = true;
            }
            
            if((so.Order_Status__c == 'Billed' || so.Order_Status__c == 'Pending Billing') && wo.Status != 'Part Shipped'){
                wo.Status = 'Part Shipped';
                System.debug('wo.Id1--> ' + wo.Id + 'wo.status1--> ' + wo.Status);
                addWoToWoList = true;
            } else if(so.Order_Status__c == 'Pending Billing/Partially Fulfilled' && so.Outbound_Tracking_Numbers__c == null && wo.Status != 'Pending Fulfillment'){
                wo.Status = 'Pending Fulfillment';
                System.debug('wo.Id2--> ' + wo.Id + 'wo.status2--> ' + wo.Status);
                addWoToWoList = true;
            } else if(so.Order_Status__c == 'Pending Billing/Partially Fulfilled' && so.Outbound_Tracking_Numbers__c != null && wo.Status != 'Part Shipped'){
                wo.Status = 'Part Shipped';
                System.debug('wo.Id3--> ' + wo.Id + 'wo.status3--> ' + wo.Status);
                addWoToWoList = true;
            } else if(so.Order_Status__c == 'Partially Fulfilled' && so.Outbound_Tracking_Numbers__c == null && wo.Status != 'Partially Fulfilled'){
                wo.Status = 'Partially Fulfilled';
                System.debug('wo.Id4--> ' + wo.Id + 'wo.status4--> ' + wo.Status);
                addWoToWoList = true;
            } else if(so.Order_Status__c == 'Partially Fulfilled' && so.Outbound_Tracking_Numbers__c != null && wo.Status != 'Part Shipped'){
                wo.Status = 'Part Shipped';
                System.debug('wo.Id5--> ' + wo.Id + 'wo.status5--> ' + wo.Status);
                addWoToWoList = true;
            } else if(so.Order_Status__c == 'Pending Fulfillment'){
                if(so.SO_Order_Status__c == 'Hold'){
                    wo.Status = 'Cannot Complete';
                } else{
                    wo.Status = 'Pending Fulfillment';
                }
                System.debug('wo.Id6--> ' + wo.Id + 'wo.status6--> ' + wo.Status);
                addWoToWoList = true;
            } else if(so.Order_Status__c == 'Pending Approval'){
                if(so.SO_Order_Status__c == 'Hold'){
                    wo.Status = 'Cannot Complete';
                } else{
                    wo.Status = 'Part Ordered';
                }
                System.debug('wo.Id7--> ' + wo.Id + 'wo.status7--> ' + wo.Status);
                addWoToWoList = true;
            }
            if(addWoToWoList) {
                boolean add = true;
                for(WorkOrder wo1 : woList) {
                    if(wo.Id == wo1.Id) {
                        add = false;
                        break;
                    }
                }
                if(add) {
                    woList.add(wo);
                }
            }
            if(addCaseToCaseList) {
                boolean add = true;
                for(Case c1 : caseList) {
                    if(c1.Id == c.Id) {
                        add = false;
                        break;
                    }
                }
                if(add) {
                    caseList.add(c);
                }
            }
        }
        update woList;
        update caseList;
    }*/
}