public class ProductTriggerHandler {
    public static boolean runOnceBeforeUpdate = true;
    public static boolean runOnceAfterUpdate = true;
    public static void handleBeforeInsert(List<Product2> prodList){
        List<Product2> variantsList = new List<Product2>();
        List<Product2> newOriginalProducts = new List<Product2>();
        List<Product2> newRefurbishedDefectiveProducts = new List<Product2>();
        for(Product2 p : prodList){
            p.isActive = true;
            if(String.isBlank(p.Name)) continue;
            if(p.Name.contains('<br>')) p.Name = p.Name.remove('<br>');
            if(p.Family == 'InventoryItem') p.Family = 'Hardware';
            if(p.Reorder_Point__c != null) p.Critical_Quantity__c = p.Reorder_Point__c/2;
            if(p.Base_Price__c == null) p.Base_Price__c = 0;
            if(String.isBlank(p.Source_Key__c)) continue;
            if(!String.isBlank(p.Product_Condition__c) && !p.Product_Condition__c.equalsIgnoreCase('Original')){
                variantsList.add(p);
            } else{
                Boolean isDefective = false;
                if (p.Name.containsIgnoreCase('Defective')) {
                    String regexPattern = '(?i)\\(.*Defective.*\\)';
                    Pattern pattern = Pattern.compile(regexPattern);
                    Matcher matcher = pattern.matcher(p.Name);
                    if (matcher.find() == true) {
                        isDefective = true;
                    }
                }
                if(p.Name.containsIgnoreCase('(New)') || p.Name.containsIgnoreCase('(Refurbished)') || isDefective){
                    newRefurbishedDefectiveProducts.add(p);
                }
            }
             //assign original product
            if(!newRefurbishedDefectiveProducts.isEMpty()){
                ProductTriggerHandler.updateNRDproductsWithOriginalProduct(newRefurbishedDefectiveProducts);
            }
        }
        if(!variantsList.isEMpty()){
            ProductTriggerHandler.populateVariantsWithOriginal(variantsList, null);
        }
    }
    
    public static void handleAfterInsert(List<Product2> prodList){
        List<Product2> activeProducts = new List<Product2>();
        List<Product2> originalProdList = new List<Product2>();
        List<Product2> newOriginalProducts = new List<Product2>();
        Set<Id> prodIds = new Set<Id>();
        for(Product2 p : prodList){
            if(String.isBlank(p.Source_Key__c)) continue;
            if(!String.isBlank(p.Product_Condition__c) && p.Product_Condition__c.equalsIgnoreCase('Original')) {
                originalProdList.add(p);
            } else {
                Boolean isDefective = false;
                if (p.Name.containsIgnoreCase('Defective')) {
                    String regexPattern = '(?i)\\(.*Defective.*\\)';
                    Pattern pattern = Pattern.compile(regexPattern);
                    Matcher matcher = pattern.matcher(p.Name);
                    if (matcher.find() == true) {
                        isDefective = true;
                    }
                }
                if(!p.Name.containsIgnoreCase('(New)') && !p.Name.containsIgnoreCase('(Refurbished)') && !isDefective){
                    newOriginalProducts.add(p);
                }
            }
            if(p.IsActive){
                activeProducts.add(p);
            }
            prodIds.add(p.Id);
        }
        ProductTriggerHandler.createBasePricePBE(prodList);
        if(!activeProducts.isEmpty()) ProductTriggerHandler.createAccountProducts(activeProducts);
        ProductTriggerHandler.syncAccountProducts(prodIds);
        createProductItems(prodList);
        if(!newOriginalProducts.isEmpty()) ProductTriggerHandler.assignOriginalProductToItsVariants(newOriginalProducts);
        if(!originalProdList.isEmpty()) {
            ProductTriggerHandler.populateVariantsWithOriginal(null, originalProdList);
        }
        updateTotalQuantityInOriginalPart(prodList);
    }
    
    public static void handleBeforeUpdate(Map<Id, Product2> newMap, Map<Id, Product2> oldMap){
        List<Product2> variantsList = new List<Product2>();
        List<Product2> newRefurbishedDefectiveProducts = new List<Product2>();
        for(Product2 p : newMap.values()){
            if(p.Name.contains('<br>')) p.Name = p.Name.remove('<br>');
            if(p.Family == 'InventoryItem') p.Family = 'Hardware';
            if(String.isBlank(p.Source_Key__c)) continue;
            if((p.Burn_Rate__c != null && p.Weeks_of_Stock_Needed__c != null) && (p.Burn_Rate__c != oldMap.get(p.Id).Burn_Rate__c || p.Weeks_of_Stock_Needed__c != oldMap.get(p.Id).Weeks_of_Stock_Needed__c)){
                p.Reorder_Point__c = p.Burn_Rate__c * p.Weeks_of_Stock_Needed__c;
            }
            if(p.Reorder_Point__c != null && p.Reorder_Point__c != oldMap.get(p.Id).Reorder_Point__c){
                p.Critical_Quantity__c = p.Reorder_Point__c/2;
            }
            if(p.Product_Condition__c != oldMap.get(p.Id).Product_Condition__c || p.Account_Item_Belongs_To__c != oldMap.get(p.Id).Account_Item_Belongs_To__c || 
                p.Manufacturer_Part_Number__c != oldMap.get(p.Id).Manufacturer_Part_Number__c || p.Name != oldMap.get(p.Id).Name || p.Original_Part__c != oldMap.get(p.Id).Original_Part__c){
                if(!String.isBlank(p.Product_Condition__c) && !p.Product_Condition__c.equalsIgnoreCase('Original')){
                    variantsList.add(p);
                } else {
                    Boolean isDefective = false;
                    if (p.Name.containsIgnoreCase('Defective')) {
                        String regexPattern = '(?i)\\(.*Defective.*\\)';
                        Pattern pattern = Pattern.compile(regexPattern);
                        Matcher matcher = pattern.matcher(p.Name);
                        if (matcher.find() == true) {
                            isDefective = true;
                        }
                    }
                    if(p.Name.containsIgnoreCase('(New)') || p.Name.containsIgnoreCase('(Refurbished)') || isDefective){
                        newRefurbishedDefectiveProducts.add(p);
                    }
                }
            }
        }
        if(!runOnceBeforeUpdate) return;
        //assign original product
        if(!newRefurbishedDefectiveProducts.isEmpty()){
            ProductTriggerHandler.updateNRDproductsWithOriginalProduct(newRefurbishedDefectiveProducts);
        }
        if(!variantsList.isEmpty()){
            ProductTriggerHandler.populateVariantsWithOriginal(variantsList, null);
        }
        ProductTriggerHandler.updateInventoryNotificationEmail(newMap, oldMap);
        runOnceBeforeUpdate = false;
    }
    
