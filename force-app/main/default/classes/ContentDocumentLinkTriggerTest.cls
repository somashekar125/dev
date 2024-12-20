@isTest
public class ContentDocumentLinkTriggerTest {
    @testSetup static void setup() {
        Test.startTest();
        Account acc = TestDataFactory.createAccount();
        acc.Name = 'BOSCOV Test';
        insert acc;
        ServiceContract sc = TestDataFactory.createServiceContract(acc);
        insert sc;
        Case cs = TestDataFactory.createCase(acc, sc);
        insert cs;
        Product2 prod = TestDataFactory.createProduct2(acc);
        insert prod;
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(prod);
        insert pbe;
        Asset ast= new Asset(AccountId = acc.Id, Product2Id = prod.Id, Name = prod.Name);
        insert ast;
        WorkOrder wo = TestDataFactory.createWorkOrder(cs, sc, acc);
        wo.No_Cost__c = true;
        wo.Service_Type__c = 'Advance Exchange (Depot Only)';
        wo.Priority = 'Severity 1';
        wo.CaseId = cs.Id;
        insert wo;
        WorkOrderLineItem woli = TestDataFactory.createWorkOrderLineItem(wo, pbe);
        insert woli;
        NoFilesWOLI.updateWOLI();
        Test.stopTest();
        WorkOrderLineItem woliCheck = [SELECT Id,No_Images__c FROM WorkOrderLineItem WHERE Id =: woli.Id];
        System.assert(woliCheck.No_Images__c == true);
    }
    
    @isTest static void testMethod1(){
        Account acc = [SELECT Id FROM Account WHERE Name = 'BOSCOV Test' LIMIT 1];
        ServiceContract sc = [SELECT Id FROM ServiceContract WHERE Name = 'test ServiceContract' LIMIT 1];
        Case cs = [SELECT Id FROM Case WHERE AccountId =: acc.Id AND Service_Type__c = 'Advance Exchange (Depot Only)' LIMIT 1];
        WorkOrder wo = [SELECT Id,(SELECT Id FROM WorkOrderLineItems) FROM WorkOrder WHERE CaseId =: cs.Id];
        List<WorkOrderLineItem> woliList = wo.WorkOrderLineItems;
        
        ContentVersion content=new ContentVersion();
        content.Title='Header_Picture1'; 
        content.PathOnClient='/' + content.Title + '.jpg'; 
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 
        content.VersionData=bodyBlob; 
        content.origin = 'H';
        insert content;
        
        Id cdId = [SELECT contentdocumentid FROM contentversion WHERE Id =: content.Id].contentdocumentId;
        List<string> docList = new List<string>();
        docList.add(cdId);
        
        List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId = wo.Id;
        contentlink.contentdocumentid=[SELECT contentdocumentid FROM contentversion WHERE Id =: content.Id].contentdocumentid;
        //contentlink.ShareType = 'I';
        contentlink.Visibility = 'AllUsers';
        cdlList.add(contentlink);

        ContentDocumentLink contentlink2 = new ContentDocumentLink();
        contentlink2.LinkedEntityId = woliList[0].Id;
        contentlink2.contentdocumentId = cdId;
        contentlink2.ShareType = 'I';
        contentlink2.Visibility = 'AllUsers'; 
        cdlList.add(contentlink2);
        
        Test.StartTest();
        insert cdlList;
        AssetInspectionFilesUpload.updateFileNames(docList, 'Before');
        List<ContentDocumentLink> cdlList2 = AssetInspectionFilesUpload.getFiles(woliList[0].Id, 'Before');
        WorkOrderLineItem woliCheck = AssetInspectionFilesUpload.getWOLI(woliList[0].Id);
        Test.StopTest();
        
        List<ContentDocumentLink> ctlCheckList = [SELECT Id FROM ContentDocumentLink WHERE LinkedentityId =: wo.Id];
        System.assert(ctlCheckList != null);
        //ContentDocument cd =[SELECT Id,Title FROM ContentDocument WHERE Id =: docList[0]];
        //System.assert(cd.Title == 'Before_Header_Picture1');
        System.assert(cdlList2 != null);
        System.assert(woliCheck != null);
    }
}