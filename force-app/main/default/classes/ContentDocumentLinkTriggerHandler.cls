public class ContentDocumentLinkTriggerHandler {
    public static void handleAfterInsert(List<ContentDocumentLink> cdLinkList) {
        Set<Id> cvIds = new Set<Id>();
        Set<Id> cdIds = new Set<Id>();
        for(ContentDocumentLink cdl : cdLinkList){
            if(String.valueOf(cdl.LinkedEntityId).startsWith('0WO') || String.valueOf(cdl.LinkedEntityId).startsWith('500')){
                cdIds.add(cdl.ContentDocumentId);
            }
        }
        List<ContentDocument> cdList = [SELECT Id,LatestPublishedVersionId FROM ContentDocument WHERE Id IN: cdIds];
        for(ContentDocument cd : cdList){
            cvIds.add(cd.LatestPublishedVersionId);
        }
        //Get ContentVersion records for the CDL being inserted
        List<ContentVersion> cvList = [SELECT Id,FirstPublishLocationId,ContentDocumentId,pathOnClient,versionData,ContentBodyId,
                                        ContentLocation,ContentUrl,Description,ExternalDataSourceId,ExternalDocumentInfo1,
                                        ExternalDocumentInfo2 FROM ContentVersion WHERE Id In:cvIds];
        List<ContentVersion> cvListToBeCreated = new List<ContentVersion>();
        for (ContentVersion cv : cvList){
            System.debug('cv.FirstPublishLocationId-> ' + cv.FirstPublishLocationId);
            //When images come FROM FN, they have FirstPublishLocationId = Id of the user configured IN FN
            //So we are only processing CV records WHERE FirstPublishLocationId = Id of the user
            if(!String.valueOf(cv.FirstPublishLocationId).startsWith('500') && !String.valueOf(cv.FirstPublishLocationId).startsWith('0WO')){
                cvListToBeCreated.add(cv);
            }
        }
        List<ContentDocumentLink> cdlToInsert = new List<ContentDocumentLink>();
        if(!cvListToBeCreated.isEmpty()){
            Map<Id,ContentVersion> cvMap = assigningFirstPublishLocationId(cdLinkList,cvListToBeCreated,cdList);
            //Getting Contecnt Versions that are created IN above method to get ContentDocumentId FROM them.
            //We cannot get ContentDocumentId FROM inserted CV List. we have to query to get it.
            //Below ContentVersion for loop creates ContentDocumentLink for WO so that files are visible IN WO too.
            Map<Id,ContentVersion> cvMap2 = new Map<Id,ContentVersion>([SELECT Id,ContentDocumentId FROM ContentVersion WHERE Id IN : cvMap.keySet()]);
            Map<Id,ContentDocument> cdMap = new Map<Id,ContentDocument>([SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId IN :cvMap2.keySet()]);
            Map<Id,ContentDocumentLink> existingCdlsMap = new Map<Id,ContentDocumentLink>([SELECT Id,ContentDocumentId, LinkedEntityId FROM 
                                                                                            ContentDocumentLink WHERE ContentDocumentId IN : cdMap.keySet()]);
            for(ContentVersion cv : cvMap2.values()){
                Id cdID = cdMap.get(cv.ContentDocumentId).Id;
                Set<Id> existingCDLLinkedEntityIds = new Set<Id>();
                for(ContentDocumentLink cdl : existingCdlsMap.values()){
                    existingCDLLinkedEntityIds.add(cdl.LinkedEntityId);
                }
                System.debug('existingCDLLinkedEntityIds-> ' + existingCDLLinkedEntityIds);
                for(ContentDocumentLink cdl : cdLinkList){
                    if(existingCDLLinkedEntityIds.contains(cdl.LinkedEntityId)) continue;
                    if(!String.valueOf(cdl.LinkedEntityId).startsWith('0WO')) continue;
                    System.debug('cdl.LinkedEntityId-> ' + cdl.LinkedEntityId);

                    ContentDocumentLink cdlNew = new ContentDocumentLink();
                    cdlNew.ContentDocumentId = cdID;
                    cdlNew.LinkedEntityId = cdl.LinkedEntityId;
                    cdlNew.ShareType = cdl.ShareType;
                    cdlNew.Visibility = 'AllUsers';
                    cdlToInsert.add(cdlNew);
                }
            }
            System.debug('cdlToInsert Size-> ' + cdlToInsert.size());
            if(!cdlToInsert.isEmpty()){
                insert cdlToInsert;
            }
        }
        //ContentVersions which don't have FirstPublishLocationId as user Id, we have to create CDL for Case.
        updateCDLinWOandCase(cdLinkList,cdlToInsert);
    }
    public static void updateCDLinWOandCase(List<ContentDocumentLink> cdLinkList,List<ContentDocumentLink> cdlToInsert){
        Set<Id> woToExclude = new Set<Id>();
        for(ContentDocumentLink cdl : cdlToInsert){
            if(String.valueOf(cdl.LinkedEntityId).startsWith('0WO')){
                woToExclude.add(cdl.LinkedEntityId);
            }
        }
        Set<Id> woIds = new Set<Id>();
        Set<Id> cdIds = new Set<Id>();
        for(ContentDocumentLink cd : cdLinkList){
            if(String.valueOf(cd.LinkedEntityId).startsWith('0WO')){
                woIds.add(cd.LinkedEntityId);
                cdIds.add(cd.ContentDocumentId);
            }
        }
        /*if(!System.isFuture() && !System.isBatch()){
            updateLibraryinCD(cdIds);
        }*/
        //List<ContentWorkspace> cws = [SELECT Id, Name FROM ContentWorkspace WHERE Name = 'Field Nation' limit 1];
        List<WorkOrder> woList = [SELECT Id, CaseId, ParentWorkOrderId FROM WorkOrder WHERE Id IN: woIds];
        Set<Id> caseIds = new Set<Id>();
        for(WorkOrder wo : woList){
            caseIds.add(wo.CaseId);
        }
        Set<Id> duplicateCaseIds = new Set<Id>();
        if(!cdIds.isEmpty() && !caseIds.isEmpty()){
            List<ContentDocumentLink> cdlRecords = [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN : caseIds AND ContentDocumentId IN: cdIds];
            for(ContentDocumentLink c : cdlRecords){
                duplicateCaseIds.add(c.LinkedEntityId);
            }
        }
        List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
        if(woList.size() != 0){
            for(ContentDocumentLink cd : cdLinkList){
                for(WorkOrder w : woList){
                    if(woToExclude.contains(w.Id)) continue;
                    if(w.CaseId != null && cd.LinkedEntityId == w.Id && !duplicateCaseIds.contains(w.CaseId)){
                        ContentDocumentLink cdl = new ContentDocumentLink();
                        cdl.LinkedEntityId = w.CaseId;
                        cdl.ContentDocumentId = cd.ContentDocumentId;
                        cdl.Visibility = 'AllUsers';
                        cdlList.add(cdl);
                    }
                    if(w.ParentWorkOrderId != null && cd.LinkedEntityId == w.Id){
                        ContentDocumentLink cdl = new ContentDocumentLink();
                        cdl.LinkedEntityId = w.ParentWorkOrderId;
                        cdl.ContentDocumentId = cd.ContentDocumentId;
                        cdl.Visibility = 'AllUsers';
                        cdlList.add(cdl);
                    }
                }
            }
            /*
            for(ContentDocumentLink cd : cdLinkList){
                if(cws.size() != 0){
                    ContentDocumentLink cdl2 = new ContentDocumentLink();
                    cdl2.LinkedEntityId = cws[0].Id;
                    cdl2.ContentDocumentId = cd.ContentDocumentId;
                    cdl2.Visibility = 'AllUsers';
                    cdlList.add(cdl2);
                }
            }*/
        }
        if(cdlList.size() != 0){
            System.debug('cdlList Size-> ' + cdlList.size());
            insert cdlList;
        }
    }
    
    public static void handleBeforeInsert(List<ContentDocumentLink> cdLinkList) {
        for(ContentDocumentLink cdl : cdLinkList){
            if(String.valueOf(cdl.LinkedEntityId).startsWith('500')){
                cdl.Visibility = 'AllUsers';
            }
        }
    }

    public static Map<Id,ContentVersion> assigningFirstPublishLocationId(List<ContentDocumentLink> cdLinkList, List<ContentVersion> cvList,List<ContentDocument> cdList) {
		System.debug('cvList-> ' + JSON.serialize(cvList));
        Set<Id> woIds = new Set<Id>();
        for(ContentDocumentLink cd : cdLinkList){
            if(String.valueOf(cd.LinkedEntityId).startsWith('0WO')){
                woIds.add(cd.LinkedEntityId);
            }
        }
        Map<Id,WorkOrder> woMap = new Map<Id,WorkOrder>([SELECT Id, CaseId, ParentWorkOrderId FROM WorkOrder WHERE Id IN: woIds]);
        List<ContentVersion> listToInsert = new List<ContentVersion>();
        //This for loop is for the CVs to be created
        //We are creating CV so that we can Set FirstPublishLocationId on them, this field can only Set when creation
        //The CV created FROM FN have user Id as the FirstPublishLocationId, so the file is not visible IN WO WHERE FN is loading it.
        //Below for loop creates CVs AND associated with Case records.
        //The CVs created FROM FN are deleted at the end
        for (ContentVersion cv : cvList){
            if(String.valueOf(cv.FirstPublishLocationId).startsWith('500') || String.valueOf(cv.FirstPublishLocationId).startsWith('0WO')) continue;
            for(ContentDocumentLink cdl : cdLinkList){
                if(cdl.ContentDocumentId != cv.ContentDocumentId) continue;
                if((String.valueOf(cdl.LinkedEntityId).startsWith('500')) || (String.valueOf(cdl.LinkedEntityId).startsWith('0WO') && woMap.containsKey(cdl.LinkedEntityId))){
                    System.debug('cdl.LinkedEntityId-> ' + cdl.LinkedEntityId);
                    ContentVersion cvNew = new ContentVersion();
                    cvNew.OwnerId = UserInfo.getUserId();
                    cvNew.pathOnClient = cv.pathOnClient;
                    cvNew.versionData = cv.versionData;
                    cvNew.ContentLocation = cv.ContentLocation;
                    cvNew.ContentUrl = cv.ContentUrl;
                    cvNew.Description = cv.Description;
                    cvNew.ExternalDataSourceId = cv.ExternalDataSourceId;
                    cvNew.ExternalDocumentInfo1 = cv.ExternalDocumentInfo1;
                    cvNew.ExternalDocumentInfo2 = cv.ExternalDocumentInfo2;
                    if(String.valueOf(cdl.LinkedEntityId).startsWith('500')){
                        cvNew.FirstPublishLocationId = cdl.LinkedEntityId;
                    } else {
                        cvNew.FirstPublishLocationId = woMap.get(cdl.LinkedEntityId).CaseId;
                    }
                    listToInsert.add(cvNew);
                }
            }
        }
        System.debug('listToInsert Size-> ' + listToInsert.size());
        if(!listToInsert.isEmpty()){
            insert listToInsert;
            System.debug('cdList Size-> ' + cdList.size());
            if(!cdList.isEmpty()){
                Database.delete(cdList, false);
            }
        }
        Map<Id,ContentVersion> cvMap = new Map<Id,ContentVersion>();
        cvMap.putAll(listToInsert);
        return cvMap;
    }
}