    public static void handleAfterUpdate(Map<Id, Product2> newMap, Map<Id, Product2> oldMap){
        List<Product2> inActiveProducts = new List<Product2>();
        List<Product2> activeProducts = new List<Product2>();
        List<Product2> originalProdList = new List<Product2>();
        List<Product2> newOriginalProducts = new List<Product2>();
        Set<Id> prodIds = new Set<Id>();
        for(Product2 p : newMap.values()){
            if(String.isBlank(p.Source_Key__c)) continue;
            if(p.Product_Condition__c != oldMap.get(p.Id).Product_Condition__c || p.Account_Item_Belongs_To__c != oldMap.get(p.Id).Account_Item_Belongs_To__c || 
                p.Manufacturer_Part_Number__c != oldMap.get(p.Id).Manufacturer_Part_Number__c || p.Name != oldMap.get(p.Id).Name || p.Original_Part__c != oldMap.get(p.Id).Original_Part__c){
                if(!String.isBlank(p.Product_Condition__c) && p.Product_Condition__c.equalsIgnoreCase('Original')) {
                    originalProdList.add(p);
                } else {
                    Boolean isDefective = false;
                    if (p.Name.containsIgnoreCase('Defective')) {
                        String regexPattern = '(?i)\\(.*Defective.*\\)';
                        Pattern pattern = Pattern.compile(regexPattern);
                        Matcher matcher = pattern.matcher(p.Name);
                        if (matcher.find() == true) {
                            isDefective = true;
                        }
                    }
                    if(!p.Name.containsIgnoreCase('(New)') && !p.Name.containsIgnoreCase('(Refurbished)') && !isDefective){
                        newOriginalProducts.add(p);
                    }
                }
            }
            if(!p.IsActive && (p.IsActive != oldMap.get(p.Id).IsActive)){
                inActiveProducts.add(p);
            }
            if(p.IsActive && (p.IsActive != oldMap.get(p.Id).IsActive)){
                activeProducts.add(p);
            }
            if((p.Name != oldMap.get(p.Id).Name || p.Account_Item_Belongs_To__c != oldMap.get(p.Id).Account_Item_Belongs_To__c)){
                prodIds.add(p.Id);
            }
        }
        if(!runOnceAfterUpdate) return;
        createAccountProducts(activeProducts);
        syncAccountProducts(prodIds);
        createProductItems(newMap.values());
        if(!originalProdList.isEmpty()) {
            ProductTriggerHandler.populateVariantsWithOriginal(null, originalProdList);
        }
        if(!newOriginalProducts.isEmpty()) ProductTriggerHandler.assignOriginalProductToItsVariants(newOriginalProducts);
        updateTotalQuantityInOriginalPart(newMap.values());
        if(inActiveProducts.size() != 0){
            ProductTriggerHandler.deleteAccountProduct(inActiveProducts);
            ProductTriggerHandler.onDeleteProductQuantityInOriginalPart(inActiveProducts);
        }
        updateBasePricePBE(newMap, oldMap);
        runOnceAfterUpdate = false;
    }

    public static void handleBeforeDelete(List<Product2> productList){
        ProductTriggerHandler.deleteAccountProduct(productList);
        // to reset Quantity in original part after deletion
        ProductTriggerHandler.onDeleteProductQuantityInOriginalPart(productList);
    }
    
    public static void createBasePricePBE(List<Product2> prodList){
        System.debug('prodList size-> ' + prodList.size());
        List<PricebookEntry> pbeList = new List<PricebookEntry>();
        List<Pricebook2> pb2List = [SELECT Id, Name, IsActive FROM PriceBook2 WHERE IsStandard=True LIMIT 1];
        System.debug('pb2List size-> ' + pb2List.size());
        List<Pricebook2> canadaPB = [SELECT Id, Name, IsActive FROM PriceBook2 WHERE Country__c = 'Canada' LIMIT 1];
        for(Product2 pd : prodList){
            if(String.isBlank(pd.Source_Key__c)) continue;
            if(pd.Base_Price__c != null) {
                PricebookEntry pbe = new PricebookEntry();
                if(pb2List.isEmpty()) continue;
                pbe.Pricebook2Id = pb2List[0].Id;
                pbe.Product2Id = pd.Id;
                pbe.UnitPrice = pd.Base_Price__c;
                pbe.IsActive = true;
                pbeList.add(pbe);
            }
            if(pd.Base_Price__c != null && pd.ProductCode != null) {
                PricebookEntry pbe = new PricebookEntry();
                if(canadaPB.isEmpty()) continue;
                pbe.Pricebook2Id = canadaPB[0].Id;
                pbe.Product2Id = pd.Id;
                if(pd.Family == 'Service') {
                    pbe.UnitPrice = pd.Base_Price__c * 1.2;
                } else {
                    pbe.UnitPrice = 0;
                }
                pbe.IsActive = true;
                pbeList.add(pbe);
            }
        }
        if(!pbeList.isEmpty()){
            insert pbeList;
        }
    }

