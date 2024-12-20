@isTest
public with sharing class FlowControllerTest {
    @IsTest static void FlowControllerTest() {
        Account rootAcc = TestDataFactory.createAccount();
        rootAcc.Name = 'Root Account';
        rootAcc.Source_Key__c = '789';
        insert rootAcc;

        Product2 stagProd = TestDataFactory.createProduct2(rootAcc);
        stagProd.Name = 'Test Verifone E355 3-Unit Gang Charger';
        insert stagProd;
        rootAcc.Staging_Product__c = stagProd.Id;
        update rootAcc;

        Account acc = TestDataFactory.createAccount();
        acc.Root_Account__c = rootAcc.Id;
        insert acc;
        
        Global_Settings__c gs = new Global_Settings__c();
        gs.FN_Markup__c = 3;
        insert gs;
		
        list<Product2> prodList = new list<Product2>();
        Product2 prod = new Product2(Name = 'Verifone MX915 Payment Terminal; Signature Capture, PCI 3.X, Ethernet (Requires I/O Block)', Account_Item_Belongs_To__c= acc.Id,source_key__c = '7843',
                                     Quantity_Available__c = 10, Critical_Quantity__c = 3, Reorder_Point__c = 6, Quantity_on_Hand__c = 10, Staging_Required__c = true, Family = 'Hardware');
        Product2 prod2 = new Product2(Name = 'Test Product', Account_Item_Belongs_To__c= acc.Id,source_key__c = '132',
                                     Quantity_Available__c = 10, Critical_Quantity__c = 3, Reorder_Point__c = 6, Quantity_on_Hand__c = 10, Staging_Required__c = true, Family = 'Hardware');
        prodList.add(prod);
        prodList.add(prod2);
        insert prodList;
        
        Id pricebookId = Test.getStandardPricebookId();
        list<PricebookEntry> pbeList = new list<PricebookEntry>();
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        PricebookEntry standardPrice2 = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod2.Id,
            UnitPrice = 10000, IsActive = true);
        
        pbeList.add(standardPrice);
        pbeList.add(standardPrice2);
        insert pbeList;
        
        ServiceContract sc = TestDataFactory.createServiceContract(acc);
        sc.Work_Order_Record_Type__c = 'Part Shipment';
        insert sc;
		
        ContractLineItem cli = new ContractLineItem();
        cli.ServiceContractId = sc.Id;
        cli.PricebookEntryId = standardPrice.id;
        cli.UnitPrice = 100;
        cli.Quantity =1 ;
        insert cli;
        
        Case cs = TestDataFactory.createCase(acc, sc);
        cs.Root_Account__c = rootAcc.Id;
        cs.Staging_Required_Count__c = 2;
        insert cs;
        
        List<Case_Product__c> cpList = new List<Case_Product__c>();
        Case_Product__c cp = new Case_Product__c();
        cp.Product__c = prod.Id;
        cp.Quantity__c = 2;
        cp.case__c = cs.Id;
        cpList.add(cp);
        Case_Product__c cp2 = new Case_Product__c();
        cp2.Product__c = prod2.Id;
        cp2.Quantity__c = 2;
        cp2.case__c = cs.Id;
        cpList.add(cp2);
        insert cpList;

        Set<Id> caseIds = new Set<Id>();
        caseIds.add(cs.Id);
        CaseTriggerHandler.createOnsitePartWO(caseIds);
        
        WorkOrder wo = TestDataFactory.createWorkOrder(cs, sc, acc);
        insert wo;
        list<Id> woIds = new list<Id>();
        woIds.add(wo.Id);
        Set<Id> woIdSet = new Set<Id>(woIds);
        
        Test.startTest();
        //List<WorkOrderLineItem> woliList = FlowController.createHardwareWOLIs(woIdSet);
        FlowController.createHardwareWOLIs(woIds);
        AssigningWorkOrderOwner.callingQueuableClass(woIds);
        Test.stopTest();
        List<WorkOrderLineItem> woliList = [SELECT Id, Quantity FROM WorkOrderLineItem WHERE WorkOrderId IN : woIds];
        System.assert(woliList != null);
        System.assert(woliList[0].Quantity == 2);
    }
}