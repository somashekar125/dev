@isTest
public class WorkOrderTriggerTest {
    @testSetup static void setup() {
        Global_Settings__c gs = TestDataFactory.CreateGlobalSettings();
        insert gs;
        Account rootAcc = TestDataFactory.createAccount();
        rootAcc.Name = 'Aldi Inc.';
        insert rootAcc;

        Product2 stagProd = TestDataFactory.createProduct2(rootAcc);
        stagProd.Name = 'Test Verifone E355 3-Unit Gang Charger';
        insert stagProd;
        rootAcc.Staging_Product__c = stagProd.Id;
        update rootAcc;
        
        Account rootAcc2 = TestDataFactory.createAccount(); 
        rootAcc2.Name = 'Premium Brands Services,LLC';
        rootAcc2.Source_Key__c = '565';
        insert rootAcc2;
        
        List<Account> accList = new List<Account>();
        Account acc = TestDataFactory.createAccount();
        acc.Root_Account__c = rootAcc.Id;
        acc.Source_Key__c = '1265865';
        accList.add(acc);
        
        Account acc2 = new Account();
        acc2.Name = 'test account2';
        //acc2.Root_Account__c = rootAcc.Id;
        acc2.Account_Rep__c = userInfo.getUserId();
        acc2.Timezone__c = 'EST';
        acc2.ShippingState = 'Canada';
        acc2.Source_Key__c = '12865';
        accList.add(acc2);
        Account acc3 = new Account();
        acc3.Name = 'CUB 001';
        acc3.Account_Rep__c = userInfo.getUserId();
        acc3.Timezone__c = 'CST';
        acc3.ShippingState = 'Canada';
        acc3.Source_Key__c = '1261865';
        accList.add(acc3);
        Account acc4 = new Account();
        acc4.Name = 'PBS 01';
        acc4.Root_Account__c = rootAcc2.Id;
        acc4.Account_Rep__c = userInfo.getUserId();
        acc4.Timezone__c = 'EST';
        acc4.ShippingState = 'United States';
        acc4.Source_Key__c = '1865';
        accList.add(acc4);
        insert accList;
        
        Project__c pro = new Project__c();
        pro.Name = 'Test Project';
        pro.Client__c = acc.Id;
        pro.Applicable_on_Days__c = 'Monday;Tuesday;Wednesday;Thursday;Friday';
        pro.Number_of_visits__c = 3;
        pro.Visit_Offset__c = 1;
        Datetime dt = Datetime.now();
        pro.Start_Time__c = dt.time();
        insert pro;
        
        Project_Account__c prjAcc = new Project_Account__c();
        prjAcc.Name = 'Test PA 1';
        prjAcc.Account__c = acc.Id;
        prjAcc.Project__c = pro.Id;
        prjAcc.Visit_1__c = Datetime.now().addDays(2);
        insert prjAcc;
        
        Id pricebookId = Test.getStandardPricebookId();
        List<ServiceContract> scList = new List<ServiceContract>();
        ServiceContract sc = TestDataFactory.createServiceContract(accList[0]);
        scList.add(sc);
        ServiceContract sc1 = TestDataFactory.createServiceContract(accList[0]);
        sc1.Service_Type__c = 'Onsite Labor Only';
        sc1.Visit_Order__c = 'Visit 1';
        scList.add(sc1);
        ServiceContract sc2 = TestDataFactory.createServiceContract(accList[0]);
        sc2.Service_Type__c = 'Advance Exchange + Onsite';
        sc2.Visit_Order__c = 'Visit 2';
        scList.add(sc2);
        ServiceContract sc3 = TestDataFactory.createServiceContract(accList[0]);
        sc3.Service_Type__c = 'Part Return';
        sc3.Visit_Order__c = 'Visit 1';
        scList.add(sc3);
        ServiceContract sc4 = TestDataFactory.createServiceContract(accList[0]);
        sc4.Service_Type__c = 'Onsite IMAC';
        sc4.Visit_Order__c = 'Visit 3';
        scList.add(sc4);
        
        ServiceContract sc5 = TestDataFactory.createServiceContract(accList[1]);
        sc5.Country__c = 'Canada';
        sc5.Visit_Order__c = 'Visit 3';
        scList.add(sc5);
        ServiceContract sc6 = TestDataFactory.createServiceContract(accList[1]);
        sc6.Service_Type__c = 'Onsite Labor Only';
        sc6.Country__c = 'Canada';
        sc6.Visit_Order__c = 'Visit 2';
        scList.add(sc6);
        ServiceContract sc7 = TestDataFactory.createServiceContract(accList[1]);
        sc7.Service_Type__c = 'Advance Exchange + Onsite';
        sc7.Country__c = 'Canada';
        sc7.Visit_Order__c = 'Visit 1';
        scList.add(sc7);
        ServiceContract sc8 = TestDataFactory.createServiceContract(accList[1]);
        sc8.Service_Type__c = 'Part Return';
        sc8.Country__c = 'Canada';
        sc8.Visit_Order__c = 'Visit 3';
        scList.add(sc8);
        insert scList;
        
        List<Case> csList = new List<Case>();
        Case cs = TestDataFactory.createCase(acc, scList[0]);
        cs.Staging_Required_Count__c = 1;
        csList.add(cs);
        Case cs1 = TestDataFactory.createCase(acc, scList[0]);
        cs1.AccountId = acc2.Id;
        csList.add(cs1);
        Case cs2 = TestDataFactory.createCase(acc, scList[1]);
        cs2.Service_Type__c = 'Onsite Labor Only';
        csList.add(cs2);
        Case cs3 = TestDataFactory.createCase(acc, scList[2]);
        cs3.Service_Type__c = 'Advance Exchange + Onsite';
        csList.add(cs3);
        Case cs4 = TestDataFactory.createCase(acc, scList[3]);
        cs4.Service_Type__c = 'Part Return';
        csList.add(cs4);
        Case cs5 = TestDataFactory.createCase(acc, scList[3]);
        cs5.Service_Type__c = 'Part Return';
        cs5.AccountId = acc2.Id;
        csList.add(cs5);
        Case cs6 = TestDataFactory.createCase(acc, scList[4]);
        cs6.Service_Type__c = 'Onsite IMAC';
        cs6.Preferred_Time__c = System.now().addDays(1);
        cs6.Root_Account__c = rootAcc.Id;
        cs6.AccountId = acc.Id;
        csList.add(cs6);
        insert csList;
        FSL__Scheduling_Policy__c sp = new FSL__Scheduling_Policy__c();
        sp.Name = 'Test CUB Scheduling_Policy';
        insert sp;
        
        Id partShipRT = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Part_Shipment').getRecordTypeId();
        Test.startTest();
        WorkOrder woParent = new WorkOrder();
        woParent.AccountId = acc.Id;
        woParent.Root_Account__c = rootAcc.Id;
        woParent.CaseId = cs.Id;
        woParent.ServiceContractId = sc.Id;
        woParent.RecordTypeId = partShipRT;
        woParent.Pricebook2Id = pricebookId;
        woParent.No_Cost__c = true;
        woParent.Priority = 'Severity 1';
        woParent.status = 'New';
        woParent.Service_Type__c = 'Advance Exchange (Depot Only)';
        woParent.Check_In_Time__c = System.now();
        woParent.Check_Out_Time__c = System.now().addDays(1);
        woParent.Time_Entries__c = '2023-04-24 11:00:00 - 2023-04-25 11:00:00 (24:00)';
        woParent.SLA_Due_DateTime__c = System.now().AddDays(5);
        woParent.Technician_OnSite_ETA_String__c = '2023-01-31T06:00:00+00:00';
        woParent.Technician_Name__c = 'Mr.Test1';
        woParent.Technican_Phone__c = '12121';
        woParent.Onsite_Manager_Name__c = 'Mr.Test1';
        woParent.Resolution_Code__c = 'RESOLVED';
        woParent.Resolution_Notes__c = 'Test';
        woParent.Technician_OnSite_ETA__c = System.now();
        woParent.SLA_Exception_Code__c = 'CUSTOMER SOFTWARE ISSUE';
        woParent.NetSuite_Error__c = false;
        woParent.Tracking_Numbers__c = '1212';
        woParent.Check_Out_Lat_Lon__latitude__s = 11;
        woParent.Check_Out_Lat_Lon__longitude__s = 11;
        woParent.Check_In_Lat_Lon__latitude__s = 22;
        woParent.Check_In_Lat_Lon__longitude__s = 22;
        woParent.Latitude = 33;
        woParent.Longitude = 44;
        woParent.PO__c = 'Parent WO';
        woParent.Billable_Expense_Total__c = 10;
        insert woParent;
        
        Event e = TestDataFactory.createEvent(woParent);
        insert e;
        
        List<ServiceAppointment> saList = new List<ServiceAppointment>();
        ServiceAppointment sa = TestDataFactory.createServiceAppointment(woParent);
        saList.add(sa);
        insert saList;
        
        list<Product2> prodList = new list<Product2>();
        Product2 prod = TestDataFactory.createProduct2(acc);
        Product2 prod1 = new Product2(Name = 'ES-ONSITE-EQUIPMENT-RENTAL-COST',Source_Key__c = '22222', isActive =  true,
                                      Family = 'Service', Account_Item_Belongs_To__c = acc.Id,No_Return_Shipment__c = true);
        Product2 prod2 = new Product2(Name = 'Test prod 3',isActive =  true,
                                      Family = 'Hardware', Account_Item_Belongs_To__c = acc2.Id,No_Return_Shipment__c = true);
        Product2 prod3 = new Product2(Name = 'ES-ONSITE-EQUIPMENT-RENTAL-CHARGE',Source_Key__c = '22222',isActive =  true,
                                      Family = 'Service', Account_Item_Belongs_To__c = acc2.Id);
        Product2 prod4 = new Product2(Name = 'ES-ONSITE-MATERIALS-CHARGE',Source_Key__c = '22222',isActive =  true,
                                      Family = 'Service', Account_Item_Belongs_To__c = acc.Id);
        Product2 prod5 = new Product2(Name = 'Test Verifone E355 3-Unit Gang Charger',isActive =  true,
                                      Family = 'Hardware', Account_Item_Belongs_To__c = acc.Id,Out_of_Scope__c = true);
        Product2 prod6 = new Product2(Name = 'ES-ONSITE-EQUIPMENT-RENTAL-COST',Source_Key__c = '22222',isActive =  true,
                                      Family = 'Service', Account_Item_Belongs_To__c = acc2.Id,No_Return_Shipment__c = true);
        Product2 prod7 = new Product2(Name = 'CO RDF',Source_Key__c = '22222',isActive =  true,
                                      Family = 'Service', Account_Item_Belongs_To__c = acc.Id,No_Return_Shipment__c = true);
        prodList.add(prod);
        prodList.add(prod1);
        prodList.add(prod2);
        prodList.add(prod3);
        prodList.add(prod4);
        prodList.add(prod5);
        prodList.add(prod6);
        prodList.add(prod7);
        insert prodList;
        
        List<Case_Product__c> cpList = new List<Case_Product__c>();
        Case_Product__c cp = new Case_Product__c(Name = 'test1', Case__c =csList[0].Id, Product__c = prodList[0].Id,Quantity__c = 1);
        Case_Product__c cp1 = new Case_Product__c(Name = 'test2', Case__c =csList[1].Id, Product__c = prodList[0].Id,Quantity__c = 1);
        Case_Product__c cp2 = new Case_Product__c(Name = 'test3', Case__c =csList[2].Id, Product__c = prodList[0].Id,Quantity__c = 1);
        Case_Product__c cp3 = new Case_Product__c(Name = 'test4', Case__c =csList[3].Id, Product__c = prodList[0].Id,Quantity__c = 1);
        Case_Product__c cp4 = new Case_Product__c(Name = 'test4', Case__c =csList[4].Id, Product__c = prodList[0].Id,Quantity__c = 1);
        Case_Product__c cp5 = new Case_Product__c(Name = 'test4', Case__c =csList[0].Id, Product__c = prodList[1].Id,Quantity__c = 1);
        Case_Product__c cp6 = new Case_Product__c(Name = 'test4', Case__c =csList[1].Id, Product__c = prodList[1].Id,Quantity__c = 1);
        Case_Product__c cp7 = new Case_Product__c(Name = 'test4', Case__c =csList[2].Id, Product__c = prodList[1].Id,Quantity__c = 1);
        Case_Product__c cp8 = new Case_Product__c(Name = 'test4', Case__c =csList[3].Id, Product__c = prodList[1].Id,Quantity__c = 1);
        Case_Product__c cp9 = new Case_Product__c(Name = 'test4', Case__c =csList[4].Id, Product__c = prodList[1].Id,Quantity__c = 1);
        Case_Product__c cp10 = new Case_Product__c(Name = 'test4', Case__c =csList[0].Id, Product__c = prodList[5].Id,Quantity__c = 1);
        cpList.add(cp);
        cpList.add(cp1);
        cpList.add(cp2);
        cpList.add(cp3);
        cpList.add(cp4);
        cpList.add(cp5);
        cpList.add(cp6);
        cpList.add(cp7);
        cpList.add(cp8);
        cpList.add(cp9);
        cpList.add(cp10);
        insert cpList;
        
        list<PricebookEntry> pbeList = new list<PricebookEntry>();
        PricebookEntry standardPrice = TestDataFactory.createPricebookEntry(prodList[0]);
        PricebookEntry standardPrice1 = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prodList[1].Id,
            UnitPrice = 10000, IsActive = true, Out_of_Scope_Price__c = 100);
        PricebookEntry standardPrice2 = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prodList[2].Id,
            UnitPrice = 10000, IsActive = true, Out_of_Scope_Price__c = 100);
        PricebookEntry standardPrice3 = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prodList[3].Id,
            UnitPrice = 10000, IsActive = true, Out_of_Scope_Price__c = 100);
        PricebookEntry standardPrice4 = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prodList[4].Id,
            UnitPrice = 10000, IsActive = true, Out_of_Scope_Price__c = 100);
        PricebookEntry standardPrice5 = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prodList[5].Id,
            UnitPrice = 10000, IsActive = true, Out_of_Scope_Price__c = 100);
        PricebookEntry standardPrice6 = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prodList[6].Id,
            UnitPrice = 10000, IsActive = true, Out_of_Scope_Price__c = 100);
        PricebookEntry standardPrice7 = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prodList[7].Id,
            UnitPrice = 10000, IsActive = true, Out_of_Scope_Price__c = 100);
        pbeList.add(standardPrice);
        pbeList.add(standardPrice1);
        pbeList.add(standardPrice2);
        pbeList.add(standardPrice3);
        pbeList.add(standardPrice4);
        pbeList.add(standardPrice5);
        pbeList.add(standardPrice6);
        pbeList.add(standardPrice7);
        insert pbeList;
        
        List<ContractLineItem> cliList = new List<ContractLineItem>();
        ContractLineItem cli = new ContractLineItem();
        cli.ServiceContractId = scList[2].id;
        cli.PricebookEntryId = pbeList[1].id;
        cli.UnitPrice = 100;
        cli.Quantity =1 ;
        cli.Priority__c = 'Severity 1' ;
        cli.Applicable_After_Total_Hours__c = 4;
        cli.Applicable_If_IMAC_Due_Hours_Within__c = 30;
        cliList.add(cli);
        ContractLineItem cli2 = new ContractLineItem();
        cli2.ServiceContractId = scList[2].id;
        cli2.PricebookEntryId = pbeList[2].id;
        cli2.UnitPrice = 100;
        cli2.Quantity =1 ;
        cli2.Priority__c = 'Severity 1' ;
        cli2.Applicable_After_Total_Hours__c = 4;
        cli2.Applicable_If_IMAC_Due_Hours_Exceeding__c = 2;
        cliList.add(cli2);
        ContractLineItem cli3 = new ContractLineItem();
        cli3.ServiceContractId = scList[2].id;
        cli3.PricebookEntryId = pbeList[2].id;
        cli3.UnitPrice = 100;
        cli3.Quantity =1 ;
        cli3.Priority__c = 'Severity 1' ;
        cli3.Applicable_After_Total_Hours__c = 4;
        cli3.Applicable_If_IMAC_Due_Hours_Within__c = null;
        cli3.Applicable_If_IMAC_Due_Hours_Exceeding__c = null;
        cliList.add(cli3);
        
        ContractLineItem cli4 = new ContractLineItem();
        cli4.ServiceContractId = scList[7].id;
        cli4.PricebookEntryId = pbeList[1].id;
        cli4.UnitPrice = 100;
        cli4.Quantity = 1 ;
        cli4.Priority__c = 'Severity 1';
        cli4.Applicable_After_Total_Hours__c = 4;
        cli4.Applicable_If_IMAC_Due_Hours_Exceeding__c = 0;
        cli4.Applicable_If_IMAC_Due_Hours_Within__c = 0;
        cliList.add(cli4);
        
        ContractLineItem cli5 = new ContractLineItem();
        cli5.ServiceContractId = scList[4].id;
        cli5.PricebookEntryId = pbeList[0].id;
        cli5.UnitPrice = 100;
        cli5.Quantity =1 ;
        cli5.Priority__c = 'Severity 1' ;
        cli5.Applicable_After_Total_Hours__c = null;
        cli5.Applicable_If_IMAC_Due_Hours_Exceeding__c = 0;
        cliList.add(cli5);
        ContractLineItem cli6 = new ContractLineItem();
        cli6.ServiceContractId = scList[4].id;
        cli6.PricebookEntryId = pbeList[1].id;
        cli6.UnitPrice = 100;
        cli6.Quantity =1 ;
        cli6.Applicable_After_Total_Hours__c = null;
        cli6.Priority__c = 'Severity 1' ;
        cliList.add(cli6);
        
        ContractLineItem cli7 = new ContractLineItem();
        cli7.ServiceContractId = scList[0].Id;
        cli7.PricebookEntryId = standardPrice5.Id;
        cli7.UnitPrice = 100;
        cli7.Quantity = 1 ;
        cliList.add(cli7);
        
        ContractLineItem cli8 = new ContractLineItem();
        cli8.ServiceContractId = scList[0].Id;
        cli8.PricebookEntryId = standardPrice5.Id;
        cli8.UnitPrice = 100;
        cli8.Quantity = 1 ;
        cli8.Include_In_WO_Type__c = 'Part Shipment';
        cliList.add(cli8);
        insert cliList;
        
        list<Id> woId = new list<Id>();
        woId.add(woParent.Id);
        //FlowController.createHardwareWOLIs(woId);
        Test.stopTest();
        List<WorkOrderLineItem> woliList = [SELECT Id,Quantity,PricebookEntryId FROM WorkOrderLineItem WHERE WorkOrderId IN: woId AND PricebookEntryId =: standardPrice5.Id];
        System.assert(woliList != null);
    }
    
    @IsTest static void coverIMACCase(){
        Test.startTest();
        Project__c pro = [SELECT Id FROM Project__c LIMIT 1];
        Project_Account__c prjAcc = [SELECT Id FROM Project_Account__c LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name = 'test account' LIMIT 1];
        ServiceContract sc = [SELECT Id,Visit_Order__c FROM ServiceContract WHERE Service_Type__c = 'Onsite IMAC' AND AccountId =: acc.Id LIMIT 1];
        List<ContractLineItem> cliList = [SELECT Id FROM ContractLineItem WHERE ServiceContractId =: sc.Id];
        Map<Id,Product2> pbMap = new Map<Id,Product2>([SELECT Id FROM Product2 WHERE Account_Item_Belongs_To__c =: acc.Id]);
        list<PricebookEntry> pbeList = [SELECT Id FROM PricebookEntry WHERE Product2Id IN:pbMap.keySet()];
        Case cs = [SELECT Id,Preferred_Time__c,Root_Account__c FROM Case WHERE AccountId =: acc.Id AND Service_Type__c = 'Onsite IMAC' AND ServiceContractId =: sc.Id LIMIT 1];
        
        WorkOrder wo = TestDataFactory.createWorkOrder(cs, sc, acc);
        wo.Preferred_Time_IMAC__c = cs.Preferred_Time__c;
        wo.Root_Account__c = cs.Root_Account__c;
        wo.Technician_Status__c = 'Approved';
        wo.Project__c = pro.Id;
        wo.Project_Account__c = prjAcc.Id;
        insert wo;
        
        List<WorkOrderLineItem> woliList = [SELECT Id FROM WorkOrderLineItem WHERE WorkOrderId =: wo.Id];
        System.assert(woliList != null);
        Test.StopTest();
    }    
    
    @IsTest static void testMethod2(){
        Test.startTest();
        Account acc = [SELECT Id FROM Account WHERE Name = 'test account' LIMIT 1];
        ServiceContract sc = [SELECT Id,Visit_Order__c FROM ServiceContract WHERE Service_Type__c = 'Advance Exchange (Depot Only)' LIMIT 1];
        Case cs = [SELECT Id FROM Case WHERE AccountId =: acc.Id AND Service_Type__c = 'Advance Exchange (Depot Only)' LIMIT 1];
        WorkOrder wo = [SELECT Id From WorkOrder WHERE ServiceContractId =:sc.Id limit 1];
        
        wo.Check_In_Time__c = System.now().addDays(2);
        wo.Check_Out_Time__c = System.now().addDays(3);
        wo.Status = 'Technician Scheduled / Assigned';
        wo.Technician_Status__c = 'Checked in';
        wo.Outbound_Tracking_Number_Status__c = 'test';
        wo.FN_Status__c = 'Published';
        wo.status = 'Acknowledged';
        wo.Latitude = 11;
        wo.Longitude = 22;
        wo.Check_In_Lat_Lon__latitude__s = 33;
        wo.Check_In_Lat_Lon__longitude__s = 44;
        wo.Check_Out_Lat_Lon__latitude__s = 55;
        wo.Check_Out_Lat_Lon__longitude__s = 66;
        update wo;
        
        wo.Check_Out_Time__c = System.now().addDays(4);
        wo.Resolution_Code__c = 'RESOLVED';
        wo.Technician_Status__c = 'Checked Out';
        wo.StartDate = System.now();
        wo.Preferred_Time_IMAC__c = System.now();
        update wo;
        
        WorkOrder woCheck = [SELECT Id,Technician_Status__c,Outbound_Tracking_Number_Status__c, Tracking_Numbers__c, Onsite_Manager_Name__c, Technican_Phone__c From WorkOrder WHERE Id =: wo.Id];
        cs = [SELECT Id,Status,Onsite_Manager_Name__c, Technician_Phone__c, Tracking_Numbers__c FROM Case WHERE Id =: cs.Id];
        System.assert(woCheck.Outbound_Tracking_Number_Status__c == 'TEST');
        System.assert(woCheck.Technician_Status__c == 'Checked Out');
        System.Assert(woCheck.Tracking_Numbers__c == cs.Tracking_Numbers__c);
        System.Assert(woCheck.Onsite_Manager_Name__c == cs.Onsite_Manager_Name__c);
        //System.Assert(woCheck.Technican_Phone__c == cs.Technician_Phone__c);
        
        Test.stopTest();
    }
    
    @IsTest static void testMehtod3(){
        Test.startTest();
        Project_Account__c prjAcc = [SELECT Id FROM Project_Account__c LIMIT 1];
        Project__c pro = [SELECT Id FROM Project__c LIMIT 1];
        Account acc = [SELECT Id,Root_Account__c FROM Account WHERE Name = 'test account' LIMIT 1];
        ServiceContract sc = [SELECT Id,Visit_Order__c FROM ServiceContract WHERE Name = 'test ServiceContract' LIMIT 1];
        Case cs = [SELECT Id FROM Case WHERE AccountId =: acc.Id AND Service_Type__c = 'Advance Exchange (Depot Only)' LIMIT 1];
        WorkOrder wo = TestDataFactory.createWorkOrder(cs, sc,acc);
        wo.Technician_Status__c = 'ETA Set';
        wo.Root_Account__c = acc.Root_Account__c;
        wo.Check_In_Time__c = System.now().addDays(2);
        wo.Project__c = pro.Id;
        wo.Project_Account__c = prjAcc.Id;
        insert wo;
        Event e = TestDataFactory.createEvent(wo);
        insert e;
        
        wo.Time_Entries__c = '2023-04-24 11:00:00 - Not Provided (00:00)';
        wo.Check_Out_Time__c = System.now().addDays(3);
        wo.Technician_Status__c = 'Approved';
        wo.Outbound_Tracking_Number_Status__c = 'test';
        wo.FN_Status__c = 'Assigned';
        wo.status = 'Acknowledged';
        wo.StartDate = System.now();
        wo.Preferred_Time_IMAC__c = System.now();
        update wo;
        
        WorkOrder woCheck = [SELECT Id,Status,Approval_Requested_Date__c, Onsite_Manager_Name__c, Technican_Phone__c, Technician_Status__c,Outbound_Tracking_Number_Status__c, Tracking_Numbers__c From WorkOrder WHERE Id =: wo.Id];
        cs = [SELECT Id,Status,Onsite_Manager_Name__c, Technician_Phone__c, Tracking_Numbers__c FROM Case WHERE Id =: cs.Id];
        System.assert(woCheck.Outbound_Tracking_Number_Status__c == 'TEST');
        //System.assert(wo.Approval_Requested_Date__c == System.now().date());
        System.Assert(woCheck.Tracking_Numbers__c == cs.Tracking_Numbers__c);
        System.Assert(woCheck.Onsite_Manager_Name__c == cs.Onsite_Manager_Name__c);
        //System.Assert(woCheck.Technican_Phone__c == cs.Technician_Phone__c);
        
        Test.stopTest();
    }
    
    @IsTest static void testMehtod4(){
        Test.startTest();
        Project_Account__c prjAcc = [SELECT Id FROM Project_Account__c LIMIT 1];
        Project__c pro = [SELECT Id FROM Project__c LIMIT 1];
        Account acc = [SELECT Id,Root_Account__c FROM Account WHERE Name = 'test account' LIMIT 1];
        ServiceContract sc = [SELECT Id,Visit_Order__c FROM ServiceContract WHERE Name = 'test ServiceContract' LIMIT 1];
        Case cs = [SELECT Id FROM Case WHERE AccountId =: acc.Id AND Service_Type__c = 'Advance Exchange + Onsite' LIMIT 1];
        Id bndlRT = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Bundle_Work_Order').getRecordTypeId();
        List<WorkOrder> woList = new List<WorkOrder>();
        WorkOrder wo = TestDataFactory.createWorkOrder(cs, sc,acc);
        wo.Root_Account__c = acc.Root_Account__c;
        wo.Service_Type__c = 'Advance Exchange + Onsite';
        wo.CaseId = cs.Id;
        wo.Project__c = pro.Id;
        wo.Project_Account__c = prjAcc.Id;
        woList.add(wo);
        
        WorkOrder wo1 = TestDataFactory.createWorkOrder(cs, sc,acc);
        wo1.ParentWorkOrderId = wo.Id;
        wo1.Root_Account__c = acc.Root_Account__c;
        wo1.CaseId = cs.Id;
        wo1.FN_Status__c = 'Draft';
        wo1.Service_Type__c = 'Advance Exchange + Onsite';
        wo1.Closing_Process__c = true;
        wo1.Project__c = pro.Id;
        wo.Project_Account__c = prjAcc.Id;
        woList.add(wo1);
        
        WorkOrder wo2 = TestDataFactory.createWorkOrder(cs, sc, acc);
        wo2.RecordTypeId = bndlRT;
        wo2.Root_Account__c = acc.Root_Account__c;
        wo2.Preferred_Time_IMAC__c = null;
        wo1.Project__c = pro.Id;
        wo.Project_Account__c = prjAcc.Id;
        woList.add(wo2);
        insert woList;
        
        list<WorkOrder> woCheckList = BundleWorkorders.totAccWorkOrders(acc.Id, 'sjdhflaksdjh');
        list<WorkOrder> woCheckList2 = BundleWorkorders.bndlWOs('ajshdljslkdj', woList[2].Id);
        WorkOrder woCheck = BundleWorkorders.bndlWordOrdr(woList[2].Id);
        String saveStatus = BundleWorkorders.saveToBndl(woList);
        
        System.assert(woCheckList != null);
        System.assert(woCheckList2 != null);
        System.assert(woCheck != null);
        System.assert(String.isNotBlank(saveStatus));
        System.assert(saveStatus == 'success');
        
        woList[1].Technician_Status__c = 'Confirmed';
        update woList[1];
        delete woList[0];
        
        //wo = [SELECT Id,Status, Check_In_Distance__c,Technician_Status__c,Outbound_Tracking_Number_Status__c From WorkOrder WHERE Id =: woList[1].Id];
        //System.assert(wo.Technician_Status__c == 'Confirmed');
        //System.assert(wo.Status == 'Technician Scheduled / Assigned');
        
        Test.stopTest();
    }
    
    @IsTest static void testMehtodAdjustDates(){
        Test.startTest();
        Project_Account__c prjAcc = [SELECT Id FROM Project_Account__c LIMIT 1];
        Project__c pro = [SELECT Id FROM Project__c LIMIT 1];
        Account acc = [SELECT Id,Root_Account__c FROM Account WHERE Name = 'test account' LIMIT 1];
        ServiceContract sc = [SELECT Id,Visit_Order__c FROM ServiceContract WHERE Name = 'test ServiceContract' LIMIT 1];
        Case cs = [SELECT Id FROM Case WHERE AccountId =: acc.Id AND Service_Type__c = 'Advance Exchange + Onsite' LIMIT 1];
        
        Id partShipRT = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Part_Shipment').getRecordTypeId();
        WorkOrder wo1 = TestDataFactory.createWorkOrder(cs,sc,acc);
        wo1.CaseId = cs.Id;
        wo1.FN_Status__c = 'Draft';
        wo1.Service_Type__c = 'Advance Exchange + Onsite';
        wo1.recordTypeId = System.Label.Onsite_Labor_WO_RT_Id;
        wo1.Check_In_Time__c = null;
        wo1.Check_Out_Time__c = null;
        wo1.Time_Entries__c = null;
        wo1.SLA_Exception_Code__c = 'OPENED FOR WRONG EQUIPMENT';
        wo1.Project__c = pro.Id;
        wo1.Project_Account__c = prjAcc.Id;
        //insert wo1;
        
        WorkOrder wo2 = TestDataFactory.createWorkOrder(cs,sc,acc);
        wo2.Check_In_Time__c = System.now().addDays(2);
        wo2.Root_Account__c = acc.Root_Account__c;
        wo2.Check_Out_Time__c = null;
        insert wo2;
        wo2.Check_In_Time__c = System.now().addDays(3); 
        wo2.Check_Out_Time__c = System.now();
        wo2.Technician_Status__c = 'Cancelled';
        wo2.OutofScope__c = true;
        wo2.Out_of_Scope_Reason__c = '	Missing Equipment';
        update wo2;
        
        wo2 = [SELECT Id,Status, Check_In_Distance__c,Technician_Status__c,Outbound_Tracking_Number_Status__c From WorkOrder WHERE Id =: wo2.Id];
        System.assert(wo2.Technician_Status__c == 'Cancelled');
        //System.assert(wo2.Status == 'Technician Scheduled / Assigned');
        
        wo2.Check_In_Time__c = System.now().addDays(4); 
        wo2.Check_Out_Time__c = null;
        wo2.Technician_Status__c = 'Delayed';
        update wo2;
        
        //wo2 = [SELECT Id,Status, Check_In_Distance__c,Technician_Status__c,Outbound_Tracking_Number_Status__c From WorkOrder WHERE Id =: wo2.Id];
        //System.assert(wo2.Technician_Status__c == 'Technician Delayed');
        //System.assert(wo2.Status == 'Technician Scheduled / Assigned');
        
        Test.stopTest();
    }
    
    @IsTest static void testcancelChildWOandCase(){
        Test.startTest();
        Project__c pro = [SELECT Id FROM Project__c LIMIT 1];
        Project_Account__c prjAcc = [SELECT Id FROM Project_Account__c LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name = 'test account2' LIMIT 1];
        Case cs = [SELECT Id FROM Case WHERE AccountId =: acc.Id AND Service_Type__c = 'Part Return' LIMIT 1];
        ServiceContract sc = [SELECT Id,Visit_Order__c FROM ServiceContract WHERE AccountId =: acc.Id AND Service_Type__c = 'Part Return' LIMIT 1];
        Map<Id,Product2> pbMap = new Map<Id,Product2>([SELECT Id FROM Product2 WHERE Account_Item_Belongs_To__c =: acc.Id]);
        list<PricebookEntry> pbeList = [SELECT Id,Out_of_Scope_Price__c FROM PricebookEntry WHERE Product2Id IN:pbMap.keySet()];
        List<Product2> prodList = pbMap.values();
        
        WorkOrder wo = TestDataFactory.createWorkOrder(cs, sc,acc);
        wo.CaseId = cs.Id;
        wo.Product__c = prodList[0].Id;
        wo.Priority = 'Severity 1';
        wo.status = 'Onsite Work Completed';
        wo.Service_Type__c = 'Part Return';
        wo.ServiceContractId = sc.Id;
        wo.Preferred_Time_IMAC__c = null;
        wo.Equipment_Rental_Cost__c =  1000;
        wo.Material_Cost__c =  1000;
        wo.Logistics_Cost__c =  1000;
        wo.Labor_Cost__c =  1000;
        wo.Total_Labor_Hours__c = 30;
        wo.SLA_Exception_Code__c = 'OPENED FOR WRONG EQUIPMENT';
        wo.StartDate = System.today();
        wo.Resolution_Notes__c = 'Test2';
        wo.Resolution_Code__c = 'RESOLVED';
        wo.Technician_OnSite_ETA__c = System.now().AddDays(2);
        wo.Tracking_Numbers__c = '111222';
        wo.Technician_Name__c = 'TestName2';
        wo.Technican_Phone__c = '111222333';
        wo.Subject = 'Test2';
        wo.Technician_OnSite_ETA_String__c = null;
        wo.Return_Authorization__c = 'Test2';
        wo.Onsite_Manager_Name__c = 'TestManager2';
        wo.Netsuite_Integration_Error__c = 'test2';
        wo.NetSuite_Error__c = false;
        wo.Project__c = pro.Id;
        wo.Project_Account__c = prjAcc.Id;
        insert wo;
        
        wo.Equipment_Rental_Cost__c =  10;
        wo.Material_Cost__c =  10;
        wo.Logistics_Cost__c =  10;
        wo.Labor_Cost__c =  10;
        wo.Technician_Status__c = 'Checked in';
        wo.OutofScope__c = true;
        wo.Out_of_Scope_Reason__c = 'Missing Equipment';
        wo.Resolution_Code__c = 'RESOLVED';
        wo.StartDate = System.now();
        wo.Preferred_Time_IMAC__c = System.now();
        update wo;
        
        WorkOrder woCheck = [SELECT Id, Technician_Status__c, Tracking_Numbers__c, Onsite_Manager_Name__c, Technican_Phone__c From WorkOrder WHERE Id =: wo.Id];
        cs = [SELECT Id,Status,Onsite_Manager_Name__c, Technician_Phone__c, Tracking_Numbers__c FROM Case WHERE Id =: cs.Id];
        System.Assert(woCheck.Technician_Status__c == 'Checked in');
        System.Assert(woCheck.Tracking_Numbers__c == cs.Tracking_Numbers__c);
        System.Assert(woCheck.Onsite_Manager_Name__c == cs.Onsite_Manager_Name__c);
        //System.Assert(woCheck.Technican_Phone__c == cs.Technician_Phone__c);
        //WorkOrderLineItem woli = [SELECT Id,UnitPrice FROM WorkOrderLineItem WHERE WorkOrderId =: wo.Id AND Created_For_Field__c = 'Equipment_Rental_Cost__c' LIMIT 1];
        //System.Assert(woli.Id != null && woli.UnitPrice == 10);
        
        Test.stopTest();
    }
    
    @IsTest static void testMthod5(){
        Test.startTest();
        Project_Account__c prjAcc = [SELECT Id FROM Project_Account__c LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name = 'test account' LIMIT 1];
        ServiceContract sc = [SELECT Id,Visit_Order__c FROM ServiceContract WHERE Service_Type__c = 'Advance Exchange + Onsite' LIMIT 1];
        Case cs = [SELECT Id FROM Case WHERE AccountId =: acc.Id AND Service_Type__c ='Advance Exchange + Onsite' LIMIT 1];
        Id pricebookId = Test.getStandardPricebookId();
        WorkOrder wo = new WorkOrder();
        wo.ParentWorkOrderId = null;
        wo.CaseId = cs.Id;
        wo.status = 'New';
        wo.Service_Type__c = 'Advance Exchange + Onsite';
        wo.ServiceContractId = sc.id;
        wo.Pricebook2Id = pricebookId;
        wo.Project_Account__c = prjAcc.Id;
        insert wo;
        
        WorkOrder wo2 = new WorkOrder();
        wo2.ParentWorkOrderId = wo.Id;
        wo2.CaseId = cs.Id;
        wo2.status = 'New';
        wo2.Service_Type__c = 'Advance Exchange + Onsite';
        wo2.ServiceContractId = sc.id;
        wo2.Pricebook2Id = pricebookId;
        insert wo2;
        
        wo.Status = 'Canceled';
        update wo;
        wo = [SELECT Id, Status, Resolution_Code__c, Resolution_Notes__c From WorkOrder WHERE Id =: wo.Id];
        System.Assert(wo.Status == 'Canceled');
        System.Assert(wo2.Resolution_Code__c == wo.Resolution_Code__c);
        System.Assert(wo2.Resolution_Notes__c == wo.Resolution_Notes__c);
        
        Test.stopTest();
    }
    
    @IsTest static void testMthod6(){
        Test.startTest();
        Project__c pro = [SELECT Id FROM Project__c LIMIT 1];
        Project_Account__c prjAcc = [SELECT Id FROM Project_Account__c LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name = 'test account' LIMIT 1];
        ServiceContract sc = [SELECT Id,Visit_Order__c FROM ServiceContract WHERE Service_Type__c = 'Advance Exchange + Onsite' LIMIT 1];
        Case cs = [SELECT Id FROM Case WHERE AccountId =: acc.Id AND Service_Type__c ='Advance Exchange + Onsite' LIMIT 1];
        Id pricebookId = Test.getStandardPricebookId();
        WorkOrder wo = new WorkOrder();
        wo.ParentWorkOrderId = null;
        wo.CaseId = cs.Id;
        wo.status = 'Acknowledged';
        wo.Service_Type__c = 'Advance Exchange + Onsite';
        wo.ServiceContractId = sc.id;
        wo.Pricebook2Id = pricebookId;
        wo.Outbound_Tracking_Number_Status__c = 'test';
        wo.Project__c = pro.Id;
        wo.Project_Account__c = prjAcc.Id;
        insert wo;
        
        wo = [SELECT Id, Outbound_Tracking_Number_Status__c, Onsite_Manager_Name__c, Technican_Phone__c, Tracking_Numbers__c From WorkOrder WHERE Id =: wo.Id];
        cs = [SELECT Id,Status,Onsite_Manager_Name__c, Technician_Phone__c, Tracking_Numbers__c FROM Case WHERE Id =: cs.Id];
        System.Assert(wo.Outbound_Tracking_Number_Status__c == 'TEST');
        System.Assert(wo.Onsite_Manager_Name__c == cs.Onsite_Manager_Name__c);
        System.Assert(wo.Technican_Phone__c == cs.Technician_Phone__c);
        System.Assert(wo.Tracking_Numbers__c == cs.Tracking_Numbers__c);
        
        WorkOrder wo2 = new WorkOrder();
        wo2.ParentWorkOrderId = wo.Id;
        wo2.CaseId = cs.Id;
        wo2.Status = 'New';
        wo2.Service_Type__c = 'Advance Exchange + Onsite';
        wo2.ServiceContractId = sc.id;
        wo2.Pricebook2Id = pricebookId;
        wo2.Technician_Status__c = 'Checked in';
        wo2.Outbound_Tracking_Number_Status__c = 'test';
        insert wo2;
        
        wo2 = [SELECT Id, Outbound_Tracking_Number_Status__c, Onsite_Manager_Name__c, Technican_Phone__c, Tracking_Numbers__c From WorkOrder WHERE Id =: wo2.Id];
        cs = [SELECT Id,Status,Onsite_Manager_Name__c, Technician_Phone__c, Tracking_Numbers__c FROM Case WHERE Id =: cs.Id];
        System.Assert(wo2.Outbound_Tracking_Number_Status__c == 'TEST');
        System.Assert(wo2.Onsite_Manager_Name__c == cs.Onsite_Manager_Name__c);
        System.Assert(wo2.Technican_Phone__c == cs.Technician_Phone__c);
        System.Assert(wo2.Tracking_Numbers__c == cs.Tracking_Numbers__c);
        Test.stopTest();
    }
    
    @IsTest static void testMthod7(){
        Test.startTest();
        Account acc = [SELECT Id FROM Account WHERE Name = 'test account' LIMIT 1];
        ServiceContract sc = [SELECT Id FROM ServiceContract WHERE Service_Type__c = 'Advance Exchange (Depot Only)' LIMIT 1];
        Case cs = [SELECT Id FROM Case WHERE AccountId =: acc.Id AND Service_Type__c ='Advance Exchange (Depot Only)' LIMIT 1];
        WorkOrder parentWO = [SELECT Id,Check_In_Time__c,Check_Out_Time__c,Time_Entries__c FROM WorkOrder WHERE PO__c = 'Parent WO' LIMIT 1];
        Map<Id,Product2> pbMap = new Map<Id,Product2>([SELECT Id FROM Product2 WHERE Family = 'Hardware' AND Account_Item_Belongs_To__c =: acc.Id]);
        list<PricebookEntry> pbeList = [SELECT Id FROM PricebookEntry WHERE Product2Id IN:pbMap.keySet()];
        
        parentWO.Check_Out_Lat_Lon__latitude__s = 12;
        parentWO.Check_Out_Lat_Lon__longitude__s = 13;
        parentWO.Check_In_Lat_Lon__latitude__s = 14;
        parentWO.Check_In_Lat_Lon__longitude__s = 15;
        parentWO.Latitude = 16;
        parentWO.Longitude = 17;
        parentWO.Tracking_Numbers__c = '12121212';
        parentWO.Technician_Name__c = 'Mr.Testing';
        parentWO.Technican_Phone__c = '12121';
        parentWO.Onsite_Manager_Name__c = 'Mr.Testing';
        parentWO.Technician_Status__c = 'Approved';
        parentWO.Resolution_Code__c = 'RESOLVED';
        update parentWO;
        
        WorkOrder parentWOCheck = [SELECT Id, Check_In_Distance__c, latitude, longitude, Check_In_Lat_Lon__latitude__s,
                    Check_In_Lat_Lon__longitude__s, Onsite_Manager_Name__c, Technican_Phone__c, Tracking_Numbers__c
                    From WorkOrder WHERE Id =: parentWO.Id];
        
        cs = [SELECT Id,Status,Onsite_Manager_Name__c, Technician_Phone__c, Tracking_Numbers__c FROM Case WHERE Id =: cs.Id];
        //System.Assert(parentWO.Onsite_Manager_Name__c == cs.Onsite_Manager_Name__c);
        //System.Assert(parentWOCheck.Technican_Phone__c == cs.Technician_Phone__c);
        //System.Assert(parentWO.Tracking_Numbers__c == cs.Tracking_Numbers__c);
        
        Id pricebookId = Test.getStandardPricebookId();
        WorkOrder wo = new WorkOrder();
        wo.ParentWorkOrderId = parentWO.Id;
        wo.NetSuite_Error__c = True;
        wo.Pricebook2Id = pricebookId;
        insert wo;
        
        Product_Markup__c pm = new Product_Markup__c();
        pm.Product__c = pbMap.values()[0].Id;
        pm.Markup__c = 10;
        pm.State__c = 'AK';
        pm.Country__c = 'United States';
        insert pm;
        
        List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
        WorkOrderLineItem woli = new WorkOrderLineItem();
        woli.PricebookEntryId = pbeList[0].Id;
        woli.Description = 'Test';
        woli.Child_WOLI__c = null;
        woli.WorkOrderId = wo.Id;
        woli.quantity = 1;
        woli.unitprice = 10;
        woli.Inspection_Outcome__c = 'Complete - Skimming Device Found';
        insert woli;
        woli.unitprice = 20;
        update woli;
        
        Test.stopTest();
    }
    
    @IsTest static void testMthod8(){
        Test.startTest();
        Account acc = [SELECT Id FROM Account WHERE Name = 'test account' LIMIT 1];
        ServiceContract sc = [SELECT Id FROM ServiceContract WHERE Service_Type__c = 'Advance Exchange (Depot Only)' LIMIT 1];
        Case cs = [SELECT Id FROM Case WHERE AccountId =: acc.Id AND Service_Type__c ='Advance Exchange (Depot Only)' LIMIT 1];
        WorkOrder parentWO = [SELECT Id,Check_In_Time__c,Check_Out_Time__c,Time_Entries__c FROM WorkOrder WHERE PO__c = 'Parent WO' LIMIT 1];
        
        parentWO.Technician_Status__c = 'Work Done';
        update parentWO;
        
        parentWO = [SELECT Id, Status From WorkOrder WHERE Id =: parentWO.Id];
        System.Assert(parentWO.Status == 'Onsite Work Completed');
        
        parentWO.Technician_Status__c = 'Start Time Set';
        update parentWO;
        
        WorkOrder parentWOCheck = [SELECT Id, Status, Onsite_Manager_Name__c, Technican_Phone__c, Tracking_Numbers__c
                    From WorkOrder WHERE Id =: parentWO.Id];
        cs = [SELECT Id,Status,Onsite_Manager_Name__c, Technician_Phone__c, Tracking_Numbers__c FROM Case WHERE Id =: cs.Id];
        System.Assert(parentWOCheck.Onsite_Manager_Name__c == cs.Onsite_Manager_Name__c);
        //System.Assert(parentWOCheck.Technican_Phone__c == cs.Technician_Phone__c);
        System.Assert(parentWOCheck.Tracking_Numbers__c == cs.Tracking_Numbers__c);
        //System.Assert(parentWOCheck.Status == 'Technician Scheduled / Assigned');
        Test.stopTest();
    }
    
    @IsTest static void testMthod9(){
        Test.startTest();
        Account acc = [SELECT Id FROM Account WHERE Name = 'test account' LIMIT 1];
        ServiceContract sc = [SELECT Id FROM ServiceContract WHERE Service_Type__c = 'Advance Exchange (Depot Only)' LIMIT 1];
        Case cs = [SELECT Id FROM Case WHERE AccountId =: acc.Id AND Service_Type__c ='Advance Exchange (Depot Only)' LIMIT 1];
        WorkOrder parentWO = [SELECT Id,Check_In_Time__c,Check_Out_Time__c,Time_Entries__c FROM WorkOrder WHERE PO__c = 'Parent WO' LIMIT 1];
        
        parentWO.Technician_Status__c = 'Approved';
        parentWO.OwnerId = '00G6g0000034waO';
        update parentWO;
        
        parentWO = [SELECT Id, Status, Onsite_Manager_Name__c, Technican_Phone__c, Tracking_Numbers__c
                    From WorkOrder WHERE Id =: parentWO.Id];
        cs = [SELECT Id,Status,Onsite_Manager_Name__c, Technician_Phone__c, Tracking_Numbers__c FROM Case WHERE Id =: cs.Id];
        System.Assert(parentWO.Onsite_Manager_Name__c == cs.Onsite_Manager_Name__c);
        //System.Assert(parentWO.Technican_Phone__c == cs.Technician_Phone__c);
        System.Assert(parentWO.Tracking_Numbers__c == cs.Tracking_Numbers__c);
        Test.stopTest();
    }
    
    @IsTest static void woToParentWO(){
        Test.startTest();
        Account acc = [SELECT Id FROM Account WHERE Name = 'test account' LIMIT 1];
        ServiceContract sc = [SELECT Id FROM ServiceContract WHERE Name = 'test ServiceContract' LIMIT 1];
        Case cs = [SELECT Id FROM Case WHERE AccountId =: acc.Id AND Service_Type__c ='Advance Exchange (Depot Only)' LIMIT 1];
        WorkOrder parentWO = [SELECT Id,Check_In_Time__c,Check_Out_Time__c,Time_Entries__c FROM WorkOrder WHERE PO__c = 'Parent WO' LIMIT 1];
        Id partShipRT = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Part_Shipment').getRecordTypeId();
        Id pricebookId = Test.getStandardPricebookId();
        
        WorkOrder woChild = new WorkOrder();
        woChild.AccountId = acc.Id;
        woChild.CaseId = cs.Id;
        woChild.ServiceContractId = sc.Id;
        woChild.RecordTypeId = partShipRT;
        woChild.Pricebook2Id = pricebookId;
        woChild.No_Cost__c = true;
        woChild.Priority = 'Severity 1';
        woChild.status = 'New';
        woChild.FN_Status__c = 'Work Done';
        woChild.Technician_Status__c = 'Scheduling';
        woChild.Service_Type__c = 'Advance Exchange (Depot Only)';
        woChild.Check_In_Time__c = System.now().addDays(1);
        woChild.Check_Out_Time__c = System.now().addDays(2);
        woChild.Time_Entries__c = '2023-04-26 11:00:00 - Not Provided (00:00)';
        woChild.SLA_Due_DateTime__c = System.now().AddDays(5);
        woChild.Technician_OnSite_ETA_String__c = '2023-01-31T06:00:00+00:00';
        woChild.Technician_Name__c = 'Mr.Test';
        woChild.Technican_Phone__c = '12121212';
        woChild.Onsite_Manager_Name__c = 'Mr.Test';
        woChild.Resolution_Code__c = 'RESOLVED';
        woChild.Resolution_Notes__c = 'Test';
        woChild.Technician_OnSite_ETA__c = System.now().AddDays(1);
        woChild.SLA_Exception_Code__c = 'CUSTOMER SOFTWARE ISSUE';
        woChild.Tracking_Numbers__c = '1212';
        woChild.Site_Location_Status__c = 'Site Complete';
        insert woChild;
        
        woChild.Technician_Status__c = 'On my way';
        woChild.ParentWorkOrderId = parentWO.Id;
        update woChild;
        
        woChild = [SELECT Id, Technician_Status__c From WorkOrder WHERE Id =: woChild.Id];
        System.Assert(woChild.Technician_Status__c == 'In Route');
        delete parentWO;
        Test.stopTest();
    }
    
    @IsTest static void closingProcess(){
        Test.startTest();
        Account acc = [SELECT Id FROM Account WHERE Name = 'test account' LIMIT 1];
        ServiceContract sc = [SELECT Id FROM ServiceContract WHERE Service_Type__c = 'Advance Exchange (Depot Only)' LIMIT 1];
        List<Case> csList = new List<Case>();
        Case cs = TestDataFactory.createCase(acc, sc);
        csList.add(cs);
        Case cs2 = TestDataFactory.createCase(acc, sc);
        csList.add(cs2);
        Case cs3 = TestDataFactory.createCase(acc, sc);
        csList.add(cs3); 
        insert csList;
        List<WorkOrder> woList = new List<WorkOrder>();
        WorkOrder wo = TestDataFactory.createWorkOrder(cs, sc, acc);
        woList.add(wo);
        WorkOrder wo2 = TestDataFactory.createWorkOrder(cs2, sc, acc);
        woList.add(wo2);
        WorkOrder wo3 = TestDataFactory.createWorkOrder(cs3, sc, acc);
        woList.add(wo3);
        insert woList;
        
        List<WorkOrder> toUpdateList = new List<WorkOrder>();
        wo.Resolution_Code__c = 'RESOLVED';
        wo.Status = 'Onsite Work Completed';
        wo.Closing_Process__c = true;
        toUpdateList.add(wo);
        wo2.Status = 'Closed';
        wo2.Closing_Process__c = true;
        toUpdateList.add(wo2);
        update toUpdateList;
        
        List<WorkOrder> toUpdateList1 = new List<WorkOrder>();
        wo.Resolution_Code__c = 'RESOLVED';
        wo.Status = 'Onsite Work Completed';
        wo.Closing_Process__c = true;
        toUpdateList.add(wo);
        wo3.Status = 'Closed';
        wo3.Closing_Process__c = false;
        toUpdateList1.add(wo2);
        update toUpdateList1;
        
        Case csCheck = [SELECT Id,Status FROM Case WHERE Id =: cs.Id];
        System.assert(csCheck.Status == 'Closed');
        Case csCheck2 = [SELECT Id,Status FROM Case WHERE Id =: cs2.Id];
        System.assert(csCheck2.Status == 'Closed');
        Test.stopTest();
    }
    
    @IsTest static void coverColorado(){
        Account acc = [SELECT Id FROM Account WHERE Name = 'test account' LIMIT 1];
        Map<Id,Product2> pbMap = new Map<Id,Product2>([SELECT Id FROM Product2 WHERE Account_Item_Belongs_To__c =: acc.Id AND Name = 'CO RDF']);
        list<PricebookEntry> pbeList = [SELECT Id FROM PricebookEntry WHERE Product2Id IN:pbMap.keySet()];
        ServiceContract sc = [SELECT Id,Single_WO_For_Billing__c FROM ServiceContract WHERE Service_Type__c = 'Advance Exchange (Depot Only)' AND AccountId =: acc.Id LIMIT 1];
        
        sc.Single_WO_For_Billing__c = true;
        update sc;
        Account coloradoAcc = TestDataFactory.createAccount();
        coloradoAcc.Name = 'test account1';
        coloradoAcc.Source_Key__c = '125';
        coloradoAcc.ShippingState = 'CO';
        insert coloradoAcc;
        Case cs = TestDataFactory.createCase(coloradoAcc, sc);
        insert cs;
        WorkOrder wo = TestDataFactory.createWorkOrder(cs, sc, coloradoAcc);
        insert wo;
        
        Test.startTest();
        WorkOrder wo2 = TestDataFactory.createWorkOrder(cs, sc, coloradoAcc);
        wo2.ParentWorkOrderId = wo.Id;
        insert wo2;
        Test.stopTest();
    }
    
    @IsTest static void partWithOnsiteCover(){
        Account acc = [SELECT Id FROM Account WHERE Name = 'CUB 001' LIMIT 1];
        ServiceContract sc = TestDataFactory.createServiceContract(acc);
        insert sc;
        Case cs = TestDataFactory.createCase(acc, sc);
        cs.Expected_SLA_Exit_Date__c = System.now().addHours(1);
        insert cs;
        
        Test.startTest();
        List<WorkOrder> woList = new List<WorkOrder>();
        WorkOrder wo = TestDataFactory.createWorkOrder(cs, sc, acc);
        wo.RecordTypeId = System.Label.Onsite_Labor_WO_RT_Id;
        woList.add(wo);
        
        WorkOrder wo2 = TestDataFactory.createWorkOrder(cs, sc, acc);
        wo2.ParentWorkOrderId = wo.Id;
        wo2.Check_In_Time__c = System.now();
        wo2.Check_Out_Time__c = System.now().AddHours(1);
        woList.add(wo2);
        insert woList;
        
        wo2.Description = 'Test';
        wo2.NetSuite_Error__c = true;
        wo2.Check_Out_Time__c = System.now().AddHours(2);
        wo2.Technician_Status__c = 'Draft';
        update wo;
        Test.stopTest();
    }
    
    @IsTest static void onlypartWOCover(){
        Account acc = [SELECT Id FROM Account WHERE Name = 'PBS 01' LIMIT 1];
        ServiceContract sc = TestDataFactory.createServiceContract(acc);
        insert sc;
        Case cs = TestDataFactory.createCase(acc, sc);
        cs.Expected_SLA_Exit_Date__c = System.now().addHours(1);
        cs.SLA_Violated__c = true;
        insert cs;
        List<User> usrList = [SELECT Id, Name, Profile.Name FROM User WHERE IsActive = true AND profile.Name = 'Field Tech' LIMIT 1];
        
        Test.startTest();
        Id pricebookId = Test.getStandardPricebookId();
        WorkOrder wo = TestDataFactory.createWorkOrder(cs, sc, acc);
        wo.OwnerId = usrList[0].Id;
        wo.RecordTypeId = System.Label.Part_Request_WO_RT_Id;
        wo.SLA_Exception_Code__c = 'CUSTOMER SOFTWARE ISSUE';
        wo.SLA_Due_DateTime__c = null;
        wo.Pricebook2Id = pricebookId;
        insert wo;
        
        WorkOrder wo2 = TestDataFactory.createWorkOrder(cs, sc, acc);
        wo2.ParentWorkOrderId = wo.Id;
        wo2.OwnerId = usrList[0].Id;
        wo2.RecordTypeId = System.Label.Part_Request_WO_RT_Id;
        wo2.SLA_Exception_Code__c = 'CUSTOMER SOFTWARE ISSUE';
        wo2.SLA_Due_DateTime__c = null;
        wo2.Pricebook2Id = pricebookId;
        wo2.Total_Labor_Hours__c = 1;
        insert wo2;
        
        wo2.Check_In_Time__c = System.now();
        wo2.Technician_Status__c = 'Approved';
        wo2.Approved__c = false;
        wo2.SLA_Due_DateTime__c = null;
        wo2.Preferred_Time_IMAC__c = null;
        wo2.Equipment_Rental_Cost__c = 10;
        wo2.Total_Labor_Hours__c = 4;
        update wo;
        
        Case csCheck = [SELECT Id,Technician_Onsite_Start_Time__c FROM Case WHERE Id =: cs.Id];
        Test.stopTest();
        
        //System.assert(csCheck.Technician_Onsite_Start_Time__c != null);
        //System.assert(csCheck.Technician_Onsite_Start_Time__c.date() == wo2.Check_In_Time__c.date());
    }
    
    @IsTest static void onlyOnsiteWOCover(){
        Account acc = [SELECT Id FROM Account WHERE Name = 'PBS 01' LIMIT 1];
        ServiceContract sc = TestDataFactory.createServiceContract(acc);
        insert sc;
        Case cs = TestDataFactory.createCase(acc, sc);
        cs.Expected_SLA_Exit_Date__c = System.now().addHours(1);
        cs.SLA_Violated__c = true;
        insert cs;
        List<User> usrList = [SELECT Id, Name, Profile.Name FROM User WHERE IsActive = true AND profile.Name = 'Field Tech' LIMIT 1];
        Id onsiteRtId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Onsite_Labor').getRecordTypeId();
        
        Test.startTest();
        Id pricebookId = Test.getStandardPricebookId(); 
        WorkOrder wo = new WorkOrder();
        wo.CaseId  = cs.Id;
        wo.ServiceContractId = sc.Id;
        wo.AccountId = acc.Id;
        wo.OwnerId = usrList[0].Id;
        wo.RecordTypeId = onsiteRtId;
        wo.SLA_Exception_Code__c = 'CUSTOMER SOFTWARE ISSUE';
        wo.SLA_Due_DateTime__c = null;
        wo.Pricebook2Id = pricebookId;
        wo.Check_In_Time__c = DateTime.newInstance(2024,02,23,8,10,0);
        wo.Record_Type_Name__c = 'Onsite Labor';
        insert wo;

        WorkOrder wo1 = new WorkOrder();
        wo1.CaseId  = cs.Id;
        wo1.ServiceContractId = sc.Id;
        wo1.AccountId = acc.Id;
        wo1.OwnerId = usrList[0].Id;
        wo1.RecordTypeId = onsiteRtId;
        wo1.SLA_Exception_Code__c = 'CUSTOMER SOFTWARE ISSUE';
        wo1.Missed_SLA_Reason__c = 'DELIVERY DELAY - IW';
        wo1.Resolution_Code__c = 'RESOLVED';
        wo1.Resolution_Notes__c = 'Test';
        wo1.SLA_Due_DateTime__c = null;
        wo1.Pricebook2Id = pricebookId;
        wo1.Check_In_Time__c = DateTime.newInstance(2024,02,23,8,10,0);
        wo1.Record_Type_Name__c = 'Part Ordering';
        insert wo1;
        wo.Check_Out_Time__c = DateTime.newInstance(2024,02,23,10,10,0);
        update wo;
        
        cs = [SELECT Id,Technician_Onsite_Start_Time__c,Technician_Onsite_Stop_Time__c FROM Case WHERE Id =: cs.Id];
        wo = [SELECT Id,Check_In_Time__c,Check_Out_Time__c,Time_Entries__c,Total_Labor_Hours__c FROM WorkOrder WHERE Id =:wo.Id];
        Test.stopTest();
        
        System.assert(cs.Technician_Onsite_Start_Time__c.date() == wo.Check_In_Time__c.date());
        System.assert(cs.Technician_Onsite_Stop_Time__c.date() == wo.Check_Out_Time__c.date());
        System.assert(wo.Total_Labor_Hours__c == 2.00);
    }
}