    public static void syncAccountProducts(Set<Id> prodIds){
        // Keeping in sync :product Name and Account_Item_Belongs_To__c with related Account_Product__c records.
        if(!prodIds.isEmpty()){
            List<Account_Product__c> accProdList = [SELECT Id,Name,Account__c,Product__c,Product__r.Name,Product__r.Account_Item_Belongs_To__c
                                                    FROM Account_Product__c WHERE Product__c IN: prodIds];
            List<Account_Product__c> accProdsUpdateList = new List<Account_Product__c>();
            for(Account_Product__c ap : accProdList){
                ap.Account__c = ap.Product__r.Account_Item_Belongs_To__c;
                if(ap.Product__r.Name.length() > 80){
                    ap.Name = ap.Product__r.Name.substring(0,79);
                } else {
                    ap.Name = ap.Product__r.Name;
                }
                accProdsUpdateList.add(ap);
            }
            if(!accProdsUpdateList.isEmpty()){
                update accProdsUpdateList;
            }
        }
    }

    public static void updateBasePricePBE(Map<Id, Product2> newMap, Map<Id, Product2> oldMap){
        List<PricebookEntry> pbeList = [SELECT Id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2Id IN: newMap.keyset()];
        List<Pricebook2> pb2List = [SELECT Id, Name, IsActive FROM PriceBook2 WHERE IsActive = true AND IsStandard = true LIMIT 1];
        List<Pricebook2> canadaPB = [SELECT Id, Name, IsActive FROM PriceBook2 WHERE IsActive = true AND Country__c = 'Canada' LIMIT 1];
        Set<Id> productIdsInPBE = new Set<Id>();
        List<PricebookEntry> toInsertList = new List<PricebookEntry>();
        for(PricebookEntry pbe : pbeList){
            productIdsInPBE.add(pbe.Product2Id);
        }
        Boolean toUpdate = false;
        for(Product2 pd : newMap.values()){
            if(String.isBlank(pd.Source_Key__c)) continue;
            for(PricebookEntry pbe : pbeList){
                if(pd.Id != pbe.Product2Id) continue;
                if(pd.Base_Price__c != null) {
                    if(pbe.UnitPrice == pd.Base_Price__c) break;
                    pbe.UnitPrice = pd.Base_Price__c;
                    toUpdate = true;
                } else if(pd.Base_Price__c == null && pbe.UnitPrice != 0) {
                    pbe.UnitPrice = 0;
                    toUpdate = true;
                }
            }
            System.debug('productIdsInPBE-> ' + productIdsInPBE);
            System.debug('pd.Id-> ' + pd.Id);
            System.debug('!productIdsInPBE.contains(pd.Id)-> ' + (!productIdsInPBE.contains(pd.Id)));
            System.debug('pd.Base_Price__c-> ' + pd.Base_Price__c);
            System.debug('pd.name-> ' + pd.name);
            if(!productIdsInPBE.contains(pd.Id) && pd.Base_Price__c != null){
                PricebookEntry pbe = new PricebookEntry();
                if(pb2List.isEmpty()) continue;
                pbe.Pricebook2Id = pb2List[0].Id;
                pbe.Product2Id = pd.Id;
                pbe.UnitPrice = pd.Base_Price__c;
                pbe.IsActive = true;
                toInsertList.add(pbe);

                if(pd.ProductCode != null) {
                    pbe = new PricebookEntry();
                    pbe.Pricebook2Id = canadaPB[0].Id;
                    pbe.Product2Id = pd.Id;
                    if(pd.Family == 'Service') {
                        pbe.UnitPrice = pd.Base_Price__c * 1.2;
                    } else {
                        pbe.UnitPrice = 0;
                    }
                    pbe.IsActive = true;
                    toInsertList.add(pbe);
                }
            }
        }
        if(toUpdate){
            runOnceBeforeUpdate = false;
            runOnceAfterUpdate = false;
            update pbeList;
        }
        if(!toInsertList.isEmpty()){
            insert toInsertList;
        }
    }

