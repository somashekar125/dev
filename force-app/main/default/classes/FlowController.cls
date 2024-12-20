public class FlowController {
    @InvocableMethod(label='Insert WOLIs' description='Inserts the WOLIs for Hardware Products.')
    public static void createHardwareWOLIs(List<Id> workOrderIds) {
        Set<Id> woIds = new Set<Id>(workOrderIds);
        Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>([SELECT Id,ParentWorkOrderId,CaseId,Case.Staging_Required_Count__c,
                                                           RecordTypeId,ServiceContractId,ServiceContract.Name, Pricebook2Id,
                                                           Case.Root_Account__r.Staging_Product__r.Name 
                                                           FROM WorkOrder WHERE Id IN :woIds AND Additional_Part_WO__c = false 
                                                           AND Record_Type_Name__c != 'Onsite Labor']);
        System.debug('woMap size -> ' + woMap.size());
        Set<Id> caseIds = new Set<Id>();
        Set<Id> svcIds = new Set<Id>();
        for(WorkOrder wo : woMap.values()) {
            caseIds.add(wo.caseId);
            svcIds.add(wo.ServiceContractId);
        }
        Map<Id,Case> cMap =  new Map<Id, Case>([SELECT Id,ServiceContract.Single_WO_For_Billing__c,Account.ShippingCountry,Root_Account__c,ServiceContractId,
                                                (SELECT Product__c,Product__r.Name, Quantity__c,CLI_Product__c FROM Case_Products__r) FROM Case
                                                WHERE Id IN :caseIds]);
        Set<Id> caseProdIds = new Set<Id>();
        for(Case c : cMap.values()) {
            for(Case_Product__c cp : c.Case_Products__r) {
                caseProdIds.add(cp.Product__c);
            }
        }
        List<Product_Bundle__c> prodBundleList = [SELECT Child_Product__c FROM Product_Bundle__c];
        for(Product_Bundle__c pb : prodBundleList){
            if(caseProdIds.contains(pb.Child_Product__c)){
                //caseProdIds.remove(pb.Child_Product__c);
            }
        }
        System.debug('caseProdIds: '+caseProdIds);
        Map<Id,ServiceContract> scMap = new Map<Id,ServiceContract>([SELECT Id,(SELECT Id,Product2Id,Product2.Family,Product2.Name,Description,
                                                                     Product2.Description,UnitPrice,Quantity,ServiceContractId FROM ContractLineItems 
                                                                     WHERE Product2.Family = 'Hardware') FROM ServiceContract WHERE ID IN:svcIds]);
        List<PricebookEntry> pbeList = [SELECT Id,isActive,Product2Id,Pricebook2Id,Product2.Name,Product2.Description,UnitPrice,Product2.Staging_Required__c 
                                        FROM PricebookEntry  WHERE Product2Id IN :caseProdIds AND isActive = true AND Product2.source_key__c != null];
        List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
        Set<Id> woStagingCountSet = new Set<Id>();
        Map<Id, Set<Id>> woIdProdIdMap = new Map<Id, Set<Id>>();
        for(WorkOrder wo : woMap.values()) {
            if(wo.RecordTypeId != Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Part_Shipment').getRecordTypeId() &&
                wo.RecordTypeId != Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Production').getRecordTypeId()) continue;
            Case c = cMap.get(wo.CaseId);
            Id woId = wo.Id;
            Id childWO;
            if(wo.ParentWorkOrderId != null && c.ServiceContract.Single_WO_For_Billing__c == true){
                woId = wo.ParentWorkOrderId;
                childWO = wo.Id;
            }
            System.debug('wo.ServiceContract.Name-> ' + wo.ServiceContract.Name);
            List<ContractLineItem> cliList = scMap.get(wo.ServiceContractId).ContractLineItems;
            System.debug('cliList size-> ' + cliList.size());
            System.debug('c.Case_Products__r size-> ' + c.Case_Products__r.size());
            System.debug('cliList-> ' + JSON.Serialize(cliList));
            System.debug('c.Case_Products__r-> ' + JSON.Serialize(c.Case_Products__r));
            Set<Id> prodIds = new Set<Id>();
            for(ContractLineItem cli : cliList){
                for(Case_Product__c cp : c.Case_Products__r) {
                    System.debug('Processing CLI Hardware: '+cp.Product__r.Name);
                    for(PricebookEntry pbe : pbeList) {
                        if(pbe.Pricebook2Id != wo.Pricebook2Id) continue;
                        if(cli.Product2Id != cp.Product__c) continue;
                        if(cp.Product__c != pbe.Product2Id) continue;
                        if(prodIds.contains(cp.Product__c)) continue;

                        Decimal price = pbe.UnitPrice;
                        String description = cli.Product2.Description;
                        if(cli.UnitPrice != null && cli.UnitPrice != 0){
                            price = cli.UnitPrice;
                        }
                        if(String.isNotBlank(cli.Description)){
                            description = cli.Description;
                        }
                        System.debug('PBE Product: '+pbe.Product2.Name);
                        System.debug('cp.Product__r.Name: ' + cp.Product__r.Name);
                        System.debug('cli.Product2.Name: ' + cli.Product2.Name);
                        System.debug('Different product? -> ' + (cli.Product2Id != cp.Product__c && cp.Product__c != pbe.Product2Id));
                        WorkOrderLineItem woli = new WorkOrderLineItem(PricebookEntryId = pbe.Id,UnitPrice = price,Quantity = cp.Quantity__c, WorkOrderId = woId,Description = description,Child_WO__c = childWO);
                        woliList.add(woli);
                        System.debug('woliList From CLI-> ' + JSON.Serialize(woliList));
                        prodIds.add(cp.Product__c);
                        woIdProdIdMap.put(woId, prodIds);
                        break;
                    }
                }
            }
        }
        //WOLIs for manually added products
        for(WorkOrder wo : woMap.values()) {
            if(wo.RecordTypeId != Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Part_Shipment').getRecordTypeId() &&
                wo.RecordTypeId != Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Production').getRecordTypeId()) continue;
            Case c = cMap.get(wo.CaseId);
            Id woId = wo.Id;
            Id childWO;
            if(wo.ParentWorkOrderId != null && c.ServiceContract.Single_WO_For_Billing__c == true){
                woId = wo.ParentWorkOrderId;
                childWO = wo.Id;
            }
            if(!c.Case_Products__r.isEmpty()){
                for(Case_Product__c cp : c.Case_Products__r) {
                    if(cp.CLI_Product__c) continue;
                    System.debug('Processing Case Product: '+cp.Product__r.Name);
                    for(PricebookEntry pbe : pbeList) {
                        System.debug('PBE Product: '+pbe.Product2.Name);
                        System.debug('cp.Product__r.Name: ' + cp.Product__r.Name);
                        System.debug(cp.Product__c+' : '+pbe.Product2Id);
                        System.debug('Different Product? -> ' + (cp.Product__c != pbe.Product2Id));
                        if(pbe.Pricebook2Id != wo.Pricebook2Id) continue;
                        if(cp.Product__c != pbe.Product2Id) continue;
                        if(woIdProdIdMap.get(woId) == null) {
                            Set<Id> prodIds = new Set<Id>();
                            woIdProdIdMap.put(woId, prodIds);
                        }
                        if(woIdProdIdMap.get(woId).contains(cp.Product__c)) continue;
                        woIdProdIdMap.get(woId).add(cp.Product__c);

                        WorkOrderLineItem woli = new WorkOrderLineItem(PricebookEntryId = pbe.Id, Quantity = cp.Quantity__c,UnitPrice = pbe.UnitPrice, WorkOrderId = woId,Child_WO__c = childWO, Description = pbe.Product2.Description);
                        woliList.add(woli);
                        System.debug('woliList From Case Product-> ' + JSON.Serialize(woliList));
                        break;
                    }
                }
            }
        }
        //Staging WOLI
        for(WorkOrder wo : woMap.values()) {
            if(wo.Case.Staging_Required_Count__c > 0) {
                System.debug('Staging product-> ' + wo.Case.Root_Account__r.Staging_Product__r.Name);
                Case c = cMap.get(wo.CaseId);
                Id woId = wo.Id;
                Id childWO;
                if(wo.ParentWorkOrderId != null && c.ServiceContract.Single_WO_For_Billing__c == true){
                    woId = wo.ParentWorkOrderId;
                    childWO = wo.Id;
                }
                if(String.isNotBlank(wo.Case.Root_Account__r.Staging_Product__r.Name)) {
                    List<PricebookEntry> stagingPBEList = [SELECT Id,Product2Id,UnitPrice,Product2.Description FROM PricebookEntry 
                                                           WHERE Product2.Staging_Required__c = true AND PriceBook2Id =: wo.PriceBook2Id AND 
                                                           Product2.Name = :wo.Case.Root_Account__r.Staging_Product__r.Name AND isActive = true AND Product2.source_key__c != null];
                    if(!stagingPBEList.isEmpty()) {
                        //if(!woIdProdIdMap.contains(stagingPBEList[0].Product2Id)){}
                        WorkOrderLineItem woli = new WorkOrderLineItem(PricebookEntryId = stagingPBEList[0].Id, Quantity = wo.Case.Staging_Required_Count__c,UnitPrice = stagingPBEList[0].UnitPrice, WorkOrderId = woId,Child_WO__c = childWO, Description = stagingPBEList[0].Product2.Description);
                        woliList.add(woli);
                        System.debug('Staging woli added-> ' + JSON.Serialize(woliList));
                    }
                }
            }
        }
        System.debug('Flow Controller : woliList size-> ' + woliList.size());
        System.debug('Flow Controller : woliList-> ' + JSON.Serialize(woliList));
        Database.insert(woliList, false);
    }
}