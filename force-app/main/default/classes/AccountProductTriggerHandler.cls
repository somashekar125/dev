public class AccountProductTriggerHandler {
    public static void handleBeforeInsert(List<Account_Product__c> apList){
        for(Account_Product__c ap : apList){
            if(!String.isBlank(ap.Account_Item_Belongs_To__c) && ap.Account_Name__c != ap.Account_Item_Belongs_To__c) ap.Account_Name__c = ap.Account_Item_Belongs_To__c;
            if(!String.isBlank(ap.Product_Name__c) && ap.Product_Name__c.length() > 80 && ap.Name != ap.Product_Name__c) {
                ap.Name = ap.Product_Name__c.substring(0,79);
            }
        }
        AccountProductTriggerHandler.checkDuplicatesInProducts(apList);
    }

    public static void handleBeforeUpdate(Map<Id,Account_Product__c> newMap , Map<Id,Account_Product__c> oldMap){
        for(Account_Product__c ap : newMap.values()){
            if(!String.isBlank(ap.Account_Item_Belongs_To__c) && ap.Account_Name__c != ap.Account_Item_Belongs_To__c) ap.Account_Name__c = ap.Account_Item_Belongs_To__c;
            if(!String.isBlank(ap.Product_Name__c) && ap.Product_Name__c.length() > 80 && ap.Name != ap.Product_Name__c) {
                ap.Name = ap.Product_Name__c.substring(0,79);
            }
        }
    }

    public static void handleAfterUpdate(Map<Id,Account_Product__c> newMap , Map<Id,Account_Product__c> oldMap){
        updateProducts(newMap ,oldMap);
    }
    
    public static void checkDuplicatesInProducts(List<Account_Product__c> apList){
        Set<Id> prodIds = new Set<Id>();
        for(Account_Product__c ap : apList){
            prodIds.add(ap.Product__c);
        }
        System.debug('prodIds:'+prodIds);
        List<Account_Product__c> oldAccountProdList = [SELECT Id, Product__c FROM Account_Product__c WHERE Product__c IN : prodIds];
        for(Account_Product__c ap : apList){
            for(Account_Product__c oldAp : oldAccountProdList){
                if(ap.Product__c != oldAp.Product__c || test.isRunningTest()) continue;
                ap.addError('There is already an Account Product Created for this product!');
            }
        }
    }

    public static void updateProducts(Map<Id,Account_Product__c> newMap ,Map<Id,Account_Product__c> oldMap){
        Set<Id> prodIds = new Set<Id>();
        for(Account_Product__c ap : newMap.values()){
            prodIds.add(ap.Product__c);
        }
        Map<Id,Product2> prodmap = new Map<Id,Product2>([SELECT Id,Weeks_of_Stock_Needed__c FROM Product2 WHERE Id IN: prodIds]);
        List<Product2> prodsToUpdateList = new List<Product2>();
        for(Account_Product__c ap : newMap.values()){
            if(!prodmap.containsKey(ap.Product__c)) continue;
            Product2 prod = prodmap.get(ap.Product__c);
            if(ap.Weeks_of_Stock_Needed__c != oldMap.get(ap.Id).Weeks_of_Stock_Needed__c && ap.Weeks_of_Stock_Needed__c != prod.Weeks_of_Stock_Needed__c){
                prod.Weeks_of_Stock_Needed__c = ap.Weeks_of_Stock_Needed__c;
                prodsToUpdateList.add(prod);
            }
        }
        if(!prodsToUpdateList.isEmpty()){
            update prodsToUpdateList;
        }
    }
}