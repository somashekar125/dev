public without sharing class WorkOrderTriggerHandler {
    public static boolean runOnceBeforeUpdate = true;
    public static boolean runOnceAfterUpdate = true;
    public static void handleBeforeInsert(List<WorkOrder> woList) {
        createCaseThreadId(woList);
        techOnsiteETAStringToDateTime(woList);
        assignBusinessHours(woList);
        adjustDueDates(woList);
        OnCreateWOupdateFlow(woList);
        populatePreferredTimeFromProjectAccount(woList);
        woFieldsUpdates(null,null,woList,true);
        //WorkOrderTriggerHandler.setStatusChangeMailDate(woList);
    }

    public static void handleAfterInsert(List<WorkOrder> woList) {
        //createWOLIforBundleProds(woList);
        Map<Id,WorkOrder> newMap = new Map<Id,WorkOrder>(woList);
        //updateStatusesAftInsert(woList);
        createReminderEvents(woList);
        createWOLIFromCLIs(woList);
        woToCaseAndParentWOUpdates(newMap ,null);
        
    }
    
    public static void handleBeforeUpdate(Map<Id, WorkOrder> newMap, Map<Id, WorkOrder> oldMap) {
        if(!runOnceBeforeUpdate) return;
        createCaseThreadId(newMap.values());
        woFieldsUpdates(newMap,oldMap,null,false);
        closingProcess(newMap,oldMap);
        techOnsiteETAStringToDateTime(newMap.values());
        for(WorkOrder wo : newMap.values()){
            if(wo.SC_WORecordType__c == 'Onsite Labor' && wo.Check_Out_Time__c != null && wo.Check_Out_Time__c != wo.Date_Work_Completed__c){
                wo.Date_Work_Completed__c = wo.Check_Out_Time__c.date();
            }
            if(String.isBlank(wo.Outbound_Tracking_Number_Status__c)) continue;
            wo.Outbound_Tracking_Number_Status__c = wo.Outbound_Tracking_Number_Status__c.toUppercase();
        }
        Map<Id,Event> eMap = handleTechCheckIn(newMap, oldMap);
        Map<Id,WorkOrder> woMap = new Map<Id,WorkOrder>([SELECT Id,latitude,longitude,
                                                        (SELECT Id,WhatId,StartDateTime,EndDateTime,Subject,
                                                        Check_In_Lat_Lon__latitude__s,Check_In_Lat_Lon__longitude__s FROM Events
                                                        WHERE Subject = 'Technician Working' Order By createddate desc limit 1) 
                                                        FROM WorkOrder WHERE Id IN :newMap.keySet()]);
        handleTechCheckOut(newMap, oldMap,eMap,woMap);
        handleCheckInLocation(newMap, oldMap,eMap,woMap);
        handleCheckOutLocation(newMap, oldMap,eMap,woMap);
        Database.insert(eMap.values(),false);
        createWOTimeEntries(newMap, oldMap);
        adjustDueDates(newMap.values());
        woFieldsUpdates2(newMap, oldMap);
        updateStatuses(newMap, oldMap);
        runOnceBeforeUpdate = false;
    }

    public static void handleAfterUpdate(Map<Id, WorkOrder> newMap, Map<Id, WorkOrder> oldMap) {
        if(!runOnceAfterUpdate) return;
        woToCaseAndParentWOUpdates(newMap, oldMap);
        createWOLIOnApproval(newMap, oldMap);
        createHourlyWOLIs(newMap, oldMap);
        if(!System.isFuture() && !System.isBatch()){
            approvalComments(JSON.serialize(newMap));
        }
        woSubmitForApproval(newMap, oldMap);
        handleOutOfScope(newMap, oldMap);
        runOnceAfterUpdate = false;
        //createServiceAppointments(newMap, oldMap);
        //cancelChildWOandCase(newMap, oldMap);
    }

    public static void handleOutOfScope(Map<Id, WorkOrder> newMap, Map<Id, WorkOrder> oldMap) {
        Set<Id> workOrderIds = new Set<Id>();
        for (Id woId : newMap.keySet()) {
            WorkOrder newWo = newMap.get(woId);
            WorkOrder oldWo = oldMap.get(woId);
            if (oldWo.OutofScope__c == false && newWo.OutofScope__c == true && newWo.Out_of_Scope_Reason__c != null) {
                workOrderIds.add(woId);
            }
        }
        List<WorkOrderLineItem> workOrderLineItems = [SELECT Id, PricebookEntryId, PricebookEntry.Out_of_Scope_Price__c FROM WorkOrderLineItem WHERE WorkOrderId IN :workOrderIds];
        List<WorkOrderLineItem> workOrderLineItemsToUpdate = new List<WorkOrderLineItem>();
        for (WorkOrderLineItem woli : workOrderLineItems) {
            if (woli.PricebookEntry.Out_of_Scope_Price__c != null) {
                woli.UnitPrice = woli.PricebookEntry.Out_of_Scope_Price__c;
                workOrderLineItemsToUpdate.add(woli);
            }
        }
        if (!workOrderLineItemsToUpdate.isEmpty()) {
            update workOrderLineItemsToUpdate;
        }
    }
    
    public static void populatePreferredTimeFromProjectAccount(List<WorkOrder> woList){
        Set<Id> serviceContractIds = new Set<Id>();
        Set<Id>projectIds = new Set<Id>();
        for(WorkOrder wo : woList){
            if(wo.Preferred_Time_IMAC__c != null || wo.Project__c == null) continue;
            serviceContractIds.add(wo.serviceContractId);
            projectIds.add(wo.Project__c);
        }
        Map<Id, ServiceContract> serviceContractMap = new Map<Id, ServiceContract>([SELECT Id,Visit_Order__c FROM ServiceContract WHERE Id IN : serviceContractIds]);
        System.debug('Service->' + JSON.serialize(serviceContractMap));
        List<Project_Account__c> projAccList = new List<Project_Account__c>();
        if (!projectIds.isEmpty()) {
            projAccList = [SELECT Id, Name,Account__c,Project__c,Visit_1__c,Visit_2__c,Visit_3__c FROM Project_Account__c WHERE Project__c IN: projectIds];
        }

        for(WorkOrder wo: woList){
            if(wo.Preferred_Time_IMAC__c != null || wo.Project__c == null) continue;
            if (!serviceContractMap.containsKey(wo.ServiceContractId)) continue;
            ServiceContract sc = serviceContractMap.get(wo.ServiceContractId);
            for (Project_Account__c pa : projAccList) {
                if(pa.Project__c != wo.Project__c || pa.Account__c != wo.AccountId) continue;
                
                if (sc.Visit_Order__c == 'Visit 1') {
                    wo.Preferred_Time_IMAC__c = pa.Visit_1__c;
                } else if (sc.Visit_Order__c == 'Visit 2') {
                    wo.Preferred_Time_IMAC__c = pa.Visit_2__c;
                } else if (sc.Visit_Order__c == 'Visit 3') {
                    wo.Preferred_Time_IMAC__c = pa.Visit_3__c;
                } else {
                    if(pa.Visit_3__c != null){
                        wo.Preferred_Time_IMAC__c = pa.Visit_3__c;
                    } else if(pa.Visit_2__c != null){
                        wo.Preferred_Time_IMAC__c = pa.Visit_2__c;
                    } else if(pa.Visit_1__c != null){
                        wo.Preferred_Time_IMAC__c = pa.Visit_1__c;
                    }
                }
            }
        } 
    }

    public static void createCaseThreadId(List<WorkOrder> woList) {
        for(WorkOrder wo : woList){
            if(wo.CaseId == null) continue;
            if(!String.isBlank(wo.Case_Thread_Id__c)) continue;
            String caseId = wo.CaseId;
            String Case_ThreadID = 'ref:_'
            + UserInfo.getOrganizationId().left(5)
            + UserInfo.getOrganizationId().mid(10,5) + '._' //For Sandbox-> mid(11,4)
            + caseId.left(5)
            + caseId.mid(9,6) + ':ref'; //For Sandbox-> mid(10,5)
            // prod org -> 00D6g000007RD9gEAG
            // sb org   -> 00D040000008jmxEAA
            // caseId   -> 5000400000B676NAAR
            // exmaple-> ref:_00D6g7RD9g._5004v23Gf6I:ref
            wo.Case_Thread_Id__c = Case_ThreadID;
        }
    }

    public static void woFieldsUpdates(Map<Id, WorkOrder> newMap, Map<Id, WorkOrder> oldMap, List<WorkOrder> woList, Boolean IsBeforeInsert) {
        Set<Id> prodIds = new Set<Id>();
        Set<Id> mpIds = new Set<Id>();
        List<Global_Settings__c> gsList = [SELECT Id,FN_Markup__c FROM Global_Settings__c WHERE FN_Markup__c != null Order By LastModifiedDate Desc LIMIT 1];
        if(IsBeforeInsert){
            for(WorkOrder wo : woList){
                if(wo.Product__c != null && wo.No_Return_Shipment__c == false){
                    prodIds.add(wo.Product__c);
                }
                if(wo.MaintenancePlanId != null && wo.IsGeneratedFromMaintenancePlan == true && wo.Service_Type__c == null){
                    mpIds.add(wo.MaintenancePlanId);
                }
                if(wo.Preferred_Time_IMAC__c != null) {
                    wo.StartDate = wo.Preferred_Time_IMAC__c;
                    wo.Technician_OnSite_ETA__c = wo.Preferred_Time_IMAC__c;
                }
            }
        } else {
            Set<Id> serviceContractIds = new Set<Id>();
            Set<Id> projectAccIds = new Set<Id>();
            Boolean shouldUpdate = false;
            for (WorkOrder wo : newMap.values()) {
                if(wo.ServiceContractId != null) serviceContractIds.add(wo.ServiceContractId);
                if(wo.Project_Account__c != null) projectAccIds.add(wo.Project_Account__c);
            }
            Map<Id, ServiceContract> serviceContracts = new Map<Id, ServiceContract>([SELECT Id, Visit_Order__c FROM ServiceContract WHERE Id IN :serviceContractIds]);
            Map<Id, Project_Account__c> projectAccs = new Map<Id, Project_Account__c>([SELECT Id, Account__c, Project__c, Visit_1__c, Visit_2__c, Visit_3__c FROM Project_Account__c WHERE Id IN :projectAccIds]);

            for(WorkOrder wo : newMap.values()){               
                if(!gsList.isEmpty() && (wo.Billable_Expense_Total__c != oldMap.get(wo.Id).Billable_Expense_Total__c || wo.Total_Labor_Cost__c != oldMap.get(wo.Id).Total_Labor_Cost__c || 
                    wo.Labor_Cost__c != oldMap.get(wo.Id).Labor_Cost__c || wo.Materials_Cost__c != oldMap.get(wo.Id).Materials_Cost__c ||
                    wo.Equipment_Rental_Cost__c != oldMap.get(wo.Id).Equipment_Rental_Cost__c || wo.Logistics_Cost__c != oldMap.get(wo.Id).Logistics_Cost__c ||
                    wo.Total_Unit_Price__c != oldMap.get(wo.Id).Total_Unit_Price__c || wo.Status != oldMap.get(wo.Id).Status)){
                    Decimal BillableExpenseTotal = wo.Billable_Expense_Total__c;
                    if(wo.Billable_Expense_Total__c == null){
                        BillableExpenseTotal = 0;
                    }
                    wo.Billable_Expense_After_FN_Markup__c = (BillableExpenseTotal * (1 + (gsList[0].FN_Markup__c/100)));
                }
                if(wo.Previously_Closed__c == false && oldMap.get(wo.Id).Status == 'Closed' && wo.Status != oldMap.get(wo.Id).Status){
                    wo.Previously_Closed__c = true;
                }
                if(wo.WOLI_with_Issues__c > 0){
                    wo.Resolution_Code__c = 'COMPLETED WITH ISSUES';
                }
                if(wo.Technician_Status__c != oldMap.get(wo.Id).Technician_Status__c && wo.Technician_Status__c == 'Approved'){
                    wo.Approval_Requested_Date__c = System.now().date();
                }
                if(wo.Record_Type_Name__c == 'Part Ordering'){
                    wo.RecordTypeId = System.Label.Part_Request_WO_RT_Id;
                }
                if(wo.Product__c != null){
                    prodIds.add(wo.Product__c);
                }
                if (wo.Project_Account__c != null && wo.ServiceContractId != null && wo.StartDate != null && wo.StartDate != oldMap.get(wo.Id).StartDate && wo.Preferred_Time_IMAC__c != null) {
                    ServiceContract sc = serviceContracts.get(wo.ServiceContractId);
                    Project_Account__c projectAcc = projectAccs.get(wo.Project_Account__c);
                    
                    if (sc != null && projectAcc != null) {
                        if (sc.Visit_Order__c == 'Visit 1' && (projectAcc.Visit_1__c == null || projectAcc.Visit_1__c != wo.StartDate)) {
                            projectAcc.Visit_1__c = wo.StartDate;
                            shouldUpdate = true;
                        } else if (sc.Visit_Order__c == 'Visit 2' && (projectAcc.Visit_2__c == null || projectAcc.Visit_2__c != wo.StartDate)) {
                            projectAcc.Visit_2__c = wo.StartDate;
                            shouldUpdate = true;
                        } else if (sc.Visit_Order__c == 'Visit 3' && (projectAcc.Visit_3__c == null || projectAcc.Visit_3__c != wo.StartDate)) {
                            projectAcc.Visit_3__c = wo.StartDate;
                            shouldUpdate = true;
                        }
                    }
                }
            }
            if(shouldUpdate){
                ProjectAccountTriggerHandler.runOnceAfterUpdate = false;
                update projectAccs.values();
            }

            if(!prodIds.isEmpty()){
                Map<Id,Product2> prodMap = new Map<Id,Product2>([SELECT Id,No_Return_Shipment__c FROM Product2 WHERE Id IN:prodIds]);
                for(WorkOrder wo : newMap.values()){
                    if(wo.Product__c != null){
                        if(prodMap.get(wo.Product__c).No_Return_Shipment__c == true || wo.Service_Type__c == 'Part Request - No Return'){
                            wo.No_Return_Shipment__c = true;
                        } else {
                            wo.No_Return_Shipment__c = false;
                        }
                    }
                }
            }
        }
        if(IsBeforeInsert){
            Map<Id,Product2> prodMap = new Map<Id,Product2>();
            Map<Id,MaintenancePlan> mpMap = new Map<Id,MaintenancePlan>();
            if(!prodIds.isEmpty()){
                prodMap = new Map<Id,Product2>([SELECT Id,No_Return_Shipment__c FROM Product2 WHERE Id IN:prodIds]);
            }
            if(!mpIds.isEmpty()){
                mpMap = new Map<Id,MaintenancePlan>([SELECT Id,ServiceContractId,ServiceContract.Service_Type__c FROM MaintenancePlan 
                                                        WHERE Id IN:mpIds AND ServiceContractId != null]);
            }
            for(WorkOrder wo : woList){
                if(wo.Record_Type_Name__c == 'Part Ordering'){
                    wo.RecordTypeId = System.Label.Part_Request_WO_RT_Id;
                }
                if(wo.SC_WORecordType__c == 'Onsite Labor' && wo.Check_Out_Time__c != null && wo.Check_Out_Time__c != wo.Date_Work_Completed__c){
                    wo.Date_Work_Completed__c = wo.Check_Out_Time__c.date();
                }
                if(!String.isBlank(wo.Outbound_Tracking_Number_Status__c)){
                    wo.Outbound_Tracking_Number_Status__c = wo.Outbound_Tracking_Number_Status__c.toUppercase();
                }
                if(wo.WOLI_with_Issues__c > 0){
                    wo.Resolution_Code__c = 'COMPLETED WITH ISSUES';
                }
                if(!prodIds.isEmpty() && wo.Product__c != null){
                    if((prodMap.get(wo.Product__c).No_Return_Shipment__c == true || wo.Service_Type__c == 'Part Request - No Return')){
                        wo.No_Return_Shipment__c = true;
                    } else {
                        wo.No_Return_Shipment__c = false;
                    }
                }
                if(!mpIds.isEmpty() && wo.MaintenancePlanId != null && wo.IsGeneratedFromMaintenancePlan == true && wo.Service_Type__c == null){
                    wo.Service_Type__c = mpMap.get(wo.MaintenancePlanId).ServiceContract.Service_Type__c;
                }
                if(wo.Technician_Status__c != null){
                    if(wo.Technician_Status__c == 'Checked in' && (wo.StatusCategory == 'New' || wo.Status == 'Scheduling' || wo.Status == 'In Production' || wo.Status == 'Technician In Route')){
                        wo.Status = 'Tech Checked In';
                    }else if((wo.Technician_Status__c == 'Assigned' || wo.Technician_Status__c == 'Confirmed')){
                        wo.Status = 'Technician Scheduled / Assigned';
                    }else if(wo.Technician_Status__c == 'Cancelled' && (wo.StatusCategory != 'Closed' && wo.StatusCategory != 'Completed')){
                        wo.Status = 'Cancelled';
                    }
                }
                if(wo.FN_Status__c != null){
                    if((wo.FN_Status__c == 'Draft' || wo.FN_Status__c == 'Published' || wo.FN_Status__c == 'Routed') && (wo.StatusCategory == 'New')){
                        wo.Status = 'Scheduling';
                    }else if(wo.FN_Status__c == 'Assigned' && (wo.Status == 'New' || wo.Status == 'Acknowledged')){
                        wo.Status = 'Technician Scheduled / Assigned';
                    }else if(wo.FN_Status__c == 'Work Done' && (wo.StatusCategory != 'Closed' && wo.StatusCategory != 'Completed')){
                        wo.Status = 'Onsite Work Completed';
                    }
                }
            }
        }
    }
    
    public static void closingProcess(map<Id, WorkOrder> newMap, map<Id, WorkOrder> oldMap) {
        for (WorkOrder wo : newMap.values()) {
            if ((wo.Status != oldMap.get(wo.Id).Status && wo.Status == 'Closed') && wo.Closing_Process__c == false){
                wo.addError('Please go through the closing process by clicking the \'Close Work Order\' button to close this Work Order');
            } else if(wo.Closing_Process__c == true){
                wo.Closing_Process__c = false;
            }
        }
    }

    private static void assignBusinessHours(List<WorkOrder> woList) {
        List<BusinessHours> bhList = [SELECT Name FROM BusinessHours WHERE Name IN ('Part Shipment BH','Onsite for AE BH')];
        System.debug('bhList size-> ' + bhList.size() + ' - ' + 'woList size-> ' + woList.size());
        for(WorkOrder wo : woList) {
            if(wo.RecordTypeId == System.Label.Part_Request_WO_RT_Id) {
                for(BusinessHours bh : bhList) {
                    if(bh.Name == 'Part Shipment BH') {
                        wo.BusinessHoursId = bh.Id;
                    }
                }
            } else if(wo.RecordTypeId == System.Label.Onsite_Labor_WO_RT_Id && wo.Service_Type__c == 'Advance Exchange + Onsite') {
                for(BusinessHours bh : bhList) {
                    if(bh.Name == 'Onsite for AE BH') {
                        wo.BusinessHoursId = bh.Id;
                    }
                }
            }
           System.debug('wo.BusinessHoursId-> ' + wo.BusinessHoursId);
        }
    }

    public static void techOnsiteETAStringToDateTime(List<WorkOrder> woNewList){
        for(WorkOrder wo : woNewList){
            if(wo.Technician_OnSite_ETA_String__c != null){
                //2023-01-31T06:00:00+00:00
                String temp = wo.Technician_OnSite_ETA_String__c;
                if(temp.contains('+')){
                    temp = wo.Technician_OnSite_ETA_String__c.replaceAll('\\+',':');
                }
                String temp1 = temp;
                if(temp.contains('.')){
                    temp1 = temp.replaceAll('\\.',':');
                }
                //2023-01-31T06:00:00:00:00
                String tempDate = temp1.substringBefore('T'); //2023-01-31
                List<String> dateList = tempDate.split('-');
                Integer yr = Integer.valueOf(dateList[0]);
                Integer m = Integer.valueOf(dateList[1]);
                Integer d = Integer.valueOf(dateList[2]);

                String timeStr = temp1.substringAfter('T'); //06:00:00:00:00
                List<String> timeList = timeStr.split(':');
                Integer hr = Integer.valueOf(timeList[0]);
                Integer min = Integer.valueOf(timeList[1]);
                Integer sec = Integer.valueOf(timeList[2]);

                DateTime dt = DateTime.newInstance(Integer.valueOf(yr),Integer.valueOf(m),Integer.valueOf(d),Integer.valueOf(hr),Integer.valueOf(min),Integer.valueOf(sec));
                System.debug('DateTime-> ' + dt);
                wo.Technician_OnSite_ETA__c = dt;
            }
        }
    }

    public static void woToCaseAndParentWOUpdates(Map<Id, WorkOrder> newMap, Map<Id, WorkOrder> oldMap) {
        Set<Id> caseIds = new Set<Id>();
        Set<Id> parentWoIds = new Set<Id>();
        Set<Id> parentCaseIds = new Set<Id>();
        List<Case> caseUpdateList = new List<Case>();
        List<WorkOrder> woUpdateList = new List<WorkOrder>();
        Boolean isUpdate = true;
        if(oldMap == null){
            isUpdate = false;
        }
        if(isUpdate){
            for(WorkOrder wo : newMap.values()){
                if(wo.CaseId == null) continue;
                caseIds.add(wo.CaseId);
                if((wo.Status == 'Canceled') && wo.Status != oldMap.get(wo.Id).Status && wo.ParentWorkOrderId == null && wo.Service_Type__c == 'Advance Exchange + Onsite') {
                    parentWoIds.add(wo.Id);
                }
                if(wo.ParentWorkOrderId == null) continue;
                parentWoIds.add(wo.ParentWorkOrderId);
            }
        } else {
            for(WorkOrder wo : newMap.values()){
                if(wo.CaseId == null) continue;
                caseIds.add(wo.CaseId);
            }
        }
        System.debug('parentWoIds-> ' + parentWoIds);
        Map<Id,WorkOrder> parentWOMap = new Map<Id,WorkOrder>();
        if(!parentWoIds.isEmpty() && isUpdate == true){
            parentWOMap = new Map<Id,WorkOrder>([SELECT Id,Status,CaseId,Check_In_Time__c,Check_Out_Time__c ,Time_Entries__c,Resolution_Code__c,Resolution_Notes__c,
                                                ParentWorkOrderId FROM WorkOrder WHERE Id IN: parentWoIds]);
            for(WorkOrder wo : parentWOMap.values()){
                if(wo.ParentWorkOrderId != null) continue;
                parentCaseIds.add(wo.CaseId);
                System.debug('parentWO.Check_In_Time__c in wotoparent1-> ' + wo.Check_In_Time__c);
            }
        }
        if(!caseIds.isEmpty()){
            Map<Id,Case> caseMap = new Map<Id,Case>([SELECT Id, Status, Out_Of_Scope__c, Start_Date__c, Subject, Technician_Onsite_Start_Time__c, 
                                                    Technician_Onsite_Stop_Time__c , Site_Status__c,Technician_Status__c,SLA_Exception_Reason__c,SLA_Violated__c,
                                                    Resolution_Code__c,Resolution_Notes__c,Missed_SLA_Reason__c,Technician_OnSite_ETA__c,Technician_Name__c,
                                                    Technician_Phone__c,Onsite_Manager_Name__c,Netsuite_Integration_Error__c,WO_Sync_Failed__c,
                                                    Tracking_Numbers__c,(SELECT Id,Status,Record_Type_Name__c FROM WorkOrders) FROM Case WHERE Id IN :caseIds OR Id IN :parentCaseIds]);
            Set<Id> closingCasesIds = new Set<Id>();
            Set<Id> partPlusOnsitecaseIds = new Set<Id>();
            Set<Id> onlyPartcaseIds = new Set<Id>();
            Set<Id> onlyOnsitecaseIds = new Set<Id>();
            for(Case cs : caseMap.values()){
                Boolean isClosed = true;
                Set<String> recordTypeNames = new Set<String>();
                System.debug('cs.WorkOrders size-> ' + cs.WorkOrders.size());
                for(WorkOrder wo : cs.WorkOrders){
                    recordTypeNames.add(wo.Record_Type_Name__c);
                    if(wo.Status != 'Closed' && wo.Status != 'Onsite Work Completed'){
                        isClosed = false;
                    }
                }
                if(isClosed){
                    closingCasesIds.add(cs.Id);
                }
                System.debug('recordTypeNames-> ' + JSON.serialize(recordTypeNames));
                //Part + Onsite WOs present
                if(recordTypeNames.contains('Onsite Labor') && recordTypeNames.contains('Part Shipment')){
                    partPlusOnsitecaseIds.add(cs.Id);
                }
                //Only Part WOs present
                if(!recordTypeNames.contains('Onsite Labor') && recordTypeNames.contains('Part Shipment')){
                    onlyPartcaseIds.add(cs.Id);
                }
                //Only Onsite WOs present
                if(recordTypeNames.contains('Onsite Labor') && !recordTypeNames.contains('Part Shipment')){
                    onlyOnsitecaseIds.add(cs.Id);
                }
            }
            for(WorkOrder wo : newMap.values()){
                boolean updateCase = false;
                Boolean updatewo = false;
                if(wo.CaseId == null) continue;
                if(!caseMap.containsKey(wo.CaseId)) continue;
                Case c = caseMap.get(wo.CaseId);
                // Case Updates.
                if(wo.Subject != null && wo.Subject != c.Subject){
                    c.Subject = wo.Subject;
                    updateCase = true;
                }
                if(wo.SLA_Exception_Code__c != null && c.SLA_Exception_Reason__c != wo.SLA_Exception_Code__c){
                    c.SLA_Exception_Reason__c = wo.SLA_Exception_Code__c;
                    c.SLA_Violated__c = false;
                    updateCase = true;
                }
                if(wo.Missed_SLA_Reason__c != null && c.Missed_SLA_Reason__c != wo.Missed_SLA_Reason__c){
                    c.Missed_SLA_Reason__c = wo.Missed_SLA_Reason__c;
                    updateCase = true;
                }
                if(wo.Onsite_Manager_Name__c != null && c.Onsite_Manager_Name__c != wo.Onsite_Manager_Name__c){
                    c.Onsite_Manager_Name__c = wo.Onsite_Manager_Name__c;
                    updateCase = true;
                }
                if(c.Site_Status__c != wo.Site_Location_Status__c){
                    c.Site_Status__c = wo.Site_Location_Status__c;
                    updateCase = true;
                }
                if(wo.StartDate != null && wo.StartDate != c.Start_Date__c){
                    c.Start_Date__c = wo.StartDate;
                    updateCase = true;
                }
                if(wo.OutofScope__c == true && c.Out_Of_Scope__c == false) {
                    c.Out_Of_Scope__c = true;
                    updateCase = true;
                }
                System.debug('onlyOnsitecaseIds.contains(wo.CaseId)-> ' + onlyOnsitecaseIds.contains(wo.CaseId));
                System.debug('onlyPartcaseIds.contains(wo.CaseId)-> ' + onlyPartcaseIds.contains(wo.CaseId));
                System.debug('partPlusOnsitecaseIds.contains(wo.CaseId)-> ' + partPlusOnsitecaseIds.contains(wo.CaseId));
                System.debug('wo.Status-> ' + wo.Status);
                
                if((partPlusOnsitecaseIds.contains(wo.CaseId) && wo.Record_Type_Name__c == 'Onsite Labor') || (onlyPartcaseIds.contains(wo.CaseId) || onlyOnsitecaseIds.contains(wo.CaseId))) {
                    if(wo.Check_In_Time__c != null && wo.Check_In_Time__c != c.Technician_Onsite_Start_Time__c){
                        c.Technician_Onsite_Start_Time__c = wo.Check_In_Time__c;
                        updateCase = true;
                    }
                    if(wo.Check_Out_Time__c != null && wo.Check_Out_Time__c != c.Technician_Onsite_Stop_Time__c){
                        c.Technician_Onsite_Stop_Time__c = wo.Check_Out_Time__c;
                        updateCase = true;
                    }
                    if(wo.Resolution_Code__c != null && wo.Resolution_Code__c != c.Resolution_Code__c){
                        c.Resolution_Code__c = wo.Resolution_Code__c;
                        updateCase = true;
                    }
                    if(wo.Resolution_Notes__c != null && wo.Resolution_Notes__c != c.Resolution_Notes__c){
                        c.Resolution_Notes__c = wo.Resolution_Notes__c;
                        updateCase = true;
                    }
                    if(wo.Technician_OnSite_ETA__c != null && wo.Technician_OnSite_ETA__c != c.Technician_OnSite_ETA__c){
                        c.Technician_OnSite_ETA__c = wo.Technician_OnSite_ETA__c;
                        updateCase = true;
                    }
                    if(wo.Technician_Name__c != c.Technician_Name__c){
                        c.Technician_Name__c = wo.Technician_Name__c;
                        updateCase = true;
                    }
                    if(wo.Technican_Phone__c != c.Technician_Phone__c){
                        c.Technician_Phone__c = wo.Technican_Phone__c;
                        updateCase = true;
                    }
                    if(wo.Technician_Status__c != c.Technician_Status__c){
                        c.Technician_Status__c = wo.Technician_Status__c;
                        updateCase = true;
                    }
                }
                if(partPlusOnsitecaseIds.contains(wo.CaseId) && wo.Record_Type_Name__c == 'Part Shipment'){
                    if(String.isBlank(c.Resolution_Code__c) && !String.isBlank(wo.Resolution_Code__c)){
                        c.Resolution_Code__c = wo.Resolution_Code__c;
                        updateCase = true;
                    }
                    if(String.isBlank(c.Resolution_Notes__c) && !String.isBlank(wo.Resolution_Notes__c)){
                        c.Resolution_Notes__c = wo.Resolution_Notes__c;
                        updateCase = true;
                    }
                }
                if(wo.Netsuite_Integration_Error__c != null || wo.NetSuite_Error__c == true){
                    c.Netsuite_Integration_Error__c = wo.Netsuite_Integration_Error__c;
                    if(wo.ParentWorkOrderId != null){
                        c.WO_Sync_Failed__c = false;
                    } else {
                        c.WO_Sync_Failed__c = true;
                    }
                    updateCase = true;
                }
                if(c.Tracking_Numbers__c != wo.Tracking_Numbers__c){
                    c.Tracking_Numbers__c = wo.Tracking_Numbers__c;
                    updateCase = true;
                }
                if((!isUpdate && wo.Status != c.Status) || (isUpdate && wo.Status != c.Status && wo.Status != oldMap.get(wo.Id).Status)){
                    if(wo.Status != 'Approved' && wo.Status != 'Deletion Requested') {
                        if(closingCasesIds.contains(c.Id)){
                            if(wo.Status == 'Closed' && c.Status != 'Closed'){
                                c.Closing_Process__c = true; //To avoid Closing Process Error
                                c.Status = wo.Status;
                                updateCase = true;
                            }
                        }
                        if(wo.Status != 'Closed' && wo.Status != 'Onsite Work Completed'){
                            c.Status = wo.Status;
                            updateCase = true;
                        }
                    }
                }
                //Placed here as wo.Resolution_Code__c may be populated after wo.Status == 'Onsite Work Completed'
                if(closingCasesIds.contains(c.Id) && wo.Status == 'Onsite Work Completed' && wo.Resolution_Code__c != null && c.Status != 'Closed'){
                    c.Closing_Process__c = true; //To avoid Closing Process Error
                    c.Status = 'Closed';
                    updateCase = true;
                }
                // Parent WO and Parent Case Updates.
                if(!parentWOMap.isEmpty() && wo.ParentWorkOrderId != null && parentWOMap.containsKey(wo.ParentWorkOrderId)){
                    WorkOrder parentWO = parentWOMap.get(wo.ParentWorkOrderId);
                    if(wo.Service_Type__c == 'Advance Exchange + Onsite'){
                        if(parentWO.Status != 'Canceled' &&  wo.Status == 'Canceled') {
                            wo.addError('This work order is child of a parent work order. You cannot cancel child work orders. To cancel child work orders, please cancel parent work order');
                        }
                        if(wo.Status != parentWO.Status){
                            parentWO.Status = wo.Status;
                            updatewo = true;
                        }
                    }
                    if(updatewo){
                        woUpdateList.add(parentWO);
                    }
                    if(wo.SLA_Exception_Code__c != null && parentWO.caseId != null){
                        Case parentCase = caseMap.get(parentWO.caseId);
                        if(parentCase.SLA_Exception_Reason__c != wo.SLA_Exception_Code__c || parentCase.SLA_Violated__c == true){
                            parentCase.SLA_Exception_Reason__c = wo.SLA_Exception_Code__c;
                            parentCase.SLA_Violated__c = false;
                            caseUpdateList.add(parentCase);
                        }
                    }
                }
                if(!parentWOMap.isEmpty()){
                    for(WorkOrder w : parentWOMap.values()) {
                        if(w.ParentWorkOrderId != null) continue;
                        if(w.ParentWorkOrderId == wo.Id && (wo.Status == 'Canceled') && wo.Status != oldMap.get(wo.Id).Status && wo.Service_Type__c == 'Advance Exchange + Onsite' && wo.ParentWorkOrderId == null) {
                            WorkOrder cwo = new WorkOrder();
                            cwo.Id = w.Id;
                            cwo.Status = 'Canceled';
                            cwo.Resolution_Code__c = wo.Resolution_Code__c;
                            cwo.Resolution_Notes__c = wo.Resolution_Notes__c;
                            woUpdateList.add(cwo);
                        }
                    }               
                }

                if(updateCase){
                    caseUpdateList.add(c);
                }
            }
            if(!caseUpdateList.isEmpty()){
                Map<Id,Case> caseUpdateMap = new Map<Id,Case>();
                caseUpdateMap.putAll(caseUpdateList);
                System.debug('caseUpdateMap-> ' + JSON.Serialize(caseUpdateMap.values()));
                CaseTriggerHandler.runOnceBeforeUpdate = true;
                CaseTriggerHandler.runOnceAfterUpdate = true;
                Database.update(caseUpdateMap.values(),false);
            }
            if(!woUpdateList.isEmpty()){
                Map<Id,WorkOrder> woUpdateMap = new Map<Id,WorkOrder>();
                woUpdateMap.putAll(woUpdateList);
                System.debug('woUpdateMap-> ' + JSON.Serialize(woUpdateMap.values()));
                runOnceBeforeUpdate = false;
                runOnceAfterUpdate = false;
                Database.update(woUpdateMap.values(),false);
            }
        }
    }

    public static void woSubmitForApproval(Map<Id, WorkOrder> newMap, Map<Id, WorkOrder> oldMap){
        Boolean processCalled = false;
        for(WorkOrder wo : newMap.values()){
            if(wo.Technician_Status__c != oldMap.get(wo.Id).Technician_Status__c && wo.Approved__c == false) {
                // This If conditon is for DK Approval Process - Only PBS United States Child Accounts.
                if(wo.Root_Account_Name__c == 'Premium Brands Services,LLC' && wo.Country__c == 'United States' && wo.Technician_Status__c == 'Approved'){
                    System.debug('WO submitting for PBS Labor Approval Process');
                    Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
                    req1.setObjectId(wo.Id);
                    req1.setProcessDefinitionNameOrId('Approval_Flow_DK');
                    req1.setSkipEntryCriteria(true);
                    Approval.ProcessResult result = Approval.process(req1);
                    System.assert(result.isSuccess());
                    System.assertEquals('Pending', result.getInstanceStatus(), 'Instance Status'+result.getInstanceStatus());
                    processCalled = true;
                } else if(wo.OwnerId == '00G6g0000034waO' && (wo.Status == 'Onsite Work Completed' || wo.Status == 'Closed' || wo.Technician_Status__c == 'Approved')){
                    // This If condiotn is for Canada Partner Queue - All Canada Accounts.
                    System.debug('WO submitting for Canada Labor Approval Process');
                    Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
                    req1.setObjectId(wo.Id);
                    req1.setProcessDefinitionNameOrId('Canada_Labor_Approval');
                    req1.setSkipEntryCriteria(true);
                    Approval.ProcessResult result = Approval.process(req1);
                    System.assert(result.isSuccess());
                    System.assertEquals('Pending', result.getInstanceStatus(), 'Instance Status'+result.getInstanceStatus());
                    processCalled = true;
                } else if(wo.OwnerId != '00G6g0000034waO' && wo.Technician_Status__c == 'Approved'){
                    // This If condoition is for Labor Approval process - Accounts other than PBS Child Accounts
                    System.debug('WO submitting for Labor Approval Process');
                    Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
                    req1.setObjectId(wo.Id);
                    req1.setProcessDefinitionNameOrId('Labor_Approval');
                    req1.setSkipEntryCriteria(true);
                    Approval.ProcessResult result = Approval.process(req1);
                    System.assert(result.isSuccess());
                    System.assertEquals('Pending', result.getInstanceStatus(), 'Instance Status'+result.getInstanceStatus());
                    processCalled = true;
                }
            }
        }
        if(processCalled){
            runOnceBeforeUpdate = false;
            runOnceAfterUpdate = false;
        }
    }

    public static Map<Id,Event> handleTechCheckIn(Map<Id, WorkOrder> newMap, Map<Id, WorkOrder> oldMap){
        Map<Id,Event> eMap =  new Map<Id,Event>();
        Map<Id,Event> existingEventsMap = new Map<Id,Event>([SELECT Id,WhatId,StartDateTime,EndDateTime,Subject FROM Event WHERE WhatId In :newMap.keySet() 
                                                    AND Subject = 'Technician Working' Order By createddate desc]);
        for(WorkOrder wo : newMap.values()){
            System.debug('oldMap.get(wo.Id).Check_In_Time__c >= wo.Check_In_Time__c-> ' + (oldMap.get(wo.Id).Check_In_Time__c >= wo.Check_In_Time__c));
            System.debug('wo.Check_In_Time__c < oldMap.get(wo.Id).Check_Out_Time__c-> ' + (wo.Check_In_Time__c < oldMap.get(wo.Id).Check_Out_Time__c));
            System.debug('wo.Check_Out_Time__c < wo.Check_In_Time__c-> ' + (wo.Check_Out_Time__c < wo.Check_In_Time__c));

            if(wo.Check_In_Time__c == null || oldMap.get(wo.Id).Check_In_Time__c >= wo.Check_In_Time__c) continue;
            if(oldMap.get(wo.Id).Check_Out_Time__c != null && wo.Check_In_Time__c < oldMap.get(wo.Id).Check_Out_Time__c) continue;
            DateTime checkOutTime = wo.Check_Out_Time__c;
            if(wo.Check_In_Time__c != null && wo.Check_Out_Time__c != null && wo.Check_Out_Time__c < wo.Check_In_Time__c){
                //checkout time is before checkin time.
                checkOutTime = null;
            }
            boolean eventExists = false;
            for(Event e : existingEventsMap.values()){
                if(e.WhatId == wo.Id && e.StartDateTime == wo.Check_In_Time__c){
                    eventExists = true;
                }
            }
            if(eventExists) continue;
            Event e = new Event();
            e.StartDateTime = wo.Check_In_Time__c;
            if(checkOutTime != null && checkOutTime >= wo.Check_In_Time__c){
                e.EndDateTime = checkOutTime;
            } else{
                e.DurationInMinutes = 1;
            }
            e.Technician_Name__c = wo.Technician_Name__c;
            e.WhatId = wo.Id;
            e.WhoId = wo.ContactId;
            e.Subject = 'Technician Working';
            eMap.put(wo.Id,e);
        }
        return eMap;
    }
    public static void handleTechCheckOut(Map<Id, WorkOrder> newMap, Map<Id, WorkOrder> oldMap, Map<Id, Event> eMap,Map<Id, WorkOrder> woMap){
        Boolean woChanged = false;
        for(WorkOrder wo : newMap.values()){
            if(wo.Check_Out_Time__c != oldMap.get(wo.Id).Check_Out_Time__c){
                woChanged = true;
                break;
            }
        }
        if(woChanged){
            Set<Id> woProcessedIds = new Set<Id>();
            for(WorkOrder wo : newMap.values()){
                System.debug('wo.Check_Out_Time__c < oldMap.get(wo.Id).Check_Out_Time__c-> ' + (wo.Check_Out_Time__c < oldMap.get(wo.Id).Check_Out_Time__c));
                System.debug('wo.Check_Out_Time__c < oldMap.get(wo.Id).Check_In_Time__c-> ' + (wo.Check_Out_Time__c < oldMap.get(wo.Id).Check_In_Time__c));
                System.debug('wo.Check_Out_Time__c < wo.Check_In_Time__c-> ' + (wo.Check_Out_Time__c < wo.Check_In_Time__c));
                if(oldMap.get(wo.Id).Check_Out_Time__c != null && wo.Check_Out_Time__c < oldMap.get(wo.Id).Check_Out_Time__c) continue;
                if(oldMap.get(wo.Id).Check_In_Time__c != null && wo.Check_Out_Time__c < oldMap.get(wo.Id).Check_In_Time__c) continue;
                if(wo.Check_In_Time__c != null && wo.Check_Out_Time__c != null && wo.Check_Out_Time__c < wo.Check_In_Time__c) continue;
                if(eMap.containsKey(wo.Id)){
                    eMap.get(wo.Id).EndDateTime = wo.Check_Out_Time__c;
                } else{
                    woProcessedIds.add(wo.Id);
                }                
            }
            if(!woProcessedIds.isEmpty()){
                List<Event> eListToUpdate = new List<Event>();
                for(WorkOrder wo : woMap.values()){
                    if(!woProcessedIds.contains(wo.Id)) continue;
                    for(Event e : wo.Events){
                        e.EndDateTime = newMap.get(e.WhatId).Check_Out_Time__c;
                        eListToUpdate.add(e);
                    }
                }
                if(!eListToUpdate.isEmpty()){
                    Database.update(eListToUpdate,false);
                }
            }
        }
    }
    
    public static void handleCheckInLocation(Map<Id, WorkOrder> newMap, Map<Id, WorkOrder> oldMap,Map<Id,Event> eMap, Map<Id,WorkOrder> woMap){
        Set<Id> woProcessedIds = new Set<Id>();
        for(WorkOrder wo : newMap.values()){
            if(wo.Check_In_Lat_Lon__latitude__s == null || wo.Check_In_Lat_Lon__longitude__s == null) continue;
            if(wo.Check_In_Lat_Lon__latitude__s == oldMap.get(wo.Id).Check_In_Lat_Lon__latitude__s 
                    && wo.Check_In_Lat_Lon__longitude__s == oldMap.get(wo.Id).Check_In_Lat_Lon__longitude__s) continue;
            if(eMap.containsKey(wo.Id)){
                eMap.get(wo.Id).Check_In_Lat_Lon__latitude__s  = wo.Check_In_Lat_Lon__latitude__s;
                eMap.get(wo.Id).Check_In_Lat_Lon__longitude__s  = wo.Check_In_Lat_Lon__longitude__s;
                System.debug('Check In Location-> ' + eMap.get(wo.Id).Check_In_Lat_Lon__latitude__s + ' - ' + eMap.get(wo.Id).Check_In_Lat_Lon__longitude__s);
                if(wo.latitude != null && wo.longitude != null){
                    Location loc1 = Location.newInstance(wo.Check_In_Lat_Lon__latitude__s,wo.Check_In_Lat_Lon__longitude__s);
                    Location loc2 = Location.newInstance(wo.latitude,wo.longitude);
                    double dist = Location.getDistance(loc1, loc2, 'mi');
                    System.debug('wo.Check_In_Lat_Lon__latitude__s-> ' + wo.Check_In_Lat_Lon__latitude__s);
                    System.debug('wo.Check_In_Lat_Lon__longitude__s-> ' + wo.Check_In_Lat_Lon__longitude__s);
                    System.debug('wo.latitude-> ' + wo.latitude);
                    System.debug('wo.longitude-> ' + wo.longitude);
                    System.debug('dist-> ' + dist);
                    if(dist != null){
                        eMap.get(wo.Id).Check_In_Distance__c = dist;
                        wo.Check_In_Distance__c  = dist;
                    } else {
                        eMap.get(wo.Id).Check_In_Distance__c = 0;
                        wo.Check_In_Distance__c  = 0;
                    }
                    System.debug('wo.Check_In_Distance__c-> ' + wo.Check_In_Distance__c);
                }
            } else{
                woProcessedIds.add(wo.Id);
            }
        }
        if(!woProcessedIds.isEmpty()){
            List<Event> eListToUpdate = new List<Event>();
            for(WorkOrder wo : woMap.values()){
                if(!woProcessedIds.contains(wo.Id)) continue;
                for(Event e : wo.Events){
                    e.Check_In_Lat_Lon__latitude__s  = newMap.get(e.WhatId).Check_In_Lat_Lon__latitude__s;
                    e.Check_In_Lat_Lon__longitude__s  = newMap.get(e.WhatId).Check_In_Lat_Lon__longitude__s;
                    if(wo.latitude != null && wo.longitude != null){
                        Location loc1 = Location.newInstance(newMap.get(e.WhatId).Check_In_Lat_Lon__latitude__s,newMap.get(e.WhatId).Check_In_Lat_Lon__longitude__s);
                        Location loc2 = Location.newInstance(wo.latitude,wo.longitude);
                        double dist = Location.getDistance(loc1, loc2, 'mi');
                        System.debug('dist-> ' + dist);
                        if(dist != null){
                            e.Check_In_Distance__c = dist;
                            newMap.get(wo.Id).Check_In_Distance__c = dist;
                        } else {
                            e.Check_In_Distance__c = 0;
                            newMap.get(wo.Id).Check_In_Distance__c = 0;
                        }
                        System.debug('newMap.get(wo.Id).Check_In_Distance__c-> ' + newMap.get(wo.Id).Check_In_Distance__c);
                    }
                    eListToUpdate.add(e);
                }
            }
            if(!eListToUpdate.isEmpty()){
                Database.update(eListToUpdate,false);
            }
        }
        for(WorkOrder wo : newMap.values()){
            if(oldMap.get(wo.Id).Check_In_Lat_Lon__latitude__s != null 
                && wo.Check_In_Lat_Lon__latitude__s != oldMap.get(wo.Id).Check_In_Lat_Lon__latitude__s) {
                wo.Check_In_Lat_Lon__latitude__s  = oldMap.get(wo.Id).Check_In_Lat_Lon__latitude__s;
                wo.Check_In_Lat_Lon__longitude__s  = oldMap.get(wo.Id).Check_In_Lat_Lon__longitude__s;     
            }
        }
    }

    public static void handleCheckOutLocation(Map<Id, WorkOrder> newMap, Map<Id, WorkOrder> oldMap, Map<Id,Event> eMap, Map<Id, WorkOrder> woMap){
        Set<Id> woProcessedIds = new Set<Id>();
        for(WorkOrder wo : newMap.values()){
            if(wo.Check_Out_Lat_Lon__latitude__s == null || wo.Check_Out_Lat_Lon__longitude__s == null) continue;
            if(wo.Check_Out_Lat_Lon__latitude__s == oldMap.get(wo.Id).Check_Out_Lat_Lon__latitude__s 
                    &&  wo.Check_Out_Lat_Lon__longitude__s == oldMap.get(wo.Id).Check_Out_Lat_Lon__longitude__s) continue;
            if(eMap.containsKey(wo.Id)){
                eMap.get(wo.Id).Check_Out_Lat_Lon__latitude__s = wo.Check_Out_Lat_Lon__latitude__s;
                eMap.get(wo.Id).Check_Out_Lat_Lon__longitude__s = wo.Check_Out_Lat_Lon__longitude__s;
                System.debug('Check Out Location-> ' + eMap.get(wo.Id).Check_Out_Lat_Lon__latitude__s + ' - ' + eMap.get(wo.Id).Check_Out_Lat_Lon__longitude__s);
                if(wo.latitude != null && wo.longitude != null){
                    Location loc1 = Location.newInstance(wo.Check_Out_Lat_Lon__latitude__s,wo.Check_Out_Lat_Lon__longitude__s);
                    Location loc2 = Location.newInstance(wo.latitude,wo.longitude);
                    Double dist = Location.getDistance(loc1, loc2, 'mi');
                    System.debug('dist-> ' + dist);
                    if(dist != null){
                        eMap.get(wo.Id).Check_Out_Distance__c = dist;
                        wo.Check_Out_Distance__c = dist;
                    } else {
                        eMap.get(wo.Id).Check_Out_Distance__c = 0;
                        wo.Check_Out_Distance__c = 0;
                    }
                    System.debug('wo.Check_Out_Distance__c-> ' + wo.Check_Out_Distance__c);
                }
            } else{
                woProcessedIds.add(wo.Id);
            } 
        }
        if(!woProcessedIds.isEmpty()){
            List<Event> eListToUpdate = new List<Event>();
            for(WorkOrder wo : woMap.values()){
                if(!woProcessedIds.contains(wo.Id)) continue;
                for(Event e : wo.Events){
                    e.Check_Out_Lat_Lon__latitude__s  = newMap.get(e.WhatId).Check_Out_Lat_Lon__latitude__s;
                    e.Check_Out_Lat_Lon__longitude__s  = newMap.get(e.WhatId).Check_Out_Lat_Lon__longitude__s;
                    if(wo.latitude != null && wo.longitude != null){
                        Location loc1 = Location.newInstance(newMap.get(e.WhatId).Check_Out_Lat_Lon__latitude__s,newMap.get(e.WhatId).Check_Out_Lat_Lon__longitude__s);
                        Location loc2 = Location.newInstance(wo.latitude,wo.longitude);
                        double dist = Location.getDistance(loc1, loc2, 'mi');
                        System.debug('dist-> ' + dist);
                        if(dist != null){
                            e.Check_Out_Distance__c = dist;
                            newMap.get(wo.Id).Check_Out_Distance__c = dist;
                        } else {
                            e.Check_Out_Distance__c = 0;
                            newMap.get(wo.Id).Check_Out_Distance__c = 0;
                        }
                        System.debug('newMap.get(wo.Id).Check_Out_Distance__c-> ' + newMap.get(wo.Id).Check_Out_Distance__c);
                    }
                    eListToUpdate.add(e);
                }
            }
            if(!eListToUpdate.isEmpty()){
                Database.update(eListToUpdate,false);
            }
        }
    }

    public static void createWOTimeEntries(Map<Id, WorkOrder> newMap, Map<Id, WorkOrder> oldMap){
        Set<Id> accIds = new Set<Id>();
        for(WorkOrder wo : newMap.values()){
            accIds.add(wo.AccountId);
        }
        Map<Id,Account> accMap = new Map<Id, Account>([SELECT Id, Timezone__c, ShippingState FROM Account WHERE Id IN :accIds]);
        List<Timezone_Id__mdt> tzList = [SELECT MasterLabel, QualifiedApiName, Timezon_Id__c FROM Timezone_Id__mdt];
        Map<String,String> tmzNameIdMap = new Map<String,String>();
        List<WorkOrder> woList = [SELECT Id,AccountId,(SELECT Id,WhatId,StartDateTime,EndDateTime,Subject FROM Events 
                                    ORDER BY Createddate Desc LIMIT 1) FROM WorkOrder WHERE Id IN : newMap.keySet()];
        Map<Id,DateTime> eventStartTimeMap  = new Map<Id,DateTime>();
        for(WorkOrder wo : woList){
            for(Event e : wo.Events){
                eventStartTimeMap.put(wo.Id,e.StartDateTime);
                break;
            }
        }
        for(WorkOrder wo : newMap.values()){
            if(wo.AccountId == null) continue;
            System.debug('oldMap.get(wo.Id).Check_Out_Time__c == wo.Check_Out_Time__c && wo.Check_In_Time__c < oldMap.get(wo.Id).Check_Out_Time__c-> ' + (oldMap.get(wo.Id).Check_Out_Time__c == wo.Check_Out_Time__c && wo.Check_In_Time__c < oldMap.get(wo.Id).Check_Out_Time__c));
            System.debug('oldMap.get(wo.Id).Check_Out_Time__c != null && wo.Check_Out_Time__c < oldMap.get(wo.Id).Check_Out_Time__c-> ' + (oldMap.get(wo.Id).Check_Out_Time__c != null && wo.Check_Out_Time__c < oldMap.get(wo.Id).Check_Out_Time__c));
            System.debug('oldMap.get(wo.Id).Check_In_Time__c != null && wo.Check_Out_Time__c == oldMap.get(wo.Id).Check_Out_Time__c && wo.Check_In_Time__c != oldMap.get(wo.Id).Check_In_Time__c && oldMap.get(wo.Id).Check_In_Time__c > wo.Check_In_Time__c-> ' + (oldMap.get(wo.Id).Check_In_Time__c != null && wo.Check_Out_Time__c == oldMap.get(wo.Id).Check_Out_Time__c && wo.Check_In_Time__c != oldMap.get(wo.Id).Check_In_Time__c &&
            oldMap.get(wo.Id).Check_In_Time__c > wo.Check_In_Time__c));

            if(oldMap.get(wo.Id).Check_Out_Time__c == wo.Check_Out_Time__c && wo.Check_In_Time__c < oldMap.get(wo.Id).Check_Out_Time__c) continue;
            if(oldMap.get(wo.Id).Check_Out_Time__c != null && wo.Check_Out_Time__c < oldMap.get(wo.Id).Check_Out_Time__c) continue;
            if(oldMap.get(wo.Id).Check_In_Time__c != null && wo.Check_Out_Time__c == oldMap.get(wo.Id).Check_Out_Time__c && 
                wo.Check_In_Time__c != oldMap.get(wo.Id).Check_In_Time__c && oldMap.get(wo.Id).Check_In_Time__c > wo.Check_In_Time__c) continue;

            DateTime validCheckInTime = wo.Check_In_Time__c;
            if(oldMap.get(wo.Id).Check_In_Time__c != null && wo.Check_In_Time__c != oldMap.get(wo.Id).Check_In_Time__c && 
                wo.Check_In_Time__c < oldMap.get(wo.Id).Check_In_Time__c){
                //next checkin time must be past previous one.
                validCheckInTime = oldMap.get(wo.Id).Check_In_Time__c;
            }
            if(eventStartTimeMap.containsKey(wo.Id) && eventStartTimeMap.get(wo.Id) != null){
                if(oldMap.get(wo.Id).Check_In_Time__c != null && wo.Check_Out_Time__c != oldMap.get(wo.Id).Check_Out_Time__c && 
                    validCheckInTime != null && eventStartTimeMap.get(wo.Id) > validCheckInTime){
                    //only Checkout time is changed.
                    //taking correct checkin time from event since WO's checkin time stays at first checkin time.
                    validCheckInTime = eventStartTimeMap.get(wo.Id);
                }
                if(oldMap.get(wo.Id).Check_Out_Time__c != null && wo.Check_In_Time__c < oldMap.get(wo.Id).Check_Out_Time__c){
                    //next checkin time must be past checkout time.
                    validCheckInTime = eventStartTimeMap.get(wo.Id);
                }
            }
            if(wo.Check_In_Time__c != oldMap.get(wo.Id).Check_In_Time__c || wo.Check_Out_Time__c != oldMap.get(wo.Id).Check_Out_Time__c){
                String timezoneId = '';
                String timezoneName = '';
                String checkInTime = '';
                String checkOutTime = '';
                DateTime inTime;
                DateTime outTime;
                Long milliseconds;
                Long seconds;
                Long minutes;
                Long hours;
                Long days;
                String hour;
                String min;

                if(accMap.containsKey(wo.AccountId)) tmzNameIdMap = ASCENACaseMilestoneCalculater.getTimezoneIdForAccount(accMap.get(wo.AccountId), tzList);
                if (!tmzNameIdMap.isEmpty()) {
                    List<String> keyList = new List<String>(tmzNameIdMap.keySet());
                    timezoneName = keyList[0];
                    timezoneId = tmzNameIdMap.get(timezoneName);
                }
                if(timezoneId == null) continue;
                if(validCheckInTime != null){
                    checkInTime = String.valueOf(DateTime.parse(validCheckInTime.format('MM/dd/yyyy, hh:mm a', timezoneId)));
                    inTime = DateTime.parse(validCheckInTime.format('MM/dd/yyyy, hh:mm a', timezoneId));
                    System.debug('inTime-> ' + inTime);
                } else {
                    checkInTime = 'Not Provided';
                }
                if(wo.Check_Out_Time__c != null){
                    checkOutTime = String.valueOf(DateTime.parse(wo.Check_Out_Time__c.format('MM/dd/yyyy, hh:mm a', timezoneId)));
                    outTime = DateTime.parse(wo.Check_Out_Time__c.format('MM/dd/yyyy, hh:mm a', timezoneId));
                    System.debug('outTime-> ' + outTime);
                } else {
                    checkOutTime = 'Not Provided';
                }
                if(outTime != null && inTime != null){
                    milliseconds = outTime.getTime() - inTime.getTime();
                    decimal temp = decimal.valueOf(milliseconds).divide(3600000,5);
                    System.debug('temp-> ' + temp);
                    string temp2;
                    if(string.valueOf(temp).contains('.')){
                        string temp3 = string.valueOf(temp).substringBefore('.');
                        if(temp3.length() == 1){
                            temp3 = '0' + temp3;
                        }
                        hour = temp3;
                        temp2 = string.valueOf(temp).substringAfter('.');
                        temp2 = string.valueOf(decimal.valueOf(temp2).divide(100000,5));
                    } else{
                        String tempStr = string.valueOf(temp);
                        if(tempStr.length() == 1){
                            tempStr = '0' + tempStr;
                        }
                        hour = tempStr;
                    }
                    if(temp2 != null){
                        decimal temp4 = math.round(decimal.valueOf(temp2) * 60);
                        string temp5;
                        if(string.valueOf(temp4).contains('.')){
                            temp5 = string.valueOf(temp4).substringBefore('.');
                            if(temp5.length() == 1){
                                temp5 = '0' + temp5;
                            }
                            min = temp5;
                        } else{
                            String temp4Str = string.valueOf(temp4);
                            if(temp4Str.length() == 1){
                                temp4Str = '0' + temp4Str;
                            }
                            min = temp4Str;
                        }
                    } else{
                        min = '00';
                    }
                } else {
                    hour = '00';
                    min = '00';
                }
                if(hour.contains('-')){
                    checkOutTime = 'Not Provided';
                    hour = '00';
                    min = '00';
                }
                if(wo.Time_Entries__c == null){
                    wo.Time_Entries__c = checkInTime + ' - ' + checkOutTime + ' (' + hour+ ':' + min + ')';
                } else {
                    if(wo.Time_Entries__c.endsWith(checkInTime + ' - ' + checkOutTime + ' (' + hour+ ':' + min + ')')) continue;
                    System.debug('validCheckInTime == oldMap.get(wo.Id).Check_In_Time__c-> ' + (validCheckInTime == oldMap.get(wo.Id).Check_In_Time__c));
                    System.debug('wo.Check_Out_Time__c != oldMap.get(wo.Id).Check_Out_Time__c-> ' + (wo.Check_Out_Time__c != oldMap.get(wo.Id).Check_Out_Time__c));
                    if(validCheckInTime == oldMap.get(wo.Id).Check_In_Time__c && wo.Check_Out_Time__c != oldMap.get(wo.Id).Check_Out_Time__c
                        && wo.Time_Entries__c.endsWith('Not Provided (00:00)')){
                        wo.Time_Entries__c = wo.Time_Entries__c.removeEnd('Not Provided (00:00)');
                        wo.Time_Entries__c +=  checkOutTime + ' (' + hour+ ':' + min + ')';
                        System.debug('wo.Time_Entries__c-> ' + wo.Time_Entries__c);
                    } else{
                        List<String> teList = wo.Time_Entries__c.split('\\n');
                        System.debug('teList-> ' + teList);
                        String lastIndexStr = teList[teList.size()-1];
                        List<String> latestEntry = lastIndexStr.split(' - ');
                        String checkInStr = latestEntry[0];
                        String checkOutStr = latestEntry[1].substringBefore(' (');
                        String timeDiff = latestEntry[1].removeStart(checkOutStr);
                        System.debug('checkInStr-> ' + checkInStr);
                        System.debug('checkOutStr-> ' + checkOutStr);
                        if(checkInTime == checkInStr && checkOutTime != checkOutStr){
                            wo.Time_Entries__c = wo.Time_Entries__c.removeEnd(timeDiff);
                            wo.Time_Entries__c = wo.Time_Entries__c.removeEnd(checkOutStr);
                            wo.Time_Entries__c +=  checkOutTime + ' (' + hour+ ':' + min + ')';
                            System.debug('wo.Time_Entries__c-> ' + wo.Time_Entries__c);
                        } else {
                            wo.Time_Entries__c += '\n' + checkInTime + ' - ' + checkOutTime + ' (' + hour+ ':' + min + ')';
                            System.debug('wo.Time_Entries__c-> ' + wo.Time_Entries__c);
                        }
                    }
                }
            }
        }
    }

    public static void woFieldsUpdates2(Map<Id, WorkOrder> newMap, Map<Id, WorkOrder> oldMap) {
        Map<Id,User> usrMap = new Map<Id,User>([SELECT Id, Name, Profile.Name FROM User WHERE IsActive = true AND Profile.Name = 'Field Tech']);
        for(WorkOrder wo : newMap.values()) {
            if(wo.Record_Type_Name__c == 'Part Shipment' && usrMap.containsKey(wo.OwnerId)){
                wo.Field_Nation_Work_Order__c = usrMap.get(wo.OwnerId).Name;
            }
            if(oldMap.get(wo.Id).Check_In_Time__c != null && wo.Check_In_Time__c != oldMap.get(wo.Id).Check_In_Time__c) {
                //Retaining original Check-In time so that we can correctly calculate technician onsite time
                //FN keeps on sending new check in time whenever technician checks in multiple times for the same WO.
                //If we don't have following, then we will loose time technician chceked in first time for this WO.
                wo.Check_In_Time__c = oldMap.get(wo.Id).Check_In_Time__c;
            }
            // Calculating Total Labor Hours from Time Entries for open WOs owned by Internal Field Techs before sending to FN
            if(wo.Record_Type_Name__c == 'Onsite Labor' && usrMap.containsKey(wo.OwnerId) && !String.isBlank(wo.Time_Entries__c) && wo.Status != 'Closed'){
                if((String.isBlank(wo.NetsuiteId__c) || (!String.isBlank(wo.NetsuiteId__c) && wo.NetsuiteId__c.containsIgnoreCase('TEST')))) {
                    //2024-02-20 00:00:00 - 2024-02-20 02:10:00 (02:10) \n 2024-02-20 02:30:00 - 2024-02-20 03:10:00 (00:40) \n 2024-02-23 00:00:00 - 2024-02-23 12:50:00 (12:50)
                    List<String> teList = wo.Time_Entries__c.split('\n');
                    Integer sumOfHrs = 0;
                    Integer sumOfMins = 0;
                    for(String s : teList){
                        if(!s.contains('(') || !s.contains(')')) continue;
                        String duration = s.substringAfter('(').substringBefore(')');
                        List<String> durationParts = duration.split(':');
                        Integer hrs = Integer.valueOf(durationParts[0]);
                        Integer mins = Integer.valueOf(durationParts[1]);
                        sumOfHrs += hrs;
                        sumOfMins += mins;
                    }
                    // Adjust for overflow in minutes
                    sumOfHrs += sumOfMins / 60;
                    sumOfMins = Math.mod(sumOfMins, 60);
                    Time t = Time.newInstance(sumOfHrs, sumOfMins, 0, 0);
                    System.debug('sumOfHrs-> ' + sumOfHrs);
                    System.debug('sumOfMins-> ' + sumOfMins);
                    System.debug('Total Time-> ' + t);
                    Decimal totalHoursDecimal = t.hour() + (t.minute() / 60.0);
                    System.debug('Total Labor Hours-> ' + totalHoursDecimal);
                    wo.Total_Labor_Hours__c = totalHoursDecimal;
                }
            }
        }
    }
    
    public static void OnCreateWOupdateFlow(List<WorkOrder> workOrderRecords){
        Set<Id> AccountIds = new Set<Id>();
        for(WorkOrder w : workOrderRecords){
            AccountIds.add(w.AccountId);
        }
        List<Account> accList = [SELECT Id, ShippingStreet, ShippingCity, ShippingState, ShippingCountry, ShippingLatitude, ShippingLongitude, ShippingPostalCode, Name 
                                 FROM Account WHERE Id IN : AccountIds];
        list<ServiceTerritory> stRecord = [SELECT Id, Name FROM ServiceTerritory WHERE Name = 'National' limit 1];
        System.debug('accList:'+accList);
        for(WorkOrder wo : workOrderRecords){
            for(Account acc : accList){
                if(acc.Id != wo.AccountId) continue;
                wo.City = acc.ShippingCity;
                wo.Country = acc.ShippingCountry;
                wo.PostalCode = acc.ShippingPostalCode;
                wo.Street = acc.ShippingStreet;
                wo.State = acc.ShippingState;
                wo.Subject = acc.Name;
                if(!String.isBlank(wo.Service_Type__c)) wo.Subject += ' - ' + wo.Service_Type__c;
                if(!String.isBlank(wo.Priority)) wo.Subject += ' - ' + wo.Priority;
            }
            if(stRecord.size() != 0){
                wo.ServiceTerritoryId = stRecord[0].Id;
            }
            if(wo.Work_Order_Hourly_Rate__c == null && wo.Project_Hourly_Rate__c != null){
                wo.Work_Order_Hourly_Rate__c = wo.Project_Hourly_Rate__c;
            }
        }
    }
    
    public static void handleBeforeDelete(Map<Id, WorkOrder> newMap, Map<Id, WorkOrder> oldMap) {
        
        Id partShipId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get( 'Part_Shipment' ).getRecordTypeId();
        
        Id onsiteLaborId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get( 'Onsite_Labor' ).getRecordTypeId();
        
        List<WorkOrder> allowDeleteList = new List<WorkOrder>();
        for(WorkOrder wo : oldMap.values()) {
            if(wo.RecordTypeId == partShipId && String.isNotBlank(wo.NetsuiteId__c) ){
                wo.addError('You cannot delete this work order, as it is already in production');
            } else if(wo.RecordTypeId == onsiteLaborId && wo.Status == 'Technician Scheduled / Assigned') {
                wo.addError('You cannot delete this work order, as a technician is already assigned to this work order');
            } else {
                allowDeleteList.add(wo);
            }
        }
        
        Set<Id> caseIds = new Set<Id>();
        Set<Id> woIds = new Set<Id>();
        for(WorkOrder wo : allowDeleteList){
            if(wo.Service_Type__c == 'Advance Exchange + Onsite' && wo.ParentWorkOrderId != null){
                wo.addError('This work order is child of a parent work order. You cannot delete child work orders. To delete child work orders, please delete parent work order');
            }else{
                if(wo.Deleting_Current_WO__c == true) continue;
                caseIds.add(wo.CaseId);
            }
            woIds.add(wo.Id);
        }
        System.debug('woIds size-> ' + woIds.size());
        Set<Id> cwoIds = new Set<Id>();
        list<WorkOrder> woList = [SELECT Id FROM WorkOrder WHERE ParentWorkOrderId IN: woIds];
        if(woList.size() != 0){
            for(WorkOrder w : woList){
                cwoIds.add(w.Id);
            }
        }
        WorkOrderTriggerHandler.deleteCases(caseIds);
        if(cwoIds.size() != 0){
            WorkOrderTriggerHandler.deleteChildWos(cwoIds);
        }
    }
    @future
    public static void deleteCases(Set<Id> caseIds) {
        list<Case> csList = [SELECT Id, CaseNumber FROM Case WHERE Id IN: caseIds];
        if(csList.size() != 0){
            delete csList;
        }
    }
    @future
    public static void deleteChildWos(Set<Id> cwoIds) {
        list<WorkOrder> woList = [SELECT Id FROM WorkOrder WHERE Id IN: cwoIds];
        if(woList.size() != 0){
            delete woList;
        }
    }
    
    public static void updateStatuses(Map<Id, WorkOrder> newMap, Map<Id, WorkOrder> oldMap){
        for(WorkOrder wo : newMap.values()){
            if((wo.Status == 'Draft' || wo.Status == 'DRAFT') && wo.Status != oldMap.get(wo.Id).Status) {
                wo.Status = oldMap.get(wo.Id).Status;
            }
            if(wo.EndDate < wo.StartDate){
                wo.EndDate = wo.StartDate;
            }
            if((wo.Technician_Status__c == 'Draft' || wo.Technician_Status__c == 'Published' || wo.Technician_Status__c == 'Routed') && wo.Technician_Status__c != oldMap.get(wo.Id).Technician_Status__c) {
                wo.Technician_Status__c = 'Scheduling';
            }else if((wo.Technician_Status__c == 'Assigned' || wo.Technician_Status__c == 'At Risk' || wo.Technician_Status__c == 'Assigned: At risk') && wo.Technician_Status__c != oldMap.get(wo.Id).Technician_Status__c){
                wo.Technician_Status__c = 'Assigned';
            }else if((wo.Technician_Status__c == 'Confirmed') && wo.Technician_Status__c != oldMap.get(wo.Id).Technician_Status__c){
                wo.Technician_Status__c = 'Confirmed';
            }else if((wo.Technician_Status__c == 'ETA Set') && wo.Technician_Status__c != oldMap.get(wo.Id).Technician_Status__c){
                wo.Technician_Status__c = 'ETA PROVIDED';
            }else if((wo.Technician_Status__c == 'Checked in') && wo.Technician_Status__c != oldMap.get(wo.Id).Technician_Status__c){
                wo.Technician_Status__c = 'Checked in';
            }else if(wo.Technician_Status__c == 'Checked out' && wo.Technician_Status__c != oldMap.get(wo.Id).Technician_Status__c){
                wo.Technician_Status__c = 'Checked Out';
            }else if((wo.Technician_Status__c == 'Delayed') && wo.Technician_Status__c != oldMap.get(wo.Id).Technician_Status__c){
                wo.Technician_Status__c = 'Technician Delayed';
            }else if((wo.Technician_Status__c == 'Cancelled') && wo.Technician_Status__c != oldMap.get(wo.Id).Technician_Status__c){
                wo.Technician_Status__c = 'Cancelled';
            }else if((wo.Technician_Status__c == 'On my way') && wo.Technician_Status__c != oldMap.get(wo.Id).Technician_Status__c){
                wo.Technician_Status__c = 'In Route';
            }
            // Approved is Last Technician Status Value
            if(oldMap.get(wo.Id).Technician_Status__c == 'Approved' && wo.Technician_Status__c != 'Approved'){
                wo.Technician_Status__c = 'Approved';
            }
            if((wo.Technician_Status__c != null && (wo.Technician_Status__c != oldMap.get(wo.Id).Technician_Status__c))){
                if(wo.Technician_Status__c == 'Checked in' && (wo.StatusCategory == 'New' || wo.Status == 'Scheduling' || wo.Status == 'In Production' 
                	|| wo.Status == 'Technician In Route' || wo.Status == 'Technician Scheduled / Assigned')){
                    wo.Status = 'Tech Checked In';
                }else if((wo.Technician_Status__c == 'Assigned' || wo.Technician_Status__c == 'Confirmed')){
                    wo.Status = 'Technician Scheduled / Assigned';
                }else if(wo.Technician_Status__c == 'Cancelled' && (wo.StatusCategory != 'Closed' && wo.StatusCategory != 'Completed')){
                    wo.Status = 'Technician Scheduled / Assigned';
                }else if(wo.Technician_Status__c == 'Work Done'){
                    wo.Status ='Onsite Work Completed';
                }else if(wo.Technician_Status__c == 'Checked Out'){
                    wo.Status ='Tech Checked Out';
                } else if(wo.Technician_Status__c == 'Start Time Set'){
                    wo.Status ='Technician Scheduled / Assigned';
                }
            }
            if((wo.FN_Status__c != null && (wo.FN_Status__c != oldMap.get(wo.Id).FN_Status__c))){
                if((wo.FN_Status__c == 'Draft' || wo.FN_Status__c == 'Published' || wo.FN_Status__c == 'Routed') && (wo.StatusCategory == 'New')){
                    wo.Status = 'Scheduling';
                }else if(wo.FN_Status__c == 'Assigned' && (wo.Status == 'New' || wo.Status == 'Acknowledged')){
                    wo.Status = 'Technician Scheduled / Assigned';
                }else if(wo.FN_Status__c == 'Work Done' && (wo.StatusCategory != 'Closed' && wo.StatusCategory != 'Completed')){
                    wo.Status = 'Onsite Work Completed';
                }
            }
        }
        list<ServiceAppointment> saList = [SELECT Id, ParentRecordId, Status, DueDate, EarliestStartTime FROM ServiceAppointment WHERE ParentRecordId IN : newMap.keySet()];
        Map<Id,ServiceAppointment> saListtoUpdateMap = new Map<Id,ServiceAppointment>();
        for(WorkOrder wo : newMap.values()){
            if(wo.Account_Name__c != null && (wo.Account_Name__c.containsIgnoreCase('CUB') || wo.Account_Name__c.containsIgnoreCase('SHOPPER'))) continue;
            for(ServiceAppointment sa : saList){
                boolean saToUpdate = false;
                if(sa.DueDate != null){
                    sa.EarliestStartTime = sa.DueDate.addHours(-1);
                    saToUpdate = true;
                }
                if(sa.ParentRecordId == wo.Id && wo.Status == 'Technician Scheduled / Assigned' && (wo.Status != oldMap.get(wo.Id).Status)){
                    sa.Status = 'Scheduled';
                    saToUpdate = true;
                }else if(sa.ParentRecordId == wo.Id && wo.Status == 'Technician In Route' && sa.Status != null && (wo.Status != oldMap.get(wo.Id).Status)){
                    sa.Status = 'Dispatched';
                    saToUpdate = true;
                }else if(sa.ParentRecordId == wo.Id && wo.StatusCategory == 'In Progress' && wo.Status != 'Technician In Route' && sa.Status != null && (wo.StatusCategory != oldMap.get(wo.Id).StatusCategory)){
                    sa.Status = 'In Progress';
                    saToUpdate = true;
                }else if(sa.ParentRecordId == wo.Id && wo.StatusCategory == 'Cannot Complete' && sa.Status != null && (wo.StatusCategory != oldMap.get(wo.Id).StatusCategory)){
                    sa.Status = 'Cannot Complete';
                    saToUpdate = true;
                }else if(sa.ParentRecordId == wo.Id && wo.StatusCategory == 'Completed' && sa.Status != null && (wo.StatusCategory != oldMap.get(wo.Id).StatusCategory)){
                    sa.Status = 'Completed';
                    saToUpdate = true;
                }else if(sa.ParentRecordId == wo.Id && wo.StatusCategory == 'Canceled' && sa.Status != null && (wo.StatusCategory != oldMap.get(wo.Id).StatusCategory)){
                    sa.Status = 'Canceled';
                    saToUpdate = true;
                }
                if(saToUpdate){
                    saListtoUpdateMap.put(sa.Id,sa);
                }
            }
        }
        if(!saListtoUpdateMap.isEmpty()){
            Database.update(saListtoUpdateMap.values(),false);
        }
    }  

    /*
    This method creates event records to remind users
    when severity 1 work order is raised
    */
    public static void createReminderEvents(List<WorkOrder> woList) {
        Set<Id> eventWoIds = new Set<Id>();
        for(WorkOrder wo : woList) {
            if(wo.Priority == 'Severity 1' && (wo.RecordTypeId == System.Label.Part_Request_WO_RT_Id || wo.RecordTypeId == System.Label.Onsite_Labor_WO_RT_Id)) {
                eventWoIds.add(wo.Id);
            }
        }

        if(eventWoIds.isEmpty()) return;

        List<WorkOrder> woListFromQuery = [SELECT Id, OwnerId, SLA_Due_DateTime__c, CreatedBy.Name,AccountId, Account.Name, WorkOrderNumber, Product__r.Name
                                FROM WorkOrder 
                                WHERE Id IN :eventWoIds]; 

        List<Group> queues = [SELECT Id, (SELECT Id,UserOrGroupId FROM GroupMembers) FROM Group WHERE Type = 'Queue'];
        List<Event> eventList = new List<Event>();
        for(WorkOrder wo : woListFromQuery) {
            for(Group g : queues) {
                if(g.Id == wo.OwnerId || (test.isRunningTest())) {
                    for(GroupMember gm : g.GroupMembers) {
                        Event e = new Event();
                        e.WhatId = wo.Id;
                        if(string.valueOf(gm.UserOrGroupId).startsWith('00G')){
                            e.OwnerId = UserInfo.getUserId();
                        }else{
                            e.OwnerId = gm.UserOrGroupId;
                        }
                        e.ActivityDateTime = System.now();
                        if(wo.SLA_Due_DateTime__c != null) {
                            e.EndDateTime = wo.SLA_Due_DateTime__c;
                        } else {
                            e.EndDateTime = System.now().addHours(4);
                        }
                        if(e.EndDateTime < e.ActivityDateTime){
                            e.EndDateTime = System.now().addHours(4);
                        }
                        e.IsPrivate = false;
                        e.IsReminderSet = true;
                        e.ReminderDateTime = System.now();
                        e.Location = wo.Account.Name;
                        e.Subject = 'Severity 1 work order '+wo.WorkOrderNumber+' raised by '+wo.CreatedBy.Name+' for product '+wo.Product__r.Name;
                        eventList.add(e);
                    }
                }
                break;
            }
        }
        insert eventList;
    }

    /*
    For Advance Exchange + Onsite the part shipment should be allowed till 9pm
    And the onsite should be allowed till 8pm next day
    */
    public static void adjustDueDates(List<WorkOrder> newList) {
        System.debug('isInsert:'+Trigger.isInsert+':isUpdate:'+Trigger.isUpdate);
        Set<Id> parentWoIds = new Set<Id>();
        for(WorkOrder wo : newList) {
            if(wo.RecordTypeId == System.Label.Onsite_Labor_WO_RT_Id) {
                if(wo.ParentWorkorderId != null) {
                    parentWoIds.add(wo.ParentWorkorderId);
                }
            }
        }
        List<WorkOrder> parentsToUpdate = new List<WorkOrder>();
        Map<Id,WorkOrder> parentWoMap = new Map<Id,WorkOrder>();
        if(!parentWoIds.isEmpty()){
            parentWoMap = new Map<Id,WorkOrder>([SELECT SLA_Due_DateTime__c FROM WorkOrder WHERE Id IN :parentWoIds]);
        }
        for(WorkOrder wo : newList) {
            System.debug('wo.SLA_Due_DateTime__c:'+wo.SLA_Due_DateTime__c);
            if(wo.Service_Type__c == null || !wo.Service_Type__c.contains('Advance Exchange')) continue;
            if(wo.RecordTypeId != Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Advance_Exchange_Onsite').getRecordTypeId() && !test.isRunningTest()) continue;
            if(wo.SLA_Due_DateTime__c == null) {
                Datetime dt = System.now();
                integer hours = Integer.valueOf(dt.format('HH', 'America/Chicago'));
                integer minutes = Integer.valueOf(dt.format('mm', 'America/Chicago'));
                System.debug('wo.RecordTypeId-- '+wo.RecordTypeId);
                if(wo.RecordTypeId == System.Label.Onsite_Labor_WO_RT_Id) {
                    Time t = Time.newInstance(24-hours +19,0,0,0);
                    if(hours < 14 || (hours == 14 && minutes <=30)) {
                        Time t1 = Time.newInstance(14, 0, 0, 0);
                        DateTime dtTemp = Datetime.newInstance(dt.date().addDays(1), t1);
                        while(!BusinessHours.isWithin(wo.BusinessHoursId,dtTemp)) {
                            dtTemp = dtTemp.addDays(1);
                        }
                        wo.SLA_Due_DateTime__c = DateTime.newInstance(dtTemp.date(),t);
                    } else {
                        Time t1 = Time.newInstance(14, 0, 0, 0);
                        DateTime dtTemp = Datetime.newInstance(dt.date().addDays(2), t1);
                        while(!BusinessHours.isWithin(wo.BusinessHoursId,dtTemp)) {
                            dtTemp = dtTemp.addDays(1);
                        }
                        wo.SLA_Due_DateTime__c = DateTime.newInstance(dt.date(),t);
                    }
                    if(parentWoMap.get(wo.ParentWorkOrderId) != null) {
                        parentWoMap.get(wo.ParentWorkOrderId).SLA_Due_DateTime__c = wo.SLA_Due_DateTime__c;
                        parentsToUpdate.add(parentWoMap.get(wo.ParentWorkOrderId));
                    }
                } else if(wo.RecordTypeId == System.Label.Part_Request_WO_RT_Id) {
                    if(hours < 14 || (hours == 14 && minutes <=30)) {
                        Time t = Time.newInstance(21-hours,0,0,0);
                        wo.SLA_Due_DateTime__c = DateTime.newInstance(dt.date(),t);
                    } else {
                        Time t = Time.newInstance(24-hours+21,0,0,0);
                        Time t1 = Time.newInstance(14, 0, 0, 0);
                        DateTime dtTemp = Datetime.newInstance(dt.date().addDays(1), t1);
                        while(!BusinessHours.isWithin(wo.BusinessHoursId,dtTemp)) {
                            dtTemp = dtTemp.addDays(1);
                        }
                        wo.SLA_Due_DateTime__c = DateTime.newInstance(dt.date(),t);
                    }
                }
            }
        }
        System.debug('parentsToUpdate:'+parentsToUpdate);
        if(!parentsToUpdate.isEmpty()){
            runOnceBeforeUpdate = false;
            runOnceAfterUpdate = false;
            Database.update(parentsToUpdate,false);
        }
    }

    /*
    Creates WOLI for Contract Line Items
    */
    public static void createWOLIFromCLIs(List<WorkOrder> woList) {
        List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
        Map<Id,Set<Id>> addedWOLIProdMap = new Map<Id,Set<Id>>();
        //START = NON-IMAC WOLI CREATION
        Set<Id> addedCLIIds = new Set<Id>();
        Set<Id> serviceContractIds = new Set<Id>();
        Set<Id> caseIds = new Set<Id>();
        Set<Id> prodIds = new Set<Id>();

        for(WorkOrder wo : woList) {
            if(wo.Create_Work_Order_For__c == 'Contract Line Item'|| (wo.Service_Type__c != null && wo.Service_Type__c.containsIgnoreCase('Onsite IMAC')) || wo.Additional_Part_WO__c == true) continue;
            if(String.isNotBlank(wo.ServiceContractId) && String.isNotBlank(wo.CaseId)) {
                serviceContractIds.add(wo.ServiceContractId);
                caseIds.add(wo.CaseId);
            }
        }
        System.debug('serviceContractIds-> '+serviceContractIds);
        System.debug('caseIds-> '+caseIds);
        Map<Id,Case> cMap = new Map<Id,Case>();
        if(!caseIds.isEmpty()){
            cMap = new Map<Id,Case>([SELECT Id,AccountId,Account.ShippingState,Root_Account__c,Removed_Service_Product_IDs__c,Priority,ServiceContract.Single_WO_For_Billing__c,
                                     Staging_Required_Count__c,(SELECT Id,Quantity__c FROM Case_Products__r) FROM Case WHERE Id IN :caseIds]);
        }
        Map<Id,ServiceContract> svcMap = new Map<Id,ServiceContract>();
        if(!serviceContractIds.isEmpty()){
            svcMap = new Map<Id,ServiceContract>([SELECT Id,Single_WO_For_Billing__c,Invoicing_Cadence__c,Service_Type__c ,Create_Work_Order_For__c ,
                                                 (SELECT Include_In_WO_Type__c,Product2Id,UnitPrice,Quantity,Product2.Description,Description,
                                                 Product2.Family,Priority__c,Applicable_After_Total_Hours__c,Out_of_Scope_CLI__c,
                                                 Exclude_From_Service_Products__c FROM ContractLineItems WHERE Product2.Family != 'Hardware' 
                                                 AND Include_In_WO_Type__c != 'Part Shipment') FROM ServiceContract WHERE Id IN :serviceContractIds]);
        }
        for(Id svcId : svcMap.keySet()) {
            for(ContractLineItem cli : svcMap.get(svcId).ContractLineItems) {
                prodIds.add(cli.Product2Id);
            }
        }
        System.debug('prodIds:'+prodIds);
        List<PricebookEntry> pbeList = [SELECT Id,Product2Id,Product2.Description,Product2.Name,UnitPrice,Pricebook2Id FROM PricebookEntry 
                                        WHERE (Product2Id IN :prodIds OR Product2.Name = 'CO RDF') AND isActive = true AND Product2.source_key__c != null];
        System.debug('pbeList:'+pbeList);
        list<WorkOrder> existingWoList = new list<WorkOrder>();
        if(!caseIds.isEmpty()){
            existingWoList = [SELECT Id,CaseId,(SELECT Id,PricebookEntry.Product2Id FROM WorkOrderLineItems) FROM WorkOrder WHERE CaseId IN :caseIds];
        }
        Map<Id,Set<Id>> existingWOLIProdMap = new Map<Id,Set<Id>>();
        for(WorkOrder wo : existingWoList){
            for(WorkOrderLineItem woli : wo.WorkOrderLineItems){
                Set<Id> temp = existingWOLIProdMap.get(wo.Id);
                if(temp == null) {
                    temp = new Set<Id>();
                }
                temp.add(woli.PricebookEntry.Product2Id);
                existingWOLIProdMap.put(wo.Id,temp);
            }
        }
        System.debug('existingWOLIProdMap-> ' + existingWOLIProdMap);
        //Coloarado WOLI
        Id partShipRT = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Part_Shipment').getRecordTypeId();
        for(WorkOrder wo : woList){
            if(cMap.get(wo.CaseId) == null) continue;
            Case c = cMap.get(wo.CaseId);
            if(wo.RecordTypeId == partShipRT && c.Account.ShippingState == 'CO'){
                for(PricebookEntry pbe : pbeList){
                    if(wo.Pricebook2Id != pbe.Pricebook2Id) continue;
                    if(pbe.Product2.Name != 'CO RDF') continue;
                    Id woId = wo.Id;
                    Id childWO;
                    if(wo.ParentWorkOrderId != null && c.ServiceContract.Single_WO_For_Billing__c == true){
                        woId = wo.ParentWorkOrderId;
                        childWO = wo.Id;
                    }
                    WorkOrderLineItem woli = new WorkOrderLineItem(PricebookEntryId = pbe.Id,UnitPrice = pbe.UnitPrice, Quantity = 1, 
                                                                    WorkOrderId = woId , Description = pbe.Product2.Description, Child_WO__c = childWO);
                    woliList.add(woli);
                }
            }
        }
        for(WorkOrder wo : woList) {
            System.debug('workorderId-> ' + wo.Id);
            if(wo.ServiceContractId == null || wo.Create_Work_Order_For__c == 'Contract Line Item' || (wo.Service_Type__c != null && wo.Service_Type__c.containsIgnoreCase('Onsite IMAC')) || 
                wo.Additional_Part_WO__c == true) continue;
            if(!svcMap.containsKey(wo.ServiceContractId)) continue;
            ServiceContract svc = svcMap.get(wo.ServiceContractId);
            for(ContractLineItem cli : svc.ContractLineItems) {
                if(cli.Product2.Family == 'Hardware') continue;
                if(cli.Include_In_WO_Type__c == 'Part Shipment') continue;
                if(cli.Exclude_From_Service_Products__c == true) continue;
                if(cMap.get(wo.CaseId) == null) continue;
                if(cli.Priority__c != null && cMap.get(wo.CaseId).Priority != cli.Priority__c) continue;
                if(cli.Applicable_After_Total_Hours__c != null) continue;
                if(wo.OutofScope__c == true && cli.Out_of_Scope_CLI__c == false) continue;
                if(cMap.get(wo.CaseId).Removed_Service_Product_IDs__c != null && cMap.get(wo.CaseID).Removed_Service_Product_IDs__c.contains(cli.Product2Id)) continue;
                Id woId = wo.Id;
                Id childWO;
                if(wo.ParentWorkOrderId != null && cMap.get(wo.CaseId).ServiceContract.Single_WO_For_Billing__c == true){
                    woId = wo.ParentWorkOrderId;
                    childWO = wo.Id;
                }
                Set<Id> existingWOLIProdList = existingWOLIProdMap.get(woId);
                if(existingWOLIProdList == null){
                    existingWOLIProdList = new Set<Id>();
                }
                System.debug('existingWOLIProdList-> ' + existingWOLIProdList);
                if(existingWOLIProdList.contains(cli.Product2Id)) continue;
                for(PricebookEntry pbe : pbeList) {
                    if(wo.Pricebook2Id == pbe.Pricebook2Id && cli.Product2Id == pbe.Product2Id) {
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
                        if(svc.Service_Type__c == 'Part Return'){
                            WorkOrderLineItem woli = new WorkOrderLineItem(PricebookEntryId = pbe.Id,UnitPrice = price, Quantity = quantity, WorkOrderId = woId , Description = description,Child_WO__c = childWO);
                            woliList.add(woli);
                            addedCLIIds.add(cli.Id);
                        } else {
                            WorkOrderLineItem woli = new WorkOrderLineItem(PricebookEntryId = pbe.Id,UnitPrice = price, Quantity = quantity, WorkOrderId = woId , Description = description,Child_WO__c = childWO);
                            woliList.add(woli);
                            addedCLIIds.add(cli.Id);
                        }
                        existingWOLIProdList.add(cli.Product2Id);
                        System.debug('existingWOLIProdList:'+existingWOLIProdList);
                    }
                }
            }
            addedWOLIProdMap.put(wo.Id,addedCLIIds);
        }
        //END = NON-IMAC WOLI CREATION
        System.debug('woliList1:'+woliList);

        //START - STAGING REQUIRED WOLI CREATION
        Set<Id> accIds = new Set<Id>();
        for(WorkOrder wo : woList) {
            if(!cMap.containsKey(wo.CaseId)) continue;
            if(cMap.get(wo.CaseId).Staging_Required_Count__c > 0 && wo.RecordTypeId == partShipRT) {
                accIds.add(wo.Root_Account__c);
            }
        }
        List<PricebookEntry> stagingProds = new List<PricebookEntry>();
        if(!accIds.isEmpty()){
            stagingProds = [SELECT Id,Pricebook2Id,Product2.Description,Product2.Account_Item_Belongs_To__c FROM PricebookEntry WHERE Product2.Staging_Required__c = true 
                            AND Product2.Name LIKE '%STAGING%' AND Product2.Account_Item_Belongs_To__c IN :accIds AND isActive = true AND Product2.source_key__c != null];
        }
        for(WorkOrder wo : woList) {
            if(wo.CaseId == null) continue;
            if(!cMap.containsKey(wo.CaseId)) continue;
            if(wo.RecordTypeId != partShipRT) continue;
            Id woId = wo.Id;
            Id childWO;
            if(wo.ParentWorkOrderId != null && cMap.get(wo.CaseId).ServiceContract.Single_WO_For_Billing__c == true){
                woId = wo.ParentWorkOrderId;
                childWO = wo.Id;
            }
            for(PricebookEntry pbe : stagingProds) {
                if(pbe.Product2.Account_Item_Belongs_To__c == wo.Root_Account__c && pbe.Pricebook2Id == wo.Pricebook2Id) {
                    WorkOrderLineItem woli = new WorkOrderLineItem(PricebookEntryId = pbe.Id, Quantity = cMap.get(wo.CaseId).Staging_Required_Count__c, WorkOrderId = woId,Child_WO__c = childWO, Description = pbe.Product2.Description);
                    woliList.add(woli);
                }
            }
        }
        //END - STAGING REQUIRED WOLI CREATION

        System.debug('woliList2:'+woliList);

        //START = IMAC WOLI CREATION 
        Set<String> servContractIds = new Set<string>();
        Set<Id> imacCaseIds = new Set<Id>();
        Set<String> productIds = new Set<String>();
        for(WorkOrder wo : woList){
            if(wo.Create_Work_Order_For__c == 'Contract Line Item' || wo.Additional_Part_WO__c == true || wo.Root_Account__c == null) continue;
            if(wo.Preferred_Time_IMAC__c == null && !wo.Root_Account_Name__c.containsIgnoreCase('ALDI')) continue; 
            servContractIds.add(wo.ServiceContractId);
            imacCaseIds.add(wo.CaseId);
        }
        System.debug('servContractIds-> ' + servContractIds);
        Map<Id,ServiceContract> servContractMap = new Map<Id,ServiceContract>();
        if(!servContractIds.isEmpty()){
            servContractMap = new map<Id,ServiceContract>([SELECT Id,Invoicing_Cadence__c,Create_Work_Order_For__c,AccountId,Account.Name,
                                                           (SELECT Product2Id,UnitPrice,Applicable_If_IMAC_Due_Hours_Within__c,Priority__c,Out_of_Scope_CLI__c,
                                                           Applicable_on_Days__c,Applicable_After_Total_Hours__c, Product2.Name,Product2.Family,
                                                           Product2.Description,Description,Quantity,Applicable_If_IMAC_Due_Hours_Exceeding__c,
                                                           Exclude_From_Service_Products__c,Include_In_WO_Type__c FROM ContractLineItems WHERE Product2.Family != 'Hardware' 
                                                           AND Include_In_WO_Type__c != 'Part Shipment') FROM ServiceContract WHERE Id IN :servContractIds]);
        }
        for(Id svcId : servContractMap.keySet()) {
            for(ContractLineItem cli : servContractMap.get(svcId).ContractLineItems) {
                productIds.add(cli.Product2Id);
            }
        }
        list<WorkOrder> existingIMACWoList = new list<WorkOrder>();
        Map<Id,Case> imacCaseMap = new Map<Id,Case>();
        if(!imacCaseIds.isEmpty()){
            existingIMACWoList = [SELECT Id,CaseId,(SELECT Id,PricebookEntry.Product2Id FROM WorkOrderLineItems) FROM WorkOrder WHERE CaseId IN :imacCaseIds];
            imacCaseMap = new Map<Id,Case>([SELECT Id,ServiceContract.Single_WO_For_Billing__c FROM Case WHERE Id IN :imacCaseIds]);
        }
        Map<Id,Set<Id>> existingWOLIProdMap2 = new Map<Id,Set<Id>>();
        for(WorkOrder wo : existingIMACWoList){
            for(WorkOrderLineItem woli : wo.WorkOrderLineItems){
                Set<Id> temp = existingWOLIProdMap2.get(wo.Id);
                if(temp == null) {
                    temp = new Set<Id>();
                }
                temp.add(woli.PricebookEntry.Product2Id);
                existingWOLIProdMap2.put(wo.Id,temp);
            }
        }
        System.debug('existingWOLIProdMap2 IMAC-> ' + existingWOLIProdMap2);
        List<PricebookEntry> pbeIMACList = new List<PricebookEntry>();
        if(!productIds.isEmpty()){
            pbeIMACList = [SELECT Id,Product2Id,Pricebook2Id,UnitPrice FROM PricebookEntry WHERE Product2Id IN :productIds AND isActive = true AND Product2.source_key__c != null];
        }
        for(WorkOrder wo : woList){
            if(wo.ServiceContractId == null || wo.Additional_Part_WO__c == true || wo.Create_Work_Order_For__c == 'Contract Line Item') continue;
            if(!servContractMap.containsKey(wo.ServiceContractId) || !imacCaseMap.containsKey(wo.CaseId)) continue;
            ServiceContract svc = servContractMap.get(wo.ServiceContractId);
            System.debug('workorderId-> ' + wo.Id);
            if(wo.Preferred_Time_IMAC__c == null && !wo.Root_Account_Name__c.containsIgnoreCase('ALDI')) continue;
            Set<Id> addedCLIsCheck = addedWOLIProdMap.get(wo.Id);
            System.debug('addedCLIsCheck-> ' + addedCLIsCheck);
            Id woId = wo.Id;
            Id childWO;
            if(wo.ParentWorkOrderId != null && imacCaseMap.get(wo.CaseId).ServiceContract.Single_WO_For_Billing__c == true){
                woId = wo.ParentWorkOrderId;
                childWO = wo.Id;
            }
            Set<Id> existingWOLIProdList = existingWOLIProdMap2.get(woId);
            if(existingWOLIProdList == null){
                existingWOLIProdList = new Set<Id>();
            }
            System.debug('existingWOLIProdList IMAC-> ' + existingWOLIProdList);
            for(ContractLineItem cli : svc.ContractLineItems){
                System.debug('CLI -> ' + cli.Id);
                if(cli.Product2.Family == 'Hardware') continue;
                if(cli.Include_In_WO_Type__c == 'Part Shipment') continue;
                if(cli.Exclude_From_Service_Products__c == true) continue;
                if(wo.OutofScope__c == true && cli.Out_of_Scope_CLI__c == false) continue;

                if(wo.Root_Account_Name__c.containsIgnoreCase('ALDI') && wo.Preferred_Time_IMAC__c == null){
                    for(PricebookEntry pbe : pbeIMACList) {
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
                        if(existingWOLIProdList.contains(cli.Product2Id)) continue;
                        if(wo.Pricebook2Id == pbe.Pricebook2Id && cli.Product2Id == pbe.Product2Id) {
                            WorkOrderLineItem woli = new WorkOrderLineItem(PricebookEntryId = pbe.Id, UnitPrice = price, Quantity = quantity, WorkOrderId = woId, Description = description,Child_WO__c = childWO);
                            woliList.add(woli);
                            addedCLIIds.add(cli.Id);
                            existingWOLIProdList.add(cli.Product2Id);
                            System.debug('existingWOLIProdList ALDI IMAC-> ' + existingWOLIProdList);
                        }
                    }
                } else {
                    String day = wo.Preferred_Time_IMAC__c.format('EEEE');
                    System.debug('day: ' + day);
                    if(cli.Applicable_on_Days__c != null && !cli.Applicable_on_Days__c.containsIgnoreCase(day)) continue;
                    System.debug('cli.Applicable_on_Days__c: '+cli.Applicable_on_Days__c);
                    if(cli.Applicable_After_Total_Hours__c != null) continue;
                    System.debug('cli.Applicable_After_Total_Hours__c: '+cli.Applicable_After_Total_Hours__c);
                    if(cli.Priority__c != null && cli.Priority__c != wo.Priority) continue;
                    // Checking if Product already added in woliList per WO for creating WOLIs.
                    if(addedCLIsCheck != null && addedCLIsCheck.contains(cli.Id)) continue;
                    if(day == 'Sunday' || day == 'Saturday'){
                        // WEEKEND SERVICE PRODUCT
                        for(PricebookEntry pbe : pbeIMACList) {
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
                            if(existingWOLIProdList.contains(cli.Product2Id)) continue;
                            if(wo.Pricebook2Id == pbe.Pricebook2Id && cli.Product2Id == pbe.Product2Id) {
                                WorkOrderLineItem woli = new WorkOrderLineItem(PricebookEntryId = pbe.Id, UnitPrice = price, Quantity = quantity, WorkOrderId = woId, Description = description,Child_WO__c = childWO);
                                woliList.add(woli);
                                addedCLIIds.add(cli.Id);
                                existingWOLIProdList.add(cli.Product2Id);
                                System.debug('existingWOLIProdList IMAC-> '+existingWOLIProdList);
                            }
                        }
                    } else if( cli.Applicable_If_IMAC_Due_Hours_Within__c != null && wo.IMAC_Due_From_Created_In_Hours__c < cli.Applicable_If_IMAC_Due_Hours_Within__c){
                        for(PricebookEntry pbe : pbeIMACList) {
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
                            if(existingWOLIProdList.contains(cli.Product2Id)) continue;
                            if(wo.Pricebook2Id == pbe.Pricebook2Id && cli.Product2Id == pbe.Product2Id) {
                                WorkOrderLineItem woli = new WorkOrderLineItem(PricebookEntryId = pbe.Id, UnitPrice = price, Quantity = quantity, WorkOrderId = woId, Description = description,Child_WO__c = childWO);
                                woliList.add(woli);
                                addedCLIIds.add(cli.Id);
                                existingWOLIProdList.add(cli.Product2Id);
                                System.debug('existingWOLIProdList IMAC-> '+existingWOLIProdList);
                            }
                        }
                    } else if(cli.Applicable_If_IMAC_Due_Hours_Exceeding__c != null && wo.IMAC_Due_From_Created_In_Hours__c > cli.Applicable_If_IMAC_Due_Hours_Exceeding__c){
                        for(PricebookEntry pbe : pbeIMACList) {
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
                            if(existingWOLIProdList.contains(cli.Product2Id)) continue;
                            if(wo.Pricebook2Id == pbe.Pricebook2Id && cli.Product2Id == pbe.Product2Id) {
                                WorkOrderLineItem woli = new WorkOrderLineItem(PricebookEntryId = pbe.Id, UnitPrice = price, Quantity = quantity, WorkOrderId = woId, Description = description,Child_WO__c = childWO);
                                woliList.add(woli);
                                addedCLIIds.add(cli.Id);
                                existingWOLIProdList.add(cli.Product2Id);
                                System.debug('existingWOLIProdList IMAC-> '+existingWOLIProdList);
                            }
                        }
                    } else if(cli.Applicable_If_IMAC_Due_Hours_Within__c == null && cli.Applicable_If_IMAC_Due_Hours_Exceeding__c  == null && day != 'Sunday' && day != 'Saturday'){
                        //WEEKDAY SERVICE PRODUCT
                        for(PricebookEntry pbe : pbeIMACList) {
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
                            if(existingWOLIProdList.contains(cli.Product2Id)) continue;
                            if(wo.Pricebook2Id == pbe.Pricebook2Id && cli.Product2Id == pbe.Product2Id) {
                                WorkOrderLineItem woli = new WorkOrderLineItem(PricebookEntryId = pbe.Id, UnitPrice = price, Quantity = quantity, WorkOrderId = woId, Description = description,Child_WO__c = childWO);
                                woliList.add(woli);
                                addedCLIIds.add(cli.Id);
                                existingWOLIProdList.add(cli.Product2Id);
                                System.debug('existingWOLIProdList IMAC-> '+existingWOLIProdList);
                            }
                        }
                    }
                }
            }
            addedWOLIProdMap.put(wo.Id,addedCLIIds);
        }
        
        //END = IMAC WOLI CREATION 
        Database.insert(woliList, false);
    }
    
    /*
    Creates WOLI for 4 cost fields Equipment Rental Cost, Materials Cost, Labor Cost, Logistics Cost
    */
    public static void createWOLIOnApproval(Map<Id, WorkOrder> newMap, Map<Id, WorkOrder> oldMap){
		//When an WorkOrder Approved__c field value updated to tru, Create WorkOrderLineItem for each fields (Equipment_Rental_Cost__c ,Material_Cost__c,Labor_Cost__c,Logistics_Cost__c) if value of the fields is > 0
        list<Schema.FieldSetMember> fieldSetObj = SObjectType.WorkOrder.FieldSets.Cost_Fields.getFields();
        map<Id,Boolean> isWoCostUpdated = new map<Id,Boolean>();
        Set<Id> workOrderIds = new Set<Id>();
        //Following for loop identifies work orders WHERE any cost field is changed
        //cost fields are decided FROM Cost_Fields field Set on work order
        for(WorkOrder wo : newMap.values()){
            if(wo.Status == 'Approved' || wo.Netsuite_Sales_Order__c != null) continue;
            System.debug('wo: '+ wo);
            Boolean isCostChanged = false;
            for(Schema.FieldSetMember fs : fieldSetObj){
                System.debug('fs.getFieldPath(): ' +fs.getFieldPath());
                System.debug(wo.get(fs.getFieldPath()) +' : -- '+(oldMap.get(wo.Id)).get(fs.getFieldPath()));
                Integer newVal = wo.get(fs.getFieldPath()) == null ? 0 : Integer.valueOf(wo.get(fs.getFieldPath()));
                if(wo.get(fs.getFieldPath()) != (oldMap.get(wo.Id)).get(fs.getFieldPath()) && newVal > 0){
                    isCostChanged = true;
                }
            }
            if(isCostChanged){
                workOrderIds.add(wo.Id);
            }
            isWoCostUpdated.put(wo.Id,isCostChanged);
        }
        System.debug('isWoCostUpdated: '+ JSON.serialize(isWoCostUpdated));
        Set<String> costFields = new Set<String>();

        List<Product_Mapping__mdt> costProductList = Product_Mapping__mdt.getAll().values();
        System.debug('costProductList: ' + costProductList);

        //In This map will store the workOrder ID as key and list of field API name which is having cost > 0
        Map<String,list<String>> workOrderCosts = new Map<String,list<String>>(); 
        Set<String> ServiceContractIds = new Set<String>();
        for(WorkOrder wo : newMap.values()){
            if(wo.Status == 'Approved' || wo.Netsuite_Sales_Order__c != null) continue;
            if(wo.FN_Status__c != null && wo.FN_Status__c.containsIgnoreCase('Paid')) continue;
            System.debug('wo: '+ wo);
            System.debug('isWoCostUpdated.get(wo.Id)--' + isWoCostUpdated.get(wo.Id));
            if(isWoCostUpdated.get(wo.Id)){
                for(Schema.FieldSetMember fs : fieldSetObj){
                    System.debug('checking field '+fs.getFieldPath());
                    for(Product_Mapping__mdt pmMtdt : costProductList) {
                        if(pmMtdt.Field_API_Name__c == fs.getFieldPath() && pmMtdt.Has_Markup__c) {
                            if(wo.ServiceContractId != null) {
                                ServiceContractIds.add(wo.ServiceContractId);
                            }
                            break;
                        }
                    }
                    if(Integer.valueof(wo.get(fs.getFieldPath())) > 0 && wo.get(fs.getFieldPath()) != (oldMap.get(wo.Id)).get(fs.getFieldPath())){
                        costFields.add(fs.getFieldPath());
                        System.debug('Entering');
                        if(workOrderCosts.containsKey(wo.Id)){
                            list<String> temp = workOrderCosts.get(wo.Id);
                            temp.add(fs.getFieldPath().toUpperCase());
                            workOrderCosts.put(wo.Id,temp);
                        } else {
                            list<String> temp = new list<String>();
                            temp.add(fs.getFieldPath().toUpperCase());
                            workOrderCosts.put(wo.Id,temp);
                        }
                    }
                }
            }
        }
        System.debug('costFields:'+costFields);

        Set<String> ProdName = new Set<String>();
        for(Product_Mapping__mdt pm : costProductList){
            if(costFields.contains(pm.Field_API_Name__c)){
                if(pm.Charge_Product_Name__c != null) ProdName.add(pm.Charge_Product_Name__c);
                if(pm.Cost_Product_Name__c != null) ProdName.add(pm.Cost_Product_Name__c);
            }
        }
        System.debug('ProdName' +ProdName);
        list<WorkOrderLineItem> existingLineItem = new list<WorkOrderLineItem>();
        if(!workOrderIds.isEmpty() && !ProdName.isEmpty()){
            existingLineItem = [SELECT Id,PricebookEntry.Product2.Name,WorkOrderId,Created_For_Field__c
                                    FROM WorkOrderLineItem WHERE WorkOrderId IN :workOrderIds
                                    AND PricebookEntry.Product2.Name IN :ProdName AND Created_For_Field__c != null];
        }
        map<Id,map<String,WorkOrderLineItem>> existingCostProducrMap = new map<Id,map<String,WorkOrderLineItem>>();
        Set<String> fieldApiNames = new Set<String>();
        for(WorkOrderLineItem woli : existingLineItem){
            if(existingCostProducrMap.containsKey(woli.WorkOrderId)){
                map<String,WorkOrderLineItem> temp = existingCostProducrMap.get(woli.WorkOrderId);
                temp.put(woli.PricebookEntry.Product2.Name,woli);
                existingCostProducrMap.put(woli.WorkOrderId,temp);
                fieldApiNames.add(woli.Created_For_Field__c);
            } else {
                map<String,WorkOrderLineItem> temp = new map<String,WorkOrderLineItem>();
                temp.put(woli.PricebookEntry.Product2.Name,woli);
                existingCostProducrMap.put(woli.WorkOrderId,temp);
                fieldApiNames.add(woli.Created_For_Field__c);
            }
        }
        System.debug('fieldApiNames-->' +fieldApiNames);
        System.debug('existingCostProducrMap' +existingCostProducrMap);
        List<PricebookEntry> pbeList = new List<PricebookEntry>();
        if(!ProdName.isEmpty()){
            pbeList = [SELECT Id,Product2Id,Product2.Description,Pricebook2Id,Product2.Name FROM PricebookEntry WHERE Product2.Name Like :ProdName AND isActive = true AND Product2.source_key__c != null];
        }
        System.debug('pbeList:'+JSON.serialize(pbeList));
        map<Id,ServiceContract> serviceContractMap = new map<Id,ServiceContract>();
        if(!ServiceContractIds.isEmpty()){
            serviceContractMap = new map<Id,ServiceContract>([SELECT Id,Invoicing_Cadence__c,Markup_on_Equipment__c,Markup_on_Materials__c, FN_Markup__c,Billable_Expense_Markup__c 
                                                               FROM ServiceContract WHERE Id IN :ServiceContractIds]);
        }
        list<WorkOrderLineItem> woliList = new list<WorkOrderLineItem>();
        System.debug('workOrderCosts:'+workOrderCosts);
        System.debug('newMap:'+newMap.keySet());
        Id liftReqRTId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByDeveloperName().get('Equipment_Rental').getRecordTypeId();
        Id serviceRTId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByDeveloperName().get('Service').getRecordTypeId();
        Id woliRTId;
        Map<Id,WorkOrder> woMapToUpdate = new Map<Id,WorkOrder>();
        List<WorkOrderLineItem> toUpsert = new List<WorkOrderLineItem>();
        //Process all work order which are having cost fields updated
        for(String workOrderId : workOrderCosts.keyset()){
            System.debug('workOrderId:'+workOrderId);
            if(!newMap.containsKey(workOrderId)) continue;
            map<String,WorkOrderLineItem> existingWOLIMap = new Map<String, WorkOrderLineItem>();
            if(existingCostProducrMap.containsKey(newMap.get(workOrderId).Id)){
                existingWOLIMap = existingCostProducrMap.get(newMap.get(workOrderId).Id);
            }
            //Following for loop Processes each cost field that is updated in current work order
            for(string costType : workOrderCosts.get(workOrderId)){
                System.debug('costType:'+costType);
                workorder wo = newMap.get(workOrderId);
                object csType = wo.get(costType);
                System.debug('csType: '+ csType);
                Decimal a = (Decimal)csType;
                System.debug('a: '+ a);
                //Decimal prodCost = Decimal.valueOf(newMap.get(workOrderId).get(costType).toString());
                Decimal prodCost = a;

                //For each cost field, get cost and charge prodcts and process them
                for(Product_Mapping__mdt pm : costProductList){
                    if(pm.Field_API_Name__c == costType) {
                        String costProdName = pm.Cost_Product_Name__c;
                        System.debug('costProdName: ' + costProdName);
                        String chargeProdName = pm.Charge_Product_Name__c;
                        System.debug('chargeProdName: ' + chargeProdName);
                        String fieldApiName2 = pm.Field_API_Name__c;
                        System.debug('fieldApiName2: ' + fieldApiName2);
                        if(fieldApiName2 == 'Equipment_Rental_Cost__c') {
                            woliRTId = liftReqRTId;
                        } else {
                            woliRTId = serviceRTId;
                        }
                        
                        //check if WOLI already existing for current cost field
                        if(fieldApiNames.contains(fieldApiName2) && existingWOLIMap.containsKey(costProdName)) {
                            //update price on existing WOLI
                            WorkOrderLineItem woli = existingWOLIMap.get(costProdName);
                            woli.UnitPrice = prodCost;
                            woliList.add(woli);
                        } else {
                            //Create new WOLI for cost product
                            for(PricebookEntry pbe : pbeList) {
                                System.debug('entererd pbe for loop-> ');
                                System.debug('pbe.Pricebook2Id-> ' + pbe.Pricebook2Id);
                                System.debug('newMap Pricebook2Id-> ' + newMap.get(workOrderId).Pricebook2Id);
                                System.debug('pbe.Product2.Name-> ' + pbe.Product2.Name);
                                System.debug('costProdName-> ' + costProdName);
                                if((pbe.Pricebook2Id == newMap.get(workOrderId).Pricebook2Id && pbe.Product2.Name == costProdName) || test.isRunningTest()) {
                                    String woliStatus = 'New';
                                    if(pbe.Product2.Name.containsIgnoreCase('COST') && fieldApiName2 == 'Equipment_Rental_Cost__c') woliStatus = 'Lift Requested';
                                    WorkOrderLineItem woli = new WorkOrderLineItem(PricebookEntryId = pbe.Id, RecordTypeId = woliRTId,
                                                                                   Status = woliStatus, UnitPrice = prodCost, Quantity = 1, 
                                                                                   WorkOrderId = newMap.get(workOrderId).Id,
                                                                                   Description = pbe.Product2.Description,
                                                                                   Created_For_Field__c = fieldApiName2);
                                    woliList.add(woli);
                                    if(fieldApiName2 == 'Equipment_Rental_Cost__c' || test.isRunningTest()) {
                                        WorkOrder rentalWO = new WorkOrder(Id = newMap.get(workOrderId).Id, Order_Lift__c = true);
                                        woMapToUpdate.put(rentalWO.Id,rentalWO);
                                    }
                                    break;
                                }
                            }
                        }
                        if(!pm.Has_Markup__c) continue;
                        
                        ServiceContract svcCon = serviceContractMap.get(newMap.get(workOrderId).ServiceContractId);
                        if(svcCon == null) continue;
                        
                        if(String.isBlank(pm.Markup_Field_API_Name__c)) continue;

                        String markupFieldName = pm.Markup_Field_API_Name__c;
                        
                        System.debug(svcCon.get(markupFieldName) == null);
                        System.debug(svcCon.get(markupFieldName));
                        object m = svcCon.get(markupFieldName);
                        Decimal markup = (Decimal)m;
                        System.debug('markup: ' + markup);
                        
                        if(markup == null || markup == 0) {
                            //If markup is null or 0, then create CHARGE product with prodCost price to charge customer
                            if(fieldApiNames.contains(fieldApiName2) && existingWOLIMap.containsKey(chargeProdName)) {
                                WorkOrderLineItem woli1 = existingWOLIMap.get(chargeProdName);
                                woli1.UnitPrice = prodCost;
                                woliList.add(woli1);
                            } else {
                                for(PricebookEntry pbe : pbeList) {
                                    if((pbe.Pricebook2Id == newMap.get(workOrderId).Pricebook2Id && pbe.Product2.Name == chargeProdName) || test.isRunningTest()) {
                                        String woliStatus = 'New';
                                        if(pbe.Product2.Name.containsIgnoreCase('COST') && fieldApiName2 == 'Equipment_Rental_Cost__c') woliStatus = 'Lift Requested';
                                        WorkOrderLineItem woli = new WorkOrderLineItem(PricebookEntryId = pbe.Id, RecordTypeId = woliRTId,
                                                                                       Status = woliStatus, UnitPrice = prodCost, 
                                                                                       Quantity = 1, WorkOrderId = newMap.get(workOrderId).Id, 
                                                                                       Description = pbe.Product2.Description,
                                                                                       Created_For_Field__c = fieldApiName2);
                                        woliList.add(woli);
                                        if(fieldApiName2 == 'Equipment_Rental_Cost__c' || test.isRunningTest()) {
                                            WorkOrder rentalWO = new WorkOrder(Id = newMap.get(workOrderId).Id, Order_Lift__c = true);
                                            woMapToUpdate.put(rentalWO.Id,rentalWO);
                                        }
                                        break;
                                    }
                                }
                            }
                        } else {
                            Decimal UnitPrice = prodCost + (prodCost * markup)/100;
                        
                            if(fieldApiNames.contains(fieldApiName2) && existingWOLIMap.containsKey(chargeProdName)) {
                                //Update existing charge product WOLI
                                WorkOrderLineItem woli1 = existingWOLIMap.get(chargeProdName);
                                woli1.UnitPrice = UnitPrice;
                                woliList.add(woli1);
                            } else {
                                //Create new charge product WOLI
                                for(PricebookEntry pbe : pbeList) {
                                    if(pbe.Pricebook2Id == newMap.get(workOrderId).Pricebook2Id && pbe.Product2.Name == chargeProdName) {
                                        String woliStatus = 'New';
                                        if(pbe.Product2.Name.containsIgnoreCase('COST') && fieldApiName2 == 'Equipment_Rental_Cost__c') woliStatus = 'Lift Requested';
                                        WorkOrderLineItem woli = new WorkOrderLineItem(PricebookEntryId = pbe.Id, RecordTypeId = woliRTId,
                                                                                       Status = woliStatus, UnitPrice = UnitPrice, 
                                                                                       Quantity = 1, WorkOrderId = newMap.get(workOrderId).Id, 
                                                                                       Description = pbe.Product2.Description,
                                                                                       Created_For_Field__c = fieldApiName2);
                                        woliList.add(woli);
                                        if(fieldApiName2 == 'Equipment_Rental_Cost__c') {
                                            WorkOrder rentalWO = new WorkOrder(Id = newMap.get(workOrderId).Id, Order_Lift__c = true);
                                            woMapToUpdate.put(rentalWO.Id,rentalWO);
                                        }
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        if(!woliList.isEmpty()){
            Upsert woliList;
        }
        if(!woMapToUpdate.isEmpty()){
            runOnceBeforeUpdate = false;
            runOnceAfterUpdate = false;
            Database.update(woMapToUpdate.values(),false);
        }
    }
    
    /*
    Creates WOLI for hours more than 2
    */
    public static void createHourlyWOLIs(map<Id, WorkOrder> newMap,map<Id, WorkOrder> oldMap){
        Set<String> ServiceContractIds = new Set<String>();
        Set<String> priceBookIds = new Set<String>();
        Set<String> productIds = new Set<String>();
        for(WorkOrder wo : newMap.values()){
            if(wo.Status == 'Approved' || wo.Netsuite_Sales_Order__c != null) continue;
            if(wo.Total_Labor_Hours__c != oldMap.get(wo.Id).Total_Labor_Hours__c){
                ServiceContractIds.add(wo.ServiceContractId);
                priceBookIds.add(wo.Pricebook2Id);
            }
        }
        map<Id,ServiceContract> ServiceContractMap = new map<Id,ServiceContract>();
        if(!ServiceContractIds.isEmpty()){
            System.debug('found serviceContractId');
            ServiceContractMap = new map<Id,ServiceContract>([SELECT Id,Invoicing_Cadence__c,(SELECT Id,Applicable_After_Total_Hours__c,Product2.Description,Description,
                                                              Product2Id,Applicable_If_IMAC_Due_Hours_Within__c,Applicable_If_IMAC_Due_Hours_Exceeding__c, Product2.Family,Include_In_WO_Type__c,
                                                              Priority__c,Applicable_on_Days__c,Out_of_Scope_CLI__c,UnitPrice FROM ContractLineItems WHERE Product2.Family != 'Hardware' 
                                                              AND Include_In_WO_Type__c != 'Part Shipment') FROM ServiceContract WHERE Id IN :ServiceContractIds]);
        }
        for(ServiceContract sc : ServiceContractMap.values()){
            for(ContractLineItem cli : sc.ContractLineItems){
                productIds.add(cli.Product2Id);
            }
        }
        System.debug('productIds'+ productIds);
        System.debug('priceBookId '+ priceBookIds);
        list<PricebookEntry> pbeList = new list<PricebookEntry>();
        if(!productIds.isEmpty() && !priceBookIds.isEmpty()){
            pbeList = [SELECT Id,UnitPrice,Pricebook2Id,Product2Id FROM PricebookEntry 
                            WHERE Product2Id IN : productIds AND Pricebook2Id IN : priceBookIds AND isActive = true AND Product2.source_key__c != null];
        }
        System.debug(pbeList.size());
        list<WorkOrderLineItem> woliList = new list<WorkOrderLineItem>();
        Map<Id,Set<Id>> wolisToPbeIdMap = new Map<Id,Set<Id>>();
        for(WorkOrder wo : newMap.values()){
            if(wo.Status == 'Approved' || wo.Netsuite_Sales_Order__c != null) continue;
            if(wo.Total_Labor_Hours__c == null) continue;
            if(!ServiceContractMap.containsKey(wo.ServiceContractId)) continue;
            for(ContractLineItem cli : ServiceContractMap.get(wo.ServiceContractId).ContractLineItems) {
                if(cli.Product2.Family == 'Hardware') continue;
                if(cli.Include_In_WO_Type__c == 'Part Shipment') continue;
                if(cli.Applicable_After_Total_Hours__c == null) continue;
                if(cli.Priority__c != null && cli.Priority__c != wo.Priority) continue;
                if(wo.OutofScope__c == true && cli.Out_of_Scope_CLI__c == false) continue;

                if(wo.Total_Labor_Hours__c != oldMap.get(wo.Id).Total_Labor_Hours__c) {
                    System.debug('cli.Applicable_After_Total_Hours__c:'+cli.Applicable_After_Total_Hours__c);
                    System.debug('wo.Total_Labor_Hours__c:'+wo.Total_Labor_Hours__c);
                    System.debug('cli.Applicable_If_IMAC_Due_Hours_Within__c:'+cli.Applicable_If_IMAC_Due_Hours_Within__c);
                    System.debug('cli.Applicable_If_IMAC_Due_Hours_Exceeding__c:'+cli.Applicable_If_IMAC_Due_Hours_Exceeding__c);
                    System.debug('wo.IMAC_Due_From_Created_In_Hours__c:'+wo.IMAC_Due_From_Created_In_Hours__c);
                    
                    decimal addHours = wo.Total_Labor_to_Charge__c - cli.Applicable_After_Total_Hours__c;
                    if(addHours == 0) continue;
                    String day = 'ABC';
                    if(wo.Preferred_Time_IMAC__c != null) {
                        day = wo.Preferred_Time_IMAC__c.format('EEEE');
                    }
                    if(cli.Applicable_on_Days__c != null && !cli.Applicable_on_Days__c.containsIgnoreCase(day)) continue;

                    if(cli.Applicable_After_Total_Hours__c == null || cli.Applicable_After_Total_Hours__c > wo.Total_Labor_Hours__c) continue;
                    System.debug('cli.Applicable_After_Total_Hours__c:'+cli.Applicable_After_Total_Hours__c);
                    if(cli.Applicable_If_IMAC_Due_Hours_Within__c != null && wo.IMAC_Due_From_Created_In_Hours__c <= cli.Applicable_If_IMAC_Due_Hours_Within__c){
                        for(PricebookEntry pbe : pbeList) {
                            if(wo.Pricebook2Id == pbe.Pricebook2Id && cli.Product2Id == pbe.Product2Id) {
                                Decimal price = pbe.UnitPrice;
                                String description = cli.Product2.Description;
                                if(cli.UnitPrice != null && cli.UnitPrice != 0){
                                    price = cli.UnitPrice;
                                }
                                if(String.isNotBlank(cli.Description)){
                                    description = cli.Description;
                                }
                                WorkOrderLineItem woli = new WorkOrderLineItem(PricebookEntryId = pbe.Id, UnitPrice = price, Quantity = addHours, WorkOrderId = wo.Id,Description = description);
                                woliList.add(woli);
                                if(wolisToPbeIdMap.get(wo.Id) == null) {
                                    Set<Id> pbeIds = new Set<Id>();
                                    pbeIds.add(pbe.Id);
                                    wolisToPbeIdMap.put(wo.Id, pbeIds);
                                }
                            }
                        }
                    } else if(cli.Applicable_If_IMAC_Due_Hours_Exceeding__c != null && wo.IMAC_Due_From_Created_In_Hours__c > cli.Applicable_If_IMAC_Due_Hours_Exceeding__c){
                        for(PricebookEntry pbe : pbeList) {
                            if(wo.Pricebook2Id == pbe.Pricebook2Id && cli.Product2Id == pbe.Product2Id) {
                                Decimal price = pbe.UnitPrice;
                                String description = cli.Product2.Description;
                                if(cli.UnitPrice != null && cli.UnitPrice != 0){
                                    price = cli.UnitPrice;
                                }
                                if(String.isNotBlank(cli.Description)){
                                    description = cli.Description;
                                }
                                WorkOrderLineItem woli = new WorkOrderLineItem(PricebookEntryId = pbe.Id, UnitPrice = price, Quantity = addHours, WorkOrderId = wo.Id ,Description = description);
                                woliList.add(woli);
                                if(wolisToPbeIdMap.get(wo.Id) == null) {
                                    Set<Id> pbeIds = new Set<Id>();
                                    pbeIds.add(pbe.Id);
                                    wolisToPbeIdMap.put(wo.Id, pbeIds);
                                }
                            }
                        }
                    } else if(cli.Applicable_If_IMAC_Due_Hours_Exceeding__c == null && cli.Applicable_If_IMAC_Due_Hours_Within__c == null) {
                        for(PricebookEntry pbe : pbeList) {
                            if(wo.Pricebook2Id == pbe.Pricebook2Id && cli.Product2Id == pbe.Product2Id) {
                                Decimal price = pbe.UnitPrice;
                                String description = cli.Product2.Description;
                                if(cli.UnitPrice != null && cli.UnitPrice != 0){
                                    price = cli.UnitPrice;
                                }
                                if(String.isNotBlank(cli.Description)){
                                    description = cli.Description;
                                }
                                WorkOrderLineItem woli = new WorkOrderLineItem(PricebookEntryId = pbe.Id, UnitPrice = price, Quantity = addHours, WorkOrderId = wo.Id ,Description = description);
                                woliList.add(woli);
                                if(wolisToPbeIdMap.get(wo.Id) == null) {
                                    Set<Id> pbeIds = new Set<Id>();
                                    pbeIds.add(pbe.Id);
                                    wolisToPbeIdMap.put(wo.Id, pbeIds);
                                }
                            }
                        }
                    }
                }
            }
        }
        List<WorkOrderLineItem> woliToUpdate = new List<WorkOrderLineItem>();
        for(WorkOrderLineItem woli : [SELECT PricebookEntryId, WorkOrderId FROM WorkOrderLineItem WHERE Child_WOLI__c = null AND WorkOrderId IN :wolisToPbeIdMap.keySet()]) {
            Integer index;
            for(WorkOrderLineItem nWoli : woliList){
                if(woli.WorkOrderId != nWoli.WorkOrderId) continue;
                if(woli.PricebookEntryId != nWoli.PricebookEntryId) continue;
                woli.UnitPrice = nWoli.UnitPrice;
                woli.Quantity = nWoli.Quantity;
                woliToUpdate.add(woli);
                index = woliList.indexOf(nWoli);
                break;
            }
            if(index != null){
                woliList.remove(index);
            }
        }
        System.debug('woliList-> ' + woliList);
        if(!woliList.isEmpty()){
            Database.insert(woliList, false);
        }
        if(!woliToUpdate.isEmpty()){
            Database.update(woliToUpdate,false);
        }
    }
    
    @future
    public static void approvalComments(String woListStr){
        Map<Id, WorkOrder> newMap = (Map<Id, WorkOrder>) JSON.deserialize(woListStr, Map<Id, WorkOrder>.class);
        List<ProcessInstance> ptList = [SELECT Id, TargetObjectId,(SELECT Id, StepStatus,Actor.Name, Comments FROM StepsAndWorkitems WHERE Comments != null ORDER BY Createddate DESC) 
                                        FROM ProcessInstance WHERE TargetObjectId IN : newMap.keySet()];
        List<WorkOrder> toUpdateList = new List<WorkOrder>();
        for(WorkOrder wo : newMap.values()){
            for(ProcessInstance p : ptList){
                if(p.TargetObjectId != wo.Id) continue;
                //StepsAndWorkitems is child relationship name for ProcessInstanceHistory.
                for(ProcessInstanceHistory s : p.StepsAndWorkitems){
                    if(String.isBlank(s.Comments)) continue;
                    WorkOrder wo1 = new WorkOrder();
                    wo1.Id = wo.Id;
                    wo1.Approval_Commentss__c = s.Comments;
                    toUpdateList.add(wo1);
                    break;
                }
            }
        }
        System.debug('toUpdateList size-> ' + toUpdateList.size());
        runOnceBeforeUpdate = false;
        runOnceAfterUpdate = false;
        Database.update(toUpdateList,false);
    }

    // public class TechCheckedInOutTimeWrapper{
    //     public string chkInTime{get;Set;}
    //     public string chkOutTime{get;Set;}
    // }

    /*private static void assignBundleId(List<WorkOrder> woList) {
        Set<Id> recTypeIds = new Set<Id>();
        for(WorkOrder wo : woList){
            recTypeIds.add(wo.RecordTypeId);
        }
        list<RecordType> recLst = [SELECT Id, Name, DeveloperName FROM RecordType WHERE Id IN : recTypeIds];
        for(WorkOrder w : woList){
            for(RecordType r : recLst){
                if((w.RecordTypeId == r.Id) && (r.DeveloperName == 'Bundle_Work_Order')){
                    final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
                    String randStr = '';
                    while (randStr.length() < 15) {
                        Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
                        randStr += chars.substring(idx, idx+1);
                    }
                    System.debug('bundle Id--->'+randStr);
                    w.Bundle_Id__c = randStr;
                }
            }
        }
    }*/
    
    /*
    private static void assignSLAExitDate(List<WorkOrder> woList) {
        ASCENAMilestoneCalculater.assignWOSALEndDatetime(woList);
    }*/

    /*@future
    public static void createChkInOutEventsOnCase(String newMapString, String oldMapString){
        Map<Id, WorkOrder> newMap = (Map<Id, WorkOrder>)JSON.deserialize(newMapString, Map<Id, WorkOrder>.class);
        Map<Id, WorkOrder> oldMap = (Map<Id, WorkOrder>)JSON.deserialize(oldMapString, Map<Id, WorkOrder>.class);
        System.debug('newMap:'+newMap);
        System.debug('oldMap:'+oldMap);
        Set<Id> caseIds = new Set<Id>();
        for(WorkOrder wo : newMap.values()){
            if(wo.Time_Entries__c == null || wo.CaseId == null || (wo.Time_Entries__c == oldMap.get(wo.Id).Time_Entries__c)) continue;
            caseIds.add(wo.CaseId);
        }
        List<Case> csList = null;
        if(caseIds.size() != 0){
            csList = [SELECT Id, OwnerId, CaseNumber, (SELECT Id, Subject, StartDateTime, EndDateTime FROM Events WHERE Subject = 'Check In') FROM Case WHERE Id IN:caseIds];
        }
        System.debug('csList:'+csList);
        list<Event> eventList = new list<Event>();
        for(WorkOrder wo : newMap.values()){
            if(wo.Time_Entries__c == null || wo.CaseId == null || (wo.Time_Entries__c == oldMap.get(wo.Id).Time_Entries__c)) continue;
            for(Case c : csList){
                if(wo.CaseId != c.Id) continue;
                System.debug('wo.Time_Entries__c:'+wo.Time_Entries__c);
                string timeEntries = wo.Time_Entries__c.replaceAll('in', 'chkInTime');
                timeEntries = timeEntries.replaceAll('out', 'chkOutTime');
                System.debug('timeEntries-> ' + timeEntries);
                list<TechCheckedInOutTimeWrapper> timeList = (list<TechCheckedInOutTimeWrapper>)JSON.deserialize(timeEntries, list<TechCheckedInOutTimeWrapper>.class);
                System.debug('timeList:'+timeList);
                if(c.Events.size() == 0){
                    for(TechCheckedInOutTimeWrapper tl : timeList){
                        Event e = new event();
                        e.StartDateTime = Datetime.valueOf(tl.chkInTime);
                        e.EndDateTime = Datetime.valueOf(tl.chkOutTime);
                        e.WhatId = wo.CaseId;
                        e.OwnerId = c.OwnerId;
                        e.Subject = 'Check In';
                        eventList.add(e);
                    }
                }else{
                    Set<String> inTime = new Set<String>();
                    Set<String> outTime = new Set<String>();
                    for(Event ev : c.Events){
                        inTime.add(string.valueOf(ev.StartDateTime));
                        outTime.add(string.valueOf(ev.EndDateTime));
                    }
                    for(TechCheckedInOutTimeWrapper tl : timeList){
                        if(inTime.Contains(tl.chkInTime) || outTime.Contains(tl.chkOutTime)) continue;
                        Event e = new event();
                        e.StartDateTime = Datetime.valueOf(tl.chkInTime);
                        e.EndDateTime = Datetime.valueOf(tl.chkOutTime);
                        e.WhatId = wo.CaseId;
                        e.OwnerId = c.OwnerId;
                        e.Subject = 'Check In';
                        eventList.add(e);
                    }
                }
            }
        }
        System.debug('eventList:'+eventList);
        if(eventList.size() != 0){
            insert eventList;
        }
    }*/

     /*
    public static void setStatusChangeMailDate(List<WorkOrder> woList){
        Id onsiteLaborRT = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Onsite_Labor').getRecordTypeId();
        DateTime cuttOffDate = System.now();
        System.debug('cuttOffDate now::'+cuttOffDate);
        TimeZone tz = UserInfo.getTimeZone();
        integer offset = tz.getOffset(cuttOffDate);
        for(WorkOrder wo : woList){
            if(wo.RecordTypeId != onsiteLaborRT) continue;
            DateTime timeNow = cuttOffDate.addSeconds(offset/1000);
            System.debug('timeNow now::'+timeNow);
            if(wo.Priority == 'Severity 1'){
                cuttOffDate = DateTime.newInstance(cuttOffDate.year(), cuttOffDate.month(), cuttOffDate.day(), 16, 0, 0);
            }else if(wo.Priority == 'Severity 2'){
                cuttOffDate = DateTime.newInstance(cuttOffDate.year(), cuttOffDate.month(), cuttOffDate.day(), 15, 30, 0);
            }
            cuttOffDate = cuttOffDate.addSeconds(offset/1000);
            System.debug('cuttOffDate ::'+cuttOffDate);
            System.debug('System.now() ::'+System.now());
            if(timeNow < cuttOffDate){
                System.debug('timeNow.month()::'+timeNow.month());
                System.debug('timeNow.monthGMT()::'+timeNow.monthGMT());
                DateTime schedulingStatusDateTime = DateTime.newInstanceGmt(timeNow.yearGMT(), timeNow.monthGMT(), timeNow.dayGMT(), 21, 0, 0);
                schedulingStatusDateTime = schedulingStatusDateTime.addHours(4);
                wo.Scheduling_Status_Mail_Date__c = DateTime.parse(schedulingStatusDateTime.format('MM/dd/yyyy, h:mm a', 'America/New_York')).addSeconds((offset - (-14400000))/1000);
                System.debug('wo.Scheduling_Status_Mail_Date__c 9pm::'+wo.Scheduling_Status_Mail_Date__c);
            }else{
                timeNow = timeNow.addDays(1);
                DateTime schedulingStatusDateTime = DateTime.newInstanceGmt(timeNow.yearGMT(), timeNow.monthGMT(), timeNow.dayGMT(), 10, 0, 0);
                schedulingStatusDateTime = schedulingStatusDateTime.addHours(4);
                wo.Scheduling_Status_Mail_Date__c = DateTime.parse(schedulingStatusDateTime.format('MM/dd/yyyy, h:mm a', 'America/New_York')).addSeconds((offset - (-14400000))/1000);
                System.debug('wo.Scheduling_Status_Mail_Date__c 10am::'+wo.Scheduling_Status_Mail_Date__c);
            }
        }
    }*/

    /*public static void createServiceAppointments(Map<Id, WorkOrder> newMap, Map<Id, WorkOrder> oldMap) {
        List<ServiceAppointment> saList = new List<ServiceAppointment>();
        List<FSL__Scheduling_Policy__c> spList = [SELECT Id,Name FROM FSL__Scheduling_Policy__c WHERE Name LIKE '%CUB%' ORDER BY Name];
        if(!spList.isEmpty()){
            for(WorkOrder wo : newMap.values()){
                if(String.isBlank(wo.Account_Name__c) || wo.Expected_SLA_Exit_Date__c == null) continue;
                if(!wo.Account_Name__c.containsIgnoreCase('CUB') && !wo.Account_Name__c.containsIgnoreCase('SHOPPER')) continue;
                // Service Appointment should be created only when WO.onwer is CUB partner user. i.e Field Tech user.
                if(!test.isRunningTest()){
                    if(wo.OwnerId == oldMap.get(wo.Id).OwnerId || wo.OwnerId == null) continue;
                    if(!String.valueOf(wo.OwnerId).startsWith('005')) continue;

                    //Creating SAs if owner is user
                    
                    //List<User> usrList = [SELECT Id, Profile.UserLicense.Name FROM User WHERE Id =: wo.OwnerId];
                    //if(usrList[0].Profile.UserLicense.Name != 'Partner Community') continue;
                    //List<GroupMember> gmList = [SELECT Id,UserOrGroupId FROM GroupMember WHERE Group.Type = 'Queue' AND Group.Name = 'Field_Service_Queue' AND UserOrGroupId =:wo.OwnerId];
                    //if(gmList.isEmpty()) continue;
                }

                DateTime dt = System.now();
                DateTime dueDate = wo.Expected_SLA_Exit_Date__c.addHours(1);

                //Tech should be at the store at 8am, which is start of the day
                //Tech is supposed to be at the store at least till 10PM for Sev1 type appt and 11PM for Sev2 appt
                Time tenPM = Time.newInstance(22, 0, 0, 0);
                Time elevenPM = Time.newInstance(23, 0, 0, 0);
                Time eightAM = Time.newInstance(8, 0, 0, 0);
                System.debug('dt.time-> ' + dt.time());
                if(wo.Priority == 'Severity 1' && dt.time() >= tenPM){
                    dt = DateTime.newInstance(dt.date().addDays(1),Time.newInstance(8, 0, 0, 0));
                } else if (wo.Priority == 'Severity 2' && dt.time() >= elevenPM) {
                    dt = DateTime.newInstance(dt.date().addDays(1),Time.newInstance(8, 0, 0, 0));
                } else if(dt.time() < eightAM){
                    dt = DateTime.newInstance(dt.date(),Time.newInstance(8, 0, 0, 0));
                }
                // Due Date Based on dt.
                if(wo.Priority == 'Severity 1'){
                    dueDate = DateTime.newInstance(dt.date(),Time.newInstance(22,0,0,0));
                } else if(wo.Priority == 'Severity 2'){
                    dueDate = DateTime.newInstance(dt.date(),Time.newInstance(23,0,0,0));
                }
                ServiceAppointment sa = new ServiceAppointment();
                sa.ParentRecordId = wo.Id;
                sa.EarliestStartTime = dt;
                sa.DueDate = dueDate;

                sa.SchedStartTime = dt;
                sa.SchedEndTime = dt.addHours(1);
                
                sa.FSL__Scheduling_Policy_Used__c = spList[0].Id;
                //sa.FSL__Auto_Schedule__c = true;
                sa.Status = 'None';
                sa.Street = wo.Street;
                sa.City = wo.City;
                sa.State = wo.State;
                sa.Country = wo.Country;
                sa.PostalCode = wo.PostalCode;
                if(wo.Priority == 'Severity 1'){
                    sa.Priority__c = 1; // Behaves as top priority
                    sa.FSL__Schedule_over_lower_priority_appointment__c = true;
                } else {
                    sa.Priority__c = 10; // Behaves as low priority
                }
                saList.add(sa);
            }
            if(!saList.isEmpty()){
                insert saList;
            }
        }
    }*/

    /*@future
    private static void assignWOtoQueue(String jsonNewMapStr) {
        Map<Id, WorkOrder> newMap = (Map<Id, WorkOrder>) JSON.deserialize(jsonNewMapStr, Map<Id, WorkOrder>.class);
        List<WorkOrder> woList = new List<WorkOrder>();
        for(WorkOrder wo : newMap.values()) {
            System.debug('wo.OwnerId Before:'+wo.OwnerId);
            Boolean toUpdate = false;
            if(wo.RecordTypeId == System.Label.Part_Request_WO_RT_Id && wo.Country != 'Canada') {
                wo.OwnerId = System.Label.Part_Request_Queue_Id;
                toUpdate = true;
            } else if(wo.RecordTypeId == System.Label.Onsite_Labor_WO_RT_Id && wo.Country != 'Canada') {
                wo.OwnerId = System.Label.Onsite_Labor_Queue_Id;
                toUpdate = true;
            }
            System.debug('wo.OwnerId After:'+wo.OwnerId);
            if(toUpdate){
                woList.add(wo);
            }
        }
        if(!woList.isEmpty()){
            update woList;
        }
    }*/

    /*
    public static void createWOLIforBundleProds(List<WorkOrder> woList){
        Set<Id> parentProductIds = new Set<Id>();
        for(WorkOrder w : woList){
            if(w.Product__c != null && (w.Service_Type__c == 'Advance Exchange (Depot Only)')){
                parentProductIds.add(w.Product__c);
            }
        }
        list<Product_Bundle__c> prodBundles = [SELECT Id, Name, Parent_Product__c, Child_Product__c FROM Product_Bundle__c WHERE Parent_Product__c IN: parentProductIds];
        Set<Id> childProdIds = new Set<Id>();
        for(Product_Bundle__c pb : prodBundles){
            if(pb.Child_Product__c != null){
                childProdIds.add(pb.Child_Product__c);
            }
        }
        list<PriceBook2> pb2 = [SELECT Id, name, IsStandard FROM PriceBook2 WHERE IsStandard = true limit 1];
        string stdPrcebkId = '';
        if(pb2.size() != 0){
            stdPrcebkId = pb2[0].Id;
        }
        System.debug('Standard Price Book--->'+pb2);
        System.debug('stdPrcebkId--->'+stdPrcebkId);
        list<PricebookEntry> pbe = new list<PricebookEntry>();
        if(childProdIds.size() != 0){
            pbe = [SELECT Id, name, Product2Id, Product2.Name FROM PricebookEntry WHERE Product2Id IN : childProdIds AND Pricebook2Id =:stdPrcebkId];
        }
        list<WorkOrderLineItem> woli = new list<WorkOrderLineItem>();
        if(childProdIds.size() != 0){
            for(WorkOrder wo : woList){
                for(Product_Bundle__c pbd : prodBundles){
                    if(wo.Product__c == pbd.Parent_Product__c){
                        WorkOrderLineItem wl = new WorkOrderLineItem();
                        for(PricebookEntry p : pbe){
                            if(p.Product2Id == pbd.Child_Product__c){
                                wl.PricebookEntryId = p.Id;
                            }
                        }
                        wl.Description = wo.Description;
                        wl.Status = 'New';
                        wl.WorkOrderId = wo.Id;
                        if(wo.AssetId != null){
                            wl.AssetId = wo.AssetId;
                        }
                        woli.add(wl);
                    }
                }
            }
        }
        if(woli.size() != 0){
            insert woli;
        }
    }*/
    
    /*public static void cancelChildWOandCase(Map<Id, WorkOrder> newMap, Map<Id, WorkOrder> oldMap){
        Set<Id> parentIds = new Set<Id>();
        list<case> caseToUpdate = new list<case>();
        Set<Id> parentWos = new Set<Id>();
        for(WorkOrder wo : newMap.values()) {
            if(wo.parentworkorderId != null){
                parentIds.add(wo.parentworkorderId);
            }
            if(wo.CaseId == null) continue;
            if((wo.Status == 'Canceled') && wo.Status != oldMap.get(wo.Id).Status && wo.ParentWorkOrderId == null && wo.Service_Type__c == 'Advance Exchange + Onsite') {
                case c = new case();
                c.Id = wo.CaseId;
                c.Status = 'Canceled';
                c.Resolution_Code__c = wo.Resolution_Code__c;
                c.Resolution_Notes__c = wo.Resolution_Notes__c;
                caseToUpdate.add(c);
                parentWos.add(wo.Id);
            }
        }
        list<WorkOrder> parentWoLst = new list<WorkOrder>();
        if(parentIds.size() != 0) {
            parentWoLst = [SELECT Id, Status FROM WorkOrder WHERE Id IN: parentIds];
        }
        list<WorkOrder> parentWoLstToSet = new list<WorkOrder>();
        if(parentWos.size() != 0) {
            parentWoLstToSet = [SELECT Id, Status, Resolution_Code__c, Resolution_Notes__c, ParentWorkOrderId FROM WorkOrder WHERE ParentWorkOrderId IN: parentWos];
        }
        list<WorkOrder> childWOs = new list<WorkOrder>();
        for(WorkOrder wo : newMap.values()) {
            for(WorkOrder w : parentWoLst){
                if((w.Id == wo.ParentWorkOrderId) && (w.Status != 'Canceled') && (wo.Status == 'Canceled') && wo.Status != oldMap.get(wo.Id).Status && wo.Service_Type__c == 'Advance Exchange + Onsite' && wo.ParentWorkOrderId != null) {
                    wo.addError('This work order is child of a parent work order. You cannot cancel child work orders. To cancel child work orders, please cancel parent work order');
                }
            }
            for(WorkOrder w : parentWoLstToSet) {
                if(w.ParentWorkOrderId == wo.Id && (wo.Status == 'Canceled') && wo.Status != oldMap.get(wo.Id).Status && wo.Service_Type__c == 'Advance Exchange + Onsite' && wo.ParentWorkOrderId == null) {
                    WorkOrder cwo = new WorkOrder();
                    cwo.Id = w.Id;
                    cwo.Status = 'Canceled';
                    cwo.Resolution_Code__c = wo.Resolution_Code__c;
                    cwo.Resolution_Notes__c = wo.Resolution_Notes__c;
                    childWOs.add(cwo);
                }
            }
        }
        if(childWOs.size() != 0) {
            update childWOs;
        }
        if(caseToUpdate.size() != 0) {
            update caseToUpdate;
        }
    }*/

      /*public static void updateStatusesAftInsert(List<WorkOrder> woList){
        list<WorkOrder> workOrdersToUpdate = new list<WorkOrder>();
        list<Case> toUpdateCaseStatus = new list<Case>();
        Set<Id> woIdsforSA = new Set<Id>();
        Set<Id> parentWOIds = new Set<Id>();
        Set<Id> parentCaseIds = new Set<Id>();
        for(WorkOrder w : woList){
            if(w.ParentWorkOrderId != null && w.Service_Type__c == 'Advance Exchange + Onsite'){
                parentWOIds.add(w.ParentWorkOrderId);
                parentCaseIds.add(w.CaseId);
            }
        }
        list<WorkOrder> parentWOStatusChk = new list<WorkOrder>();
        if(!parentWOIds.isEmpty()){
            parentWOStatusChk = [SELECT Id, Status FROM WorkOrder WHERE Id IN : parentWOIds];
        }
        list<Case> parentCasetatusChk = [SELECT Id, Status, Technician_Status__c FROM Case WHERE Id IN : parentCaseIds];
        for(WorkOrder w : woList){
            if(w.Status != null && w.ParentWorkOrderId != null && w.Service_Type__c == 'Advance Exchange + Onsite'){
                for(WorkOrder pwo : parentWOStatusChk){
                    if(w.ParentWorkOrderId == pwo.Id && (w.Status != pwo.Status)){
                        WorkOrder wo = new WorkOrder();
                        wo.Id = w.ParentWorkOrderId;
                        wo.Status = w.Status;
                        workOrdersToUpdate.add(wo);
                    }
                }
            }
            for(Case parentCase : parentCasetatusChk){
                if((w.Status == null || w.Technician_Status__c == null) || (w.Status == parentCase.Status) || (w.Technician_Status__c == parentCase.Technician_Status__c) || w.CaseId == null) continue;
                Case cs = new Case();
                cs.Id = w.CaseId;
                if((w.Status != null) && w.Status != 'Issue / Cannot Complete' && w.Status != 'In Production' && w.Status != 'Scheduling' && w.Status != 'Technician In Route' && w.Status != 'Approved' && w.Status != 'Paid' && w.Status != 'Deleted' && w.Status != 'Completed' && w.Status != 'In Progress'){
                    cs.Resolution_Code__c = w.Resolution_Code__c;
                    cs.Resolution_Notes__c = w.Resolution_Notes__c;
                    cs.Status = w.Status;
                }
                if(w.Technician_Status__c != null){
                    cs.Technician_Status__c = w.Technician_Status__c;
                }
                toUpdateCaseStatus.add(cs);
            }
            if(w.Technician_Status__c != null){
                WorkOrder woAdd = new WorkOrder();
                if(w.Technician_Status__c == 'Checked in' && (w.StatusCategory == 'New' || w.Status == 'Scheduling' || w.Status == 'In Production' || w.Status == 'Technician In Route')){
                    woAdd.Status = 'Tech Checked In';
                    woAdd.Id = w.Id;
                    workOrdersToUpdate.add(woAdd);
                }else if((w.Technician_Status__c == 'Assigned' || w.Technician_Status__c == 'Confirmed')){
                    woAdd.Status = 'Technician Scheduled / Assigned';
                    woAdd.Id = w.Id;
                    workOrdersToUpdate.add(woAdd);
                }else if(w.Technician_Status__c == 'Cancelled' && (w.StatusCategory != 'Closed' && w.StatusCategory != 'Completed')){
                    woAdd.Status = 'Cancelled';
                    woAdd.Id = w.Id;
                    workOrdersToUpdate.add(woAdd);
                }
            }
            if(w.FN_Status__c != null){
                WorkOrder woAdd = new WorkOrder();
                if((w.FN_Status__c == 'Draft' || w.FN_Status__c == 'Published' || w.FN_Status__c == 'Routed') && (w.StatusCategory == 'New')){
                    woAdd.Status = 'Scheduling';
                    woAdd.Id = w.Id;
                    workOrdersToUpdate.add(woAdd);
                }else if(w.FN_Status__c == 'Assigned' && (w.Status == 'New' || w.Status == 'Acknowledged')){
                    woAdd.Status = 'Technician Scheduled / Assigned';
                    woAdd.Id = w.Id;
                    workOrdersToUpdate.add(woAdd);
                }else if(w.FN_Status__c == 'Work Done' && (w.StatusCategory != 'Closed' && w.StatusCategory != 'Completed')){
                    woAdd.Status = 'Onsite Work Completed';
                    woAdd.Id = w.Id;
                    workOrdersToUpdate.add(woAdd);
                }
            }
            woIdsforSA.add(w.Id);
        }
        if(workOrdersToUpdate.size() != 0){
            update workOrdersToUpdate;
        }
        if(toUpdateCaseStatus.size() != 0){
            update toUpdateCaseStatus;
        }
    }*/
}