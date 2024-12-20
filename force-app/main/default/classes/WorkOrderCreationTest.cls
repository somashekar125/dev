@isTest
public class WorkOrderCreationTest {
    @isTest static void testMethod1(){
        Account acc = TestDataFactory.createAccount();
        insert acc;
        
        List<ServiceContract> scList = new List<ServiceContract>();
        ServiceContract sc = TestDataFactory.createServiceContract(acc);
        sc.Name = 'test Onsite';
        sc.Work_Order_Record_Type__c = 'Onsite Labor';
        sc.Service_Type__c = 'Part Return';
        scList.add(sc);

        ServiceContract sc1 = TestDataFactory.createServiceContract(acc);
        sc1.Name = 'test Part + onsite';
        scList.add(sc1);
        
        ServiceContract sc2 = TestDataFactory.createServiceContract(acc);
        sc2.Name = 'test3 Part + onsite';
        scList.add(sc2);
        insert scList;
        
        List<ServiceContract> scChildList = new List<ServiceContract>();
        ServiceContract sc1Child = TestDataFactory.createServiceContract(acc);
        sc1Child.Name = 'test Part Child';
        sc1Child.ParentServiceContractId = scList[1].Id;
        scChildList.add(sc1Child);
        
        ServiceContract sc2Child = TestDataFactory.createServiceContract(acc);
        sc2Child.Name = 'test onsite Child';
        sc2Child.Service_Type__c = 'Onsite Labor Only';
        sc2Child.Work_Order_Record_Type__c = 'Onsite Labor';
        sc2Child.ParentServiceContractId = scList[2].Id;
        scChildList.add(sc2Child);
        insert scChildList;
        
        case cs = TestDataFactory.createCase(acc,scList[0]);
        insert cs;

        Test.startTest();
        Case csCheck = [SELECT Id,Service_Type__c FROM Case WHERE Id =: WorkOrderCreationController.getCaseRec(cs.Id).Id];
        RecordType rtCheck = WorkOrderCreationController.getRecordType();
        ServiceContract scCheck = [SELECT Id,Name,Service_Type__c,Work_Order_Record_Type__c FROM  ServiceContract WHERE 
                                   Id =: WorkOrderCreationController.getServiceContract(scList[0].Id,true).Id];
        ServiceContract scCheck1 = [SELECT Id,Name,Service_Type__c,Work_Order_Record_Type__c FROM  ServiceContract WHERE 
                                   Id =: WorkOrderCreationController.getServiceContract(scList[1].Id,false).Id];
        ServiceContract scCheck2 = [SELECT Id,Name,Service_Type__c,Work_Order_Record_Type__c FROM  ServiceContract WHERE 
                                   Id =: WorkOrderCreationController.getServiceContract(scList[2].Id,true).Id];
        
        System.assert(csCheck != null);
        System.assert(csCheck.Service_Type__c == 'Advance Exchange (Depot Only)');
        System.assert(rtCheck != null);
        System.assert(rtCheck.Name == 'Part Ordering');
        
        System.assert(scCheck != null);
        System.assert(scCheck.Name == 'test Onsite');
        System.assert(scCheck.Service_Type__c == 'Part Return');
        System.assert(scCheck.Work_Order_Record_Type__c == 'Onsite Labor');
        
        System.assert(scCheck1 != null);
        System.assert(scCheck1.Name == 'test Part Child');
        System.assert(scCheck1.Service_Type__c == 'Advance Exchange (Depot Only)');
        System.assert(scCheck1.Work_Order_Record_Type__c == 'Part Shipment');
        
        System.assert(scCheck2 != null);
        System.assert(scCheck2.Name == 'test onsite Child');
        System.assert(scCheck2.Service_Type__c == 'Onsite Labor Only');
        System.assert(scCheck2.Work_Order_Record_Type__c == 'Onsite Labor');
        Test.stopTest();
    }       
}