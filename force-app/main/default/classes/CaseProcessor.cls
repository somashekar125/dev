public class CaseProcessor implements Queueable {
    private List<Case> casesToProcess;
    private Id projectId;
    private String serviceContractJson;
    private List<ServiceContract> childServiceContractList;
    private Map<Id,Decimal> projAccQuantityMap;
    public CaseProcessor(List<Case> casesToProcess, Id projectId, String serviceContractJson, List<ServiceContract> childServiceContractList, Map<Id,Decimal> projAccQuantityMap) {
        this.casesToProcess = casesToProcess;
        this.projectId = projectId;
        this.serviceContractJson = serviceContractJson;
        this.childServiceContractList = childServiceContractList;
        this.projAccQuantityMap = projAccQuantityMap;
    }

    public void execute(QueueableContext context) {
        Boolean success = false;
        Integer retries = 3;
        System.debug('test');

        while (!success && retries > 0) {
            try {
                List<Case_Product__c> caseProductsToCreate = new List<Case_Product__c>();
                ServiceContract serviceContract = (ServiceContract)JSON.deserialize(serviceContractJson, ServiceContract.class);
                
                insert casesToProcess;

                for (Case c : casesToProcess) {
                    for (ContractLineItem cli : serviceContract.ContractLineItems) {
                        Case_Product__c newCaseProduct = new Case_Product__c();
                        newCaseProduct.Case__c = c.Id;
                        newCaseProduct.Product__c = cli.Product2Id;
                        newCaseProduct.Name = cli.Product2.Name;
                        if (cli.Product2.Name.length() > 80) {
                            newCaseProduct.Case_Product_Full_Name__c = cli.Product2.Name;
                            newCaseProduct.Name = cli.Product2.Name.substring(0, 79);
                        }
                        if(projAccQuantityMap.containsKey(c.Project_Account__c)) {
                            newCaseProduct.Quantity__c = (cli.Quantity != null && cli.Quantity != 0) ? projAccQuantityMap.get(c.Project_Account__c) * cli.Quantity : projAccQuantityMap.get(c.Project_Account__c);
                        } else {
                            newCaseProduct.Quantity__c = cli.Quantity;
                        }
                        caseProductsToCreate.add(newCaseProduct);
                    }
                }

                for (ServiceContract childContract : childServiceContractList) {
                    for (Case c : casesToProcess) {
                        for (ContractLineItem cli : childContract.ContractLineItems) {
                            Case_Product__c newCaseProduct = new Case_Product__c();
                            newCaseProduct.Case__c = c.Id;
                            newCaseProduct.Product__c = cli.Product2Id;
                            newCaseProduct.Name = cli.Product2.Name;
                            if (cli.Product2.Name.length() > 80) {
                                newCaseProduct.Case_Product_Full_Name__c = cli.Product2.Name;
                                newCaseProduct.Name = cli.Product2.Name.substring(0, 79);
                            }
                            if(projAccQuantityMap.containsKey(c.Project_Account__c)) {
                                newCaseProduct.Quantity__c = projAccQuantityMap.get(c.Project_Account__c);
                            } else {
                                newCaseProduct.Quantity__c = cli.Quantity;
                            }
                            caseProductsToCreate.add(newCaseProduct);
                        }
                    }
                }

                if (!caseProductsToCreate.isEmpty()) {
                    insert caseProductsToCreate;
                }
              for (Case caseToUpdate : casesToProcess) {
                    caseToUpdate.Create_Work_Order__c = true;
                }

                update casesToProcess;

                success = true;
            } catch (Exception e) {
                retries--;
                if (retries == 0) {
                    throw e;
                }
            }
        }
    }
}