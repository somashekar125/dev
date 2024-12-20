public class AssetInspectionFilesUpload {
	@auraEnabled
    public static List<ContentDocumentLink> getFiles(String recId, String inspectType){
        System.debug('recId:'+recId+':inspectType:'+inspectType);
        return [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: recId and ContentDocument.Title Like : inspectType+'%'];
    }
    @AuraEnabled
    public static void updateFileNames(List<String> documentIds, String inspectionType){
        System.debug('documentIds:'+documentIds+':inspectionType:'+inspectionType);
        List<ContentDocument> cdList = [SELECT Id, Title FROM ContentDocument WHERE Id IN : documentIds];
        for(ContentDocument cd : cdList){
            cd.Title = inspectionType+'_'+cd.Title;
        }
        if(!cdList.isEmpty()){
            update cdList;
        }
    }
    @AuraEnabled
    public static WorkOrderLineItem getWOLI(String woliId){
        return [SELECT Id,Status FROM WorkOrderLineItem WHERE Id =:woliId];
    }
}