public without sharing class DateTimeTimezoned {
    @auraEnabled
    public static Case getCaseRec(String caseId){
        Case c = [SELECT Id,Expected_SLA_Exit_Date__c,Preferred_Time__c,Part_Receipt_Due_DateTime__c,Account.Timezone__c,Technician_OnSite_ETA__c
                    FROM Case WHERE Id =:caseId];
        return c;
    }

    public class CorrectingDateTimesWrapper {
        @AuraEnabled
        public String SLAdateStr {get;set;}
        @AuraEnabled
        public Datetime SLADateTimeValue {get;set;}
        @AuraEnabled
        public String PrefdateStr {get;set;}
        @AuraEnabled
        public Datetime PrefDateTimeValue {get;set;}
        @AuraEnabled
        public String PartdateStr {get;set;}
        @AuraEnabled
        public Datetime PartDateTimeValue {get;set;}
        @AuraEnabled
        public String TechdateStr {get;set;}
        @AuraEnabled
        public Datetime TechDateTimeValue {get;set;}
        @AuraEnabled
        public Boolean saveDate {get;set;}
    }

    @auraEnabled
    public static CorrectingDateTimesWrapper correctingDateTimes(Case caseRec,Boolean saveDate){
        String stroetimezone = '';
        String dateTimeStr = '';
        User currUser = [SELECT Id, TimeZoneSidKey FROM user WHERE Id = :UserInfo.getUserId()];
        List<Timezone_Id__mdt> tzList = [SELECT MasterLabel, QualifiedApiName, Timezon_Id__c FROM Timezone_Id__mdt];
        for(Timezone_Id__mdt tz : tzList) {
            if(tz.MasterLabel == caseRec.Account.Timezone__c){
                stroetimezone = tz.Timezon_Id__c;
            }
        }
        CorrectingDateTimesWrapper dtSave = new CorrectingDateTimesWrapper();
        if(saveDate){
            if(caseRec.Expected_SLA_Exit_Date__c != null){
                //Passing Values Back to CMP.Setting Wrapper Values.
                dateTimeStr = caseRec.Expected_SLA_Exit_Date__c.format('MM/dd/yyyy hh:mm a');
                dtSave.SLAdateStr = dateTimeStr;
                dtSave.SLADateTimeValue = caseRec.Expected_SLA_Exit_Date__c;
                dtSave.saveDate = false;
                //Calculation.
                integer storeTimehours = Integer.valueOf(caseRec.Expected_SLA_Exit_Date__c.format('HH', stroetimezone));
                integer userTimehours = Integer.valueOf(caseRec.Expected_SLA_Exit_Date__c.format('HH', currUser.TimeZoneSidKey));
                if(storeTimehours == 0){
                    storeTimehours = 24;
                }
                if(userTimehours == 0){
                    userTimehours = 24;
                }
                integer result;
                System.debug('caseRec.Expected_SLA_Exit_Date__c before-> ' + caseRec.Expected_SLA_Exit_Date__c);
                //Converting To User TimeZone.
                result = userTimehours - storeTimehours;
                caseRec.Expected_SLA_Exit_Date__c = caseRec.Expected_SLA_Exit_Date__c.addHours(result);
                System.debug('caseRec.Expected_SLA_Exit_Date__c after-> ' + caseRec.Expected_SLA_Exit_Date__c);
            }
            if(caseRec.Preferred_Time__c != null){
                //Passing Values Back to CMP.Setting Wrapper Values.
                dateTimeStr = caseRec.Preferred_Time__c.format('MM/dd/yyyy hh:mm a');
                dtSave.PrefdateStr = dateTimeStr;
                dtSave.PrefDateTimeValue = caseRec.Preferred_Time__c;
                //Calculation.
                integer storeTimehours = Integer.valueOf(caseRec.Preferred_Time__c.format('HH', stroetimezone));
                integer userTimehours = Integer.valueOf(caseRec.Preferred_Time__c.format('HH', currUser.TimeZoneSidKey));
                if(storeTimehours == 0){
                    storeTimehours = 24;
                }
                if(userTimehours == 0){
                    userTimehours = 24;
                }
                integer result;
                System.debug('caseRec.Preferred_Time__c before-> ' + caseRec.Preferred_Time__c);
                result = userTimehours - storeTimehours;
                caseRec.Preferred_Time__c = caseRec.Preferred_Time__c.addHours(result);
                System.debug('caseRec.Preferred_Time__c after-> ' + caseRec.Preferred_Time__c);
            }
            if(caseRec.Part_Receipt_Due_DateTime__c != null){
                //Passing Values Back to CMP.Setting Wrapper Values.
                dateTimeStr = caseRec.Part_Receipt_Due_DateTime__c.format('MM/dd/yyyy hh:mm a');
                dtSave.PartdateStr = dateTimeStr;
                dtSave.PartDateTimeValue = caseRec.Part_Receipt_Due_DateTime__c;
                //Calculation.
                integer storeTimehours = Integer.valueOf(caseRec.Part_Receipt_Due_DateTime__c.format('HH', stroetimezone));
                integer userTimehours = Integer.valueOf(caseRec.Part_Receipt_Due_DateTime__c.format('HH', currUser.TimeZoneSidKey));
                if(storeTimehours == 0){
                    storeTimehours = 24;
                }
                if(userTimehours == 0){
                    userTimehours = 24;
                }
                integer result;
                System.debug('caseRec.Part_Receipt_Due_DateTime__c before-> ' + caseRec.Part_Receipt_Due_DateTime__c);
                result = userTimehours - storeTimehours;
                caseRec.Part_Receipt_Due_DateTime__c = caseRec.Part_Receipt_Due_DateTime__c.addHours(result);
                System.debug('caseRec.Part_Receipt_Due_DateTime__c after-> ' + caseRec.Part_Receipt_Due_DateTime__c);
            }
            if(caseRec.Technician_OnSite_ETA__c != null){
                //Passing Values Back to CMP.Setting Wrapper Values.
                dateTimeStr = caseRec.Technician_OnSite_ETA__c.format('MM/dd/yyyy hh:mm a');
                dtSave.TechdateStr = dateTimeStr;
                dtSave.TechDateTimeValue = caseRec.Technician_OnSite_ETA__c;
                //Calculation.
                integer storeTimehours = Integer.valueOf(caseRec.Technician_OnSite_ETA__c.format('HH', stroetimezone));
                integer userTimehours = Integer.valueOf(caseRec.Technician_OnSite_ETA__c.format('HH', currUser.TimeZoneSidKey));
                if(storeTimehours == 0){
                    storeTimehours = 24;
                }
                if(userTimehours == 0){
                    userTimehours = 24;
                }
                integer result;
                System.debug('caseRec.Technician_OnSite_ETA__c before-> ' + caseRec.Technician_OnSite_ETA__c);
                result = userTimehours - storeTimehours;
                caseRec.Technician_OnSite_ETA__c = caseRec.Technician_OnSite_ETA__c.addHours(result);
                System.debug('caseRec.Technician_OnSite_ETA__c after-> ' + caseRec.Technician_OnSite_ETA__c);
            }
            update caseRec;
        } else{
            if(caseRec.Expected_SLA_Exit_Date__c != null){
                integer storeTimehours = Integer.valueOf(caseRec.Expected_SLA_Exit_Date__c.format('HH', stroetimezone));
                integer userTimehours = Integer.valueOf(caseRec.Expected_SLA_Exit_Date__c.format('HH', currUser.TimeZoneSidKey));
                if(userTimehours == 0){
                    userTimehours = 24;
                }
                integer result;
                System.debug('caseRec.Expected_SLA_Exit_Date__c before-> ' + caseRec.Expected_SLA_Exit_Date__c);
                result = storeTimehours - userTimehours;
                caseRec.Expected_SLA_Exit_Date__c = caseRec.Expected_SLA_Exit_Date__c.addHours(result);
                System.debug('caseRec.Expected_SLA_Exit_Date__c after-> ' + caseRec.Expected_SLA_Exit_Date__c);
                dateTimeStr = caseRec.Expected_SLA_Exit_Date__c.format('MM/dd/yyyy hh:mm a');
                System.debug('dateTimeStr-> ' + dateTimeStr);
                
                dtSave.SLAdateStr = dateTimeStr;
                dtSave.saveDate = false;
                dtSave.SLADateTimeValue = caseRec.Expected_SLA_Exit_Date__c;
            }
            //Preffered DateTime.
            if(caseRec.Preferred_Time__c != null){
                integer storeTimehours = Integer.valueOf(caseRec.Preferred_Time__c.format('HH', stroetimezone));
                integer userTimehours = Integer.valueOf(caseRec.Preferred_Time__c.format('HH', currUser.TimeZoneSidKey));
                if(userTimehours == 0){
                    userTimehours = 24;
                }
                integer result;
                System.debug('caseRec.Preferred_Time__c before-> ' + caseRec.Preferred_Time__c);
                result = storeTimehours - userTimehours;
                caseRec.Preferred_Time__c = caseRec.Preferred_Time__c.addHours(result);
                System.debug('caseRec.Preferred_Time__c after-> ' + caseRec.Preferred_Time__c);
                dateTimeStr = caseRec.Preferred_Time__c.format('MM/dd/yyyy hh:mm a');
                System.debug('dateTimeStr-> ' + dateTimeStr);
                
                dtSave.PrefdateStr = dateTimeStr;
                dtSave.PrefDateTimeValue = caseRec.Preferred_Time__c;
            }
            //Part DateTime.
            if(caseRec.Part_Receipt_Due_DateTime__c != null){
                integer storeTimehours = Integer.valueOf(caseRec.Part_Receipt_Due_DateTime__c.format('HH', stroetimezone));
                integer userTimehours = Integer.valueOf(caseRec.Part_Receipt_Due_DateTime__c.format('HH', currUser.TimeZoneSidKey));
                if(userTimehours == 0){
                    userTimehours = 24;
                }
                integer result;
                System.debug('caseRec.Part_Receipt_Due_DateTime__c before-> ' + caseRec.Part_Receipt_Due_DateTime__c);
                result = storeTimehours - userTimehours;
                caseRec.Part_Receipt_Due_DateTime__c = caseRec.Part_Receipt_Due_DateTime__c.addHours(result);
                System.debug('caseRec.Part_Receipt_Due_DateTime__c after-> ' + caseRec.Part_Receipt_Due_DateTime__c);
                dateTimeStr = caseRec.Part_Receipt_Due_DateTime__c.format('MM/dd/yyyy hh:mm a');
                System.debug('dateTimeStr-> ' + dateTimeStr);
                
                dtSave.PartdateStr = dateTimeStr;
                dtSave.PartDateTimeValue = caseRec.Part_Receipt_Due_DateTime__c;
            }
            //Tech ETA.
            if(caseRec.Technician_OnSite_ETA__c != null){
                integer storeTimehours = Integer.valueOf(caseRec.Technician_OnSite_ETA__c.format('HH', stroetimezone));
                integer userTimehours = Integer.valueOf(caseRec.Technician_OnSite_ETA__c.format('HH', currUser.TimeZoneSidKey));
                if(userTimehours == 0){
                    userTimehours = 24;
                }
                integer result;
                System.debug('caseRec.Technician_OnSite_ETA__c before-> ' + caseRec.Technician_OnSite_ETA__c);
                result = storeTimehours - userTimehours;
                caseRec.Technician_OnSite_ETA__c = caseRec.Technician_OnSite_ETA__c.addHours(result);
                System.debug('caseRec.Technician_OnSite_ETA__c after-> ' + caseRec.Technician_OnSite_ETA__c);
                dateTimeStr = caseRec.Technician_OnSite_ETA__c.format('MM/dd/yyyy hh:mm a');
                System.debug('dateTimeStr-> ' + dateTimeStr);
                
                dtSave.TechdateStr = dateTimeStr;
                dtSave.TechDateTimeValue = caseRec.Technician_OnSite_ETA__c;
            }
        }
        return dtSave;
    }
}