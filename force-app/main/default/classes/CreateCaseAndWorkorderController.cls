public class CreateCaseAndWorkorderController {

    @AuraEnabled(cacheable=true)
    public static String getUserTimezone() {
        User currentUser = [SELECT TimeZoneSidKey FROM User WHERE Id = :UserInfo.getUserId()];
        System.debug('timezone '+currentUser.TimeZoneSidKey);
        return currentUser.TimeZoneSidKey;
    }
    
    @AuraEnabled
    public static List<Project_Account__c> getProjectAccounts(String recordId, String searchKeyFrom, String searchKeyTo){       
        List<Project_Account__c> projAccList = [SELECT Id, Name,Account__c,Account__r.ShippingStreet, Account__r.ShippingCity, Account__r.ShippingState, Account__r.ShippingCountry,Project__r.Description__c,
                                                Account__r.ShippingPostalCode,Project__c,Project__r.Service_Contract__c,Project__r.Support_Team__c,Project__r.Support_Team__r.Tech_Notes__c,Project__r.Tech_Notes__c,
                                                Project__r.Service_Contract__r.Visit_Order__c,Project__r.Service_Contract__r.Name,Visit_1__c,Visit_2__c,Visit_3__c,Quantity_of_Devices__c,(SELECT Id FROM Cases__r)
                                                FROM Project_Account__c WHERE Project__c =: recordId AND (Visit_1__c != null OR Visit_2__c !=null OR Visit_3__c !=null) ORDER BY Name];

        Map<Id, Project_Account__c> filteredProjAccMap = new Map<Id, Project_Account__c>();
        Boolean reachedSearchFromKey = false;
        for (Project_Account__c pa : projAccList) {
            if(String.isNotBlank(searchKeyFrom) || String.isNotBlank(searchKeyTo)) {
                if(String.isBlank(searchKeyFrom) && String.isNotBlank(searchKeyTo)) {
                    filteredProjAccMap.put(pa.Id, pa);
                }
                if(String.isNotBlank(searchKeyTo) && pa.Name.containsIgnoreCase(searchKeyTo)) {
                    filteredProjAccMap.put(pa.Id, pa);
                    break;
                }
                if(String.isNotBlank(searchKeyFrom) && pa.Name.containsIgnoreCase(searchKeyFrom)) {
                    filteredProjAccMap.put(pa.Id, pa);
                    reachedSearchFromKey = true;
                    continue;
                }
                if(reachedSearchFromKey) {
                    filteredProjAccMap.put(pa.Id, pa);
                    continue;
                }
            } else {
                filteredProjAccMap.put(pa.Id, pa);
            }
        }
        return new List<Project_Account__c>(filteredProjAccMap.values());
    }

    @AuraEnabled
    public static Boolean getServiceContract(String recordId){
        Boolean visitOrder = true;
        Project__c project = [SELECT Id, Name, Service_Contract__c, (SELECT Id, Name,Account__c FROM Project_Accounts__r) FROM Project__c WHERE Id =: recordId LIMIT 1];

        List<ServiceContract> childServiceContractList = [SELECT Id, Name, AccountId,Visit_Order__c, Priority__c,Country__c, Service_Type__c,ParentServiceContractId 
                                                          FROM ServiceContract WHERE ParentServiceContractId =:  project.Service_Contract__c];
        for(ServiceContract sc: childServiceContractList){
            if(sc.Visit_Order__c == null){
                visitOrder = false;
            }
        }
        return visitOrder;
    }

    @AuraEnabled
    public static Boolean getServiceContractVisitOrder(String recordId, List<Project_Account__c> selectedProjAccList) {
        Boolean isValid = true;
    
        Project__c project = [SELECT Id, Service_Contract__c, Service_Contract__r.Visit_Order__c FROM Project__c WHERE Id = :recordId LIMIT 1];
        if (project.Service_Contract__c != null) {
            List<ServiceContract> childServiceContractList = [SELECT Id, Name, AccountId,Visit_Order__c,ParentServiceContractId 
                                                              FROM ServiceContract WHERE ParentServiceContractId =:  project.Service_Contract__c];

                if(childServiceContractList.isEmpty()) {
                    if (project.Service_Contract__c == null || project.Service_Contract__r.Visit_Order__c == null) {
                        isValid = false;
                    } else {
                        String serviceContractVisitOrder = project.Service_Contract__r.Visit_Order__c;
            
                        for (Project_Account__c pa : selectedProjAccList) {
                            if (serviceContractVisitOrder == 'Visit 3' && pa.Visit_3__c == null) {
                                isValid = false; 
                                break;
                            } else if (serviceContractVisitOrder == 'Visit 2' && pa.Visit_2__c == null) {
                                isValid = false; 
                                break;
                            } else if (serviceContractVisitOrder == 'Visit 1' && pa.Visit_1__c == null) {
                                isValid = false; 
                                break;
                            }
                        }
                    }
                } else {
                    for(ServiceContract csc: childServiceContractList){
                        String childServiceContractVisitOrder = csc.Visit_Order__c;
                        for (Project_Account__c pa : selectedProjAccList) {
                            if (childServiceContractVisitOrder == 'Visit 3' && pa.Visit_3__c == null) {
                                isValid = false; 
                                break;
                            } else if (childServiceContractVisitOrder == 'Visit 2' && pa.Visit_2__c == null) {
                                isValid = false; 
                                break;
                            } else if (childServiceContractVisitOrder == 'Visit 1' && pa.Visit_1__c == null) {
                                isValid = false; 
                                break;
                            }
                        }
                    }
                }
        }
        
        return isValid;
    }
    
    @AuraEnabled
    public static List<Project_Account__c> searchProjectAccounts(String searchKey, String recordId) {
        Map<Id,Project_Account__c> projAccMap = new Map<Id,Project_Account__c>();
        searchKey = searchKey + '%';
        String searchKey2 = '%' + searchKey + '%';
        List<Project_Account__c> accList = [SELECT Id, Name, Account__c, Project__c,Project__r.Service_Contract__c, Visit_1__c,Visit_2__c,Visit_3__c,Quantity_of_Devices__c FROM Project_Account__c WHERE Project__c =: recordId AND Name LIKE :searchKey ORDER BY Name];
        List<Project_Account__c> accList2 = [SELECT Id, Name, Account__c, Project__c,Project__r.Service_Contract__c,Visit_1__c,Visit_2__c,Visit_3__c,Quantity_of_Devices__c FROM Project_Account__c WHERE Project__c =: recordId AND Name LIKE :searchKey2 ORDER BY Name];
        projAccMap.putAll(accList);
        projAccMap.putAll(accList2);
        return projAccMap.values();
    }

    @AuraEnabled
    public static void createCaseAndWorkorderRecords(String recordId, List<Project_Account__c> projAccList) {
        System.debug('recordId->' + recordId);
        List<Case> csList = new List<Case>();
        Project__c project = [SELECT Id, Name, Service_Contract__c, (SELECT Id, Name, Account__c,Quantity_of_Devices__c FROM Project_Accounts__r) FROM Project__c WHERE Id = :recordId LIMIT 1];

        if (project.Service_Contract__c != null) {
            ServiceContract serviceContract = [SELECT Id, Name, AccountId, Priority__c, Country__c, Visit_Order__c, Service_Type__c,
                                            (SELECT Id, Product2Id, Product2.Name, Quantity, Product_Family__c, Exclude_From_Service_Products__c 
                                                FROM ContractLineItems WHERE Exclude_From_Service_Products__c = false AND Product_Family__c = 'Hardware' AND Product2.IsActive = true AND Product2.Source_Key__c != null) 
                                            FROM ServiceContract WHERE Id = :project.Service_Contract__c LIMIT 1];

            List<ServiceContract> childServiceContractList =[SELECT Id, Name, AccountId, Priority__c, Country__c, Service_Type__c, ParentServiceContractId,
                                                            (SELECT Id, Product2Id, Product2.Name, Quantity, Product_Family__c, Exclude_From_Service_Products__c 
                                                            FROM ContractLineItems WHERE Exclude_From_Service_Products__c = false AND Product_Family__c = 'Hardware' AND Product2.IsActive = true AND Product2.Source_Key__c != null) 
                                                            FROM ServiceContract WHERE ParentServiceContractId =: project.Service_Contract__c];

            Map<Id,Decimal> projAccQuantityMap = new  Map<Id,Decimal>();
            System.debug('Service->' + JSON.serialize(serviceContract));
            for (Project_Account__c projectAccount : projAccList) {
                if(projectAccount.Quantity_of_Devices__c != null){
                    projAccQuantityMap.put(projectAccount.Id, projectAccount.Quantity_of_Devices__c);
                }
                Case newCase = new Case();
                newCase.Root_Account__c = serviceContract.AccountId;
                newCase.Priority = serviceContract.Priority__c != null ? serviceContract.Priority__c : 'Severity 3';
                if (childServiceContractList.isEmpty()) {
                    if (projectAccount.Visit_3__c != null && serviceContract.Visit_Order__c == 'Visit 3') {
                        newCase.Preferred_Time__c = projectAccount.Visit_3__c;
                    } else if (projectAccount.Visit_2__c != null && serviceContract.Visit_Order__c == 'Visit 2') {
                        newCase.Preferred_Time__c = projectAccount.Visit_2__c;
                    } else if (projectAccount.Visit_1__c != null && serviceContract.Visit_Order__c == 'Visit 1') {
                        newCase.Preferred_Time__c = projectAccount.Visit_1__c;
                    }
                } else {
                    newCase.Preferred_Time__c = null;
                }
                newCase.Service_Type__c = serviceContract.Service_Type__c;
                newCase.ServiceContractId = serviceContract.Id;
                newCase.AccountId = projectAccount.Account__c;
                newCase.Project__c = project.Id;
                newCase.Status = 'New';
                newCase.Project_Account__c = projectAccount.Id;
                if(projectAccount.Project__r.Support_Team__c != null) {
                    newCase.Support_Team__c = projectAccount.Project__r.Support_Team__c;
                    newCase.Tech_Notes__c = projectAccount.Project__r.Support_Team__r.Tech_Notes__c;
                } else {
                    newCase.Tech_Notes__c = projectAccount.Project__r.Tech_Notes__c;
                }
                newCase.Description = projectAccount.Project__r.Description__c;
                newCase.Incident__c = 'TEST';
                csList.add(newCase);
            }

            if (!csList.isEmpty()) {
                Integer batchSize = 30;
                for (Integer i = 0; i < csList.size(); i += batchSize) {
                    Integer endIndex = Math.min(i + batchSize, csList.size());
                    List<Case> batch = new List<Case>();
                    for (Integer j = i; j < endIndex; j++) {
                        batch.add(csList[j]);
                    }
                    
                    System.debug('projAccQuantityMap-->'+ projAccQuantityMap);
                    System.enqueueJob(new CaseProcessor(batch, project.Id, JSON.serialize(serviceContract),childServiceContractList,projAccQuantityMap));
                }
                System.debug('Cases inserted: ' + JSON.serialize(csList));
            }
        }
    }

}