public without sharing class InstallationStatusPath {
    @AuraEnabled
    public static void getWO(String woId){
        WorkOrder wo = [SELECT Id,Installation_Status__c FROM WorkOrder WHERE Id =:woId];
        update wo;
    }
}