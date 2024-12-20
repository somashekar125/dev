public without sharing class FslQuickActions {
    @AuraEnabled
    public static void populateCheckInTime(Id ServiceAppointmentId){
        System.debug('ServiceAppointmentId-> ' + ServiceAppointmentId);
        ServiceAppointment sa = [SELECT Id,ParentRecordId,Check_In_Time__c FROM ServiceAppointment WHERE Id =: ServiceAppointmentId];
        sa.Check_In_Time__c = System.now();
        update sa;
        if(sa.ParentRecordId != null && String.valueOf(sa.ParentRecordId).startsWith('0WO')){
            WorkOrder wo = new WorkOrder(Id = sa.ParentRecordId, Check_In_Time__c = sa.Check_In_Time__c);
            update wo;
        }
    }

    @AuraEnabled
    public static void populateCheckOutTime(Id ServiceAppointmentId){
        ServiceAppointment sa = [SELECT Id,ParentRecordId,Check_Out_Time__c FROM ServiceAppointment WHERE Id =: ServiceAppointmentId];
        sa.Check_Out_Time__c = System.now();
        update sa;
        if(sa.ParentRecordId != null && String.valueOf(sa.ParentRecordId).startsWith('0WO')){
            WorkOrder wo = new WorkOrder(Id = sa.ParentRecordId, Check_Out_Time__c = sa.Check_Out_Time__c);
            update wo;
        }
    }
}