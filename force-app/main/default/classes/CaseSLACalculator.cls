public without sharing class CaseSLACalculator {
    public static void assignSALEndDatetime(List<Case> caseList) {
        Set<Id> accIds = new Set<Id>();
        for(Case c : caseList) {
            if(c.Expected_SLA_Exit_Date__c != null) continue;
            accIds.add(c.AccountId);
        }
        if(accIds.isEmpty()) return;
        
        Map<Id,Account> accMap = new Map<Id, Account>([SELECT Id, Timezone__c, ShippingState FROM Account WHERE Id IN :accIds]);
        List<Timezone_Id__mdt> tzList = [SELECT MasterLabel, QualifiedApiName, Timezon_Id__c FROM Timezone_Id__mdt];
        Map<String,String> tmzNameIdMap = new Map<String,String>();
        for(Case c : caseList) {
            c.SLA_Calculation_Log__c = '';
            String timezoneId = '';
            String timezoneName = '';
            String bhName = '';
            c.SLA_Calculation_Log__c += 'c.Service_Type__c-> ' + c.Service_Type__c + '<br/>';
            if(accMap.containsKey(c.AccountId)) tmzNameIdMap = ASCENACaseMilestoneCalculater.getTimezoneIdForAccount(accMap.get(c.AccountId), tzList);
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
            if(c.Account_Name_For_Search__c.containsIgnoreCase('ALDI')){
                bhName += ' - ' + 'ALDI';
            }
            System.debug('timezoneId-> ' + timezoneId + ' timezoneName-> ' + timezoneName +' bhName-> '+bhName);
            c.SLA_Calculation_Log__c += 'timezoneId-> ' + timezoneId + ' timezoneName-> ' + timezoneName + ' bhName-> ' + bhName + '<br/>';
            
            BusinessHours bh = null;
            if(Test.isRunningTest()) {
                bh = [select Id from BusinessHours][0];
            } else {
                List<BusinessHours> bhList = [select Id from BusinessHours where Name = :bhName];
                if(bhList.isEmpty()) {
                    c.SLA_Calculation_Log__c += 'Skipping execution as no BusinessHours record found';
                    continue;
                } else {
                    bh = bhList[0];
                    c.BusinessHoursId = bh.Id;
                }
            }
            
            //ALDI SLA
            //Business Hrs - 7AM to 7PM.
            if(c.Account_Name_For_Search__c.containsIgnoreCase('ALDI') && String.isNotBlank(timezoneId)){
                DateTime prefDt = System.now();
                integer aldislaMinutes = 0;
                if(c.Preferred_Time__c != null){
                    prefDt = c.Preferred_Time__c;
                }
                Boolean beforeEight = false;
                integer hour = prefDt.hour();
                integer minutes = prefDt.minute();
                System.debug('Within Business Hours? -> ' + BusinessHours.isWithin(bh.Id, prefDt));
                if(hour < 7  || (hour == 7 && minutes == 0) || !BusinessHours.isWithin(bh.Id, prefDt)){
                    System.debug('hour < 7');
                    c.SLA_Calculation_Log__c += 'hour < 7' + '<br/>';
                    aldislaMinutes = (17 + 17) * 60;
                } else if(c.Priority == 'Severity 3'){
                    aldislaMinutes = (17 + 17 + 17) * 60;
                    c.SLA_Calculation_Log__c += 'Adding 4 Business days' + '<br/>';
                } else if(c.Priority == 'Severity 2'){
                    aldislaMinutes = (17 + 17) * 60;
                    c.SLA_Calculation_Log__c += 'Adding 2 Business days' + '<br/>';
                } else if(c.Priority == 'Severity 1'){
                    Time sev1DateTime = Time.newInstance(12,0,0,0);
                    System.debug('prefDt.time()-> ' + prefDt.time());
                    if(prefDt.time() < sev1DateTime){
                        aldislaMinutes = 240;
                        beforeEight = true;
                        c.SLA_Calculation_Log__c += 'Adding 4 Business hours' + '<br/>';
                    } else if(prefDt.time() > sev1DateTime){
                        aldislaMinutes = 17 * 60;
                        c.SLA_Calculation_Log__c += 'Adding 1 Business day' + '<br/>';
                    }
                }
                System.debug('After Adding Business Hours-> ' + BusinessHours.add(bh.Id, System.now(), aldislaMinutes * 60 * 1000));
                datetime slaDatime = BusinessHours.add(bh.Id, System.now(), aldislaMinutes * 60 * 1000);
                if(beforeEight){
                    c.Expected_SLA_Exit_Date__c = slaDatime;
                    
                } else {
                    c.Expected_SLA_Exit_Date__c = DateTime.newInstance(slaDatime.date(), Time.newInstance(23,59,0,0));
                }
                System.debug('ALDI c.Expected_SLA_Exit_Date__c-> ' + c.Expected_SLA_Exit_Date__c);
                c.SLA_Calculation_Log__c += '\\n line 95 c.Expected_SLA_Exit_Date__c-> ' + string.valueOf(c.Expected_SLA_Exit_Date__c) + '<br/>';
                continue;
            }
        }
    }
}