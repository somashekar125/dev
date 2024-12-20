@isTest
public class AssetInspectionFilesUploadTest {
    @isTest static void testMethod1(){
        Account acc = TestDataFactory.createAccount();
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
        insert wo;
        WorkOrderLineItem woli = TestDataFactory.createWorkOrderLineItem(wo, pbe);
        insert woli;

        Test.startTest();
        ContentVersion content=new ContentVersion();
        content.Title='Header_Picture1';
        content.PathOnClient='/' + content.Title + '.jpg'; 
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 
        content.VersionData=bodyBlob; 
        //content.FirstPublishLocationId = cl6.Id;
        content.origin = 'H';
        insert content;
        List<string> docList = new List<string>();
        docList.add([SELECT contentdocumentid FROM contentversion WHERE Id =: content.id].contentdocumentid);
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId = woli.id;
        contentlink.contentdocumentid=[SELECT contentdocumentid FROM contentversion WHERE Id =: content.id].contentdocumentid;
        contentlink.ShareType = 'I';
        contentlink.Visibility = 'AllUsers'; 
        insert contentlink;
        
        AssetInspectionFilesUpload.updateFileNames(docList, 'Before');
        List<ContentDocumentLink> cdlList = AssetInspectionFilesUpload.getFiles(woli.Id, 'Before');
        WorkOrderLineItem woliCheck = AssetInspectionFilesUpload.getWOLI(woli.Id);
        Test.stopTest();
        ContentDocument cd =[SELECT Id,Title FROM ContentDocument WHERE Id =: docList[0]];
        System.assert(cd.Title == 'Before_Header_Picture1');
        System.assert(cdlList != null);
        System.assert(woliCheck != null);
    }
}