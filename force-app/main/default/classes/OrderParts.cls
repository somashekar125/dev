public without sharing class OrderParts {
    @AuraEnabled
    public static Boolean checkWOOwnerId(String workorderId) {
        Boolean isCubFieldTech = false;
        List<WorkOrder> woList = [SELECT Id,OwnerId FROM WorkOrder WHERE Id =: workorderId];
        if(!woList.isEmpty()){
            if(String.valueOf(woList[0].OwnerId).startsWith('005')) isCubFieldTech = true;
        }
        return isCubFieldTech;
    }
    
    @AuraEnabled
    public static List<Product2> retriveItemClassProducts(String workorderId) {
        System.debug('workorderId-> ' + workorderId);
        List<Product2> prodList = new List<Product2>();
        List<WorkOrder> woList = [SELECT Id,OwnerId,Root_Account__c,Root_Account__r.H_W_Root_Account__c,Equipment_Type__c,Equipment_Type__r.Item_Class__c 
                                  FROM WorkOrder WHERE Id =:workorderId AND Equipment_Type__r.Item_Class__c != null];
        if(woList.isEmpty()) return prodList;

        List<ServiceResource> srList = [SELECT Id,LocationId,RelatedRecordId FROM ServiceResource WHERE RelatedRecordId=:woList[0].OwnerId AND IsActive = true];
        Id vanLocId;
        if(!srList.isEmpty()) vanLocId = srList[0].LocationId;
        Map<Id,Schema.Location> locMap = new Map<Id,Schema.Location>([SELECT Id,Name FROM Location WHERE 
                                                                      (Name LIKE 'IWCR%' AND LocationType = 'Warehouse') OR (Id =: vanLocId) OR 
                                                                      (LocationType = 'Site' AND OwnerId =: woList[0].OwnerId) LIMIT 3]);
        System.debug('woList[0].Equipment_Type__r.Item_Class__c-> ' + woList[0].Equipment_Type__r.Item_Class__c);
        prodList = [SELECT Id, Name,Quantity_on_Hand__c,Quantity_Available__c,Quantity_Back_Ordered__c,Quantity__c,ProductCode,
                    (SELECT Id,LocationId,Location.Name,Location.LocationType, QuantityOnHand FROM ProductItems 
                    WHERE LocationId IN: locMap.keySet() LIMIT 3) FROM Product2 
                    WHERE Id IN (SELECT Product2Id FROM ProductItem WHERE LocationId IN:locMap.keySet()) AND 
                    NS_Item_Class__c =:woList[0].Equipment_Type__r.Item_Class__c AND 
                    (Account_Item_Belongs_To__c =: woList[0].Root_Account__r.H_W_Root_Account__c OR 
                    Account_Item_Belongs_To__c =: woList[0].Root_Account__c) AND Family = 'Hardware' ORDER BY Name];
        for(Product2 p : prodList){
            p.Quantity__c = 0;
        }
        return prodList;
    }
    
    @AuraEnabled
    public static List<Product2> retriveAllCUBProducts(String workorderId, Integer limitNumber) {
        System.debug('workorderId-> ' + workorderId);
        List<Product2> prodList = new List<Product2>();
        List<WorkOrder> woList = [SELECT Id,OwnerId,Root_Account__c,Root_Account__r.H_W_Root_Account__c FROM WorkOrder 
                                  WHERE Id =:workorderId AND Root_Account__c != null];
        System.debug('woList[0].Root_Account__r.H_W_Root_Account__c-> ' + woList[0].Root_Account__r.H_W_Root_Account__c);
        List<ServiceResource> srList = [SELECT Id,LocationId,RelatedRecordId FROM ServiceResource WHERE RelatedRecordId=:woList[0].OwnerId AND IsActive = true];
        Id vanLocId;
        if(!srList.isEmpty()) vanLocId = srList[0].LocationId;
        Map<Id,Schema.Location> locMap = new Map<Id,Schema.Location>([SELECT Id,Name FROM Location 
                                                                      WHERE (Name LIKE 'IWCR%' AND LocationType = 'Warehouse') OR 
                                                                      (Id =: vanLocId) OR (LocationType = 'Site' AND 
                                                                      OwnerId =: woList[0].OwnerId) LIMIT 3]);
        prodList = [SELECT Id, Name,Quantity_on_Hand__c,Quantity_Available__c,Quantity_Back_Ordered__c,Quantity__c,ProductCode,
                    (SELECT Id,LocationId,Location.Name,Location.LocationType, QuantityOnHand 
                    FROM ProductItems WHERE LocationId IN:locMap.keySet() LIMIT 3)
                    FROM Product2 WHERE Id IN (SELECT Product2Id FROM ProductItem WHERE LocationId IN:locMap.keySet()) AND 
                    (Account_Item_Belongs_To__c =: woList[0].Root_Account__r.H_W_Root_Account__c OR 
                    Account_Item_Belongs_To__c =: woList[0].Root_Account__c) AND Family = 'Hardware' ORDER BY Name LIMIT :limitNumber];
        for(Product2 p : prodList){
            p.Quantity__c = 0;
        }
        return prodList;
    }
    
    @AuraEnabled
    public static List<Product2> retriveSearhedProducts(String searchKey, String workorderId) {
        System.debug('workorderId-> ' + workorderId);
        Map<Id,Product2> prodMap = new Map<Id,Product2>();
        List<WorkOrder> woList = [SELECT Id,Root_Account__c,Root_Account__r.H_W_Root_Account__c,OwnerId FROM WorkOrder 
                                  WHERE Id =:workorderId AND Root_Account__c != null];
        System.debug('woList[0].Root_Account__r.H_W_Root_Account__c-> ' + woList[0].Root_Account__r.H_W_Root_Account__c);
        List<ServiceResource> srList = [SELECT Id,LocationId,RelatedRecordId FROM ServiceResource WHERE RelatedRecordId=:woList[0].OwnerId AND IsActive = true];
        Id vanLocId;
        if(!srList.isEmpty()) vanLocId = srList[0].LocationId;
        searchKey = searchKey + '%';
        String searchKey2 = '%' + searchKey + '%';
        List<Product2> prodList = [SELECT Id, Name,Quantity_on_Hand__c,Quantity_Available__c,Quantity_Back_Ordered__c,Quantity__c,ProductCode,
                                   (SELECT Id,LocationId,Location.Name,Location.LocationType,QuantityOnHand 
                                   FROM ProductItems 
                                   WHERE (Location.Name LIKE 'IWCR%' AND Location.LocationType = 'Warehouse') OR 
                                   (LocationId =: vanLocId) OR (Location.LocationType = 'Site' AND Location.OwnerId =: woList[0].OwnerId))
                                   FROM Product2 
                                   WHERE Id IN (SELECT Product2Id FROM ProductItem WHERE (Location.Name LIKE 'IWCR%' AND 
                                   Location.LocationType = 'Warehouse') OR (LocationId =: vanLocId) OR 
                                   (Location.LocationType = 'Site' AND Location.OwnerId =: woList[0].OwnerId)) AND 
                                   (Name LIKE :searchKey OR Manufacturer_Part_Number__c LIKE :searchKey OR ProductCode LIKE :searchKey) AND 
                                   (Account_Item_Belongs_To__c =: woList[0].Root_Account__r.H_W_Root_Account__c OR 
                                   Account_Item_Belongs_To__c =: woList[0].Root_Account__c) AND Family = 'Hardware' ORDER BY Name];
        List<Product2> prodList2 = [SELECT Id, Name,Quantity_on_Hand__c,Quantity_Available__c,Quantity_Back_Ordered__c,Quantity__c,ProductCode,
                                    (SELECT Id,LocationId,Location.Name,Location.LocationType,QuantityOnHand 
                                    FROM ProductItems 
                                    WHERE (Location.Name LIKE 'IWCR%' AND Location.LocationType = 'Warehouse') OR 
                                    (LocationId =: vanLocId) OR (Location.LocationType = 'Site' AND Location.OwnerId =: woList[0].OwnerId))
                                    FROM Product2 
                                    WHERE Id IN (SELECT Product2Id FROM ProductItem WHERE (Location.Name LIKE 'IWCR%' AND 
                                    Location.LocationType = 'Warehouse') OR (LocationId =: vanLocId) OR 
                                    (Location.LocationType = 'Site' AND Location.OwnerId =: woList[0].OwnerId)) AND 
                                    (Name LIKE :searchKey2 OR Manufacturer_Part_Number__c LIKE :searchKey2 OR ProductCode LIKE :searchKey2) AND 
                                    (Account_Item_Belongs_To__c =: woList[0].Root_Account__r.H_W_Root_Account__c OR 
                                    Account_Item_Belongs_To__c =: woList[0].Root_Account__c) AND Family = 'Hardware' ORDER BY Name];
        prodMap.putAll(prodList);
        prodMap.putAll(prodList2);
        for(Product2 p : prodMap.values()){
            p.Quantity__c = 0;
        }
        return prodMap.values();
    }
    
    @AuraEnabled
    public static String createWOLIs(List<Product2> prodList, String workorderId) {
        try{
            List<WorkOrder> woList = new List<WorkOrder>();
            if(!String.isBlank(workorderId)){
                woList = [SELECT Id,Root_Account__c,Netsuite_Sales_Order__c,CaseId,OwnerId,AccountId,Incident__c,Pricebook2Id,
                          Equipment_Type__c,Problem_Type__c,Department2__c,Street, 
                          City,State,Country,PostalCode FROM WorkOrder WHERE Id =:workorderId];
            }
            if(woList.isEmpty()){
                return 'No Oniste Work Order Found.';
            }
            createWOandInventory(prodList,woList[0]);
        } catch(Exception e){
            System.debug('e.getMessage()-> ' + e.getMessage());
            return e.getMessage();
        }
        return 'Work Order & Inventory Records Are Created Successfully!.';
    }
    
    public static void createWOandInventory(List<Product2> prodList, WorkOrder onsiteWO) {
        System.debug('prodList-> ' + JSON.serialize(prodList));
        List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
        Id partRTId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Part_Shipment').getRecordTypeId();
        List<ServiceContract> scList = [SELECT Id,AccountId FROM ServiceContract WHERE AccountId =: onsiteWO.Root_Account__c AND 
                                        Status = 'Active' AND Include_in_Service_Type_Picklist__c = true AND 
                                        Service_Type__c = 'Advance Exchange (Depot Only)' AND Work_Order_Record_Type__c = 'Part Shipment' LIMIT 1];
        WorkOrder wo = new WorkOrder();
        wo.CaseId = onsiteWO.CaseId;
        wo.AccountId = onsiteWO.AccountId;
        wo.Root_Account__c = onsiteWO.Root_Account__c;
        wo.OwnerId = onsiteWO.OwnerId;
        wo.Pricebook2Id =onsiteWO.Pricebook2Id;
        wo.RecordTypeId = partRTId;
        if(!scList.isEmpty()){
            wo.ServiceContractId = scList[0].Id;
        }
        wo.Equipment_Type__c =onsiteWO.Equipment_Type__c;
        wo.Problem_Type__c = onsiteWO.Problem_Type__c;
        wo.Department2__c = onsiteWO.Department2__c;
        wo.Service_Type__c = 'Field Tech - Part Request';
        wo.Incident__c = onsiteWO.Incident__c;
        wo.Street = onsiteWO.Street;
        wo.City = onsiteWO.City;
        wo.State = onsiteWO.State;
        wo.Country = onsiteWO.Country;
        wo.PostalCode = onsiteWO.PostalCode;
        wo.OrderedPartWO__c = true;
        insert wo;
        
        //Creating WOLIs
        Set<Id> prodIds = new Set<Id>();
        for(Product2 p : prodList){
            prodIds.add(p.Id);
        }
        List<PricebookEntry> pbeList = [SELECT Id,Product2Id,UnitPrice FROM PricebookEntry 
                                        WHERE Product2Id IN: prodIds AND Pricebook2Id =: wo.Pricebook2Id];
        for(Product2 p : prodList){
            if(p.Quantity__c == 0) continue;
            for(PricebookEntry pbe : pbeList){
                if(pbe.Product2Id != p.Id) continue;
                WorkOrderLineItem woli = new WorkOrderLineItem(PricebookEntryId = pbe.Id,UnitPrice = pbe.UnitPrice,Quantity = p.Quantity__c, WorkOrderId = wo.Id);
                woliList.add(woli);
            }
        }
        System.debug('woliList-> ' + JSON.serialize(woliList));
        if(!woliList.isEmpty()) insert woliList;

        //IWCR Warehouse, Hub & Van Locations
        List<ServiceResource> srList = [SELECT Id,LocationId,RelatedRecordId FROM ServiceResource WHERE RelatedRecordId=:onsiteWO.OwnerId AND IsActive = true];
        Id vanLocId;
        if(!srList.isEmpty()) vanLocId = srList[0].LocationId;
        List<Schema.Location> locList = [SELECT Id,Name,LocationType, (SELECT Id,LocationId,Location.Name,
                                         Location.LocationType,Product2Id,Product2.Name,QuantityOnHand 
                                         FROM ProductItems) FROM Location 
                                         WHERE (Id =: vanLocId) OR (OwnerId =: onsiteWO.OwnerId AND LocationType = 'Site') OR (Name LIKE 'IWCR%' AND LocationType = 'Warehouse') LIMIT 3];
        //All product Items In Hub & Van Locations
        /*List<ProductItem> inStockProdList = new List<ProductItem>();
        for(Schema.Location l : locList){
        inStockProdList.addAll(l.ProductItems);
        }
        System.debug('inStockProdList -> ' + inStockProdList);
        Map<Id,Decimal> hubProdItemMap = new Map<Id,Decimal>();
        Map<Id,Decimal> vanProdItemMap = new Map<Id,Decimal>();
        for(ProductItem pi : inStockProdList){
        if(pi.Location.LocationType == 'Van'){
        vanProdItemMap.put(pi.Product2Id,pi.QuantityOnHand);
        }
        if(pi.Location.LocationType == 'Site'){
        hubProdItemMap.put(pi.Product2Id,pi.QuantityOnHand);
        }
        }
        System.debug('vanProdItemMap values-> ' + vanProdItemMap.values());
        System.debug('hubProdItemMap values-> ' + hubProdItemMap.values());*/
        
        // Checking if an item needs to be ordered from IWCR Warehouse.
        Map<ProductRequest,List<ProductRequestLineItem>> prodReqMap = new Map<ProductRequest,List<ProductRequestLineItem>>();
        Schema.Location siteLocation = null;
        Schema.Location vanLocation = null;
        Schema.Location warehouseLocation = null;
        for(Schema.Location l : locList){
            if(l.LocationType == 'Site'){
                siteLocation = l;
            }
            if(l.LocationType == 'Van'){
                vanLocation = l;
            }
            if(l.LocationType == 'Warehouse'){
                warehouseLocation = l;
            }
        }
        
        Map<Id,Id> woliProdMap = new Map<Id,Id>();
        for(WorkOrderLineItem woli : woliList){
            for(PricebookEntry pbe : pbeList){
                if(woli.PricebookEntryId != pbe.Id) continue;
                woliProdMap.put(woli.Id,pbe.Product2Id);
            }
        }
        ProductRequest pr = null;
        for(WorkOrderLineItem woli : woliList){
            if(!woliProdMap.containskey(woli.Id)) continue;
            Decimal quantityRequired = 0;
            for(Product2 prod : prodList){
                if(prod.Id != woliProdMap.get(woli.Id)) continue;
                quantityRequired = woli.Quantity;
                /*Decimal vanQuantity = 0;
                Decimal hubQuantity = 0;
                if(vanProdItemMap.containskey(prod.Id)){
                vanQuantity = vanProdItemMap.get(prod.Id);
                }
                if(hubProdItemMap.containskey(prod.Id)){
                hubQuantity = hubProdItemMap.get(prod.Id);
                }*/
                                
                //if(quantityRequired <= vanQuantity) continue; // If sufficient Qty exist on van then no transfer of products
                
                /*Decimal totalQuantity = vanQuantity + hubQuantity;
                if(quantityRequired > totalQuantity){
                ProductRequestLineItem prl1 = new ProductRequestLineItem();
                prl1.AccountId = wo.AccountId;
                prl1.CaseId = wo.CaseId;
                prl1.Product2Id = prod.Id;
                prl1.QuantityRequested = quantityRequired - totalQuantity;
                prl1.QuantityUnitOfMeasure = 'Each';
                prl1.WorkOrderId = wo.Id;
                prl1.WorkOrderLineItemId = woli.Id;
                prl1.SourceLocationId = warehouseLocation.Id;
                prl1.DestinationLocationId = siteLocation.Id;
                if(prodReqMap.isEmpty()){
                pr = new ProductRequest();
                pr.AccountId = wo.AccountId;
                pr.OwnerId = onsiteWO.OwnerId;
                pr.CaseId = wo.CaseId;
                pr.WorkOrderId = wo.Id;
                pr.Status = 'Submitted';
                List<ProductRequestLineItem> prliList = new List<ProductRequestLineItem>();
                prliList.add(prl1);
                prodReqMap.put(pr,prliList);
                } else{
                prodReqMap.get(pr).add(prl1);
                }
                ProductRequestLineItem prl2 = new ProductRequestLineItem();
                prl2.AccountId = wo.AccountId;
                prl2.CaseId = wo.CaseId;
                prl2.ParentId = pr.Id;
                prl2.Product2Id = prod.Id;
                prl2.QuantityRequested = quantityRequired - vanQuantity;
                prl2.QuantityUnitOfMeasure = 'Each';
                prl2.WorkOrderId = wo.Id;
                prl2.WorkOrderLineItemId = woli.Id;
                prl2.SourceLocationId = siteLocation.Id;
                prl2.DestinationLocationId = vanLocation.Id;
                prodReqMap.get(pr).add(prl2);
                System.debug('prodReqMap.get(pr) 2-> ' + prodReqMap.get(pr));
                continue;
                }*/
                
                //Direct transfer from IWCR Warehouse to Van
                //if(quantityRequired > vanQuantity){}
                ProductRequestLineItem prl = new ProductRequestLineItem();
                prl.AccountId = wo.AccountId;
                prl.CaseId = wo.CaseId;
                prl.Product2Id = prod.Id;
                prl.QuantityRequested = quantityRequired;
                prl.QuantityUnitOfMeasure = 'Each';
                prl.WorkOrderId = wo.Id;
                prl.WorkOrderLineItemId = woli.Id;
                prl.SourceLocationId = warehouseLocation.Id;
                prl.DestinationLocationId = vanLocation.Id;
                
                if(prodReqMap.isEmpty()){
                    pr = new ProductRequest();
                    pr.AccountId = wo.AccountId;
                    pr.OwnerId = onsiteWO.OwnerId;
                    pr.CaseId = wo.CaseId;
                    pr.WorkOrderId = wo.Id;
                    pr.Status = 'Draft';
                    List<ProductRequestLineItem> prliList = new List<ProductRequestLineItem>();
                    prliList.add(prl);
                    prodReqMap.put(pr,prliList);
                } else {
                    prodReqMap.get(pr).add(prl);
                }
                System.debug('prodReqMap.get(pr)-> ' + prodReqMap.get(pr));
                continue;
            }
        }
        if(!prodReqMap.isEmpty()){
            System.debug('prodReqMap.get(pr) 3-> ' + prodReqMap.get(pr));
            List<ProductRequestLineItem> prliToInsertList = prodReqMap.get(pr);
            System.debug('prliToInsertList-> ' + JSON.serialize(prliToInsertList));
            insert pr;
            for(ProductRequestLineItem prli : prliToInsertList){
                prli.ParentId = pr.Id;
            }
            if(!prliToInsertList.isEmpty()){
                insert prliToInsertList;
                
                //Creating Product Transfer Records
                List<ProductTransfer> ptList = new List<ProductTransfer>();
                for(ProductRequestLineItem prli : prliToInsertList){
                    ProductTransfer pt = new ProductTransfer();
                    pt.Product2Id = prli.Product2Id;
                    pt.ProductRequestLineItemId = prli.Id;
                    pt.Case__c = wo.CaseId;
                    pt.Work_Order__c = wo.Id;
                    pt.Onsite_Work_Order__c = onsiteWO.Id;
                    pt.Work_Order_Line_Item__c = prli.WorkOrderLineItemId;
                    pt.Sales_Order__c = wo.Netsuite_Sales_Order__c;
                    pt.quantitysent  = prli.QuantityRequested;
                    pt.QuantityUnitOfMeasure = prli.QuantityUnitOfMeasure;
                    pt.DestinationLocationId = prli.DestinationLocationId;
                    pt.SourceLocationId = prli.SourceLocationId;
                    pt.Description = 'Transferring products to Van Location.';
                    String woOwnerId = onsiteWO.OwnerId;
                    if(woOwnerId.startsWith('005')) {
                        pt.OwnerId = woOwnerId;
                    }
                    for(Schema.Location loc : locList) {
                        if(loc.Id == prli.SourceLocationId) {
                            for(ProductItem pi : loc.ProductItems) {
                                if(pi.Product2Id == prli.Product2Id) {
                                    pt.SourceProductItemId = pi.Id;
                                    break;
                                }
                            }
                            break;
                        }
                    }
                    ptList.add(pt);
                }
                if(!ptList.isEmpty()) insert ptList;
            }
        }
    }
}