    public static void populateVariantsWithOriginal(List<Product2> variantsList, List<Product2> originalProdList){
        if(variantsList != null) {
            //When Child product is updated assign original product
            List<Product2> orgProductsList = new List<Product2>();
            List<Product2> variantsList2 = new List<Product2>();
            Set<String> mpnSet = new Set<String>();
            Set<String> acctIdSet = new Set<String>();
            for(Product2 prod : variantsList){
                mpnSet.add(prod.Manufacturer_Part_Number__c);
                acctIdSet.add(prod.Account_Item_Belongs_To__c);
                System.debug('Main Product product condition->'+prod.Main_Product_Product_Condition__c);
                if(prod.Product_Condition__c != null && prod.Main_Product_Product_Condition__c == null) {
                    variantsList2.add(prod);
                }
            }
            List<Product2> origProdList =  [SELECT Id, Name, Account_Item_Belongs_To__c, Original_Part__c, Source_Key__c, Manufacturer_Part_Number__c 
                                            FROM Product2 WHERE Source_Key__c != null AND isActive = true AND Product_Condition__c = 'Original' AND Manufacturer_Part_Number__c != null
                                            AND Manufacturer_Part_Number__c IN: mpnSet AND Account_Item_Belongs_To__c IN: acctIdSet
                                            ];
            for(Product2 prod : variantsList){
                for(Product2 origProd : origProdList){
                    if(prod.Id == origProd.Id) continue;
                    if((origProd.Manufacturer_Part_Number__c != prod.Manufacturer_Part_Number__c) || (origProd.Account_Item_Belongs_To__c != prod.Account_Item_Belongs_To__c)) continue;
                    prod.Original_Part__c = origProd.Id;
                    break;
                }
            }
            if(!variantsList2.isEmpty()) {
                updateNRDproductsWithOriginalProduct(variantsList2);
            }
        }
        if(originalProdList != null) {
             //When original product is updated assign it to its variants.
            List<Product2> childProductsToUpdate = new List<Product2>();
            Set<String> mpnSet = new Set<String>();
            Set<String> acctIdSet = new Set<String>();
            for(Product2 prod : originalProdList){
                mpnSet.add(prod.Manufacturer_Part_Number__c);
                acctIdSet.add(prod.Account_Item_Belongs_To__c);
            }
            List<Product2> variantList =   [SELECT Id, Name, Account_Item_Belongs_To__c,Original_Part__c, Source_Key__c, Manufacturer_Part_Number__c  
                                            FROM Product2 WHERE Source_Key__c != null AND isActive = true AND Product_Condition__c != 'Original' 
                                            AND Manufacturer_Part_Number__c IN: mpnSet AND Account_Item_Belongs_To__c IN: acctIdSet AND Manufacturer_Part_Number__c != null
                                            ];
            for(Product2 origProd : originalProdList){
                for(Product2 prod : variantList){
                    if(prod.Id == origProd.Id) continue;
                    if((origProd.Manufacturer_Part_Number__c != prod.Manufacturer_Part_Number__c) || (origProd.Account_Item_Belongs_To__c != prod.Account_Item_Belongs_To__c)) continue;
                    if(prod.Original_Part__c == origProd.Id) continue;
                    prod.Original_Part__c = origProd.Id;
                    childProductsToUpdate.add(prod);
                }
            }
            if(!childProductsToUpdate.isEmpty()) {
                runOnceBeforeUpdate = false;
                runOnceAfterUpdate = false;
                update childProductsToUpdate;
            }
        }
    }

    //When original product is updated assign it to its variants.
    public static void assignOriginalProductToItsVariants(List<Product2> originalProductsList){
        Set<String> productNames = new Set<String>();
        for(Product2 prod : originalProductsList){
            if(String.isBlank(prod.Source_Key__c)) continue;
            for (Integer i = 0; i <= prod.Name.length(); i++) {
                String variation1 = prod.Name.substring(0, i) + ' (New) ' + prod.Name.substring(i);
                variation1 = variation1.replaceAll('\\s+', ' ').trim();
                productNames.add(variation1);

                String variation2 = prod.Name.substring(0, i) + ' (Refurbished) ' + prod.Name.substring(i);
                variation2 = variation2.replaceAll('\\s+', ' ').trim();
                productNames.add(variation2);
            }
        }
        List<Product2> variantsList = [SELECT Id, Name, Account_Item_Belongs_To__c,Original_Part__c,Original_Part__r.Original_Part__c, Source_Key__c  
                                       FROM Product2 WHERE Source_Key__c != null AND isActive = true AND (Name IN : productNames OR Name LIKE '%(%Defective%)%')];
        System.debug('variantsList size-> ' + variantsList.size());
        Map<Id,Product2> childProductsToUpdate = new Map<Id,Product2>();
        for(Product2 orgProd : originalProductsList){
            if(String.isBlank(orgProd.Source_Key__c)) continue;
            for(Product2 varProd : variantsList){
                if(varProd.Id == orgProd.Id) continue;
                System.debug('varProd Name-> ' + varProd.Name);
                String plainProdName = varProd.Name.replace('(New)','').replace('(Refurbished)','');
                plainProdName = plainProdName.replaceAll('\\([^()]*Defective[^()]*\\)', '').trim();
                plainProdName = plainProdName.replace('  ',' ').trim();
                if(plainProdName == orgProd.Name && varProd.Account_Item_Belongs_To__c == orgProd.Account_Item_Belongs_To__c && varProd.Original_Part__c != orgProd.Id){
                    varProd.Original_Part__c = orgProd.Id;
                    childProductsToUpdate.put(varProd.Id,varProd);
                }
            }
        }
        System.debug('childProductsToUpdate-> ' + childProductsToUpdate);
        if(!childProductsToUpdate.isEmpty()){
            runOnceBeforeUpdate = false;
            runOnceAfterUpdate = false;
            update childProductsToUpdate.values();
        }
    }

    //When Child product is updated assign original product
    public static void updateNRDproductsWithOriginalProduct(List<Product2> productsList){
        Set<String> productNames = new Set<String>();
        for(Product2 prod : productsList){
            if(String.isBlank(prod.Source_Key__c)) continue;
            String plainProdName = prod.Name.replace('(New)','').replace('(Refurbished)','');
            plainProdName = plainProdName.replaceAll('\\([^()]*Defective[^()]*\\)', '').trim();
            System.debug('plainProdName 1-> ' + plainProdName);
            plainProdName = plainProdName.replace('  ',' ').trim();
            productNames.add(plainProdName);
        }
        System.debug('productNames-> ' + JSON.serialize(productNames));
        List<Product2> originalProductList = [SELECT Id, Name, Account_Item_Belongs_To__c,Original_Part__c,Source_Key__c,
                                              (SELECT Id, Name, Account_Item_Belongs_To__c,Original_Part__c,Source_Key__c FROM Products__r WHERE Source_Key__c != null) 
                                              FROM Product2 WHERE Source_Key__c != null AND isActive = true AND Name IN : productNames];                  
        for(Product2 prod : productsList){
            if(String.isBlank(prod.Source_Key__c)) continue;
            String plainProdName = prod.Name.replace('(New)','').replace('(Refurbished)','');
            plainProdName = plainProdName.replaceAll('\\([^()]*Defective[^()]*\\)', '').trim();
            plainProdName = plainProdName.replace('  ',' ').trim();
            if(!originalProductList.isEmpty()){
                for(Product2 originalProd : originalProductList){
                    if(originalProd.Id == prod.Id) break;
                    if(plainProdName == originalProd.Name && prod.Account_Item_Belongs_To__c == originalProd.Account_Item_Belongs_To__c){
                        prod.Original_Part__c = originalProd.Id;
                    }
                }
            } else {
                prod.Original_Part__c = null;
            }
        }
    }

