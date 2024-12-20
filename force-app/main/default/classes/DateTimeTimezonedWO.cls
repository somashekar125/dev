public without sharing class DateTimeTimezonedWO {
    @auraEnabled
    public static WorkOrder getWORec(String woId){
        WorkOrder wo = [SELECT Id,SLA_Due_DateTime__c,Technician_OnSite_ETA__c,Preferred_Time_IMAC__c,Account.Timezone__c,Check_In_Time__c,
                        Check_Out_Time__c,Time_Entries__c FROM WorkOrder WHERE Id =:woId];
        return wo;
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
        public String CheckIndateStr {get;set;}
        @AuraEnabled
        public Datetime CheckInDateTimeValue {get;set;}
        @AuraEnabled
        public String CheckOutdateStr {get;set;}
        @AuraEnabled
        public Datetime CheckOutDateTimeValue {get;set;}
        @AuraEnabled
        public String TechdateStr {get;set;}
        @AuraEnabled
        public Datetime TechDateTimeValue {get;set;}
        @AuraEnabled
        public Boolean saveDate {get;set;}
    }

    @auraEnabled
    public static CorrectingDateTimesWrapper correctingDateTimes(WorkOrder woRec,Boolean saveDate){
        String stroetimezone = '';
        String dateTimeStr = '';
        User currUser = [SELECT Id, TimeZoneSidKey FROM user WHERE Id = :UserInfo.getUserId()];
        List<Timezone_Id__mdt> tzList = [SELECT MasterLabel, QualifiedApiName, Timezon_Id__c FROM Timezone_Id__mdt];
        for(Timezone_Id__mdt tz : tzList) {
            if(tz.MasterLabel == woRec.Account.Timezone__c){
                stroetimezone = tz.Timezon_Id__c;
            }
        }
        CorrectingDateTimesWrapper dtSave = new CorrectingDateTimesWrapper();
        if(saveDate){
            if(woRec.SLA_Due_DateTime__c != null){
                //Passing Values Back to CMP.Setting Wrapper Values.
                dateTimeStr = woRec.SLA_Due_DateTime__c.format('MM/dd/yyyy hh:mm a');
                dtSave.SLAdateStr = dateTimeStr;
                dtSave.SLADateTimeValue = woRec.SLA_Due_DateTime__c;
                dtSave.saveDate = false;
                //Calculation.
                integer storeTimehours = Integer.valueOf(woRec.SLA_Due_DateTime__c.format('HH', stroetimezone));
                integer userTimehours = Integer.valueOf(woRec.SLA_Due_DateTime__c.format('HH', currUser.TimeZoneSidKey));
                if(storeTimehours == 0){
                    storeTimehours = 24;
                }
                if(userTimehours == 0){
                    userTimehours = 24;
                }
                integer result;
                System.debug('woRec.SLA_Due_DateTime__c before-> ' + woRec.SLA_Due_DateTime__c);
                //Converting To User TimeZone.
                if(userTimehours > storeTimehours){
                    result = userTimehours - storeTimehours;
                    //adding hours
                    woRec.SLA_Due_DateTime__c = woRec.SLA_Due_DateTime__c.addHours(result);
                }
                if(userTimehours < storeTimehours){
                    result = userTimehours - storeTimehours;
                    //subtracting hours
                    woRec.SLA_Due_DateTime__c = woRec.SLA_Due_DateTime__c.addHours(result);
                }
                System.debug('woRec.SLA_Due_DateTime__c after-> ' + woRec.SLA_Due_DateTime__c);
            }
            if(woRec.Preferred_Time_IMAC__c != null){
                //Passing Values Back to CMP.Setting Wrapper Values.
                dateTimeStr = woRec.Preferred_Time_IMAC__c.format('MM/dd/yyyy hh:mm a');
                dtSave.PrefdateStr = dateTimeStr;
                dtSave.PrefDateTimeValue = woRec.Preferred_Time_IMAC__c;
                //Calculation.
                integer storeTimehours = Integer.valueOf(woRec.Preferred_Time_IMAC__c.format('HH', stroetimezone));
                integer userTimehours = Integer.valueOf(woRec.Preferred_Time_IMAC__c.format('HH', currUser.TimeZoneSidKey));
                if(storeTimehours == 0){
                    storeTimehours = 24;
                }
                if(userTimehours == 0){
                    userTimehours = 24;
                }
                integer result;
                System.debug('woRec.Preferred_Time_IMAC__c before-> ' + woRec.Preferred_Time_IMAC__c);
                if(userTimehours > storeTimehours){
                    result = userTimehours - storeTimehours;
                    //adding hours
                    woRec.Preferred_Time_IMAC__c = woRec.Preferred_Time_IMAC__c.addHours(result);
                }
                if(userTimehours < storeTimehours){
                    result = userTimehours - storeTimehours;
                    //subtracting hours
                    woRec.Preferred_Time_IMAC__c = woRec.Preferred_Time_IMAC__c.addHours(result);
                }
                System.debug('woRec.Preferred_Time_IMAC__c after-> ' + woRec.Preferred_Time_IMAC__c);
            }
            if(woRec.Check_In_Time__c != null){
                //Passing Values Back to CMP.Setting Wrapper Values.
                dateTimeStr = woRec.Check_In_Time__c.format('MM/dd/yyyy hh:mm a');
                dtSave.CheckIndateStr = dateTimeStr;
                dtSave.CheckInDateTimeValue = woRec.Check_In_Time__c;
                //Calculation.
                integer storeTimehours = Integer.valueOf(woRec.Check_In_Time__c.format('HH', stroetimezone));
                integer userTimehours = Integer.valueOf(woRec.Check_In_Time__c.format('HH', currUser.TimeZoneSidKey));
                if(storeTimehours == 0){
                    storeTimehours = 24;
                }
                if(userTimehours == 0){
                    userTimehours = 24;
                }
                integer result;
                System.debug('woRec.Check_In_Time__c before-> ' + woRec.Check_In_Time__c);
                if(userTimehours > storeTimehours){
                    result = userTimehours - storeTimehours;
                    //adding hours
                    woRec.Check_In_Time__c = woRec.Check_In_Time__c.addHours(result);
                }
                if(userTimehours < storeTimehours){
                    result = userTimehours - storeTimehours;
                    //subtracting hours
                    woRec.Check_In_Time__c = woRec.Check_In_Time__c.addHours(result);
                }
                System.debug('woRec.Check_In_Time__c after-> ' + woRec.Check_In_Time__c);
            }
            if(woRec.Check_Out_Time__c != null){
                //Passing Values Back to CMP.Setting Wrapper Values.
                dateTimeStr = woRec.Check_Out_Time__c.format('MM/dd/yyyy hh:mm a');
                dtSave.CheckOutdateStr = dateTimeStr;
                dtSave.CheckOutDateTimeValue = woRec.Check_Out_Time__c;
                //Calculation.
                integer storeTimehours = Integer.valueOf(woRec.Check_Out_Time__c.format('HH', stroetimezone));
                integer userTimehours = Integer.valueOf(woRec.Check_Out_Time__c.format('HH', currUser.TimeZoneSidKey));
                if(storeTimehours == 0){
                    storeTimehours = 24;
                }
                if(userTimehours == 0){
                    userTimehours = 24;
                }
                integer result;
                System.debug('woRec.Check_Out_Time__c before-> ' + woRec.Check_Out_Time__c);
                if(userTimehours > storeTimehours){
                    result = userTimehours - storeTimehours;
                    //adding hours
                    woRec.Check_Out_Time__c = woRec.Check_Out_Time__c.addHours(result);
                }
                if(userTimehours < storeTimehours){
                    result = userTimehours - storeTimehours;
                    //subtracting hours
                    woRec.Check_Out_Time__c = woRec.Check_Out_Time__c.addHours(result);
                }
                System.debug('woRec.Check_Out_Time__c after-> ' + woRec.Check_Out_Time__c);
            }
            if(woRec.Technician_OnSite_ETA__c != null){
                //Passing Values Back to CMP.Setting Wrapper Values.
                dateTimeStr = woRec.Technician_OnSite_ETA__c.format('MM/dd/yyyy hh:mm a');
                dtSave.TechdateStr = dateTimeStr;
                dtSave.TechDateTimeValue = woRec.Technician_OnSite_ETA__c;
                //Calculation.
                integer storeTimehours = Integer.valueOf(woRec.Technician_OnSite_ETA__c.format('HH', stroetimezone));
                integer userTimehours = Integer.valueOf(woRec.Technician_OnSite_ETA__c.format('HH', currUser.TimeZoneSidKey));
                if(storeTimehours == 0){
                    storeTimehours = 24;
                }
                if(userTimehours == 0){
                    userTimehours = 24;
                }
                integer result;
                System.debug('woRec.Technician_OnSite_ETA__c before-> ' + woRec.Technician_OnSite_ETA__c);
                if(userTimehours > storeTimehours){
                    result = userTimehours - storeTimehours;
                    //adding hours
                    woRec.Technician_OnSite_ETA__c = woRec.Technician_OnSite_ETA__c.addHours(result);
                }
                if(userTimehours < storeTimehours){
                    result = userTimehours - storeTimehours;
                    //subtracting hours
                    woRec.Technician_OnSite_ETA__c = woRec.Technician_OnSite_ETA__c.addHours(result);
                }
                System.debug('woRec.Technician_OnSite_ETA__c after-> ' + woRec.Technician_OnSite_ETA__c);
            }
            update woRec;
        } else{
            if(woRec.SLA_Due_DateTime__c != null){
                integer storeTimehours = Integer.valueOf(woRec.SLA_Due_DateTime__c.format('HH', stroetimezone));
                integer userTimehours = Integer.valueOf(woRec.SLA_Due_DateTime__c.format('HH', currUser.TimeZoneSidKey));
                if(userTimehours == 0){
                    userTimehours = 24;
                }
                integer result;
                System.debug('woRec.SLA_Due_DateTime__c before-> ' + woRec.SLA_Due_DateTime__c);
                if(userTimehours > storeTimehours){
                    result = storeTimehours - userTimehours;
                    //subtracting hours
                    woRec.SLA_Due_DateTime__c = woRec.SLA_Due_DateTime__c.addHours(result);
                }
                if(userTimehours < storeTimehours){
                    result = storeTimehours - userTimehours;
                    //adding hours
                    woRec.SLA_Due_DateTime__c = woRec.SLA_Due_DateTime__c.addHours(result);
                }
                System.debug('woRec.SLA_Due_DateTime__c after-> ' + woRec.SLA_Due_DateTime__c);
                dateTimeStr = woRec.SLA_Due_DateTime__c.format('MM/dd/yyyy hh:mm a');
                System.debug('dateTimeStr-> ' + dateTimeStr);
                //Setting Wrapper Values.
                dtSave.SLAdateStr = dateTimeStr;
                dtSave.saveDate = false;
                dtSave.SLADateTimeValue = woRec.SLA_Due_DateTime__c;
            }
            //Preffered DateTime.
            if(woRec.Preferred_Time_IMAC__c != null){
                integer storeTimehours = Integer.valueOf(woRec.Preferred_Time_IMAC__c.format('HH', stroetimezone));
                integer userTimehours = Integer.valueOf(woRec.Preferred_Time_IMAC__c.format('HH', currUser.TimeZoneSidKey));
                if(userTimehours == 0){
                    userTimehours = 24;
                }
                integer result;
                System.debug('woRec.Preferred_Time_IMAC__c before-> ' + woRec.Preferred_Time_IMAC__c);
                if(userTimehours > storeTimehours){
                    result = storeTimehours - userTimehours;
                    //subtracting hours
                    woRec.Preferred_Time_IMAC__c = woRec.Preferred_Time_IMAC__c.addHours(result);
                }
                if(userTimehours < storeTimehours){
                    result = storeTimehours - userTimehours;
                    //adding hours
                    woRec.Preferred_Time_IMAC__c = woRec.Preferred_Time_IMAC__c.addHours(result);
                }
                System.debug('woRec.Preferred_Time_IMAC__c after-> ' + woRec.Preferred_Time_IMAC__c);
                dateTimeStr = woRec.Preferred_Time_IMAC__c.format('MM/dd/yyyy hh:mm a');
                System.debug('dateTimeStr-> ' + dateTimeStr);
                //Setting Wrapper Values.
                dtSave.PrefdateStr = dateTimeStr;
                dtSave.PrefDateTimeValue = woRec.Preferred_Time_IMAC__c;
            }
            //Check In.
            if(woRec.Check_In_Time__c != null){
                integer storeTimehours = Integer.valueOf(woRec.Check_In_Time__c.format('HH', stroetimezone));
                integer userTimehours = Integer.valueOf(woRec.Check_In_Time__c.format('HH', currUser.TimeZoneSidKey));
                if(userTimehours == 0){
                    userTimehours = 24;
                }
                integer result;
                System.debug('woRec.Check_In_Time__c before-> ' + woRec.Check_In_Time__c);
                if(userTimehours > storeTimehours){
                    result = storeTimehours - userTimehours;
                    //subtracting hours
                    woRec.Check_In_Time__c = woRec.Check_In_Time__c.addHours(result);
                }
                if(userTimehours < storeTimehours){
                    result = storeTimehours - userTimehours;
                    //adding hours
                    woRec.Check_In_Time__c = woRec.Check_In_Time__c.addHours(result);
                }
                System.debug('woRec.Check_In_Time__c after-> ' + woRec.Check_In_Time__c);
                dateTimeStr = woRec.Check_In_Time__c.format('MM/dd/yyyy hh:mm a');
                System.debug('dateTimeStr-> ' + dateTimeStr);
                //Setting Wrapper Values.
                dtSave.CheckIndateStr = dateTimeStr;
                dtSave.CheckInDateTimeValue = woRec.Check_In_Time__c;
            }
            //Check Out.
            if(woRec.Check_Out_Time__c != null){
                integer storeTimehours = Integer.valueOf(woRec.Check_Out_Time__c.format('HH', stroetimezone));
                integer userTimehours = Integer.valueOf(woRec.Check_Out_Time__c.format('HH', currUser.TimeZoneSidKey));
                if(userTimehours == 0){
                    userTimehours = 24;
                }
                integer result;
                System.debug('woRec.Check_Out_Time__c before-> ' + woRec.Check_Out_Time__c);
                if(userTimehours > storeTimehours){
                    result = storeTimehours - userTimehours;
                    //subtracting hours
                    woRec.Check_Out_Time__c = woRec.Check_Out_Time__c.addHours(result);
                }
                if(userTimehours < storeTimehours){
                    result = storeTimehours - userTimehours;
                    //adding hours
                    woRec.Check_Out_Time__c = woRec.Check_Out_Time__c.addHours(result);
                }
                System.debug('woRec.Check_Out_Time__c after-> ' + woRec.Check_Out_Time__c);
                dateTimeStr = woRec.Check_Out_Time__c.format('MM/dd/yyyy hh:mm a');
                System.debug('dateTimeStr-> ' + dateTimeStr);
                //Setting Wrapper Values.
                dtSave.CheckOutdateStr = dateTimeStr;
                dtSave.CheckOutDateTimeValue = woRec.Check_Out_Time__c;
            }
            //Tech ETA.
            if(woRec.Technician_OnSite_ETA__c != null){
                integer storeTimehours = Integer.valueOf(woRec.Technician_OnSite_ETA__c.format('HH', stroetimezone));
                integer userTimehours = Integer.valueOf(woRec.Technician_OnSite_ETA__c.format('HH', currUser.TimeZoneSidKey));
                if(userTimehours == 0){
                    userTimehours = 24;
                }
                integer result;
                System.debug('woRec.Technician_OnSite_ETA__c before-> ' + woRec.Technician_OnSite_ETA__c);
                if(userTimehours > storeTimehours){
                    result = storeTimehours - userTimehours;
                    //subtracting hours
                    woRec.Technician_OnSite_ETA__c = woRec.Technician_OnSite_ETA__c.addHours(result);
                }
                if(userTimehours < storeTimehours){
                    result = storeTimehours - userTimehours;
                    //adding hours
                    woRec.Technician_OnSite_ETA__c = woRec.Technician_OnSite_ETA__c.addHours(result);
                }
                System.debug('woRec.Technician_OnSite_ETA__c after-> ' + woRec.Technician_OnSite_ETA__c);
                dateTimeStr = woRec.Technician_OnSite_ETA__c.format('MM/dd/yyyy hh:mm a');
                System.debug('dateTimeStr-> ' + dateTimeStr);
                //Setting Wrapper Values.
                dtSave.TechdateStr = dateTimeStr;
                dtSave.TechDateTimeValue = woRec.Technician_OnSite_ETA__c;
            }
        }
        return dtSave;
    }
    
    @auraEnabled
    public static List<String> getTimeEntries(WorkOrder woRec){
        List<String> teList = new List<String>();
        if(woRec.Time_Entries__c != null){
            teList = woRec.Time_Entries__c.Split('\\)');
            System.debug('teList before-> ' + teList);
            for(Integer i=0 ; i<teList.Size(); i++){
                if(teList[i].contains(')')){
                    teList[i] += ' (' + woRec.Account.Timezone__c + ')';
                } else {
                    teList[i] += ') (' + woRec.Account.Timezone__c + ')';
                }
            }
            System.debug('teList after-> ' + teList);
        }
        return teList;
    }
}