@isTest
public class LiftRentalEmailHandlerTest {
    @testSetup static void setup() {
        Account acc = TestDataFactory.createAccount();
        acc.ShippingCountry = 'United States';
        acc.Name = 'ALDI Inc';
        insert acc;
        ServiceContract sc = TestDataFactory.createServiceContract(acc);
        sc.AccountId = acc.Id;
        sc.Country__c = 'United States';
        sc.Service_Type__c = 'Onsite IMAC - Critical';
        insert sc;
        Case cs = TestDataFactory.createCase(acc, sc);
        insert cs;
        
        Test.startTest();
        WorkOrder wo = TestDataFactory.createWorkOrder(cs, sc, acc);
        wo.Equipment_Rental_Cost__c = null;
        insert wo;
        
        list<Product2> prodList = new list<Product2>();
        Product2 prod = new Product2(Name = 'ES-ONSITE-EQUIPMENT-RENTAL-COST',Source_Key__c = '22222', isActive =  true,
                                     Family = 'Service', Account_Item_Belongs_To__c = acc.Id);
        Product2 prod2 = new Product2(Name = 'ES-ONSITE-EQUIPMENT-RENTAL-CHARGE',Source_Key__c = '22222',isActive =  true,
                                      Family = 'Service', Account_Item_Belongs_To__c = acc.Id);
        prodList.add(prod);
        prodList.add(prod2);
        insert prodList;
        
        Id pricebookId = Test.getStandardPricebookId();
        list<PricebookEntry> pbeList = new list<PricebookEntry>();
        PricebookEntry standardPrice = TestDataFactory.createPricebookEntry(prodList[0]);
        PricebookEntry standardPrice1 = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prodList[1].Id,
            UnitPrice = 10000, IsActive = true);
        pbeList.add(standardPrice);
        pbeList.add(standardPrice1);
        insert pbeList;
        
        List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
        WorkOrderLineItem woli = new WorkOrderLineItem();
        woli.PricebookEntryId = pbeList[0].Id;
        woli.Status = 'New';
        woli.WorkOrderId = wo.Id;
        woli.quantity = 1;
        woli.unitprice = 10;
        woli.Created_For_Field__c = 'Equipment_Rental_Cost__c';
        woli.Vendor__c = 'United Rentals';
        woli.Rental_Order_Number__c = '228510043';
        woliList.add(woli);
        