    public static void createProductItems(List<Product2> prodList){
        Map<Id,Product2> prodMap = new Map<Id,Product2>(prodList);
        List<Product2> prodList2 = [SELECT Id,Quantity_Available__c,IsActive, Source_Key__c, (SELECT Id FROM ProductItems) 
                                    FROM Product2 WHERE Account_Item_Belongs_To__r.Name = 'IW Technologies - EST Field Support' AND
                                    IsActive = true AND Family = 'Hardware' AND Source_Key__c != null AND 
                                    Id IN:prodMap.keySet() AND Id NOT IN (SELECT Product2Id FROM ProductItem)];
        List<ProductItem> piList = new List<ProductItem>();
        List<Schema.Location> locList = [SELECT Id,Name FROM Location WHERE Name LIKE 'IWCR%' AND LocationType = 'Warehouse' LIMIT 1];
        if(!locList.isEmpty() && !prodList2.isEmpty()){
            for(Product2 prod : prodList2){
                ProductItem pi = new ProductItem();
                pi.LocationId = locList[0].Id;
                pi.Product2Id = prod.Id;
                pi.QuantityOnHand = 100;
                pi.Minimum_Quantity__c = 100;
                pi.QuantityUnitOfMeasure = 'Each';
                piList.add(pi);
            }
            if(!piList.isEmpty()){
                insert piList;
            }
        }
    }


