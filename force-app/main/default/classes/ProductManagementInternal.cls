public without sharing class ProductManagementInternal {
    //Used in ProductManagementLineItemsInternal Component.
    @auraEnabled
    public static Case newCaseLine(){
        Case cl = new Case();
        User currUser = [SELECT AccountId, Account.Root_Account__c FROM user WHERE Id= :UserInfo.getUserId()];
        if(currUser.Account.Root_Account__c == null) {
            cl.Root_Account__c = curruser.AccountId;
        } else {
            cl.Root_Account__c = curruser.Account.Root_Account__c;
        }
        return cl;
    }
    
    //Used in ProductManagementParentComponent
    @auraEnabled
    public static boolean checkUserType(){
        boolean hasContact = false;
        List<User> userList = [SELECT Id, ContactId, Account.Name FROM User WHERE Id =: UserInfo.getUserId()];
        if(userList.isEmpty()){
            return hasContact;
        }
        if(userList[0].ContactId != null){
            System.debug('userList[0].ContactId-->' + userList[0].ContactId);
            hasContact = true;
        }
        return hasContact;
    }

    //Used in CaseDeletionRequest component.
    @auraEnabled
    public static Case getCaseRecord(String caseId){
        return [SELECT Id, CaseNumber, Status, Service_Type__c FROM Case WHERE Id =: caseId LIMIT 1];
    }
    
    //Used in CaseDeletionRequest component.
    @auraEnabled
    public static String caseDeletionRequest(String caseId){
        Case cs = new Case();
        cs.Id = caseId;
        cs.Status = 'Deletion Requested';
        String saveStatus = '';
        try{
            update cs;
            saveStatus = 'success';
        }catch(DmlException ec){
            saveStatus = ec.getDmlMessage(0);
        }
        return saveStatus;
    }

    //Used in RevisitWorkOrder compnonent
    @auraEnabled
    public static Case newCase(){
        Case cl = new Case();
        return cl;
    }
    
    //Used in ProductManagementLineItemsInternal Component.
    @auraEnabled
    public static List<Support_Team__c> getSupportTeamNotes( Account childAccount){
        return [SELECT Id, Name, Email__c, Tech_Notes__c FROM Support_Team__c WHERE Account__c =: childAccount.Id OR Account__c =: childAccount.ParentId OR 
                Account__c =: childAccount.Root_Account__c ORDER BY Name];
    }

    // for red hot order and revisit
    //Used in RevisitWorkOrder compnonent
    @auraEnabled
    public static WorkOrder getWO(String woId){
        List<WorkOrder> woLst = [SELECT Id, AccountId, CaseId, ParentWorkOrderId, ParentWorkOrder.CaseId, ParentWorkOrder.Case.Support_Team__c, ParentWorkOrder.Case.Account_Product__c, Case.Support_Team__c, Case.Account_Product__c, SLA_Exception_Code__c, Product__c, No_Cost__c, (SELECT Id FROM WorkOrderLineItems) FROM WorkOrder WHERE Id =: woId];
        System.debug('work order:'+woLst);
        return woLst[0];
    }
    
    //Used in ProductManagement & RevisitWorkOrder compnonents
    @auraEnabled
    public static String getAccProductId(String ProdId){
        String ProducctId = '';
        List<Account_Product__c> prd = [SELECT Id, Product__c FROM Account_Product__c WHERE Product__c =: ProdId LIMIT 1];
        if(prd.size() != 0){
            System.debug('Account prd[0]    --->'+prd[0]);
            System.debug('prd[0].Product__c --->'+prd[0].Id);
            ProducctId = prd[0].Id;
        }
        return ProducctId;
    }
    
    //Used in ProductManagement & RevisitWorkOrder compnonents
    @auraEnabled
    public static String getProductId(String accProdId){
        String ProducctId = '';
        List<Account_Product__c> prd = [SELECT Id, Product__c FROM Account_Product__c WHERE Id =: accProdId LIMIT 1];
        if(prd.size() != 0){
            System.debug('Account prd[0]    --->'+prd[0]);
            System.debug('prd[0].Product__c --->'+prd[0].Product__c);
            ProducctId = prd[0].Product__c;
        }
        return ProducctId;
    }
    
    //Used in ProductManagement & RevisitWorkOrder compnonents
    @auraEnabled
    public static String prodtHdlCode(String prodId){
        String handleCode = '';
        List<product2> prd = [SELECT Id, Name, Handling_Code__c FROM product2 WHERE Id =: prodId LIMIT 1];
        if(prd.size() != 0){
            System.debug('prd[0].Handling_Code__c--->'+prd[0]);
            System.debug('prd[0].Handling_Code__c--->'+prd[0].Handling_Code__c);
            handleCode = prd[0].Handling_Code__c;
        }
        return handleCode;
    }

    //Used in ProductManagementLineItemsInternal Component.
    @auraEnabled
    public static boolean checkForCUB(Id rootAccountId){
        System.debug('rootAccountId-> ' + rootAccountId);
        Account rootAacc = [SELECT Id,Name FROM Account WHERE Id =: rootAccountId LIMIT 1];
        boolean isCUB = false;
        if(rootAacc.Name.containsIgnoreCase('United Natural Foods') || rootAacc.Name.containsIgnoreCase('Jerry\'s Enterprises') || rootAacc.Name.containsIgnoreCase('Big Y Foods')){
            isCUB = true;
        }
        return isCUB;
    }
    //Used in CreateSeverity2WO component.
    @auraEnabled
    public static String CreateSev2Wo(String sev1WOId){
        System.debug('sev 1 wo Id--->'+sev1WOId);
        List<WorkOrder> sev1 = [SELECT Id, AccountId, CaseId, City, Country, PostalCode, StartDate, State, Street, Priority, EntitlementId, AssetId, Pricebook2Id, Service_Type__c, Incident__c, Product__c, Description, RecordTypeId, Preferred_Time_IMAC__c, POS_Register_Number__c, Department__c FROM WorkOrder WHERE Id =: sev1WOId];
        System.debug('sev 1--->'+sev1.size()+'--------'+sev1);
        Id advOnsitRT = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get( 'Advance_Exchange_Onsite' ).getRecordTypeId();
        System.debug('record type Id--->'+advOnsitRT);
        String saveStatus = '';
        
        if(sev1.size() != 0 && sev1[0].Priority == 'Severity 1'){
            try{
                List<Entitlement> entl = [SELECT Id, Type FROM Entitlement WHERE AccountId = : sev1[0].AccountId AND Type = 'Advance Exchange + Onsite' LIMIT 1];
                WorkOrder wo = new WorkOrder();
                wo.AccountId = sev1[0].AccountId;
                wo.CaseId = sev1[0].CaseId;
                wo.City = sev1[0].City;
                wo.Country = sev1[0].Country;
                wo.PostalCode = sev1[0].PostalCode;
                wo.State = sev1[0].State;
                wo.Street = sev1[0].Street;
                wo.Product__c = sev1[0].Product__c;
                wo.StartDate = sev1[0].StartDate;
                wo.Preferred_Time_IMAC__c = sev1[0].Preferred_Time_IMAC__c;
                wo.POS_Register_Number__c = sev1[0].POS_Register_Number__c;
                wo.Department__c = sev1[0].Department__c;
                wo.Priority = 'Severity 2';
                wo.Incident__c = sev1[0].Incident__c;
                wo.Pricebook2Id = sev1[0].Pricebook2Id;
                wo.Service_Type__c = sev1[0].Service_Type__c;
                wo.RecordTypeId = advOnsitRT;
                wo.AssetId = sev1[0].AssetId;
                wo.ParentWorkOrderId = sev1[0].Id;
                wo.Description = sev1[0].Description;
                if(entl.size() != 0){
                    wo.EntitlementId = entl[0].Id;
                }
                insert wo;
                List<WorkOrder> woLst = new List<WorkOrder>();
                for(integer i = 0; i < 2; i++){
                    WorkOrder woCld = new WorkOrder();
                    woCld.AccountId = wo.AccountId;
                    woCld.CaseId = wo.CaseId;
                    woCld.City = wo.City;
                    woCld.Country = wo.Country;
                    woCld.PostalCode = wo.PostalCode;
                    woCld.State = wo.State;
                    woCld.Street = wo.Street;
                    woCld.Product__c = wo.Product__c;
                    woCld.StartDate = wo.StartDate;
                    woCld.Preferred_Time_IMAC__c = wo.Preferred_Time_IMAC__c;
                    woCld.POS_Register_Number__c = wo.POS_Register_Number__c;
                    woCld.Department__c = wo.Department__c;
                    woCld.Priority = 'Severity 2';
                    woCld.Incident__c = wo.Incident__c;
                    woCld.Pricebook2Id = wo.Pricebook2Id;
                    woCld.Service_Type__c = wo.Service_Type__c;
                    if(i == 0){
                        Id onsitLabRT = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Onsite_Labor').getRecordTypeId();
                        woCld.RecordTypeId = onsitLabRT;
                    }
                    if(i == 1){
                        Id partShipRT = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Part_Shipment').getRecordTypeId();
                        woCld.RecordTypeId = partShipRT;
                    }
                    woCld.AssetId = wo.AssetId;
                    woCld.ParentWorkOrderId = wo.Id;
                    woCld.Description = wo.Description;
                    woLst.add(woCld);
                }
                if(woLst.size() != 0){
                    insert woLst;
                }
                saveStatus = wo.Id;
            }catch(DmlException ec){
                saveStatus = ec.getDmlMessage(0);
            }
        }
        return saveStatus;
    }
    
    //Used in Productmanagement & RevisitWorkOrder Components.
    // this method is for old Form Ui to create cases
    @auraEnabled
    public static String CreateCaseRecs(String accId, List<Case> CsLines, WorkOrder oldWorkOrder, WorkOrder newWorkOrder, boolean redHotOrder){
        System.debug('oldWorkOrder: '+oldWorkOrder);
        System.debug('newWorkOrder: '+newWorkOrder);
        String saveStatus;
        Savepoint sp = Database.setSavepoint();
        try{
            Id bndleCs = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Bundle').getRecordTypeId();
            Case bundleCase = new Case();
            if(CsLines.size() > 1){
                bundleCase.RecordTypeId = bndleCs;
                bundleCase.AccountId = accId;
                //insert bundleCase;
            }
            //This is to update old work order in revisit component
            if(oldWorkOrder != null){
                oldWorkOrder.Closing_Process__c = true; //To Avoid Closing Process Validation Error.
                oldWorkOrder.Status = 'Closed';
                update oldWorkOrder;
                if(!oldWorkOrder.No_Cost__c && (oldWorkOrder.WorkOrderLineItems.size() != 0)){
                    delete oldWorkOrder.WorkOrderLineItems;
                }
            }
            List<PriceBook2> pb2 = [SELECT Id, Name, IsStandard, Country__c FROM PriceBook2 WHERE IsStandard = TRUE LIMIT 1];
            String stdPrcebkId = '';
            if(pb2.size() != 0){
                stdPrcebkId = pb2[0].Id;
            }
            if(test.isRunningTest()){
                stdPrcebkId = Test.getStandardPricebookId();
            }
            set<Id> prodIds = new set<Id>();
            
            integer s1WoCounter = 0;
            integer s2WoCounter = 0;
            integer poCounter = 0;
            List<Entitlement> entl = new List<Entitlement>();//[SELECT Id, Type,Name FROM Entitlement WHERE AccountId = :accId];
            Id tempAccId = accId;
            while(entl.isEmpty()) {
                entl = [SELECT Id, Type,Name, AccountId FROM Entitlement WHERE AccountId = :tempAccId];
                if(entl.isEmpty()) {
                    List<Account> parentAccList = [SELECT ParentId FROM Account WHERE Id = :tempAccId];
                    if(!parentAccList.isEmpty() && parentAccList[0].ParentId != null) {
                        tempAccId = parentAccList[0].ParentId;
                    } else {
                        break;
                    }
                }else{
                    break;
                }
            }
            List<Account> accRecs = [SELECT Id, Name, Root_Account__r.Staging_Product__r.Name,Timezone__c, 
                                    Parent.Email_To_Notify_On_Case_Creation__c, Root_Account__r.Email_To_Notify_On_Case_Creation__c, 
                                    ShippingCity, ShippingState, ShippingCountry, ShippingStreet, ShippingPostalCode FROM Account 
                                    WHERE Id =: accId LIMIT 1];
            List<BusinessHours> bhs = new List<BusinessHours>();
            if(accRecs.size() != 0){
                bhs = [SELECT Id, Name, IsActive FROM BusinessHours WHERE Name LIKE : accRecs[0].Timezone__c+'%'];
            }
            System.debug('bhs:'+bhs);
            List<Group> partnerQueue = [SELECT Id, Name, DeveloperName, Type FROM Group WHERE Type='Queue' AND DeveloperName = 'Canada_Partner_Queue' LIMIT 1];
            System.debug('partnerQueue:'+partnerQueue);
            String loggedinUserEmail = userinfo.getUserEmail();
            System.debug('loggedinUserEmail::'+loggedinUserEmail);
            for(Case c : CsLines){
                if(accRecs[0].Root_Account__r.Email_To_Notify_On_Case_Creation__c != null){
                    c.Customer_Notification_Email2__c = accRecs[0].Root_Account__r.Email_To_Notify_On_Case_Creation__c;
                }
                if(accRecs[0].Parent.Email_To_Notify_On_Case_Creation__c != null){
                    c.Customer_Notification_Email_4__c = accRecs[0].Parent.Email_To_Notify_On_Case_Creation__c;
                }
                if(c.ProductId != null){
                    prodIds.add(c.ProductId);
                }
                if((bhs.size() != 0)){
                    String bhName = accRecs[0].Timezone__c + ' - ' + c.Priority;
                    if(accRecs[0].Name.containsIgnoreCase('ALDI')){
                        bhName = accRecs[0].Timezone__c + ' - ' + c.Priority + ' - ALDI';
                    } else if(accRecs[0].Name.containsIgnoreCase('(JEI)') || accRecs[0].Name.containsIgnoreCase('Jerry\'s Enterprises')) {
                        bhName = accRecs[0].Timezone__c + ' - ' + c.Priority + ' - JRY';
                    } else if(accRecs[0].Name.containsIgnoreCase('CUB') || accRecs[0].Name.containsIgnoreCase('SHOPPER')){
                        bhName = accRecs[0].Timezone__c + ' - ' + c.Priority + ' - CUB';
                    } else if (accRecs[0].Name.containsIgnoreCase('Big Y Foods')){
                        bhName = accRecs[0].Timezone__c + ' - ' + c.Priority + ' - BYF';
                    }
                    for(BusinessHours bh : bhs){
                        if(bh.Name != bhName) continue;
                        c.BusinessHoursId = bh.Id;
                    }
                }
                if(c.Service_Type__c == 'Onsite Labor Only' || c.Service_Type__c == 'Onsite IMAC'){
                    if(c.Priority == 'Severity 1'){
                        s1WoCounter++;
                    }
                    if(c.Priority == 'Severity 2'){
                        s2WoCounter++;
                    }
                }
                for(Entitlement et : entl) {
                    if((!c.Out_Of_Scope__c) && (et.Type == c.Service_Type__c)){
                        c.EntitlementId = et.Id;
                    }
                    if((!c.Out_Of_Scope__c) && (et.Type == 'Onsite Labor Only') && (c.Service_Type__c == 'Onsite Labor Only')){
                        c.EntitlementId = et.Id;
                    }
                    //for revisit new workorder entitlement should be blank if SLA_Exception_Code__c is selected
                    if(newWorkOrder != null && newWorkOrder.SLA_Exception_Code__c != '' && newWorkOrder.SLA_Exception_Code__c != null){
                        c.EntitlementId = '';
                    }
                }
                if(bundleCase.Id != null){
                    c.ParentId = bundleCase.Id;
                }
                c.AccountId = accId;
                if(partnerQueue.size() != 0 && accRecs[0].ShippingCountry == 'Canada'){
                    c.OwnerId = partnerQueue[0].Id;
                }
                c.Origin = 'Web';
                // for red hot order priority to be Severity 1
                if(redHotOrder){
                    c.Priority = 'Severity 1';
                }
                System.debug('c:'+c);
            }
            List<PricebookEntry> pbe = [SELECT Id, Name, Product2Id, Product2.Name, Product2.Account_Item_Belongs_To__c, Product2.Staging_Required__c, Pricebook2Id, Pricebook2.Country__c FROM PricebookEntry WHERE (Product2Id IN : prodIds OR Product2.Family = 'Service' OR Product2.Name = :accRecs[0].Root_Account__r.Staging_Product__r.Name)];
            if(oldWorkOrder == null){
                insert CsLines;
            }
        }catch(DmlException ec){
            Database.rollback(sp);
            saveStatus = ec.getDmlMessage(0);
        }
        return saveStatus;
    }
    
    //Used in ProductManagementLineItemsInternal Component.
    // for new UI to assign case workorders
    @auraEnabled
    public static List<RecordType> getCaseRecordTypes(){
        return [SELECT Id, Name, DeveloperName FROM RecordType WHERE sObjectType='Case'];
    }
    
    //Used in ProductManagementLineItemsInternal Component.
    // for new UI to create cases  with product line items
    @auraEnabled
    public static String CreateCaseProdLineitems(List<Case> caseList, List<Case_Product__c> caseProducts, WorkOrder oldWorkOrder, WorkOrder newWorkOrder, boolean redHotOrder,List<Product2> serviceProdList){
        System.debug('caseList:' + JSON.Serialize(caseList));
        System.debug('caseProducts-> ' + JSON.Serialize(caseProducts));
        System.debug('serviceProdList-> ' + JSON.Serialize(serviceProdList));
        String saveStatus;
        Savepoint sp = Database.setSavepoint();
        try{
            Set<Id> accIds = new Set<Id>();
            set<Id> prodIds = new set<Id>();
            set<Id> scIds = new set<Id>();
            for(Case caseRec : caseList){
                caseRec.Origin = 'Web';
                caseRec.Products_Ordered__c = '';
                // for red hot order priority to be Severity 1
                if(redHotOrder){
                    caseRec.Priority = 'Severity 1';
                }
                if(!caseProducts.isEmpty()){
                    caseRec.ProductId = caseProducts[0].Product__c;
                    caseRec.Has_Case_Products__c = true;
                } else {
                    caseRec.Has_Case_Products__c = false;
                }
                accIds.add(caseRec.AccountId);
                scIds.add(caseRec.ServiceContractId);
            }
            for(Case_Product__c cp : caseProducts){
                if(cp.Product__c != null){
                    prodIds.add(cp.Product__c);
                }
            }
            List<Product2> productList = [SELECT Id, Name, ProductCode, Staging_Required__c, 
                                          (SELECT Id, Child_Product__c, Parent_Product__c FROM Product_Bundles__r) FROM Product2 
                                          WHERE Id IN: prodIds];
            decimal stagingCount = 0;
            Decimal totalQty = 0;
            for(Case caseRec : caseList){
                integer i = 1;
                for(Case_Product__c cp : caseProducts){
                    totalQty += cp.Quantity__c;
                    for(Product2 p : productList){
                        if(cp.Product__c == p.Id){
                            caseRec.Products_Ordered__c = caseRec.Products_Ordered__c +i+'. '+p.Name+'<br>  ';
                            i++;
                            if(p.Staging_Required__c) {
                                stagingCount += cp.Quantity__c;
                            }
                        }
                        for(Product_Bundle__c pb : p.Product_Bundles__r){
                            prodIds.add(pb.Child_Product__c);
                        }
                    }
                }
                caseRec.Product_Quantity__c = totalQty;
                if(oldWorkOrder == null){
                    caseRec.Staging_Required_Count__c = stagingCount;
                }
            }
            Map<Id,ServiceContract> scMap = new Map<Id,ServiceContract>([SELECT Id,ParentServiceContractId,(SELECT Id,Product2Id,Product2.Family,
                                                                         Product2.Name,Product2.Description, UnitPrice,Quantity, 
                                                                         ServiceContractId, Exclude_From_Service_Products__c FROM ContractLineItems
                                                                         WHERE Product2.Family = 'Hardware' AND Product2Id IN :prodIds) FROM ServiceContract 
                                                                         WHERE Id IN :scIds OR ParentServiceContractId IN :scIds]);
            if(oldWorkOrder == null){
                for(Case caseRec : caseList){
                    if(!scMap.containsKey(caseRec.ServiceContractId)) continue;
                    ServiceContract sc = scMap.get(caseRec.ServiceContractId);
                    List<ContractLineItem> cliList = sc.ContractLineItems;
                    if(!cliList.isEmpty()){
                        caseRec.Additional_Part_WO__c = true;
                    }
                }
            }

            Id bndleCs = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Bundle').getRecordTypeId();
            List<Entitlement> entlList = new List<Entitlement>();
            if(!accIds.isEmpty()) {
                entlList = [SELECT Id, Type,Name, AccountId FROM Entitlement WHERE AccountId IN :accIds];
            }
            Map<Id,Account> accMap = new Map<Id,Account>([SELECT Id, Name, Root_Account__r.Name, Parent.Email_To_Notify_On_Case_Creation__c,
                                                          Root_Account__r.Email_To_Notify_On_Case_Creation__c,
                                                          ShippingCountry, Timezone__c FROM Account WHERE Id IN :accIds]);
            System.debug('accMap-> ' + accMap);
            List<BusinessHours> bhsList = new List<BusinessHours>();
            if(accMap.size() != 0){
                bhsList = [SELECT Id, Name, IsActive FROM BusinessHours];
            }
            System.debug('bhsList-> ' + bhsList);
            List<Group> partnerQueue = [SELECT Id, Name, DeveloperName, Type FROM Group WHERE Type ='Queue' AND DeveloperName = 'Canada_Partner_Queue' LIMIT 1];
            System.debug('partnerQueue:'+partnerQueue);
            String loggedinUserEmail = userinfo.getUserEmail();
            System.debug('loggedinUserEmail::'+loggedinUserEmail);

            for(Case caseRec : caseList){
                if(!accMap.containsKey(caseRec.AccountId)) continue;
                Account acc = accMap.get(caseRec.AccountId);
                if(acc.Root_Account__r.Email_To_Notify_On_Case_Creation__c != null){
                    caseRec.Customer_Notification_Email2__c = acc.Root_Account__r.Email_To_Notify_On_Case_Creation__c;
                }
                if(acc.Parent.Email_To_Notify_On_Case_Creation__c != null){
                    caseRec.Customer_Notification_Email_4__c = acc.Parent.Email_To_Notify_On_Case_Creation__c;
                }
                if(acc.Root_Account__r.Name == System.Label.PBS_Account_Name){
                    caseRec.Customer_Notification_Email3__c = System.Label.Contact_Customer_Notification_Mail_3;
                } else if(acc.Root_Account__r.Name == System.Label.Maurice_Account_Name){
                    caseRec.Customer_Notification_Email3__c = System.Label.Maurices_Inc_Customer_Notification_Mail_3;
                } else if (acc.Root_Account__r.Name == System.Label.YM_LLC_Account_Name) {
                    caseRec.Customer_Notification_Email3__c = System.Label.YM_LLC_Customer_Notification_Mail_3;
                }
                if(partnerQueue.size() != 0 && acc.ShippingCountry == 'Canada'){
                    caseRec.OwnerId = partnerQueue[0].Id;
                }
                if((bhsList.size() != 0) && acc.Timezone__c != null){
                    String bhName = acc.Timezone__c +' - ' + caseRec.Priority;
                    if(acc.Name.containsIgnoreCase('ALDI')){
                        bhName = acc.Timezone__c + ' - ' + caseRec.Priority + ' - ALDI';
                    } else if(acc.Name.containsIgnoreCase('(JEI)') || acc.Name.containsIgnoreCase('Jerry\'s Enterprises')) {
                        bhName = acc.Timezone__c + ' - ' + caseRec.Priority + ' - JRY';
                    } else if(acc.Name.containsIgnoreCase('CUB') || acc.Name.containsIgnoreCase('SHOPPER')){
                        bhName = acc.Timezone__c + ' - ' + caseRec.Priority + ' - CUB';
                    } else if (acc.Name.containsIgnoreCase('Big Y Foods')){
                        bhName = acc.Timezone__c + ' - ' + caseRec.Priority + ' - BYF';
                    }
                    for(BusinessHours bh : bhsList){
                        if(bh.Name != bhName) continue;
                        caseRec.BusinessHoursId = bh.Id;
                    }
                }
                for(Entitlement et : entlList) {
                    if(caseRec.AccountId != et.AccountId) continue;
                    if((!caseRec.Out_Of_Scope__c) && (et.Type == caseRec.Service_Type__c)){
                        caseRec.EntitlementId = et.Id;
                    }
                    if((!caseRec.Out_Of_Scope__c) && (et.Type == 'Onsite Labor Only') && (caseRec.Service_Type__c == 'Onsite Labor Only')){
                        caseRec.EntitlementId = et.Id;
                    }
                    //for revisit new workorder entitlement should be blank if SLA_Exception_Code__c is selected
                    if(newWorkOrder != null && newWorkOrder.SLA_Exception_Code__c != '' && newWorkOrder.SLA_Exception_Code__c != null){
                        caseRec.EntitlementId = '';
                    }
                }
            }
            //Inserting CaseList
            insert caseList;
            
            System.debug('caseList-> ' + JSON.Serialize(caseList));
            Map<Id, List<Case_Product__c>> caseProductMap = new Map<Id, List<Case_Product__c>>();
            for(Case caseRec : caseList){
                System.debug('caseRec Id-> ' + caseRec.Id);
                List<Case_Product__c> caseProductsToInsert = new List<Case_Product__c>();
                System.debug('caseProducts size-> ' + caseProducts.size());
                for(Case_Product__c cp : caseProducts){
                    Case_Product__c cNew = new Case_Product__c();
                    cNew.Case__c = caseRec.Id;
                    cNew.Product__c = cp.Product__c;
                    cNew.Quantity__c = cp.Quantity__c;
                    // To Avoid Case Product Name Length error.
                    if(cp.Name != null && cp.Name != '' && cp.Name.length() > 80){
                        cNew.Case_Product_Full_Name__c = cp.Name;
                        cNew.Name = cp.Name.substring(0,79);
                    }
                    if(scMap.containsKey(caseRec.ServiceContractId)){
                        ServiceContract sc = scMap.get(caseRec.ServiceContractId);
                        List<ContractLineItem> cliList = sc.ContractLineItems;
                        for(ContractLineItem cli : cliList){
                            if(cp.Product__c == cli.Product2Id){
                                cNew.CLI_Product__c = true;
                            }
                        }
                    }
                    caseProductsToInsert.add(cNew);
                    System.debug('caseProductsToInsert to be inserted-> ' + JSON.Serialize(caseProductsToInsert));
                }
                caseProductMap.put(caseRec.Id, caseProductsToInsert);
                System.debug('caseProductMap to be inserted-> ' + JSON.Serialize(caseProductMap.values()));
            }
            List<Case_Product__c> allCaseProductsToInsert  = new List<Case_Product__c>();
            if(!caseProductMap.isEmpty()){
                for (List<Case_Product__c> caseProductList : caseProductMap.values()) {
                    allCaseProductsToInsert .addAll(caseProductList);
                }
                if (!allCaseProductsToInsert .isEmpty()) {
                    insert allCaseProductsToInsert ;
                }
            }
            //Taking peffered time from case form populated for CLIs.
            List<WorkOrder_Schedule__c> wosList = new List<WorkOrder_Schedule__c>();
            for(Case caseRec : caseList){
                for(Product2 prod : serviceProdList){
                    WorkOrder_Schedule__c wos = new WorkOrder_Schedule__c();
                    wos.Preferred_Time__c = prod.Dummy_Preferred_Time__c;
                    wos.Product__c = prod.Id;
                    wos.case__c = caseRec.Id;
                    wosList.add(wos);
                }
            }
            System.debug('wosList-->' + wosList);
            insert wosList;
            
            //To invoke 'Create WO Through Service Contract' flow.
            for(Case caseRec : caseList){
                caseRec.Create_Work_Order__c = true;
            }
            update caseList;
            
            /*if(!prodIds.isEmpty()){
                List<Product_Bundle__c> bundleProdList = [SELECT Id, Name, Child_Product__c, Parent_Product__c FROM Product_Bundle__c 
                                                          WHERE Parent_Product__c IN: prodIds AND Child_Product__c != null];
                if(bundleProdList.size() != 0){
                    System.debug('allCaseProductsToInsert [0].Case__c-> ' + allCaseProductsToInsert [0].Case__c);
                    ProductManagementInternal.createKitCaseProducts(allCaseProductsToInsert , bundleProdList);
                }
            }*/
            saveStatus = caseList[0].Id;//'success';
        }catch(DmlException ec){
            Database.rollback(sp);
            saveStatus = ec.getDmlMessage(0);
        }
        return saveStatus;
    }
    
    //Not Used
    //future shipment and PRLI creation
    /*@future
    public static void createPRLIandShipments(String woSerial, String caseProductListSerial, String accoutSerial){
        System.debug('woSerial-> ' + woSerial);
        WorkOrder workOrdRec = (WorkOrder)JSON.deserialize(woSerial, WorkOrder.class);
        List<Case_Product__c> caseProducts = (List<Case_Product__c>)JSON.deserialize(caseProductListSerial, List<Case_Product__c>.class);
        Account accountRec = (Account)JSON.deserialize(accoutSerial, Account.class);
        List<ShipmentItem> shipItemList = new List<ShipmentItem>();
        List<ProductRequestLineItem> prliList = new List<ProductRequestLineItem>();
        System.debug('workOrdLst :'+workOrdRec);
        Shipment ship = ProductManagementLineItemsInternal.checkLocationsAndCreateShipment(accountRec);
        ProductRequest pr = ProductManagementLineItemsInternal.createProductRequest(ship, workOrdRec.Id);
        for(Case_Product__c cp : caseProducts){
            if(ship.Id != null){
                shipItemList.add(ProductManagementLineItemsInternal.createShipmentItem(cp, ship.Id));
            }
            if(pr.Id != null){
                prliList.add(ProductManagementLineItemsInternal.createProductRequestLineItem(pr, cp));
            }
        }
        if(shipItemList.size() != 0){
            insert shipItemList;
        }
        if(prliList.size() != 0){
            insert prliList;
        }
    }*/
    
    /*
	@future
	public static void createShipItems(String siSerialized){
	List<ShipmentItem> siList = (List<ShipmentItem>)JSON.deserialize(siSerialized, List<ShipmentItem>.class);
	insert siList;
	}
	
	@future
	public static void createPRLIs(String prliSerialized){
	List<ProductRequestLineItem> prliList = (List<ProductRequestLineItem>)JSON.deserialize(prliSerialized, List<ProductRequestLineItem>.class);
	insert prliList;
	} */
    
    // To check and create location, addresses and shipment
    /*public static Shipment checkLocationsAndCreateShipment(Account acc){
        List<Schema.Location> locationList = [SELECT Id, Name, LocationType, (SELECT Id, Name, Street, City, Country, State, PostalCode, LocationType FROM Addresses) FROM Location WHERE (Name =: acc.Name or Name =: System.Label.IWCR_Warehouse)];
        Schema.Location wareHouseLoc = null;
        for(Schema.Location loc: locationList){
            if(loc.Name == System.Label.IWCR_Warehouse){
                wareHouseLoc = loc;
            }
        }
        if(locationList.size() <= 1){
            Schema.Location newLoc = new Schema.Location();
            newLoc.Name = acc.Name;
            newLoc.LocationType = 'Site';
            insert newLoc;
            locationList.add(newLoc);
        }
        Shipment shipmentRec = new Shipment();
        Schema.Address addrsRec = new Schema.Address();
        for(Schema.Location loc: locationList){
            if(loc.Name == acc.Name){
                if(loc.Addresses.size() != 0){
                    shipmentRec = ProductManagementLineItemsInternal.createShipment(wareHouseLoc, loc, loc.Addresses[0], acc.Name);
                }else{
                    Schema.Address addrs = new Schema.Address();
                    addrs.ParentId = loc.Id;
                    addrs.LocationType = 'Site';
                    addrs.Street = acc.ShippingStreet;
                    addrs.City = acc.ShippingCity;
                    addrs.Country = acc.ShippingCountry;
                    addrs.State = acc.ShippingState;
                    addrs.PostalCode = acc.ShippingPostalCode;
                    addrs.AddressType = 'Shipping';
                    addrsRec = addrs;
                }
            }
        }
        if(addrsRec.ParentId != null){
            insert addrsRec;
            for(Schema.Location loc: locationList){
                if(addrsRec.ParentId != loc.Id) continue;
                shipmentRec = ProductManagementLineItemsInternal.createShipment(wareHouseLoc, loc, addrsRec, acc.Name);
            }
        }
        if(shipmentRec.ShipToName != null){
            insert shipmentRec;
        }
        return shipmentRec;
    }*/
    
    //Not Used
    //create shipment
    /*public static Shipment createShipment(Schema.Location sourceLoc, Schema.Location destinationLoc, Schema.Address addrs, String accountName){
        Shipment ship = new Shipment();
        ship.SourceLocationId = sourceLoc.Id;
        ship.DestinationLocationId = destinationLoc.Id;
        if(sourceLoc.Addresses.size() != 0){
            ship.ShipFromStreet = sourceLoc.Addresses[0].Street;
            ship.ShipFromCity = sourceLoc.Addresses[0].City;
            ship.ShipFromState = sourceLoc.Addresses[0].State;
            ship.ShipFromPostalCode = sourceLoc.Addresses[0].PostalCode;
            ship.ShipFromCountry = sourceLoc.Addresses[0].Country;
        }
        ship.ShipToStreet = addrs.Street;
        ship.ShipToCity = addrs.City;
        ship.ShipToState = addrs.State;
        ship.ShipToPostalCode = addrs.PostalCode;
        ship.ShipToCountry = addrs.Country;
        ship.ShipToName = accountName;
        return ship;
    }*/
    
    //Not Used
    //create ShipmentItem
    /*public static ShipmentItem createShipmentItem(Case_Product__c cp, String shipmentId){
        ShipmentItem si = new ShipmentItem();
        si.Product2Id = cp.Product__c;
        si.Quantity = cp.Quantity__c;
        si.ShipmentId = shipmentId;
        return si;
    }*/
    
    //Not Used
    //create product request record
    /*public static ProductRequest createProductRequest(Shipment ship, String woId){
        ProductRequest pr = new ProductRequest();
        pr.WorkOrderId = woId;
        pr.SourceLocationId = ship.SourceLocationId;
        pr.DestinationLocationId = ship.DestinationLocationId;
        pr.ShipToStreet = ship.ShipToStreet;
        pr.ShipToCity = ship.ShipToCity;
        pr.ShipToState = ship.ShipToState;
        pr.ShipToPostalCode = ship.ShipToPostalCode;
        pr.ShipToCountry = ship.ShipToCountry;
        insert pr;
        return pr;
    }*/
    
    //Not Used
    //create product request line item record
    /*public static ProductRequestLineItem createProductRequestLineItem(ProductRequest pr, Case_Product__c cp){
        ProductRequestLineItem prli = new ProductRequestLineItem();
        prli.ParentId = pr.Id;
        prli.Product2Id = cp.Product__c;
        prli.QuantityRequested = cp.Quantity__c;
        prli.WorkOrderId = pr.WorkOrderId;
        prli.SourceLocationId = pr.SourceLocationId;
        prli.DestinationLocationId = pr.DestinationLocationId;
        prli.ShipToStreet = pr.ShipToStreet;
        prli.ShipToCity = pr.ShipToCity;
        prli.ShipToState = pr.ShipToState;
        prli.ShipToPostalCode = pr.ShipToPostalCode;
        prli.ShipToCountry = pr.ShipToCountry;
        return prli;
    }*/

    //Used in CreateCaseProdLineitems Mehtod.
    //create case products for product bundles (kit products)

    /*public static void createKitCaseProducts(List<Case_Product__c> cpList, List<Product_Bundle__c> bundleList){
        List<Case_Product__c> kitCPList = new List<Case_Product__c>();
        for(Product_Bundle__c pb : bundleList){
            for(Case_Product__c cp : cpList){
                if(cp.Case__c == null) continue;
                if(pb.Parent_Product__c == cp.Product__c){
                    Case_Product__c cpNew = new Case_Product__c();
                    cpNew.Case__c = cp.Case__c;
                    cpNew.Product__c = pb.Child_Product__c;
                    cpNew.Quantity__c = cp.Quantity__c;
                    kitCPList.add(cpNew);
                }
            }
        }
        if(kitCPList.size() != 0){
            insert kitCPList;
        }
    }*/
    
    //Used in ProductManagement & RevisitWorkOrder Components.
    @AuraEnabled
    public static List<Code__c> getProductProblemCodes(Id prodId){
        List<Product2> prodList = [SELECT Family FROM Product2 WHERE Id = :prodId];
        List<Code__c> problemCodes = [SELECT Id, Name FROM Code__c WHERE Product_Family__c = :prodList[0].Family AND Type__c = 'Problem Code'];
        return problemCodes;
    }

    //Used in ProductManagementLineItemsInternal Component.
    @AuraEnabled
    public static List<ServiceContract> getServiceContracts(String accountId,String location){
        System.debug('accountId-> ' + accountId);
        List<ServiceContract> scList = new List<ServiceContract>();
        Schema.DescribeFieldResult fieldResult = ServiceContract.Service_Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        Account acc = [SELECT Id,Name,Root_Account__c,ShippingCountry FROM Account WHERE Id =: accountId LIMIT 1];
        System.debug('acc Name-> ' + acc.Name);
        System.debug('acc Root_Account__c-> ' + acc.Root_Account__c);
        if(acc.Root_Account__c != null){
            accountId = String.valueOf(acc.Root_Account__c);
        }
        if(location == null){
            location = acc.ShippingCountry;
        }
        List<ServiceContract> svcList = [SELECT Name,PO_Number__c,Work_Order_Record_Type__c  ,Description,Disable_Adding_Hardware_Products__c,Support_Team__c,
                                            Support_Team__r.Tech_Notes__c,Include_Part__c,Priority__c,Status,Create_Work_Order_For__c,
                                            Hardware_Product_Required__c,Show_CLIs_As_Service_Products__c,Service_Type__c,Schedulable__c,
                                            Country__c FROM ServiceContract WHERE AccountId = :accountId 
                                            AND Include_in_Service_Type_Picklist__c = true AND Country__c = : location AND Status = 'Active'];
        for( Schema.PicklistEntry pickListVal : ple){
            for(ServiceContract sc : svcList){
                System.debug('pickListVal-->'+ pickListVal);
                if(pickListVal.getValue() == sc.Service_Type__c){
                    scList.add(sc);
                }
            }
        }
        return scList;
    }

    //Used in ProductManagementLineItemsInternal Component.
    @AuraEnabled
    public static List<String> getDepartments(){
        List<String> departments = new List<String>();
        Schema.DescribeFieldResult fieldResult = Case.Department2__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            departments.add(pickListVal.getValue());
        }
        return departments;
    }

    //Used in ProductManagementLineItemsInternal Component.
    @AuraEnabled
    public static List<Equipment_Type__c> getEquipmentTypes(String parentAccountId){
        System.debug('getProblemTypes parentAccountId -> ' + parentAccountId);
        List<Equipment_Type_For_Account__c> etaList = [SELECT Equipment_Type__c,Account__c FROM Equipment_Type_For_Account__c WHERE Account__c =: parentAccountId];
        Set<Id> etIds = new Set<Id>();
        for(Equipment_Type_For_Account__c eta : etaList){
            etIds.add(eta.Equipment_Type__c);
        }
        return [SELECT Id, Name, Product_Grouping__c, Product_Grouping__r.Name FROM Equipment_Type__c WHERE Id IN:etIds ORDER BY Name];
    }

    //Used in ProductManagementLineItemsInternal Component.
    @AuraEnabled
    public static List<Problem_Type__c> getProblemTypes(String productGroupingId){
        System.debug('getProblemTypes productGroupingId -> ' + productGroupingId);
        List<Problem_Type_Product_Grouping_Pair__c> ptpgList = [SELECT Problem_Type__c FROM Problem_Type_Product_Grouping_Pair__c WHERE Product_Grouping__c = :productGroupingId];
        Set<Id> ptIds = new Set<Id>();
        for(Problem_Type_Product_Grouping_Pair__c ptpg : ptpgList) {
            ptIds.add(ptpg.Problem_Type__c);
        }
        return [SELECT Id, Name FROM Problem_Type__c where Id IN :ptIds ORDER BY Name];
    }

    //Used in ProductManagementLineItemsInternal Component.
    @AuraEnabled
    public static List<Product2> getServiceProdcuts(String ServiceContractId){
        List<Product2> prodListToGo = new List<Product2>();
        if(String.isBlank(ServiceContractId)) return prodListToGo;

        Map<Id,ServiceContract> svcMap = new Map<Id,ServiceContract>([SELECT Id,Work_Order_Record_Type__c, Hardware_Product_Required__c,Create_Work_Order_For__c, Show_CLIs_As_Service_Products__c, 
                                                                      (SELECT Product2Id,Exclude_From_Service_Products__c,Product2.Family,Product2.Out_of_Scope__c,Quantity 
                                                                      FROM ContractLineItems WHERE Exclude_From_Service_Products__c = false) 
                                                                      FROM ServiceContract WHERE Id = :ServiceContractId OR ParentServiceContractId = :ServiceContractId
                                                                    ]);
        Set<Id> prodIds = new Set<Id>();
        Map<Id,ContractLineItem> cliMap = new Map<Id,ContractLineItem>();
        for(Id svcId : svcMap.keySet()) {
            cliMap.putAll(svcMap.get(svcId).ContractLineItems);
            for(ContractLineItem cli : svcMap.get(svcId).ContractLineItems) {
                prodIds.add(cli.Product2Id);
            }
        }
        if(prodIds.isEmpty()) return prodListToGo;

        List<Product2> prodList = [SELECT Id, Name, Family, Quantity__c, Out_of_Scope__c FROM Product2 WHERE Id IN :prodIds AND isActive = true AND source_key__c != null];
        Map<Id,Decimal> prodQtyMap = new Map<Id,Decimal>();
        for(ContractLineItem cli : cliMap.values()) {
            for(Product2 p : prodList){
                if(p.Id != cli.Product2Id) continue;
                if(prodListToGo.contains(p)) continue;
                if(cli.Quantity == null || cli.Quantity == 0) cli.Quantity = 1; 
                prodQtyMap.put(p.Id,cli.Quantity);
                p.Quantity__c = cli.Quantity;
                prodListToGo.add(p);
            }
        }
        List<Product_Bundle__c> pbList = [SELECT Id, Parent_Product__c, Child_Product__c, Child_Product_Qty__c FROM Product_Bundle__c WHERE Parent_Product__c =: prodIds];
        Set<Id> bundleProdIds = new Set<Id>();
        for(Product_Bundle__c pb : pbList){
            bundleProdIds.add(pb.Child_Product__c);
        }
        List<Product2> bundleProdList = [SELECT Id, Name, Family, Quantity__c, Out_of_Scope__c FROM Product2 
                                         WHERE Id IN :bundleProdIds AND isActive = true AND source_key__c != null];
        prodListToGo.addAll(bundleProdList);
        for(Product_Bundle__c pb : pbList){
            for(Product2 prod : prodListToGo) {
                if(pb.Child_Product__c != prod.Id) continue;
                Decimal pbQty = (pb.Child_Product_Qty__c != null && pb.Child_Product_Qty__c != 0) ? pb.Child_Product_Qty__c : 1;
                Decimal cliQty = (prodQtyMap.containsKey(pb.Parent_Product__c)) ? prodQtyMap.get(pb.Parent_Product__c) : 1;
                prod.Quantity__c = cliQty * pbQty;
                prod.NS_Item_Class__c = 'Bundle Product';
                break;
            }
        }
        System.debug('prodListToGo size-> ' + prodListToGo.size());
        System.debug('prodListToG-> ' + JSON.Serialize(prodListToGo));
        return prodListToGo;
    }

    //Used in ProductManagementLineItemsInternal Component.
    @auraEnabled
    public static List<Product2> getBundleProducts (String scId, String parentProdId){
        List<Product2> prodListToGo = new List<Product2>();
        if(!String.isBlank(parentProdId)) {
            List<Product_Bundle__c> pbList = [SELECT Id, Parent_Product__c, Child_Product__c, Child_Product_Qty__c FROM Product_Bundle__c WHERE Parent_Product__c =: parentProdId];
            Set<Id> bundleProdIds = new Set<Id>();
            for(Product_Bundle__c pb : pbList){
                bundleProdIds.add(pb.Child_Product__c);
            }
            bundleProdIds.add(parentProdId);
            Map<Id,Product2> bundleProdMap = new Map<Id,Product2>([SELECT Id, Name, Quantity__c, Out_of_Scope__c FROM Product2 WHERE Id IN :bundleProdIds AND isActive = true 
                                             AND source_key__c != null]);
            if(!bundleProdMap.isEmpty() && bundleProdMap.size() > 1) {
                if(bundleProdMap.containsKey(parentProdId)) prodListToGo.add(bundleProdMap.get(parentProdId));
                for(Product2 p : bundleProdMap.values()) {
                    if(p.Id != parentProdId) prodListToGo.add(p);
                }
            }
            List<ContractLineItem> cliList = new List<ContractLineItem>();
            if(!String.isBlank(scId)) {
                cliList = [SELECT Id,Product2Id,Quantity FROM ContractLineItem 
                           WHERE ServiceContractId =:scId AND Product2.Family = 'Hardware' AND Exclude_From_Service_Products__c = false];
            }
            Map<Id,Decimal> prodQtyMap = new Map<Id,Decimal>();
            for(ContractLineItem cli : cliList){
                if(cli.Quantity == null || cli.Quantity == 0) cli.Quantity = 1;
                prodQtyMap.put(cli.Product2Id,cli.Quantity);
            }
            for(Product_Bundle__c pb : pbList){
                for(Product2 prod : prodListToGo) {
                    if(pb.Parent_Product__c == prod.Id) {
                        prod.Quantity__c = (prodQtyMap.containsKey(prod.Id)) ? prodQtyMap.get(prod.Id) : 1;
                        prod.NS_Item_Class__c = '';
                        continue;
                    }
                    if(pb.Child_Product__c != prod.Id) continue;
                    Decimal pbQty = (pb.Child_Product_Qty__c != null && pb.Child_Product_Qty__c != 0) ? pb.Child_Product_Qty__c : 1;
                    Decimal cliQty = (prodQtyMap.containsKey(pb.Parent_Product__c)) ? prodQtyMap.get(pb.Parent_Product__c) : 1;
                    prod.Quantity__c = cliQty * pbQty;
                    prod.NS_Item_Class__c = 'Bundle Product';
                }
            }
        }
        return prodListToGo;
    }    

    //Used in ProductManagementLineItemsInternal Component.
    @auraEnabled
    public static List<CaseTemplate__c> getCaseTemplates(String RootAccountId){
        return [SELECT Id,Name,Template__c,Root_Account__c FROM CaseTemplate__c WHERE Root_Account__c =: RootAccountId];
    }

    //Used in ProductManagementLineItemsInternal Component.
    @auraEnabled
    public static void createNewTemplate(String RootAccountId, String selectedTemplate, String TemplateName){
        CaseTemplate__c ct = new CaseTemplate__c();
        ct.Name = TemplateName;
        ct.Root_Account__c = RootAccountId;
        ct.Template__c = selectedTemplate;
        insert ct;
    }

    //Used in ProductManagementLineItemsInternal Component.
    @auraEnabled
    public static Account getChildAccount(Id AccountId){
        return [SELECT Id,Name FROM Account WHERE Id =: AccountId];
    }

    //Used in ProductManagementLineItemsInternal Component.
    @auraEnabled
    public static Map<String,String> getHelpTexts(){
        Map<String,String> helpTextMap = new Map<String,String>();
        String AccountIdHelpText = Case.AccountId.getDescribe().getInlineHelpText();
        if(String.isNotBlank(AccountIdHelpText)){
            helpTextMap.put('AccountId',AccountIdHelpText);
        }
        String ServiceTypeHelpText = Case.Service_Type__c.getDescribe().getInlineHelpText();
        if(String.isNotBlank(ServiceTypeHelpText)){
            helpTextMap.put('Service_Type__c',ServiceTypeHelpText);
        }
        String PreferredTimeHelpText = Case.Preferred_Time__c.getDescribe().getInlineHelpText();
        if(String.isNotBlank(PreferredTimeHelpText)){
            helpTextMap.put('Preferred_Time__c',PreferredTimeHelpText);
        }
        String PriorityHelpText = Case.Priority.getDescribe().getInlineHelpText();
        if(String.isNotBlank(PriorityHelpText)){
            helpTextMap.put('Priority',PriorityHelpText);
        }
        String POSRegisterNumberHelpText = Case.POS_Register_Number__c.getDescribe().getInlineHelpText();
        if(String.isNotBlank(POSRegisterNumberHelpText)){
            helpTextMap.put('POS_Register_Number__c',POSRegisterNumberHelpText);
        }
        String PONumberHelpText = Case.PO_Number__c.getDescribe().getInlineHelpText();
        if(String.isNotBlank(PONumberHelpText)){
            helpTextMap.put('PO_Number__c',PONumberHelpText);
        }
        String IncidentHelpText = Case.Incident__c.getDescribe().getInlineHelpText();
        if(String.isNotBlank(IncidentHelpText)){
            helpTextMap.put('Incident__c',IncidentHelpText);
        }
        String SupportTeamHelpText = Case.Support_Team__c.getDescribe().getInlineHelpText();
        if(String.isNotBlank(SupportTeamHelpText)){
            helpTextMap.put('Support_Team__c',SupportTeamHelpText);
        }
        String TechNotesHelpText = Case.Tech_Notes__c.getDescribe().getInlineHelpText();
        if(String.isNotBlank(TechNotesHelpText)){
            helpTextMap.put('Tech_Notes__c',TechNotesHelpText);
        }
        String DescriptionHelpText = Case.Description.getDescribe().getInlineHelpText();
        if(String.isNotBlank(DescriptionHelpText)){
            helpTextMap.put('Description',DescriptionHelpText);
        }
        String AssetNumberHelpText = Case.Asset_Number__c.getDescribe().getInlineHelpText();
        if(String.isNotBlank(AssetNumberHelpText)){
            helpTextMap.put('Asset_Number__c',AssetNumberHelpText);
        }
        String OnsiteContactNameHelpText = Case.Onsite_Contact_Name__c.getDescribe().getInlineHelpText();
        if(String.isNotBlank(OnsiteContactNameHelpText)){
            helpTextMap.put('Onsite_Contact_Name__c',OnsiteContactNameHelpText);
        }
        String IncludePartHelpText = Case.Include_Part__c.getDescribe().getInlineHelpText();
        if(String.isNotBlank(IncludePartHelpText)){
            helpTextMap.put('Include_Part__c',IncludePartHelpText);
        }
        String DepartmentHelpText = Case.Department2__c.getDescribe().getInlineHelpText();
        if(String.isNotBlank(DepartmentHelpText)){
            helpTextMap.put('Department2__c',DepartmentHelpText);
        }
        String EquipmentTypeHelpText = Case.Equipment_Type__c.getDescribe().getInlineHelpText();
        if(String.isNotBlank(EquipmentTypeHelpText)){
            helpTextMap.put('Equipment_Type__c',EquipmentTypeHelpText);
        }
        String ProblemTypeHelpText = Case.Problem_Type__c.getDescribe().getInlineHelpText();
        if(String.isNotBlank(ProblemTypeHelpText)){
            helpTextMap.put('Problem_Type__c',ProblemTypeHelpText);
        }
        return helpTextMap;
    }
}