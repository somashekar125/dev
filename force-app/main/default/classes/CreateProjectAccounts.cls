public with sharing class CreateProjectAccounts {

    @AuraEnabled
    public static List<Account> getChildAccounts(Id projectId){
        List<Project__c> projectList = [SELECT Id, Name, Client__c FROM Project__c WHERE Id =: projectId];
        System.debug('projectList -->'+JSON.serialize(projectList));
        if(!projectList.isEmpty()){
            List<Account> accList = [SELECT Id, Name, ParentId, ShippingStreet, ShippingCity, Type, Active__c, ShippingState, ShippingCountry, ShippingPostalCode, ShippingLatitude,
            						 Root_Account__c FROM Account WHERE Id NOT IN (SELECT Account__c FROM Project_Account__c WHERE Project__c = :projectList[0].Id) AND 
                                     (ParentId = :projectList[0].Client__c OR Root_Account__c = :projectList[0].Client__c) AND Type = 'Store' AND Active__c = true ORDER BY Name];
            System.debug('accList -->'+JSON.serialize(accList));
            return accList;
        }
        return null;
    }

    @AuraEnabled
    public static List<Account> projectAccountCreation(List<Account> accountList, String projectId){
        if(!accountList.isEmpty() && !String.isBlank(projectId)) {
            List<Project_Account__c> projAccList = new List<Project_Account__c>();
            for (Account acc : accountList) {
                Project_Account__c pa = new Project_Account__c();
                pa.Name = acc.Name;
                pa.Account__c = acc.Id;
                pa.Project__c = projectId;
                projAccList.add(pa);
            }
            if(!projAccList.isEmpty()) {
                insert projAccList;
            }
        }
        return getChildAccounts(projectId);
    }


    @AuraEnabled(cacheable=true)
    public static List<Account> searchAccounts(String searchKey, String projectId) {
        Map<Id,Account> accMap = new Map<Id,Account>();
        searchKey = searchKey + '%';
        String searchKey2 = '%' + searchKey + '%';
        List<Project__c> projectList = [SELECT Id, Name, Client__c FROM Project__c WHERE Id =: projectId];
        if(!projectList.isEmpty()){
            List<Account> accList = [SELECT Id, Name, ParentId, ShippingStreet, ShippingCity, ShippingState, ShippingCountry, ShippingPostalCode, ShippingLatitude,
                                    Root_Account__c FROM Account WHERE Id NOT IN (SELECT Account__c FROM Project_Account__c) AND 
                                    (ParentId = :projectList[0].Client__c OR Root_Account__c = :projectList[0].Client__c) AND Name LIKE :searchKey ORDER BY Name];
             List<Account> accList2 = [SELECT Id, Name, ParentId, ShippingStreet, ShippingCity, ShippingState, ShippingCountry, ShippingPostalCode, ShippingLatitude,
                                        Root_Account__c FROM Account WHERE Id NOT IN (SELECT Account__c FROM Project_Account__c) AND 
                                        (ParentId = :projectList[0].Client__c OR Root_Account__c = :projectList[0].Client__c) AND Name LIKE :searchKey2 ORDER BY Name];
            accMap.putAll(accList);
            accMap.putAll(accList2);
        }
        return accMap.values();
    }

    @AuraEnabled
    public static List<Project_Account__c> getExistingProjectAccounts(String projectId) {
        List<Project_Account__c> existingProjectAccounts = new List<Project_Account__c>();
        if (!String.isBlank(projectId)) {
            existingProjectAccounts = [SELECT Id, Name, Account__c, Project__c FROM Project_Account__c WHERE Project__c = :projectId ORDER BY Name];
        }
        return existingProjectAccounts;
    }

    @AuraEnabled
    public static List<Project_Account__c> deleteProjectAccount(String projectId, List<Id> projectAccountIds) {
        try {
            if (String.isNotBlank(projectId) && projectAccountIds != null && !projectAccountIds.isEmpty()) {
                List<Project_Account__c> projectAccountsToDelete = [
                    SELECT Id FROM Project_Account__c WHERE Project__c = :projectId AND Id IN :projectAccountIds
                ];
                if (!projectAccountsToDelete.isEmpty()) {
                    delete projectAccountsToDelete;
                }
            }
        } catch (Exception e) {
            System.debug('Error deleting project accounts: ' + e.getMessage());
        }
        return getExistingProjectAccounts(projectId);
    }

    @AuraEnabled
    public static List<Project_Account__c> searchProjectAccounts(String searchKey, String projectId) {
        Map<Id,Project_Account__c> projAccMap = new Map<Id,Project_Account__c>();
        searchKey = searchKey + '%';
        String searchKey2 = '%' + searchKey + '%';
        List<Project__c> projectList = [SELECT Id, Name, Client__c FROM Project__c WHERE Id =: projectId];
        if(!projectList.isEmpty()){
            List<Project_Account__c> accList = [SELECT Id, Name, Account__c, Project__c FROM Project_Account__c WHERE Project__c IN :projectList AND Name LIKE :searchKey ORDER BY Name];
            List<Project_Account__c> accList2 = [SELECT Id, Name, Account__c, Project__c FROM Project_Account__c WHERE Project__c IN :projectList AND Name LIKE :searchKey2 ORDER BY Name];
            projAccMap.putAll(accList);
            projAccMap.putAll(accList2);
        }
        return projAccMap.values();
    }

    @AuraEnabled
    public static String processCSVFile(Id projectId, String fileContents) {
        List<Project_Account__c> projectAccountsToCreate = new List<Project_Account__c>();
        List<Project_Account__c> projectAccountsToUpdate = new List<Project_Account__c>();
        List<String> csvRows = fileContents.split('\n');
        String errorMessage = '';

        Map<String, Integer> headerMap = parseHeaders(csvRows[0].toLowerCase());

        for (Integer i = 1; i < csvRows.size(); i++) {
            List<String> csvValues = parseCSVRow(csvRows[i]);

            if (csvValues.size() >= headerMap.size()) {
                String name;
                String projectName;
                String accountName;
                Decimal quantityOfDevices;
                Decimal qtyOldDevices;
                Time startTime;
                Boolean precallComplete;

                String projectAccId = getValueByHeader(headerMap, csvValues, 'id');
                if(String.isNotBlank(getValueByHeader(headerMap, csvValues, 'name'))){
                    name = getValueByHeader(headerMap, csvValues, 'name');
                } else if(String.isNotBlank(getValueByHeader(headerMap, csvValues, 'project account name'))){
                    name = getValueByHeader(headerMap, csvValues, 'project account name');
                } else {
                    errorMessage = 'Set CSV Column Header for Project Account Name as either Name or Project Account Name.';
                }
                if(String.isNotBlank(getValueByHeader(headerMap, csvValues, 'project'))){
                    projectName = getValueByHeader(headerMap, csvValues, 'project');
                } else if(String.isNotBlank(getValueByHeader(headerMap, csvValues, 'projectid'))){
                    projectName = getValueByHeader(headerMap, csvValues, 'projectid');
                } else if(String.isNotBlank(getValueByHeader(headerMap, csvValues, 'project id'))){
                    projectName = getValueByHeader(headerMap, csvValues, 'project id');
                }
                else {
                    errorMessage = 'Set CSV Column Header for ProjectId as either Project or ProjectId';
                }
                if(String.isNotBlank(getValueByHeader(headerMap, csvValues, 'account'))){
                    accountName = getValueByHeader(headerMap, csvValues, 'account');
                } else if(String.isNotBlank(getValueByHeader(headerMap, csvValues, 'accountid'))){
                    accountName = getValueByHeader(headerMap, csvValues, 'accountid');
                }else if(String.isNotBlank(getValueByHeader(headerMap, csvValues, 'account id'))){
                    accountName = getValueByHeader(headerMap, csvValues, 'account id');
                } else {
                    errorMessage = 'Set CSV Column Header for AccountId as either Account or AccountId';
                }

                Datetime visit1 = getVisitDatetime(headerMap, csvValues, 'visit 1', 'visit 1 datetime', 'visit 1 date', 'visit 1 time');
                Datetime visit2 = getVisitDatetime(headerMap, csvValues, 'visit 2', 'visit 2 datetime', 'visit 2 date', 'visit 2 time');
                Datetime visit3 = getVisitDatetime(headerMap, csvValues, 'visit 3', 'visit 3 datetime', 'visit 3 date', 'visit 3 time');
                
                if(getValueByHeader(headerMap, csvValues, 'quantity of devices') != null && isNumeric(getValueByHeader(headerMap, csvValues, 'quantity of devices'))) {
                    quantityOfDevices = Decimal.valueOf(getValueByHeader(headerMap, csvValues, 'quantity of devices'));
                }
                String comments = getValueByHeader(headerMap, csvValues, 'comments');
                String siteStatus = getValueByHeader(headerMap, csvValues, 'site status');
                if(getValueByHeader(headerMap, csvValues, 'qty old devices') != null && isNumeric(getValueByHeader(headerMap, csvValues, 'qty old devices'))) {
                    qtyOldDevices = Decimal.valueOf(getValueByHeader(headerMap, csvValues, 'qty old devices'));
                }
                String dispatcher = getValueByHeader(headerMap, csvValues, 'dispatcher');
                if (getValueByHeader(headerMap, csvValues, 'start time') != null) {
                    String startTimeString = getValueByHeader(headerMap, csvValues, 'start time');
                    if (!String.isBlank(startTimeString)) {
                        String timeString = convertTo24HourFormat(startTimeString);
                        List<String> timeParts = timeString.split(':');
                        Integer hour = Integer.valueOf(timeParts[0]);
                        Integer minute = Integer.valueOf(timeParts[1]);
                        Integer second = Integer.valueOf(timeParts[2]);
                        
                        startTime = Time.newInstance(hour, minute, second, 0);
                    }
                }  
                if (getValueByHeader(headerMap, csvValues, 'precall complete') != null) {
                    String precallComplete1 = getValueByHeader(headerMap, csvValues, 'precall complete');
                    if (!String.isBlank(precallComplete1)) {
                        precallComplete = Boolean.valueOf(precallComplete1);
                    }
                }
                String precallContactName = getValueByHeader(headerMap, csvValues, 'precall contact name');
                String precallNotes = getValueByHeader(headerMap, csvValues, 'precall notes');

                if (projectAccId != null && projectAccId.startsWith('a0t')) {
                    //update
                    Project_Account__c projectAccountToInsert = new Project_Account__c();
                    //Project Account Id in production starts with 'a1q' but in sandbox 'a0t'
                    if (String.isNotBlank(projectAccId) && projectAccId.startsWith('a0t')) {
                        projectAccountToInsert.Id = projectAccId;
                    } else {
                        errorMessage = 'Project Account Id is missing or invalid in one or more rows.';
                        return errorMessage;
                    }
                    
                    projectAccountToInsert.Name = name;
                    if (String.isNotBlank(accountName) && accountName.startsWith('001')) {
                        projectAccountToInsert.Account__c = accountName;
                    }
                    
                    projectAccountToInsert.Visit_1__c = visit1;
                    projectAccountToInsert.Visit_2__c = visit2;
                    projectAccountToInsert.Visit_3__c = visit3;
                    if(quantityOfDevices != null) {
                        projectAccountToInsert.Quantity_of_Devices__c = quantityOfDevices;
                    }
                    projectAccountToInsert.Comments__c = comments;
                    projectAccountToInsert.Site_Status__c = siteStatus;
                    if(qtyOldDevices != null) {
                        projectAccountToInsert.Qty_Old_Devices__c = qtyOldDevices;
                    }
                    projectAccountToInsert.Dispatcher__c = dispatcher;
                    projectAccountToInsert.Start_Time__c = startTime;
                    if(precallComplete != null) {
                        projectAccountToInsert.Precall_Complete__c = precallComplete;
                    }
                    projectAccountToInsert.Precall_Contact_Name__c = precallContactName;
                    projectAccountToInsert.Precall_Notes__c = precallNotes;

                    projectAccountsToUpdate.add(projectAccountToInsert);
                } else {
                    //insert
                    Project_Account__c projectAccountToInsert = new Project_Account__c();
                    projectAccountToInsert.Name = name;
                    
                    if (String.isNotBlank(projectName) && projectName.startsWith('a0n')) {
                        projectAccountToInsert.Project__c = projectName;
                    } else {
                        errorMessage = 'Project is missing or invalid in one or more rows.';
                        return errorMessage;
                    }
                    
                    if (String.isNotBlank(accountName) && accountName.startsWith('001')) {
                        projectAccountToInsert.Account__c = accountName;
                    } else {
                        errorMessage = 'Account is missing or invalid in one or more rows.';
                        return errorMessage;
                    }
                    
                    projectAccountToInsert.Visit_1__c = visit1;
                    projectAccountToInsert.Visit_2__c = visit2;
                    projectAccountToInsert.Visit_3__c = visit3;
                    if(quantityOfDevices != null) {
                        projectAccountToInsert.Quantity_of_Devices__c = quantityOfDevices;
                    }
                    projectAccountToInsert.Comments__c = comments;
                    projectAccountToInsert.Site_Status__c = siteStatus;
                    if(qtyOldDevices != null) {
                        projectAccountToInsert.Qty_Old_Devices__c = qtyOldDevices;
                    }
                    projectAccountToInsert.Dispatcher__c = dispatcher;
                    projectAccountToInsert.Start_Time__c = startTime;
                    projectAccountToInsert.Precall_Complete__c = precallComplete;
                    projectAccountToInsert.Precall_Contact_Name__c = precallContactName;
                    projectAccountToInsert.Precall_Notes__c = precallNotes;

                    projectAccountsToCreate.add(projectAccountToInsert);
                }
            }
        }

        if (!projectAccountsToCreate.isEmpty() && String.isBlank(errorMessage) && Schema.sObjectType.Project_Account__c.isCreateable()) {
            try {
                System.debug('projectAccountsToCreate-->'+JSON.serialize(projectAccountsToCreate));
                ProjectAccountTriggerHandler.checkForDuplicates(projectAccountsToCreate);
                insert projectAccountsToCreate;
            }  catch (Exception e){
                errorMessage = 'A Project Account with this Account already exists for this Project.';
            }    
        }
        if (!projectAccountsToUpdate.isEmpty() && String.isBlank(errorMessage) && Schema.sObjectType.Project_Account__c.isUpdateable()) {
            update projectAccountsToUpdate;
        }
        return errorMessage == '' ? 'Success' : errorMessage;
    }

    private static Datetime getVisitDatetime(Map<String, Integer> headerMap, List<String> csvValues, String combinedHeader, String posibleHeader, String dateHeader, String timeHeader) {
        String combinedDateTimeStr = getValueByHeader(headerMap, csvValues, combinedHeader);
        String posibleDateTimeStr = getValueByHeader(headerMap, csvValues, posibleHeader);
        System.debug('combinedDateTimeStr-->'+combinedDateTimeStr);
        Datetime validDateTime = null;
        if (String.isNotBlank(combinedDateTimeStr)) {
            try {
                if(isValidDateTime(combinedDateTimeStr)) {
                    validDateTime = Datetime.valueOf(combinedDateTimeStr.replace('T', ' ').replace('Z', ''));
                }           
                return validDateTime;
            } catch (Exception e) {
                System.debug('Failed to parse combined datetime: ' + validDateTime);
                return null;
            }
        } else if (String.isNotBlank(posibleDateTimeStr)){
            try {
                if(isValidDateTime(posibleDateTimeStr)) {
                    validDateTime = Datetime.valueOf(posibleDateTimeStr.replace('T', ' ').replace('Z', ''));
                }           
                return validDateTime;
            } catch (Exception e) {
                System.debug('Failed to parse combined datetime: ' + validDateTime);
                return null;
            }
        } else {
            String dateStr = getValueByHeader(headerMap, csvValues, dateHeader);
            String timeStr = getValueByHeader(headerMap, csvValues, timeHeader);
            return handleDateTime(dateStr, timeStr);
        }
    }
 
    public static Boolean isNumeric(String str) {
        if (String.isBlank(str)) {
            return false;
        }
        return Pattern.matches('^[-+]?\\d+(\\.\\d+)?$', str);
    }

    private static Map<String, Integer> parseHeaders(String headerRow) {
        Map<String, Integer> headerMap = new Map<String, Integer>();
        List<String> headers = parseCSVRow(headerRow);
    
        for (Integer i = 0; i < headers.size(); i++) {
            headerMap.put(headers[i].trim(), i);
        }
        return headerMap;
    }
        
    private static String getValueByHeader(Map<String, Integer> headerMap, List<String> csvValues, String header) {
        if (headerMap.containsKey(header) && headerMap.get(header) < csvValues.size()) {
            return csvValues[headerMap.get(header)].trim();
        }
        return null;
    }
    
    private static Datetime getDatetimeFromHeaders(Map<String, Integer> headerMap, List<String> csvValues, String dateHeader, String timeHeader) {
        String dateStr = getValueByHeader(headerMap, csvValues, dateHeader);
        String timeStr = getValueByHeader(headerMap, csvValues, timeHeader);
    
        if (String.isNotBlank(dateStr) && String.isNotBlank(timeStr)) {
            Datetime combinedDateTimeStr = handleDateTime(dateStr, timeStr);
            try {
                return combinedDateTimeStr;
            } catch (Exception e) {
                System.debug('Failed to parse datetime: ' + combinedDateTimeStr);
                return null;
            }
        }
        return null;
    }

    private static Boolean isValidDateTime(String dateTimeStr) {
        try {
            String formattedDateTimeStr = dateTimeStr.replace('T', ' ').replace('Z', '');
            Datetime.valueOf(formattedDateTimeStr);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    private static Datetime handleDateTime(String dateStr, String timeStr) {
        if (String.isNotBlank(dateStr)) {
            dateStr = dateStr.trim().replace('\r', '').replace('\n', '');

            String standardizedDate = standardizeDateFormat(dateStr);

            if (String.isNotBlank(timeStr)) {
                timeStr = timeStr.trim().replace('\r', '').replace('\n', '');
                String standardizedTime = convertTo24HourFormat(timeStr);

                String combinedDateTime = standardizedDate + ' ' + standardizedTime;
                return parseDatetime(combinedDateTime);
            } else {
                return parseDatetime(standardizedDate);
            }
        }
        return null;
    }

    private static String standardizeDateFormat(String dateStr) {
        if (dateStr.contains('-')) {
            if (dateStr.split('-')[0].length() == 4) {
                return dateStr;
            } else {
                List<String> parts = dateStr.split('-');
                return parts[2] + '-' + parts[1] + '-' + parts[0];
            }
        } else if (dateStr.contains('/')) {
            List<String> parts = dateStr.split('/');
            if (parts[0].length() == 4) {
                return parts[0] + '-' + parts[1] + '-' + parts[2];
            } else {
                return parts[2] + '-' + parts[1] + '-' + parts[0];
            }
        } else {
            throw new IllegalArgumentException('Unsupported date format: ' + dateStr);
        }
    }

    private static String convertTo24HourFormat(String timeStr) {
        timeStr = timeStr.toUpperCase();
        List<String> timeParts = timeStr.split(' ');
        if (timeParts.size() != 2) {
            throw new IllegalArgumentException('Unsupported time format: ' + timeStr);
        }
        String timeValue = timeParts[0];
        String period = timeParts[1];

        List<String> hourMinute = timeValue.split(':');
        Integer hour = Integer.valueOf(hourMinute[0]);
        String minute = hourMinute[1];

        if (period == 'AM' && hour == 12) {
            hour = 0;
        } else if (period == 'PM' && hour != 12) {
            hour += 12;
        }

        String hourString = (hour < 10) ? '0' + hour : String.valueOf(hour);
        return hourString + ':' + minute + ':00';
    }

    private static Datetime parseDatetime(String datetimeString) {
        if (String.isNotBlank(datetimeString)) {
            datetimeString = datetimeString.trim().replace('\r', '').replace('\n', '');
            String formattedDateTime = datetimeString.replaceAll('T', ' ').replaceAll('\\.\\d{3}Z$', '');
            return Datetime.valueOf(formattedDateTime);
        }
        return null;
    }

    private static List<String> parseCSVRow(String csvRow) {
        List<String> parsedValues = new List<String>();
        Boolean inQuotes = false;
        String value = '';

        for (Integer i = 0; i < csvRow.length(); i++) {
            String charAt = csvRow.substring(i, i + 1);
            if (charAt == '"') {
                inQuotes = !inQuotes;
            } else if (charAt == ',' && !inQuotes) {
                parsedValues.add(value);
                value = '';
            } else {
                value += charAt;
            }
        }
        parsedValues.add(value);
        return parsedValues;
    }
}