    //Populate Total Quantity fields in original product.
    public static void updateTotalQuantityInOriginalPart(List<Product2> prodList){
        Set<Id> origProdIds = new Set<Id>();
        for(Product2 origProd : prodList){
            if(origProd.Original_Part__c == null && origProd.IsActive == true) origProdIds.add(origProd.Id);
            if(origProd.Original_Part__c != null && origProd.IsActive == true) origProdIds.add(origProd.Original_Part__c);
        }
        System.debug('origProdIds size-> ' + origProdIds.size());
        if(!origProdIds.isEmpty()){
            List<Product2> origProdList = [SELECT Id, Name, ProductCode, Product_Condition__c, Burn_Rate__c, X12_Weeks_Order_History__c, Tested_Defective_QA__c,
                                           Tested_Defective_QOH__c,NS_Quantity_Available__c, NS_Quantity_On_Hand__c, Quantity_Available__c, 
                                           Quantity_on_Hand__c, Defective_Quantity_Available__c, Defective_Quantity_on_Hand__c, Source_Key__c,
                                           (SELECT Id, Quantity__c FROM Sales_Order_Lines__r WHERE CreatedDate = LAST_N_DAYS:84 
                                           AND Sales_Order__r.Case__r.ServiceContract.Include_In_Burn_Rate_Calculation__c = true) FROM Product2 
                                           WHERE IsActive = true AND Source_Key__c != null AND Id IN:origProdIds ORDER BY LastModifiedDate DESC];
            List<Product2> childProdList = [SELECT Id, Name, ProductCode, Product_Condition__c, Burn_Rate__c, X12_Weeks_Order_History__c, Original_Part__c,NS_Quantity_Available__c, 
                                            NS_Quantity_On_Hand__c,Quantity_Available__c,Quantity_on_Hand__c,Source_Key__c,
                                            (SELECT Id, Quantity__c FROM Sales_Order_Lines__r WHERE CreatedDate = LAST_N_DAYS:84 
                                            AND Sales_Order__r.Case__r.ServiceContract.Include_In_Burn_Rate_Calculation__c = true) FROM Product2 
                                            WHERE IsActive = true AND Source_Key__c != null AND Original_Part__c IN: origProdIds ORDER BY LastModifiedDate DESC];
            Map<Id,Product2> origPlusChildMap = new Map<Id,Product2>();
            for(Product2 origProd : origProdList){
                Decimal orderHistory = 0;
                Decimal childOrderHistory = 0;
                System.debug('origProd.Sales_Order_Lines__r'+JSON.serialize(origProd.Sales_Order_Lines__r));
                for(Sales_Order_Line__c soli : origProd.Sales_Order_Lines__r){
                    if(soli.Quantity__c != null) orderHistory += soli.Quantity__c;
                }
                
                Decimal totalNSQunatityAvailable = (origProd.NS_Quantity_Available__c != null) ? origProd.NS_Quantity_Available__c : 0;
                Decimal totalNSQunatityOnHand = (origProd.NS_Quantity_On_Hand__c != null) ? origProd.NS_Quantity_On_Hand__c : 0;
                Decimal totalDefectiveQtyAvailable = 0;
                Decimal totalDefectiveQtyOnHand = 0;
                Decimal totalTestedDefectiveQA = 0;
                Decimal totalTestedDefectiveQOH = 0;

                for(product2 childPd : childProdList){
                    if(childPd.Original_Part__c != origProd.Id) continue;
                    for(Sales_Order_Line__c soli : childPd.Sales_Order_Lines__r){
                        if(soli.Quantity__c != null) {
                            orderHistory += soli.Quantity__c;
                            childOrderHistory += soli.Quantity__c;
                        }
                    }
                    Decimal childBurnRate = (childOrderHistory / 12).setScale(2, RoundingMode.CEILING);
                    if(childPd.X12_Weeks_Order_History__c != childOrderHistory || childPd.Burn_Rate__c != childBurnRate) {
                        childPd.X12_Weeks_Order_History__c = childOrderHistory;
                        childPd.Burn_Rate__c = childBurnRate;
                        origPlusChildMap.put(childPd.Id,childPd);
                    }
                    
                    if(!String.isBlank(childPd.Product_Condition__c)) {
                        if(!String.isBlank(childPd.Product_Condition__c) && childPd.Product_Condition__c.containsIgnoreCase('Tested Defective')){
                            if(childPd.Quantity_Available__c != null) totalTestedDefectiveQA += childPd.Quantity_Available__c;
                            if(childPd.Quantity_on_Hand__c != null) totalTestedDefectiveQOH += childPd.Quantity_on_Hand__c;
                        } else if(!String.isBlank(childPd.Product_Condition__c) && childPd.Product_Condition__c.equalsIgnoreCase('Defective')){
                            if(childPd.Quantity_Available__c != null) totalDefectiveQtyAvailable += childPd.Quantity_Available__c;
                            if(childPd.Quantity_on_Hand__c != null) totalDefectiveQtyOnHand += childPd.Quantity_on_Hand__c;
                        } else {
                            if(childPd.NS_Quantity_Available__c != null) totalNSQunatityAvailable += childPd.NS_Quantity_Available__c;
                            if(childPd.NS_Quantity_On_Hand__c != null) totalNSQunatityOnHand += childPd.NS_Quantity_On_Hand__c;
                        }
                    } else {
                        Boolean isTestedDefective = false;
                        if (childPd.Name.containsIgnoreCase('Tested Defective')) {
                            String regexPattern = '(?i)\\(.*Tested Defective.*\\)';
                            Pattern pattern = Pattern.compile(regexPattern);
                            Matcher matcher = pattern.matcher(childPd.Name);
                            if (matcher.find() == true) {
                                isTestedDefective = true;
                            }
                        }
                        Boolean isDefective = false;
                        if (childPd.Name.containsIgnoreCase('Defective')) {
                            String regexPattern = '(?i)\\(.*Defective.*\\)';
                            Pattern pattern = Pattern.compile(regexPattern);
                            Matcher matcher = pattern.matcher(childPd.Name);
                            if (matcher.find() == true) {
                                isDefective = true;
                            }
                        }
                        if(isTestedDefective){
                            if(childPd.Quantity_Available__c != null) totalTestedDefectiveQA += childPd.Quantity_Available__c;
                            if(childPd.Quantity_on_Hand__c != null) totalTestedDefectiveQOH += childPd.Quantity_on_Hand__c;
                        } else if(isDefective){
                            if(childPd.Quantity_Available__c != null) totalDefectiveQtyAvailable += childPd.Quantity_Available__c;
                            if(childPd.Quantity_on_Hand__c != null) totalDefectiveQtyOnHand += childPd.Quantity_on_Hand__c;
                        } else {
                            if(childPd.NS_Quantity_Available__c != null) totalNSQunatityAvailable += childPd.NS_Quantity_Available__c;
                            if(childPd.NS_Quantity_On_Hand__c != null) totalNSQunatityOnHand += childPd.NS_Quantity_On_Hand__c;
                        }
                    }
                }
                System.debug('totalNSQunatityAvailable-> ' + totalNSQunatityAvailable);
                System.debug('totalNSQunatityOnHand-> ' + totalNSQunatityOnHand);
                System.debug('totalDefectiveQtyAvailable-> ' + totalDefectiveQtyAvailable);
                System.debug('totalDefectiveQtyOnHand-> ' + totalDefectiveQtyOnHand);
                System.debug('totalTestedDefectiveQA-> ' + totalTestedDefectiveQA);
                System.debug('totalTestedDefectiveQOH-> ' + totalTestedDefectiveQOH);
                System.debug('12 week orderHistory-> ' + orderHistory);
                System.debug('childOrderHistory-> ' + childOrderHistory);

                if(totalNSQunatityAvailable != origProd.Quantity_Available__c) origProd.Quantity_Available__c = totalNSQunatityAvailable;
                if(totalNSQunatityOnHand != origProd.Quantity_on_Hand__c) origProd.Quantity_on_Hand__c = totalNSQunatityOnHand;
                if(totalDefectiveQtyAvailable != origProd.Defective_Quantity_Available__c) origProd.Defective_Quantity_Available__c = totalDefectiveQtyAvailable;
                if(totalDefectiveQtyOnHand != origProd.Defective_Quantity_on_Hand__c) origProd.Defective_Quantity_on_Hand__c = totalDefectiveQtyOnHand;
                if(totalTestedDefectiveQA != origProd.Tested_Defective_QA__c) origProd.Tested_Defective_QA__c = totalTestedDefectiveQA;
                if(totalTestedDefectiveQOH != origProd.Tested_Defective_QOH__c) origProd.Tested_Defective_QOH__c = totalTestedDefectiveQOH;
                
                origProd.X12_Weeks_Order_History__c = integer.valueOf(orderHistory);
                origProd.Burn_Rate__c = (orderHistory / 12).setScale(2, RoundingMode.CEILING);
                origPlusChildMap.put(origProd.Id,origProd);
            }
            if(!origPlusChildMap.isEmpty()){
                runOnceBeforeUpdate = false;
                runOnceAfterUpdate = false;
                update origPlusChildMap.values();
            }
        }
    }

