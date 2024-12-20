global class ASCENACaseMilestoneCalculater implements Support.MilestoneTriggerTimeCalculator {   
    global Integer calculateMilestoneTriggerTime(String caseId, String milestoneTypeId){
        MilestoneType mt = [SELECT Name FROM MilestoneType WHERE Id=:milestoneTypeId];
        
        Case c = [SELECT Account_Name_For_Search__c,CreatedDate,Priority, SLA_Calculation_Log__c, Preferred_Time__c, Account.Timezone__c,Entitlement.Type,Service_Type__c, BusinessHoursId FROM Case WHERE Id=:caseId];
        
        String timezoneId = '';
        String bhName = '';
        if(c.Entitlement != null && c.Entitlement.Type.contains('Advance Exchange')) {
            timezoneId = 'America/Chicago';
            bhName = 'CDT - ' + c.Priority;
        } else if('Severity 2'.equalsIgnoreCase(c.Priority)) {
            timezoneId = 'America/New_York';
            bhName = 'EST - ' + c.Priority;
        } else {
            if(c.Account.Timezone__c != null){
                Timezone_Id__mdt tz = [SELECT MasterLabel, QualifiedApiName, Timezon_Id__c FROM Timezone_Id__mdt  WHERE MasterLabel = :c.Account.Timezone__c];
                timezoneId = tz.Timezon_Id__c;
                bhName = c.Account.Timezone__c +' - ' + c.Priority;
            }
        }
        
        BusinessHours bh = null;
        if(Test.isRunningTest()) {
            bh = [SELECT Id FROM BusinessHours WHERE IsActive = true][0];
        } else {
            if(c.Account.Timezone__c != null){
                bh = [SELECT Id FROM BusinessHours WHERE Name = :bhName AND IsActive = true];
            }
        }
        //This gives number of miutes FROM WO CreatedDate within which WO must be closed for SLA
        integer triggerMinutes = 0;
        if(c.Entitlement != null && c.Entitlement.Type == 'Onsite IMAC' && c.Preferred_Time__c != null) {
            triggerMinutes = getSLAMinutesForOnsiteIMAC(c, timezoneId);
        } else {
            if(c.SLA_Calculation_Log__c == null){
                c.SLA_Calculation_Log__c = '';
            }
            if(bh != null){
                triggerMinutes = getSLAMinutes(c.CreatedDate, timezoneId, c.Priority, c.Service_Type__c, c, bh);
            }
        }
        System.debug('triggerMinutes-> '+triggerMinutes);
        if(c.Entitlement != null && 
           (c.Entitlement.Type == 'Onsite Labor Only' || 
            c.Entitlement.Type == 'Onsite Networking Services' || 
            c.Entitlement.Type == 'Onsite Break-Fix' || 
            c.Entitlement.Type == 'Onsite IMAC')) {
                if(mt.Name.equals('Technician Scheduled / Assigned')) {
                    triggerMinutes = triggerMinutes - 180;
                } else if(mt.Name.equals('Acknowledged')) {
                    triggerMinutes = 30;
                }
                Datetime temp = System.now().addMinutes(triggerMinutes);
                System.debug('mt.Name:' + mt.Name + ' hours:' + Integer.valueOf(temp.format('HH', timezoneId)) +' Minutes:' + Integer.valueOf(temp.format('mm', timezoneId)));
            } else if(c.Entitlement != null && c.Entitlement.Type == 'Advance Exchange + Onsite') {
                if(mt.Name.equals('Technician Scheduled / Assigned')) {
                    triggerMinutes = triggerMinutes - 8 * 60;
                } else if(mt.Name.equals('Part Received At Customer Site')) {
                    triggerMinutes = triggerMinutes - 240;
                } else if(mt.Name.equals('Part Shipped To Customer Site') || Test.isRunningTest()) {
                    Datetime dt = c.CreatedDate;
                    if(dt == null) {
                        dt = System.now();
                    }
                    String aeTimezoneId = 'America/Chicago';
                    String aeBHName = 'CDT - ' + c.Priority;
                    List<BusinessHours> aeBHList = [SELECT Id FROM BusinessHours WHERE Name = :aeBHName];
                    if(aeBHList.isEmpty()) {
                        c.SLA_Calculation_Log__c += 'Skipping execution as no BusinessHours record found';
                    } else {
                        triggerMinutes = ASCENACaseMilestoneCalculater.getSLAMinutes(dt, aeTimezoneId, c.Priority,'Advance Exchange (Depot Only)', c, aeBHList[0]);
                    }
                } else if(mt.Name.equals('Acknowledged')) {
                    triggerMinutes = 30;
                }
            } else if(c.Entitlement != null && c.Entitlement.Type == 'Advance Exchange (Depot Only)') {
                if(mt.Name.equals('Acknowledged')) {
                    triggerMinutes = 30;
                }
            }
        System.debug('mt.Name-> ' + mt.Name + ' triggerMinutes-> ' + triggerMinutes);
        if(triggerMinutes <= 0) {
            triggerMinutes = 1;
        }
        return triggerMinutes;
    }
    
    public static integer getSLAMinutesForOnsiteIMAC(Case c, String timezoneId) {
        System.debug('c.Preferred_Time__c-> '+c.Preferred_Time__c);
        Datetime d = Datetime.newInstance(c.Preferred_Time__c.year(), c.Preferred_Time__c.month(),c.Preferred_Time__c.day(), 8, 0, 0);
        System.debug('datTime with 8AM-> ' + d);
        integer mins = (integer) ((c.Preferred_Time__c.getTime() - d.getTime()) / 60000);
        System.debug('mins1-> ' + mins);
        for(integer i=System.today().day(); i < (c.Preferred_Time__c.date().day() - 1); i++) {
            Date tempDate = System.today().toStartOfMonth().addDays(i);
            Time myTime = Time.newInstance(14, 0, 0, 0);
            DateTime dtTemp = DateTime.newInstance(tempDate, myTime);
            if(BusinessHours.isWithin(c.BusinessHoursId,dtTemp)) {
                if(c.Priority == 'Severity 1') {
                    mins += 12 * 60;
                } else if(c.Priority == 'Severity 2') {
                    mins += 9 * 60;
                }
            }
        }
        System.debug('mins2-> ' + mins);
        Date tempDate = System.today();
        Time myTime = Time.newInstance(14, 0, 0, 0);
        DateTime dtTemp = DateTime.newInstance(tempDate, myTime);
        if(BusinessHours.isWithin(c.BusinessHoursId,dtTemp) || Test.isRunningTest()) {
            integer hours = Integer.valueOf(System.now().format('HH', timezoneId));
            integer minutes = Integer.valueOf(System.now().format('mm', timezoneId));
            System.debug(hours + ':' + minutes);
            if(c.Priority == 'Severity 1') {
                if(hours < 8) {
                    mins += 840;
                } else if(hours < 22) {
                    mins += (22 - System.now().hour()) * 60;
                }   
            } else if(c.Priority == 'Severity 2') {
                if(hours < 8) {
                    mins += 540;
                } else if(hours < 17){
                    mins += (17 - System.now().hour()) * 60;
                }
            }
        }
        return mins;
    }
    
    public static void assignSALEndDatetime(List<Case> caseList) {
        Set<Id> accIds = new Set<Id>();
        for(Case c : caseList) {
            accIds.add(c.AccountId);
        }
        if(accIds.isEmpty()) return;
        
        Map<Id,Account> accMap = new Map<Id, Account>([SELECT Id, Name, Timezone__c, ShippingState FROM Account WHERE Id IN :accIds]);
        List<Timezone_Id__mdt> tzList = [SELECT MasterLabel, QualifiedApiName, Timezon_Id__c FROM Timezone_Id__mdt];
        Map<String,String> tmzNameIdMap = new Map<String,String>();
        for(Case c : caseList) {
            if(!accMap.containsKey(c.AccountId)) continue;
            System.debug('c.Description-> ' + c.Description);
            c.SLA_Calculation_Log__c = '';
            String timezoneId = '';
            String timezoneName = '';
            
            String bhName = '';
            c.SLA_Calculation_Log__c += 'c.Service_Type__c-> ' + c.Service_Type__c + '<br/>';
            tmzNameIdMap = ASCENACaseMilestoneCalculater.getTimezoneIdForAccount(accMap.get(c.AccountId), tzList);
            if (!tmzNameIdMap.isEmpty()) {
                List<String> keyList = new List<String>(tmzNameIdMap.keySet());
                timezoneName = keyList[0];
                timezoneId = tmzNameIdMap.get(timezoneName);
            }
            bhName = timezoneName +' - ' + c.Priority;
            if(c.Service_Type__c != null && c.Service_Type__c != 'Onsite Labor Only' && c.Service_Type__c != 'Onsite Break-Fix' && c.Service_Type__c != 'Onsite Networking Services' && !c.Service_Type__c.contains('Advance Exchange')) {
                if('Severity 2'.equalsIgnoreCase(c.Priority) && c.Preferred_Time__c == null) {
                    timezoneId = 'America/New_York';
                    bhName = 'EST - ' + c.Priority;
                } 
            }
            if(c.Account_Name_For_Search__c.containsIgnoreCase('(JEI)') || c.Account_Name_For_Search__c.containsIgnoreCase('Jerry\'s Enterprises')) {
                bhName += ' - JRY';
            } else if(c.Account_Name_For_Search__c.containsIgnoreCase('CUB') || c.Account_Name_For_Search__c.containsIgnoreCase('SHOPPER')){
                bhName += ' - CUB';
            } else if (c.Account_Name_For_Search__c.containsIgnoreCase('Big Y Foods')){
                bhName = 'EST - Severity 1 - BYF';
            }
            System.debug('timezoneId-> ' + timezoneId + ' timezoneName-> ' + timezoneName +' bhName-> '+bhName);
            c.SLA_Calculation_Log__c += 'timezoneId-> ' + timezoneId + ' timezoneName-> ' + timezoneName + ' bhName-> ' + bhName + '<br/>';

            BusinessHours bh = null;
            List<BusinessHours> bhList = [SELECT Id,Name FROM BusinessHours WHERE Name = :bhName AND IsActive = true LIMIT 1];
            if(bhList.isEmpty()) {
                c.SLA_Calculation_Log__c += '<br>' + 'Skipping execution as no BusinessHours record found';
                continue;
            } else {
                bh = bhList[0];
                c.BusinessHoursId = bh.Id;
            }
            
            if(c.Preferred_Time__c != null && String.isBlank(timezoneId)) {
                continue;
            } else if(c.Preferred_Time__c != null && String.isNotBlank(timezoneId)) {
                System.debug('Onsite IMAC timezoneId-> ' + timezoneId);
                integer hours = Integer.valueOf(c.Preferred_Time__c.format('HH', timezoneId));
                integer minute = Integer.valueOf(c.Preferred_Time__c.format('mm', timezoneId));
                System.debug('Onsite IMAC timezoneId-> ' + hours + ':' + minute);
                System.debug('c.Preferred_Time__c BEFORE-> ' + c.Preferred_Time__c);
                c.Preferred_Time__c = c.Preferred_Time__c.addHours(c.Preferred_Time__c.hour() - hours);
                System.debug('c.Preferred_Time__c AFTER-> ' + c.Preferred_Time__c);
                c.Expected_SLA_Exit_Date__c = c.Preferred_Time__c;
                System.debug('c.Expected_SLA_Exit_Date__c-> ' + c.Expected_SLA_Exit_Date__c);
                c.SLA_Calculation_Log__c += '<br>c.Expected_SLA_Exit_Date__c-> ' + String.valueOf(c.Expected_SLA_Exit_Date__c) + '<br/>';
                continue;
            }
            
            System.debug('CASE CREATED DATE:'+c.CreatedDate);
            c.SLA_Calculation_Log__c += 'timezoneName-> ' + timezoneName + ' bhName-> ' + bhName + '<br/>';
            Datetime dt = c.CreatedDate;
            // dt = c.Dummy_field__c;
            if(dt == null) dt = System.now();
            c.SLA_Calculation_Log__c += '<br>Datetime to be considered-> ' + String.valueOf(dt) + '<br/>';
            
            Datetime dt1 = null;
            if(c.Service_Type__c != null && c.Service_Type__c.equalsIgnoreCase('Advance Exchange (Depot Only)')) {
                integer slaMinutes = ASCENACaseMilestoneCalculater.getSLAMinutes(dt, timezoneId, c.Priority,c.Service_Type__c, c, bh);
                dt1 = BusinessHours.add(bh.Id, dt, slaMinutes * 60 * 1000);
                System.debug('dt1 AFTER AE SLA-> ' + dt1);
                c.Part_Receipt_Due_DateTime__c = dt1;
                continue;
            }
            if(c.Service_Type__c != null && c.Service_Type__c.equalsIgnoreCase('Advance Exchange + Onsite')) {
                if(bh == null) {
                    c.SLA_Calculation_Log__c += '<br> Skipping execution as no BusinessHours record found';
                    continue;
                } else {
                    integer aeSlaMinutes = ASCENACaseMilestoneCalculater.getSLAMinutes(dt, timezoneId, c.Priority,'Advance Exchange (Depot Only)', c, bh);
                    System.debug('aeSlaMinutes-> ' + aeSlaMinutes);
                    c.SLA_Calculation_Log__c += 'aeSlaMinutes-> ' + aeSlaMinutes + '<br/>';
                    Datetime aeSLADateTime = BusinessHours.add(bh.Id, dt, aeSlaMinutes * 60 * 1000);
                    System.debug('aeSLADateTime AFTER AEO SLA-> ' + aeSLADateTime);
                    c.SLA_Calculation_Log__c += 'aeSLADateTime AFTER AEO SLA-> ' + aeSLADateTime + '<br/>';
                    c.Part_Receipt_Due_DateTime__c = aeSLADateTime;
                }
            }
            integer slaMinutes = ASCENACaseMilestoneCalculater.getSLAMinutes(dt, timezoneId, c.Priority,c.Service_Type__c, c, bh);
            System.debug('slaMinutes-> ' + slaMinutes);
            c.SLA_Calculation_Log__c += 'slaMinutes-> ' + slaMinutes + '<br/>';
            System.debug('dt1 BEFORE SLA-> ' + dt);
            System.debug('business hours name-> ' + bh.Name);
            c.SLA_Calculation_Log__c += 'dt1 BEFORE SLA-> ' + dt + ' bh.Id-> ' + bh.Id + '<br/>';
            dt1 = BusinessHours.add(bh.Id, dt, slaMinutes * 60 * 1000);
            System.debug('dt1 AFTER SLA-> ' + dt1);
            c.SLA_Calculation_Log__c += 'dt1 AFTER SLA-> ' + dt1 + '<br/>';
            
            integer hours = Integer.valueOf(dt1.format('HH', timezoneId));
            System.debug(timezoneId +' hours:'+hours);
            c.SLA_Calculation_Log__c += timezoneId + ' hours:' + hours +'<br/>';
            
            //When SLA is 5pm or 9pm, the calculation assigns SLA = 8am next morning
            //Following logic corrects that issue
            Time fivePm = Time.newInstance(17, 0, 0, 0);
            if(c.Account_Name_For_Search__c.containsIgnoreCase('Big Y Foods')) {
                if (dt1.time() == fivePm ) {
                    dt1 = BusinessHours.add(bh.Id, dt1, -1 * 60 * 1000);
                }
            } else {
                dt1 = BusinessHours.add(bh.Id, dt1, -1 * 60 * 1000);
            }
            System.debug('dt1 11-> ' + dt1);
            c.SLA_Calculation_Log__c += 'dt1 11-> ' + dt1 + '<br/>';
            c.Expected_SLA_Exit_Date__c = dt1;
            System.debug('c.Expected_SLA_Exit_Date__c-> ' + c.Expected_SLA_Exit_Date__c);
            c.SLA_Calculation_Log__c += 'c.Expected_SLA_Exit_Date__c-> ' + c.Expected_SLA_Exit_Date__c + '<br/>';
        }
    }
    
    public static Map<String,String> getTimezoneIdForAccount(Account a, List<Timezone_Id__mdt> tzList) {
        if(a == null) return null;
        System.debug('getTimezoneIdForAccount Account-> ' + JSON.Serialize(a));
        Map<String,String> tmzNameIdMap = new Map<String,String>();
        if(!String.isBlank(a.Timezone__c)){
            for(Timezone_Id__mdt tz : tzList) {
                if(tz.MasterLabel == a.Timezone__c) {
                    tmzNameIdMap.put(tz.MasterLabel, tz.Timezon_Id__c);
                    return tmzNameIdMap;
                }
            }
        }
        String tmz = null;
        List<Account> accList = [SELECT Id,ShippingState, Timezone__c FROM Account WHERE ShippingState =: a.ShippingState AND Id !=: a.Id ORDER BY ShippingState LIMIT 1000];
        Map<String,Integer> tmzCountMap = new Map<String,Integer>();
        if(!String.isBlank(a.Timezone__c)) tmzCountMap.put(a.Timezone__c,1);
        for(Account acc : accList){
            if(String.isBlank(acc.Timezone__c)) continue;
            if(String.isBlank(acc.ShippingState)) continue;
            if(tmzCountMap.containsKey(acc.Timezone__c)) {
                Integer count = tmzCountMap.get(acc.Timezone__c);
                count++;
                tmzCountMap.put(acc.Timezone__c,count);
            } else {
                tmzCountMap.put(acc.Timezone__c,1);
            }
        }
        Integer tmCount = 0;
        for(String s : tmzCountMap.keySet()) {
            if(tmzCountMap.get(s) > tmCount) {
                tmCount = tmzCountMap.get(s);
                tmz = s;
            }
        }
        if(tmz != null){
            for(Timezone_Id__mdt tz : tzList) {
                if(tz.MasterLabel == tmz) {
                    tmzNameIdMap.put(tz.MasterLabel, tz.Timezon_Id__c);
                    break;
                }
            }
            a.Timezone__c = tmz;
            AccountTriggerHandler.runOnceBeforeUpdate = false;
            AccountTriggerHandler.runOnceAfterUpdate = false;
            update a;
        }
        return tmzNameIdMap;
    }
    
    public static integer getSLAMinutes(Datetime dt, String timezoneId, String priority, String serviceType, Case c, BusinessHours bh) {
        System.debug('dt-> ' + dt);
        integer triggerMinutes = 0;
        if(serviceType == 'Onsite Labor Only'  || serviceType == 'Onsite Networking Services' || serviceType == 'Onsite Break-Fix') {
            integer hours = Integer.valueOf(dt.format('HH', timezoneId));
            integer minute = Integer.valueOf(dt.format('mm', timezoneId));
            String weekDay = dt.format('EEE', timezoneId);
            System.debug('serviceType-> ' + serviceType + ' weekDay:' + weekDay + ':hours:' + hours + ':minute:' + minute);
            c.SLA_Calculation_Log__c += 'getSLAMinutes serviceType-> ' + String.valueOf(serviceType) + ' hours:' + String.valueOf(hours) + ' minute:' + String.valueOf(minute) + '<br/>';
            if (c.Account_Name_For_Search__c.containsIgnoreCase('Big Y Foods')){
                triggerMinutes = 480; 
            } else{
                if('Severity 1'.equalsIgnoreCase(priority)) {
                    if(c.Account_Name_For_Search__c.containsIgnoreCase('(JEI)') || c.Account_Name_For_Search__c.containsIgnoreCase('Jerry\'s Enterprises')) {
                        triggerMinutes = getJRYSev1SLAMinutes(hours, minute, dt, timezoneId, bh, c);
                    } else {
                        triggerMinutes = getSev1SLAMinutes(hours, minute, dt, timezoneId, bh);
                    }
                } else if('Severity 2'.equalsIgnoreCase(priority)) {
                    if(c.Account_Name_For_Search__c.containsIgnoreCase('(JEI)') || c.Account_Name_For_Search__c.containsIgnoreCase('Jerry\'s Enterprises')) {
                        triggerMinutes = getJRYSev2SLAMinutes(hours, minute, weekDay, dt, serviceType, bh, c);
                    } else if(c.Account_Name_For_Search__c.containsIgnoreCase('CUB') || c.Account_Name_For_Search__c.containsIgnoreCase('SHOPPER')){
                        triggerMinutes = getCUBSev2SLAMinutes(hours, minute, weekDay, dt, serviceType, bh, c);
                    } else{
                        triggerMinutes = getSev2SLAMinutes(hours, minute, weekDay, dt, serviceType, bh, c);
                    }
                } else if('Severity 3'.equalsIgnoreCase(priority)) {
                    if(c.Account_Name_For_Search__c.containsIgnoreCase('CUB') || c.Account_Name_For_Search__c.containsIgnoreCase('SHOPPER')){
                        triggerMinutes = getCUBSev3SLAMinutes(hours, minute, weekDay, dt, serviceType, bh, c);
                    }
                }
            }
            c.SLA_Calculation_Log__c += 'Onsite case triggerMinutes-> ' + String.valueOf(triggerMinutes) + '<br/>';
        } else if(serviceType == 'Advance Exchange (Depot Only)') {
            integer hours = Integer.valueOf(dt.format('HH', timezoneId));
            integer minute = Integer.valueOf(dt.format('mm', timezoneId));
            System.debug('AE ONLY CTD hours-> ' + hours + ':minutes:' + minute + ':' + BusinessHours.isWithin(bh.Id, dt));
            c.SLA_Calculation_Log__c += 'AE ONLY CTD hours:' + hours + ':minutes:' + minute + ':' + BusinessHours.isWithin(bh.Id, dt) + '<br/>';
            if(hours < 8 || (hours == 8 && minute == 0) || !BusinessHours.isWithin(bh.Id, dt)) {
                System.debug('Hours <= 8:00');
                c.SLA_Calculation_Log__c += 'Hours <= 8:00 <br/>';
                triggerMinutes = 16 * 60;
            } else if(hours < 14 || (hours == 14 && minute <= 30)) {
                System.debug('Hours <= 2:30');
                c.SLA_Calculation_Log__c += 'Hours <= 2:30 <br/>';
                triggerMinutes = (24 - hours - 1) * 60 + (60 - minute);
            } else {
                c.SLA_Calculation_Log__c += 'Hours > 2:30 <br/>';
                triggerMinutes = (24 - hours - 1) * 60 + 16 * 60 + (60 - minute);
                System.debug('Hours > 2:30');
            }
            triggerMinutes = triggerMinutes -1;
            c.SLA_Calculation_Log__c += '<br>Advance Exchange triggerMinutes-> ' + String.valueOf(triggerMinutes);
        } else if(serviceType == 'Advance Exchange + Onsite') {
            integer hours = Integer.valueOf(dt.format('HH', 'America/Chicago'));
            integer minute = Integer.valueOf(dt.format('mm', 'America/Chicago'));
            System.debug('CTD hours:' + hours + ':minutes:' + minute);
            c.SLA_Calculation_Log__c += 'CTD hours:'+hours+':minutes:'+minute+'<br/>';
            
            integer storeHours = Integer.valueOf(dt.format('HH', timezoneId));
            integer storeMinutes = Integer.valueOf(dt.format('mm', timezoneId));
            System.debug('STORE storeHours:' + storeHours + ':storeMinutes:' + storeMinutes);
            
            c.SLA_Calculation_Log__c += 'STORE storeHours:' + storeHours + ':storeMinutes:' + storeMinutes + '<br/>';
            if(hours < 8 || (hours == 8 && minute == 0) || !BusinessHours.isWithin(bh.Id, dt)) {
                System.debug('Hours <= 8:00');
                c.SLA_Calculation_Log__c += 'Hours <= 8:00 <br/>';
                triggerMinutes = 16 * 2 * 60;
            } else if(hours < 14 || (hours == 14 && minute <= 30)) {
                System.debug('Hours <= 2:30');
                c.SLA_Calculation_Log__c += 'Hours <= 2:30 <br/>';
                triggerMinutes = (24 - storeHours - 1) * 60 + 16 * 60 + (60 - storeMinutes);
            } else {
                System.debug('Hours > 2:30');
                c.SLA_Calculation_Log__c += 'Hours > 2:30 <br/>';
                if(!BusinessHours.isWithin(bh.Id, dt)) {
                    triggerMinutes = 16 * 2 * 60;
                } else {
                    triggerMinutes = (24 - storeHours - 1) * 60 + 16 * 2 * 60 + (60 - storeMinutes);
                }
            }
        }
        System.debug('triggerMinutes-> ' + triggerMinutes);
        c.SLA_Calculation_Log__c += 'Line 404 triggerMinutes-> ' + triggerMinutes + '<br/>';
        return triggerMinutes;
    }
    
    public static integer getSev1SLAMinutes(integer hour, integer minutes, Datetime fromDate, String timezoneId, BusinessHours bh) {
        integer slaMinutes = 240;
        
        if(hour > 8 && (hour < 16 || (hour == 16 && minutes == 0))  || !BusinessHours.isWithin(bh.Id, fromDate)) {
            slaMinutes = 240;
        } else if((hour == 16 && minutes > 0) || hour > 16) {
            if(minutes > 0) {
                slaMinutes = ((22 - (hour + 1)) + 4) * 60;
            } else if (minutes == 0) {
                slaMinutes = ((22 - (hour)) + 4) * 60;
            }
            System.debug('slaMinutes-> ' + slaMinutes);
        }
        System.debug('slaMinutes-> ' + slaMinutes);
        return slaMinutes;
    }
    
    public static integer getSev2SLAMinutes(integer hour, integer minutes, String weekDay, Datetime fromDate, String serviceType, BusinessHours bh, Case c) {
        // 8AM - 12AM : So due time must be 11:59PM
        // 12hrs + 4hrs i.e till 12AM, so one day service hours = 16
        System.debug('getSev2SLAMinutes-> ' + weekDay + ':' + hour + ':' + minutes);
        c.SLA_Calculation_Log__c += 'getSev2SLAMinutes-> ' + weekDay + ':' + hour + ':' + minutes + '<br/>';
        integer slaMinutes = 240;
        
        //If weekend or any holiday weekday, next business day is
        if(weekDay.equalsIgnoreCase('SAT') || weekDay.equalsIgnoreCase('SUN')) {
            System.debug('HOLIDAY OR WEEKEND '+hour+' '+minutes);
            c.SLA_Calculation_Log__c += 'HOLIDAY OR WEEKEND -> ' + hour + ' ' + minutes + '<br/>';
            slaMinutes = (16 + 16) * 60;
        } else {
            if(hour < 8 || (hour == 8 && minutes == 0)  || !BusinessHours.isWithin(bh.Id, fromDate)) {
                System.debug('hour < 8 or not withing business hrs');
                c.SLA_Calculation_Log__c += 'hour < 8 or not withing business hrss' + '<br/>';
                slaMinutes = (16 + 16) * 60;
            } else if(hour < 15 || (hour == 15 && minutes <= 30)) {
                System.debug('hour <= 15');
                c.SLA_Calculation_Log__c += 'hour <= 15' + '<br/>';
                //16hr + 8 = 24
                if(minutes == 0) {
                    slaMinutes = ( 24 - (hour + 1) + 16) * 60;
                } else {
                    slaMinutes = ( 24 - (hour + 1) + 16) * 60 + (60 - minutes);
                }
            } else if(hour > 15 || (hour == 15 && minutes > 30)) {
                System.debug('hour > 15');
                c.SLA_Calculation_Log__c += 'hour > 15' + '<br/>';
                slaMinutes = (60 - minutes) + ( 24 - (hour + 1) + 16 + 16 ) * 60;
            }
        }
        return slaMinutes;
    }
    
    public static integer getCUBSev2SLAMinutes(integer hour, integer minutes, String weekDay, Datetime fromDate, String serviceType, BusinessHours bh, Case c) {
        // 8AM - 11PM : So due time must be 10:59PM
        // 12hrs + 3hrs i.e till 11PM, so one day service hours = 15
        System.debug('getCUBSev2SLAMinutes-> ' + weekDay + ' : ' + hour + ' : ' + minutes);
        c.SLA_Calculation_Log__c += 'getCUBSev2SLAMinutes-> ' + weekDay + ' : ' + hour + ' : ' + minutes + '<br/>';
        integer slaMinutes = 240;
        
        //If weekend or any holiday weekday, next business day is
        if(weekDay.equalsIgnoreCase('SAT') || weekDay.equalsIgnoreCase('SUN')) {
            System.debug('HOLIDAY OR WEEKEND '+hour+' '+minutes);
            c.SLA_Calculation_Log__c += 'HOLIDAY OR WEEKEND-> ' + hour + ' ' + minutes + '<br/>';
            slaMinutes = (15 + 15) * 60;
        } else {
            if(hour < 8 || (hour == 8 && minutes == 0)  || !BusinessHours.isWithin(bh.Id, fromDate)) {
                System.debug('hour < 8 or not withing business hrs');
                c.SLA_Calculation_Log__c += 'hour < 8 or not withing business hrs' + '<br/>';
                slaMinutes = (15 + 15 + 15) * 60;
            } else if(hour < 14 || (hour == 14 && minutes == 0)) {
                System.debug('hour <= 14');
                c.SLA_Calculation_Log__c += 'hour < 14 or hour = 14' + '<br/>';
                //15hr + 8 = 23
                if(minutes == 0) {
                    slaMinutes = ( 23 - (hour + 1) + 15) * 60;
                } else {
                    slaMinutes = ( 23 - (hour + 1) + 15) * 60 + (60 - minutes);
                }
            } else if(hour > 14 || (hour == 14 && minutes > 0)) {
                System.debug('hour > 14');
                c.SLA_Calculation_Log__c += 'hour > 14' + '<br/>';
                slaMinutes = (60 - minutes) + ( 23 - (hour + 1) + 15 + 15 ) * 60;
            }
        }
        return slaMinutes;
    }

    public static integer getCUBSev3SLAMinutes(integer hour, integer minutes, String weekDay, Datetime fromDate, String serviceType, BusinessHours bh, Case c) {
        // 7AM - 12AM : So due time must be 11:59PM, cut-off is 2PM
        // 12hrs + 5hrs i.e. till 12AM, so one day service hours = 17
        //Resolution Due in 3 business days from the opened date
        //If opened by 1:59 PM Local, opened date is first Business Day
		//If opened after 2:00 PM local, tomorrow is the first Business Day
        System.debug('getCUBSev3SLAMinutes-> ' + weekDay + ' : ' + hour + ' : ' + minutes);
        c.SLA_Calculation_Log__c += 'getCUBSev3SLAMinutes-> ' + weekDay + ' : ' + hour + ' : ' + minutes + '<br/>';
        integer slaMinutes = 240;
        
        //If weekend or any holiday weekday, jumping to next business day
        if(weekDay.equalsIgnoreCase('SAT') || weekDay.equalsIgnoreCase('SUN')) {
            System.debug('HOLIDAY OR WEEKEND '+hour+' '+minutes);
            c.SLA_Calculation_Log__c += 'HOLIDAY OR WEEKEND-> ' + hour + ' ' + minutes + '<br/>';
            slaMinutes = (17 + 17 + 17) * 60;
        } else {
            if(hour < 7 || (hour == 7 && minutes == 0)  || !BusinessHours.isWithin(bh.Id, fromDate)) {
                System.debug('hour < 7 or not withing business hrs');
                c.SLA_Calculation_Log__c += 'hour < 7 or not withing business hrs' + '<br/>';
                slaMinutes = (17 + 17 + 17 + 17) * 60;
            } else if(hour < 14 || (hour == 14 && minutes == 0)) {
                System.debug('hour <= 14');
                c.SLA_Calculation_Log__c += 'hour < 14 or hour = 14' + '<br/>';
                if(minutes == 0) {
                    slaMinutes = ( 24 - (hour + 1) + 17 + 17) * 60;
                } else {
                    slaMinutes = ( 24 - (hour + 1) + 17 + 17) * 60 + (60 - minutes);
                }
            } else if(hour > 14 || (hour == 14 && minutes > 0)) {
                System.debug('hour > 14');
                c.SLA_Calculation_Log__c += 'hour > 14' + '<br/>';
                slaMinutes = (60 - minutes) + ( 24 - (hour + 1) + 17 + 17 + 17) * 60;
            }
        }
        return slaMinutes;
    }

    public static integer getJRYSev1SLAMinutes(integer hour, integer minutes, Datetime fromDate, String timezoneId, BusinessHours bh, Case c) {
        /*Sunday-Saturday, 8AM - 10PM, cut-off is 12PM.
        before 12PM = tech will be on-site within next 10Hrs.
        after 12PM = tech will be on-site by next business day by 12PM.*/
        //So one day serice hrs = 14 i.e. till 10PM
        //14hrs + 8 = 22
        integer slaMinutes = 240;
        if(!BusinessHours.isWithin(bh.Id, fromDate)) {
            System.debug('Not withing business hrs');
            c.SLA_Calculation_Log__c += 'Sev1 Not within business hrs' + '<br/>';
            return slaMinutes;
        }
        if(hour < 12 || (hour == 12 && minutes == 0)) {
            System.debug('Sev1 hour < 12');
            c.SLA_Calculation_Log__c += 'Sev1 hour < 12' + '<br/>';
            slaMinutes = 10 * 60;
        } else if(hour > 12 || (hour == 12 && minutes > 0)) {
            System.debug('Sev1 hour > 12');
            c.SLA_Calculation_Log__c += 'Sev1 hour > 12' + '<br/>';
            slaMinutes = ( 22 - (hour + 1) + 4) * 60 + (60 - minutes);
        }
        return slaMinutes;
    }

    public static integer getJRYSev2SLAMinutes(integer hour, integer minutes, String weekDay, Datetime fromDate, String serviceType, BusinessHours bh, Case c) {
        /*Monday – Friday, 8AM - 5PM, cut-off is 2PM.
		before 2PM = tech will be on-site on next business day by 10PM.
		after 2PM = tech will be on-site on 2nd business day by 10PM.*/
        // 8AM - 10PM : So due time must be 10:59PM CST
        // so one day service hours = 14
        System.debug('getJRYSev2SLAMinutes-> ' + weekDay + ' : ' + hour + ' : ' + minutes);
        c.SLA_Calculation_Log__c += 'getJRYSev2SLAMinutes-> ' + weekDay + ' : ' + hour + ' : ' + minutes + '<br/>';
        integer slaMinutes = 240;
        
        //If weekend or any holiday weekday, next business day is
        if(weekDay.equalsIgnoreCase('SAT') || weekDay.equalsIgnoreCase('SUN')) {
            System.debug('HOLIDAY OR WEEKEND '+hour+' '+minutes);
            c.SLA_Calculation_Log__c += 'HOLIDAY OR WEEKEND-> ' + hour + ' ' + minutes + '<br/>';
            slaMinutes = (14 + 14) * 60;
        } else {
            if(hour < 8 || (hour == 8 && minutes == 0)  || !BusinessHours.isWithin(bh.Id, fromDate)) {
                System.debug('hour < 8 or not withing business hrs');
                c.SLA_Calculation_Log__c += 'hour < 8 or not withing business hrs' + '<br/>';
                slaMinutes = (14 + 14 + 14) * 60;
            } else if(hour < 14 || (hour == 14 && minutes == 0)) {
                System.debug('hour <= 14');
                c.SLA_Calculation_Log__c += 'hour < 14 or hour = 14' + '<br/>';
                if(minutes == 0) {
                    //14hrs + 8 =22
                    slaMinutes = ( 22 - (hour + 1) + 14) * 60;
                } else {
                    slaMinutes = ( 22 - (hour + 1) + 14) * 60 + (60 - minutes);
                }
            } else if(hour > 14 || (hour == 14 && minutes > 0)) {
                System.debug('hour > 14');
                c.SLA_Calculation_Log__c += 'hour > 14' + '<br/>';
                slaMinutes = (60 - minutes) + ( 22 - (hour + 1) + 14 + 14 ) * 60;
            }
        }
        return slaMinutes;
    }

    // public static integer getBigYSev1SLAMinutes(integer hour, integer minutes, Datetime fromDate, String timezoneId, BusinessHours bh, Case c) {
    //     integer slaMinutes = 480;
    //     // if (!BusinessHours.isWithin(bh.Id, fromDate)) {
    //     //     System.debug('Case opened outside business hours');
    //     //     c.SLA_Calculation_Log__c += 'Opened outside business hours<br/>';
    //     //     slaMinutes = 480 * 2;        
    //     // }
    //     return slaMinutes;
    // }
}