public with sharing class SalesOrderBatch implements Database.Batchable<sObject> {
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id,Tracking_Numbers__c,Ship_Date__c,'+
                                        'Return_Authorization__c,Return_Order_Tracking_Numbers__c,Order_Status__c,Minutes_Since_Modified__c,'+
                                        'Outbound_Tracking_Numbers__c,SO_Order_Status__c,Work_Order__c,Work_Order_Sync_Error__c '+
                                        'FROM Sales_Order__c WHERE Minutes_Since_Modified__c <= 3 AND Work_Order__c != null');
    }

    public void execute(Database.BatchableContext BC, List<Sales_Order__c> scope){
        try {
            processRecords(scope);
        } catch (Exception e) {
            System.debug('Error in Batch Apex: ' + e.getMessage());
            User u = [SELECT Id FROM User WHERE Name = 'Vaibhav Patil' LIMIT 1];

            BatchApexErrorEvent errorEvent = new BatchApexErrorEvent(
                AsyncApexJobId = BC.getJobId(),
                JobScope = '{}',
                Message = e.getMessage(),
                StackTrace = e.getStackTraceString()
            );
            Messaging.SingleEmailMessage errorMail = new Messaging.SingleEmailMessage();

            errorMail.setTargetObjectId(u.Id);
            errorMail.setToAddresses(new String[] {'vaibhavp@aspiresoftwareconsultancy.com','somashekar.rg@aspiresoftwareconsultancy.com'});
            errorMail.setSubject('Error in Sales Order Batch Execution');
            String emailBody = 'An error occurred during the execution of the Sales Order Batch.\n\n';
            emailBody += '--- ERROR DETAILS ---\n';
            emailBody += 'Error Message: ' + e.getMessage() + '\n';
            emailBody += 'Stack Trace: ' + e.getStackTraceString() + '\n\n';
            
            emailBody += '--- BATCH JOB DETAILS ---\n';
            emailBody += 'Batch Job ID: ' + BC.getJobId() + '\n';
            emailBody += 'Batch Instance: SalesOrderBatch\n';
            emailBody += 'Execution Time: ' + System.now().format() + '\n\n';
            
            emailBody += '--- JOB SCOPE ---\n';
            if (errorEvent.JobScope != null && errorEvent.JobScope != '{}') {
                emailBody += 'Job Scope: ' + errorEvent.JobScope + '\n\n';
            } else {
                emailBody += 'Job Scope: No specific job scope available.\n\n';
            }

            emailBody += 'Please review the above details and take appropriate action.\n';
            errorMail.setPlainTextBody(emailBody);
            errorMail.setSaveAsActivity(false);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { errorMail });                
        }
    }

    public static void processRecords(List<Sales_Order__c> soList){
        Set<Id> woIds = new Set<Id>();
        System.debug('soList--->'+soList);
        for(Sales_Order__c so : soList){
            woIds.add(so.Work_Order__c);
        }
        Map<Id, WorkOrder> woMap = new Map<Id,WorkOrder>([SELECT Status,CaseId,Tracking_Numbers__c, Return_Authorization__c,Resolution_Notes__c,
                                                          Return_Order_Tracking_Numbers__c, Netsuite_Sales_Order__c,AccountId,Account.Timezone__c,
                                                          Ship_Date__c,RecordType.Name,RecordTypeId,Closing_Process__c,Resolution_Code__c, 
                                                          (SELECT Id, NewValue, OldValue, Field, CreatedDate FROM Histories WHERE Field = 'Status' ORDER BY CreatedDate ASC) 
                                                          FROM WorkOrder WHERE Id = :woIds]);
        Map<Id,Sales_Order__c> erroredSOMap = new Map<Id,Sales_Order__c>();
        Map<Id,WorkOrder> woToUpdateMap = new Map<Id,WorkOrder>();
        Map<Id,Case> csToUpdateMap = new Map<Id,Case>();
        for(Sales_Order__c so : soList){
            try {
                WorkOrder wo = woMap.get(so.Work_Order__c);
                Case c = new Case(Id=wo.CaseId);

                boolean updateWO = false;
                boolean updateCase = false;
                String  partShippedDateStr;
                List<Timezone_Id__mdt> tzList = [SELECT MasterLabel, QualifiedApiName, Timezon_Id__c FROM Timezone_Id__mdt];
                String timezoneId = '';
                for(Timezone_Id__mdt tz : tzList) {
                    if(wo.Account.Timezone__c == null) continue;
                    if(tz.MasterLabel != wo.Account.Timezone__c) continue;
                    timezoneId = tz.Timezon_Id__c;
                    break;
                }
                for(WorkOrderHistory wh : wo.Histories){
                    if(wh.NewValue != 'Part Shipped') continue;
                    DateTime dt = DateTime.parse(wh.CreatedDate.format('MM/dd/yyyy, hh:mm a', timezoneId));
                    partShippedDateStr = dt.format('MM/dd/yyyy hh:mm a');
                    break;
                }
                System.debug('partShippedDateStr-> ' + partShippedDateStr);
                System.debug('wo.Netsuite_Sales_Order__c-> ' + wo.Netsuite_Sales_Order__c);
                if(wo.Netsuite_Sales_Order__c == null) {
                    wo.Netsuite_Sales_Order__c = so.Id;
                    updateWO = true;
                }
                System.debug('c.NetSuite_Sales_Order__c-> ' + c.NetSuite_Sales_Order__c);
                if(c.NetSuite_Sales_Order__c == null) {
                    c.NetSuite_Sales_Order__c = so.Id;
                    updateCase = true;
                }
                
                if(wo.RecordType.Name == 'Part Shipment'){
                    System.debug('wo.Tracking_Numbers__c-> ' + wo.Tracking_Numbers__c);
                    System.debug('so.Outbound_Tracking_Numbers__c->' + so.Outbound_Tracking_Numbers__c);
                    if(so.Outbound_Tracking_Numbers__c != wo.Tracking_Numbers__c && String.isBlank(wo.Tracking_Numbers__c)) {
                        wo.Tracking_Numbers__c = so.Outbound_Tracking_Numbers__c;
                        updateWO = true;

                        c.Tracking_Numbers__c = so.Outbound_Tracking_Numbers__c;
                        updateCase = true;
                    }
                    
                    System.debug('wo.Ship_Date__c-> ' + wo.Ship_Date__c);
                    System.debug('so.Ship_Date__c-> ' + so.Ship_Date__c);
                    if(so.Ship_Date__c != wo.Ship_Date__c && wo.Ship_Date__c == null) {
                        wo.Ship_Date__c = so.Ship_Date__c.addDays(1);
                        updateWO = true;
                        
                        c.Ship_Date__c = so.Ship_Date__c.addDays(1);
                        updateCase = true;
                    }

                    System.debug('wo.Return_Authorization__c-> ' + wo.Return_Authorization__c);
                    System.debug('so.Return_Authorization__c-> ' + so.Return_Authorization__c);
                    if(so.Return_Authorization__c  != wo.Return_Authorization__c && String.isBlank(wo.Return_Authorization__c)) {
                        wo.Return_Authorization__c = so.Return_Authorization__c;
                        c.Return_Authorization__c = so.Return_Authorization__c;
                        updateWO = true;
                        updateCase = true;
                    }

                    System.debug('wo.Return_Order_Tracking_Numbers__c-> ' + wo.Return_Order_Tracking_Numbers__c);
                    System.debug('so.Return_Order_Tracking_Numbers__c-> ' + so.Return_Order_Tracking_Numbers__c);
                    if(so.Return_Order_Tracking_Numbers__c  != wo.Return_Order_Tracking_Numbers__c && String.isBlank(wo.Return_Order_Tracking_Numbers__c)) {
                        wo.Return_Order_Tracking_Numbers__c = so.Return_Order_Tracking_Numbers__c;
                        c.Return_Tracking_Numbers__c = so.Return_Order_Tracking_Numbers__c;
                        updateWO = true;
                        updateCase = true;
                    }
                    
                    System.debug('so.Order_Status__c-> ' + so.Order_Status__c + 'wo.Status-> ' + wo.Status);
                    System.debug('so.Outbound_Tracking_Numbers__c-> ' + so.Outbound_Tracking_Numbers__c);
                    System.debug('wo.RecordType.Name-> ' + wo.RecordType.Name);
                    System.debug('wo.Status-->'+wo.Status);
                
                    //If work order status is closed, then no need to update it based on data.
                    if(wo.Status == 'Closed') {
                        if(updateWO) {
                            WorkOrderTriggerHandler.runOnceBeforeUpdate = true;
                            WorkOrderTriggerHandler.runOnceAfterUpdate = true;
                            woToUpdateMap.put(wo.Id,wo);
                        }
                        if(updateCase && wo.CaseId != null) {
                            CaseTriggerHandler.runOnceBeforeUpdate = true;
                            CaseTriggerHandler.runOnceAfterUpdate = true;
                            csToUpdateMap.put(c.Id,c);
                        }
                        continue;
                    }
                    System.debug('wo.Resolution_Code__c-> ' + wo.Resolution_Code__c);
                    if(so.Order_Status__c == 'Billed' && wo.Status != 'Closed'){
                        wo.Status = 'Closed';
                        wo.Resolution_Code__c = 'SHIPMENT COMPLETE';
                        String resNotes = 'Product Shipped on ' + partShippedDateStr + '\n' + 'Tracking #' + wo.Tracking_Numbers__c;
                        if(String.isBlank(wo.Resolution_Notes__c)) {
                            wo.Resolution_Notes__c = resNotes;
                        } else {
                            wo.Resolution_Notes__c += '\n' + resNotes;
                        }
                        wo.Closing_Process__c = true;
                        System.debug('wo.Id1--> ' + wo.Id + 'wo.status1--> ' + wo.Status);
                        updateWO = true;
                    } else if((so.Order_Status__c == 'Pending Billing') && wo.Status != 'Part Shipped'){
                        wo.Status = 'Part Shipped';
                        System.debug('wo.Id2--> ' + wo.Id + 'wo.status2--> ' + wo.Status);
                        updateWO = true;
                    } else if(so.Order_Status__c == 'Pending Billing/Partially Fulfilled' && so.Outbound_Tracking_Numbers__c == null){
                        if(so.SO_Order_Status__c == 'Hold'){
                            wo.Status = 'Cannot Complete';
                        } else{
                            wo.Status = 'Pending Fulfillment';
                        }
                        System.debug('wo.Id3--> ' + wo.Id + 'wo.status3--> ' + wo.Status);
                        updateWO = true;
                    } else if(so.Order_Status__c == 'Pending Billing/Partially Fulfilled' && so.Outbound_Tracking_Numbers__c != null){
                        if(so.SO_Order_Status__c == 'Hold'){
                            wo.Status = 'Cannot Complete';
                        } else{
                            wo.Status = 'Part Shipped';
                        }
                        System.debug('wo.Id4--> ' + wo.Id + 'wo.status4--> ' + wo.Status);
                        updateWO = true;
                    } else if(so.Order_Status__c == 'Partially Fulfilled' && so.Outbound_Tracking_Numbers__c == null && wo.Status != 'Partially Fulfilled'){
                        wo.Status = 'Partially Fulfilled';
                        System.debug('wo.Id5--> ' + wo.Id + 'wo.status5--> ' + wo.Status);
                        updateWO = true;
                    } else if(so.Order_Status__c == 'Partially Fulfilled' && so.Outbound_Tracking_Numbers__c != null && wo.Status != 'Part Shipped'){
                        wo.Status = 'Part Shipped';
                        System.debug('wo.Id6--> ' + wo.Id + 'wo.status6--> ' + wo.Status);
                        updateWO = true;
                    } else if(so.Order_Status__c == 'Pending Fulfillment'){
                        if(so.SO_Order_Status__c == 'Hold'){
                            wo.Status = 'Cannot Complete';
                        } else{
                            wo.Status = 'Pending Fulfillment';
                        }
                        System.debug('wo.Id7--> ' + wo.Id + 'wo.status7--> ' + wo.Status);
                        updateWO = true;
                    } else if(so.Order_Status__c == 'Pending Approval'){
                        if(so.SO_Order_Status__c == 'Hold'){
                            wo.Status = 'Cannot Complete';
                        } else{
                            wo.Status = 'Part Ordered';
                        }
                        System.debug('wo.Id8--> ' + wo.Id + 'wo.status8--> ' + wo.Status);
                        updateWO = true;
                    }
                }
                if(updateWO) {
                    System.debug('Updating WO-> ' + wo);
                    woToUpdateMap.put(wo.Id,wo);
                }
                if(updateCase && wo.CaseId != null) {
                    System.debug('Updating case-> ' + c);
                    csToUpdateMap.put(c.Id,c);
                }
            } catch(Exception e) {
                so.Work_Order_Sync_Error__c = e.getCause() + '\\n' +e.getLineNumber()+'\\n'+e.getMessage()+'\\n'+e.getStackTraceString();
                erroredSOMap.put(so.Id,so);
            }
        }
        WorkOrderTriggerHandler.runOnceBeforeUpdate = true;
        WorkOrderTriggerHandler.runOnceAfterUpdate = true;
        if(!woToUpdateMap.isEmpty()) update woToUpdateMap.values();
        CaseTriggerHandler.runOnceBeforeUpdate = true;
        CaseTriggerHandler.runOnceAfterUpdate = true;
        if(!csToUpdateMap.isEmpty()) update csToUpdateMap.values();
        if(!erroredSOMap.isEmpty()) update erroredSOMap.values();
    }

    public void finish(Database.BatchableContext BC){
        if(!test.isRunningTest()){
            List<CronTrigger> ctList = [SELECT Id, CronJobDetail.Name FROM CronTrigger WHERE CronJobDetail.Name = 'Sales Order Batch'];
            if(ctList.isEmpty()){
                try {
                    System.scheduleBatch(new SalesOrderBatch(), 'Sales Order Batch', 1, 10);
                } catch (Exception e) {
                    System.debug('Error in Batch Apex: ' + e.getMessage());
                    User u = [SELECT Id FROM User WHERE Name = 'Vaibhav Patil' LIMIT 1];

                    BatchApexErrorEvent errorEvent = new BatchApexErrorEvent(
                        AsyncApexJobId = BC.getJobId(),
                        JobScope = '{}',
                        Message = e.getMessage(),
                        StackTrace = e.getStackTraceString()
                    );
                    Messaging.SingleEmailMessage errorMail = new Messaging.SingleEmailMessage();

                    errorMail.setTargetObjectId(u.Id);
                    errorMail.setToAddresses(new String[] {'vaibhavp@aspiresoftwareconsultancy.com','somashekar.rg@aspiresoftwareconsultancy.com'});
                    errorMail.setSubject('Error in Sales Order Batch Execution');
                    String emailBody = 'An error occurred during the execution of the Sales Order Batch.\n\n';
                    emailBody += '--- ERROR DETAILS ---\n';
                    emailBody += 'Error Message: ' + e.getMessage() + '\n';
                    emailBody += 'Stack Trace: ' + e.getStackTraceString() + '\n\n';
                    
                    emailBody += '--- BATCH JOB DETAILS ---\n';
                    emailBody += 'Batch Job ID: ' + BC.getJobId() + '\n';
                    emailBody += 'Batch Instance: SalesOrderBatch\n';
                    emailBody += 'Execution Time: ' + System.now().format() + '\n\n';
                    
                    emailBody += '--- JOB SCOPE ---\n';
                    if (errorEvent.JobScope != null && errorEvent.JobScope != '{}') {
                        emailBody += 'Job Scope: ' + errorEvent.JobScope + '\n\n';
                    } else {
                        emailBody += 'Job Scope: No specific job scope available.\n\n';
                    }

                    emailBody += 'Please review the above details and take appropriate action.\n';
                    errorMail.setPlainTextBody(emailBody);
                    errorMail.setSaveAsActivity(false);
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { errorMail });
                }
            }
        }
    }    
}