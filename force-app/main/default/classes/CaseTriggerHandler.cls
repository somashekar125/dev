public without sharing class CaseTriggerHandler {
    public static boolean runOnceAfterUpdate = true;
    public static boolean runOnceBeforeUpdate = true;
    public static void handleBeforeInsert(List<Case> caseList) {
        assignSLAExitDate(caseList);
        setServiceContractId(caseList);
        setStoreTimezoneDateTimes(caseList);
        caseFieldUpdate(caseList);
        handleCaseCreation(caseList);
        caseFieldUpdateFromETA(caseList);    
    }

    public static void handleAfterInsert(List<Case> caseList) {
        Set<Id> caseIds = new Set<Id>();
        for(Case c : caseList){
            caseIds.add(c.Id);
        }
        List<Account> acList = [SELECT Id, Name, (SELECT Id, Name FROM ChildAccounts) FROM Account WHERE Name = 'Premium Brands Services, LLC'];
        Set<Id> acIds = new Set<Id>();
        for(Account a : acList){
            acIds.add(a.Id);
            for(Account ac : a.ChildAccounts){
                acIds.add(ac.Id);
            }
        }
        List<case> csList = [SELECT Id, AccountId FROM Case WHERE Id IN : caseIds AND Account.ParentId IN : acList];
        if(csList.size() != 0){
            createCaseContactRoles(csList);
        }
        Map<Id, Case> newMap = new Map<Id, Case>(caseList);
        convertedCaseProcess(newMap, null);
    }
    
    public static void handleBeforeUpdate(Map<Id, Case> newMap, Map<Id, Case> oldMap) {
        if(runOnceBeforeUpdate) {
            closingProcess(newMap,oldMap);
            handleCaseCancellationRequest(newMap,oldMap);
            caseFieldUpdate(newMap.values());
            handleCaseCreation(newMap.values());
            List<Case> caseList = new List<Case>();
            List<Case> caseList2 = new List<Case>();
            for(Case cs : newMap.values()){
                if(cs.Calculate_SLA__c) caseList.add(cs);
                if(cs.Preferred_Time__c != oldMap.get(cs.Id).Preferred_Time__c || cs.Expected_SLA_Exit_Date__c != oldMap.get(cs.Id).Expected_SLA_Exit_Date__c
                    || cs.Part_Receipt_Due_DateTime__c != oldMap.get(cs.Id).Part_Receipt_Due_DateTime__c || cs.Technician_OnSite_ETA__c != oldMap.get(cs.Id).Technician_OnSite_ETA__c
                    || cs.Technician_Onsite_Start_Time__c != oldMap.get(cs.Id).Technician_Onsite_Start_Time__c || cs.Technician_Onsite_Stop_Time__c != oldMap.get(cs.Id).Technician_Onsite_Stop_Time__c) {
                        caseList2.add(cs);
                    }
            }
            if(!caseList.isEmpty()) assignSLAExitDate(caseList);
            if(!caseList2.isEmpty())  setStoreTimezoneDateTimes(caseList2);
        }
        for(Case c : newMap.values()){
            if(c.Status != 'Closed' && oldMap.get(c.Id).Status == 'Deletion Requested') {
                c.Status = 'Deletion Requested';
            }
            if(c.CreatedDate > c.Closed_Date_Time__c){
                c.addError('Closed date cannot be earlier than case created date!');
            }
            // New Closed_Date_Time__c must not be greater than Old value.
            if(c.Closed_Date_Time__c > oldMap.get(c.Id).Closed_Date_Time__c){
                c.Closed_Date_Time__c = oldMap.get(c.Id).Closed_Date_Time__c;
            }
            //This field is used to send reminder email
            if(c.Status == 'Tech Checked In' && c.Status != oldMap.get(c.Id).Status) {
                c.Reminder_DateTime__c = System.now();
            } else {
                c.Reminder_DateTime__c = null;
            }
        }
        populatingClosedDates(newMap,oldMap);
    }

    public static void handleAfterUpdate(Map<Id, Case> newMap, Map<Id, Case> oldMap){
        if(!runOnceAfterUpdate) return;
        Set<Id> parentCsId = new Set<Id>();
        for(Case c : newMap.values()){
            if((c.Status == 'Closed' || c.Status == 'Tech Checked In' || c.Status == 'Part Received By Customer') && c.Status != oldMap.get(c.Id).Status && c.ParentId != null){
                parentCsId.add(c.ParentId);
            }
        }
        closeParentCases(parentCsId);
        convertedCaseProcess(newMap, oldMap);

        
        Map<Id,Case> csMap = new Map<Id,Case>();
        for(Case cs : newMap.values()){
            if(cs.Create_Work_Order__c && cs.Create_Work_Order__c != oldMap.get(cs.Id).Create_Work_Order__c && !String.isBlank(cs.Service_Type__c) 
                && !String.isBlank(cs.Root_Account__c) && !String.isBlank(cs.ServiceContractId) && !String.isBlank(cs.Country__c)) {
                csMap.put(cs.Id,cs);
            }
        }
        System.debug('csMap size-> ' + csMap.size());
        if(!csMap.isEmpty()) WorkOrderController.createWOThroughServiceContract(JSON.serialize(csMap));
    }

    public static void handleBeforeDelete(List<Case> caseList) {
        Set<Id> caseIds = new Set<Id>();
        for(Case c : caseList){
            caseIds.add(c.Id);
        }
        List<WorkOrder> woList = [SELECT Id FROM WorkOrder WHERE CaseId IN : caseIds];
        if(!woList.isEmpty()){
            delete woList;
        }
        //Placing this query here to avoid 'Entity is deleted' exception.
        List<WorkOrder> chLdWOList = [SELECT Id FROM WorkOrder WHERE ParentWorkOrder.CaseId IN : caseIds];
        if(!chLdWOList.isEmpty()){
            delete chLdWOList;
        }
        //CaseProductTriggerHandler.updateProductQuantityOnCPDelete(caseIds);
    }
    
    public static void convertedCaseProcess(Map<Id, Case> newMap, Map<Id, Case> oldMap) {
        Map<Id, Id> caseContactMap = new Map<Id, Id>();
        Map<Id, Decimal> caseProductQuantityMap = new Map<Id, Decimal>();
        Map<Id, String> caseTrackingNumbersMap = new Map<Id, String>();
        List<Task> tasksToCreate = new List<Task>();
        List<Case> casesToUpdate = new List<Case>();
        Set<Id> parentCaseIds = new Set<Id>();
		Boolean isUpdate = (oldMap != null) ? true: false;
        
        for (Id caseId : newMap.keySet()) {
            Case newCase = newMap.get(caseId);
            if (isUpdate) {
                if(!oldMap.containsKey(caseId)) continue;
                Case oldCase = oldMap.get(caseId);
                if (newCase.ContactId != oldCase.ContactId) {
                    caseContactMap.put(caseId, newCase.ContactId);
                }
                if (newCase.Product_Quantity__c != oldCase.Product_Quantity__c) {
                    caseProductQuantityMap.put(caseId, newCase.Product_Quantity__c);
                }
                if (newCase.Tracking_Numbers__c != oldCase.Tracking_Numbers__c && newCase.Tracking_Numbers__c != null) {
                    caseTrackingNumbersMap.put(caseId, newCase.Tracking_Numbers__c);
                }   
            }
            if(!isUpdate) {
                if (newCase.Status == 'Acknowledged' && newCase.ParentId != null) {
                    parentCaseIds.add(newCase.ParentId);
                }
                if (newCase.Service_Type__c == 'Part Return') {
                    Task newTask = new Task(
                        OwnerId = System.Label.Part_Request_Queue_Id,
                        Subject = 'Return Label need to be sent for the case',
                        WhatId = newCase.Id,
                        Status = 'Open',
                        Priority = 'Normal',
                        ActivityDate = System.today()
                    );
                    tasksToCreate.add(newTask);
                }
            }
        }

        if (!parentCaseIds.isEmpty()) {
            Map<Id, Case> parentCaseMap = new Map<Id, Case>([
                SELECT Id, RecordType.DeveloperName 
                FROM Case 
                WHERE Id IN :parentCaseIds
            ]);

            for (Id caseId : newMap.keySet()) {
                Case newCase = newMap.get(caseId);
                if (newCase.Status == 'Acknowledged' && newCase.ParentId != null && parentCaseMap.containsKey(newCase.ParentId)) {
                    Case parentCase = parentCaseMap.get(newCase.ParentId);
                    if (parentCase.RecordType.DeveloperName == 'Bundle') {
                        newCase.Status = 'In Progress';
                        casesToUpdate.add(newCase);
                    }
                }
            }
        }

        if (!caseContactMap.isEmpty() || !caseProductQuantityMap.isEmpty() || !caseTrackingNumbersMap.isEmpty()) {
            List<WorkOrder> workOrdersToUpdate = [
                SELECT Id, ContactId, CaseId, Product_Quantity__c, Tracking_Numbers__c 
                FROM WorkOrder 
                WHERE CaseId IN :caseContactMap.keySet() 
                    OR CaseId IN :caseProductQuantityMap.keySet()
                    OR CaseId IN :caseTrackingNumbersMap.keySet()
            ];
            Boolean toUpdateWO = false;
            for (WorkOrder wo : workOrdersToUpdate) {
                if (caseContactMap.containsKey(wo.CaseId)) {
                    wo.ContactId = caseContactMap.get(wo.CaseId);
                    toUpdateWO = true;
                }
                if (caseProductQuantityMap.containsKey(wo.CaseId)) {
                    wo.Product_Quantity__c = caseProductQuantityMap.get(wo.CaseId);
                    toUpdateWO = true;
                }
                if (caseTrackingNumbersMap.containsKey(wo.CaseId) && wo.Tracking_Numbers__c != caseTrackingNumbersMap.get(wo.CaseId)) {
                    wo.Tracking_Numbers__c = caseTrackingNumbersMap.get(wo.CaseId);
                    toUpdateWO = true;
                }
            }

            if (toUpdateWO) {
                WorkOrderTriggerHandler.runOnceBeforeUpdate = false;
                WorkOrderTriggerHandler.runOnceAfterUpdate = false;
                update workOrdersToUpdate;
            }
        }

        if (!tasksToCreate.isEmpty()) {
            insert tasksToCreate;
        }

        if (!casesToUpdate.isEmpty()) {
            CaseTriggerHandler.runOnceBeforeUpdate = false;
            CaseTriggerHandler.runOnceAfterUpdate = false;
            update casesToUpdate;
        }
    }

    public static void closeParentCases(Set<Id> parentCsId) {
        List<Case> csList = [SELECT Id, CaseNumber, Status, ParentId FROM Case WHERE ParentId IN: parentCsId AND 
                              (Status != 'Closed' AND Status != 'Tech Checked In' AND Status != 'Part Received By Customer')];
        Set<Id> excludeCsIds = new Set<Id>();
        for(Case cs : csList){
            excludeCsIds.add(cs.ParentId);
        }
        System.debug('excludeCsIds-> ' + excludeCsIds);
        Set<Id> closedCases = new Set<Id>();
        for(Id i : parentCsId){
            if(!excludeCsIds.contains(i)){
                closedCases.add(i);
            }
        }
        System.debug('closedCases-> ' + closedCases);
        if(closedCases.size() != 0){
            List<Case> clsedCase = new List<Case>();
            for(Id csid : closedCases){
                Case cs = new Case();
                cs.Id = csid;
                cs.Closing_Process__c = true;
                cs.Status = 'Closed';
                clsedCase.add(cs);
            }
            runOnceAfterUpdate = false;
            Database.update(clsedCase, false);
        }
    }

    public static void populatingClosedDates(Map<Id, Case> newMap, Map<Id, Case> oldMap){
        for(Case c : newMap.values()){
            if(c.Status == oldMap.get(c.Id).Status) continue;
            if(c.Actual_Part_Close_Date__c != null && c.Closed_Date_Time__c != null) continue;
            if(c.Actual_Part_Close_Date__c == null && c.Status == 'Part Shipped'){
                c.Actual_Part_Close_Date__c = System.now();
            }
            if(c.Closed_Date_Time__c != null) continue;
            if(c.Priority == 'Severity 2' && (c.Account_Name_For_Search__c.containsIgnoreCase('CUB') || c.Account_Name_For_Search__c.containsIgnoreCase('SHOPPER'))){
                if(c.Status == 'Onsite Work Completed' || c.Status == 'Closed'){
                    c.Closed_Date_Time__c = System.now();
                }
            } else {
                if((c.Status == 'Tech Checked In' || c.Status == 'Onsite Work Completed' 
                    || c.Status == 'Closed' || c.Status == 'Cannot Complete' || c.Status == 'Tech Checked Out')){
                    c.Closed_Date_Time__c = System.now();
                }
            }
        }
    }

    public static void closingProcess(Map<Id, Case> newMap, Map<Id, Case> oldMap) {
        for (Case c : newMap.values()) {
            System.debug('c.Closing_Process__c before->  ' + c.Closing_Process__c + ' c.Status-> ' + c.Status);
            if ((c.Status != oldMap.get(c.Id).Status && c.Status == 'Closed') && c.Closing_Process__c == false){
                System.debug('throwing error here->c.Closing_Process__c->  ' + c.Closing_Process__c + ' c.Status-> ' + c.Status);
                c.addError('Please go through the closing process by clicking the \'Close Case\' button to close this case');
            } else if(c.Closing_Process__c == true){
                c.Closing_Process__c = false;
            }
        }
    }

    public static void handleCaseCancellationRequest(Map<Id, Case> newMap, Map<Id, Case> oldMap) {
        Set<Id> csIds = new Set<Id>();
        for(Case cs : newMap.values()) {
            if(cs.Status == 'Cancellation Requested' && cs.Status != oldMap.get(cs.Id).Status) csIds.add(cs.Id);
        }
        if(!csIds.isEmpty()) {
            List<WorkOrder> woList = [SELECT Id, Status FROM WorkOrder WHERE CaseId IN :csIds AND Status != 'Closed' AND Status != 'Onsite Work Completed'];
            for(WorkOrder wo : woList) {
                wo.Status = 'Cancellation Requested';
            }
            if(!woList.isEmpty()) Database.update(woList, false);
        }
    }

    public static void setStoreTimezoneDateTimes(List<Case> caseList) {
        Set<Id> accIds = new Set<Id>();
        for(Case c : caseList){
            accIds.add(c.AccountId);
        }
        Map<Id,Account> accMap = new Map<Id, Account>([SELECT Id, Timezone__c, ShippingState FROM Account WHERE Id IN :accIds]);
        List<Timezone_Id__mdt> tzList = [SELECT MasterLabel, QualifiedApiName, Timezon_Id__c FROM Timezone_Id__mdt];
        User currUser = [SELECT Id, TimeZoneSidKey FROM User WHERE Id = :UserInfo.getUserId()];
        Map<String,String> tmzNameIdMap = new Map<String,String>();
        String timezoneId = '';
        String timezoneName = '';
        if(accMap.isEmpty() || tzList.isEmpty()) return;

        for(Case c : caseList){
            tmzNameIdMap = ASCENACaseMilestoneCalculater.getTimezoneIdForAccount(accMap.get(c.AccountId), tzList);
            if (!tmzNameIdMap.isEmpty()) {
                List<String> keyList = new List<String>(tmzNameIdMap.keySet());
                timezoneName = keyList[0];
                timezoneId = tmzNameIdMap.get(timezoneName);
            }
            if(String.isBlank(timezoneId)) continue;
            String temp = ' (' + timezoneName + ')';
            if(c.Expected_SLA_Exit_Date__c != null){
                c.SLA_Due_Date_TimeStr__c = c.Expected_SLA_Exit_Date__c.format('MM/dd/yyyy hh:mm a') + temp;
            }
            System.debug('c.Preferred_Time__c-->' +c.Preferred_Time__c);
            if(c.Preferred_Time__c != null){
                DateTime dt = timeZoneConversion(c.Preferred_Time__c, timezoneId, currUser);
                c.Preferred_TimeStr__c = dt.format('MM/dd/yyyy hh:mm a') + temp;
            }
            if(c.Part_Receipt_Due_DateTime__c != null){
                // DateTime dt = timeZoneConversion(c.Part_Receipt_Due_DateTime__c, timezoneId, currUser);
                c.Part_Shipped_Due_Date_TimeStr__c = C.Part_Receipt_Due_DateTime__c.format('MM/dd/yyyy hh:mm a') + temp;
            }
            if(c.Technician_OnSite_ETA__c != null){
                // DateTime dt = timeZoneConversion(c.Technician_OnSite_ETA__c, timezoneId, currUser);
                c.Technician_OnSite_ETA_Str__c = C.Technician_OnSite_ETA__c.format('MM/dd/yyyy hh:mm a') + temp;
            }
            if(c.Technician_Onsite_Start_Time__c != null){
                // DateTime dt = timeZoneConversion(c.Technician_Onsite_Start_Time__c, timezoneId, currUser);
                c.Technician_Onsite_Start_TimeStr__c = C.Technician_Onsite_Start_Time__c.format('MM/dd/yyyy hh:mm a') + temp;
            }
            if(c.Technician_Onsite_Stop_Time__c != null){
                // DateTime dt = timeZoneConversion(c.Technician_Onsite_Stop_Time__c, timezoneId, currUser);
                c.Technician_Onsite_Stop_TimeStr__c = C.Technician_Onsite_Stop_Time__c.format('MM/dd/yyyy hh:mm a') + temp;
            }
        }
    }

    public static Datetime timeZoneConversion(Datetime dt, String timezoneId, User currUser) {
        Integer storeTimeHours = Integer.valueOf(dt.format('HH', timezoneId));
        Integer userTimeHours = Integer.valueOf(dt.format('HH', currUser.TimeZoneSidKey));
        if (storeTimeHours == 0) {
            storeTimeHours = 24;
        }
        if (userTimeHours == 0) {
            userTimeHours = 24;
        }
        Integer result = 0;
        result = storeTimeHours - userTimeHours;
        return dt.addHours(result);
    }

    public static void setServiceContractId(List<Case> caseList) {
        Set<Id> accIds = new Set<Id>();
        List<String> serviceTypes = new List<String>();
        for(Case c : caseList){
            if(c.ServiceContractId == null){
                accIds.add(c.AccountId);
                serviceTypes.add(c.Service_Type__c);
            }
        }
        if(!accIds.isEmpty() && !serviceTypes.isEmpty()){
            Map<Id,Account> accMap = new Map<Id,Account>([SELECT Id,ShippingCountry,Root_Account__c FROM Account WHERE Id IN: accIds]);
            List<ServiceContract> scList = [SELECT Id,Service_Type__c,Country__c,AccountId FROM ServiceContract 
                                            WHERE Service_Type__c IN :serviceTypes AND Status = 'Active' AND Include_in_Service_Type_Picklist__c = true];
            for(Case c : caseList){
                for(Account a : accMap.values()){
                    if(c.AccountId != a.Id) continue;
                    for(ServiceContract sc : scList){
                        if(a.Root_Account__c != sc.AccountId) continue;
                        if(sc.Service_Type__c == c.Service_Type__c && sc.Country__c == a.ShippingCountry){
                            c.ServiceContractId = sc.Id;
                        }
                    }
                }
            }
        }
    }

    public static void caseFieldUpdate(List<Case> caseList) {
        for (Case c : caseList) {
            if (!String.isBlank(c.Root_Account_Name__c) && c.Root_Account_Name__c.containsIgnoreCase('TGI Friday')) {
                c.PO_Number__c = c.Incident__c;
            }
        }
    }

    public static void caseFieldUpdateFromETA(List<Case> caseList) {
        Set<Id> equipmentTypeIds = new Set<Id>();
        for (Case caseRecord : caseList) {  
            if (caseRecord.Equipment_Type__c != null) {
                equipmentTypeIds.add(caseRecord.Equipment_Type__c);
            } 
            if(caseRecord.Preferred_Time__c != null) {
                caseRecord.Start_Date__c = caseRecord.Preferred_Time__c;
            }
        }

        Map<Id, Equipment_Type_For_Account__c> equipmentTypeMap = new Map<Id, Equipment_Type_For_Account__c>([SELECT Id, Out_of_Scope__c, Equipment_Type__c FROM Equipment_Type_For_Account__c WHERE Equipment_Type__c IN :equipmentTypeIds]);
        
        System.debug('equipmentTypeMap-->' + JSON.serialize(equipmentTypeMap));
        
        for (Case caseRecord : caseList) {
            System.debug('caseRecord.Equipment_Type__c-->' + caseRecord.Equipment_Type__c);
            for (Equipment_Type_For_Account__c equipmentTypeRecord : equipmentTypeMap.values()) {
                if (equipmentTypeRecord.Equipment_Type__c == caseRecord.Equipment_Type__c) {
                    if (equipmentTypeRecord.Out_of_Scope__c == true) {
                        caseRecord.Out_of_Scope__c = true;
                    }
                }
            }
        }
    }   
    
    public static void handleCaseCreation(List<Case> caseList) {
        Set<Id> serviceContractIds = new Set<Id>();
        for (Case c : caseList) {                   
            if (c.ServiceContractId != null && !c.Include_Part__c) { 
                serviceContractIds.add(c.ServiceContractId);
            }
        }
        
        if (!serviceContractIds.isEmpty()) {
            Map<Id, ServiceContract> serviceContracts = new Map<Id, ServiceContract>(
                [SELECT Id, Work_Order_Record_Type__c,(SELECT Id, Product2.Name, Priority__c, Product2Id FROM ContractLineItems) FROM ServiceContract WHERE Id IN :serviceContractIds]);

            for (Case c : caseList) {
                ServiceContract serviceContract = serviceContracts.get(c.ServiceContractId);

                if (serviceContract != null && serviceContract.Work_Order_Record_Type__c == 'Onsite Labor') {                    
                    ContractLineItem matchingItem = null;
                    for (ContractLineItem cli : serviceContract.ContractLineItems) {
                        if (cli.Priority__c == c.Priority) {
                            matchingItem = cli;
                            break;
                        }
                    }

                    if (matchingItem != null) {
                        c.ProductId = matchingItem.Product2Id;
                    } else if (!serviceContract.ContractLineItems.isEmpty()) {
                        c.ProductId = serviceContract.ContractLineItems[0].Product2Id;
                    }
                }
            }
        }
    }  
    
    public static void createCaseContactRoles(List<Case> caseList) {
        List<Contact> conList = [SELECT Id FROM Contact WHERE Include_in_3hr_4hr_Alerts__c = true];
        List<CaseContactRole> ccrList = new List<CaseContactRole>();
        for(Contact c : conList) {
            for(Case c1 : caseList) {
                CaseContactRole ccr = new CaseContactRole(CasesId = c1.Id, ContactId = c.Id, Role = 'Business Contact');
                ccrList.add(ccr);
            }
        }
        insert ccrList;
    }

    /*public static void completeMilestones(List<Case> cList) {
        Set<String> statuses = new Set<String>();
        Set<Id> caseIds = new Set<Id>();
        for(Case c : cList) {
            statuses.add(c.Status);
            caseIds.add(c.Id);
        }

        List<CaseMilestone> cmsToUpdate = [SELECT Id, CaseId, MilestoneType.Name, completionDate
            FROM CaseMilestone cm
            WHERE caseId IN :caseIds AND cm.MilestoneType.Name IN :statuses 
            AND completionDate = null];

        for(Case c : cList) {
            for(CaseMilestone cm : cmsToUpdate) {
                if(c.Id == cm.CaseId && cm.MilestoneType.Name == c.Status) {
                    cm.completionDate = c.LastModifiedDate;
                }
            }
        }

        update cmsToUpdate;
    }*/

    private static void assignSLAExitDate(List<Case> caseList) {
        List<Case> slaCases = new List<Case>();
        List<Case> aldiSLACases = new List<Case>();
        for(Case c : caseList) {
            if(!String.isBlank(c.Account_Name_For_Search__c) && c.Account_Name_For_Search__c.containsIgnoreCase('ALDI')){
                aldiSLACases.add(c);
            } else if(c.Service_Type__c == 'Onsite Labor Only' || c.Service_Type__c == 'Advance Exchange + Onsite' 
                || c.Service_Type__c == 'Onsite Break-Fix' || c.Service_Type__c == 'Advance Exchange (Depot Only)' 
                || c.Preferred_Time__c != null){
                slaCases.add(c);
            }
        }
        if(!aldiSLACases.isEmpty()) {
            CaseSLACalculator.assignSALEndDatetime(aldiSLACases);
        }
        if(!slaCases.isEmpty()) {
            ASCENACaseMilestoneCalculater.assignSALEndDatetime(slaCases);
        }
    }

    //Using Future method to avoid 101 Error
    //Called from CreateOnistePartWO invocable class to get parentWOId so it is called after all WOs are created.
    @future
    public static void createOnsitePartWO(Set<Id> caseIdsFromFlow) {
        List<WorkOrder> woList = new List<WorkOrder>();
        Map<Id,Case> caseMap = new Map<Id,Case>([SELECT Id,Equipment_Type__c,Problem_Type__c,Department2__c,CreatedById,CreatedBy.Name,Support_Team__r.Name,Out_Of_Scope__c,Service_Type__c,Include_Part__c,
                                                 ContactId,Department__c,POS_Register_Number__c,Product_Quantity__c,Incident__c,OwnerId,Priority,
                                                 PO_Number__c,Description,AccountId,ProductId,Project__c,Tech_Notes__c,Account.ShippingStreet,
                                                 Account.ShippingState,Account.ShippingCity,Account.ShippingCountry,Account.ShippingPostalCode,
                                                 Root_Account__c,ServiceContractId,(SELECT Product__c,Product__r.Name, Quantity__c 
                                                 FROM Case_Products__r) FROM Case WHERE ID IN:caseIdsFromFlow]);
        System.debug('caseMap for Part WO-> ' + caseMap);
        List<WorkOrder> childWorkOrderList = [SELECT Id,CaseId,ParentWorkOrderId FROM WorkOrder WHERE Additional_Part_WO__c = false 
                                              AND Case.ServiceContract.Single_WO_For_Billing__c = true AND ParentWorkOrderId != null AND CaseId IN: caseMap.keySet()];
        Map<Id,Id> caseParentWOMap = new Map<Id,Id>();
        for(WorkOrder wo : childWorkOrderList){
            if(caseParentWOMap.containsKey(wo.CaseId)) continue;
            caseParentWOMap.put(wo.caseId,wo.ParentWorkOrderId);
        }
        Id scId = caseMap.values()[0].ServiceContractId;
        Map<Id,ServiceContract> scMap = new Map<Id,ServiceContract>([SELECT Id,Name,FN_Template_ID__c,Include_Part__c,Priority__c,
                                                                     Work_Order_Record_Type__c,Country__c,Pricebook2Id,
                                                                     (SELECT Id,Work_Order_Record_Type__c,FN_Template_ID__c FROM ChildServiceContracts),
                                                                     (SELECT Id,Include_In_WO_Type__c,Product2Id,Product2.Family,Product2.Name,
                                                                     Product2.Description,UnitPrice,Quantity,ServiceContractId FROM ContractLineItems 
                                                                     WHERE Product2.Family = 'Hardware' OR Include_In_WO_Type__c = 'Part Shipment') FROM ServiceContract WHERE Id =: scId]);
        System.debug('scMap for Part WO-> ' + scMap);
        Set<Id> serviceCLIsToMoveIds = new Set<Id>();
        for(ServiceContract sc : scMap.values()){
            for(ContractLineItem cli : sc.ContractLineItems){
                if(cli.Include_In_WO_Type__c == 'Part Shipment'){
                    serviceCLIsToMoveIds.add(cli.Id);
                }
            }
        }
        Id partShipRT = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Part_Shipment').getRecordTypeId();
        for(Case c : caseMap.values()){
            if(c.ServiceContractId == null) continue;
            if(!scMap.containsKey(c.ServiceContractId)) continue;
            ServiceContract sc = scMap.get(c.ServiceContractId);
            if((sc.Work_Order_Record_Type__c == 'Part Shipment' || sc.Work_Order_Record_Type__c == 'Advance Exchange + Onsite' || sc.Work_Order_Record_Type__c == 'Production')) continue;
            List<Case_Product__c> caseProdsList = caseMap.get(c.Id).Case_Products__r;
            if(caseProdsList.isEmpty() && serviceCLIsToMoveIds.isEmpty()) continue;
            
            List<ContractLineItem> cliList = sc.ContractLineItems;
            boolean woExist = false;
            Id woId;
            if(caseParentWOMap.containsKey(c.Id)){
                woId = caseParentWOMap.get(c.Id);
            }
            if(cliList.size() != 0 && !sc.ChildServiceContracts.isEmpty()){
                System.debug('Has CLI AND Child CLI Hardware Product');
                WorkOrder wo = new WorkOrder();
                wo.RecordTypeId = partShipRT;
                wo.AccountId = c.AccountId;
                wo.Pricebook2Id = sc.Pricebook2Id;
                wo.Product__c = c.ProductId;
                wo.ServiceContractId = sc.Id;
                wo.Service_Type__c = c.Service_Type__c;
                wo.CaseId = c.Id;
                wo.Incident__c = c.Incident__c;
                wo.FN_Template_ID__c = sc.FN_Template_ID__c;
                wo.Description = c.Description;
                wo.PO__c = c.PO_Number__c;
                wo.Priority = c.Priority;
                wo.OwnerId = c.OwnerId;
                wo.Department__c = c.Department__c;
                wo.Equipment_Type__c = c.Equipment_Type__c;
                wo.Problem_Type__c = c.Problem_Type__c;
                wo.Department2__c = c.Department2__c;
                wo.POS_Register_Number__c = c.POS_Register_Number__c;
                wo.Product_Quantity__c = c.Product_Quantity__c;
                wo.City = c.Account.ShippingCity;
                wo.ContactId = c.ContactId;
                wo.Country = c.Account.ShippingCountry;
                wo.PostalCode = c.Account.ShippingPostalCode;
                wo.State = c.Account.ShippingState;
                wo.Street = c.Account.ShippingStreet;
                wo.Tech_Notes__c = c.Tech_Notes__c;
                wo.Project__c = c.Project__c;
                wo.Additional_Part_WO__c = true;
                if(woId != null){
                    wo.ParentWorkOrderId = woId;
                }
                woList.add(wo);
                woExist = true;
            } else if(cliList.size() != 0){
                if(sc.ChildServiceContracts.isEmpty()){
                    System.debug('Has CLI Hardware Product');
                    WorkOrder wo = new WorkOrder();
                    wo.RecordTypeId = partShipRT;
                    wo.AccountId = c.AccountId;
                    wo.Pricebook2Id = sc.Pricebook2Id;
                    wo.Product__c = c.ProductId;
                    wo.ServiceContractId = sc.Id;
                    wo.Service_Type__c = c.Service_Type__c;
                    wo.CaseId = c.Id;
                    wo.Incident__c = c.Incident__c;
                    wo.FN_Template_ID__c = sc.FN_Template_ID__c;
                    wo.Description = c.Description;
                    wo.PO__c = c.PO_Number__c;
                    wo.Priority = c.Priority;
                    wo.OwnerId = c.OwnerId;
                    wo.Department__c = c.Department__c;
                    wo.Equipment_Type__c = c.Equipment_Type__c;
                    wo.Problem_Type__c = c.Problem_Type__c;
                    wo.Department2__c = c.Department2__c;
                    wo.POS_Register_Number__c = c.POS_Register_Number__c;
                    wo.Product_Quantity__c = c.Product_Quantity__c;
                    wo.City = c.Account.ShippingCity;
                    wo.ContactId = c.ContactId;
                    wo.Country = c.Account.ShippingCountry;
                    wo.PostalCode = c.Account.ShippingPostalCode;
                    wo.State = c.Account.ShippingState;
                    wo.Street = c.Account.ShippingStreet;
                    wo.Tech_Notes__c = c.Tech_Notes__c;
                    wo.Project__c = c.Project__c;
                    wo.Additional_Part_WO__c = true;
                    if(woId != null){
                        wo.ParentWorkOrderId = woId;
                    }
                    woList.add(wo);
                    woExist = true;
                }
            } else if(!sc.ChildServiceContracts.isEmpty()){
                List<ServiceContract> scChildList = sc.ChildServiceContracts;
                boolean partWo = true;
                for(ServiceContract sc2 : scChildList){
                    if(sc2.Work_Order_Record_Type__c == 'Part shipment' || sc2.Work_Order_Record_Type__c == 'Advance Exchange + Onsite' || 
                        sc2.Work_Order_Record_Type__c == 'Production'){
                        partWo = false;
                    }
                }
                if(!partWo) continue;
                System.debug('Child SC Has CLI Hardware Product');
                WorkOrder wo = new WorkOrder();
                wo.RecordTypeId = partShipRT;
                wo.AccountId = c.AccountId;
                wo.Pricebook2Id = sc.Pricebook2Id;
                wo.Product__c = c.ProductId;
                wo.ServiceContractId = sc.Id;
                wo.Service_Type__c = c.Service_Type__c;
                wo.CaseId = c.Id;
                wo.Incident__c = c.Incident__c;
                wo.FN_Template_ID__c = sc.FN_Template_ID__c;
                wo.Description = c.Description;
                wo.PO__c = c.PO_Number__c;
                wo.Priority = c.Priority;
                wo.OwnerId = c.OwnerId;
                wo.Department__c = c.Department__c;
                wo.Equipment_Type__c = c.Equipment_Type__c;
                wo.Problem_Type__c = c.Problem_Type__c;
                wo.Department2__c = c.Department2__c;
                wo.POS_Register_Number__c = c.POS_Register_Number__c;
                wo.Product_Quantity__c = c.Product_Quantity__c;
                wo.City = c.Account.ShippingCity;
                wo.ContactId = c.ContactId;
                wo.Country = c.Account.ShippingCountry;
                wo.PostalCode = c.Account.ShippingPostalCode;
                wo.State = c.Account.ShippingState;
                wo.Street = c.Account.ShippingStreet;
                wo.Tech_Notes__c = c.Tech_Notes__c;
                wo.Project__c = c.Project__c;
                wo.Additional_Part_WO__c = true;
                if(woId != null){
                    wo.ParentWorkOrderId = woId;
                }
                woList.add(wo);
                woExist = true;
            }
            if(c.Include_Part__c == true && woExist == false && c.Case_Products__r.size() != 0){
                //This is not additional part WO which is created based on CLI hardware product.
                //wo.Additional_Part_WO__c = true to avoid creating Service product WOLIs in this WO.
                WorkOrder wo = new WorkOrder();
                wo.RecordTypeId = partShipRT;
                wo.AccountId = c.AccountId;
                wo.Pricebook2Id = sc.Pricebook2Id;
                wo.Product__c = c.ProductId;
                wo.ServiceContractId = sc.Id;
                wo.Service_Type__c = c.Service_Type__c;
                wo.CaseId = c.Id;
                wo.Incident__c = c.Incident__c;
                wo.FN_Template_ID__c = sc.FN_Template_ID__c;
                wo.Description = c.Description;
                wo.PO__c = c.PO_Number__c;
                wo.Priority = c.Priority;
                wo.OwnerId = c.OwnerId;
                wo.Department__c = c.Department__c;
                wo.Equipment_Type__c = c.Equipment_Type__c;
                wo.Problem_Type__c = c.Problem_Type__c;
                wo.Department2__c = c.Department2__c;
                wo.POS_Register_Number__c = c.POS_Register_Number__c;
                wo.Product_Quantity__c = c.Product_Quantity__c;
                wo.City = c.Account.ShippingCity;
                wo.ContactId = c.ContactId;
                wo.Country = c.Account.ShippingCountry;
                wo.PostalCode = c.Account.ShippingPostalCode;
                wo.State = c.Account.ShippingState;
                wo.Street = c.Account.ShippingStreet;
                wo.Tech_Notes__c = c.Tech_Notes__c;
                wo.Project__c = c.Project__c;
                wo.Additional_Part_WO__c = true;
                if(woId != null){
                    wo.ParentWorkOrderId = woId;
                }
                woList.add(wo);
            }
        }
        System.debug('Part woList size-> ' + woList.size());
        Set<Id> pbIds = new Set<Id>();
        Set<Id> caseIds = new Set<Id>();
        Set<Id> woIds = new Set<Id>();
        if(woList.size() != 0){
            insert woList;
            for(WorkOrder wo : woList){
                woIds.add(wo.Id);
                caseIds.add(wo.CaseId);
                pbIds.add(wo.Pricebook2Id);
            }
            List<Case> csList =  [SELECT Account.ShippingCountry,Root_Account__c,Include_Part__c,ServiceContractId,Staging_Required_Count__c,
                                  (SELECT Product__c,Product__r.Name, Quantity__c,CLI_Product__c FROM Case_Products__r), 
                                  (SELECT Id,Priority,Case.Root_Account__r.Staging_Product__r.Name,PriceBook2Id FROM WorkOrders WHERE Id IN: woIds)FROM Case WHERE ID IN :caseIds];
            System.debug('csList size-> ' + csList.size());
            
            Set<Id> caseProdIds = new Set<Id>();
            for(Case c : csList){
                for(Case_Product__c cp : c.Case_Products__r) {
                    caseProdIds.add(cp.Product__c);
                }
            }
            List<ContractLineItem> cliList = [SELECT Id,Priority__c,Include_In_WO_Type__c,Product2Id,Product2.Family,Product2.Name,Product2.Description,UnitPrice,Quantity,Description,
                                                ServiceContractId,ServiceContract.ParentServiceContractId FROM ContractLineItem 
                                                WHERE (ServiceContractId =:scId OR ServiceContract.ParentServiceContractId =: scId)];
            System.debug('caseProdIds:'+caseProdIds);
            for(ContractLineItem cli : cliList){
                caseProdIds.add(cli.Product2Id);
            }
            List<Product_Bundle__c> prodBundleList = [SELECT Child_Product__c FROM Product_Bundle__c ];
            for(Product_Bundle__c pb : prodBundleList){
                if(caseProdIds.contains(pb.Child_Product__c)){
                    //caseProdIds.remove(pb.Child_Product__c);
                }
            }
            List<PricebookEntry> pbeList = [SELECT Id,Product2Id,Product2.Description,Product2.Name,UnitPrice,Product2.Staging_Required__c FROM PricebookEntry
                                            WHERE Product2Id IN :caseProdIds AND Pricebook2Id iN :pbIds AND isActive = true AND Product2.source_key__c != null];
            List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
            Map<Id,WorkOrderLineItem> woliMap = new Map<Id,WorkOrderLineItem>();
            
            integer stagingProdCount = 0;
            for(Case c :csList){
                for(WorkOrder wo : c.WorkOrders){
                    Id woId = wo.Id;
                    Id childWO;
                    if(caseParentWOMap.containsKey(c.Id)){
                        woId = caseParentWOMap.get(c.Id);
                        childWO = wo.Id;
                    }
                    Set<Id> prodIds = new Set<Id>();
                    for(ContractLineItem cli : cliList){
                        if(!String.isBlank(cli.Priority__c) && cli.Priority__c != wo.Priority) continue;
                        System.debug('CLI Id-> ' + cli.Id);
                        if(cli.Include_In_WO_Type__c == 'Onsite Labor') continue;
                        for(Case_Product__c cp : c.Case_Products__r) {
                            if(cli.Product2.Family != 'Hardware') continue;
                            System.debug('Processing CLI Hardware Product');
                            for(PricebookEntry pbe : pbeList) {
                                Decimal price = pbe.UnitPrice;
                                String description = cli.Product2.Description;
                                if(cli.UnitPrice != null && cli.UnitPrice != 0){
                                    price = cli.UnitPrice;
                                }
                                if(String.isNotBlank(cli.Description)){
                                    description = cli.Description;
                                }
                                System.debug('PBE Product-> '+pbe.Product2.Name + 'pbe.Product2Id-> ' + pbe.Product2Id);
                                System.debug('cp.Product__r.Name-> ' + cp.Product__r.Name + 'cp.Product__c-> ' + cp.Product__c);
                                System.debug('cli.Product2.Name-> ' + cli.Product2.Name + 'cli.Product2Id-> ' + cli.Product2Id);
                                System.debug('Different product? -> ' + ((cli.Product2Id != cp.Product__c) && (cp.Product__c != pbe.Product2Id)));
                                if(cli.Product2Id != cp.Product__c) continue;
                                if(cp.Product__c != pbe.Product2Id) continue;
                                if(prodIds.contains(pbe.Product2Id)) continue;
                                WorkOrderLineItem woli = new WorkOrderLineItem(PricebookEntryId = pbe.Id,UnitPrice = price,Quantity = cp.Quantity__c, WorkOrderId = woId,Description = description,Child_WO__c = childWO);
                                woliList.add(woli);
                                prodIds.add(cli.Product2Id);
                                System.debug('Part WOLI Created With Product-> ' + cli.Product2.Name);
                                System.debug('woliList-> ' + JSON.Serialize(woliList));
                                if(pbe.Product2.Staging_Required__c) {
                                    stagingProdCount++;
                                }
                                break;
                            }
                        }
                        if(cli.Include_In_WO_Type__c == 'Part Shipment'){
                            for(PricebookEntry pbe : pbeList) {
                                if(cli.Product2Id != pbe.Product2Id) continue;
                                if(prodIds.contains(cli.Product2Id)) continue;
                                Decimal price = pbe.UnitPrice;
                                Decimal quantity = 1;
                                String description = cli.Product2.Description;
                                if(cli.Quantity != null && cli.Quantity != 0){
                                    quantity = cli.Quantity;
                                }
                                if(cli.UnitPrice != null && cli.UnitPrice != 0){
                                    price = cli.UnitPrice;
                                }
                                if(String.isNotBlank(cli.Description)){
                                    description = cli.Description;
                                }
                                System.debug('cli.Product2.Name-> ' + cli.Product2.Name + 'cli.Product2Id-> ' + cli.Product2Id);
                                WorkOrderLineItem woli = new WorkOrderLineItem(PricebookEntryId = pbe.Id,UnitPrice = price,Quantity = quantity, WorkOrderId = woId,Description = description,Child_WO__c = childWO);
                                woliList.add(woli);
                                prodIds.add(cli.Product2Id);
                                System.debug('Service Product WOLI Created-> ' + cli.Product2.Name);
                                System.debug('woliList-> ' + JSON.Serialize(woliList));
                                if(pbe.Product2.Staging_Required__c) {
                                    stagingProdCount++;
                                }
                            }
                        }
                    }
                    //WOLIs for onsite WO based on Include Part.
                    //OR WOLI for Manually added H/W products.
                    if(c.Include_Part__c == true || c.Case_Products__r.size() != 0){
                        for(Case_Product__c cp : c.Case_Products__r) {
                            for(PricebookEntry pbe : pbeList) {
                                if(cp.Product__c != pbe.Product2Id) continue;
                                if(prodIds.contains(pbe.Product2Id)) continue;
                                WorkOrderLineItem woli = new WorkOrderLineItem(PricebookEntryId = pbe.Id,UnitPrice = pbe.UnitPrice,Quantity = cp.Quantity__c, WorkOrderId = woId,Description = pbe.Product2.Description,Child_WO__c = childWO);
                                woliList.add(woli);
                                prodIds.add(pbe.Product2Id);
                                System.debug('Include Part/Manually added Product WOLI Created-> ' + cp.Product__r.Name);
                                System.debug('woliList-> ' + JSON.Serialize(woliList));
                                if(pbe.Product2.Staging_Required__c) {
                                    stagingProdCount++;
                                }
                            }
                        }
                    }
                    if(stagingProdCount > 0) {
                        System.debug('wo.Case.Root_Account__r.Staging_Product__r.Name-> ' + wo.Case.Root_Account__r.Staging_Product__r.Name);
                        if(String.isNotBlank(wo.Case.Root_Account__r.Staging_Product__r.Name)) {
                            List<PricebookEntry> stagingPBEList = [SELECT Id,Product2Id,UnitPrice,Product2.Description FROM PricebookEntry WHERE Product2.Staging_Required__c = true AND PriceBook2Id =: wo.PriceBook2Id AND Product2.Name =: wo.Case.Root_Account__r.Staging_Product__r.Name AND isActive = true AND Product2.source_key__c != null];
                            if(!stagingPBEList.isEmpty()) {
                                //if(!woIdProdIdMap.contains(stagingPBEList[0].Product2Id)){}
                                WorkOrderLineItem woli = new WorkOrderLineItem(PricebookEntryId = stagingPBEList[0].Id, Quantity = c.Staging_Required_Count__c, WorkOrderId = woId, UnitPrice = stagingPBEList[0].UnitPrice,Child_WO__c = childWO, Description = stagingPBEList[0].Product2.Description);
                                woliList.add(woli);
                            }
                        }
                    }
                }
            }
            System.debug('woliList size (CaseTriggerHandler)-> ' + woliList.size());
            if(woliList.size() != 0){
                Database.insert(woliList, false);
            }
        }
    }
}