    //on delete quantity update in original part
    public static void onDeleteProductQuantityInOriginalPart(List<Product2> productList){
        Set<Id> originalPartIds = new Set<Id>();
        for(Product2 childPd : productList){
            if(String.isBlank(childPd.Source_Key__c)) continue;
            if(childPd.Original_Part__c != null){
                originalPartIds.add(childPd.Original_Part__c);
            }
        }
        list<Product2> origProdList = [SELECT Id,Tested_Defective_QA__c,Tested_Defective_QOH__c, Defective_Quantity_Available__c, 
                                   Defective_Quantity_on_Hand__c,Quantity_Available__c, Quantity_on_Hand__c, Source_Key__c  
                                   FROM Product2 WHERE Source_Key__c != null AND Id IN : originalPartIds];
        for(Product2 origProd : origProdList){
            for(Product2 childPd : productList){
                if(origProd.Id != childPd.Original_Part__c || String.isBlank(childPd.Source_Key__c)) continue;
                
                if(!String.isBlank(childPd.Product_Condition__c)) {
                    if(!String.isBlank(childPd.Product_Condition__c) && childPd.Product_Condition__c.containsIgnoreCase('Tested Defective')){
                        origProd.Tested_Defective_QA__c = (origProd.Tested_Defective_QA__c != null) ? origProd.Tested_Defective_QA__c : 0;
                        origProd.Tested_Defective_QOH__c = (origProd.Tested_Defective_QOH__c != null) ? origProd.Tested_Defective_QOH__c : 0;
                        decimal Quantity_Available = (childPd.Quantity_Available__c != null) ? childPd.Quantity_Available__c : 0;
                        decimal Quantity_OnHand = (childPd.Quantity_on_Hand__c != null) ? childPd.Quantity_on_Hand__c : 0;
                        origProd.Tested_Defective_QA__c = origProd.Tested_Defective_QA__c - Quantity_Available;
                        if(origProd.Tested_Defective_QA__c < 0){
                            origProd.Tested_Defective_QA__c = 0;
                        }
                        origProd.Tested_Defective_QOH__c = origProd.Tested_Defective_QOH__c - Quantity_OnHand;
                        if(origProd.Tested_Defective_QOH__c < 0){
                            origProd.Tested_Defective_QOH__c = 0;
                        }
                    } else if(!String.isBlank(childPd.Product_Condition__c) && childPd.Product_Condition__c.equalsIgnoreCase('Defective')){
                        origProd.Defective_Quantity_Available__c = (origProd.Defective_Quantity_Available__c != null) ? origProd.Defective_Quantity_Available__c : 0;
                        origProd.Defective_Quantity_on_Hand__c = (origProd.Defective_Quantity_on_Hand__c != null) ? origProd.Defective_Quantity_on_Hand__c : 0;
                        decimal Quantity_Available = (childPd.Quantity_Available__c != null) ? childPd.Quantity_Available__c : 0;
                        decimal Quantity_OnHand = (childPd.Quantity_on_Hand__c != null) ? childPd.Quantity_on_Hand__c : 0;
                        origProd.Defective_Quantity_Available__c = origProd.Defective_Quantity_Available__c - Quantity_Available;
                        if(origProd.Defective_Quantity_Available__c < 0){
                            origProd.Defective_Quantity_Available__c = 0;
                        }
                        origProd.Defective_Quantity_on_Hand__c = origProd.Defective_Quantity_on_Hand__c - Quantity_OnHand;
                        if(origProd.Defective_Quantity_on_Hand__c < 0){
                            origProd.Defective_Quantity_on_Hand__c = 0;
                        }
                    } else {
                        origProd.Quantity_Available__c = (origProd.Quantity_Available__c != null) ? origProd.Quantity_Available__c : 0;
                        origProd.Quantity_on_Hand__c = (origProd.Quantity_on_Hand__c != null) ? origProd.Quantity_on_Hand__c : 0;
                        decimal Quantity_Available = (childPd.NS_Quantity_Available__c != null) ? childPd.NS_Quantity_Available__c : 0;
                        decimal Quantity_OnHand = (childPd.NS_Quantity_On_Hand__c != null) ? childPd.NS_Quantity_On_Hand__c : 0;
                        origProd.Quantity_Available__c = origProd.Quantity_Available__c - Quantity_Available;
                        if(origProd.Quantity_Available__c < 0){
                            origProd.Quantity_Available__c = 0;
                        }
                        origProd.Quantity_on_Hand__c = origProd.Quantity_on_Hand__c - Quantity_OnHand;
                        if(origProd.Quantity_on_Hand__c < 0){
                            origProd.Quantity_on_Hand__c = 0;
                        }
                    }
                } else {
                    Boolean isTestedDefective = false;
                    if (childPd.Name.containsIgnoreCase('Tested Defective')) {
                        String regexPattern = '(?i)\\(.*Tested Defective.*\\)';
                        Pattern pattern = Pattern.compile(regexPattern);
                        Matcher matcher = pattern.matcher(childPd.Name);
                        if (matcher.find() == true) {
                            isTestedDefective = true;
                        }
                    }
                    Boolean isDefective = false;
                    if (childPd.Name.containsIgnoreCase('Defective')) {
                        String regexPattern = '(?i)\\(.*Defective.*\\)';
                        Pattern pattern = Pattern.compile(regexPattern);
                        Matcher matcher = pattern.matcher(childPd.Name);
                        if (matcher.find() == true) {
                            isDefective = true;
                        }
                    }
                    if(isTestedDefective){
                        origProd.Tested_Defective_QA__c = (origProd.Tested_Defective_QA__c != null) ? origProd.Tested_Defective_QA__c : 0;
                        origProd.Tested_Defective_QOH__c = (origProd.Tested_Defective_QOH__c != null) ? origProd.Tested_Defective_QOH__c : 0;
                        decimal Quantity_Available = (childPd.Quantity_Available__c != null) ? childPd.Quantity_Available__c : 0;
                        decimal Quantity_OnHand = (childPd.Quantity_on_Hand__c != null) ? childPd.Quantity_on_Hand__c : 0;
                        origProd.Tested_Defective_QA__c = origProd.Tested_Defective_QA__c - Quantity_Available;
                        if(origProd.Tested_Defective_QA__c < 0){
                            origProd.Tested_Defective_QA__c = 0;
                        }
                        origProd.Tested_Defective_QOH__c = origProd.Tested_Defective_QOH__c - Quantity_OnHand;
                        if(origProd.Tested_Defective_QOH__c < 0){
                            origProd.Tested_Defective_QOH__c = 0;
                        }
                    } else if(isDefective){
                        origProd.Defective_Quantity_Available__c = (origProd.Defective_Quantity_Available__c != null) ? origProd.Defective_Quantity_Available__c : 0;
                        origProd.Defective_Quantity_on_Hand__c = (origProd.Defective_Quantity_on_Hand__c != null) ? origProd.Defective_Quantity_on_Hand__c : 0;
                        decimal Quantity_Available = (childPd.Quantity_Available__c != null) ? childPd.Quantity_Available__c : 0;
                        decimal Quantity_OnHand = (childPd.Quantity_on_Hand__c != null) ? childPd.Quantity_on_Hand__c : 0;
                        origProd.Defective_Quantity_Available__c = origProd.Defective_Quantity_Available__c - Quantity_Available;
                        if(origProd.Defective_Quantity_Available__c < 0){
                            origProd.Defective_Quantity_Available__c = 0;
                        }
                        origProd.Defective_Quantity_on_Hand__c = origProd.Defective_Quantity_on_Hand__c - Quantity_OnHand;
                        if(origProd.Defective_Quantity_on_Hand__c < 0){
                            origProd.Defective_Quantity_on_Hand__c = 0;
                        }
                    } else {
                        origProd.Quantity_Available__c = (origProd.Quantity_Available__c != null) ? origProd.Quantity_Available__c : 0;
                        origProd.Quantity_on_Hand__c = (origProd.Quantity_on_Hand__c != null) ? origProd.Quantity_on_Hand__c : 0;
                        decimal Quantity_Available = (childPd.NS_Quantity_Available__c != null) ? childPd.NS_Quantity_Available__c : 0;
                        decimal Quantity_OnHand = (childPd.NS_Quantity_On_Hand__c != null) ? childPd.NS_Quantity_On_Hand__c : 0;
                        origProd.Quantity_Available__c = origProd.Quantity_Available__c - Quantity_Available;
                        if(origProd.Quantity_Available__c < 0){
                            origProd.Quantity_Available__c = 0;
                        }
                        origProd.Quantity_on_Hand__c = origProd.Quantity_on_Hand__c - Quantity_OnHand;
                        if(origProd.Quantity_on_Hand__c < 0){
                            origProd.Quantity_on_Hand__c = 0;
                        }
                    }
                }
            }
        }
        runOnceBeforeUpdate = false;
        runOnceAfterUpdate = false;
        update origProdList;
    }
    
