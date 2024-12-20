public with sharing class ProjectProductTriggerHandler {
    public static void duplicateCheckPrimaryProduct(List<Project_Product__c> projectProductList){
        Set<Id> projectIDs = new Set<Id>();
        for(Project_Product__c pp: projectProductList){
            if(!pp.Primary_Product__c) continue;
            projectIDs.add(pp.Project__c);
        }
        List<Project__c> projectList = [SELECT Id, Name, (SELECT Id, Name FROM Project_Products__r WHERE Primary_Product__c = TRUE) FROM project__c WHERE Id IN: projectIDs];
        for(Project_Product__c pp: projectProductList){
            for(Project__c proj : projectList){
                if(proj.ID==pp.project__c && proj.Project_Products__r.size()>0){
                    pp.addError('Primary product for this project is already set.');
                }
            }
        }
    }
    
}