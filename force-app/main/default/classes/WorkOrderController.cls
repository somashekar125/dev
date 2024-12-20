public without sharing class WorkOrderController {
@Future
public static void createWOThroughServiceContract(String csMapStr){
    // we are having so many quaries so to avoid dml governar limit exception we are using future methode.
    Map<Id, Case> csMap = (Map<Id, Case>) JSON.deserialize(csMapStr, Map<Id, Case>.class);
    Set<String> countryNames = new Set<String>();
    Set<ID> scIds = new Set<ID>();
    for (Case c: csMap.values()) {
        scIds.add(c.ServiceContractId);
        countryNames.add(c.Country__c);
    }
    Set<Id> allProdIds = new Set<Id>();
    // query for case products
    Map<Id, List<Case_Product__c>> csProductMap = new Map<Id, List<Case_Product__c>>();
    List<Case_Product__c> csProducts = [SELECT Id, Product__c, Case__c, Product__r.Name, Quantity__c, CLI_Product__c  
                                        FROM Case_Product__c WHERE Case__c IN :csMap.keySet()];
    for (Case c: csMap.values()) {
        List<Case_Product__c> cpList = new List<Case_Product__c>();
        for(Case_Product__c cp : csProducts){
            if(cp.Case__c != c.Id) continue;
            cpList.add(cp);
            allProdIds.add(cp.Product__c);
        }
        if(!cpList.isEmpty()) csProductMap.put(c.Id, cpList);
    }
    // quary for all service contrects including contract line items and child service contract id
    Map<Id, ServiceContract> scMap = new Map<Id, ServiceContract>();
    Map<Id, ServiceContract> ChildServiceContractMap = new Map<Id, ServiceContract>();
    if(!scIds.isEmpty()) {
        scMap = new Map<Id, ServiceContract>(
            [SELECT Id, Name, AccountId, Account.Staging_Product__c, ApprovalStatus, Country__c,Create_Work_Order_For__c, CreatedDate, 
                Number_Of_Technicians__c, Pricebook2Id, Priority__c, Schedulable__c, Service_Type__c,
                Single_WO_For_Billing__c, Status, TotalPrice, Work_Order_Record_Type__c, FN_Template_ID__c, 
                (SELECT Id,Account.Staging_Product__c FROM ChildServiceContracts WHERE Status = 'Active'), 
                (
                    SELECT Id, Product2Id, Quantity, UnitPrice, PricebookEntry.Product2Id, PricebookEntry.Product2.Name, 
                        PricebookEntry.Product2.Family, PricebookEntry.Product2.Description, Product_Family__c, Priority__c, 
                        Number_Of_Technicians__c, Exclude_From_Service_Products__c, Include_In_WO_Type__c, Out_of_Scope_CLI__c,
                        Applicable_on_Days__c, PricebookEntryId, Description, Applicable_If_IMAC_Due_Hours_Within__c,
                        Applicable_If_IMAC_Due_Hours_Exceeding__c, Applicable_After_Total_Hours__c, Work_Order_Record_Type__c 
                    FROM ContractLineItems WHERE Exclude_From_Service_Products__c = false
                ) 
            FROM ServiceContract WHERE Id IN :scIds AND Status = 'Active' AND Include_in_Service_Type_Picklist__c = true
            ]);
        // quary for all child service contracts including contract line items
        ChildServiceContractMap = new Map<Id, ServiceContract>(
            [SELECT Id, Name, ParentServiceContractId, AccountId, Account.Staging_Product__c, BillingAddress, Country__c, Pricebook2Id, 
                Create_Work_Order_For__c, Number_Of_Technicians__c, Priority__c, Schedulable__c, Service_Type__c, 
                Include_Part__c, Single_WO_For_Billing__c, Work_Order_Record_Type__c, FN_Template_ID__c, 
                (
                    SELECT Id, Product2Id, Quantity, UnitPrice, Product_Family__c, Priority__c, PricebookEntry.Product2Id, Out_of_Scope_CLI__c,
                    Include_In_WO_Type__c, PricebookEntry.Product2.Family, PricebookEntry.Product2.Description, Number_Of_Technicians__c, 
                    Exclude_From_Service_Products__c, Applicable_on_Days__c, PricebookEntryId, Applicable_If_IMAC_Due_Hours_Within__c, 
                    Applicable_If_IMAC_Due_Hours_Exceeding__c, Description, Applicable_After_Total_Hours__c, Work_Order_Record_Type__c, 
                    PricebookEntry.Product2.Name FROM ContractLineItems WHERE Exclude_From_Service_Products__c = false
                ) 
            FROM ServiceContract WHERE ParentServiceContractId IN :scMap.keySet() AND Status = 'Active'
            ]);
    }
    Map<Id,List<ServiceContract>> parentChildSCMap = new Map<Id, List<ServiceContract>>();
    for(ServiceContract sc : scMap.values()){
        allProdIds.add(sc.Account.Staging_Product__c);
        List<ServiceContract> scList = new List<ServiceContract>();
        for(ServiceContract sc2 : sc.ChildServiceContracts){
            if(!ChildServiceContractMap.containsKey(sc2.Id)) continue;
            scList.add(ChildServiceContractMap.get(sc2.Id));
        }
        if(!scList.isEmpty()) parentChildSCMap.put(sc.Id,scList);
    }
    // quary for work order scheduled
    List<WorkOrder_Schedule__c> woScheduleList = [
        SELECT
            Id, Name, Case__c, Preferred_Time__c, Product__c
        FROM WorkOrder_Schedule__c
        WHERE Case__c IN :csMap.keySet()
    ];
    // record type
    Id partShipId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Part_Shipment').getRecordTypeId();
    Id onsiteLaborId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Onsite_Labor').getRecordTypeId();

    // quary for Pricebook based on countryName
    List<Pricebook2> pbList = [
        SELECT
            Id, Name, Country__c, IsActive, IsStandard
        FROM Pricebook2
        WHERE isActive = true AND Country__c IN :countryNames
    ];

    Map<String, Id> countryPBMap = new Map<String, Id>();
    for(Pricebook2 pb: pbList){
        countryPBMap.put(pb.Country__c, pb.Id);
    }
    for(Case c : csMap.values()){
        if(!scMap.containsKey(c.ServiceContractId)) continue;
        ServiceContract parentSC = scMap.get(c.ServiceContractId);
        List<ServiceContract> scList = new List<ServiceContract>();
        scList.add(parentSC);
        for (List<ServiceContract> scList1 : parentChildSCMap.values()) {
            if(scList1 == null) continue;
            scList.addAll(scList1);
        }
        for(ServiceContract sc : scList){
            for(ContractLineItem cli : sc.ContractLineItems){
                allProdIds.add(cli.Product2Id);
            }
        }
    }

    // quary for PricebookEntry based on countryname and pricebookid
    Map<Id, PricebookEntry> pbeMap = new Map<Id, PricebookEntry>(
        [SELECT Id, IsActive, UnitPrice, Pricebook2Id, Product2Id, Product2.Name, Product2.Description, Product2.Staging_Required__c 
        FROM PricebookEntry WHERE Pricebook2Id IN :countryPBMap.values() AND Product2Id IN :allProdIds AND IsActive = true 
        AND Product2.Source_Key__c != null]);
    Map<Id, Map<Id,Id>> pbProdPbeMap = new Map<Id, Map<Id,Id>>();
    for(Pricebook2 pb: pbList){
        Map<Id,Id> prodPbeMap = new Map<Id,Id>();
        for(PricebookEntry pbe: pbeMap.values()){
            if(pb.Id != pbe.Pricebook2Id) continue;
            System.debug('pbe.Product2.Name-> ' + pbe.Product2.Name);
            prodPbeMap.put(pbe.Product2Id, pbe.Id);
        }
        pbProdPbeMap.put(pb.Id, prodPbeMap);
        System.debug('pbProdPbeMap-> ' + JSON.serialize(pbProdPbeMap));
    }

    Map<WorkOrder, List<WorkOrder>> parentChildWOMap = new Map<WorkOrder, List<WorkOrder>>();
    List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
    Integer temp = 1;
    for(Case c: csMap.values()) {
        if(!scMap.containsKey(c.ServiceContractId)) continue;
        Boolean masterWO = true;
        String netSuitId = (!String.isBlank(c.Incident__c) && c.Incident__c.containsIgnoreCase('Test')) ? 'TEST CASE' : '';
        ServiceContract parentSC = scMap.get(c.ServiceContractId);
        List<ServiceContract> scList = new List<ServiceContract>();
        if(!parentSC.ChildServiceContracts.isEmpty() && parentChildSCMap.containsKey(parentSC.Id)){
            scList.addAll(parentChildSCMap.get(parentSC.Id));
        } else{
            scList.add(parentSC);
        }
        Boolean isApproved = false;
        String woStatus = 'New';
        for(ServiceContract sc : scList){
            isApproved = false;
            woStatus = 'New';
            if(sc.Service_Type__c == 'Part Return') {
                woStatus = 'Approved';
                isApproved = true;
            }
            List<ContractLineItem> cliList = sc.ContractLineItems;
            if(sc.Create_Work_Order_For__c == 'Service Contract') {
                Id rtId;
                if(sc.Work_Order_Record_Type__c == 'Onsite Labor'){
                    rtId = onsiteLaborId;
                } else if(sc.Work_Order_Record_Type__c == 'Part Shipment'){
                    rtId = partShipId;
                }
                Map<Boolean, Map<WorkOrder, List<WorkOrder>>> masterWOParentChildWOMap = createWOforServiceContract(parentSC, 
                    parentChildWOMap, c, sc, woScheduleList, rtId, countryPBMap, masterWO, woStatus, isApproved);
                parentChildWOMap.putAll(masterWOParentChildWOMap.values()[0]);
                Set<Boolean> masterWOSet = masterWOParentChildWOMap.keySet();
                for(Boolean i : masterWOSet) {
                    masterWO = i;
                    break;
                }
            } else if(sc.Create_Work_Order_For__c =='Contract Line Item'){
                Map<Id,Id> productPBEMap = new Map<Id, Id>();

                if(pbProdPbeMap.containsKey(sc.Pricebook2Id)) productPBEMap.putAll(pbProdPbeMap.get(sc.Pricebook2Id));
                System.debug('productPBEMap-->'+JSON.serialize(productPBEMap));
                Map<Boolean, Map<Integer, Map<Map<WorkOrder, List<WorkOrder>>, List<WorkOrderLineItem>>>> masterWOIndexJoinMap = 
                    createWOforContractLineItem(parentSC, parentChildWOMap, woliList, cliList, sc, c, productPBEMap, woScheduleList, 
                    pbeMap, countryPBMap, onsiteLaborId, partShipId, temp, masterWO, woStatus, isApproved);

                Map<Integer, Map<Map<WorkOrder, List<WorkOrder>>, List<WorkOrderLineItem>>> joinedTempMap = 
                    new Map<Integer, Map<Map<WorkOrder, List<WorkOrder>>, List<WorkOrderLineItem>>>();

                if(!masterWOIndexJoinMap.values().isEmpty()) joinedTempMap.putAll(masterWOIndexJoinMap.values()[0]);
                Set<Boolean> masterWOSet = masterWOIndexJoinMap.keySet();
                for(Boolean i : masterWOSet) {
                    masterWO = i;
                    break;
                }
                Map<Map<WorkOrder, List<WorkOrder>>, List<WorkOrderLineItem>> joinedMap = 
                    new Map<Map<WorkOrder, List<WorkOrder>>, List<WorkOrderLineItem>>();
                if(!joinedTempMap.values().isEmpty()) joinedMap = joinedTempMap.values()[0];
                Set<Integer> tempSet = joinedTempMap.keySet();
                for(Integer i : tempSet) {
                    temp = i;
                    break;
                }
                for(Map<WorkOrder, List<WorkOrder>> item : joinedMap.keySet()){
                    parentChildWOMap.putAll(item);
                    break;
                }
                if(!joinedMap.values().isEmpty()) woliList = joinedMap.values()[0];
            }
        }
        // creating part shipment work order for onsite case
        isApproved = false;
        woStatus = 'New';
        if(masterWO) {
            netSuitId = (!String.isBlank(c.Incident__c) && c.Incident__c.containsIgnoreCase('Test')) ? 'TEST CASE' : '';
        } else {
            netSuitId = (!String.isBlank(c.Incident__c) && c.Incident__c.containsIgnoreCase('Test')) ? 'TEST CASE' : 'Intentionally made TRUE so as to not to send this WO to NetSuite';
        }
        Set<Id> serviceCLIsToMoveIds = new Set<Id>();
        for(ServiceContract sc : scList){
            for(ContractLineItem cli : sc.ContractLineItems){
                if(cli.Include_In_WO_Type__c == 'Part Shipment' && cli.Product_Family__c == 'Service'){
                    serviceCLIsToMoveIds.add(cli.Id);
                }
            }
        }
        if((parentSC.Work_Order_Record_Type__c == 'Part Shipment' || parentSC.Work_Order_Record_Type__c == 'Advance Exchange + Onsite' || parentSC.Work_Order_Record_Type__c == 'Production')) continue;
        List<Case_Product__c> caseProdsList = new List<Case_Product__c>();
        if(!csProductMap.isEmpty() && csProductMap.containsKey(c.Id)) caseProdsList = csProductMap.get(c.Id);
        if(caseProdsList.isEmpty() && serviceCLIsToMoveIds.isEmpty()) continue;
        
        List<ContractLineItem> hwCliList = new List<ContractLineItem>();
        List<ContractLineItem> cliList = parentSC.ContractLineItems;
        for(ContractLineItem cli : cliList) {
            if(cli.Product_Family__c == 'Hardware') hwCliList.add(cli);
        }
        if(parentChildSCMap.containsKey(c.ServiceContractId)) {
            List<ServiceContract> childScList = parentChildSCMap.get(c.ServiceContractId);
            for(ServiceContract childsc : childScList) {
                for(ContractLineItem cli : childsc.ContractLineItems) {
                    if(cli.Product_Family__c == 'Hardware') hwCliList.add(cli);
                }
            }
        }
        List<Case_Product__c> cpList = new List<Case_Product__c>();
        if(!csProductMap.isEmpty() && csProductMap.containsKey(c.Id)) cpList = csProductMap.get(c.Id);
        if(!hwCliList.isEmpty() || !serviceCLIsToMoveIds.isEmpty() || (c.Include_Part__c == true && !cpList.isEmpty())){
            WorkOrder wo = createWO(c.ProductId, parentSC, c, countryPBMap.get(c.Country__c), c.Preferred_Time__c, 
            partShipId, isApproved, woStatus, netSuitId);

            wo.Additional_Part_WO__c = true;
            if(masterWO){
                parentChildWOMap.put(wo, new List<WorkOrder>());
            } else {
                parentChildWOMap.values()[parentChildWOMap.size() - 1].add(wo);
            }
        }
    }
    List<WorkOrder> toInsert = new List<WorkOrder>();
    List<WorkOrder> childWOList = new List<WorkOrder>();
    if(!parentChildWOMap.isEmpty()) toInsert.addAll(parentChildWOMap.keySet());
    insert toInsert;

    for (List<WorkOrder> listItem : parentChildWOMap.values()) {
        if(listItem == null) continue;
        childWOList.addAll(listItem);
    }
    for(WorkOrder wo : toInsert){
        for(WorkOrder cwo : childWOList){
            if(wo.CaseId != cwo.CaseId) continue;
            cwo.ParentWorkOrderId = wo.Id;
        }
    }
    insert childWOList;
    
    List<WorkOrder> additionalWOList = new List<WorkOrder>();
    List<WorkOrder> woList = new List<WorkOrder>();
    for(WorkOrder wo : toInsert){
        if(wo.RecordTypeId != partShipId) continue;
        if(wo.Additional_Part_WO__c) additionalWOList.add(wo);
        if(!wo.Additional_Part_WO__c) woList.add(wo);
    }
    for(WorkOrder wo : childWOList){
        if(wo.RecordTypeId != partShipId) continue;
        if(wo.Additional_Part_WO__c) additionalWOList.add(wo);
        if(!wo.Additional_Part_WO__c) woList.add(wo);
    }
    // calling createWOLIForOnsite to create woli with hardware products part shipment work order in onsite case.
    if(!additionalWOList.isEmpty()) woliList.addAll(createWOLIForOnsite(csMap, scMap, parentChildSCMap, additionalWOList, csProductMap, pbeMap, pbProdPbeMap));
    // calling createHardwareWOLIs to create woli with hardware products for part shipment work order in part shippment case.
    if(!woList.isEmpty()) woliList.addAll(createHardwareWOLIs(csMap, scMap, parentChildSCMap, woList, csProductMap, pbeMap, pbProdPbeMap, partShipId));

    List<WorkOrder> workorderList = new List<WorkOrder>();
    if(!toInsert.isEmpty()) workorderList.addAll(toInsert);
    if(!childWOList.isEmpty()) workorderList.addAll(childWOList);
    System.debug('woliList size '+ woliList.size());
    if(!woliList.isEmpty()){
        for(WorkOrder wo : workorderList){
            for(WorkOrderLineItem woli : woliList){
                if(wo.Work_Order_Number__c != woli.Work_Order_Number__c) continue;
                System.debug('WorkOrderId: ' + woli.WorkOrderId);
                System.debug('Case__c: ' + woli.Case__c);
                System.debug('wo Case__c : ' + wo.CaseId);
                System.debug('wo product: ' + wo.Product__c);
                System.debug('pbeMap ' + pbeMap);
                System.debug('PricebookEntryId: ' + woli.PricebookEntryId);

                if(woli.Case__c == wo.CaseId && wo.Product__c == pbeMap.get(woli.PricebookEntryId).Product2Id && String.isBlank(woli.WorkOrderId)) {
                    if(wo.ParentWorkOrderId != null) {
                        woli.WorkOrderId = wo.ParentWorkOrderId;
                        woli.Child_WO__c = wo.Id;
                    } else {
                        woli.WorkOrderId = wo.Id;
                    }
                }
            }
        }
        insert woliList;
    }
    for(Case c: csMap.values()){
        c.Create_Work_Order__c = false; 
    }
    CaseTriggerHandler.runOnceBeforeUpdate = false;
    CaseTriggerHandler.runOnceAfterUpdate = false;
    update csMap.values();
}

public static Map<Boolean, Map<WorkOrder, List<WorkOrder>>> createWOforServiceContract(ServiceContract parentSC, 
    Map<WorkOrder, List<WorkOrder>> parentChildWOMap, Case c, ServiceContract sc, List<WorkOrder_Schedule__c> woScheduleList, 
    Id rtId, Map<String, Id> countryPBMap, Boolean masterWO, String woStatus, Boolean isApproved) {
    
    DateTime prefDateTime = c.Preferred_Time__c;
    if(prefDateTime == null){
        for(WorkOrder_Schedule__c wos: woScheduleList) {
            if(wos.Case__c != c.Id) continue;
            prefDateTime = wos.Preferred_Time__c;
            break;
        }
    }
    String netSuitId = (!String.isBlank(c.Incident__c) && c.Incident__c.containsIgnoreCase('Test')) ? 'TEST CASE' : '';
    Integer numOfTechs = (sc.Number_Of_Technicians__c != null && sc.Number_Of_Technicians__c != 0) ? Integer.valueOf(sc.Number_Of_Technicians__c) : 1;

    if(parentSC.Single_WO_For_Billing__c && masterWO) {
        // Parent WO
        masterWO = false;
        WorkOrder wo = createWO(c.ProductId, sc, c, countryPBMap.get(c.Country__c), prefDateTime, rtId, isApproved, 
            woStatus, netSuitId);

        numOfTechs = numOfTechs - 1;
        if(numOfTechs == 0) {
            parentChildWOMap.put(wo, new List<WorkOrder>());
        } else {
            List<WorkOrder> woList2 = new List<WorkOrder>();
            for(Integer i=0; i<numOfTechs; i++){
                netSuitId = (!String.isBlank(c.Incident__c) && c.Incident__c.containsIgnoreCase('Test')) ? 'TEST CASE' : 'Intentionally made TRUE so as to not to send this WO to NetSuite';
                WorkOrder childWO = createWO(c.ProductId, sc, c, countryPBMap.get(c.Country__c), prefDateTime, 
                    rtId, isApproved, woStatus, netSuitId);
                woList2.add(childWO);
            }
            parentChildWOMap.put(wo,woList2);
        }
    } else if(!masterWO){
        // Child WO
        netSuitId = (!String.isBlank(c.Incident__c) && c.Incident__c.containsIgnoreCase('Test')) ? 'TEST CASE' : 'Intentionally made TRUE so as to not to send this WO to NetSuite';
        WorkOrder wo = createWO(c.ProductId, sc, c, countryPBMap.get(c.Country__c), prefDateTime, rtId, isApproved, 
            woStatus, netSuitId);

        numOfTechs = numOfTechs - 1;
        if(numOfTechs == 0) {
            parentChildWOMap.values()[parentChildWOMap.size() - 1].add(wo);
        } else {
            for(Integer i=0; i<numOfTechs; i++){
                WorkOrder childWO = createWO(c.ProductId, sc, c, countryPBMap.get(c.Country__c), prefDateTime, rtId, isApproved, 
                    woStatus, netSuitId);
                parentChildWOMap.values()[parentChildWOMap.size() - 1].add(childWO);
            }
        }    
    } else if(!parentSC.Single_WO_For_Billing__c){
        // Indenpendent WO
        netSuitId = (!String.isBlank(c.Incident__c) && c.Incident__c.containsIgnoreCase('Test')) ? 'TEST CASE' : '';
        WorkOrder wo = createWO(c.ProductId, sc, c, countryPBMap.get(c.Country__c), prefDateTime, rtId, isApproved, 
            woStatus, netSuitId);

        numOfTechs = numOfTechs - 1;
        parentChildWOMap.put(wo, null);
        System.debug('parentChildWOMap size -> '+ parentChildWOMap.size());
        for(Integer i=0; i<numOfTechs; i++){
            netSuitId = (!String.isBlank(c.Incident__c) && c.Incident__c.containsIgnoreCase('Test')) ? 'TEST CASE' : 'Intentionally made TRUE so as to not to send this WO to NetSuite';
            WorkOrder cloneWO = createWO(c.ProductId, sc, c, countryPBMap.get(c.Country__c), prefDateTime, rtId, 
                isApproved, woStatus, netSuitId);
            parentChildWOMap.put(cloneWO, null);
        }
    } 
    Map<Boolean, Map<WorkOrder, List<WorkOrder>>> masterWOParentChildWOMap = new Map<Boolean, Map<WorkOrder, List<WorkOrder>>>();
    masterWOParentChildWOMap.put(masterWO, parentChildWOMap);
    System.debug('masterWOParentChildWOMap size -> '+ masterWOParentChildWOMap.size());
    return masterWOParentChildWOMap;
}

public static Map<Boolean, Map<Integer, Map<Map<WorkOrder, List<WorkOrder>>, List<WorkOrderLineItem>>>> createWOforContractLineItem(
    ServiceContract parentSC, Map<WorkOrder, List<WorkOrder>> parentChildWOMap, List<WorkOrderLineItem> woliList,
    List<ContractLineItem> cliList, ServiceContract sc, Case c, Map<Id, Id> productPBEMap, List<WorkOrder_Schedule__c> woScheduleList,
    Map<Id, PricebookEntry> pbeMap, Map<String, Id> countryPBMap, Id onsiteLaborId,Id partShipId, Integer temp, Boolean masterWO, 
    String woStatus, Boolean isApproved) {

    Map<Integer, Map<Map<WorkOrder, List<WorkOrder>>, List<WorkOrderLineItem>>> indexJoinMap = 
        new Map<Integer, Map<Map<WorkOrder, List<WorkOrder>>, List<WorkOrderLineItem>>>();
    System.debug('cliList size---->> '+ cliList.size());
    for(ContractLineItem cli: cliList){
        Id rtId;
        Id pbeId = null;
        if(cli.Work_Order_Record_Type__c == 'Onsite Labor'){
            rtId = onsiteLaborId;
        } else if(cli.Work_Order_Record_Type__c == 'Part Shipment'){
            rtId = partShipId;
        }
        if(!productPBEMap.containsKey(cli.Product2Id) || cli.Product_Family__c == 'Hardware' || cli.Include_In_WO_Type__c == 'Part Shipment') continue;
        if(!String.isBlank(c.Removed_Service_Product_IDs__c) && c.Removed_Service_Product_IDs__c.contains(cli.PricebookEntry.Product2Id)) continue;
        if(cli.PricebookEntry.Product2.Family == 'Hardware' || (!String.isBlank(cli.Priority__c) && c.Priority != cli.Priority__c)) continue;
        Map<Map<WorkOrder, List<WorkOrder>>, List<WorkOrderLineItem>> joinedMap = 
            new Map<Map<WorkOrder, List<WorkOrder>>, List<WorkOrderLineItem>>();
        DateTime prefDateTime = c.Preferred_Time__c;
        for(WorkOrder_Schedule__c wos: woScheduleList) {
            if(cli.Product2Id != wos.Product__c || wos.Preferred_Time__c == null) continue;
            prefDateTime = wos.Preferred_Time__c;
            break;
        }
        String netSuitId = (!String.isBlank(c.Incident__c) && c.Incident__c.containsIgnoreCase('Test')) ? 'TEST CASE' : '';
        Integer numOfTechs = (cli.Number_Of_Technicians__c != null && cli.Number_Of_Technicians__c != 0) ? Integer.valueOf(cli.Number_Of_Technicians__c) : 1;
        Decimal UnitPrice = (cli.UnitPrice != null && cli.UnitPrice != 0) ? cli.UnitPrice : pbeMap.get(productPBEMap.get(cli.Product2Id)).UnitPrice;
        String description = (!String.isBlank(cli.Description)) ? cli.Description : pbeMap.get(productPBEMap.get(cli.Product2Id)).Product2.Description;
        if(parentSC.Single_WO_For_Billing__c && masterWO){
            // Parent WO
            masterWO = false;
            WorkOrder wo = createWO(cli.Product2Id, sc, c, countryPBMap.get(c.Country__c), prefDateTime, onsiteLaborId, isApproved, woStatus, netSuitId);
            if(wo.OutofScope__c == true && cli.Out_of_Scope_CLI__c == false) continue;
            pbeId = (productPBEMap.containsKey(cli.Product2Id)) ? productPBEMap.get(cli.Product2Id) : null;
            System.debug('pbeId-->'+pbeId);
            if (pbeId == null) continue;
            wo.Work_Order_Number__c = temp;
            parentChildWOMap.put(wo, new List<WorkOrder>());
            // Call createWOLI method after creating each WorkOrder           
            WorkOrderLineItem woli = createWOLI(c.Id, pbeId, cli.Quantity, UnitPrice, description);
            woli.Work_Order_Number__c = temp;
            woliList.add(woli);
            temp++;
            numOfTechs = numOfTechs - 1;
            if(numOfTechs > 0) {
                List<WorkOrder> additionalTechWoList = new List<WorkOrder>();
                for(Integer i=0; i<numOfTechs; i++){
                    netSuitId = (!String.isBlank(c.Incident__c) && c.Incident__c.containsIgnoreCase('Test')) ? 'TEST CASE' : 'Intentionally made TRUE so as to not to send this WO to NetSuite';
                    WorkOrder childWO = createWO(cli.Product2Id, sc, c, countryPBMap.get(c.Country__c), prefDateTime, 
                    rtId, isApproved, woStatus, netSuitId);
                    childWO.Work_Order_Number__c = temp;
                    additionalTechWoList.add(childWO);
                    temp++;
                }
                parentChildWOMap.values()[parentChildWOMap.size() - 1].addAll(additionalTechWoList);
            }
        } else if(parentSC.Single_WO_For_Billing__c && !masterWO){
            netSuitId = (!String.isBlank(c.Incident__c) && c.Incident__c.containsIgnoreCase('Test')) ? 'TEST CASE' : 'Intentionally made TRUE so as to not to send this WO to NetSuite';
            WorkOrder wo = createWO(cli.Product2Id, sc, c, countryPBMap.get(c.Country__c), prefDateTime, rtId, isApproved, woStatus, netSuitId);
            if(wo.OutofScope__c == true && cli.Out_of_Scope_CLI__c == false) continue;
            pbeId = (productPBEMap.containsKey(cli.Product2Id)) ? productPBEMap.get(cli.Product2Id) : null;
            System.debug('pbeId-->'+pbeId);
            if (pbeId == null) continue;

            wo.Work_Order_Number__c = temp;
            // Call createWOLI method after creating each WorkOrder
            WorkOrderLineItem woli = createWOLI(c.Id, pbeId, cli.Quantity, UnitPrice, description);
            woli.Work_Order_Number__c = temp;
            woliList.add(woli);
            temp++;
            parentChildWOMap.values()[parentChildWOMap.size() - 1].add(wo);
            numOfTechs = numOfTechs - 1;
            if(numOfTechs != 0) {
                List<WorkOrder> additionalTechWoList = new List<WorkOrder>();
                for(Integer i=0; i<numOfTechs; i++){
                    WorkOrder childWO = createWO(cli.Product2Id, sc, c, countryPBMap.get(c.Country__c), prefDateTime, rtId, isApproved, woStatus, netSuitId);
                    childWO.Work_Order_Number__c = temp;
                    additionalTechWoList.add(childWO);
                    temp++;
                }
                parentChildWOMap.values()[parentChildWOMap.size() - 1].addAll(additionalTechWoList);
            }
        } else if(!parentSC.Single_WO_For_Billing__c){
            netSuitId = (!String.isBlank(c.Incident__c) && c.Incident__c.containsIgnoreCase('Test')) ? 'TEST CASE' : '';
            WorkOrder wo = createWO(cli.Product2Id, sc, c, countryPBMap.get(c.Country__c), prefDateTime, rtId, isApproved, woStatus, netSuitId);
            if(wo.OutofScope__c == true && cli.Out_of_Scope_CLI__c == false) continue;
            pbeId = (productPBEMap.containsKey(cli.Product2Id)) ? productPBEMap.get(cli.Product2Id) : null;
            System.debug('pbeId-->'+pbeId);
            if (pbeId == null) continue;

            wo.Work_Order_Number__c = temp;
            // Call createWOLI method after creating each WorkOrder
            WorkOrderLineItem woli = createWOLI(c.Id, pbeId, cli.Quantity, UnitPrice, description);
            woli.Work_Order_Number__c = temp;
            woliList.add(woli);
            temp++;
            parentChildWOMap.put(wo, null);
            numOfTechs = numOfTechs - 1;
            if(numOfTechs > 0) {
                for(Integer i=0; i<numOfTechs; i++){
                    netSuitId = (!String.isBlank(c.Incident__c) && c.Incident__c.containsIgnoreCase('Test')) ? 'TEST CASE' : 'Intentionally made TRUE so as to not to send this WO to NetSuite';
                    WorkOrder cloneWO = createWO(cli.Product2Id, sc, c, countryPBMap.get(c.Country__c), prefDateTime, rtId, 
                    isApproved, woStatus, netSuitId);
                    cloneWO.Work_Order_Number__c = temp;
                    parentChildWOMap.put(cloneWO, null);
                    temp++;
                }
            }
            System.debug('woliList size last-> ' + woliList.size());
        }
        joinedMap.put(parentChildWOMap,woliList);
        System.debug('joinedMap size --> '+ joinedMap.size());
        indexJoinMap.put(temp, joinedMap);
    }
    Map<Boolean, Map<Integer, Map<Map<WorkOrder, List<WorkOrder>>, List<WorkOrderLineItem>>>> masterWOIndexJoinMap = 
        new Map<Boolean, Map<Integer, Map<Map<WorkOrder, List<WorkOrder>>, List<WorkOrderLineItem>>>>();
    masterWOIndexJoinMap.put(masterWO, indexJoinMap);
    return masterWOIndexJoinMap;
}

public static WorkOrder createWO(Id productId, ServiceContract sc, Case c, Id pbId, DateTime prefDateTime, 
    Id rtId, Boolean isApproved, String woStatus, String netSuitId){

    WorkOrder wo = new WorkOrder();

    wo.AccountId = c.AccountId;
    wo.Approved__c = isApproved;
    wo.CaseId = c.Id;
    wo.ContactId = c.ContactId;
    wo.Department__c = c.Department__c;
    wo.Department2__c = c.Department2__c;
    wo.Description = c.Description;
    wo.Equipment_Type__c = c.Equipment_Type__c;
    wo.FN_Template_ID__c = sc.FN_Template_ID__c;
    wo.Incident__c = c.Incident__c;
    wo.NetsuiteId__c = netSuitId;
    wo.OwnerId = c.OwnerId;
    wo.POS_Register_Number__c = c.POS_Register_Number__c;
    wo.PO__c = c.PO_Number__c;
    wo.Preferred_Time_IMAC__c = prefDateTime;
    wo.Pricebook2Id = pbId;
    wo.Priority = c.Priority;
    wo.Problem_Type__c = c.Problem_Type__c;
    wo.Product_Quantity__c = c.Product_Quantity__c;
    wo.Product__c = productId;
    wo.Project__c = c.Project__c;
    wo.RecordTypeId = rtId;
    wo.Root_Account__c = c.Root_Account__c;
    wo.ServiceContractId = sc.Id;
    wo.Service_Type__c = sc.Service_Type__c;
    wo.Status = woStatus;
    wo.Tech_Notes__c = c.Tech_Notes__c;
    wo.BusinessHoursId = c.BusinessHoursId;
    wo.Project_Account__c = c.Project_Account__c;
    wo.OutofScope__c = c.Out_Of_Scope__c;

    return wo;
}

public static WorkOrderLineItem createWOLI(Id caseId, Id pricebookEntryId, Decimal quantity, Decimal unitPrice, String description){

    WorkOrderLineItem woli = new WorkOrderLineItem();
    woli.Case__c = caseId;
    woli.PricebookEntryId = pricebookEntryId;
    woli.Quantity = quantity;
    woli.Status = 'New';
    woli.UnitPrice = unitPrice;
    woli.Description = description;
    return woli;
}

public static List<WorkOrderLineItem> createWOLIForOnsite(Map<Id, Case> csMap, Map<Id, ServiceContract> scMap, 
    Map<Id, List<ServiceContract>>  parentChildSCMap, List<WorkOrder> woList, Map<Id, List<Case_Product__c>> csProductMap, 
    Map<Id, PricebookEntry> pbeMap, Map<Id, Map<Id,Id>> pbProdPbeMap){
    
    List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
    for(Case c :csMap.values()){
        Integer stagingProdCount = 0;
        if(!scMap.containsKey(c.ServiceContractId)) continue;
        ServiceContract sc = scMap.get(c.ServiceContractId);
        List<ContractLineItem> hwCliList = new List<ContractLineItem>();
        for(ContractLineItem cli : sc.ContractLineItems) {
            if(cli.Product_Family__c == 'Hardware' || cli.Include_In_WO_Type__c == 'Part Shipment') hwCliList.add(cli);
        }
        if(parentChildSCMap.containsKey(c.ServiceContractId)) {
            List<ServiceContract> childScList = parentChildSCMap.get(c.ServiceContractId);
            for(ServiceContract childsc : childScList) {
                for(ContractLineItem cli : childsc.ContractLineItems) {
                    if(cli.Product_Family__c == 'Hardware' || cli.Include_In_WO_Type__c == 'Part Shipment') hwCliList.add(cli);
                }
            }
        }
        List<Case_Product__c> caseProdsList = new List<Case_Product__c>();
        if(!csProductMap.isEmpty() && csProductMap.containsKey(c.Id)) caseProdsList = csProductMap.get(c.Id);
        for(WorkOrder wo : woList){
            if(wo.CaseId != c.Id) continue;
            Id woId = wo.Id;
            Id childWO;
            if(wo.ParentWorkOrderId != null && sc.Single_WO_For_Billing__c){
                woId = wo.ParentWorkOrderId;
                childWO = wo.Id;
            }
            Set<Id> prodIds = new Set<Id>();
            Map<Id,Id> productPBEMap = new Map<Id, Id>();
            if(pbProdPbeMap.containsKey(wo.Pricebook2Id)) productPBEMap.putAll(pbProdPbeMap.get(wo.Pricebook2Id));
            for(ContractLineItem cli : hwCliList){
                if(!String.isBlank(cli.Priority__c) && cli.Priority__c != wo.Priority) continue;
                if(cli.Include_In_WO_Type__c == 'Onsite Labor') continue;
                for(Case_Product__c cp : caseProdsList) {
                    if(cp.Case__c != c.Id) continue;
                    if(cli.PricebookEntry.Product2.Family != 'Hardware') continue;
                    if(cli.Product2Id != cp.Product__c) continue;
                    if(prodIds.contains(cli.Product2Id)) continue;
                    Id pbeId = (productPBEMap.containsKey(cli.Product2Id)) ? productPBEMap.get(cli.Product2Id) : null;
                    if(pbeId == null) continue;
                    Decimal price = (pbeMap.containsKey(pbeId)) ? pbeMap.get(pbeId).UnitPrice : 0;
                    String description = cli.PricebookEntry.Product2.Description;
                    if(cli.UnitPrice != null && cli.UnitPrice != 0){
                        price = cli.UnitPrice;
                    }
                    if(String.isNotBlank(cli.Description)){
                        description = cli.Description;
                    }
                    WorkOrderLineItem woli = createWOLI(c.Id, pbeId, cp.Quantity__c, price, description);
                    woli.WorkOrderId = woId;
                    woli.Child_WO__c = childWO;
                    woliList.add(woli);
                    prodIds.add(cli.Product2Id);
                    if(pbeMap.get(pbeId).Product2.Staging_Required__c) {
                        stagingProdCount++;
                    }
                    break;
                }
                if(cli.Include_In_WO_Type__c == 'Part Shipment'){
                    if(prodIds.contains(cli.Product2Id)) continue;
                    Id pbeId = (productPBEMap.containsKey(cli.Product2Id)) ? productPBEMap.get(cli.Product2Id) : null;
                    if(pbeId == null) continue;
                    Decimal price = (pbeMap.containsKey(pbeId)) ? pbeMap.get(pbeId).UnitPrice : 0;
                    String description = cli.PricebookEntry.Product2.Description;
                    Decimal quantity = 1;
                    if(cli.Quantity != null && cli.Quantity != 0){
                        quantity = cli.Quantity;
                    }
                    if(cli.UnitPrice != null && cli.UnitPrice != 0){
                        price = cli.UnitPrice;
                    }
                    if(String.isNotBlank(cli.Description)){
                        description = cli.Description;
                    }
                    WorkOrderLineItem woli = createWOLI(c.Id, pbeId, quantity, price, description);
                    woli.WorkOrderId = woId;
                    woli.Child_WO__c = childWO;
                    woliList.add(woli);
                    prodIds.add(cli.Product2Id);
                    if(pbeMap.get(pbeId).Product2.Staging_Required__c) {
                        stagingProdCount++;
                    }
                }
            }
            //WOLIs for onsite WO based on Include Part.
            //OR WOLI for Manually added H/W products.
            if(c.Include_Part__c == true || caseProdsList.size() != 0){
                for(Case_Product__c cp : caseProdsList) {
                    if(cp.Case__c != c.Id) continue;
                    if(prodIds.contains(cp.Product__c)) continue;
                    Id pbeId = (productPBEMap.containsKey(cp.Product__c)) ? productPBEMap.get(cp.Product__c) : null;
                    if(pbeId == null) continue;
                    Decimal price = (pbeMap.containsKey(pbeId)) ? pbeMap.get(pbeId).UnitPrice : 0;
                    String description = (pbeMap.containsKey(pbeId)) ? pbeMap.get(pbeId).Product2.Description : '';
                    WorkOrderLineItem woli = createWOLI(c.Id, pbeId, cp.Quantity__c, price, description);
                    woli.WorkOrderId = woId;
                    woli.Child_WO__c = childWO;
                    woliList.add(woli);
                    prodIds.add(pbeMap.get(pbeId).Product2Id);
                    if(pbeMap.get(pbeId).Product2.Staging_Required__c) {
                        stagingProdCount++;
                    }
                }
            }
            if(stagingProdCount > 0) {
                if(String.isNotBlank(sc.Account.Staging_Product__c) && productPBEMap.containsKey(sc.Account.Staging_Product__c)) {
                    Id pbeId = productPBEMap.get(sc.Account.Staging_Product__c);
                    WorkOrderLineItem woli = createWOLI(c.Id, pbeId, c.Staging_Required_Count__c, pbeMap.get(pbeId).UnitPrice, 
                    pbeMap.get(pbeId).Product2.Description);
                    woli.WorkOrderId = woId;
                    woli.Child_WO__c = childWO;
                    woliList.add(woli);
                }
            }
        }
    }
    return woliList;
}

public static List<WorkOrderLineItem> createHardwareWOLIs (Map<Id, Case> csMap, Map<Id, ServiceContract> scMap, 
    Map<Id, List<ServiceContract>>  parentChildSCMap, List<WorkOrder> woList, Map<Id, List<Case_Product__c>> csProductMap, 
    Map<Id, PricebookEntry> pbeMap, Map<Id, Map<Id,Id>> pbProdPbeMap, Id partShipId){
    
    List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
    Set<Id> woStagingCountSet = new Set<Id>();
    Map<Id, Set<Id>> woIdProdIdMap = new Map<Id, Set<Id>>();
    Map<Id, ServiceContract> allSCMap = new Map<Id, ServiceContract>();
    for(Case c : csMap.values()){
        if(!scMap.containsKey(c.ServiceContractId)) continue;
        ServiceContract parentSC = scMap.get(c.ServiceContractId);
        allSCMap.put(parentSC.id,parentSC);
        if(!parentSC.ChildServiceContracts.isEmpty() && parentChildSCMap.containsKey(parentSC.Id)){
            allSCMap.putAll(parentChildSCMap.get(parentSC.Id));
        }
    }
    for(WorkOrder wo : woList) {
        if(!csMap.containsKey(wo.CaseId) || !allSCMap.containsKey(wo.ServiceContractId)) continue;
        if(wo.RecordTypeId != partShipId && wo.RecordTypeId != Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Production').getRecordTypeId()) continue;
        Case c = csMap.get(wo.CaseId);
        if(!allSCMap.containsKey(c.ServiceContractId)) continue;
        List<Case_Product__c> cpList = new List<Case_Product__c>();
        if(csProductMap.containsKey(c.Id)) cpList = csProductMap.get(c.Id);
        
        ServiceContract parentSC = allSCMap.get(c.ServiceContractId);
        ServiceContract sc = allSCMap.get(wo.ServiceContractId);
        Id woId = wo.Id;
        Id childWO;
        if(wo.ParentWorkOrderId != null && parentSC.Single_WO_For_Billing__c){
            woId = wo.ParentWorkOrderId;
            childWO = wo.Id;
        }
        Map<Id,Id> productPBEMap = new Map<Id, Id>();
        if(pbProdPbeMap.containsKey(sc.Pricebook2Id)) productPBEMap.putAll(pbProdPbeMap.get(sc.Pricebook2Id));
        List<ContractLineItem> cliList = sc.ContractLineItems;
        Set<Id> prodIds = new Set<Id>();
        for(ContractLineItem cli : cliList){
            Id pbeId = null;
            pbeId = (productPBEMap.containsKey(cli.Product2Id)) ? productPBEMap.get(cli.Product2Id) : null;
            if(pbeId == null) continue;
            for(Case_Product__c cp : cpList) {
                if(cli.Product2Id != cp.Product__c) continue;
                if(prodIds.contains(cp.Product__c)) continue;
                String description = (!String.isBlank(cli.Description)) ? cli.Description : pbeMap.get(pbeId).Product2.Description;
                Decimal price = 0;
                if(cli.UnitPrice != null && cli.UnitPrice != 0){
                    price = cli.UnitPrice;
                } else {
                    price = pbeMap.get(pbeId).UnitPrice;
                }
                WorkOrderLineItem woli = createWOLI(c.Id, pbeId, cp.Quantity__c, price, description);
                woli.WorkOrderId = woId;
                woli.Child_WO__c = childWO;
                woliList.add(woli);
                prodIds.add(cp.Product__c);
                woIdProdIdMap.put(woId, prodIds);
                break;
            }
        }
        // WOLIs for manually added products
        for(Case_Product__c cp : cpList) {
            if(cp.CLI_Product__c) continue;
            Id pbeId = (productPBEMap.containsKey(cp.Product__c)) ? productPBEMap.get(cp.Product__c) : null;
            if(pbeId == null) continue;
            if(woIdProdIdMap.get(woId) == null) {
                Set<Id> pdIds = new Set<Id>();
                woIdProdIdMap.put(woId, pdIds);
            }
            if(woIdProdIdMap.get(woId).contains(cp.Product__c)) continue;
            woIdProdIdMap.get(woId).add(cp.Product__c);
            WorkOrderLineItem woli = createWOLI(c.Id, pbeId, cp.Quantity__c, pbeMap.get(pbeId).UnitPrice, 
            pbeMap.get(pbeId).Product2.Description);
            woli.WorkOrderId = woId;
            woli.Child_WO__c = childWO;
            woliList.add(woli);
        }
        // Staging WOLI
        if(c.Staging_Required_Count__c > 0) {
            if(!String.isBlank(sc.Account.Staging_Product__c) && productPBEMap.containsKey(sc.Account.Staging_Product__c)) {
                Id pbeId = productPBEMap.get(sc.Account.Staging_Product__c);
                WorkOrderLineItem woli = createWOLI(c.Id, pbeId, c.Staging_Required_Count__c, pbeMap.get(pbeId).UnitPrice, 
                pbeMap.get(pbeId).Product2.Description);
                woli.WorkOrderId = woId;
                woli.Child_WO__c = childWO;
                woliList.add(woli);
            }
        }      
    }
    return woliList;
}
}