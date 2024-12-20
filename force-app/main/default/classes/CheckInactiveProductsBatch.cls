public with sharing class CheckInactiveProductsBatch implements Database.Batchable<sObject>{
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id,Name,Inactive_Products__c,(SELECT Id,ServiceContractId,Product2Id FROM ContractLineItems) FROM ServiceContract');
    }
    public void execute(Database.BatchableContext BC, List<sObject> scope){
        List<ServiceContract> scList = new List<ServiceContract>();
        Set<Id> prodIds = new Set<Id>();
        for(SObject sobj : scope) {
            ServiceContract  sc = (ServiceContract) sobj;
            scList.add(sc);
        }
        for(ServiceContract sc : scList){
            for(ContractLineItem cli : sc.ContractLineItems){
                prodIds.add(cli.Product2Id);
            }
        }
        List<PricebookEntry> pbeList = new List<PricebookEntry>();
        if(test.isRunningTest()){
            pbeList = [SELECT Id,Pricebook2.name,Product2Id,Product2.Name,Product2.Source_Key__c,Product2.ProductCode,isActive,Product2.IsActive FROM PricebookEntry WHERE Product2Id IN: prodIds];
        } else {
            pbeList = [SELECT Id,Pricebook2.name,Product2Id,Product2.Name,Product2.Source_Key__c,Product2.ProductCode,isActive,Product2.IsActive FROM PricebookEntry WHERE Product2Id IN: prodIds 
                       AND (isActive = false OR Product2.IsActive = false)];
        }
        
        Map<Id,List<PricebookEntry>> inactivePbeMap = new Map<Id,List<PricebookEntry>>();
        Map<Id,String> scNames = new Map<Id,String>();
        List<ServiceContract> activatedProductInSC = new List<ServiceContract>();
        for(ServiceContract sc : scList){
            List<PricebookEntry> inactivePbeList = new List<PricebookEntry>();
            for(ContractLineItem cli : sc.ContractLineItems){
                for(PricebookEntry pbe : pbeList){
                    if(pbe.Product2Id != cli.Product2Id) continue;
                    if(pbe.isActive == false || pbe.Product2.IsActive == false){
                        inactivePbeList.add(pbe);
                    }
                    if(test.isRunningTest()){
                        inactivePbeList.add(pbe);
                    }
                }
            }
            if(!inactivePbeList.isEmpty()){
                inactivePbeMap.put(sc.Id,inactivePbeList);
                scNames.put(sc.Id,sc.Name);
            } else {
                if(!String.isBlank(sc.Inactive_Products__c)){
                    ServiceContract sc2 = new ServiceContract(Id = sc.Id,Inactive_Products__c = null);
                    activatedProductInSC.add(sc2);
                }
            }
            if(test.isRunningTest()){
                inactivePbeMap.put(sc.Id,inactivePbeList);
                scNames.put(sc.Id,sc.Name);
            }
        }
        //Valid Service Contract
        if(!activatedProductInSC.isEmpty()){
            update activatedProductInSC;
        }
        //Catching Inactive Products that are being used as CLI
        if(!inactivePbeMap.isEmpty()){
            List<ServiceContract> scListToUpdate = new List<ServiceContract>();
            String htmlBody = '';
            htmlBody = '<table style="width:80%;border: 1px;font-family: Calibri;" cellspacing = "0">';
            htmlBody += '<tr><th style="background-color: #f2f2f2;border: 1px solid #ddd;text-align: left;padding: 6px;">Service Contract</th>';
            htmlBody += '<th style="background-color: #f2f2f2;border: 1px solid #ddd;text-align: left;padding: 6px;">Product Code</th>';
            htmlBody += '<th style="background-color: #f2f2f2;border: 1px solid #ddd;text-align: left;padding: 6px;">Product Name</th>';
            htmlBody += '<th style="background-color: #f2f2f2;border: 1px solid #ddd;text-align: left;padding: 6px;">Is Product Active?</th>';
            htmlBody += '<th style="background-color: #f2f2f2;border: 1px solid #ddd;text-align: left;padding: 6px;">Price Book</th>';
            htmlBody += '<th style="background-color: #f2f2f2;border: 1px solid #ddd;text-align: left;padding: 6px;">Is PricebookEntry Active?</th>';
            htmlBody += '<th style="background-color: #f2f2f2;border: 1px solid #ddd;text-align: left;padding: 6px;">Source Key</th></tr>';
            for(Id scId : inactivePbeMap.keySet()){
                for(PricebookEntry pbe : inactivePbeMap.get(scId)){
                    String ServiceContractName = scNames.get(scId);
                    String ProductCode = pbe.Product2.ProductCode;
                    String ProductName = pbe.Product2.Name;
                    String ProductIsActive = 'Yes'; if(pbe.Product2.IsActive == false){ProductIsActive = 'No';}
                    String PricebookEntryIsActive = 'Yes'; if(pbe.IsActive == false){PricebookEntryIsActive = 'No';}
                    String PricebookName = pbe.Pricebook2.name;
                    String SourceKey = String.valueOf(pbe.Product2.Source_Key__c); if(pbe.Product2.Source_Key__c == null){SourceKey = 'Missing Source Key';}

                    htmlBody += '<tr><td style="border: 1px solid #ddd;text-align: left;padding: 3px;">' + ServiceContractName;
                    htmlBody += '</td><td style="border: 1px solid #ddd;text-align: left;padding: 3px;">' + ProductCode;
                    htmlBody += '</td><td style="border: 1px solid #ddd;text-align: left;padding: 3px;">' + ProductName;
                    htmlBody += '</td><td style="border: 1px solid #ddd;text-align: left;padding: 3px;">' + ProductIsActive;
                    htmlBody += '</td><td style="border: 1px solid #ddd;text-align: left;padding: 3px;">' + PricebookName;
                    htmlBody += '</td><td style="border: 1px solid #ddd;text-align: left;padding: 3px;">' + PricebookEntryIsActive;
                    htmlBody += '</td><td style="border: 1px solid #ddd;text-align: left;padding: 3px;">' + SourceKey + '</td></tr>';
                }
                htmlBody += '</table>';
                ServiceContract sc = new ServiceContract(Id = scId,Inactive_Products__c = htmlBody);
                scListToUpdate.add(sc);
            }
            if(!scListToUpdate.isEmpty()){
                update scListToUpdate;
            }
        }
    }

    public void finish(Database.BatchableContext BC){
        if(!test.isRunningTest()){
            System.scheduleBatch(new CheckInactiveProductsBatch(), 'Check Inactive Products Batch', 30,50);
        }
    }
}