        WorkOrderLineItem woli2 = new WorkOrderLineItem();
        woli2.PricebookEntryId = pbeList[0].Id;
        woli2.Status = 'New';
        woli2.WorkOrderId = wo.Id;
        woli2.quantity = 1;
        woli2.unitprice = 10;
        woli2.Created_For_Field__c = 'Equipment_Rental_Cost__c';
        woli2.Vendor__c = 'United Rentals';
        woli2.Rental_Order_Number__c = '228510043';
        woliList.add(woli2);
        insert woliList;
        Test.stopTest();
    }
    
    @istest static void TestinBoundEmail(){
        test.startTest();
        WorkOrder wo = [SELECT Id,WorkOrderNumber,(SELECT Id,Status,Rental_Order_Number__c FROM WorkOrderLineItems WHERE Created_For_Field__c = 'Equipment_Rental_Cost__c') FROM WorkOrder LIMIT 1];
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        String temp = 'Caution: This email originated from outside of the organization. Do not \n';
        temp += 'click links or open attachments unless you recognize the sender and know the \n';
        temp +=  'content is safe. When in doubt, contact the IT Dept. \n';
        temp += 'Ready for confirmation. \n';
        temp += 'Reservation # 228510043 \n';
        temp += 'Request received. \n';
        temp += ' \n';
        temp += '5922058 - ILLINOIS WHOLESALE \n';
        temp += 'Subtotal \n';
        temp += ' $765.89 \n';
        temp += 'Jobsite \n';
        temp += 'Delivery Date/Time \n';
        temp += '12/20/2023 7:36 AM \n';
        temp += 'Ordered By \n';
        temp += 'MAYE CARBONELL \n';
        temp += 'PO NUMBER \n';
        temp += wo.WorkOrderNumber + ' \n';
        
        email.plainTextBody = temp;
        List<String> toAddList = new List<String>();
        toAddList.add('patil@gmail.com');
        email.toAddresses = toAddList;
        email.fromAddress = 'vpatil@gmail.com';
        LiftRentalEmailHandler  testInbound = new LiftRentalEmailHandler ();
        testInbound.handleInboundEmail(email, env);
        test.stopTest();
        
        WorkOrder liftRequesteddWO = [SELECT Id,Equipment_Rental_Cost__c, 
                                      (SELECT Id,Status,Rental_Order_Number__c,Product2.Name FROM WorkOrderLineItems WHERE Created_For_Field__c = 'Equipment_Rental_Cost__c') 
                                      FROM WorkOrder WHERE Id=: wo.Id];
        
        List<WorkOrderLineItem> woliCheck = liftRequesteddWO.WorkOrderLineItems;
        System.assert(woliCheck[0].Status == 'Lift Requested');
        System.assert(woliCheck[0].Rental_Order_Number__c == '228510043');
    }
    
    @istest static void TestinBoundEmail1(){
        test.startTest();
        WorkOrder wo = [SELECT Id,WorkOrderNumber,(SELECT Id,Status,Rental_Order_Number__c FROM WorkOrderLineItems WHERE Created_For_Field__c = 'Equipment_Rental_Cost__c') FROM WorkOrder LIMIT 1];
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        String temp = 'Caution: This email originated from outside of the organization. Do not \n';
        temp += 'click links or open attachments unless you recognize the sender and know the \n';
        temp +=  'content is safe. When in doubt, contact the IT Dept. \n';
        temp += 'Ready for confirmation. \n';
        temp += 'Contract # 228510043 \n';
        temp += 'Reservation created. \n';
        temp += ' \n';
        temp += '5922058 - ILLINOIS WHOLESALE \n';
        temp += 'Subtotal \n';
        temp += ' $765.89 \n';
        temp += 'Jobsite \n';
        temp += 'Delivery Date/Time \n';
        temp += '12/20/2023 7:36 AM \n';
        temp += 'Ordered By \n';
        temp += 'MAYE CARBONELL \n';
        temp += 'PO NUMBER \n';
        temp += wo.WorkOrderNumber + ' \n';
        
        email.plainTextBody = temp;
        List<String> toAddList = new List<String>();
        toAddList.add('patil@gmail.com');
        email.toAddresses = toAddList;
        email.fromAddress = 'vpatil@gmail.com';
        LiftRentalEmailHandler  testInbound = new LiftRentalEmailHandler ();
        testInbound.handleInboundEmail(email, env);
        test.stopTest();
        
        WorkOrder confirmedWO = [SELECT Id,Equipment_Rental_Cost__c,
                                 (SELECT Id,Status,Rental_Order_Number__c,Product2.Name FROM WorkOrderLineItems WHERE Created_For_Field__c = 'Equipment_Rental_Cost__c') FROM WorkOrder WHERE Id=: wo.Id];
        List<WorkOrderLineItem> woliCheck = confirmedWO.WorkOrderLineItems;
        System.assert(woliCheck[0].Status == 'Rental Confirmed');
        System.assert(woliCheck[0].Rental_Order_Number__c == '228510043');
    }
    
    @istest static void TestinBoundEmail2(){
        test.startTest();
        WorkOrder wo = [SELECT Id,WorkOrderNumber,(SELECT Id,Status,Rental_Order_Number__c FROM WorkOrderLineItems WHERE Created_For_Field__c = 'Equipment_Rental_Cost__c') FROM WorkOrder LIMIT 1];
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        String temp = 'Caution: This email originated from outside of the organization. Do not \n';
        temp += 'click links or open attachments unless you recognize the sender and know the \n';
        temp +=  'content is safe. When in doubt, contact the IT Dept. \n';
        temp += 'Reservation # 228510043 \n';
        temp += 'Your equipment is on the way. \n';
        temp += ' \n';
        temp += '5922058 - ILLINOIS WHOLESALE \n';
        temp += 'Subtotal \n';
        temp += ' $765.89 \n';
        temp += 'Jobsite \n';
        temp += 'Delivery Date/Time \n';
        temp += '12/20/2023 7:36 AM \n';
        temp += 'Ordered By \n';
        temp += 'MAYE CARBONELL \n';
        temp += 'PO NUMBER \n';
        temp += wo.WorkOrderNumber + ' \n';
        
        email.plainTextBody = temp;
        List<String> toAddList = new List<String>();
        toAddList.add('patil@gmail.com');
        email.toAddresses = toAddList;
        email.fromAddress = 'vpatil@gmail.com';
        LiftRentalEmailHandler  testInbound = new LiftRentalEmailHandler ();
        testInbound.handleInboundEmail(email, env);
        test.stopTest();
        
        WorkOrder inRouteWO = [SELECT Id,Equipment_Rental_Cost__c, 
                               (SELECT Id,Status,Rental_Order_Number__c,Product2.Name FROM WorkOrderLineItems WHERE Created_For_Field__c = 'Equipment_Rental_Cost__c') 
                               FROM WorkOrder WHERE Id=: wo.Id];
        
        List<WorkOrderLineItem> woliCheck = inRouteWO.WorkOrderLineItems;
        System.assert(woliCheck[0].Status == 'Lift In Route');
        System.assert(woliCheck[0].Rental_Order_Number__c == '228510043');
    }
    
    @istest static void TestinBoundEmail3(){
        test.startTest();
        WorkOrder wo = [SELECT Id,WorkOrderNumber,(SELECT Id,Status,Rental_Order_Number__c FROM WorkOrderLineItems WHERE Created_For_Field__c = 'Equipment_Rental_Cost__c') FROM WorkOrder LIMIT 1];
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        String temp = 'Caution: This email originated from outside of the organization. Do not \n';
        temp += 'click links or open attachments unless you recognize the sender and know the \n';
        temp +=  'content is safe. When in doubt, contact the IT Dept. \n';
        temp += 'Your equipment has arrived \n';
        temp += 'Contract Number \n';
        temp += '228510043 \n';
        temp += ' \n';
        temp += '5922058 - ILLINOIS WHOLESALE \n';
        temp += 'Subtotal \n';
        temp += ' $765.89 \n';
        temp += 'Jobsite \n';
        temp += 'Delivery Date/Time \n';
        temp += '12/20/2023 7:36 AM \n';
        temp += 'Ordered By \n';
        temp += 'MAYE CARBONELL \n';
        temp += 'PO NUMBER \n';
        temp += wo.WorkOrderNumber + ' \n';
        
        email.plainTextBody = temp;
        List<String> toAddList = new List<String>();
        toAddList.add('patil@gmail.com');
        email.toAddresses = toAddList;
        email.fromAddress = 'vpatil@gmail.com';
        LiftRentalEmailHandler  testInbound = new LiftRentalEmailHandler ();
        testInbound.handleInboundEmail(email, env);
        test.stopTest();
        
        WorkOrder deliveredWO = [SELECT Id,Equipment_Rental_Cost__c, 
                                 (SELECT Id,Status,Rental_Order_Number__c,Product2.Name FROM WorkOrderLineItems WHERE Created_For_Field__c = 'Equipment_Rental_Cost__c') 
                                 FROM WorkOrder WHERE Id=: wo.Id];
        
        List<WorkOrderLineItem> woliCheck = deliveredWO.WorkOrderLineItems;
        System.assert(woliCheck[0].Status == 'Delivered');
        System.assert(woliCheck[0].Rental_Order_Number__c == '228510043');
    }
    
    @istest static void TestinBoundEmail4(){
        test.startTest();
        WorkOrder wo = [SELECT Id,WorkOrderNumber,(SELECT Id,Status,Rental_Order_Number__c FROM WorkOrderLineItems WHERE Created_For_Field__c = 'Equipment_Rental_Cost__c') FROM WorkOrder LIMIT 1];
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        String temp = 'Caution: This email originated from outside of the organization. Do not \n';
        temp += 'click links or open attachments unless you recognize the sender and know the \n';
        temp +=  'content is safe. When in doubt, contact the IT Dept. \n';
        temp += 'Equipment past due \n';
        temp += 'Requisition # 228510043 \n';
        temp += ' \n';
        temp += '5922058 - ILLINOIS WHOLESALE \n';
        temp += 'Subtotal \n';
        temp += ' $765.89 \n';
        temp += 'Delivery Date/Time \n';
        temp += '12/20/2023 7:36 AM \n';
        temp += 'Ordered By \n';
        temp += 'MAYE CARBONELL \n';
        temp += 'PO NUMBER \n';
        temp += wo.WorkOrderNumber + ' \n';
        
        email.plainTextBody = temp;
        List<String> toAddList = new List<String>();
        toAddList.add('patil@gmail.com');
        email.toAddresses = toAddList;
        email.fromAddress = 'vpatil@gmail.com';
        LiftRentalEmailHandler  testInbound = new LiftRentalEmailHandler ();
        testInbound.handleInboundEmail(email, env);
        test.stopTest();
        
        WorkOrder rentalOverdueWO = [SELECT Id,Equipment_Rental_Cost__c, 
                                     (SELECT Id,Status,Rental_Order_Number__c,Product2.Name FROM WorkOrderLineItems WHERE Created_For_Field__c = 'Equipment_Rental_Cost__c') 
                                     FROM WorkOrder WHERE Id=: wo.Id];
        
        List<WorkOrderLineItem> woliCheck = rentalOverdueWO.WorkOrderLineItems;
        System.assert(woliCheck[0].Status == 'Rental Overdue');
        System.assert(woliCheck[0].Rental_Order_Number__c == '228510043');
    }
    
    @istest static void TestinBoundEmail5(){
        test.startTest();
        WorkOrder wo = [SELECT Id,WorkOrderNumber,(SELECT Id,Status,Rental_Order_Number__c FROM WorkOrderLineItems WHERE Created_For_Field__c = 'Equipment_Rental_Cost__c') FROM WorkOrder LIMIT 1];
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        String temp = 'Caution: This email originated from outside of the organization. Do not \n';
        temp += 'click links or open attachments unless you recognize the sender and know the \n';
        temp +=  'content is safe. When in doubt, contact the IT Dept. \n';
        temp += 'Pickup request received \n';
        temp += 'Reservation # 228510043 \n';
        temp += ' \n';
        temp += '5922058 - ILLINOIS WHOLESALE \n';
        temp += 'Subtotal \n';
        temp += ' $765.89 \n';
        temp += 'Delivery Date/Time \n';
        temp += '12/20/2023 7:36 AM \n';
        temp += 'Ordered By \n';
        temp += 'MAYE CARBONELL \n';
        temp += 'PO NUMBER \n';
        temp += wo.WorkOrderNumber + ' \n';
        
        email.plainTextBody = temp;
        List<String> toAddList = new List<String>();
        toAddList.add('patil@gmail.com');
        email.toAddresses = toAddList;
        email.fromAddress = 'vpatil@gmail.com';
        LiftRentalEmailHandler  testInbound = new LiftRentalEmailHandler ();
        testInbound.handleInboundEmail(email, env);
        test.stopTest();
        
        WorkOrder pickupRequestedWO = [SELECT Id,Equipment_Rental_Cost__c, 
                                       (SELECT Id,Status,Rental_Order_Number__c,Product2.Name FROM WorkOrderLineItems WHERE Created_For_Field__c = 'Equipment_Rental_Cost__c') 
                                       FROM WorkOrder WHERE Id=: wo.Id];
        
        List<WorkOrderLineItem> woliCheck = pickupRequestedWO.WorkOrderLineItems;
        System.assert(woliCheck[0].Status == 'Pickup Requested');
        System.assert(woliCheck[0].Rental_Order_Number__c == '228510043');
    }
    
    @istest static void TestinBoundEmail6(){
        test.startTest();
        WorkOrder wo = [SELECT Id,WorkOrderNumber,(SELECT Id,Status,Rental_Order_Number__c FROM WorkOrderLineItems WHERE Created_For_Field__c = 'Equipment_Rental_Cost__c') FROM WorkOrder LIMIT 1];
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        String temp = 'Caution: This email originated from outside of the organization. Do not \n';
        temp += 'click links or open attachments unless you recognize the sender and know the \n';
        temp +=  'content is safe. When in doubt, contact the IT Dept. \n';
        temp += 'An invoice has been issued for ILLINOIS WHOLESALE \n';
        temp += 'Reservation # 228510043 \n';
        temp += ' \n';
        temp += '5922058 - ILLINOIS WHOLESALE \n';
        temp += 'Subtotal \n';
        temp += ' $765.89 \n';
        temp += 'Delivery Date/Time \n';
        temp += '12/20/2023 7:36 AM \n';
        temp += 'Ordered By \n';
        temp += 'MAYE CARBONELL \n';
        temp += 'PO NUMBER \n';
        temp += wo.WorkOrderNumber + ' \n';
        
        email.plainTextBody = temp;
        List<String> toAddList = new List<String>();
        toAddList.add('patil@gmail.com');
        email.toAddresses = toAddList;
        email.fromAddress = 'vpatil@gmail.com';
        LiftRentalEmailHandler  testInbound = new LiftRentalEmailHandler ();
        testInbound.handleInboundEmail(email, env);
        test.stopTest();
        
        WorkOrder pickupRequestedWO = [SELECT Id,Equipment_Rental_Cost__c, 
                                       (SELECT Id,Status,Rental_Order_Number__c,Product2.Name FROM WorkOrderLineItems WHERE Created_For_Field__c = 'Equipment_Rental_Cost__c') 
                                       FROM WorkOrder WHERE Id=: wo.Id];
        
        List<WorkOrderLineItem> woliCheck = pickupRequestedWO.WorkOrderLineItems;
        System.assert(woliCheck[0].Status == 'Invoiced');
        System.assert(woliCheck[0].Rental_Order_Number__c == '228510043');
    }
    
    @istest static void TestinBoundEmail7(){
        test.startTest();
        WorkOrder wo = [SELECT Id,WorkOrderNumber,(SELECT Id,Status,Rental_Order_Number__c FROM WorkOrderLineItems WHERE Created_For_Field__c = 'Equipment_Rental_Cost__c') FROM WorkOrder LIMIT 1];
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        String temp = 'Caution: This email originated from outside of the organization. Do not \n';
        temp += 'click links or open attachments unless you recognize the sender and know the \n';
        temp +=  'content is safe. When in doubt, contact the IT Dept. \n';
        temp += 'Reservation # 228510043 \n';
        temp += ' \n';
        temp += 'FYI: In Route \n';
        temp += '5922058 - ILLINOIS WHOLESALE \n';
        temp += 'Subtotal \n';
        temp += ' $765.89 \n';
        temp += 'Jobsite \n';
        temp += 'Delivery Date/Time \n';
        temp += '12/20/2023 7:36 AM \n';
        temp += 'Ordered By \n';
        temp += 'MAYE CARBONELL \n';
        temp += 'PO NUMBER \n';
        temp += wo.WorkOrderNumber + ' \n';
        
        email.plainTextBody = temp;
        List<String> toAddList = new List<String>();
        toAddList.add('patil@gmail.com');
        email.toAddresses = toAddList;
        email.fromAddress = 'vpatil@gmail.com';
        LiftRentalEmailHandler  testInbound = new LiftRentalEmailHandler ();
        testInbound.handleInboundEmail(email, env);
        test.stopTest();
        
        WorkOrder pickupRequestedWO = [SELECT Id,Equipment_Rental_Cost__c, 
                                       (SELECT Id,Status,Rental_Order_Number__c,Product2.Name FROM WorkOrderLineItems WHERE Created_For_Field__c = 'Equipment_Rental_Cost__c') 
                                       FROM WorkOrder WHERE Id=: wo.Id];
        
        List<WorkOrderLineItem> woliCheck = pickupRequestedWO.WorkOrderLineItems;
        System.assert(woliCheck[0].Status == 'Lift In Route');
        System.assert(woliCheck[0].Rental_Order_Number__c == '228510043');
    }
    
    @istest static void TestinBoundEmail8(){
        test.startTest();
        WorkOrder wo = [SELECT Id,WorkOrderNumber,(SELECT Id,Status,Rental_Order_Number__c FROM WorkOrderLineItems WHERE Created_For_Field__c = 'Equipment_Rental_Cost__c') FROM WorkOrder LIMIT 1];
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        String temp = 'Caution: This email originated from outside of the organization. Do not \n';
        temp += 'click links or open attachments unless you recognize the sender and know the \n';
        temp +=  'content is safe. When in doubt, contact the IT Dept. \n';
        temp += 'Reservation # 228510043 \n';
        temp += ' \n';
        temp += 'FYI: Lift Delivered \n';
        temp += '5922058 - ILLINOIS WHOLESALE \n';
        temp += 'Subtotal \n';
        temp += ' $765.89 \n';
        temp += 'Jobsite \n';
        temp += 'Delivery Date/Time \n';
        temp += '12/20/2023 7:36 AM \n';
        temp += 'Ordered By \n';
        temp += 'MAYE CARBONELL \n';
        temp += 'PO NUMBER \n';
        temp += wo.WorkOrderNumber + ' \n';
        
        email.plainTextBody = temp;
        List<String> toAddList = new List<String>();
        toAddList.add('patil@gmail.com');
        email.toAddresses = toAddList;
        email.fromAddress = 'vpatil@gmail.com';
        LiftRentalEmailHandler  testInbound = new LiftRentalEmailHandler ();
        testInbound.handleInboundEmail(email, env);
        test.stopTest();
        
        WorkOrder pickupRequestedWO = [SELECT Id,Equipment_Rental_Cost__c, 
                                       (SELECT Id,Status,Rental_Order_Number__c,Product2.Name FROM WorkOrderLineItems WHERE Created_For_Field__c = 'Equipment_Rental_Cost__c') 
                                       FROM WorkOrder WHERE Id=: wo.Id];
        
        List<WorkOrderLineItem> woliCheck = pickupRequestedWO.WorkOrderLineItems;
        System.assert(woliCheck[0].Status == 'Lift Delivered');
        System.assert(woliCheck[0].Rental_Order_Number__c == '228510043');
    }
    
    @istest static void TestinBoundEmail9(){
        Account acc = [SELECT Id FROM Account LIMIT 1];
        ServiceContract sc = [SELECT Id FROM ServiceContract LIMIT 1];
        Case cs = [SELECT Id FROM Case LIMIT 1];
        test.startTest();
        
        WorkOrder wo = TestDataFactory.createWorkOrder(cs, sc, acc);
        wo.Equipment_Rental_Cost__c = null;
        insert wo;
        
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        String temp = 'Caution: This email originated from outside of the organization. Do not \n';
        temp += 'click links or open attachments unless you recognize the sender and know the \n';
        temp +=  'content is safe. When in doubt, contact the IT Dept. \n';
        temp += 'Reservation # 228510043 \n';
        temp += ' \n';
        temp += 'FYI: Lift Requested \n';
        temp += '5922058 - ILLINOIS WHOLESALE \n';
        temp += 'Invoice Amount \n';
        temp += ' $765.89 \n';
        temp += 'Jobsite \n';
        temp += 'Delivery Date/Time \n';
        temp += '12/20/2023 7:36 AM \n';
        temp += 'Ordered By \n';
        temp += 'MAYE CARBONELL \n';
        temp += 'PO NUMBER \n';
        temp += wo.WorkOrderNumber + ' \n';
        temp += 'Estimated Delivery \n';
        temp += '12/20/2023 7:36 AM \n';
        temp += 'Estimated Start \n';
        temp += '12/20/2023 7:36 AM \n';
        temp += 'Estimated End \n';
        temp += '12/20/2023 8:36 AM \n';
        temp += 'Date Stopped \n';
        temp += '12/20/2023 8:36 AM \n';
        
        email.plainTextBody = temp;
        List<String> toAddList = new List<String>();
        toAddList.add('patil@gmail.com');
        email.toAddresses = toAddList;
        email.fromAddress = 'vpatil@gmail.com';
        LiftRentalEmailHandler  testInbound = new LiftRentalEmailHandler ();
        testInbound.handleInboundEmail(email, env);
        test.stopTest();
    }
}