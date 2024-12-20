@istest
public class EmailHandlerTest {
    @testSetup static void setup() {
        Test.startTest();
        Account acc = TestDataFactory.createAccount();
        acc.ShippingCountry = 'United States';
        acc.Name = 'ALDI Inc';
        insert acc;
        
        ServiceContract sc = TestDataFactory.createServiceContract(acc);
        sc.AccountId = acc.Id;
        sc.Country__c = 'United States';
        sc.Service_Type__c = 'Onsite IMAC - Critical';
        insert sc;
        
        Account acc2 = TestDataFactory.createAccount();
        acc2.Name = '468-079 Bettendorf';
        acc2.ParentId = acc.Id;
        acc2.Root_Account__c = acc.Id;
        acc2.Source_Key__c = '145';
        acc2.ShippingCountry ='United States';
        acc2.Type = 'Store';
        insert acc2;
        
        Support_Team__c sp = new Support_Team__c();
        sp.Name = 'ALDI GSD';
        sp.Account__c = acc.Id;
        sp.Tech_Notes__c = 'Test';
        insert sp;
        Test.stopTest();
    }
    
    @istest static void TestinBoundEmail(){
        test.startTest();
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        String temp = 'Please process this work order for the following:\n';
        temp += 'Company name: Telaid New/Repl \n';
        temp += 'Opened by: Karen McGranahan (mcgranahan@aldi-499.loc) \\n';
        temp += 'Request #: REQ0848707 \n';
        temp += 'Incident #: INC1841516 \n';
        temp += 'Opened date: 2022-10-26 17:58:47 CEST \n';
        temp += 'GSD Phone: 866-711-2534 \n';
        temp += 'Aldi location: 468-079 Bettendorf,IA \\ 3221 Devils Glen Rd \n';
        temp += 'Address: 3221 Devils Glen Rd, 52722 Bettendorf,IA, United States of America \n';
        temp += 'Phone: 563-214-8072 \n';
        temp += 'Service: US Expansion Service \n';
        temp += 'Quantity: 1 \n';
        temp += 'Urgency:  High \n';
        temp += 'Service Date/Time:  09/11/2023 20:30:00 \n';
        temp += 'Store Format:  SOTF, Legacy \n';
        temp += 'Type of Service:  Low Voltage Cabling, Networking, Point of Sale, CCTV / Alarms, Structured Cabling, Telecom / VOIP, Other \n';
        temp += 'Comments: Describe the reason for the technician dispatch \n';
        temp += 'Ref:MSG193094177\n';
        email.plainTextBody = temp;
        List<String> toAddList = new List<String>();
        toAddList.add('patil@gmail.com');
        email.toAddresses = toAddList;
        email.fromAddress = 'vpatil@gmail.com';
        EmailHandler  testInbound=new EmailHandler ();
        testInbound.handleInboundEmail(email, env);
        test.stopTest();
        
        Support_Team__c sp = [SELECT Id,Tech_Notes__c FROM Support_Team__c LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name = '468-079 Bettendorf' LIMIT 1];
        Case cs = [SELECT Id, Tech_Notes__c, Service_Type__c, Priority FROM Case WHERE AccountId =: acc.Id];
        System.assert(cs.Tech_Notes__c == sp.Tech_Notes__c);
        System.assert(cs.Service_Type__c == 'Onsite IMAC - Critical');
        System.assert(cs.Priority == 'Severity 1');
    }
    
    @istest  static void TestinBoundEmail2(){
        test.startTest();
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        String temp = 'Please process this work order for the following:\n';
        temp += 'Company name: Telaid New/Repl \n';
        temp += 'Opened by: Karen McGranahan (mcgranahan@aldi-499.loc) \\n';
        temp += 'Request #: REQ0848707 \n';
        temp += 'Incident #: INC1841516 \n';
        temp += 'Opened date: 2022-10-26 17:58:47 CEST \n';
        temp += 'GSD Phone: 866-711-2534 \n';
        temp += 'Aldi location: 468-079 Bettendorf,IA \\ 3221 Devils Glen Rd \n';
        temp += 'Address: 3221 Devils Glen Rd, 52722 Bettendorf,IA, United States of America \n';
        temp += 'Phone: 563-214-8072 \n';
        temp += 'Service: US Expansion Service \n';
        temp += 'Quantity: 1 \n';
        temp += 'Urgency:  High \n';
        temp += 'Service Date/Time:  0534539/1345351/2234234023 243530:3342320:00 \n';
        temp += 'Store Format:  SOTF, Legacy \n';
        temp += 'Type of Service:  Low Voltage Cabling, Networking, Point of Sale, CCTV / Alarms, Structured Cabling, Telecom / VOIP, Other \n';
        temp += 'Comments: Describe the reason for the technician dispatch \n';
        temp += 'Ref:MSG193094177\n';
        email.plainTextBody = temp;
        List<String> toAddList = new List<String>();
        toAddList.add('patil@gmail.com');
        email.toAddresses = toAddList;
        email.fromAddress = 'vpatil@gmail.com';
        EmailHandler  testInbound=new EmailHandler ();
        testInbound.handleInboundEmail(email, env);
        test.stopTest();
        
        Account acc = [SELECT Id,(SELECT Id FROM Cases) FROM Account WHERE Name = '468-079 Bettendorf' LIMIT 1];
        System.assert(acc.Cases.isEmpty());
    }
}