@isTest
public class CaseProductTriggerTest {
    @testSetup static void setup() { 
        List<Account> accList = new List<Account>();
        list<Timezone_Id__mdt> tzm = [SELECT MasterLabel, QualifiedApiName, Timezon_Id__c FROM Timezone_Id__mdt];
        Account acc = TestDataFactory.createAccount();
        acc.Name = 'Premium Brands Services, LLC';
        acc.ShippingState = 'United States';
        accList.add(acc);
        Account acc2 = new Account();
        acc2.Name = 'Premium Brands Services, LLC';
        acc2.Account_Rep__c = userInfo.getUserId();
        acc2.Timezone__c = tzm[0].MasterLabel;
        acc2.ShippingState = 'Canada';
        acc2.Source_Key__c = '12865';
        accList.add(acc2);
        
        Account acc3 = new Account();
        acc3.Name = 'Test Account 1';
        acc3.Account_Rep__c = userInfo.getUserId();
        acc3.Timezone__c = tzm[2].MasterLabel;
        acc3.Source_Key__c = '1286';
        accList.add(acc3);
        Account acc4 = new Account();
        acc4.Name = 'Test Account 2';
        acc4.Account_Rep__c = userInfo.getUserId();
        acc4.Timezone__c = tzm[4].MasterLabel;
        acc4.Source_Key__c = '128';
        accList.add(acc4);
        Account acc5 = new Account();
        acc5.Name = 'Test Account 3';
        acc5.Account_Rep__c = userInfo.getUserId();
        acc5.Timezone__c = tzm[6].MasterLabel;
        acc5.Source_Key__c = '122';
        accList.add(acc5);
        
        //AccountTriggerTest
        Account parentAcc1 = new Account();
        parentAcc1.Name = 'parent account 1';
        parentAcc1.Source_Key__c = '1232345';
        
        Account parentAcc2 = new Account();
        parentAcc2.Name = 'Parent account 2';
        parentAcc2.Source_Key__c = '1234546';
        
        Account parentAcc3 = new Account();
        parentAcc3.Name = 'Parent account 3';
        parentAcc3.Source_Key__c = '1238747';
        accList.add(parentAcc1);
        accList.add(parentAcc2);
        accList.add(parentAcc3);
        insert accList;
        
        Account accChild = new Account();
        accChild.Name = 'test account1';
        accChild.ParentId = parentAcc1.Id;
        accChild.Source_Key__c = '9712348';
        insert accChild;
        
        Account accChild2 = new Account();
        accChild2.Name = 'test account2';
        accChild2.ParentId = parentAcc2.Id;
        accChild2.Source_Key__c = '1235449';
        insert accChild2;
        
        accChild2 = [SELECT Id,Root_Account__c,ParentId FROM Account WHERE Id =: accChild2.Id];
        System.assert(accChild2.Root_Account__c == accChild2.ParentId);
        
        Account acc2Check = [SELECT Id,Root_Account__c FROM Account WHERE Id =: accChild.Id];
        Account acc3Check = [SELECT Id,Root_Account__c FROM Account WHERE Id =: accChild2.Id];
        System.assert(acc2Check.Root_Account__c == accChild.ParentId);
        System.assert(acc3Check.Root_Account__c == accChild2.ParentId);
        
        accChild2.ParentId = parentAcc3.Id;
        update accChild2;
        
        Id pricebookId = Test.getStandardPricebookId();
        List<ServiceContract> scList = new List<ServiceContract>();
        ServiceContract sc = TestDataFactory.createServiceContract(accList[0]);
        scList.add(sc);
        ServiceContract sc1 = TestDataFactory.createServiceContract(accList[0]);
        sc1.Service_Type__c = 'Onsite Labor Only';
        sc1.Work_Order_Record_Type__c = 'Onsite Labor';
        scList.add(sc1);
        ServiceContract sc2 = TestDataFactory.createServiceContract(accList[0]);
        sc2.Service_Type__c = 'Advance Exchange + Onsite';
        scList.add(sc2);
        ServiceContract sc3 = TestDataFactory.createServiceContract(accList[0]);
        sc3.Service_Type__c = 'Part Return';
        sc3.Work_Order_Record_Type__c = 'Onsite Labor';
        scList.add(sc3);
        ServiceContract sc4 = TestDataFactory.createServiceContract(accList[0]);
        sc4.Service_Type__c = 'New Store Install';
        sc4.Work_Order_Record_Type__c = 'Onsite Labor';
        scList.add(sc4);
        
        ServiceContract sc5 = TestDataFactory.createServiceContract(accList[1]);
        sc5.Country__c = 'Canada';
        scList.add(sc5);
        ServiceContract sc6 = TestDataFactory.createServiceContract(accList[1]);
        sc6.Service_Type__c = 'Onsite Labor Only';
        sc6.Work_Order_Record_Type__c = 'Onsite Labor';
        sc6.Country__c = 'Canada';
        scList.add(sc6);
        ServiceContract sc7 = TestDataFactory.createServiceContract(accList[1]);
        sc7.Service_Type__c = 'Advance Exchange + Onsite';
        sc7.Country__c = 'Canada';
        scList.add(sc7);
        ServiceContract sc8 = TestDataFactory.createServiceContract(accList[1]);
        sc8.Service_Type__c = 'Part Return';
        sc8.Work_Order_Record_Type__c = 'Onsite Labor';
        sc8.Country__c = 'Canada';
        scList.add(sc8);
        ServiceContract sc9 = TestDataFactory.createServiceContract(accList[0]);
        sc9.Service_Type__c = 'New Store Install';
        sc9.Work_Order_Record_Type__c = 'Onsite Labor';
        scList.add(sc9);
        insert scList;

        list<Product2> prodList = new list<Product2>();
        Product2 prod = TestDataFactory.createProduct2(acc);
        Product2 originalProduct = new Product2(Name = 'original product', Account_Item_Belongs_To__c = acc2.Id,
                                                Family = 'Hardware', IsActive = true, Quantity_Available__c = 10);
        Product2 prod1 = new Product2(Name = 'Verifone MX915 Payment Terminal; Signature Capture, PCI 3.X, Ethernet (Requires I/O Block)', Account_Item_Belongs_To__c= acc2.Id,
                                      Quantity_Available__c = 10, Critical_Quantity__c = 3, Reorder_Point__c = 6, Quantity_on_Hand__c = 10, Staging_Required__c = true, Family = 'Hardware');
        Product2 prod2 = new Product2(Name = 'ES-ONSITE-EQUIPMENT-RENTAL-COST',Source_Key__c = '22222',
                                      Family = 'Service', Account_Item_Belongs_To__c = acc.Id);
        Product2 prod3 = new Product2(Name = 'Test prod 3',Quantity_Available__c = 10,
                                      Family = 'Hardware', Account_Item_Belongs_To__c = acc2.Id);
        Product2 prod4 = new Product2(Name = 'ES-ONSITE-EQUIPMENT-RENTAL-CHARGE',Source_Key__c = '22222',
                                      Family = 'Service', Account_Item_Belongs_To__c = acc2.Id);
        Product2 prod5 = new Product2(Name = 'ES-ONSITE-MATERIALS-CHARGE',Source_Key__c = '22222',
                                      Family = 'Service', Account_Item_Belongs_To__c = acc.Id);
        prodList.add(originalProduct);
        prodList.add(prod);
        prodList.add(prod1);
        prodList.add(prod2);
        prodList.add(prod3);
        prodList.add(prod4);
        prodList.add(prod5);
        insert prodList;
        
        list<PricebookEntry> pbeList = new list<PricebookEntry>();
        PricebookEntry standardPrice = TestDataFactory.createPricebookEntry(prodList[0]);
        PricebookEntry standardPrice1 = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prodList[1].Id,
            UnitPrice = 10000, IsActive = true);
        PricebookEntry standardPrice2 = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prodList[2].Id,
            UnitPrice = 10000, IsActive = true);
        PricebookEntry standardPrice3 = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prodList[3].Id,
            UnitPrice = 10000, IsActive = true);
        PricebookEntry standardPrice4 = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prodList[4].Id,
            UnitPrice = 10000, IsActive = true);
        PricebookEntry standardPrice5 = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prodList[5].Id,
            UnitPrice = 10000, IsActive = true);
        pbeList.add(standardPrice);
        pbeList.add(standardPrice1);
        pbeList.add(standardPrice2);
        pbeList.add(standardPrice3);
        pbeList.add(standardPrice4);
        pbeList.add(standardPrice5);
        insert pbeList;
        
        List<Case> csList = new List<Case>();
        Case cs = TestDataFactory.createCase(acc, scList[0]);
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
        Test.startTest();
        insert csList;

        Id partShipRT = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Part_Shipment').getRecordTypeId();
        WorkOrder woParent = new WorkOrder();
        woParent.AccountId = accList[1].Id;
        woParent.CaseId = csList[0].Id;
        woParent.ServiceContractId = scList[0].Id;
        woParent.RecordTypeId = partShipRT;
        woParent.Pricebook2Id = pricebookId;
        woParent.No_Cost__c = true;
        woParent.Priority = 'Severity 1';
        woParent.status = 'New';
        woParent.FN_Status__c = 'Work Done';
        woParent.Technician_Status__c = 'Scheduling';
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
        woParent.NetSuite_Error__c = true;
        woParent.Tracking_Numbers__c = '1212';
        woParent.Check_Out_Lat_Lon__latitude__s = 11;
        woParent.Check_Out_Lat_Lon__longitude__s = 11;
        woParent.Check_In_Lat_Lon__latitude__s = 22;
        woParent.Check_In_Lat_Lon__longitude__s = 22;
        woParent.Latitude = 33;
        woParent.Longitude = 44;
        woParent.PO__c = 'Parent WO';
        insert woParent;
        
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
        insert cpList;

        Set<Id> caseIds = new Set<Id>();
        caseIds.add(cs2.Id);
        CaseTriggerHandler.createOnsitePartWO(caseIds);
        
        ContractLineItem cli3 = new ContractLineItem();
        cli3.ServiceContractId = scList[9].Id;
        cli3.Number_Of_Technicians__c = 1;
        cli3.Work_Order_Record_Type__c = 'Onsite Labor';
        cli3.PricebookEntryId = pbeList[3].Id;
        cli3.Include_In_WO_Type__c = 'Part Shipment';
        cli3.Quantity =1;
        cli3.UnitPrice = 10;
        insert cli3;
        
        Test.stopTest();
    }
    
    @IsTest static void testMethod1(){
        Account acc = [SELECT Id,Name,Root_Account__r.Name,ShippingCountry FROM Account WHERE Name = 'Premium Brands Services, LLC' LIMIT 1];
        ServiceContract sc = TestDataFactory.createServiceContract(acc);
        insert sc;
        
        Account acc2 = new Account();
        acc2.ParentId = acc.Id;
        acc2.Root_Account__c = acc.Id;
        acc2.Name = 'test account';
        acc2.Source_Key__c = '145';
        acc2.Account_Rep__c = userInfo.getUserId();
        list<Timezone_Id__mdt> tzm = [SELECT MasterLabel, QualifiedApiName, Timezon_Id__c FROM Timezone_Id__mdt];
        acc2.Timezone__c = tzm[0].MasterLabel;
        acc2.ShippingState = 'United States';
        insert acc2;
        
        Test.startTest();
        Case cs = new Case();
        cs.AccountId = acc2.Id;
        cs.ServiceContractId = null;
        cs.Status = 'New';
        cs.Service_Type__c = 'Advance Exchange (Depot Only)';
        cs.Preferred_Time__c = System.now();
        cs.Expected_SLA_Exit_Date__c = System.now();
        cs.Part_Receipt_Due_DateTime__c = System.now();
        cs.Technician_OnSite_ETA__c = System.now();
        cs.Technician_Onsite_Start_Time__c = System.now();
        cs.Technician_Onsite_Stop_Time__c = System.now();
        insert cs;
        
        Contact c = new Contact();
        c.Include_in_3hr_4hr_Alerts__c = true;
        c.LastName = 'test';
        insert c;
        
        acc2 = [SELECT Id,Name,Root_Account__r.Name,ShippingCountry FROM Account WHERE Id =: acc2.Id];
        cs = [SELECT Id,Main_Account_Name__c,SLA_Due_Date_TimeStr__c,Part_Shipped_Due_Date_TimeStr__c,Technician_OnSite_ETA_Str__c,
              Technician_Onsite_Start_TimeStr__c,Technician_Onsite_Stop_TimeStr__c FROM Case WHERE Id =: cs.Id];
        System.Assert(cs.SLA_Due_Date_TimeStr__c != null);
        System.Assert(cs.Part_Shipped_Due_Date_TimeStr__c != null);
        System.Assert(cs.Technician_OnSite_ETA_Str__c != null);
        System.Assert(cs.Technician_Onsite_Start_TimeStr__c != null);
        System.Assert(cs.Technician_Onsite_Stop_TimeStr__c != null);
        test.stopTest();
    }
    
    @IsTest static void testMethod2(){
        Account acc = [SELECT Id FROM Account WHERE Name = 'Premium Brands Services, LLC' AND ShippingState = 'Canada' LIMIT 1];
        ServiceContract scParent = [SELECT Id FROM ServiceContract WHERE Service_Type__c = 'Onsite labor Only' AND Country__c = 'Canada' AND AccountId =: acc.Id LIMIT 1];
        ServiceContract scChild = TestDataFactory.createServiceContract(acc);
        List<PricebookEntry> standardPriceList = [SELECT Id,Product2Id,UnitPrice,IsActive FROM PricebookEntry WHERE Product2.Account_Item_Belongs_To__c =: acc.Id AND IsActive = True];
        scChild.ParentServiceContractId = scParent.Id;
        scChild.Service_Type__c = 'Onsite Labor Only';
        scChild.Work_Order_Record_Type__c = 'Onsite Labor';
        scChild.Country__c = 'Canada';
        insert scChild;
        
        Map<Id,Product2> pbMap = new Map<Id,Product2>([SELECT Id FROM Product2 WHERE Account_Item_Belongs_To__c =: acc.Id]);
        list<PricebookEntry> pbeList = [SELECT Id FROM PricebookEntry WHERE Product2Id IN:pbMap.keySet()];
        List<Product2> prodList = pbMap.values();
        List<ContractLineItem> childcliList = new List<ContractLineItem>();
        ContractLineItem childcli = new ContractLineItem();
        childcli.ServiceContractId = scChild.Id;
        childcli.Number_Of_Technicians__c = 1;
        childcli.Work_Order_Record_Type__c = 'Onsite Labor';
        childcli.PricebookEntryId = pbeList[0].Id;
        childcli.Quantity = 1;
        childcli.UnitPrice = 10;
       	childcliList.add(childcli);
        
        ContractLineItem childcli1 = new ContractLineItem();
        childcli1.ServiceContractId = scChild.Id;
        childcli1.Number_Of_Technicians__c = 1;
        childcli1.Work_Order_Record_Type__c = 'Onsite Labor';
        childcli1.PricebookEntryId = pbeList[0].Id;
        childcli1.Quantity = 1;
        childcli1.UnitPrice = 10;
        childcli1.Include_In_WO_Type__c = 'Part Shipment';
        childcliList.add(childcli1);
        insert childcliList;
        
        Account acc2 = [SELECT Id FROM Account WHERE Name = 'Premium Brands Services, LLC' AND ShippingState = 'United States' LIMIT 1];
        ServiceContract sc = [SELECT Id FROM ServiceContract WHERE Service_Type__c = 'Advance Exchange (Depot Only)' AND AccountId =: acc2.Id LIMIT 1];
        ServiceContract sc2 = [SELECT Id FROM ServiceContract WHERE Service_Type__c = 'Advance Exchange + Onsite' AND AccountId =: acc2.Id LIMIT 1];
        ServiceContract sc3 = [SELECT Id FROM ServiceContract WHERE Service_Type__c = 'New Store Install' AND AccountId =: acc2.Id LIMIT 1];
        //List<Product2> prodList = [SELECT Id FROM Product2 WHERE Account_Item_Belongs_To__c =: acc.Id];
        
        Test.startTest();
        list<Case> csList = new list<Case>();
        Case cs = new Case();
        cs.Asset_Number__c = '0001';
        cs.AccountId = acc.Id;
        cs.Description = 'test1234';
        cs.Service_Type__c = 'Onsite labor Only';
        cs.Status = 'New';
        cs.Case_Products__c ='';
        cs.ServiceContractID = scChild.Id;
        cs.Include_Part__c = true;
        csList.add(cs);
        
        Case cs1 = new Case();
        cs1.Asset_Number__c = '0001';
        cs1.AccountId = acc.Id;
        cs1.Description = 'test1234';
        cs1.Service_Type__c = 'Onsite labor Only';
        cs1.Preferred_Time__c = System.today();
        cs1.Status = 'New';
        cs1.Case_Products__c = '';
        cs1.ServiceContractID = scChild.Id;
        csList.add(cs1);
        
        Case cs2 = new Case();
        cs2.Asset_Number__c = '0001';
        cs2.AccountId = acc2.Id;
        cs2.Description = 'test1234';
        cs2.Service_Type__c = 'Advance Exchange + Onsite';
        cs2.Status = 'New';
        cs2.Case_Products__c = '';
        cs2.ServiceContractID = sc.Id;
        csList.add(cs2);
        
        Case cs3 = new Case();
        cs3.Asset_Number__c = '0001';
        cs3.AccountId = acc2.Id;
        cs3.Description = 'test1234';
        cs3.Service_Type__c = 'Advance Exchange (Depot Only)';
        cs3.Status = 'New';
        cs3.Case_Products__c = '';
        cs3.ServiceContractID = sc2.Id;
        csList.add(cs3);
        
        Case cs4 = new Case();
        cs4.Asset_Number__c = '0001';
        cs4.AccountId = acc.Id;
        cs4.Description = 'test1234';
        cs4.Service_Type__c = 'New Store Install';
        cs4.Status = 'New';
        cs4.Case_Products__c ='';
        cs4.ServiceContractID = sc3.Id;
        csList.add(cs4);
        
        Case cs5 = new Case();
        cs5.Asset_Number__c = '0001';
        cs5.AccountId = acc.Id;
        cs5.Description = 'test1234';
        cs5.Service_Type__c = 'New Store Install';
        cs5.Status = 'New';
        cs5.Case_Products__c ='';
        cs5.ServiceContractID = sc3.Id;
        cs5.Include_Part__c = true;
        csList.add(cs5);
        insert csList;
        
        List<Case_Product__c> cpList = new List<Case_Product__c>();
        Case_Product__c cp = new Case_Product__c(Name = 'test', Case__c = csList[0].Id, Product__c = prodList[1].Id,Quantity__c = 1);
        Case_Product__c cp1 = new Case_Product__c(Name = 'test2', Case__c = csList[1].Id, Product__c = prodList[1].Id,Quantity__c = 1);
        Case_Product__c cp2 = new Case_Product__c(Name = 'test2', Case__c = csList[4].Id, Product__c = prodList[1].Id,Quantity__c = 1);
        Case_Product__c cp3 = new Case_Product__c(Name = 'test2', Case__c = csList[5].Id, Product__c = prodList[1].Id,Quantity__c = 1);
        cpList.add(cp);
        cpList.add(cp1);
        cpList.add(cp2);
        cpList.add(cp3);
        insert cpList;
        Set<Id> caseIds = new Set<Id>();
        caseIds.add(cs.Id);
        CaseTriggerHandler.createOnsitePartWO(caseIds);
        test.stopTest();
        
        WorkOrder wo = [SELECT Id FROM WorkOrder WHERE CaseId =: cs.Id LIMIT 1];
        List<WorkOrderLineItem> woliList = [SELECT Id, UnitPrice FROM WorkOrderLineItem WHERE WorkOrderId =: wo.Id];
        System.Assert(wo.Id != null);
        System.Assert(woliList != null);
    }
    
    @IsTest static void testMethod3(){
        Account acc = [SELECT Id FROM Account WHERE Name = 'Premium Brands Services, LLC' AND ShippingState = 'United States' LIMIT 1];
        ServiceContract sc = [SELECT Id FROM ServiceContract WHERE Service_Type__c = 'Advance Exchange (Depot Only)' AND AccountId =: acc.Id LIMIT 1];
        ServiceContract sc2 = [SELECT Id FROM ServiceContract WHERE Service_Type__c = 'Advance Exchange + Onsite' AND AccountId =: acc.Id LIMIT 1];
        ServiceContract sc3 = [SELECT Id FROM ServiceContract WHERE Service_Type__c = 'Onsite labor Only' AND AccountId =: acc.Id LIMIT 1];
        
        Test.startTest();
        list<Case> csList = new list<Case>();
        Case cs = new Case();
        cs.Asset_Number__c = '0001';
        cs.AccountId = acc.Id;
        cs.Description = 'test1234';
        cs.Service_Type__c = 'Advance Exchange + Onsite';
        cs.Status = 'New';
        cs.Case_Products__c = '';
        cs.ServiceContractID = sc.Id;
        cs.Actual_Part_Close_Date__c = null;
        cs.Closed_Date_Time__c = null;
        csList.add(cs);
        
        Case cs2 = new Case();
        cs2.Asset_Number__c = '0001';
        cs2.AccountId = acc.Id;
        cs2.Description = 'test1234';
        cs2.Service_Type__c = 'Advance Exchange (Depot Only)';
        cs2.Status = 'New';
        cs2.Case_Products__c = '';
        cs2.ServiceContractID = sc2.Id;
        cs2.Actual_Part_Close_Date__c = null;
        csList.add(cs2);
        
        Case cs3 = new Case();
        cs3.Asset_Number__c = '0001';
        cs3.AccountId = acc.Id;
        cs3.Description = 'test1234';
        cs3.Service_Type__c = 'Onsite labor Only';
        cs3.Preferred_Time__c = System.today();
        cs3.Status = 'New';
        cs3.Case_Products__c = '';
        cs3.ServiceContractID = sc3.Id;
        cs3.Closed_Date_Time__c = null;
        cs3.Tracking_Numbers__c = '11';
        cs3.Product_Quantity__c = 14;
        csList.add(cs3);
        insert csList;
        
        csList[0].status = 'Part Shipped';
        csList[1].status = 'Part Shipped';
        
        csList[2].status = 'Tech Checked In';
        csList[2].ParentId = csList[0].Id;
        csList[2].Tracking_Numbers__c = '111';
        csList[2].Product_Quantity__c = 4;
        update csList;
        
        Case cse = [SELECT Id,Actual_Part_Close_Date__c,Closed_Date_Time__c FROM Case Where Id =: csList[0].Id];
        Case cse3 = [SELECT Id,Actual_Part_Close_Date__c FROM Case Where Id =: csList[1].Id];
        Case cse4 = [SELECT Id,Closed_Date_Time__c FROM Case Where Id =: csList[2].Id];
        List<WorkOrder> woList = [SELECT Id, ContactId, CaseId, Product_Quantity__c, Tracking_Numbers__c FROM WorkOrder 
                                  WHERE CaseId =: csList[2].Id];
        Test.stopTest();
        
        System.Assert(cse.Actual_Part_Close_Date__c != null);
        System.Assert(cse3.Actual_Part_Close_Date__c != null);
        System.Assert(cse4.Closed_Date_Time__c != null);
        System.Assert(woList != null);
    }
        
    @IsTest static void testMethod4(){
        Test.startTest();
        List<Account> accList = [SELECT Id FROM Account];
        
        List<Case> csList = new List<Case>();
        Case cs = TestDataFactory.createCase(accList[0], null);
        cs.Preferred_Time__c = System.now();
        csList.add(cs);
        Case cs1 = TestDataFactory.createCase(accList[1], null);
        cs1.Preferred_Time__c = System.now();
        csList.add(cs1);
        Case cs2 = TestDataFactory.createCase(accList[2], null);
        cs2.Preferred_Time__c = System.now();
        csList.add(cs2);
        Case cs3 = TestDataFactory.createCase(accList[3], null);
        cs3.Preferred_Time__c = System.now();
        csList.add(cs3);
        Case cs4 = TestDataFactory.createCase(accList[4], null);
        cs4.Preferred_Time__c = System.now();
        csList.add(cs4);
        insert csList;
        
        delete csList;
        Test.stopTest();
    }
    
    @IsTest static void testMethod5(){
        Account acc = [SELECT Id FROM Account WHERE Name = 'Premium Brands Services, LLC' AND ShippingState = 'Canada' LIMIT 1];
        ServiceContract scParent = [SELECT Id FROM ServiceContract WHERE Service_Type__c = 'Onsite labor Only' AND Country__c = 'Canada' AND AccountId =: acc.Id LIMIT 1];
		ServiceContract scChild = TestDataFactory.createServiceContract(acc);
        scChild.ParentServiceContractId = scParent.Id;
        scChild.Service_Type__c = 'Onsite Labor Only';
        scChild.Work_Order_Record_Type__c = 'Onsite Labor';
        scChild.Country__c = 'Canada';
        insert scChild;
        Map<Id,Product2> pbMap = new Map<Id,Product2>([SELECT Id FROM Product2 WHERE Account_Item_Belongs_To__c =: acc.Id]);
        list<PricebookEntry> pbeList = [SELECT Id FROM PricebookEntry WHERE Product2Id IN:pbMap.keySet()];
        List<Product2> prodList = pbMap.values();
        
        ContractLineItem childcli = new ContractLineItem();
        childcli.ServiceContractId = scChild.Id;
        childcli.Number_Of_Technicians__c = 1;
        childcli.Work_Order_Record_Type__c = 'Onsite Labor';
        childcli.PricebookEntryId = pbeList[0].Id;
        childcli.Quantity = 1;
        childcli.UnitPrice = 10;
        insert childcli;
        
        List<ContractLineItem> cliList = new List<ContractLineItem>();
        ContractLineItem cli = new ContractLineItem();
        cli.ServiceContractId = scParent.Id;
        cli.Number_Of_Technicians__c =1;
        cli.Work_Order_Record_Type__c = 'Onsite Labor';
        cli.PricebookEntryId = pbeList[0].Id;
        cli.Quantity =1;
        cli.UnitPrice = 10;
        cliList.add(cli);
        ContractLineItem cli2 = new ContractLineItem();
        cli2.ServiceContractId = scParent.Id;
        cli2.Number_Of_Technicians__c =1;
        cli2.Work_Order_Record_Type__c = 'Onsite Labor';
        cli2.PricebookEntryId = pbeList[0].Id;
        cli2.Quantity =1;
        cli2.UnitPrice = 10;
        cliList.add(cli2);
        insert cliList;
        
        Test.startTest();
        List<Case> csList = new List<Case>();
        Case cs = new Case();
        cs.Asset_Number__c = '0001';
        cs.AccountId = acc.Id;
        cs.Description = 'test1234';
        cs.Service_Type__c = 'Onsite Labor Only';
        cs.Status = 'New';
        cs.Case_Products__c = '';
        cs.ServiceContractID = scParent.Id;
        cs.Include_Part__c = true;
        csList.add(cs);
        
        Case cs2 = new Case();
        cs2.Asset_Number__c = '0001';
        cs2.AccountId = acc.Id;
        cs2.Description = 'test1234';
        cs2.Service_Type__c = 'Onsite Labor Only';
        cs2.Preferred_Time__c = System.today();
        cs2.Status = 'New';
        cs2.Case_Products__c = '';
        cs2.ServiceContractID = scParent.Id;
        csList.add(cs2);
        
        Case cs3 = new Case();
        cs3.Asset_Number__c = '0001';
        cs3.AccountId = acc.Id;
        cs3.Description = 'test1234';
        cs3.Service_Type__c = 'Onsite Labor Only';
        cs3.Status = 'New';
        cs3.Case_Products__c = '';
        cs3.ServiceContractID = scParent.Id;
        csList.add(cs3);
        insert csList;
        
        List<Case_Product__c> cpList = new List<Case_Product__c>();
        Case_Product__c cp = new Case_Product__c(Name = 'test', Case__c = csList[0].Id, Product__c = prodList[0].Id,Quantity__c = 1);
        Case_Product__c cp2 = new Case_Product__c(Name = 'test2', Case__c = csList[1].Id, Product__c = prodList[0].Id,Quantity__c = 1);
        cpList.add(cp);
        cpList.add(cp2);
        insert cpList;
        Set<Id> caseIds = new Set<Id>();
        caseIds.add(cs.Id);
        CaseTriggerHandler.createOnsitePartWO(caseIds);
        Test.stopTest();
        
        WorkOrder wo = [SELECT Id FROM WorkOrder WHERE CaseId =: cs.Id LIMIT 1];
        WorkOrder woCheck = ClosingProcess.getwoRec(wo.Id);
        Case csCheck = ClosingProcess.getCaseRec(cs.Id);
        System.assert(woCheck != null);
        System.assert(csCheck != null);
        List<WorkOrderLineItem> woliList = [SELECT Id, UnitPrice FROM WorkOrderLineItem WHERE WorkOrderId =: wo.Id];
        System.Assert(wo.Id != null);
        System.Assert(woliList != null);
    }
    
    @IsTest static void testMethod6(){
        Account acc = [SELECT Id FROM Account WHERE Name = 'Premium Brands Services, LLC' AND ShippingState = 'Canada' LIMIT 1];
        ServiceContract scParent = [SELECT Id FROM ServiceContract WHERE Service_Type__c = 'Onsite labor Only' AND Country__c = 'Canada' AND AccountId =: acc.Id LIMIT 1];
        Map<Id,Product2> pbMap = new Map<Id,Product2>([SELECT Id FROM Product2 WHERE Account_Item_Belongs_To__c =: acc.Id]);
        list<PricebookEntry> pbeList = [SELECT Id FROM PricebookEntry WHERE Product2Id IN:pbMap.keySet()];
        List<Product2> prodList = pbMap.values();
        
        Test.startTest();
        Case cs = new Case();
        
        cs.Asset_Number__c = '0001';
        cs.AccountId = acc.Id;
        cs.Description = 'test1234';
        cs.Service_Type__c = 'Onsite Labor Only';
        cs.Status = 'Acknowledged';
        cs.Case_Products__c = '';
        cs.ServiceContractID = scParent.Id;
        cs.Include_Part__c = true;
        insert cs;
        
        Case cs1 = new Case();    
        cs1.Asset_Number__c = '0001';
        cs1.AccountId = acc.Id;
        cs1.Description = 'test1234';
        cs1.Service_Type__c = 'Onsite Labor Only';
        cs1.Status = 'Acknowledged';
        cs1.Case_Products__c = '';
        cs1.ServiceContractID = scParent.Id;
        cs1.Include_Part__c = true;
        cs1.ParentId = cs.Id;
        insert cs1;
        
        Case parentCase = new Case(
            Asset_Number__c = '0001',
            AccountId = acc.Id,
            Description = 'test1234',
            Service_Type__c = 'Onsite Labor Only',
            Status = 'Acknowledged',
            Case_Products__c = '',
            ServiceContractID = scParent.Id,
            Tracking_Numbers__c = 'PTN1',
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Bundle' LIMIT 1].Id
        );
        
        List<Case_Product__c> cpList = new List<Case_Product__c>();
        Case_Product__c cp = new Case_Product__c(Name = 'test', Case__c = cs.Id, Product__c = prodList[0].Id,Quantity__c = 1);
        Case_Product__c cp2 = new Case_Product__c(Name = 'test2', Case__c = cs.Id, Product__c = prodList[0].Id,Quantity__c = 1);
        cpList.add(cp);
        cpList.add(cp2);
        insert cpList;
        Set<Id> caseIds = new Set<Id>();
        List<Id> caseIds2 = new List<Id>();
        caseIds.add(cs.Id);
        caseIds2.add(cs.Id);
        CaseTriggerHandler.createOnsitePartWO(caseIds);
        CreateOnistePartWO.CreateOnistePartWO(caseIds2);
       	
        cs = [SELECT Id,Actual_Part_Close_Date__c,Closed_Date_Time__c FROM Case Where Id =: cs.Id];
        
       // CaseTriggerHandler.convertedCaseProcess();
        test.stopTest();
        
        WorkOrder wo = [SELECT Id FROM WorkOrder WHERE CaseId =: cs.Id LIMIT 1];
        List<WorkOrderLineItem> woliList = [SELECT Id, UnitPrice FROM WorkOrderLineItem WHERE WorkOrderId =: wo.Id];
        System.Assert(wo.Id != null);
        System.Assert(woliList != null);
        //System.Assert(woliList[0].UnitPrice == 10);
    }
}