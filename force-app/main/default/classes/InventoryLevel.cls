public without sharing class InventoryLevel {
    @AuraEnabled
    public static List<Product2> getInventoryProducts() {
        System.debug('userinfo.getUserId()-> ' + userinfo.getUserId());
        List<Product2> prodList = new List<Product2>();
        List<ServiceResource> srList = [SELECT Id,LocationId,RelatedRecordId FROM ServiceResource WHERE RelatedRecordId=:userinfo.getUserId()];
        List<Schema.Location> locList = [SELECT Id,Name FROM Location WHERE Id =: srList[0].LocationId LIMIT 1];
        if(!locList.isEmpty()){
            prodList = [SELECT Id, Name,Quantity_on_Hand__c,Quantity_Available__c, Quantity_Back_Ordered__c,Quantity__c,NS_Item_Class__c,ProductCode,
                        (
                            SELECT Id,LocationId,Location.Name,Location.LocationType, QuantityOnHand,Minimum_Quantity__c   
                            FROM ProductItems 
                            WHERE LocationId =: locList[0].Id
                        ) 
                        FROM Product2 WHERE Id IN (SELECT Product2Id FROM ProductItem WHERE LocationId =: locList[0].Id) ORDER BY Name
                        ];
        }
        return prodList;
    }

    @AuraEnabled
    public static List<ServiceResource> getActiveServiceResources(){
        return [SELECT Id,Name,RelatedRecordId FROM ServiceResource WHERE IsActive = true AND LocationId != null];
    }    

    @AuraEnabled
    public static String getFieldTechId(){
        String fieldTechId = '';
        Map<Id,User> usrMap = new Map<Id,User>([SELECT Id, Name, Profile.Name FROM User WHERE Id =:userinfo.getUserId() AND IsActive = true AND profile.Name = 'Field Tech']);
        if(!usrMap.isEmpty()){
            List<ServiceResource> srList = [SELECT Id,RelatedRecordId FROM ServiceResource WHERE RelatedRecordId =:userinfo.getUserId() AND IsActive = true];
            if(!srList.isEmpty()) fieldTechId = srList[0].Id;
        }
        return fieldTechId;
    }

    @AuraEnabled
    public static Map<Integer,List<Product2>> getAllProducts(Integer limitNumber, String fieldTechId) {
        List<ServiceResource> srList = [SELECT Id,LocationId,RelatedRecordId FROM ServiceResource WHERE Id =:fieldTechId AND IsActive = true];
        Id vanLocId;
        if(!srList.isEmpty()) vanLocId = srList[0].LocationId;
        Map<Id,Schema.Location> locMap = new Map<Id,Schema.Location>([SELECT Id,Name FROM Location WHERE (Name LIKE 'IWCR%' AND LocationType = 'Warehouse') 
                                                                      OR (Id =: vanLocId) LIMIT 2]);

        List<Product2> prodList = [SELECT Id, Name,Quantity_on_Hand__c,Quantity_Available__c, Quantity_Back_Ordered__c,Quantity__c,ProductCode,
                                   (SELECT Id,LocationId,Location.Name,Location.LocationType,QuantityOnHand,Minimum_Quantity__c FROM ProductItems 
                                   WHERE LocationId =: locMap.keySet()) FROM Product2 
                                   WHERE Id IN (SELECT Product2Id FROM ProductItem WHERE LocationId =: locMap.keySet()) ORDER BY Name LIMIT :limitNumber];
        List<AggregateResult> totalProdCount = [SELECT COUNT(Id) FROM Product2 WHERE Id IN (SELECT Product2Id FROM ProductItem 
                                                WHERE LocationId =: locMap.keySet())];
        for(Product2 p : prodList){
            p.Quantity__c = 0;
            List<ProductItem> piList = p.ProductItems;
            for(ProductItem pi : piList){
                if(pi.Minimum_Quantity__c == null) pi.Minimum_Quantity__c = 0;
                if(pi.QuantityOnHand == null) pi.QuantityOnHand = 0;
            }
        }
        Integer count = 0;
        if(totalProdCount != null && !totalProdCount.isEmpty()) {
            count = (Integer)totalProdCount[0].get('expr0');
        }
        Map<Integer,List<Product2>> prodListCountMap = new Map<Integer,List<Product2>>();
        prodListCountMap.put(count,prodList);
        return prodListCountMap;
    }

    @AuraEnabled
    public static Map<Integer,List<Product2>> getMinQtyProducts(Integer limitNumber, String fieldTechId) {
        List<ServiceResource> srList = [SELECT Id,LocationId,RelatedRecordId FROM ServiceResource WHERE Id =:fieldTechId AND IsActive = true];
        Id vanLocId;
        if(!srList.isEmpty()) vanLocId = srList[0].LocationId;
        List<Product2> prodList = [SELECT Id, Name,Quantity_on_Hand__c,Quantity_Available__c, Quantity_Back_Ordered__c,Quantity__c,ProductCode,
                                   (SELECT Id,LocationId,Location.Name,Location.LocationType,QuantityOnHand,Minimum_Quantity__c FROM ProductItems 
                                   WHERE LocationId =: vanLocId AND Minimum_Quantity__c != null AND Minimum_Quantity__c != 0) FROM Product2 
                                   WHERE Id IN (SELECT Product2Id FROM ProductItem WHERE LocationId =: vanLocId AND Minimum_Quantity__c != null 
                                   AND Minimum_Quantity__c != 0) ORDER BY Name LIMIT :limitNumber];
        List<AggregateResult> totalProdCount = [SELECT COUNT(Id) FROM Product2 WHERE Id IN (SELECT Product2Id FROM ProductItem 
                                                WHERE LocationId =: vanLocId AND Minimum_Quantity__c != null AND Minimum_Quantity__c != 0)];
        for(Product2 p : prodList){
            p.Quantity__c = 0;
            List<ProductItem> piList = p.ProductItems;
            for(ProductItem pi : piList){
                if(pi.QuantityOnHand == null) pi.QuantityOnHand = 0;
            }
        }
        Integer count = 0;
        if(totalProdCount != null && !totalProdCount.isEmpty()) {
            count = (Integer)totalProdCount[0].get('expr0');
        }
        Map<Integer,List<Product2>> prodListCountMap = new Map<Integer,List<Product2>>();
        prodListCountMap.put(count,prodList);
        return prodListCountMap;
    }

    @AuraEnabled
    public static List<Product2> retriveSearhedProducts(String searchKey, String fieldTechId) {
        Map<Id,Product2> prodMap = new Map<Id,Product2>();
        List<ServiceResource> srList = [SELECT Id,LocationId,RelatedRecordId FROM ServiceResource WHERE Id =:fieldTechId AND IsActive = true];
        Id vanLocId;
        if(!srList.isEmpty()) vanLocId = srList[0].LocationId;
        searchKey = searchKey + '%';
        String searchKey2 = '%' + searchKey + '%';
        List<Product2> prodList = [SELECT Id, Name,Quantity_on_Hand__c,Quantity_Available__c,Quantity_Back_Ordered__c,Quantity__c,ProductCode,
                                   (SELECT Id,LocationId,Location.Name,Location.LocationType,QuantityOnHand,Minimum_Quantity__c FROM ProductItems 
                                   WHERE (Location.Name LIKE 'IWCR%' AND Location.LocationType = 'Warehouse') OR (LocationId =: vanLocId)) FROM Product2 
                                   WHERE Id IN (SELECT Product2Id FROM ProductItem WHERE (Location.Name LIKE 'IWCR%'  
                                   AND Location.LocationType = 'Warehouse') OR (LocationId =: vanLocId))  
                                   AND (Name LIKE :searchKey OR Manufacturer_Part_Number__c LIKE :searchKey OR ProductCode LIKE :searchKey)  
                                   AND Family = 'Hardware' ORDER BY Name];
        List<Product2> prodList2 = [SELECT Id, Name,Quantity_on_Hand__c,Quantity_Available__c,Quantity_Back_Ordered__c,Quantity__c,ProductCode,
                                    (SELECT Id,LocationId,Location.Name,Location.LocationType,QuantityOnHand,Minimum_Quantity__c FROM ProductItems 
                                    WHERE (Location.Name LIKE 'IWCR%' AND Location.LocationType = 'Warehouse') OR (LocationId =: vanLocId)) FROM Product2 
                                    WHERE Id IN (SELECT Product2Id FROM ProductItem WHERE (Location.Name LIKE 'IWCR%'  
                                    AND Location.LocationType = 'Warehouse') OR (LocationId =: vanLocId))  
                                    AND (Name LIKE :searchKey2 OR Manufacturer_Part_Number__c LIKE :searchKey2 OR ProductCode LIKE :searchKey2)  
                                    AND Family = 'Hardware' ORDER BY Name];
        prodMap.putAll(prodList);
        prodMap.putAll(prodList2);
        for(Product2 p : prodMap.values()){
            p.Quantity__c = 0;
            List<ProductItem> piList = p.ProductItems;
            for(ProductItem pi : piList){
                if(pi.Minimum_Quantity__c == null) pi.Minimum_Quantity__c = 0;
                if(pi.QuantityOnHand == null) pi.QuantityOnHand = 0;
            }
        }
        return prodMap.values();
    }
    
    @AuraEnabled
    public static Boolean creatingReplenishmentWO(List<Product2> prodList, String fieldTechId) {
        Boolean allGood = false;
        List<ServiceResource> srList = [SELECT Id,LocationId,RelatedRecordId,RelatedRecord.FirstName, RelatedRecord.Name FROM ServiceResource WHERE Id =:fieldTechId AND IsActive = true];
        Id vanLocId;
        List<Account> accList = new List<Account>();
        if(!srList.isEmpty()){
            vanLocId = srList[0].LocationId;
            String accName = srList[0].RelatedRecord.FirstName + '%Vanstock';
            accList = [SELECT Id, Name, ShippingStreet, ShippingCity, ShippingState, ShippingCountry, ShippingPostalCode FROM Account WHERE Name LIKE :accName];
        }
        List<Schema.Location> locList = [SELECT Id,Name,LocationType,(SELECT Id,LocationId,Location.Name,
                                         Location.LocationType,Product2Id,Product2.Name,QuantityOnHand 
                                         FROM ProductItems) FROM Location WHERE (Name LIKE 'IWCR%' AND LocationType = 'Warehouse') LIMIT 1];
        Id whseLocId = (!locList.isEmpty()) ? locList[0].Id : null;
        Id partShipId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get( 'Part_Shipment' ).getRecordTypeId();
        Map<Id,Pricebook2> pbMap = new Map<Id,Pricebook2>([SELECT Id, Country__c FROM Pricebook2 WHERE IsActive = true AND Country__c = 'United States' LIMIT 1]);
        Id pbId = (!pbMap.isEmpty()) ? pbMap.values()[0].Id : null;
        Map<Id,Product2> prodMap = new Map<Id,Product2>(prodList);
        List<PricebookEntry> pbeList = [SELECT Id,UnitPrice,Pricebook2Id,Product2Id FROM PricebookEntry WHERE Product2Id IN : prodMap.keySet() 
                                        AND Pricebook2Id IN : pbMap.keySet() AND isActive = true];
        if(Test.isRunningTest()){
            pbId = Test.getStandardPricebookId();
            pbeList = [SELECT Id,UnitPrice,Pricebook2Id,Product2Id FROM PricebookEntry];
        }
        WorkOrder wo = new WorkOrder();
        if(!srList.isEmpty()) {
            wo.OwnerId = srList[0].RelatedRecordId;
            wo.Service_Resource__c = srList[0].Id;
            wo.Description = 'MUST SHIP WITH P/N & S/N LABEL' + '\n' + 'MUST HAVE -HOLD FOR TECH- LABEL';
        }
        wo.Pricebook2Id = pbId;
        wo.RecordTypeId = partShipId;
        wo.Service_Type__c = 'Van Stock';
        if(!accList.isEmpty()){
            wo.AccountId = accList[0].Id;
            wo.Street = accList[0].ShippingStreet;
            wo.City = accList[0].ShippingCity;
            wo.State = accList[0].ShippingState;
            wo.Country = accList[0].ShippingCountry;
            wo.PostalCode = accList[0].ShippingPostalCode;
        }
        wo.OrderedPartWO__c = true;
        insert wo;

        if(wo.Id != null) {
            List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>(); 
            for(PricebookEntry pbe : pbeList){
                for(Product2 prod : prodList){
                    if(pbe.Product2Id != prod.Id) continue;
                    WorkOrderLineItem woli = new WorkOrderLineItem();
                    woli.WorkOrderId = wo.Id;
                    woli.PricebookEntryId = pbe.Id;
                    woli.UnitPrice = pbe.UnitPrice;
                    woli.Quantity = prod.Quantity__c;
                    woliList.add(woli);
                }
            }
            if(!woliList.isEmpty() && whseLocId != null && vanLocId != null){
                insert woliList;
                ProductRequest pr = new ProductRequest();
                pr.Description = 'MUST SHIP WITH P/N & S/N LABEL' + '\n' + 'MUST HAVE -HOLD FOR TECH- LABEL';
                pr.Status = 'Draft';
                pr.WorkOrderId = wo.Id;
                pr.SourceLocationId = whseLocId;
                pr.DestinationLocationId = vanLocId;
                insert pr;

                List<ProductRequestLineItem> prliList = new List<ProductRequestLineItem>();
                List<ProductTransfer> ptList = new List<ProductTransfer>();
                for(Product2 prod : prodList){
                    ProductRequestLineItem prl = new ProductRequestLineItem();
                    prl.ParentId = pr.Id;
                    prl.Product2Id = prod.Id;
                    prl.WorkOrderId = wo.Id;
                    prl.QuantityRequested = prod.Quantity__c;
                    prl.QuantityUnitOfMeasure = 'Each';
                    prl.SourceLocationId = whseLocId;
                    prl.DestinationLocationId = vanLocId;
                    prliList.add(prl);
                }
                if(!prliList.isEmpty()){
                    insert prliList;

                    for(ProductRequestLineItem prli : prliList){
                        ProductTransfer pt = new ProductTransfer();
                        pt.Work_Order__c = wo.Id;
                        pt.Product2Id = prli.Product2Id;
                        pt.ProductRequestLineItemId = prli.Id;
                        pt.quantitysent = prli.QuantityRequested;
                        pt.QuantityUnitOfMeasure = 'Each';
                        pt.SourceLocationId = whseLocId;
                        pt.DestinationLocationId = vanLocId;
                        pt.OwnerId = wo.OwnerId;
                        pt.Description = 'MUST SHIP WITH P/N & S/N LABEL' + '\n' + 'MUST HAVE -HOLD FOR TECH- LABEL';
                        for(ProductItem pi : locList[0].ProductItems) {
                            if(pi.Product2Id == prli.Product2Id) {
                                pt.SourceProductItemId = pi.Id;
                                break;
                            }
                        }
                        ptList.add(pt);
                    }
                    if(!ptList.isEmpty()){
                        insert ptList;
                        allGood = true;
                    }
                }
            }
        }
        return allGood;
    }
}