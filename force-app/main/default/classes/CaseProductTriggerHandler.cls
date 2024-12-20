public with sharing class CaseProductTriggerHandler {

    public static void handleBeforeInsert(List<Case_Product__c> cpList){
        Set<Id> caseIds = new Set<Id>();
        for(Case_Product__c cp : cpList){
            caseIds.add(cp.Case__c);
        }
        if(!caseIds.isEmpty()){
            CaseProductTriggerHandler.caseProdsTableToCase(caseIds,cpList);
        }
    }
    
    public static void handleAfterInsert(List<Case_Product__c> cpList){
        /*Set<Id> caseIds = new Set<Id>();
        for(Case_Product__c cp : cpList){
            caseIds.add(cp.Case__c);
        }
        List<Case> caseRecList = [SELECT Id,Service_Type__c,ServiceContract.Inventory_Impact__c FROM Case WHERE Id IN:caseIds];
        System.debug('caseRecList--->'+caseRecList);
        List<Case_Product__c> cpListToReduceInventory = new List<Case_Product__c>();
        Set<Id> caseIdToIncreaeInventory = new Set<Id>();
        for(Case c : caseRecList){
            System.debug('c.ServiceContract.Inventory_Impact__c '+ c.ServiceContract.Inventory_Impact__c);
            if(c.ServiceContract.Inventory_Impact__c == 'Decrease'){
                for(Case_Product__c cp :  cpList){
                    System.debug('cp.Case__c '+cp.Case__c+' - '+c.Id);
                    if(cp.Case__c == c.Id){
                        cpListToReduceInventory.add(cp);
                    }
                }
            }else if(c.ServiceContract.Inventory_Impact__c == 'Increase'){
                caseIdToIncreaeInventory.add(c.Id);
            }
        }
        if(userInfo.getName() != 'Bakul PBS'){
            if(!cpListToReduceInventory.isEmpty()){
                CaseProductTriggerHandler.updateProductBurnRate(JSON.serialize(cpListToReduceInventory));
                System.debug('Inventory Decreased');
            }
            if(!caseIdToIncreaeInventory.isEmpty()){
                CaseProductTriggerHandler.updateProductQuantityOnCPDelete(caseIdToIncreaeInventory);
                System.debug('Inventory Increased');
            }
        }*/
    }
    
    /*@future
    public static void updateProductBurnRate(String cpListString){
        List<Case_Product__c> cpList = (List<Case_Product__c>)JSON.deserialize(cpListString,List<Case_Product__c>.class);
        Set<Id> productIds = new Set<Id>();
        for(Case_Product__c cp : cpList){
            if(cp.Product__c == null) continue;
            productIds.add(cp.Product__c);
        }
        System.debug('productIds size-> ' + productIds.size());
        List<Product2> productList = [SELECT Id , Burn_Rate__c,X12_Weeks_Order_History__c, Quantity_Available__c, Quantity_on_Hand__c, 
                                      (SELECT Id, Quantity__c, Case__r.Service_Type__c FROM Case_Products__r 
                                      WHERE CreatedDate = LAST_N_DAYS:84 AND Case__r.ServiceContract.Include_In_Burn_Rate_Calculation__c = true) 
                                      FROM Product2 WHERE Id IN:productIds AND Critical_Quantity_lessthan_Reorder__c = true];
        for(Case_Product__c cp : cpList){
            for(Product2 pd : productList){
                if(cp.Product__c != pd.Id) continue;
                decimal orderHistory = 0;
                for(Case_Product__c cpChild : pd.Case_Products__r){
                    if(cpChild.Quantity__c != null && cpChild.Quantity__c != 0){
                        orderHistory += cpChild.Quantity__c;
                    }
                    if(cp.Id == cpChild.Id){
                        if(pd.Quantity_Available__c != null && (pd.Quantity_Available__c >= cp.Quantity__c)){
                            pd.Quantity_Available__c = pd.Quantity_Available__c - cp.Quantity__c;
                        } else{
                            pd.Quantity_Available__c = 0;
                        }
                        if(pd.Quantity_on_Hand__c != null && (pd.Quantity_on_Hand__c >= cp.Quantity__c)){
                            pd.Quantity_on_Hand__c = pd.Quantity_on_Hand__c - cp.Quantity__c;
                        } else{
                            pd.Quantity_on_Hand__c = 0;
                        }
                    }
                }
                System.debug('12 week orderHistory-> ' + orderHistory);
                System.debug('pd.Quantity_on_Hand__c-> ' + pd.Quantity_on_Hand__c);
                pd.Burn_Rate__c = (orderHistory / 12).setScale(2, RoundingMode.CEILING);
                pd.X12_Weeks_Order_History__c = integer.valueOf(orderHistory);
            }
        }
        System.debug('productList-> ' + productList);
        update productList;
    }
	
	public static void updateProductQuantityOnCPDelete(Set<Id> caseIds){
        List<Case_Product__c> cpList = [SELECT Id, Case__c, Product__c, Quantity__c FROM Case_Product__c WHERE Case__c IN : caseIds];
        Set<Id> productIds = new Set<Id>();
        for(Case_Product__c cp : cpList){
            productIds.add(cp.Product__c);
        }
        List<Product2> prodList = [SELECT Id, Quantity_Available__c, Quantity_on_Hand__c FROM Product2 WHERE Id IN: productIds];
        for(Case_Product__c cp : cpList){
            for(Product2 p : prodList){
                if(cp.Product__c != p.Id) continue;
                if(p.Quantity_Available__c == null) p.Quantity_Available__c = 0;
                if(p.Quantity_on_Hand__c == null) p.Quantity_on_Hand__c = 0;
                if(cp.Quantity__c != null && cp.Quantity__c != 0){
                    p.Quantity_Available__c = p.Quantity_Available__c + cp.Quantity__c;
                    p.Quantity_on_Hand__c = p.Quantity_on_Hand__c + cp.Quantity__c;
                }
            }
        }
        update prodList;
    }*/

    public static void caseProdsTableToCase(Set<Id> caseIds, List<Case_Product__c> cpList) {
        Map<Id, Case> cMap = new Map<Id, Case>([SELECT Id, Case_Products__c FROM Case WHERE Id IN :caseIds]);

        Map<Id, List<Case_Product__c>> caseProductsMap = new Map<Id, List<Case_Product__c>>();
        for (Case_Product__c cp : cpList) {
            if (cp.Case__c != null) {
                if (!caseProductsMap.containsKey(cp.Case__c)) {
                    caseProductsMap.put(cp.Case__c, new List<Case_Product__c>());
                }
                caseProductsMap.get(cp.Case__c).add(cp);
            }
        }

        Map<Id, Case> caseMapToUpdate = new Map<Id, Case>();

        for (Id caseId : caseProductsMap.keySet()) {
            List<Case_Product__c> cpListForCase = caseProductsMap.get(caseId);
            String htmlBody = '';
            htmlBody = '<table style="width:80%;border: 1px;font-family: Calibri;" cellspacing="0">';
            htmlBody += '<tr><th style="background-color: #f2f2f2;border: 1px solid #ddd;text-align: left;padding: 6px;">Product Code</th>';
            htmlBody += '<th style="background-color: #f2f2f2;border: 1px solid #ddd;text-align: left;padding: 6px;">Product Name</th>';
            htmlBody += '<th style="background-color: #f2f2f2;border: 1px solid #ddd;text-align: left;padding: 6px;">Quantity</th></tr>';

            for (Case_Product__c cp : cpListForCase) {
                String productCode = cp.Product_Code__c != null ? cp.Product_Code__c : '[Not Provided]';
                String productName = cp.Product_Name__c != null ? cp.Product_Name__c : '[Not Provided]';
                String quantity = cp.Quantity__c != null ? String.valueOf(cp.Quantity__c) : '[Not Provided]';

                htmlBody += '<tr><td style="border: 1px solid #ddd;text-align: left;padding: 3px;">' + productCode + '</td>';
                htmlBody += '<td style="border: 1px solid #ddd;text-align: left;padding: 3px;">' + productName + '</td>';
                htmlBody += '<td style="border: 1px solid #ddd;text-align: left;padding: 3px;">' + quantity + '</td></tr>';
            }

            htmlBody += '</table>';

            if (cMap.containsKey(caseId)) {
                Case c = cMap.get(caseId);
                c.Case_Products__c = htmlBody;
                caseMapToUpdate.put(c.Id, c);
            }
        }

        if (!caseMapToUpdate.isEmpty()) {
            update caseMapToUpdate.values();
        }
    }
}