public without sharing class ReturnParts {
    @AuraEnabled
    public static List<ProductItem> getVanStock(){
        List<ProductItem> prodItemList = new List<ProductItem>();
        List<ServiceResource> srList = [SELECT Id,LocationId,RelatedRecordId FROM ServiceResource WHERE RelatedRecordId=:UserInfo.getUserId()];
        if(!srList.isEmpty()){
            prodItemList = [SELECT Id,Product2Id,Product2.Name,Product_Code__c,LocationId,Location.Name,Location.LocationType, QuantityOnHand 
                            FROM ProductItem WHERE LocationId =:srList[0].LocationId ORDER BY Product2.Name];
        }
        return prodItemList;
    }

    @AuraEnabled
    public static List<Product2> retriveAllProducts(Integer limitNumber) {
        List<Product2> prodList = new List<Product2>();
        List<ServiceResource> srList = [SELECT Id,LocationId,RelatedRecordId FROM ServiceResource WHERE RelatedRecordId=:UserInfo.getUserId()];
        Id vanLocId;
        if(!srList.isEmpty()){
            vanLocId = srList[0].LocationId;
        }
        Map<Id,Schema.Location> locMap = new Map<Id,Schema.Location>([SELECT Id,Name FROM Location 
                                                                      WHERE (Name LIKE 'IWCR%' AND LocationType = 'Warehouse') OR 
                                                                      (Id =: vanLocId) OR (LocationType = 'Site' AND 
                                                                      OwnerId =: UserInfo.getUserId()) LIMIT 3]);
        prodList = [SELECT Id, Name,Quantity_Available__c,Quantity__c,ProductCode,
                    (SELECT Id,LocationId,Location.Name,Location.LocationType, QuantityOnHand 
                    FROM ProductItems WHERE LocationId IN:locMap.keySet() LIMIT 3)
                    FROM Product2 WHERE Id IN (SELECT Product2Id FROM ProductItem WHERE LocationId IN:locMap.keySet()) ORDER BY Name LIMIT :limitNumber 
                    ];
        for(Product2 p : prodList){
            p.Quantity__c = 0;
        }
        return prodList;
    }

    @AuraEnabled
    public static List<Product2> retriveSearhedProducts(String searchKey) {
        System.debug('searchKey-> ' + searchKey);
        Map<Id,Product2> prodMap = new Map<Id,Product2>();
        List<ServiceResource> srList = [SELECT Id,LocationId,RelatedRecordId FROM ServiceResource 
                                        WHERE RelatedRecordId=:UserInfo.getUserId()];
        Id vanLocId;
        if(!srList.isEmpty()){
            vanLocId = srList[0].LocationId;
        }
        List<Schema.Location> locList = [SELECT Id,Name FROM Location 
                                         WHERE (Name LIKE 'IWCR%' AND LocationType = 'Warehouse') LIMIT 1];
        Id whseLocId = locList[0].Id;
        searchKey = searchKey + '%';
        String searchKey2 = '%' + searchKey + '%';
        List<Product2> prodList = [SELECT Id, Name,Quantity_Available__c,Quantity__c,ProductCode,
                                   (SELECT Id,Product2Id,Product2.Name,Product_Code__c,LocationId,Location.Name,Location.LocationType,
                                   QuantityOnHand FROM ProductItems WHERE LocationId =:vanLocId) FROM Product2 
                                   WHERE Id IN (SELECT Product2Id FROM ProductItem) AND 
                                   (Name LIKE :searchKey OR Manufacturer_Part_Number__c LIKE :searchKey OR ProductCode LIKE :searchKey)];
        List<Product2> prodList2 = [SELECT Id, Name,Quantity_Available__c,Quantity__c,ProductCode,
                                    (SELECT Id,Product2Id,Product2.Name,Product_Code__c,LocationId,Location.Name,Location.LocationType,
                                    QuantityOnHand FROM ProductItems WHERE LocationId =:vanLocId) FROM Product2 
                                    WHERE Id IN (SELECT Product2Id FROM ProductItem) AND 
                                    (Name LIKE :searchKey2 OR Manufacturer_Part_Number__c LIKE :searchKey2 OR ProductCode LIKE :searchKey2)];
        prodMap.putAll(prodList);
        prodMap.putAll(prodList2);
        if(prodMap.isEmpty()){
            List<Product2> prodList3 = [SELECT Id, Name,Quantity_Available__c,Quantity__c,ProductCode,
                                        (SELECT Id,Product2Id,Product2.Name,Product_Code__c,LocationId,Location.Name,Location.LocationType,
                                        QuantityOnHand FROM ProductItems WHERE LocationId =:whseLocId) FROM Product2 
                                        WHERE Id IN (SELECT Product2Id FROM ProductItem) AND 
                                        (Name LIKE :searchKey OR Manufacturer_Part_Number__c LIKE :searchKey OR ProductCode LIKE :searchKey)];
            List<Product2> prodList4 = [SELECT Id, Name,Quantity_Available__c,Quantity__c,ProductCode,
                                        (SELECT Id,Product2Id,Product2.Name,Product_Code__c,LocationId,Location.Name,Location.LocationType,
                                        QuantityOnHand FROM ProductItems WHERE LocationId =:whseLocId) FROM Product2 
                                        WHERE Id IN (SELECT Product2Id FROM ProductItem) AND 
                                        (Name LIKE :searchKey2 OR Manufacturer_Part_Number__c LIKE :searchKey2 OR ProductCode LIKE :searchKey2)];
            prodMap.putAll(prodList3);
            prodMap.putAll(prodList4);
        }
        return prodMap.values();
    }

    @AuraEnabled
    public static void returnProductsToWarehouse(List<ProductItem> returnPartsList, List<Product2> prodList) {
        System.debug('returnPartsList-> ' + JSON.serialize(returnPartsList));
        System.debug('prodList-> ' + JSON.serialize(prodList));
        List<ServiceResource> srList = [SELECT Id,LocationId,RelatedRecordId FROM ServiceResource 
                                        WHERE RelatedRecordId=:UserInfo.getUserId()];
        Id vanLocId;
        if(!srList.isEmpty()){
            vanLocId = srList[0].LocationId;
        }
        List<Schema.Location> locList = [SELECT Id,Name,LocationType FROM Location 
                                         WHERE (Name LIKE 'IWCR%' AND LocationType = 'Warehouse') LIMIT 1];
        Id whseLocId = locList[0].Id;
        
        ProductRequest pr = new ProductRequest();
        pr.Description = 'Returning produdts to Warehouse Location.';
        pr.Status = 'Draft';
        pr.SourceLocationId = vanLocId;
        pr.DestinationLocationId = whseLocId;
        insert pr;
        List<ProductRequestLineItem> prliList = new List<ProductRequestLineItem>();
        List<ProductTransfer> ptList = new List<ProductTransfer>();

        for(ProductItem p : returnPartsList){
            ProductRequestLineItem prl = new ProductRequestLineItem();
            prl.ParentId = pr.Id;
            prl.Product2Id = p.Product2Id;
            prl.QuantityRequested = p.QuantityOnHand;
            prl.QuantityUnitOfMeasure = 'Each';
            prl.SourceLocationId = vanLocId;
            prl.DestinationLocationId = whseLocId;
            prliList.add(prl);
        }
        for(Product2 prod : prodList){
            ProductRequestLineItem prl = new ProductRequestLineItem();
            prl.ParentId = pr.Id;
            prl.Product2Id = prod.Id;
            prl.QuantityRequested = prod.Quantity__c;
            prl.QuantityUnitOfMeasure = 'Each';
            prl.SourceLocationId = vanLocId;
            prl.DestinationLocationId = whseLocId;
            prliList.add(prl);
        }
        if(!prliList.isEmpty()){
            insert prliList;

            for(ProductRequestLineItem prli : prliList){
                ProductTransfer pt = new ProductTransfer();
                pt.Product2Id = prli.Product2Id;
                pt.ProductRequestLineItemId = prli.Id;
                pt.quantitysent = prli.QuantityRequested;
                pt.QuantityReceived = prli.QuantityRequested;
                pt.IsReceived = true;
                pt.ReceivedById = UserInfo.getUserId();
                pt.QuantityUnitOfMeasure = 'Each';
                pt.SourceLocationId = vanLocId;
                pt.DestinationLocationId = whseLocId;
                pt.OwnerId = UserInfo.getUserId();
                pt.Description = 'Returning produdts to Warehouse Location.';
                ptList.add(pt);
            }
            if(!ptList.isEmpty()){
                insert ptList;
            }
        }
        /*ReturnOrder ro = new ReturnOrder();
        ro.ReturnedById = UserInfo.getUserId();
        ro.SourceLocationId = vanLocId;
        ro.DestinationLocationId = locMap.values()[0].Id;
        insert ro;

        if(ro.Id != null){
            List<ReturnOrderLineItem> roliList = new List<ReturnOrderLineItem>();
            for(ProductItem p : returnPartsList){
                ReturnOrderLineItem roli = new ReturnOrderLineItem();
                roli.ReturnOrderId = ro.Id;
                roli.Product2Id = p.Product2Id;
                roli.ProductItemId = p.Id;
                roli.QuantityReturned = p.QuantityOnHand;
                roli.SourceLocationId = vanLocId;
                roli.DestinationLocationId = locMap.values()[0].Id;
                roliList.add(roli);
            }

            for(Product2 prod : prodList){
                ReturnOrderLineItem roli = new ReturnOrderLineItem();
                roli.ReturnOrderId = ro.Id;
                roli.Product2Id = prod.Id;
                roli.QuantityReturned = prod.Quantity__c;
                roli.SourceLocationId = vanLocId;
                roli.DestinationLocationId = locMap.values()[0].Id;
                roliList.add(roli);
            }
            if(!roliList.isEmpty()){
                insert roliList;
            }
        }*/
    }
}