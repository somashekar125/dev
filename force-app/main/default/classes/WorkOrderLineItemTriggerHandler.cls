public class WorkOrderLineItemTriggerHandler {
    public static void handleBeforeInsert(List<WorkOrderLineItem> woliList) {
        applyProductMarkup(woliList);
    }

    public static void handlebeforeUpdate(Map<Id, WorkOrderLineItem> newMap, Map<Id, WorkOrderLineItem> oldMap) {
        List<WorkOrderLineItem> markupWOLIsList = new List<WorkOrderLineItem>();
        for(WorkOrderLineItem w : newMap.values()){
            if(w.PricebookEntryId != oldMap.get(w.Id).PricebookEntryId){
                markupWOLIsList.add(w);
            }
        }
        if(!markupWOLIsList.isEmpty()){
            applyProductMarkup(markupWOLIsList);
        }
        imagesCheck(newMap);
    }

    public static void handleAfterInsert(Map<Id, WorkOrderLineItem> newMap) {
        WorkOrderLineItemTriggerHandler.copyChildWOLIToParentWo(newMap);
        outOfScopeCheck(newMap);
        List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
        for(WorkOrderLineItem woli : newMap.values()){
            if(woli.Product_Family__c == 'Hardware') woliList.add(woli);
        }
        if(!woliList.isEmpty()){
            populateProductOrderedInCase(woliList, false);
        }
        //createFSLInventoryRecords(newMap);
    }

    public static void handleAfterUpdate(Map<Id, WorkOrderLineItem> newMap, Map<Id, WorkOrderLineItem> oldMap){
        if(!System.isFuture() && !System.isBatch()) {
            WorkOrderLineItemTriggerHandler.updateWOLIInParentWo(JSON.serialize(newMap),JSON.serialize(oldMap));
        }
        outOfScopeCheck(newMap);
    }

    public static void handleBeforeDelete(Map<Id, WorkOrderLineItem> oldMap) {
        List<WorkOrderLineItem> parentWOLIList = [SELECT Id,Child_WOLI__c FROM WorkOrderLineItem WHERE Child_WOLI__c IN: oldMap.keySet()];
        System.debug('oldMap.keySet()-->' + oldMap.keySet());
        System.debug('parentWOLIList size-->' + parentWOLIList.size());
        if(parentWOLIList.size() > 0){
            delete parentWOLIList;
        }
    }

    public static void handleAfterDelete(Map<Id, WorkOrderLineItem> oldMap) {
        List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
        for(WorkOrderLineItem woli : oldMap.values()){
            if(woli.Product_Family__c == 'Hardware' && woli.ParentWorkOrderLineItemId == null) woliList.add(woli);
        }
        if(!woliList.isEmpty()){
            populateProductOrderedInCase(woliList, true);
        }
    }

    /*public static void createFSLInventoryRecords(Map<Id, WorkOrderLineItem> newMap) {
        List<ProductConsumed> pcList = new List<ProductConsumed>();
        Set<Id> prodIds = new Set<Id>();
        for(WorkOrderLineItem woli : newMap.values()){
            prodIds.add(woli.product2Id);
        }
        List<ProductItem> piList = [SELECT Id,Product2Id FROM ProductItem WHERE Product2Id IN:prodIds];
        Map<Id,Id> woliProdItemMap = new Map<Id,Id>();
        for(WorkOrderLineItem woli : newMap.values()){
            for(ProductItem pi : piList){
                if(pi.Product2Id != woli.product2Id) continue;
                woliProdItemMap.put(woli.Id,pi.Id);
            }
        }
        if(!woliProdItemMap.isEmpty()){
            for(WorkOrderLineItem woli : newMap.values()){
                if(woliProdItemMap.containsKey(woli.Id) && (woli.Account_Name__c.containsIgnoreCase('CUB') || woli.Account_Name__c.containsIgnoreCase('SHOPPERS'))){
                    ProductConsumed pc = new ProductConsumed();
                    pc.WorkOrderId = woli.WorkOrderId;
                    pc.WorkOrderLineItemId = woli.Id; 
                    pc.ProductItemId = woliProdItemMap.get(woli.Id);
                    pc.PricebookEntryId = woli.PricebookEntryId;
                    pc.QuantityConsumed = woli.Quantity;
                    pc.UnitPrice = woli.UnitPrice;
                    pcList.add(pc);
                }
            }
            if(!pcList.isEmpty()){
                insert pcList;
            }
        }
    }*/

    public static void populateProductOrderedInCase(List<WorkOrderLineItem> woliList, Boolean isAfterDelete) {
        Set<String> csNumbers = new Set<String>();
        for(WorkOrderLineItem woli : woliList){
            csNumbers.add(woli.Case_Number__c);
        }
        List<Case> csList = new List<Case>();
        if(!csNumbers.isEmpty()){
            csList = [SELECT Id,CaseNumber,Products_Ordered__c FROM Case WHERE CaseNumber IN: csNumbers];
            Integer poCount = 0;
            for(Case cs : csList){
                for(WorkOrderLineItem woli : woliList){
                    if(woli.Case_Number__c != cs.CaseNumber) continue;
                    //contains() & containIgnoreCase() doesn't work all the time as Product Name contains special characters and html tags.
                    if(isAfterDelete){
                        if(!String.isBlank(cs.Products_Ordered__c)){
                            cs.Products_Ordered__c = cs.Products_Ordered__c.remove('<p>').replaceAll('</p>','<br>');
                            cs.Products_Ordered__c = cs.Products_Ordered__c.replaceAll('&quot;','"');
                            System.debug('cs.Products_Ordered__c before-> ' + cs.Products_Ordered__c);
                            // ex: 1. Crucial MX500 Solid State Drive; 250GB, 3D NAND SATA 2.5" 7mm (w/ 9.5mm Adapter)<br>
                            String productOrdered = '';
                            if(cs.Products_Ordered__c.contains('<br>')){
                                List<String> tempList = cs.Products_Ordered__c.split('<br>');
                                //Listing all except deleted ones.
                                for(String s : tempList){
                                    s = s.replace('&quot;', '"');
                                    if(!s.contains(woli.Product_Name__c)) productOrdered += s + '<br>';
                                }
                                //Renumbering
                                List<String> poList = productOrdered.split('<br>');
                                productOrdered = '';
                                for(String s : poList){
                                    List<String> tempList2 = s.split(' ');
                                    poCount += 1;
                                    String temp = poCount + '.';
                                    String prodName = '';
                                    Boolean isReplaced = false;
                                    //ReplaceAll is not ideal as matching pairs will be multiple in same line.
                                    //So replacing at first match.
                                    for(String s2 : tempList2){
                                        if(s2 == tempList2[0] && !isReplaced) {
                                            prodName += temp + ' ';
                                            isReplaced = true;
                                            continue;
                                        }
                                        prodName += s2 + ' ';
                                    }
                                    productOrdered += prodName + '<br>';
                                }
                            }                            
                            cs.Products_Ordered__c = productOrdered;
                            System.debug('cs.Products_Ordered__c after delete-> ' + cs.Products_Ordered__c);
                        }
                    } else {
                        if(!String.isBlank(cs.Products_Ordered__c)){
                            cs.Products_Ordered__c = cs.Products_Ordered__c.remove('<p>').replaceAll('</p>','<br>');
                            cs.Products_Ordered__c = cs.Products_Ordered__c.replaceAll('&quot;','"');
                            System.debug('cs.Products_Ordered__c before-> ' + cs.Products_Ordered__c);
                            List<String> tempList = new List<String>();
                            Boolean prodExists = false;
                            if(cs.Products_Ordered__c.contains('<br>')){
                                tempList = cs.Products_Ordered__c.split('<br>');
                                for(String s : tempList){
                                    s = s.replace('&quot;', '"');
                                    if(s.contains(woli.Product_Name__c)) prodExists = true;
                                }
                            }
                            if(prodExists || tempList.isEmpty()) continue;
                            List<String> tempList2 = tempList[tempList.size() - 1].split(' ');
                            String temp = tempList2[0].remove('.').remove('<br>');
                            if(temp.isNumeric()) poCount = Integer.valueOf(temp);
                            poCount += 1;
                            cs.Products_Ordered__c += poCount + '. ' + woli.Product_Name__c + '<br>';
                        } else {
                            poCount += 1;
                            cs.Products_Ordered__c = poCount + '. ' + woli.Product_Name__c + '<br>';
                        }
                        System.debug('cs.Products_Ordered__c after insert-> ' + cs.Products_Ordered__c);
                    }
                }
            }
            if(poCount != 0 || isAfterDelete){
                update csList;
            }
        }
    }

    public static void outOfScopeCheck(Map<Id, WorkOrderLineItem> newMap) {
        List<WorkOrderLineItem> woliList = [SELECT Id,WorkOrder.CaseId,Product2.Out_of_Scope__c FROM WorkOrderLineItem 
                                            WHERE Id IN: newMap.keySet() AND Product2.Out_of_Scope__c = true];
        Set<Id> csIds = new Set<Id>();
        for(WorkOrderLineItem woli : woliList){
            csIds.add(woli.WorkOrder.CaseId);
        }
        if(!csIds.isEmpty()){
            List<Case> csList = [SELECT Id,Out_Of_Scope__c FROM Case WHERE Out_Of_Scope__c = false AND Id IN:csIds];
            for(Case c: csList){
                c.Out_Of_Scope__c = true;
            }
            if(!csList.isEmpty()){
                update csList;
            }
        }
    }

    public static void imagesCheck(Map<Id, WorkOrderLineItem> newMap) {
        Map<Id,WorkOrderLineItem> woliMap = new Map<Id,WorkOrderLineItem>([SELECT Id,No_Images__c,(SELECT Id FROM ContentDocumentLinks) FROM WorkOrderLineItem
                                                                            WHERE WorkOrder.Account.Name like 'BOSCOV%' AND Id IN:newMap.keySet()]);
        for(WorkOrderLineItem woli : newMap.values()){
            if(!woliMap.containsKey(woli.Id)) continue;
            WorkOrderLineItem w = woliMap.get(woli.Id);
            if(w.ContentDocumentLinks.size() > 0){
                woli.No_Images__c = false;
            }
        }
    }

    public static void applyProductMarkup(List<WorkOrderLineItem> woliList){
        Set<Id> pbIds = new Set<Id>();
        Set<Id> prodIds = new Set<Id>();
        Set<Id> woIds = new Set<Id>();
        Set<Id> markupProdIds = new Set<Id>();
        for(WorkOrderLineItem w : woliList){
            pbIds.add(w.PricebookEntryId);
            woIds.add(w.WorkOrderId);
        }
        Map<Id,WorkOrder> woMap = new  Map<Id,WorkOrder>([SELECT Id,Account.ShippingCountry,Account.ShippingState FROM WorkOrder WHERE Id IN: woIds]);
        List<Product2> prodLIst = [SELECT Id,(SELECT Id,Product__c,Markup__c,State__c,Country__c FROM Product_Markups__r),
                                    (SELECT Id,Product2Id FROM PricebookEntries WHERE Id IN:pbIds) FROM Product2 
                                    WHERE Id IN (SELECT Product__c FROM Product_Markup__c)];
        for(Product2 p : prodLIst){
            for(Product_Markup__c pm : p.Product_Markups__r){
                markupProdIds.add(pm.Product__c);
            }
        }
        if(!markupProdIds.isEmpty()){
            for(WorkOrderLineItem w : woliList){
                for(Product2 prod : prodLIst){
                    for(PricebookEntry pbe : prod.PricebookEntries){
                        if(w.PricebookEntryId != pbe.Id) continue;
                        if(!markupProdIds.contains(pbe.Product2Id)) continue;
                        for(Product_Markup__c pm : prod.Product_Markups__r){
                            if(pm.Product__c != pbe.Product2Id) continue;
                            WorkOrder wo = woMap.get(w.WorkOrderId);
                            if(wo.Account.ShippingCountry == pm.Country__c && wo.Account.ShippingState == pm.State__c){
                                w.UnitPrice += pm.Markup__c;
                            }
                        }
                    }
                }
                
            }
        }
    }

    public static void copyChildWOLIToParentWo(Map<Id, WorkOrderLineItem> newMap) {
        Map<Id,WorkOrderLineItem> childWoWoliMap = new Map<Id, WorkOrderLineItem>([SELECT Id,WorkOrder.ParentWorkOrderId,
                                                                                   WorkOrderId,Child_WOLI__c,PricebookEntryId,unitPrice,Quantity,
                                                                                   Description FROM WorkOrderLineItem WHERE Id IN :newMap.keySet() 
                                                                                   AND WorkOrder.ParentWorkOrderId != null]);
        System.debug('newMap to copy-->' + newMap);
        System.debug('childWoWoliMap size-->' + childWoWoliMap.size());
        System.debug('childWoWoliMap-->' + childWoWoliMap);
        List<WorkOrderLineItem> woliList = [SELECT Child_WOLI__c,PricebookEntryId,unitPrice,Quantity,
                                            Description,WorkOrderId FROM WorkOrderLineItem 
                                            WHERE Child_WOLI__c IN :childWoWoliMap.keySet()];
        System.debug('woliList size-->' + woliList.size());
        List<WorkOrderLineItem> toInsert = new List<WorkOrderLineItem>();
        Set<ID> woliIds = new Set<ID>();
        for(WorkOrderLineItem woli : childWoWoliMap.values()) {
            boolean parentWoliFound = false;
            for(WorkOrderLineItem woli1 : woliList) {
                if(woli.Id == woli1.Child_WOLI__c) {
                    parentWoliFound = true;
                    break;
                }
            }
            System.debug('parentWoliFound-->' + parentWoliFound);
            if(!parentWoliFound) {
                WorkOrderLineItem parenWoli = new WorkOrderLineItem(PricebookEntryId =woli.PricebookEntryId,unitPrice=woli.unitPrice,Quantity=1,
                Description = woli.Description,WorkOrderId=woli.WorkOrder.ParentWorkOrderId, Child_WOLI__c = woli.Id,Child_WO__c = woli.WorkOrderId);
                
                toInsert.add(parenWoli);
            }
        }
        if(!toInsert.isEmpty()){
            insert toInsert;
        }
        //ParentWOLICreationBatch pbc = new ParentWOLICreationBatch(toInsert);
        //Database.executeBatch(pbc, 1);
    }

    @future
    public static void updateWOLIInParentWo(String newMapStr, String oldMapStr) {
        Map<Id, WorkOrderLineItem> newMap = (Map<Id, WorkOrderLineItem>) JSON.deserialize(newMapStr, Map<Id, WorkOrderLineItem>.class);
        Map<Id, WorkOrderLineItem> oldMap = (Map<Id, WorkOrderLineItem>) JSON.deserialize(oldMapStr, Map<Id, WorkOrderLineItem>.class);
        List<WorkOrderLineItem> wolisToUpdateList = new List<WorkOrderLineItem>();
        Map<Id,WorkOrderLineItem> childWoWoliMap = new Map<Id, WorkOrderLineItem>([SELECT Id,WorkOrder.ParentWorkOrderId,
                                                    WorkOrderId,Child_WOLI__c,PricebookEntryId,unitPrice,Quantity,Description
                                                    FROM WorkOrderLineItem WHERE Id IN :newMap.keySet() 
                                                    AND WorkOrder.ParentWorkOrderId != null]);
        List<WorkOrderLineItem> parentWOLIList = [SELECT Id,Child_WOLI__c,PricebookEntryId,Quantity,
                                                    Description,WorkOrderId,unitPrice FROM WorkOrderLineItem 
                                                    WHERE Child_WOLI__c IN: childWoWoliMap.keySet()];
        System.debug('parentWOLIList size-->' + parentWOLIList.size());
        for(WorkOrderLineItem woliNew : childWoWoliMap.values()){
            for(WorkOrderLineItem woliOld : parentWOLIList){
                if(woliNew.Id != woliOld.Child_WOLI__c) continue;
                WorkOrderLineItem woli = new WorkOrderLineItem();
                woli.Id = woliOld.Id;
                boolean isUpdated = false;
                if(woliNew.Quantity != woliOld.Quantity){
                    woli.Quantity = woliNew.Quantity;
                    isUpdated = true;
                }
                if(woliNew.Description != woliOld.Description){
                    woli.Description = woliNew.Description;
                    isUpdated = true;
                }
                if(woliNew.unitPrice != woliOld.unitPrice){
                    woli.unitPrice = woliNew.unitPrice;
                    isUpdated = true;
                }
                if(isUpdated) {
                    wolisToUpdateList.add(woli);
                }
            }
        }
        Map<Id,WorkOrderLineItem> wolisToUpdateMap = new Map<Id,WorkOrderLineItem>();
        wolisToUpdateMap.putAll(wolisToUpdateList);
        Update wolisToUpdateMap.values();
    }

    /*public static void createAssets(List<WorkOrderLineItem> woliList){
        set<Id> woIds = new set<Id>();
        for(WorkOrderLineItem woli : woliList){
            woIds.add(woli.WorkOrderId);
        }
        System.debug('workOrderIds::'+woIds);
        List<WorkOrder> woList = [SELECT Id, CaseId, Case.Asset_Number__c FROM WorkOrder WHERE Id IN: woIds];
        set<String> asstNums = new set<String>();
        set<string> caseIds = new set<string>();
        for(WorkOrder wo : woList){
            caseIds.add(wo.CaseId);
            if(wo.Case.Asset_Number__c == null) continue;
            if((!wo.Case.Asset_Number__c.contains(',') && !wo.Case.Asset_Number__c.contains('&') && !wo.Case.Asset_Number__c.contains('AND'))){
                asstNums.add(wo.Case.Asset_Number__c);
            }
            else {
                List<string> serialNumberList = wo.Case.Asset_Number__c.split(',');
                for(String str : serialNumberList){
                    asstNums.add(str);
                }
            }
        }
        List<Case_Product__c> cpList = [SELECT Id, Case__r.AccountId, Case__r.Account.Root_Account__c, Case__r.Service_Type__c, Product__c, Product__r.Name, Product__r.Account_Item_Belongs_To__c FROM Case_Product__c WHERE Case__c IN: caseIds AND Product__r.Family = 'Hardware'];
        set<string> productIds = new set<string>();
        for(Case_Product__c cp : cpList){
            productIds.add(cp.Product__c);
        }
        List<Asset> assetList = [SELECT Id, Name, SerialNumber, Asset_Number__c, Product2Id FROM Asset WHERE Asset_Number__c IN: asstNums AND Product2Id IN: productIds];
        for(Asset a : assetList){
            asstNums.remove(a.Asset_Number__c);
        }
        list<PricebookEntry> pbeList = [SELECT Id, Name, Product2Id, UnitPrice, Pricebook2.Country__c, Pricebook2.IsStandard, Product2.Name, Product2.Account_Item_Belongs_To__c, Pricebook2Id FROM PricebookEntry WHERE IsActive = true AND Product2Id IN : productIds];
        System.debug('asset list saved--->'+assetList);
        System.debug('remaining asset numbers--->'+asstNums);
        List<String> assetNumberList = new List<String>();
        assetNumberList.addAll(asstNums);
        List<Asset> asstSave = new List<Asset>();
        if(asstNums.size() != 0 && !cpList.isEmpty()){
            for(Integer k=0;k<assetNumberList.size();k++){
                if(cpList[k].Case__r.AccountId != null && (cpList[k].Case__r.Service_Type__c.containsIgnoreCase('Advance Exchange') || cpList[k].Case__r.Service_Type__c.containsIgnoreCase('Part'))){
                    Asset newAst = new Asset();
                    System.debug('cpList[k]..Product__r.Name::'+cpList[k].Product__r.Name);
                    newAst.Name = cpList[k].Product__r.Name;
                    newAst.Product2Id = cpList[k].Product__c;
                    newAst.AccountId = cpList[k].Case__r.AccountId;
                    newAst.Asset_Number__c = assetNumberList[k];
                    newAst.SerialNumber = assetNumberList[k];
                    asstSave.add(newAst);
                }
            }
            System.debug('remaining asset list aft save Add--->'+asstSave);
            if(asstSave.size() != 0){
                insert asstSave;
                assetList.addAll(asstSave);
            }
        }
        System.debug('remaining asset list aft save Add--->'+assetList);
        for(WorkOrderLineItem woli : woliList){
            for(Asset a : assetList){
                System.debug('a.Product2Id::'+a.Product2Id);
                for(PricebookEntry pbe : pbeList){
                    System.debug('pbe.Product2Id::'+pbe.Product2Id);
                    System.debug('pbe.Id::'+pbe.Id);
                    if(woli.PricebookEntryId == pbe.Id && a.Product2Id == pbe.Product2Id){
                        woli.AssetId = a.Id;
                    }
                }
            }
        }
    }
    
    public static void updateWOLIAddresses(List<WorkOrderLineItem> woliList){
        set<Id> woIds = new set<Id>();
        for(WorkOrderLineItem woli : woliList){
            woIds.add(woli.WorkOrderId);
        }
        List<WorkOrder> woList = [SELECT Id, Account.ShippingStreet, Account.ShippingCity, Account.ShippingState, Account.ShippingCountry,  Account.ShippingPostalCode FROM WorkOrder WHERE ID IN : woIds];
        for(WorkOrderLineItem wol : woliList){
            for(WorkOrder wo : woList){
                if(wol.WorkOrderId != wo.Id) continue;
                wol.City = wo.Account.ShippingCity;
                wol.Country = wo.Account.ShippingCountry;
                wol.PostalCode = wo.Account.ShippingPostalCode;
                wol.Street = wo.Account.ShippingStreet;
                wol.State = wo.Account.ShippingState;
            }
        }
    }*/
}