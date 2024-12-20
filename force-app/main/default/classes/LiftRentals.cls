public without sharing class LiftRentals {
    @AuraEnabled
    public static Boolean checkForExistingWOLI(String woId) {
        Boolean existWOLI = false;
        List<Product_Mapping__mdt> costProductList = Product_Mapping__mdt.getAll().values();
        System.debug('costProductList-> ' + costProductList);
        set<String> ProdName = new set<String>();
        for(Product_Mapping__mdt pm : costProductList){
            if(pm.Field_API_Name__c != 'Equipment_Rental_Cost__c') continue;
            if(pm.Charge_Product_Name__c != null) ProdName.add(pm.Charge_Product_Name__c);
            if(pm.Cost_Product_Name__c != null) ProdName.add(pm.Cost_Product_Name__c);
        }
        list<WorkOrderLineItem> existingLineItem = new list<WorkOrderLineItem>();
        if(!ProdName.isEmpty()){
            existingLineItem = [SELECT Id FROM WorkOrderLineItem WHERE WorkOrderId =:woId AND PricebookEntry.Product2.Name IN :ProdName 
                                AND (PricebookEntry.Product2.Name LIKE '%EQUIPMENT-RENTAL%' OR Created_For_Field__c = 'Equipment_Rental_Cost__c')];
        }
        if(!existingLineItem.isEmpty()){
            existWOLI = true;
        }
        return existWOLI;
    }
    
    @AuraEnabled
    public static WorkOrder getwoRec(Id woId){
        WorkOrder wo = [SELECT Id,CaseId,Preferred_Time_IMAC__c,StartDate FROM WorkOrder WHERE Id =: woId];
        if(wo.Preferred_Time_IMAC__c != null){
            wo.StartDate = DateTime.newInstance(wo.Preferred_Time_IMAC__c.date(), Time.newInstance(7,0,0,0));
        } else {
            wo.StartDate = DateTime.newInstance(System.now().date(), Time.newInstance(7,0,0,0));
        }
        System.debug('wo.StartDate time-> ' + wo.StartDate.time());
        return wo;
    }
    
    @AuraEnabled
    public static Boolean orderingLift(String woId, String vendor, Date prefDate, String prefTime) {
        Boolean isLiftRequested = false;
        WorkOrder wo = [SELECT Id,AccountId,Account.Timezone__c,CaseId,Preferred_Time_IMAC__c,StartDate FROM WorkOrder WHERE Id =: woId];
        System.debug('vendor-> ' + vendor);
        System.debug('prefDate-> ' + prefDate);
        System.debug('prefTime-> ' + prefTime);
        DateTime dt = null;
        if(prefDate != null && !String.isBlank(prefTime)){
            // Splitting the time string and converting to integers
            Integer hours = Integer.valueOf(prefTime.substring(0, 2));
            Integer minutes = Integer.valueOf(prefTime.substring(3, 5));
            Integer seconds = Integer.valueOf(prefTime.substring(6, 8));
            // Creating a Time instance
            Time parsedTime = Time.newInstance(hours, minutes, seconds, 0);
            System.debug('parsedTime-> ' + parsedTime);
            dt = DateTime.newInstance(prefDate,parsedTime);
            //Calculation.
            String stroetimezone = '';
            User currUser = [SELECT Id, TimeZoneSidKey FROM user WHERE Id = :UserInfo.getUserId()];
            List<Timezone_Id__mdt> tzList = [SELECT MasterLabel, QualifiedApiName, Timezon_Id__c FROM Timezone_Id__mdt];
            for(Timezone_Id__mdt tz : tzList) {
                if(tz.MasterLabel == wo.Account.Timezone__c){
                    stroetimezone = tz.Timezon_Id__c;
                }
            }
            integer storeTimehours = Integer.valueOf(dt.format('HH', stroetimezone));
            integer userTimehours = Integer.valueOf(dt.format('HH', currUser.TimeZoneSidKey));
            if(storeTimehours == 0){
                storeTimehours = 24;
            }
            if(userTimehours == 0){
                userTimehours = 24;
            }
            integer result;
            //Converting To User TimeZone.
            if(userTimehours > storeTimehours){
                result = userTimehours - storeTimehours;
                //adding hours
                dt = dt.addHours(result);
            }
            if(userTimehours < storeTimehours){
                result = userTimehours - storeTimehours;
                //subtracting hours
                dt = dt.addHours(result);
            }
            System.debug('dt after-> ' + dt);
        }
        List<WorkOrder> woList = [SELECT Id,Order_Lift__c,Equipment_Rental_Cost__c,Pricebook2Id,ServiceContractId,
                                  ServiceContract.Markup_on_Equipment__c FROM WorkOrder WHERE Id=: woId AND Order_Lift__c = false LIMIT 1];
        if(!woList.isEmpty()){
            List<Product_Mapping__mdt> costProductList = Product_Mapping__mdt.getAll().values();
            System.debug('costProductList-> ' + costProductList);
            set<String> ProdName = new set<String>();
            for(Product_Mapping__mdt pm : costProductList){
                if(pm.Field_API_Name__c != 'Equipment_Rental_Cost__c') continue;
                if(pm.Charge_Product_Name__c != null) ProdName.add(pm.Charge_Product_Name__c);
                if(pm.Cost_Product_Name__c != null) ProdName.add(pm.Cost_Product_Name__c);
            }
            List<PricebookEntry> pbeList = [SELECT Id,Pricebook2Id,Product2Id,Product2.Description,Product2.Name FROM PricebookEntry 
                                            WHERE Product2.Name Like :ProdName AND isActive = true AND Pricebook2Id =: woList[0].Pricebook2Id];
            Id liftRtlId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByDeveloperName().get( 'Equipment_Rental' ).getRecordTypeId();
            List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
            for(PricebookEntry pbe : pbeList){
                if(pbe.Pricebook2Id != woList[0].Pricebook2Id) continue;
                String woliStatus = 'New';
                if(pbe.Product2.Name.containsIgnoreCase('COST')){
                    woliStatus = 'Lift Requested';
                }
                WorkOrderLineItem woli = new WorkOrderLineItem(PricebookEntryId = pbe.Id, unitPrice = 0, Quantity = 1, 
                                                               RecordTypeId = liftRtlId, WorkOrderId = woId, StartDate = dt, Vendor__c = vendor,
                                                               Status = woliStatus, Description = pbe.Product2.Description,
                                                               Created_For_Field__c = 'Equipment_Rental_Cost__c');
                woliList.add(woli);
            }
            if(!woliList.isEmpty()){
                insert woliList;
                
                woList[0].Vendor__c = vendor;
                woList[0].Order_Lift__c = true;
                update woList[0];
                
                isLiftRequested = true;
            }
        }
        return isLiftRequested;
    }
    
    @AuraEnabled
    public static Boolean returningLift(String woId) {
        //WorkOrder wo = new WorkOrder(Id = woId, Return_Lift__c = true);
        Boolean isReturnLiftRequested = false;
        List<WorkOrder> woList = [SELECT Id,Return_Lift__c FROM WorkOrder WHERE Id=: woId AND Return_Lift__c = false LIMIT 1];
        if(!woList.isEmpty()){
            
            List<Product_Mapping__mdt> costProductList = Product_Mapping__mdt.getAll().values();
            System.debug('costProductList: ' + costProductList);
            set<String> ProdName = new set<String>();
            for(Product_Mapping__mdt pm : costProductList){
                if(pm.Field_API_Name__c != 'Equipment_Rental_Cost__c') continue;
                if(pm.Charge_Product_Name__c != null) ProdName.add(pm.Charge_Product_Name__c);
                if(pm.Cost_Product_Name__c != null) ProdName.add(pm.Cost_Product_Name__c);
            }
            list<WorkOrderLineItem> existingLineItem = new list<WorkOrderLineItem>();
            if(!ProdName.isEmpty()){
                existingLineItem = [SELECT Id,Status FROM WorkOrderLineItem WHERE WorkOrderId =:woId
                                    AND PricebookEntry.Product2.Name IN :ProdName AND Created_For_Field__c != null];
            }
            for(WorkOrderLineItem woli : existingLineItem){
                woli.Status = 'Pickup Requested';
            }
            if(!existingLineItem.isEmpty()){
                update existingLineItem;
                
                woList[0].Return_Lift__c = true;
                isReturnLiftRequested = true;
                update woList[0];
            }
        }
        return isReturnLiftRequested;
    }
}