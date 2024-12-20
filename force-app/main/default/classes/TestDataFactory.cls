@isTest
public class TestDataFactory {
    public static Account createAccount(){
        Account acc = new Account(
            Name = 'test account',
            Source_Key__c = '12345',
            Account_Rep__c = userInfo.getUserId(),
            Timezone__c = 'EST',
            ShippingCountry = 'United States',
            ShippingState = 'NY'
        );
        return acc;
    }
    
    public static Sales_Order__c createSalesOrder(Account acc, Case cs) {
        Sales_Order__c so = new Sales_Order__c(
        	Account__c = acc.Id,
            Case__c = cs.Id
        );
        return so;
    }
    
    public static Product2 createProduct2(Account acc){
        Product2 prod = new Product2(
            isActive = true,
            Name = 'Test Product',
            ProductCode = 'Test Code',
            Family = 'Hardware', 
            Account_Item_Belongs_To__c = acc.Id,
            Base_Price__c = 10,
            Source_Key__c = '12345',
            Staging_Required__c = true, 
            No_Return_Shipment__c = true,
            Reorder_Point__c = 6,
            Burn_Rate__c = 1,
            Weeks_of_Stock_Needed__c = 12,
            Quantity_Available__c = 10, 
            Quantity_on_Hand__c = 10, 
            NS_Quantity_Available__c = 5,
            X12_Weeks_Order_History__c = 5,
            Product_Condition__c = 'Original',
            Manufacturer_Part_Number__c = 'Test-01'
        );
        return prod;
    }
    