    //create account products
    public static void createAccountProducts(List<Product2> prodList){
        Set<Id> prodIds = new Set<Id>();
        for(Product2 p : prodList){
            if(String.isBlank(p.Source_Key__c)) continue;
            prodIds.add(p.Id);
        }
        List<Product2> prodListChildCheck = [SELECT Id, Name,Family, Account_Item_Belongs_To__c, Source_Key__c, (SELECT Id FROM Account_Products__r) 
                                             FROM Product2 WHERE Source_Key__c != null AND IsActive = true AND Id IN : prodIds AND Family = 'Hardware'];
        List<Account_Product__c> apList = new List<Account_Product__c>();
        for(Product2 pd : prodListChildCheck){
            if(pd.Account_Products__r.size() != 0) continue;
            Account_Product__c ap = new Account_Product__c();
            if(pd.Name.length() <= 80){
                ap.Name = pd.Name;
            }else{
                ap.Name = pd.Name.substring(0,79);
            }
            ap.Account__c = pd.Account_Item_Belongs_To__c;
            ap.Product__c = pd.Id;
            apList.add(ap);
        }
        if(apList.size() != 0){
            insert apList;
        }
    }
    
    public static void updateInventoryNotificationEmail(Map<Id, Product2> newMap, Map<Id, Product2> oldMap){
        for(Product2 p : newMap.Values()){
                if(p.Quantity_Available__c > p.Reorder_Point__c){
                    p.Inventory_Email_Sent__c = false;
                }
                if(p.Quantity_Available__c > p.Critical_Quantity__c){
                    p.Critical_Email_Sent__c = false;
                    System.debug('p.Critical_Email_Sent__c:'+p.Critical_Email_Sent__c);
                }
        }
    }
    
    public static void deleteAccountProduct(List<Product2> productList){
        Set<Id> prodIds = new Set<Id>();
        for(Product2 pd : productList){
            prodIds.add(pd.Id);
        }
        System.debug('prodIdss:'+prodIds);
        List<Account_Product__c> accProducts = [SELECT Id FROM Account_Product__c WHERE Product__c IN : prodIds];
        if(prodIds.size() != 0){
            delete accProducts;
        }
    }
}