public without sharing class ProductsConsumed {

    @AuraEnabled
    public static Boolean checkWOOwnerId(String workorderId) {
        Boolean isCubFieldTech = false;
        List<WorkOrder> woList = [SELECT Id,OwnerId FROM WorkOrder WHERE Id =: workorderId];
        if(!woList.isEmpty()){
            if(String.valueOf(woList[0].OwnerId).startsWith('005')){
                isCubFieldTech = true;
            }
        }
        return isCubFieldTech;
    }

    @AuraEnabled
    public static WorkOrder retrieveWorkOrder(String workOrderId) {
        List<WorkOrder> woList = [SELECT Id,WorkOrderNumber,CaseId,OwnerId,Root_Account__c,Root_Account__r.H_W_Root_Account__c,AccountId,Account_Name__c,
                                  Owner.Name,Pricebook2Id,Equipment_Type__c,Problem_Type__c,Department2__c,Incident__c,Street,City,State,
                                  Country,PostalCode,NetsuiteId__c,Ready_For_Invoice__c FROM WorkOrder WHERE Id =: workOrderId];
        return woList[0];
    }

    @AuraEnabled
    public static List<WorkOrder> getOpenOnsiteWOs() {
        System.debug('userinfo.getUserId()-> ' + userinfo.getUserId());
        List<WorkOrder> woList = [SELECT Id,WorkOrderNumber,Account_Name__c,SLA_Due_Date_TimeStr__c,Ready_For_Invoice__c,CaseId FROM WorkOrder 
                                  WHERE (Status != 'Closed' OR Status != 'Cancelled') AND OwnerId =: userinfo.getUserId() AND 
                                  Record_Type_Name__c = 'Onsite Labor' ORDER BY WorkOrderNumber];
        return woList;
    }

	@AuraEnabled
    public static List<WorkOrderlineItem> getWOLIs(WorkOrder woRec) {
        List<WorkOrderlineItem> woliList = new List<WorkOrderlineItem>();
        if(woRec != null){
            woliList = [SELECT Id,PricebookEntry.Product2Id,PricebookEntry.Product2.Name,PricebookEntry.Product2.Family,
                        PricebookEntry.Product2.ProductCode,Quantity,WorkOrderId,WorkOrder.OrderedPartWO__c,WorkOrder.CaseId FROM WorkOrderLineItem 
                        WHERE WorkOrder.CaseId =:woRec.CaseId AND WorkOrder.OrderedPartWO__c = true 
                        AND PricebookEntry.Product2.Family = 'Hardware' ORDER BY PricebookEntry.Product2.Name];
        }
        return woliList;
    }

    @AuraEnabled
    public static List<ProductItem> getVanStock(WorkOrder woRec) {
        List<ProductItem> prodItemList = new List<ProductItem>();
        List<ServiceResource> srList = [SELECT Id,LocationId,RelatedRecordId FROM ServiceResource WHERE RelatedRecordId=:woRec.OwnerId];
        if(!srList.isEmpty()){
            prodItemList = [SELECT Id,Product2Id,Product2.Name,Product_Code__c,LocationId,Location.Name,Location.LocationType, QuantityOnHand 
                            FROM ProductItem WHERE LocationId =:srList[0].LocationId ORDER BY Product2.Name];
        }
        return prodItemList;
    }

    @AuraEnabled
    public static List<WorkOrder> retriveSearhedWOs(String searchKey) {
        List<WorkOrder> woList = new List<WorkOrder>();
        if(String.isNotBlank(searchKey)){
            searchKey =  '%' + searchKey + '%';
            woList = [SELECT Id,WorkOrderNumber,Account_Name__c,SLA_Due_Date_TimeStr__c,Ready_For_Invoice__c,CaseId FROM WorkOrder 
                      WHERE WorkOrderNumber LIKE:searchKey 
                      AND (Status != 'Closed' OR Status != 'Cancelled') AND OwnerId =: userinfo.getUserId() 
                      AND Record_Type_Name__c = 'Onsite Labor' ORDER BY WorkOrderNumber];
        }
        System.debug('woList size-> ' + woList.size());
        return woList;
    }

    @AuraEnabled
    public static List<ProductItem> retriveSearhedProducts(String searchKey, WorkOrder woRec) {
        System.debug('woRec-> ' + JSON.serialize(woRec));
        System.debug('searchKey-> ' + searchKey);
        Map<Id,ProductItem> prodItemMap = new Map<Id,ProductItem>();
        System.debug('woRec.Root_Account__r.H_W_Root_Account__c-> ' + woRec.Root_Account__r.H_W_Root_Account__c);
        List<ServiceResource> srList = [SELECT Id,LocationId,RelatedRecordId FROM ServiceResource 
                                        WHERE RelatedRecordId=:woRec.OwnerId];
        if(test.isRunningTest()){
            srList = [SELECT Id,LocationId,RelatedRecordId FROM ServiceResource WHERE RelatedRecordId=:UserInfo.getUserId()];
        }
        if(srList.isEmpty()){
            return prodItemMap.values();
        }
        searchKey = searchKey + '%';
        String searchKey2 = '%' + searchKey + '%';
        List<ProductItem> prodItemnList = [SELECT Id,Product2Id,Product2.Name,Product_Code__c,LocationId,Location.Name,Location.LocationType,QuantityOnHand 
                                           FROM ProductItem WHERE LocationId =: srList[0].LocationId AND 
                                           (Product2.Account_Item_Belongs_To__c =: woRec.Root_Account__r.H_W_Root_Account__c OR 
                                           Product2.Account_Item_Belongs_To__c =: woRec.Root_Account__c) AND 
                                           (Product2.Name LIKE :searchKey OR Product2.Manufacturer_Part_Number__c LIKE :searchKey OR Product_Code__c LIKE :searchKey) 
                                           ORDER BY Product2.Name];
        List<ProductItem> prodItemnList2 = [SELECT Id,Product2Id,Product2.Name,Product_Code__c,LocationId,Location.Name,Location.LocationType,QuantityOnHand 
                                           FROM ProductItem WHERE LocationId =: srList[0].LocationId AND 
                                           (Product2.Account_Item_Belongs_To__c =: woRec.Root_Account__r.H_W_Root_Account__c OR 
                                           Product2.Account_Item_Belongs_To__c =: woRec.Root_Account__c) AND 
                                           (Product2.Name LIKE :searchKey2 OR Product2.Manufacturer_Part_Number__c LIKE :searchKey2 OR Product_Code__c LIKE :searchKey2) 
                                           ORDER BY Product2.Name];
        prodItemMap.putAll(prodItemnList);
        prodItemMap.putAll(prodItemnList2);

        return prodItemMap.values();
    }

    @AuraEnabled
    public static void consumeProducts(WorkOrder woRec, List<WorkOrderLineItem> woliConsumePartsList, List<ProductItem> vanPartsToConsumeList) {
        System.debug('woliConsumePartsList-> ' + JSON.serialize(woliConsumePartsList));
        System.debug('vanPartsToConsumeList-> ' + JSON.serialize(vanPartsToConsumeList));
        List<ServiceResource> srList = [SELECT Id,Name,LocationId,Location.Name,RelatedRecordId FROM ServiceResource WHERE RelatedRecordId=:woRec.OwnerId];
        if(test.isRunningTest()){
            srList = [SELECT Id,Name,LocationId,Location.Name,RelatedRecordId FROM ServiceResource WHERE RelatedRecordId=:UserInfo.getUserId()];
        }
        if(!srList.isEmpty() && (!woliConsumePartsList.isEmpty() || !vanPartsToConsumeList.isEmpty())){
            Set<Id> prodIds = new Set<Id>();
            for(WorkOrderLineItem w : woliConsumePartsList){
                prodIds.add(w.PricebookEntry.Product2Id);
            }
            for(ProductItem pi : vanPartsToConsumeList){
                prodIds.add(pi.Product2Id);
            }
            Map<Id,Id> productProdItemMap = new Map<Id,Id>();
            if(!prodIds.isEmpty()){
                List<ProductItem> piList = [SELECT Id,Product2Id,LocationId FROM ProductItem 
                                            WHERE LocationId =: srList[0].LocationId AND Product2Id IN:prodIds];
                System.debug('piList-> ' + JSON.serialize(piList));
                for(ProductItem pi : piList){
                    productProdItemMap.put(pi.Product2Id,pi.Id);
                }
            }
            List<Schema.ProductConsumed> pcList = new List<Schema.ProductConsumed>();
            for(WorkOrderLineItem woli : woliConsumePartsList){
                Schema.ProductConsumed pc = new Schema.ProductConsumed();
                pc.WorkOrderId = woRec.Id;
                if(productProdItemMap.containskey(woli.PricebookEntry.Product2Id)){
                    pc.ProductItemId = productProdItemMap.get(woli.PricebookEntry.Product2Id);
                }
                pc.PricebookEntryId = woli.PricebookEntryId;
                pc.QuantityConsumed = woli.Quantity;
                pc.UnitPrice = woli.UnitPrice;
                pcList.add(pc);
            }
            List<PricebookEntry> pbeList = [SELECT Id,Product2Id,UnitPrice FROM PricebookEntry 
                                                WHERE Product2Id IN: prodIds AND Pricebook2Id =: woRec.Pricebook2Id];
            for(ProductItem pi : vanPartsToConsumeList){
                for(PricebookEntry pbe : pbeList){
                    if(pbe.Product2Id != pi.Product2Id) continue;
                    Schema.ProductConsumed pc = new Schema.ProductConsumed();
                    pc.WorkOrderId = woRec.Id;
                    pc.ProductItemId = pi.Id;
                    pc.PricebookEntryId = pbe.Id;
                    pc.QuantityConsumed = pi.QuantityOnHand;
                    pc.UnitPrice = pbe.UnitPrice;
                    pcList.add(pc);
                }
            }
            if(!pcList.isEmpty()){
                insert pcList;
                List<ServiceContract> scList = [SELECT Id,AccountId FROM ServiceContract WHERE AccountId =: woRec.Root_Account__c 
                                                AND Status = 'Active'AND Service_Type__c = 'Product Consumption' 
                                                AND Work_Order_Record_Type__c = 'Part Shipment' AND Name LIKE '%Consumption%' LIMIT 1];
                Id partRTId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Part_Shipment').getRecordTypeId();
                
                WorkOrder wo = new WorkOrder();
                String msg = 'CONSUMPTION ORDER -- DO NOT SHIP' + '\n' + 'TECH NAME: ' + woRec.Owner.Name + '\n' + 'VAN: ' + srList[0].Location.Name;
                wo.Description = msg;
                wo.Status = 'Closed';
                wo.Resolution_Code__c = 'RESOLVED';
                wo.Closing_Process__c = true;
                wo.CaseId = woRec.CaseId;
                wo.AccountId = woRec.AccountId;
                wo.Root_Account__c = woRec.Root_Account__c;
                wo.OwnerId = woRec.OwnerId;
                wo.Pricebook2Id = woRec.Pricebook2Id;
                wo.RecordTypeId = partRTId;
                if(!scList.isEmpty()){
                    wo.ServiceContractId = scList[0].Id;
                }
                wo.Equipment_Type__c = woRec.Equipment_Type__c;
                wo.Problem_Type__c = woRec.Problem_Type__c;
                wo.Department2__c = woRec.Department2__c;
                wo.Service_Type__c = 'Product Consumption';
                wo.Incident__c = woRec.Incident__c;
                wo.Street = woRec.Street;
                wo.City = woRec.City;
                wo.State = woRec.State;
                wo.Country = woRec.Country;
                wo.PostalCode = woRec.PostalCode;
                wo.ConsumptionPartWO__c = true;
                insert wo;

                List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
                if(wo.Id != null){
                    for(Schema.ProductConsumed pc : pcList){
                        for(PricebookEntry pbe : pbeList){
                            if(pbe.Id != pc.PricebookEntryId) continue;
                            WorkOrderLineItem woli = new WorkOrderLineItem();
                            woli.PricebookEntryId = pbe.Id;
                            woli.UnitPrice = pbe.UnitPrice;
                            woli.Quantity = pc.QuantityConsumed;
                            woli.WorkOrderId = wo.Id;
                            woliList.add(woli);
                        }
                    }
                }
                if(!woliList.isEmpty()){
                    insert woliList;
                }
            }
        }
    }
}