public with sharing class SchedulingVisits {
    public static String serializedProjAccList { get; set; }
    public ApexPages.StandardSetController setCon;

    public SchedulingVisits(ApexPages.StandardSetController controller) {
        this.setCon = controller;
        System.debug('this.setCon--> '+this.setCon);
    }

    public PageReference init() {

        String buttonName = ApexPages.currentPage().getParameters().get('buttonName');
        System.debug('Button Name: ' + buttonName);

        String recordIds = ApexPages.currentPage().getParameters().get('selectedIds');
        System.debug('recordIds: ' + recordIds);

        List<Project_Account__c> selected = setCon.getSelected();
        if (selected != null) {
            serializedProjAccList = JSON.serialize(selected);              
        } else {
            serializedProjAccList = '[]';
        }
        
        System.debug('Selected Project Accounts: ' + serializedProjAccList);
        return null;
    }

    @AuraEnabled(cacheable=true)
    public static String getUserTimezone() {
        User currentUser = [SELECT TimeZoneSidKey FROM User WHERE Id = :UserInfo.getUserId()];
        System.debug('timezone '+currentUser.TimeZoneSidKey);
        return currentUser.TimeZoneSidKey;
    }

    @auraEnabled
    public static Project__c getProjectRecord(String recordId) {
        Project__c projects = [SELECT Id, Name, Visit_Offset__c, Start_Time__c, Applicable_on_Days__c, Number_of_visits__c FROM Project__c WHERE Id =:recordId];
        System.debug('projAccs--->'+JSON.serialize(projects));
        return projects;
    }

    @AuraEnabled
    public static List<Project_Account__c> getSelectedList(List<Id> projAccList, String recordId, String visit, String orderBy) {
        System.debug('Input Project Account List: ' + JSON.serialize(projAccList));
        System.debug('recordId-->'+recordId);
        String query = 'SELECT Id, Name,Start_Time__c, Account__c, Project__r.Name, Account__r.Name, Account__r.Timezone__c, Account__r.ShippingStreet, ' +
                        'Account__r.ShippingCity, Account__r.ShippingState, Account__r.ShippingCountry, Account__r.ShippingPostalCode, ' +
                        'Account__r.ShippingLatitude, Account__r.ShippingLongitude, Project__r.Visit_Offset__c, Project__r.Start_Time__c,' +
                        'Visit_1__c,Visit_2__c, Visit_3__c, Project__r.Applicable_on_Days__c, Account__r.Metro_Area__c,Project__r.Number_of_visits__c FROM Project_Account__c ';

        if (projAccList.isEmpty()) {
            query += 'WHERE Project__c = :recordId ';
        } else {
            query += 'WHERE Id IN :projAccList ';
        }
        query += orderBy;
        System.debug('query-> ' + query);
        List<Project_Account__c> paList = Database.query(query);
        if(paList.size() == 0) return null;
        List<Project_Account__c> filteredPaList = new List<Project_Account__c>();
        for (Project_Account__c pa : paList) {
            if (visit == 'VISIT 2' && pa.Visit_1__c == null) {
                continue;
            }
            if (visit == 'VISIT 3' && pa.Visit_2__c == null) {
                continue;
            }
            filteredPaList.add(pa);
        }
        for(Project_Account__c pa: filteredPaList){
            if(visit == 'VISIT 1' && pa.Visit_1__c == null) pa.Visit_1__c = null;
            if(visit == 'VISIT 2' && pa.Visit_2__c == null) pa.Visit_2__c = null;
            if(visit == 'VISIT 3' && pa.Visit_3__c == null) pa.Visit_3__c = null;
        }
        System.debug('Fetched Project Account List before: ' + JSON.serialize(filteredPaList));
        //filteredPaList = timeZoneConversion(filteredPaList, visit, true);list
        filteredPaList = populateVisitsOnLoad(filteredPaList, visit);
        System.debug('Fetched Project Account List after: ' + JSON.serialize(filteredPaList));
        return filteredPaList;
    }

    @AuraEnabled
    public static void SchedulingVisit(String newDateTimeListStr, String updateDateTimeListStr, String visit) {
        List<Project_Account__c> prjAccList = new List<Project_Account__c>();
        if(!String.isBlank(newDateTimeListStr)) {
            for (Project_Account__c projAcc : (List<Project_Account__c>) JSON.deserialize(newDateTimeListStr, List<Project_Account__c>.class)) {
                if(visit == 'VISIT 1' && projAcc.Visit_1__c !=null){
                    DateTime desiredDateTime = DateTime.newInstance(projAcc.Visit_1__c.year(), projAcc.Visit_1__c.month(), projAcc.Visit_1__c.day(), projAcc.Visit_1__c.hour(), projAcc.Visit_1__c.minute(), projAcc.Visit_1__c.second());
                
                    TimeZone nyTimeZone = TimeZone.getTimeZone(String.valueOf(UserInfo.getTimeZone()));

                    Integer offset = nyTimeZone.getOffset(desiredDateTime) / 1000;
                    DateTime utcDateTime = desiredDateTime.addSeconds(-offset);
                    projAcc.Visit_1__c = utcDateTime;
                    System.debug('Stored projAcc.Visit_1__c in UTC: ' + projAcc.Visit_1__c);
                } else if (visit == 'VISIT 2' && projAcc.Visit_2__c !=null) {
                    DateTime desiredDateTime = DateTime.newInstance(projAcc.Visit_2__c.year(), projAcc.Visit_2__c.month(), projAcc.Visit_2__c.day(), projAcc.Visit_2__c.hour(), projAcc.Visit_2__c.minute(), projAcc.Visit_2__c.second());
                
                    TimeZone nyTimeZone = TimeZone.getTimeZone(String.valueOf(UserInfo.getTimeZone()));

                    Integer offset = nyTimeZone.getOffset(desiredDateTime) / 1000;
                    DateTime utcDateTime = desiredDateTime.addSeconds(-offset);
                    projAcc.Visit_2__c = utcDateTime;
                    System.debug('Stored projAcc.Visit_1__c in UTC: ' + projAcc.Visit_2__c);
                } else if (visit == 'VISIT 3' && projAcc.Visit_3__c !=null) {
                    DateTime desiredDateTime = DateTime.newInstance(projAcc.Visit_3__c.year(), projAcc.Visit_3__c.month(), projAcc.Visit_3__c.day(), projAcc.Visit_3__c.hour(), projAcc.Visit_3__c.minute(), projAcc.Visit_3__c.second());
                
                    TimeZone nyTimeZone = TimeZone.getTimeZone(String.valueOf(UserInfo.getTimeZone()));

                    Integer offset = nyTimeZone.getOffset(desiredDateTime) / 1000;
                    DateTime utcDateTime = desiredDateTime.addSeconds(-offset);
                    projAcc.Visit_3__c = utcDateTime;
                    System.debug('Stored projAcc.Visit_1__c in UTC: ' + projAcc.Visit_3__c);
                }
                prjAccList.add(projAcc);
            }
        }
        if(!String.isBlank(updateDateTimeListStr)) {
            prjAccList.addAll((List<Project_Account__c>) JSON.deserialize(updateDateTimeListStr, List<Project_Account__c>.class));
        }
        //prjAccList = timeZoneConversion(prjAccList, 'All Visits', false);
        update prjAccList;
    }

    // public static List<Project_Account__c> timeZoneConversion(List<Project_Account__c> paList, String visit, boolean forComponent) {
    //     System.debug('Input Project Account List before update: ' + JSON.serialize(paList));
    //     User currUser = [SELECT Id, TimeZoneSidKey FROM User WHERE Id = :UserInfo.getUserId()];
    //     Set<Id> accIds = new Set<Id>();
    //     Map<String, String> tmzNameIdMap = new Map<String, String>();
    //     List<Timezone_Id__mdt> tzList = [SELECT MasterLabel, QualifiedApiName, Timezon_Id__c FROM Timezone_Id__mdt];
        
    //     for (Project_Account__c pa : paList) {
    //         accIds.add(pa.Account__c);
    //     }
        
    //     Map<Id, Account> accMap = new Map<Id, Account>([SELECT Id, Name, Timezone__c, ShippingState FROM Account WHERE Id IN :accIds]);
        
    //     for (Project_Account__c pa : paList) {
    //         tmzNameIdMap = ASCENACaseMilestoneCalculater.getTimezoneIdForAccount(accMap.get(pa.Account__c), tzList);
    //         if (!tmzNameIdMap.isEmpty()) {
    //             List<String> keyList = new List<String>(tmzNameIdMap.keySet());
    //             String timezoneName = keyList[0];
    //             String timezoneId = tmzNameIdMap.get(timezoneName);
                
    //             if (visit == 'VISIT 1' && pa.Visit_1__c != null) {
    //                 System.debug('populating visit 1');
    //                 pa.Visit1_1__c = timeZoneConversionFromVisit(pa.Visit_1__c, timezoneId, currUser, forComponent);
    //             } else if (visit == 'VISIT 2') {
    //                 if (pa.Visit_2__c != null) {
    //                     System.debug('populating visit 2');
    //                     pa.Visit2_2__c = timeZoneConversionFromVisit(pa.Visit_2__c, timezoneId, currUser, forComponent);
    //                 }
    //             } else if (visit == 'VISIT 3') {
    //                 if (pa.Visit_3__c != null) {
    //                     System.debug('populating visit 3');
    //                     pa.Visit3_3__c = timeZoneConversionFromVisit(pa.Visit_3__c, timezoneId, currUser, forComponent);
    //                 }
    //             } else if (visit == 'All Visits') {
    //                 System.debug('populating for all visits');
    //                 if (pa.Visit_1__c != null) pa.Visit1_1__c = timeZoneConversionFromVisit(pa.Visit_1__c, timezoneId, currUser, forComponent);
    //                 if (pa.Visit_2__c != null) pa.Visit2_2__c = timeZoneConversionFromVisit(pa.Visit_2__c, timezoneId, currUser, forComponent);
    //                 if (pa.Visit_3__c != null) pa.Visit3_3__c = timeZoneConversionFromVisit(pa.Visit_3__c, timezoneId, currUser, forComponent);
    //             }
    //         }
    //     }
    //     return paList;
    // }
    
    public static List<Project_Account__c> timeZoneConversionOnload(List<Project_Account__c> paList, String visit, boolean forComponent) {
        System.debug('Input Project Account List before update: ' + JSON.serialize(paList));
        User currUser = [SELECT Id, TimeZoneSidKey FROM User WHERE Id = :UserInfo.getUserId()];
        Set<Id> accIds = new Set<Id>();
        Map<String, String> tmzNameIdMap = new Map<String, String>();
        List<Timezone_Id__mdt> tzList = [SELECT MasterLabel, QualifiedApiName, Timezon_Id__c FROM Timezone_Id__mdt];
        
        for (Project_Account__c pa : paList) {
            accIds.add(pa.Account__c);
        }
        
        Map<Id, Account> accMap = new Map<Id, Account>([SELECT Id, Name, Timezone__c, ShippingState FROM Account WHERE Id IN :accIds]);
        
        for (Project_Account__c pa : paList) {
            tmzNameIdMap = ASCENACaseMilestoneCalculater.getTimezoneIdForAccount(accMap.get(pa.Account__c), tzList);
            if (!tmzNameIdMap.isEmpty()) {
                List<String> keyList = new List<String>(tmzNameIdMap.keySet());
                String timezoneName = keyList[0];
                String timezoneId = tmzNameIdMap.get(timezoneName);
                
                if (visit == 'VISIT 1' && pa.Visit_1__c != null) {
                    System.debug('populating visit 1');
                    pa.Visit_1__c = timeZoneConversionFromVisit(pa.Visit_1__c, timezoneId, currUser, forComponent);
                } else if (visit == 'VISIT 2') {
                    if (pa.Visit_2__c != null) {
                        System.debug('populating visit 2');
                        pa.Visit_2__c = timeZoneConversionFromVisit(pa.Visit_2__c, timezoneId, currUser, forComponent);
                    }
                } else if (visit == 'VISIT 3') {
                    if (pa.Visit_3__c != null) {
                        System.debug('populating visit 3');
                        pa.Visit_3__c = timeZoneConversionFromVisit(pa.Visit_3__c, timezoneId, currUser, forComponent);
                    }
                }
            }
        }
        return paList;
    }

    @auraEnabled
    public static List<Project_Account__c> populateVisitsOnLoad(List<Project_Account__c> paList, String visit) {
        System.debug('paList--'+JSON.serialize(paList));
        for (Project_Account__c pa : paList) {
            if(pa.Project__r.Applicable_on_Days__c == null) continue;
            Set<String> applicableDays = new Set<String>(pa.Project__r.Applicable_on_Days__c.split(';'));
            if (visit == 'VISIT 2') {
                if(pa.Project__r.Visit_Offset__c != null){
                    if (pa.Visit_1__c != null && pa.Visit_2__c == null) {
                        Integer offsetDays = Integer.valueOf(pa.Project__r.Visit_Offset__c);
                        for (Integer i = offsetDays;; i++) {
                            pa.Visit_2__c = pa.Visit_1__c.addDays(i);
                            String dayOfWeek = pa.Visit_2__c.format('EEEE');
                            if (applicableDays.contains(dayOfWeek)) break;
                        }                           
                        if(pa.Start_Time__c !=null){
                            pa.Visit_2__c = DateTime.newInstance(pa.Visit_2__c.date(), pa.Start_Time__c);
                        } else if (pa.Project__r.Start_Time__c != null) {
                            pa.Visit_2__c = DateTime.newInstance(pa.Visit_2__c.date(), pa.Project__r.Start_Time__c);
                        }else {
                            pa.Visit_2__c = DateTime.newInstance(pa.Visit_2__c.date(), pa.Visit_1__c.time());
                        }
                    }
                }              
            } else if (visit == 'VISIT 3') { 
				if(pa.Project__r.Visit_Offset__c != null){
					if (pa.Visit_2__c != null && pa.Visit_3__c == null) {
						Integer offsetDays = Integer.valueOf(pa.Project__r.Visit_Offset__c);
                        for (Integer i = offsetDays;; i++) {
                            pa.Visit_3__c = pa.Visit_2__c.addDays(i);
                            String dayOfWeek = pa.Visit_3__c.format('EEEE');
                            if (applicableDays.contains(dayOfWeek)) break;
                        }
						if(pa.Start_Time__c !=null){
							pa.Visit_3__c = DateTime.newInstance(pa.Visit_3__c.date(), pa.Start_Time__c);
						} else if(pa.Project__r.Start_Time__c !=null){
							pa.Visit_3__c = DateTime.newInstance(pa.Visit_3__c.date(), pa.Project__r.Start_Time__c);
						} else {
							pa.Visit_3__c = DateTime.newInstance(pa.Visit_3__c.date(), pa.Visit_2__c.time());
						}
					}
				}
            }
        }
        return paList;
    }   
    
    public static Datetime timeZoneConversionFromVisit(Datetime visit, String timezoneId, User currUser, boolean forComponent) {
        Integer storeTimeHours = Integer.valueOf(visit.format('HH', timezoneId));
        Integer userTimeHours = Integer.valueOf(visit.format('HH', currUser.TimeZoneSidKey));
        if (storeTimeHours == 0) {
            storeTimeHours = 24;
        }
        if (userTimeHours == 0) {
            userTimeHours = 24;
        }
        Integer result = 0;
        if (forComponent) {
            result = storeTimeHours - userTimeHours;
        } else {
            result = userTimeHours - storeTimeHours;
        }
        System.debug('result --> ' + result);
        DateTime dt = visit.addHours(result);
        return dt;
    }
}