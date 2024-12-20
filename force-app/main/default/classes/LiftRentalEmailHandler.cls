global class LiftRentalEmailHandler implements Messaging.InboundEmailHandler {
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        System.debug('Email -> ' + email);
        System.debug('Email plainTextBody -> ' + email.plainTextBody);
        System.debug('Email htmlBody-> ' + email.htmlBody);
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        
        List<String> emailBodyLines = null;
        
        if (String.isNotBlank(email.plainTextBody)) {
            emailBodyLines = email.plainTextBody.split('\\n');
            System.debug('emailBodyLines from plaintextbody' + emailBodyLines);
        } else if (String.isNotBlank(email.htmlBody)) {
            emailBodyLines = email.htmlBody.split('\\n');
            System.debug('emailBodyLines from htmlBody' + emailBodyLines);
        } else {
            System.debug('Neither HTML nor PLAIN body specified');
            return result;
        }
        try {
            String woNumberKey = 'PO NUMBER';
            String woNumberKey2 = 'PO';
            String woNumbervalue = null;
            Boolean foundWONumber = false;
            for (String line : emailBodyLines) {
                if (foundWONumber) {
                    // Check if the line is not empty or does not contain unwanted characters
                    line = line.trim();
                    if(String.isEmpty(line) || !line.isNumeric() || (line.length() != 5 && line.length() != 8)) continue;
                    woNumbervalue = line;
                    break;
                }
                // Marking it here so above code will check next lines for value.
                if (line.containsIgnoreCase(woNumberKey) || line.contains(woNumberKey2)) {
                    List<String> temp = line.split(' ');
                    for(String s : temp){
                        if(s == 'PO') {
                            foundWONumber = true;
                            System.debug('foundWONumber in line-> ' + line);
                            break;
                        }
                    }
                    System.debug('PO in line-> ' + line);
                }
            }

            if(woNumbervalue == null || (woNumbervalue.length() != 5 && woNumbervalue.length() != 8)){
                String woNumberKey3 = 'Jobsite';
                String woNumberKey4 = 'Jobsite Name';
                Boolean foundWONumber2 = false;
                for (String line : emailBodyLines) {
                    if (foundWONumber2) {
                        // Check if the line is not empty or does not contain unwanted characters
                        line = line.trim();
                        if (!String.isEmpty(line) && line != '') {
                            line = line.remove(',');
                            List<String> tempList = line.split(' ');
                            String temp = tempList[tempList.size() - 1];
                            if(!temp.isNumeric() || (temp.length() != 5 && temp.length() != 8)) continue;
                            woNumbervalue = temp;
                            break;
                        }
                    }
                    // Marking it here so above code will check next lines for value.
                    if (!line.containsIgnoreCase('Jobsite ID')  && (line.containsIgnoreCase(woNumberKey3) || line.containsIgnoreCase(woNumberKey4))) {
                        System.debug('Jobsite in line-> ' + line);
                        foundWONumber2 = true;
                    }
                }
            }
            
            List<WorkOrder> woList = new List<WorkOrder>();
            Map<String,String> tmzNameIdMap = new Map<String,String>();
            String timezoneId;
            if(woNumbervalue != null && (woNumbervalue.length() == 5 || woNumbervalue.length() == 8)){
                woNumbervalue = '%' + woNumbervalue;
                woList = [SELECT Id, WorkOrderNumber,Pricebook2Id,AccountId,Equipment_Rental_Cost__c,Order_Lift__c,Return_Lift__c, 
                          (SELECT Id,Product2.Name,StartDate,EndDate,unitPrice,Status,Rental_Order_Number__c,Requested_By__c FROM WorkOrderLineItems 
                          WHERE Product2.Name LIKE '%EQUIPMENT-RENTAL%' OR Created_For_Field__c = 'Equipment_Rental_Cost__c') 
                          FROM WorkOrder WHERE WorkOrderNumber LIKE: woNumbervalue LIMIT 1];
                woNumbervalue = woNumbervalue.remove('%');
                if(!woList.isEmpty()){
                    woNumbervalue = woList[0].WorkOrderNumber;
                    List<Account> accList = [SELECT Id, ShippingState, Timezone__c FROM Account WHERE Id =: woList[0].AccountId];
                    if(!accList.isEmpty()){
                        List<Timezone_Id__mdt> tzList = [SELECT MasterLabel, QualifiedApiName, Timezon_Id__c FROM Timezone_Id__mdt];
                        tmzNameIdMap = ASCENACaseMilestoneCalculater.getTimezoneIdForAccount(accList[0], tzList);
                        if (!tmzNameIdMap.isEmpty()) {
                            List<String> keyList = new List<String>(tmzNameIdMap.keySet());
                            String timezoneName = keyList[0];
                            timezoneId = tmzNameIdMap.get(timezoneName);
                        }
                    }
                }
            }
            
            String rentalOrderNum;
            String woliStatus = ''; 
            
            for(String ln : emailBodyLines){
                System.debug('Status in line-> ' + ln);
                if(ln.containsIgnoreCase('Pickup request received')){
                    woliStatus = 'Pickup Requested';
                    continue;
                } else if(ln.containsIgnoreCase('Request received')){
                    woliStatus = 'Lift Requested';
                    continue;
                } else if (ln.containsIgnoreCase('Ready for confirmation')){
                    woliStatus = 'Rental Confirmed';
                    continue;
                } else if(ln.containsIgnoreCase('Your equipment is on the way')){
                    woliStatus = 'Lift In Route';
                    continue;
                } else if(ln.containsIgnoreCase('Your equipment has arrived')){
                    woliStatus = 'Delivered';
                    continue;
                } else if(ln.containsIgnoreCase('Equipment past due')){
                    woliStatus = 'Rental Overdue';
                    continue;
                } else if(ln.containsIgnoreCase('An invoice has been issued for ILLINOIS WHOLESALE') || ln.containsIgnoreCase('An invoice has been issued for')){
                    woliStatus = 'Invoiced';
                    continue;
                } else if(ln.containsIgnoreCase('Rental extended')){
                    woliStatus = 'Rental extended';
                    continue;
                } else if(ln.containsIgnoreCase('FYI')){
                    List<String> tempList = ln.split(' ');
                    for(String s : tempList){
                        s = s.trim();
                        if(!s.isAlpha()) continue;
                        if(s == 'Route'){
                            woliStatus = 'Lift In Route';
                            break;
                        } else if (s == 'Delivered'){
                            woliStatus = 'Lift Delivered';
                            break;
                        } else if (s == 'Requested'){
                            woliStatus = 'Lift Requested';
                            break;
                        }
                    }
                    continue;
                }
                if(ln.containsIgnoreCase('Reservation #') || ln.containsIgnoreCase('Contract #') || ln.containsIgnoreCase('Requisition #')){
                    System.debug('Rental Order in line-> ' + ln);
                    rentalOrderNum = ln.substringAfter('#').trim();
                    continue;
                }
            }
            
            if(rentalOrderNum == null){
                String vendorNumberKey = 'Contract Number';
                Boolean foundVendorNumber = false;
                for (String line : emailBodyLines) {
                    if (foundVendorNumber) {
                        if(line.contains('-')) continue;
                        // Check if the line is not empty or does not contain unwanted characters
                        line = line.trim();
                        if (!String.isEmpty(line) && line != '') {
                            if(line.isNumeric()){
                                rentalOrderNum = line;
                                break;
                            }
                        }
                    }
                    // Marking it here so above code will check next lines for value.
                    if (line.containsIgnoreCase(vendorNumberKey)) {
                        System.debug('Rental order2 in line-> ' + line);
                        foundVendorNumber = true;
                    }
                }
            }
            
            if(woNumbervalue == null && rentalOrderNum != null){
                List<WorkOrderLineItem> woliList = [SELECT Id,Rental_Order_Number__c,WorkOrder.WorkOrderNumber 
                                                    FROM WorkOrderLineItem WHERE Rental_Order_Number__c =: rentalOrderNum LIMIT 1];
                if(!woliList.isEmpty()) woNumbervalue = woliList[0].WorkOrder.WorkOrderNumber;
                if(woNumbervalue != null){
                    woList  =   [SELECT Id, WorkOrderNumber,Pricebook2Id,Account.Timezone__c,Equipment_Rental_Cost__c,Order_Lift__c,Return_Lift__c,
                                 (SELECT Id,Product2.Name,StartDate,EndDate,unitPrice,Status,Rental_Order_Number__c,Requested_By__c FROM WorkOrderLineItems 
                                  WHERE Product2.Name LIKE '%EQUIPMENT-RENTAL%' OR Created_For_Field__c = 'Equipment_Rental_Cost__c') 
                                 FROM WorkOrder WHERE WorkOrderNumber =: woNumbervalue LIMIT 1];
                    if(!woList.isEmpty()){
                        if(!woList.isEmpty()){
                            woNumbervalue = woList[0].WorkOrderNumber;
                            List<Account> accList = [SELECT Id, ShippingState, Timezone__c FROM Account WHERE Id =: woList[0].AccountId];
                            if(!accList.isEmpty()){
                                List<Timezone_Id__mdt> tzList = [SELECT MasterLabel, QualifiedApiName, Timezon_Id__c FROM Timezone_Id__mdt];
                                tmzNameIdMap = ASCENACaseMilestoneCalculater.getTimezoneIdForAccount(accList[0], tzList);
                                if (!tmzNameIdMap.isEmpty()) {
                                    List<String> keyList = new List<String>(tmzNameIdMap.keySet());
                                    String timezoneName = keyList[0];
                                    timezoneId = tmzNameIdMap.get(timezoneName);
                                }
                            }
                        }
                    }
                }
            }
            
            String subtotalKey = 'Subtotal';
            Decimal equipmentRentalCost = null;
            Boolean foundSubtotal = false;
            for (String line : emailBodyLines) {
                if (foundSubtotal) {
                    // Check if the line is not empty or does not contain unwanted characters
                    if (!String.isEmpty(line.trim()) && line != '') {
                        line = line.remove('$').remove(',').trim();
                        equipmentRentalCost = Decimal.valueOf(line);
                        break;
                    }
                }
                // Marking it here so above code will check next lines for value.
                if (line.containsIgnoreCase(subtotalKey)) {
                    System.debug('Equipment Rental Cost in line-> ' + line);
                    foundSubtotal = true;
                }
            }
            
            String invoiceAmountKey = 'Invoice Amount';
            Boolean foundInvoiceAmount = false;
            for (String line : emailBodyLines) {
                if (foundInvoiceAmount) {
                    line = line.trim();
                    if(line.contains('-')) continue;
                    // Check if the line is not empty or does not contain unwanted characters
                    if (!String.isEmpty(line) && line != '') {
                        line = line.remove('$').remove(',').trim();
                        equipmentRentalCost = Decimal.valueOf(line);
                        break;
                    }
                }
                // Marking it here so above code will check next lines for value.
                if (line.containsIgnoreCase(invoiceAmountKey)) {
                    System.debug('Invoice Amount in line-> ' + line);
                    foundInvoiceAmount = true;
                }
            }
            
            String orderedByKey = 'Ordered By';
            String orderedByValue = null;
            Boolean foundOrderedBy = false;
            for (String line : emailBodyLines) {
                if (foundOrderedBy) {
                    // Check if the line is not empty or does not contain unwanted characters
                    if (!String.isEmpty(line.trim()) && line != '') {
                        orderedByValue = line.trim();
                        break;
                    }
                }
                // Marking it here so above code will check next lines for value.
                if (line.containsIgnoreCase(orderedByKey)) {
                    System.debug('Ordered By in line-> ' + line);
                    foundOrderedBy = true;
                }
            }
            
            String estimatedDeliveryDateTimeKey = 'Estimated Delivery';
            String deliveryDateTimeKey = 'Delivery Date/Time';
            String estimateStartKey = 'Estimated Start';
            String estimateEndKey = 'Estimated End';
            String stopDateTimeKey = 'Date Stopped';
            String extendedEndKey = 'New End Date';
            DateTime estimatedDeliveryDateTimeValue;
            DateTime deliveryDateTimeValue;
            DateTime startDateValue;
            DateTime endDateValue;
            DateTime stopDateTimeValue;
            Boolean foundEstimatedDeliveryDateTimeKey = false;
            Boolean foundDeliveryDateTimeKey = false;
            Boolean foundEstimateStartKey = false;
            Boolean foundEstimateEndKey = false;
            Boolean foundStopDateTimeKey = false;
            for (String line : emailBodyLines) {
                if (foundDeliveryDateTimeKey || foundEstimateStartKey || foundEstimateEndKey || foundStopDateTimeKey || foundEstimatedDeliveryDateTimeKey) {
                    // Check if the line is not empty or does not contain unwanted characters
                    if (!String.isEmpty(line.trim()) && line != '') {
                        if(!line.contains('/')) continue;
                        
                        String ampm;
                        if(line.contains('AM')){
                            ampm = 'AM';
                            line = line.replace(' AM', '');
                        } else if(line.contains('PM')){
                            ampm = 'PM';
                            line = line.replace(' AM', '');
                        }
                        
                        List<String> tempList = line.split(' ');
                        Date dt;
                        Time tm;
                        
                        for(String s : tempList){
                            if(s.isNumeric() || s.isAlpha() || s.isAlphaSpace() || s.isAlphanumeric() || s.isAlphanumericSpace()) continue;
                            System.debug('characters in comments-> ' + s);
                            if(s.contains('/') && s.countMatches('/') == 2){
                                String[] strDateSplit = s.split('/');
                                Integer mn = Integer.valueOf(strDateSplit[0]);
                                Integer dy = Integer.valueOf(strDateSplit[1]);
                                Integer yr = Integer.valueOf(strDateSplit[2]);
                                dt = Date.newInstance(yr,mn,dy);
                                
                                System.debug('date value-> ' + dt);
                            }
                            if(s.contains(':') && s.countMatches(':') == 1){
                                String[] strTimeSplit = s.split(':');
                                if(!strTimeSplit[0].isNumeric()) continue;
                                if(!strTimeSplit[1].isNumeric()) continue;
                                if(strTimeSplit[0] != null && strTimeSplit[1] != null){
                                    Integer hr = Integer.valueOf(strTimeSplit[0]);
                                    if(ampm == 'PM'){
                                        hr += 12;
                                    }
                                    Integer min = Integer.valueOf(strTimeSplit[1]);
                                    tm = Time.newInstance(hr,min,0,0);
                                    System.debug('time value-> ' + tm);
                                }
                            }
                            if(dt != null && tm == null){
                                tm = Time.newInstance(7,0,0,0);
                            }
                        }
                        if(dt != null && tm != null){
                            DateTime tempdt = DateTime.newInstance(dt,tm);
                            if(foundEstimatedDeliveryDateTimeKey){
                                if(String.isNotBlank(timezoneId)){
                                    estimatedDeliveryDateTimeValue = DateTime.parse(tempdt.format('MM/dd/yyyy, hh:mm a', timezoneId));
                                    foundEstimatedDeliveryDateTimeKey = false;
                                    continue;
                                } else {
                                    estimatedDeliveryDateTimeValue = DateTime.parse(tempdt.format('MM/dd/yyyy, hh:mm a'));
                                    foundEstimatedDeliveryDateTimeKey = false;
                                    continue;
                                }
                            }
                            if(foundDeliveryDateTimeKey){
                                if(String.isNotBlank(timezoneId)){
                                    deliveryDateTimeValue = DateTime.parse(tempdt.format('MM/dd/yyyy, hh:mm a', timezoneId));
                                    foundDeliveryDateTimeKey = false;
                                    continue;
                                } else {
                                    deliveryDateTimeValue = DateTime.parse(tempdt.format('MM/dd/yyyy, hh:mm a'));
                                    foundDeliveryDateTimeKey = false;
                                    continue;
                                }
                            }
                            if(foundEstimateStartKey){
                                if(String.isNotBlank(timezoneId)){
                                    startDateValue = DateTime.parse(tempdt.format('MM/dd/yyyy, hh:mm a', timezoneId));
                                    foundEstimateStartKey = false;
                                    continue;
                                } else {
                                    startDateValue = DateTime.parse(tempdt.format('MM/dd/yyyy, hh:mm a'));
                                    foundEstimateStartKey = false;
                                    continue;
                                }
                            }
                            if(foundEstimateEndKey){
                                if(String.isNotBlank(timezoneId)){
                                    endDateValue = DateTime.parse(tempdt.format('MM/dd/yyyy, hh:mm a', timezoneId));
                                    foundEstimateEndKey = false;
                                    continue;
                                } else {
                                    endDateValue = DateTime.parse(tempdt.format('MM/dd/yyyy, hh:mm a'));
                                    foundEstimateEndKey = false;
                                    continue;
                                }
                            }
                            if(foundStopDateTimeKey){
                                if(String.isNotBlank(timezoneId)){
                                    stopDateTimeValue = DateTime.parse(tempdt.format('MM/dd/yyyy, hh:mm a', timezoneId));
                                    foundStopDateTimeKey = false;
                                    continue;
                                } else {
                                    stopDateTimeValue = DateTime.parse(tempdt.format('MM/dd/yyyy, hh:mm a'));
                                    foundStopDateTimeKey = false;
                                    continue;
                                }
                            }
                        }
                    }
                }
                // Marking it here so above code will check in next lines for value.
                if (line.containsIgnoreCase(estimatedDeliveryDateTimeKey)) {
                    System.debug('Estimated delivery time in line-> ' + line);
                    foundEstimatedDeliveryDateTimeKey = true;
                }
                if(line.containsIgnoreCase(deliveryDateTimeKey)){
                    System.debug('Delivery time in line-> ' + line);
                    foundDeliveryDateTimeKey = true;
                }
                if (line.containsIgnoreCase(estimateStartKey)) {
                    System.debug('start time in line-> ' + line);
                    foundEstimateStartKey = true;
                }
                if (line.containsIgnoreCase(estimateEndKey) || line.containsIgnoreCase(extendedEndKey)) {
                    System.debug('End Time in line-> ' + line);
                    foundEstimateEndKey = true;
                }
                if (line.containsIgnoreCase(stopDateTimeKey)) {
                    System.debug('stop time in line-> ' + line);
                    foundStopDateTimeKey = true;
                }
            }
            
            System.debug('WO Number-> ' + woNumbervalue);
            System.debug('woliStatus-> ' + woliStatus);
            System.debug('Ordered By-> ' + orderedByValue);
            System.debug('Equipment Rental Cost-> ' + equipmentRentalCost);
            System.debug('rentalOrderNum-> ' + rentalOrderNum);
            System.debug('estimatedDeliveryDateTimeValue-> ' + estimatedDeliveryDateTimeValue);
            System.debug('deliveryDateTimeValue-> ' + deliveryDateTimeValue);
            System.debug('startDateValue-> ' + startDateValue);
            System.debug('endDateValue-> ' + endDateValue);
            System.debug('stopDateTimeValue-> ' + stopDateTimeValue);
            
            System.debug('woList-> ' + JSON.serialize(woList));
            if(!woList.isEmpty()){
                System.debug('woList[0].WorkOrderLineItems.size()-> ' + woList[0].WorkOrderLineItems.size());
                List<User> usrList = new List<User>();
                if(!String.isBlank(orderedByValue)){
                    usrList = [SELECT Id,Name FROM User WHERE Name =: orderedByValue LIMIT 1];
                }
                if(woList[0].WorkOrderLineItems.size() > 0){
                    for(WorkOrderLineItem woli : woList[0].WorkOrderLineItems){
                        if(woliStatus != null && woli.Product2.Name.containsIgnoreCase('COST'))  woli.Status = woliStatus;
                        if(startDateValue != null) woli.StartDate = startDateValue;
                        if(endDateValue != null) woli.EndDate = endDateValue;
                        if(estimatedDeliveryDateTimeValue != null) woli.Estimated_Delivery__c = estimatedDeliveryDateTimeValue;
                        if(deliveryDateTimeValue != null) woli.Delivery_Date_Time__c = deliveryDateTimeValue;
                        if(stopDateTimeValue != null) woli.Date_Stopped__c = stopDateTimeValue;
                        if(rentalOrderNum != null) woli.Rental_Order_Number__c = rentalOrderNum;
                        if(!usrList.isEmpty()) woli.Requested_By__c = usrList[0].Id;
                    }
                    update woList[0].WorkOrderLineItems;
                } else {
                    List<Product_Mapping__mdt> costProductList = Product_Mapping__mdt.getAll().values();
                    System.debug('costProductList-> ' + costProductList);
                    set<String> ProdName = new set<String>();
                    for(Product_Mapping__mdt pm : costProductList){
                        if(pm.Field_API_Name__c != 'Equipment_Rental_Cost__c') continue;
                        if(pm.Charge_Product_Name__c != null) ProdName.add(pm.Charge_Product_Name__c);
                        if(pm.Cost_Product_Name__c != null) ProdName.add(pm.Cost_Product_Name__c);
                    }
                    List<PricebookEntry> pbeList = [SELECT Id,Pricebook2Id,Product2Id,Product2.Description,Product2.Name FROM PricebookEntry 
                                                    WHERE Product2.Name Like :ProdName AND isActive = true AND Pricebook2Id =: woList[0].Pricebook2Id];
                    Id liftRtlId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByDeveloperName().get( 'Equipment_Rental' ).getRecordTypeId();
                    List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
                    for(PricebookEntry pbe : pbeList){
                        if(pbe.Pricebook2Id != woList[0].Pricebook2Id) continue;
                        String status = 'New';
                        if(pbe.Product2.Name.containsIgnoreCase('COST')){
                            status = 'Lift Requested';
                        }
                        WorkOrderLineItem woli = new WorkOrderLineItem();
                        woli.PricebookEntryId = pbe.Id; 
                        woli.unitPrice = equipmentRentalCost;
                        woli.Quantity = 1;
                        woli.RecordTypeId = liftRtlId;
                        woli.WorkOrderId = woList[0].Id;
                        if(startDateValue != null) woli.StartDate = startDateValue;
                        if(endDateValue != null) woli.EndDate = endDateValue;
                        if(estimatedDeliveryDateTimeValue != null) woli.Estimated_Delivery__c = estimatedDeliveryDateTimeValue;
                        if(deliveryDateTimeValue != null) woli.Delivery_Date_Time__c = deliveryDateTimeValue;
                        if(stopDateTimeValue != null) woli.Date_Stopped__c = stopDateTimeValue;
                        if(rentalOrderNum != null) woli.Rental_Order_Number__c = rentalOrderNum;
                        if(!usrList.isEmpty()) woli.Requested_By__c = usrList[0].Id;
                        woli.Vendor__c = 'United Rentals';
                        woli.Status = status;
                        woli.Description = pbe.Product2.Description;
                        woli.Created_For_Field__c = 'Equipment_Rental_Cost__c';
                        woliList.add(woli);
                    }
                    if(!woliList.isEmpty()){
                        insert woliList;
                    }
                }
                Boolean doUpdate = false;
                if(equipmentRentalCost != null){
                    woList[0].Equipment_Rental_Cost__c = equipmentRentalCost;
                    doUpdate = true;
                }
                if(woList[0].Order_Lift__c == false){
                    woList[0].Order_Lift__c = true;
                    doUpdate = true;
                }
                if(woliStatus == 'Pickup Requested' || woliStatus == 'Invoiced'){
                    woList[0].Return_Lift__c = true;
                    doUpdate = true;
                }
                if(doUpdate) {
                    WorkOrderTriggerHandler.runOnceBeforeUpdate = true;
                    WorkOrderTriggerHandler.runOnceAfterUpdate = true;
                    update woList;
                }
            }
        }
        catch (Exception e) {
            System.debug('Exception -> ' + e);           
        }
        return result;
    }
}