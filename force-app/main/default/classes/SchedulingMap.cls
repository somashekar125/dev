public without sharing class SchedulingMap {
    public Datetime selectedDate {get;set;}
    public Boolean showForSelectedDate {get;set;}
    public Integer weekNum {get;set;}

    public SchedulingMap() {
        selectedDate = null;
    }

    @AuraEnabled(cacheable=true)
    public static String getUserTimezone() {
        User currentUser = [SELECT TimeZoneSidKey FROM User WHERE Id = :UserInfo.getUserId()];
        System.debug('timezone '+currentUser.TimeZoneSidKey);
        return currentUser.TimeZoneSidKey;
    }

    @RemoteAction  @AuraEnabled
    public static Map<String, Object> getProjAccts(Id projectId, String selectedDateValue, Boolean showForSelectedDate, Integer weekNum) {
        System.debug('selectedDateValue-> ' + selectedDateValue);
        System.debug('showForSelectedDate-> ' + showForSelectedDate);
        System.debug('weekNum-> ' + weekNum);
        Date dateSelected;
        Date weekStartDate = null;
        Date weekEndDate = null;
        if(!String.isBlank(selectedDateValue)){
            if(selectedDateValue.contains('-')){
                List<String> dateParts = selectedDateValue.split('-');    
                if (dateParts.size() == 3) {
                    Integer year = Integer.valueOf(dateParts[0]);
                    Integer month = Integer.valueOf(dateParts[1]);
                    Integer day = Integer.valueOf(dateParts[2]);
                    if(year != null && month !=null && day != null){
                        dateSelected = Date.newInstance(year, month, day);
                    }                    
                } else {
                    System.debug('Invalid date format');
                }
            }
        }
        if (weekNum != null && weekNum != 0) {
            Date startOfYear = Date.newInstance(Date.today().year(), 1, 1);
            weekStartDate = startOfYear.addDays((weekNum - 1) * 7);
            weekEndDate = weekStartDate.addDays(6);
        }

        Map<String, Object> resultMap = new Map<String, Object>();
        
        String query = 'SELECT Id, Name,Start_Time__c, Account__c, Project__r.Name, Account__r.Name, Account__r.Timezone__c, Account__r.ShippingStreet,Project__r.Daily_Sites__c,' +
                        'Account__r.ShippingCity, Account__r.ShippingState, Account__r.ShippingCountry, Account__r.ShippingPostalCode,Project__r.Total_Work_Days__c, ' +
                        'Account__r.ShippingLatitude, Account__r.ShippingLongitude, Project__r.Visit_Offset__c, Project__r.Start_Time__c, Project__r.Start_Date__c, Project__r.End_Date__c,' +
                        'Visit_1__c, Visit_2__c, Visit_3__c, Project__r.Applicable_on_Days__c, Account__r.Metro_Area__c,Project__r.Number_of_visits__c,Project__r.Work_Weeks__c FROM Project_Account__c '+ 
                        'WHERE Project__c = :projectId AND Account__c != null ORDER BY Account__r.Name';

        List<Project_Account__c> projectAccounts = Database.query(query);
        System.debug('projectAccounts.size-->'+projectAccounts.size());
        Date startDate;
        Date endDate;
        Decimal workWeeks;
        Decimal totalWorkDays;
        Decimal dailySites;

        if(projectAccounts.size() == 0) return null;
        if(projectAccounts[0].Project__r.Start_Date__c == null){
            startDate = null;
        }else{
            startDate = projectAccounts[0].Project__r.Start_Date__c;
        } 
        if(projectAccounts[0].Project__r.End_Date__c == null){
            endDate = null;
        } else{
            endDate = projectAccounts[0].Project__r.End_Date__c;
        }
        if(projectAccounts[0].Project__r.Work_Weeks__c == null){
            workWeeks = null;
        } else {
            workWeeks = projectAccounts[0].Project__r.Work_Weeks__c;
        }
        if(projectAccounts[0].Project__r.Total_Work_Days__c == null){
            totalWorkDays = null;
        } else {
            totalWorkDays = projectAccounts[0].Project__r.Total_Work_Days__c;
        } 
        if(projectAccounts[0].Project__r.Daily_Sites__c == null){
            dailySites = null;
        } else {
            dailySites = projectAccounts[0].Project__r.Daily_Sites__c;
        }
        for(Project_Account__c pa: projectAccounts){
            if(pa.Visit_1__c == null) pa.Visit_1__c = null;
            if(pa.Visit_2__c == null) pa.Visit_2__c = null;
            if(pa.Visit_3__c == null) pa.Visit_3__c = null;
            
        }

        System.debug('projectAccounts -->' + JSON.serialize(projectAccounts));
        List<Project_Account__c> filteredAccounts = new List<Project_Account__c>();
        System.debug('dateSelected -->' + dateSelected);
        for (Project_Account__c pa : projectAccounts) {
            if(dateSelected != null){
                if ((pa.Visit_1__c != null && pa.Visit_1__c.date() == dateSelected) ||
                    (pa.Visit_2__c != null && pa.Visit_2__c.date() == dateSelected) ||
                    (pa.Visit_3__c != null && pa.Visit_3__c.date() == dateSelected)) {
                    filteredAccounts.add(pa);
                }
            } else if(weekStartDate != null && weekEndDate != null) {
                if((pa.Visit_1__c != null && pa.Visit_1__c.date() >= weekStartDate && pa.Visit_1__c.date() <= weekEndDate) ||
                   (pa.Visit_2__c != null && pa.Visit_2__c.date() >= weekStartDate && pa.Visit_2__c.date() <= weekEndDate) ||
                   (pa.Visit_3__c != null && pa.Visit_3__c.date() >= weekStartDate && pa.Visit_3__c.date() <= weekEndDate)){
                    filteredAccounts.add(pa);
                }
            } else {
            filteredAccounts = projectAccounts;
            }
        }
        System.debug('filteredAccounts -->' + JSON.serialize(filteredAccounts));

        //Marker info window
        for (Project_Account__c pa: filteredAccounts) {
            pa.Visits__c = ''; 
            if (pa.Visit_1__c == null && pa.Visit_2__c == null && pa.Visit_3__c == null) continue;
            String htmlBody = '<ul>'; 
            for (Integer i = 1; i <= 3; i++) {
                String visitFieldName = 'Visit_' + i + '__c';
                DateTime dt = (DateTime) pa.get(visitFieldName);
                if (dt == null) continue;
                String dt2 = dt.format('MM/dd/yyyy hh:mm a');
                if (pa.get(visitFieldName) != null) 
                    htmlBody += '<li><strong>Visit ' + i + ' : </strong>' + dt2 +  ' (' +pa.Account__r.Timezone__c + ')'+'<br></li>'; 
            }
            htmlBody += '</ul>';
            pa.Visits__c = htmlBody;
            System.debug('pa.Visits__c-->'+pa.Visits__c);
        }

        Integer totalStores = filteredAccounts.size();
        Integer totalVisits = 0;
        
        for(Project_Account__c pa : filteredAccounts) {
            for(Integer i = 1; i <= 3; i++) {
                String visitField = 'Visit_' + i + '__c';
                if(pa.get(visitField) != null) {
                    totalVisits++;
                }
            }
        }
        resultMap.put('projAccounts', filteredAccounts);

        resultMap.put('totalStores', totalStores);
        resultMap.put('totalVisits', totalVisits);

        resultMap.put('startdate', startDate);
        resultMap.put('enddate', endDate);
        resultMap.put('workweeks', workWeeks);
        resultMap.put('totalworkdays', totalWorkDays);
        resultMap.put('dailysites', dailySites);
        
        List<Project_Account__c> paList = Database.query(query);
        List<Project_Account__c> filteredAccounts2 = new List<Project_Account__c>();
        for (Project_Account__c pa : paList) {
            if(dateSelected != null && showForSelectedDate == true){
                if ((pa.Visit_1__c != null && pa.Visit_1__c.date() == dateSelected) ||
                    (pa.Visit_2__c != null && pa.Visit_2__c.date() == dateSelected) ||
                    (pa.Visit_3__c != null && pa.Visit_3__c.date() == dateSelected)) {
                        filteredAccounts2.add(pa);
                }
            } else if(weekStartDate != null && weekEndDate != null && showForSelectedDate == true) {
                if((pa.Visit_1__c != null && pa.Visit_1__c.date() >= weekStartDate && pa.Visit_1__c.date() <= weekEndDate) ||
                (pa.Visit_2__c != null && pa.Visit_2__c.date() >= weekStartDate && pa.Visit_2__c.date() <= weekEndDate) ||
                (pa.Visit_3__c != null && pa.Visit_3__c.date() >= weekStartDate && pa.Visit_3__c.date() <= weekEndDate)){
                    filteredAccounts2.add(pa);
                }
            } else {
                filteredAccounts2 = paList;
            }
        }
        if(filteredAccounts2.size() > 0 && filteredAccounts2[0].Project__r.Visit_Offset__c != null){
            filteredAccounts2 = SchedulingVisits.populateVisitsOnLoad(filteredAccounts2, 'Visit 2');
            filteredAccounts2 = SchedulingVisits.populateVisitsOnLoad(filteredAccounts2, 'Visit 3');
        } 
        resultMap.put('filteredAccounts', JSON.serialize(filteredAccounts2));

        return resultMap;
    }
    
    @RemoteAction
    public static void scheduleVisit(String accountId, String projectId, String datetimeValue) {
        System.debug('accountId Value: ' + accountId);
        System.debug('projectId Value: ' + projectId);
        System.debug('Datetime Value: ' + datetimeValue);
        
        List<Project_Account__c> projectAccounts = [SELECT Id, Project__c, Start_Time__c, Visit_1__c, Visit_2__c, Visit_3__c, Account__c,
                                                    Account__r.Metro_Area__c, Account__r.Timezone__c, Account__r.ShippingStreet, Account__r.Shippingcity,
                                                    Account__r.ShippingState, Account__r.ShippingCountry, Account__r.ShippingPostalCode, Account__r.ShippingLatitude, Project__r.Visit_Offset__c, Project__r.Start_Time__c, Project__r.Applicable_on_Days__c,
                                                    Account__r.ShippingLongitude FROM Project_Account__c WHERE Project__c = :projectId AND Account__c = :accountId LIMIT 1];
        System.debug('projectAccounts : ' + JSON.serialize(projectAccounts));

        datetimeValue = datetimeValue.replace('T', ' ');
        List<String> tempList = datetimeValue.split(' ');
        Date dt;
        Time tm;
        DateTime scheduleDateTime;
        for(String s : tempList){
            System.debug('characters in comments-> ' + s);
            if(s.contains('-') && s.countMatches('-') == 2){
                String[] strDateSplit = s.split('-');
                Integer yr = Integer.valueOf(strDateSplit[0]);
                Integer mn = Integer.valueOf(strDateSplit[1]);
                Integer dy = Integer.valueOf(strDateSplit[2]);
                dt = Date.newInstance(yr,mn,dy);

                System.debug('date value-> ' + dt);
            }
            if(s.contains(':') && s.countMatches(':') == 1){
                String[] strTimeSplit = s.split(':');
                if(!strTimeSplit[0].isNumeric()) continue;
                if(!strTimeSplit[1].isNumeric()) continue;
                if(strTimeSplit[0] != null && strTimeSplit[1] != null){
                    Integer hr = Integer.valueOf(strTimeSplit[0]);
                    Integer min = Integer.valueOf(strTimeSplit[1]);
                    tm = Time.newInstance(hr,min,0,0);
                    System.debug('time value-> ' + tm);
                }
            }
        }
        if(dt != null && tm != null){
            DateTime tempdt = DateTime.newInstance(dt,tm);
            String visit = 'All Visits';
            if(projectAccounts[0].Visit_1__c == null) {
                projectAccounts[0].Visit_1__c = tempdt;
                visit = 'VISIT 1';
            } else if(projectAccounts[0].Visit_2__c == null) {
                projectAccounts[0].Visit_2__c = tempdt;
                visit = 'VISIT 2';
            } else if(projectAccounts[0].Visit_3__c == null) {
                projectAccounts[0].Visit_3__c = tempdt;
                visit = 'VISIT 3';
            }
            update projectAccounts;
        }
    }


    @AuraEnabled
    public static Map<String, Map<String, Integer>> getVisitData(String selectedDate, String recordId, Integer weekNum) {
        System.debug('selected date -->' + selectedDate);
        Date dt;
        Date weekStartDate = null;
        Date weekEndDate = null;

        if (selectedDate != null) {
            List<String> tempList = selectedDate.split(' ');
            for (String s : tempList) {
                System.debug('characters in comments-> ' + s);
                if (s.contains('-') && s.countMatches('-') == 2) {
                    String[] strDateSplit = s.split('-');
                    Integer yr = Integer.valueOf(strDateSplit[0]);
                    Integer mn = Integer.valueOf(strDateSplit[1]);
                    Integer dy = Integer.valueOf(strDateSplit[2]);
                    dt = Date.newInstance(yr, mn, dy);
                    System.debug('date value-> ' + dt);
                }
            }
            System.debug('selected date -->' + dt);
        }
        if (weekNum != 0) {
            Date startOfYear = Date.newInstance(Date.today().year(), 1, 1);
            weekStartDate = startOfYear.addDays((weekNum - 1) * 7);
            weekEndDate = weekStartDate.addDays(6);
        }
        
        List<Project_Account__c> projectAccounts = [
            SELECT Visit_1__c, Visit_2__c, Visit_3__c, Account__r.Metro_Area__c, Project__c, Project__r.Number_of_visits__c
            FROM Project_Account__c 
            WHERE (Visit_1__c != null OR Visit_2__c != null OR Visit_3__c != null) AND Project__c = :recordId AND Account__r.Metro_Area__c != null
        ];
        System.debug('projectAccounts -->' + JSON.serialize(projectAccounts));
        
        List<Project_Account__c> filteredAccounts = new List<Project_Account__c>();
        for (Project_Account__c pa : projectAccounts) {
            if (dt != null) {           
                if ((pa.Visit_1__c != null && pa.Visit_1__c.date() == dt) ||
                    (pa.Visit_2__c != null && pa.Visit_2__c.date() == dt) ||
                    (pa.Visit_3__c != null && pa.Visit_3__c.date() == dt)) {
                    filteredAccounts.add(pa);
                }
            } else if(weekStartDate != null && weekEndDate != null) {
                if((pa.Visit_1__c != null && pa.Visit_1__c.date() >= weekStartDate && pa.Visit_1__c.date() <= weekEndDate) ||
                   (pa.Visit_2__c != null && pa.Visit_2__c.date() >= weekStartDate && pa.Visit_2__c.date() <= weekEndDate) ||
                   (pa.Visit_3__c != null && pa.Visit_3__c.date() >= weekStartDate && pa.Visit_3__c.date() <= weekEndDate)){
                    filteredAccounts.add(pa);
                }
            } else {
                filteredAccounts = projectAccounts;
            }
        }
        
        Map<String, Map<String, Integer>> metroAreaVisitData = new Map<String, Map<String, Integer>>();

        for (Project_Account__c pa : filteredAccounts) {
            String metroArea = pa.Account__r.Metro_Area__c;
            Decimal numberOfVisits = pa.Project__r.Number_of_visits__c;

            if (!metroAreaVisitData.containsKey(metroArea)) {
                metroAreaVisitData.put(metroArea, new Map<String, Integer>{
                    'Visit_1__c' => 0,
                    'Visit_2__c' => 0,
                    'Visit_3__c' => 0
                });
            }

            if (numberOfVisits == null || numberOfVisits >= 1) {
                if (pa.Visit_1__c != null) {
                    metroAreaVisitData.get(metroArea).put('Visit_1__c', metroAreaVisitData.get(metroArea).get('Visit_1__c') + 1);
                }
            } 
             if (numberOfVisits == null || numberOfVisits >= 2) {
                if (pa.Visit_2__c != null) {
                    metroAreaVisitData.get(metroArea).put('Visit_2__c', metroAreaVisitData.get(metroArea).get('Visit_2__c') + 1);
                }
            } 
            if (numberOfVisits == null || numberOfVisits >= 3) {
                if (pa.Visit_3__c != null) {
                    metroAreaVisitData.get(metroArea).put('Visit_3__c', metroAreaVisitData.get(metroArea).get('Visit_3__c') + 1);
                }
            }
        }
        return metroAreaVisitData;
    }


    @AuraEnabled
    public static Map<String, Integer> getAccountData(String selectedDate, String recordId, Integer weekNum) {
        Map<String, Integer> timezoneCounts = new Map<String, Integer>();
        System.debug('weekNum-->'+weekNum);
        Date dt = null;
        Date weekStartDate = null;
        Date weekEndDate = null;
    
        if (selectedDate != null) {
            List<String> tempList = selectedDate.split(' ');
            for (String s : tempList) {
                System.debug('characters in comments-> ' + s);
                if (s.contains('-') && s.countMatches('-') == 2) {
                    String[] strDateSplit = s.split('-');
                    Integer yr = Integer.valueOf(strDateSplit[0]);
                    Integer mn = Integer.valueOf(strDateSplit[1]);
                    Integer dy = Integer.valueOf(strDateSplit[2]); 
                    dt = Date.newInstance(yr, mn, dy);
                    System.debug('date value-> ' + dt);
                    break;
                }
            }
            System.debug('selected date -->' + dt);
        } 
        if (weekNum != 0) {
            Date startOfYear = Date.newInstance(Date.today().year(), 1, 1);
            weekStartDate = startOfYear.addDays((weekNum - 1) * 7);
            weekEndDate = weekStartDate.addDays(6); 
        }
    
        List<Project_Account__c> accounts = [SELECT Timezone__c, Visit_1__c, Visit_2__c, Visit_3__c FROM Project_Account__c WHERE Project__c = :recordId];
    
        List<Project_Account__c> filteredAccounts = new List<Project_Account__c>();
        for (Project_Account__c pa : accounts) {
            if (dt != null) {           
                if ((pa.Visit_1__c != null && pa.Visit_1__c.date() == dt) ||
                    (pa.Visit_2__c != null && pa.Visit_2__c.date() == dt) ||
                    (pa.Visit_3__c != null && pa.Visit_3__c.date() == dt)) {
                    filteredAccounts.add(pa);
                }
            } else if(weekStartDate != null && weekEndDate != null) {
                if((pa.Visit_1__c != null && pa.Visit_1__c.date() >= weekStartDate && pa.Visit_1__c.date() <= weekEndDate) ||
                   (pa.Visit_2__c != null && pa.Visit_2__c.date() >= weekStartDate && pa.Visit_2__c.date() <= weekEndDate) ||
                   (pa.Visit_3__c != null && pa.Visit_3__c.date() >= weekStartDate && pa.Visit_3__c.date() <= weekEndDate)){
                    filteredAccounts.add(pa);
                }
            } else {
                filteredAccounts = accounts;
            }
        }
    
        for (Project_Account__c account : filteredAccounts) {
            String timezone = account.Timezone__c;
            if (timezone != null) {
                if (timezoneCounts.containsKey(timezone)) {
                    timezoneCounts.put(timezone, timezoneCounts.get(timezone) + 1);
                } else {
                    timezoneCounts.put(timezone, 1);
                }
            }
        }
    
        System.debug('timezoneCounts--> ' + JSON.serialize(timezoneCounts));
        return timezoneCounts;
    }

    @AuraEnabled
    public static List<Project_Account__c> getProjAccVisitsData(String selectedDate, String recordId, Integer weekNum) {
        Date dt = null;
        Date weekStartDate = null;
        Date weekEndDate = null;

        if (selectedDate != null) {
            List<String> tempList = selectedDate.split(' ');
            for (String s : tempList) {
                if (s.contains('-') && s.countMatches('-') == 2) {
                    String[] strDateSplit = s.split('-');
                    Integer yr = Integer.valueOf(strDateSplit[0]);
                    Integer mn = Integer.valueOf(strDateSplit[1]);
                    Integer dy = Integer.valueOf(strDateSplit[2]);
                    dt = Date.newInstance(yr, mn, dy);
                    break;
                }
            }
        }

        if (weekNum != 0) {
            Date startOfYear = Date.newInstance(Date.today().year(), 1, 1);
            weekStartDate = startOfYear.addDays((weekNum - 1) * 7);
            weekEndDate = weekStartDate.addDays(6);
        }

        List<Project_Account__c> accounts = [SELECT Timezone__c, Name,Start_Time__c, Visit_1__c, Visit_2__c, Visit_3__c, Account__r.Metro_Area__c FROM Project_Account__c WHERE Project__c = :recordId];

        List<Project_Account__c> filteredAccounts = new List<Project_Account__c>();

        for (Project_Account__c pa : accounts) {
            if (dt != null) {
                if ((pa.Visit_1__c != null && pa.Visit_1__c.date() == dt) ||
                    (pa.Visit_2__c != null && pa.Visit_2__c.date() == dt) ||
                    (pa.Visit_3__c != null && pa.Visit_3__c.date() == dt)) {
                    filteredAccounts.add(pa);
                }
            } else if (weekStartDate != null && weekEndDate != null) {
                if ((pa.Visit_1__c != null && pa.Visit_1__c.date() >= weekStartDate && pa.Visit_1__c.date() <= weekEndDate) ||
                    (pa.Visit_2__c != null && pa.Visit_2__c.date() >= weekStartDate && pa.Visit_2__c.date() <= weekEndDate) ||
                    (pa.Visit_3__c != null && pa.Visit_3__c.date() >= weekStartDate && pa.Visit_3__c.date() <= weekEndDate)) {
                    filteredAccounts.add(pa);
                }
            } else {
                filteredAccounts.add(pa);
            }
        }
        List<Project_Account__c> updatedAccounts = new List<Project_Account__c>();
        if(!filteredAccounts.isEmpty()) {
            for (Project_Account__c projAcc : filteredAccounts) {
                if(projAcc.Visit_1__c !=null){
                    DateTime desiredDateTime = DateTime.newInstance(projAcc.Visit_1__c.year(), projAcc.Visit_1__c.month(), projAcc.Visit_1__c.day(), projAcc.Visit_1__c.hour(), projAcc.Visit_1__c.minute(), projAcc.Visit_1__c.second());
                
                    TimeZone nyTimeZone = TimeZone.getTimeZone(String.valueOf(UserInfo.getTimeZone()));

                    Integer offset = nyTimeZone.getOffset(desiredDateTime) / 1000;
                    System.debug('offset-->'+offset);
                    DateTime utcDateTime = desiredDateTime.addSeconds(offset);
                    projAcc.Visit_1__c = utcDateTime;
                    System.debug('Stored projAcc.Visit_1__c in UTC: ' + projAcc.Visit_1__c);
                } else if (projAcc.Visit_2__c !=null) {
                    DateTime desiredDateTime = DateTime.newInstance(projAcc.Visit_2__c.year(), projAcc.Visit_2__c.month(), projAcc.Visit_2__c.day(), projAcc.Visit_2__c.hour(), projAcc.Visit_2__c.minute(), projAcc.Visit_2__c.second());
                
                    TimeZone nyTimeZone = TimeZone.getTimeZone(String.valueOf(UserInfo.getTimeZone()));

                    Integer offset = nyTimeZone.getOffset(desiredDateTime) / 1000;
                    DateTime utcDateTime = desiredDateTime.addSeconds(offset);
                    projAcc.Visit_2__c = utcDateTime;
                    System.debug('Stored projAcc.Visit_1__c in UTC: ' + projAcc.Visit_2__c);
                } else if (projAcc.Visit_3__c !=null) {
                    DateTime desiredDateTime = DateTime.newInstance(projAcc.Visit_3__c.year(), projAcc.Visit_3__c.month(), projAcc.Visit_3__c.day(), projAcc.Visit_3__c.hour(), projAcc.Visit_3__c.minute(), projAcc.Visit_3__c.second());
                
                    TimeZone nyTimeZone = TimeZone.getTimeZone(String.valueOf(UserInfo.getTimeZone()));

                    Integer offset = nyTimeZone.getOffset(desiredDateTime) / 1000;
                    DateTime utcDateTime = desiredDateTime.addSeconds(offset);
                    projAcc.Visit_3__c = utcDateTime;
                    System.debug('Stored projAcc.Visit_1__c in UTC: ' + projAcc.Visit_3__c);
                }
                updatedAccounts.add(projAcc);
            }
        }

        System.debug('filteredAccounts-->'+JSON.serialize(updatedAccounts));
        return updatedAccounts;
    }

    @AuraEnabled
    public static List<Project_Account__c> getProjAccforDownload(String recordId) {

        List<Project_Account__c> accounts = [SELECT Timezone__c, Name, Start_Time__c, Visit_1__c, Visit_2__c,Project__c, Visit_3__c, Quantity_of_Devices__c, Comments__c, Dispatcher__c,
                                            Site_Status__c, Qty_Old_Devices__c, Account__r.Metro_Area__c, Account__r.Name, Account__r.Timezone__c, Account__r.ShippingStreet,
                                            Precall_Notes__c, Precall_Complete__c, Precall_Contact_Name__c,
                                            Account__r.ShippingCountry, Account__r.ShippingState, Account__r.ShippingCity, Account__r.ShippingPostalCode FROM Project_Account__c 
                                            WHERE Project__c = :recordId];

        List<Project_Account__c> filteredAccounts = new List<Project_Account__c>();

        if (!accounts.isEmpty()) {
            TimeZone userTimeZone = TimeZone.getTimeZone(String.valueOf(UserInfo.getTimeZone()));
            
            for (Project_Account__c projAcc : accounts) {
                if (projAcc.Visit_1__c != null) {
                    projAcc.Visit_1__c = convertToUTC(projAcc.Visit_1__c, userTimeZone);
                }
                if (projAcc.Visit_2__c != null) {
                    projAcc.Visit_2__c = convertToUTC(projAcc.Visit_2__c, userTimeZone);
                }
                if (projAcc.Visit_3__c != null) {
                    projAcc.Visit_3__c = convertToUTC(projAcc.Visit_3__c, userTimeZone);
                }
                filteredAccounts.add(projAcc);
            }
        }

        System.debug('filteredAccounts-->' + JSON.serialize(filteredAccounts));
        return filteredAccounts;
    }

    private static DateTime convertToUTC(DateTime originalDateTime, TimeZone userTimeZone) {
        Integer offset = userTimeZone.getOffset(originalDateTime) / 1000;
        return originalDateTime.addSeconds(offset);
    }

    @AuraEnabled
    public static void updateProjectAccounts(String newDateTimeListStr, String updateDateTimeListStr, Map<Id, List<String>> data) {
        List<Project_Account__c> prjAccList = new List<Project_Account__c>();
        Map<Id,Project_Account__c> newMap = new Map<Id,Project_Account__c>();

        if (!String.isBlank(newDateTimeListStr)) {
            List<Project_Account__c> prjAccListUpdate = (List<Project_Account__c>) JSON.deserialize(updateDateTimeListStr, List<Project_Account__c>.class);
            List<Project_Account__c> prjAccList1 = (List<Project_Account__c>) JSON.deserialize(newDateTimeListStr, List<Project_Account__c>.class);
            prjAccListUpdate.addAll(prjAccList1);

            for (Project_Account__c projAcc : prjAccListUpdate) {
                if (!data.containsKey(projAcc.Id)) continue;
                List<String> fieldList = data.get(projAcc.Id);
                if(fieldList.contains('Visit_1__c')) {
                    projAcc.Visit_1__c = convertToUserTimezone(projAcc.Visit_1__c);
                }
                if(fieldList.contains('Visit_2__c')) {
                    projAcc.Visit_2__c = convertToUserTimezone(projAcc.Visit_2__c);
                }
                if(fieldList.contains('Visit_3__c')) {
                    projAcc.Visit_3__c = convertToUserTimezone(projAcc.Visit_3__c);
                }
                newMap.put(projAcc.Id, projAcc);
            }
        }

        if(!newMap.isEmpty()){
            update newMap.values();
        }
    }

    @AuraEnabled
    public static DateTime convertToUserTimezone(DateTime localDateTime) {
        TimeZone userTimeZone = TimeZone.getTimeZone(String.valueOf(UserInfo.getTimeZone()));
        Integer offset = userTimeZone.getOffset(localDateTime) / 1000;
        DateTime newDT = localDateTime.addSeconds(-offset);
        return newDT;
    }

    @auraEnabled
    public static Project__c getProject(String recordId) {
        Project__c projectList = [SELECT Id, Name, Start_Time__c, Visit_Offset__c, Applicable_on_Days__c,Number_of_visits__c FROM Project__c WHERE Id =:recordId];
        System.debug('projAccs--->'+JSON.serialize(projectList));
        return projectList;
    }

    @auraEnabled
    public static Map<String, String> getProjectAcc(String paList , String orderBy) {
        List<Project_Account__c> projectAccountsList = (List<Project_Account__c>) JSON.deserialize(paList, List<Project_Account__c>.class);
        Set<Id> projAccId = new Set<Id>();
        System.debug('paList--> : ' + JSON.serialize(projectAccountsList));
        for(Project_Account__c p: projectAccountsList){
            projAccId.add(p.Id);
        }
        String query = 'SELECT Id,Start_Time__c, Project__c,Account__r.Name, Visit_1__c, Visit_2__c, Visit_3__c, Account__c,' +
                        'Account__r.Metro_Area__c, Account__r.Timezone__c, Account__r.ShippingStreet, Account__r.Shippingcity,' +
                        'Account__r.ShippingState, Account__r.ShippingCountry, Account__r.ShippingPostalCode, Account__r.ShippingLatitude,' + 
                        'Project__r.Visit_Offset__c, Project__r.Start_Time__c, Project__r.Applicable_on_Days__c,Project__r.Number_of_visits__c,' +
                        'Account__r.ShippingLongitude FROM Project_Account__c WHERE Id IN :projAccId ' + orderBy;

        List<Project_Account__c> projectAccounts = Database.query(query);
        System.debug('projectAccounts : ' + JSON.serialize(projectAccounts));
        Map<String, String> paMap = new  Map<String, String>();

        String paListStr = JSON.serialize(projectAccounts);
        if(projectAccounts.size() > 0 && (projectAccounts[0].Project__r.Visit_Offset__c != null)){
            List<Project_Account__c> paList1 = SchedulingVisits.populateVisitsOnLoad(projectAccounts, 'Visit 2');
            paList1 = SchedulingVisits.populateVisitsOnLoad(projectAccounts, 'Visit 3');
            paMap.put(paListStr, JSON.serialize(paList1));
        } else {
            paMap.put(paListStr, JSON.serialize(projectAccounts));
        }
        return paMap;
    }
}