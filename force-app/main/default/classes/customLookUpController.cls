public without sharing class customLookUpController {
    @AuraEnabled
    public static List < sObject > fetchLookUpValues(String searchKeyWord, String objectAPIName, String rootAccountId, String hwRootAccountId, Integer recordLimit) {
        //If Main product exist then display only Main product.
        //If Main product doesn't exist/not active then display (New) only.
        //If Main product and (New ) both doesn't exist/not active then display (Refurbished) only.
        //Product name in UI will be same as Main Product i.e. without (New) and (Refurbished).
        //This logic is for all accounts except PBS. In PBS we are displaying all Products based on search key.
        System.debug('rootAccountId-->' + rootAccountId);
        System.debug('hwRootAccountId-->' + hwRootAccountId);
        System.debug('objectAPIName-->' + objectAPIName);
        System.debug('searchKeyWord-->' + searchKeyWord);
        System.debug('recordLimit-->' + recordLimit);
        String searchKeyAcc = '%' + searchKeyWord + '%';
        String searchKey = searchKeyWord + '%';
        List < sObject > returnList = new List < sObject > ();
        if(objectAPIName.startsWithIgnoreCase('product2')){
            Map<Id,Product2> prodMap = new Map<Id,Product2>();
            String familyCondition = '';
            if(objectAPIName == 'product2Hardware'){
                familyCondition = 'AND Family = \'Hardware\' ';
            }else if(objectAPIName == 'product2Service'){
                familyCondition = 'AND Family = \'Service\' ';
            }
            String beginQuery = 'SELECT Id, Name, Out_of_Scope__c FROM Product2 ';
            String accFilter = (hwRootAccountId != null && !String.isBlank(hwRootAccountId)) ? 'AND (Account_Item_Belongs_To__c =:rootAccountId OR Account_Item_Belongs_To__c =:hwRootAccountId)' : 'AND Account_Item_Belongs_To__c =:rootAccountId ';
            String filter = 'WHERE IsActive = true AND source_key__c != null ' + accFilter;
            String orderBy = 'ORDER BY Name';
            List<Account> rootAccList = [SELECT Id, Name FROM Account WHERE Id = :rootAccountId];
            if(!rootAccList.isEmpty()) {
                String sQuery = beginQuery + filter;
                String sQuery2 = beginQuery + filter;
                //List must have exact search matched products as first elements then other elements.
                if(rootAccList[0].Name == 'Premium Brands Services, LLC' || rootAccList[0].Name == 'Maurices Inc.' || rootAccList[0].Name == 'TGI Fridays Inc.' || rootAccList[0].Name == 'Cavender\'s Boot City') {
                    sQuery += 'AND Portal_Access__c = true AND Name LIKE: searchKey ' + familyCondition + orderBy;
                    sQuery2 += 'AND Portal_Access__c = true AND Name LIKE: searchKeyAcc ' + familyCondition + orderBy;
                    System.debug('sQuery-> ' + sQuery);
                    System.debug('sQuery2-> ' + sQuery2);
                    List < Product2 > prodList = Database.query(sQuery);
                    List < Product2 > prodList2 = Database.query(sQuery2);
                    prodMap.putAll(prodList);
                    prodMap.putAll(prodList2);
                } else {
                    sQuery += 'AND Name LIKE: searchKey ' + familyCondition + orderBy;
                    sQuery2 += 'AND Name LIKE: searchKeyAcc ' + familyCondition + orderBy;
                    System.debug('sQuery-> ' + sQuery);
                    System.debug('sQuery2-> ' + sQuery2);
                
                    List<sObject> lstOfRecords = Database.query(sQuery);
                    List<sObject> lstOfRecords2 = Database.query(sQuery2);
                    List<sObject> returnedProds = customLookUpController.returnProducts(lstOfRecords);
                    List<sObject> returnedProds2 = customLookUpController.returnProducts(lstOfRecords2);
                    returnList.addAll(returnedProds);
                    returnList.addAll(returnedProds2);

                    System.debug('sobject Product List size-> ' + returnList.size());
                    System.debug('sobject Product List-> ' + JSON.Serialize(returnList));
                    
                    //removing duplicate products.
                    for(sObject sobj : returnList){
                        Product2  p = (Product2) sobj;
                        prodMap.put(p.Id,p);
                    }
                    System.debug('prodMap size-> ' + prodMap.size());
                    System.debug('prodMap.values()-> ' + JSON.Serialize(prodMap.values()));
                }
            }
            return prodMap.values();
        }else if(objectAPIName.equalsIgnoreCase('Project__c')){
            String sQuery =  'SELECT Id, Name FROM ' +objectAPIName + ' WHERE Name LIKE: searchKey AND Client__c = \''+rootAccountId+'\' order by Name limit '+recordLimit ;
            return Database.query(sQuery);
        } else if(objectAPIName.equalsIgnoreCase('RootAccounts')){
            String sQuery =  'SELECT Id, Name, ShippingCountry, H_W_Root_Account__c,Default_Service_Contract__c,Default_Service_Contract__r.Service_Type__c FROM Account WHERE Active__c = true AND Name LIKE: searchKey AND Root_Account__c = null AND source_key__c != null ORDER BY Name limit '+recordLimit ;
            return Database.query(sQuery);
        } else if(objectAPIName.equalsIgnoreCase('ChildAccounts')){
            String sQuery =  'SELECT Id, Name, ShippingCountry, ParentId, Parent.Default_Service_Contract__c, Parent.Default_Service_Contract__r.Service_Type__c, Root_Account__r.Default_Service_Contract__c, Root_Account__r.Default_Service_Contract__r.Service_Type__c FROM Account WHERE Active__c = true AND Name LIKE: searchKeyAcc AND Root_Account__c = :rootAccountId AND source_key__c != null ORDER BY Name limit '+recordLimit ;
            return Database.query(sQuery);
        } else{
            String sQuery =  'SELECT ID FROM ' +objectAPIName + ' WHERE Name LIKE: searchKey order by createdDate limit '+recordLimit ;
            return Database.query(sQuery);
        }
    }

    public static List < sObject > returnProducts(List < sObject > lstOfRecords) {
        List < sObject > returnList = new List < sObject > ();
        for (sObject obj: lstOfRecords) {
            String prodName = String.valueOf(obj.get('Name'));
            if(prodName.containsIgnoreCase('(New)') || prodName.containsIgnoreCase('(Refurbished)') || 
                prodName.containsIgnoreCase('(Defective)') || prodName.containsIgnoreCase('Tested Defective')) continue;
            // adding main products
            returnList.add(obj);
        }
        System.debug('Product List-> ' + JSON.Serialize(returnList));
        Set<String> prodNames = new Set<String>();
        Set<String> addedProdNames = new Set<String>();
        for(sObject ro : returnList) {
            prodNames.add(String.valueOf(ro.get('Name')).toLowerCase());
        }
        for (sObject obj: lstOfRecords) {
            String origProdName = String.valueOf(obj.get('Name'));
            System.debug('origProdName-> ' + origProdName);
            if(origProdName.containsIgnoreCase('(Defective)') || origProdName.endsWithIgnoreCase('(Test)') || origProdName.endsWithIgnoreCase('(Refurbished)')) continue;
            String plainProdName = String.valueOf(obj.get('Name')).replace('(New)','');
            plainProdName = plainProdName.trim().toLowerCase();
            System.debug('plainProdName-> ' + plainProdName);
            if(!prodNames.contains(plainProdName) && origProdName.endsWithIgnoreCase('(New)')) {
                String displayProduct = String.valueOf(obj.get('Name')).replace('(New)','');
                if(addedProdNames.contains(displayProduct.trim())) continue;
                Product2 prod = (Product2)obj;
                prod.Name = displayProduct.trim();
                // adding (New) products
                returnList.add(prod);
                addedProdNames.add(displayProduct.trim());
            }
        }
        //Since we dont know which product comes first in loop we need separate for loop.
        for (sObject obj: lstOfRecords) {
            String origProdName = String.valueOf(obj.get('Name'));
            System.debug('origProdName-> ' + origProdName);
            if(origProdName.containsIgnoreCase('(Defective)') || origProdName.endsWithIgnoreCase('(Test)') || origProdName.endsWithIgnoreCase('(New)')) continue;
            String plainProdName = String.valueOf(obj.get('Name')).replace('(Refurbished)','');
            plainProdName = plainProdName.trim().toLowerCase();
            System.debug('plainProdName-> ' + plainProdName);
            if(!prodNames.contains(plainProdName) && origProdName.endsWithIgnoreCase('(Refurbished)')) {
                String displayProduct = String.valueOf(obj.get('Name')).replace('(Refurbished)','');
                if(addedProdNames.contains(displayProduct.trim())) continue;
                Product2 prod = (Product2)obj;
                prod.Name = displayProduct.trim();
                // adding (Refurbished) products.
                returnList.add(prod);
                addedProdNames.add(displayProduct.trim());
            }
        }
        return returnList;
    }
}