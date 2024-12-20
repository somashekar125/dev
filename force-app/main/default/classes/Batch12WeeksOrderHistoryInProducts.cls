global class Batch12WeeksOrderHistoryInProducts implements Database.Batchable<sObject>,Schedulable {
    global Database.QueryLocator start(Database.BatchableContext bc){
        String query =  'SELECT Id, Name, Product_Condition__c, ProductCode, Burn_Rate__c, X12_Weeks_Order_History__c, Tested_Defective_QA__c,Tested_Defective_QOH__c, '+
                        'NS_Quantity_Available__c, NS_Quantity_On_Hand__c, Quantity_Available__c, Quantity_on_Hand__c, '+
                        'Defective_Quantity_Available__c, Defective_Quantity_on_Hand__c,(SELECT Id, Quantity__c FROM Sales_Order_Lines__r ' + 
                        'WHERE CreatedDate = LAST_N_DAYS:84 AND Sales_Order__r.Case__r.ServiceContract.Include_In_Burn_Rate_Calculation__c = true) ' +
                        'FROM Product2 WHERE IsActive = true AND Original_Part__c = null AND Source_Key__c != null ORDER BY LastModifiedDate DESC';
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc, List<Product2> scope){
        Set<Id> originalParts = new Set<Id>();
        for(Product2 origProd : scope){
            originalParts.add(origProd.Id);
        }
        System.debug('originalParts size -> ' + originalParts.size());
        List<Product2> childProdList = [SELECT Id, Name, Product_Condition__c, ProductCode, Burn_Rate__c, X12_Weeks_Order_History__c, Original_Part__c,NS_Quantity_Available__c, 
                                        NS_Quantity_On_Hand__c,Quantity_Available__c,Quantity_on_Hand__c,
                                        (SELECT Id, Quantity__c FROM Sales_Order_Lines__r WHERE CreatedDate = LAST_N_DAYS:84 
                                        AND Sales_Order__r.Case__r.ServiceContract.Include_In_Burn_Rate_Calculation__c = true) FROM Product2 
                                        WHERE Original_Part__c IN: originalParts AND IsActive = true AND Source_Key__c != null ORDER BY LastModifiedDate DESC];
        System.debug('childProdList size -> ' + childProdList.size());
        Map<Id,Product2> origPlusChildMap = new Map<Id,Product2>();
        for(Product2 origProd : scope){
            Decimal orderHistory = 0;
            Decimal childOrderHistory = 0;
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
        try {
            if(!origPlusChildMap.isEmpty()){
                System.debug('Updating Products');
                ProductTriggerHandler.runOnceBeforeUpdate = false;
                ProductTriggerHandler.runOnceAfterUpdate = false;
                update origPlusChildMap.values();
            }
        } catch (Exception e) {
            System.debug('Error updating records: ' + e.getMessage());
        }        
    }
    global void finish(Database.BatchableContext bc){
    
    }
    global void execute(SchedulableContext sc){
        Batch12WeeksOrderHistoryInProducts prodBatch = new Batch12WeeksOrderHistoryInProducts();
        Database.executeBatch(prodBatch);
    }
}