    public static PricebookEntry createPricebookEntry(Product2 prod){
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, 
            Product2Id = prod.Id,
            UnitPrice = 100, 
            IsActive = true
        );
        return standardPrice;
    }
    
    public static ServiceContract createServiceContract(Account acc){
        Id pricebookId = Test.getStandardPricebookId();
        ServiceContract sc = new ServiceContract(
            Name = 'test ServiceContract',
            AccountId = acc.Id,
            Create_Work_Order_For__c = 'Service Contract',
            Invoice_Group__c = 'Field Service',
            Service_Type__c = 'Advance Exchange (Depot Only)',
            Work_Order_Record_Type__c = 'Part Shipment',
            Markup_on_Equipment__c = 2,
            Markup_on_Materials__c = null,
            Pricebook2Id = pricebookId,
            Include_in_Service_Type_Picklist__c = true,
            Country__c = 'United States',
            Single_WO_For_Billing__c = false,
            StartDate = System.now().Date(),
            Include_In_Burn_Rate_Calculation__c = true
        );
        return sc;
    }
    
    public static ContractLineItem createContractLineItem(ServiceContract sc, PricebookEntry pbe){
        ContractLineItem cli = new ContractLineItem(
            ServiceContractId = sc.Id,
            Number_Of_Technicians__c = 1,
            Work_Order_Record_Type__c = sc.Work_Order_Record_Type__c,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100,
            Description = 'TEST'
        );
        return cli;
    }
    
    public static Case createCase(Account acc,ServiceContract sc){
        Case c = new Case(
            AccountId = acc.Id,
            Incident__c = 'TEST',
            OwnerId = userInfo.getUserId(),
            Status = 'New',
            Priority = 'Severity 2',
            Asset_Number__c = '0001',
            Description = 'test1234',
            Service_Type__c = 'Advance Exchange (Depot Only)',
            ServiceContractId = (sc != null) ? sc.Id : null,
            Technician_Onsite_Start_Time__c = null,
            Technician_Onsite_Stop_Time__c = null,
            Site_Status__c = 'Site Not Ready',
            Technician_Status__c = 'CONFIRMED',
            Technician_Name__c = null,
            Technician_Phone__c = null,
            Onsite_Manager_Name__c = null,
            Resolution_Code__c = null,
            Resolution_Notes__c = null,
            Technician_OnSite_ETA__c = System.now(),
            SLA_Exception_Reason__c = 'OPENED FOR WRONG EQUIPMENT',
            Tracking_Numbers__c = null,
            Include_Part__c = false
        );
        return c;
    }
    
    public static Case_Product__c createCaseProduct(Case cs, Product2 prod){
        Case_Product__c cp = new Case_Product__c(
            Name = prod.Name, 
            Case__c = cs.Id, 
            Product__c = prod.Id,
            Quantity__c = 1);
        return cp;
    }
    
    public static WorkOrder createWorkOrder(Case cs, ServiceContract sc, Account acc){
        Id partShipRT = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Part_Shipment').getRecordTypeId();
        Id pricebookId = Test.getStandardPricebookId();
        WorkOrder wo = new WorkOrder(
            AccountId = acc.Id,
            CaseId = cs.Id,
            ServiceContractId = sc.Id,
            RecordTypeId = partShipRT,
            Pricebook2Id = pricebookId,
            No_Cost__c = true,
            Priority = 'Severity 1',
            status = 'New',
            FN_Status__c = 'Work Done',
            Technician_Status__c = 'Scheduling',
            Outbound_Tracking_Number_Status__c = 'test',
            Service_Type__c = 'Advance Exchange (Depot Only)',
            Check_In_Time__c = System.now(),
            Check_Out_Time__c = System.now().addDays(1),
            Time_Entries__c = '2023-04-24 11:00:00 - 2023-04-25 11:00:00 (24:00)',
            SLA_Due_DateTime__c = System.now().AddDays(5),
            Technician_OnSite_ETA_String__c = '2023-01-31T06:00:00+00:00',
            Technician_Name__c = 'Mr.Test1',
            Technican_Phone__c = '12121',
            Onsite_Manager_Name__c = 'Mr.Test1',
            Resolution_Code__c = 'RESOLVED',
            Resolution_Notes__c = 'Test',
            Technician_OnSite_ETA__c = System.now(),
            SLA_Exception_Code__c = 'CUSTOMER SOFTWARE ISSUE',
            NetSuite_Error__c = false,
            Tracking_Numbers__c = '1212',
            Check_Out_Lat_Lon__latitude__s = 11,
            Check_Out_Lat_Lon__longitude__s = 11,
            Check_In_Lat_Lon__latitude__s = 22,
            Check_In_Lat_Lon__longitude__s = 22,
            Latitude = 33,
            Longitude = 44,
            Billable_Expense_Total__c = 10
        );
        return wo;
    }
    
    public static WorkOrderLineItem createWorkOrderLineItem(WorkOrder wo , PricebookEntry pbe){
        WorkOrderLineItem woli = new WorkOrderLineItem(
            PricebookEntryId = pbe.Id,
            UnitPrice = 100,
            Quantity = 1,
            WorkOrderId = wo.Id,
            Description = 'Test'
        );
        return woli;
    }
    
    public static Event createEvent(WorkOrder wo){
        Event e = new Event(
            StartDateTime = wo.Check_In_Time__c,
            WhatId = wo.Id,
            WhoId = wo.ContactId,
            DurationInMinutes = 1,
            Subject = 'Technician Working'
        );
        return e;
    }
    
    public static Product_Bundle__c createProductBundle(List<Product2> prodList){
        Product_Bundle__c pbd = new Product_Bundle__c(
            Name = 'test bundle',
            Parent_Product__c = prodList[0].Id,
            Child_Product__c = prodList[1].Id
        );
        return pbd;
    }
    
    public static ServiceAppointment createServiceAppointment(WorkOrder wo){
        ServiceAppointment sa = new ServiceAppointment(
            ParentRecordId = wo.Id,
            EarliestStartTime = System.now(),
            DueDate = System.now().AddDays(2),
            Status = 'Scheduled'
        );
        return sa;
    }
    
    public static Contact CreateContact(Account Acc){
        contact con = new contact(
            LastName = 'test',
            AccountId = acc.Id,
            Email = 'test@asc.com',
            Receive_Inventory_Notifications__c = true
        );
        return con;
    }
    
    public static Global_Settings__c CreateGlobalSettings(){
        Global_Settings__c gs = new Global_Settings__c(FN_Markup__c = 3);
        return gs;
    }
}