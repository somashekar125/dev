public class SalesOrderLineTriggerHandler {
    public static void handlerAfterInsert(List<Sales_Order_Line__c> solList){
        SalesOrderLineTriggerHandler.createAssetAndWOLIsfromSOL(JSON.serialize(solList));
        //SalesOrderLineTriggerHandler.createROs(JSON.serialize(solList));
        SalesOrderLineTriggerHandler.insertCaseSerialNumber(solList);
    }
    
    // Creation of RO and ROLI is handled by Mulesoft.
    // We are only populating CaseId in RO FROM SO.
    /*@Future
    public static void createROs(string solListString){
        List<Sales_Order_Line__c> solLines = (List<Sales_Order_Line__c>)JSON.deserialize(solListString, List<Sales_Order_Line__c>.class);
        Set<Id> soIds = new Set<Id>();
        for(Sales_Order_Line__c sol : solLines){
            soIds.add(sol.Sales_Order__c);
        }
        List<Sales_Order__c> soAndSOLIList = [SELECT Id, Account__c, Order_Type__c, Total__c, Work_Order__r.CaseId, (SELECT Id, Product__c, Product__r.Family, Description__c, Taxable__c, Line_Number__c, Unit_Price__c, Quantity__c FROM Sales_Order_Lines__r),(SELECT Id,Sales_Order__c FROM Return_Orders__r) FROM Sales_Order__c WHERE Id IN: soIds and Return_Authorization__c != null];
        List<ReturnOrder> roList = new List<ReturnOrder>();
        for(Sales_Order__c so : soAndSOLIList){
            if(so.Order_Type__c != 'Part Shipment') continue;
            if(!so.Return_Orders__r.isEmpty()) {
                roList.add(so.Return_Orders__r[0]);
                continue;
            }
            ReturnOrder ro = new ReturnOrder();
            ro.CaseId = so.Work_Order__r.CaseId;
            ro.AccountId = so.Account__c;
            ro.Total__c = so.Total__c;
            ro.Sales_Order__c = so.Id;
            roList.add(ro);
        }
        if(roList.size() != 0){
            upsert roList;
            List<ReturnOrderLineItem> roliList = new List<ReturnOrderLineItem>();
            for(ReturnOrder ro : roList){
                for(Sales_Order__c so : soAndSOLIList){
                    if(ro.Sales_Order__c != so.Id) continue;
                    for(Sales_Order_Line__c soli : so.Sales_Order_Lines__r){
                        if(soli.Quantity__c == null || soli.Quantity__c < 1 || soli.Product__c == null || soli.Product__r.Family == 'Service') continue;
                        ReturnOrderLineItem roli = new ReturnOrderLineItem();
                        roli.ReturnOrderId = ro.Id;
                        roli.Description = soli.Description__c;
                        roli.Product2Id = soli.Product__c;
                        roli.Taxable__c = soli.Taxable__c;
                        roli.Line__c = soli.Line_Number__c;
                        roli.QuantityExpected = soli.Quantity__c;
                        roli.QuantityReturned = soli.Quantity__c;
                        roli.Rate__c = soli.Unit_Price__c;
                        roliList.add(roli);
                    }
                }
            }
            if(roliList.size() != 0){
                insert roliList;
            }
        }
    }*/
    
    public static void handlerAfterUpdate(Map<Id, Sales_Order_Line__c> solListNew, Map<Id, Sales_Order_Line__c> solListOld){
        List<Sales_Order_Line__c> soListforAssets = new List<Sales_Order_Line__c>();
        for(Sales_Order_Line__c sol : solListNew.values()){
            if(sol.Serial_Numbers__c == null || sol.Serial_Numbers__c == solListOld.get(sol.Id).Serial_Numbers__c) continue;
            soListforAssets.add(sol);
        }
        System.debug('soListforAssets.size()::'+soListforAssets.size());
        if(soListforAssets.size() != 0){
            System.debug('calling future...');
            SalesOrderLineTriggerHandler.createAssetAndWOLIsfromSOL(JSON.serialize(soListforAssets));
        }
        SalesOrderLineTriggerHandler.updateCaseSerialNumber(solListNew, solListOld);
    }
    
    public static void handlerBeforeInsert(List<Sales_Order_Line__c> solList){
        SalesOrderLineTriggerHandler.populateProduct(solList);
    }
    
    public static void handlerBeforeUpdate(List<Sales_Order_Line__c> solList){
        SalesOrderLineTriggerHandler.populateProduct(solList);
    }
    
    public static void populateProduct(List<Sales_Order_Line__c> solList){
        Set<string> productNames = new Set<string>();
        Set<string> soIds = new Set<string>();
        for(Sales_Order_Line__c sol : solList){
            if(sol.Product__c == null && sol.Description__c != null){
                productNames.add(sol.Description__c);
                soIds.add(sol.Sales_Order__c);
            }
        }
        List<Product2> prodList = [SELECT Id, Name, Account_Item_Belongs_To__c, ProductCode FROM Product2 WHERE Name IN : productNames and isActive = true and Portal_Access__c = true and Source_Key__c != null];
        List<Sales_Order__c> soList = [SELECT Id, Name, Account__c, Account__r.Root_Account__c FROM Sales_Order__c WHERE Id IN : soIds];
        for(Sales_Order_Line__c sol : solList){
            if(sol.Product__c == null && sol.Description__c != null){
                for(Sales_Order__c so : soList){
                    for(Product2 prod : prodList){
                        if(sol.Sales_Order__c == so.Id && (prod.Name == sol.Description__c || prod.ProductCode == sol.Description__c) && prod.Account_Item_Belongs_To__c == so.Account__r.Root_Account__c){
                            sol.Product__c = prod.Id;
                        }
                    }
                }
            }
        }
    }
    
    @future
    public static void createAssetAndWOLIsfromSOL(string solListString){
        List<Sales_Order_Line__c> solList = (List<Sales_Order_Line__c>)JSON.deserialize(solListString, List<Sales_Order_Line__c>.class);
        Set<Id> soIds = new Set<Id>();
        for(Sales_Order_Line__c sol : solList){
            soIds.add(sol.Sales_Order__c);
        }
        System.debug('soIds::'+soIds);
        if(soIds.size() != 0){
            List<Sales_Order__c> soList = [SELECT Id, Name, Account__c, Work_Order__c, (SELECT Id, Name, Product__c, Serial_Numbers__c, Product__r.Name, Quantity__c FROM Sales_Order_Lines__r WHERE Product__c != null ORDER BY Line_Number__c asc) FROM Sales_Order__c WHERE Id IN : soIds and Work_Order__c != null];
            Set<string> serialNumbers = new Set<string>();
            Set<Id> woIds = new Set<Id>();
            for(Sales_Order__c soRec : soList){
                for(Sales_Order_Line__c sol : soRec.Sales_Order_Lines__r){
                    if(sol.Serial_Numbers__c == null) continue;
                    serialNumbers.add(sol.Serial_Numbers__c);
                }
                woIds.add(soRec.Work_Order__c);
            }
            System.debug('soList::'+soList);
            System.debug('serialNumbers::'+serialNumbers);
            List<WorkOrder> woList = [SELECT Id, AccountId, CaseId, Description, (SELECT Id, Quantity, SOLI_Serial_Number__c, UnitPrice, Status, WorkOrderId, Description, AssetId, PricebookEntry.Product2Id, PricebookEntryId FROM WorkOrderLineItems) FROM WorkOrder WHERE Id IN : woIds];
            List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
            for(Sales_Order__c so : soList){
                for(WorkOrder wo : woList){
                    if(so.Work_Order__c != wo.Id) continue;
                    for(WorkOrderLineItem woli : wo.WorkOrderLineItems){
                        for(Sales_Order_Line__c sol : so.Sales_Order_Lines__r){
                            if(sol.Serial_Numbers__c == null || woli.SOLI_Serial_Number__c != null || sol.Product__c != woli.PricebookEntry.Product2Id || integer.valueOf(sol.Quantity__c) != integer.valueOf(woli.Quantity)) continue;
                            if(woli.Quantity <= 1){
                                woli.SOLI_Serial_Number__c = sol.Serial_Numbers__c;
                                woliList.add(woli);
                                System.debug('if....');
                            }else{
                                List<string> serialNumberList = sol.Serial_Numbers__c.split(',');
                                for(integer i = 0; i < woli.Quantity; i++){
                                    WorkOrderLineItem woliNew = new WorkOrderLineItem();
                                    woliNew.Description = wo.Description;
                                    woliNew.Status = 'New';
                                    woliNew.WorkOrderId = wo.Id;
                                    woliNew.PricebookEntryId = woli.PricebookEntryId;
                                    woliNew.UnitPrice = woli.UnitPrice;
                                    woliNew.Quantity = 1;
                                    if(i == 0){
                                        woliNew.Id = woli.Id;
                                    }
                                    woliNew.SOLI_Serial_Number__c = serialNumberList[i];
                                    woliList.add(woliNew);
                                    System.debug('else if...');
                                }
                            }
                        }
                    }
                }
            }
            System.debug('woliList::'+woliList.size()+'---'+woliList);
            List<Asset> savedAssets = [SELECT Id, Name, Product2Id, AccountId, SerialNumber, Asset_Number__c FROM Asset WHERE serialNumber IN : serialNumbers];
            Set<string> assetNames = new Set<string>();
            for(Asset ast : savedAssets){
                assetNames.add(ast.SerialNumber);
            }
            System.debug('assetNames::'+assetNames);
            List<Asset> assetList = new List<Asset>();
            for(Sales_Order__c soRec : soList){
                System.debug('soRec.Sales_Order_Lines__r::'+soRec.Sales_Order_Lines__r.size());
                for(Sales_Order_Line__c sol : soRec.Sales_Order_Lines__r){
                    if(assetNames.contains(sol.Name) || sol.Serial_Numbers__c == null) continue;
                    if(!sol.Serial_Numbers__c.contains(',')){
                        Asset ast = new Asset();
                        ast.Name = sol.Serial_Numbers__c;
                        ast.Product2Id = sol.Product__c;
                        ast.AccountId = soRec.Account__c;
                        ast.SerialNumber = sol.Serial_Numbers__c;
                        ast.Asset_Number__c = sol.Serial_Numbers__c;
                        assetList.add(ast);
                    }else{
                        List<string> serialNumberList = sol.Serial_Numbers__c.split(',');
                        for(string str : serialNumberList){
                            Asset ast = new Asset();
                            ast.Name = str;
                            ast.Product2Id = sol.Product__c;
                            ast.AccountId = soRec.Account__c;
                            ast.SerialNumber = str;
                            ast.Asset_Number__c = str;
                            assetList.add(ast);
                        }
                    }
                    
                }
            }
            System.debug('assetList::'+assetList);
            if(assetList.size() != 0){
                insert assetList;
                List<WorkOrderLineItem> woliListWithoutDublicates = new List<WorkOrderLineItem>();
                Set<string> slNumber = new Set<string>();
                for(Asset ast : assetList){
                    for(WorkOrderLineItem wol : woliList){
                        if(slNumber.contains(wol.SOLI_Serial_Number__c)) continue;
                        if(wol.SOLI_Serial_Number__c == ast.SerialNumber){
                            wol.AssetId = ast.Id;
                            woliListWithoutDublicates.add(wol);
                            slNumber.add(wol.SOLI_Serial_Number__c);
                        }
                    }
                }
                if(woliListWithoutDublicates.size() != 0){
                    upsert woliListWithoutDublicates;
                    System.debug('upsert...');
                }
                Set<Id> astIds = new Set<Id>();
                for(Asset ast : assetList){
                    astIds.add(ast.Id);
                }
                List<Asset> astList2 = [SELECT Id, Name, Product2.Name FROM Asset WHERE Id IN: astIds];
                for(Asset asst : astList2){
                    asst.Name = asst.Product2.Name;
                }
                update astList2;
            }
        }
    }
    public static void insertCaseSerialNumber(List<Sales_Order_Line__c> solList){
        Set<Id> soIds = new Set<Id>();
        for(Sales_Order_Line__c sol : solList){
            soIds.add(sol.Sales_Order__c);
        }
        SalesOrderLineTriggerHandler.updateCaseSerialNumber2(soIds);
    }
    public static void updateCaseSerialNumber(Map<Id, Sales_Order_Line__c> solListNew, Map<Id, Sales_Order_Line__c> solListOld){
        Set<Id> soIds = new Set<Id>();
        for(Sales_Order_Line__c sol : solListNew.values()){
            if(sol.Serial_Numbers__c == solListOld.get(sol.Id).Serial_Numbers__c) continue;
            soIds.add(sol.Sales_Order__c);
        }
        SalesOrderLineTriggerHandler.updateCaseSerialNumber2(soIds);
    }
    public static void updateCaseSerialNumber2(Set<Id> soIds){
        Set<Id> caseIds = new Set<Id>();
        List<String> commaSeperatedSerialNumbers = new List<String>();
        List<Sales_Order__c> soList = [SELECT id,Case__c,(SELECT Id,Serial_Numbers__c,Sales_Order__c FROM Sales_Order_Lines__r) FROM Sales_Order__c WHERE id in: soIds];
        for(Sales_Order__c so : soList){
            caseIds.add(so.Case__c);
            for(Sales_Order_Line__c soli : so.Sales_Order_Lines__r){
                if(soli.Serial_Numbers__c != null){
                    commaSeperatedSerialNumbers.add(soli.Serial_Numbers__c);
                }
            }
            System.debug('commaSeperatedSerialNumbers-->' + commaSeperatedSerialNumbers);
        }
        list<case> csList = [SELECT id,Serial_Numbers__c FROM case WHERE Id In: caseIds];
        for(case cs : csList){
            if(commaSeperatedSerialNumbers.size() >0){
                if(commaSeperatedSerialNumbers.size() == 1){
                    cs.Serial_Numbers__c = commaSeperatedSerialNumbers[0];
                } else{
                    cs.Serial_Numbers__c = String.join(commaSeperatedSerialNumbers,',');
                }
            } else {
                cs.Serial_Numbers__c = null;
            }
        }
        update csList;
    }
}