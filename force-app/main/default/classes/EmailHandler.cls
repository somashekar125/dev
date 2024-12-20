global class EmailHandler implements Messaging.InboundEmailHandler {
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        System.debug('Email -> ' + email);
        System.debug('Email Service Invoked-> ' + email.plainTextBody);
        System.debug('Email Service Invoked-> ' + email.htmlBody);
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        Set<String> keyList = new Set<String>();
        keyList.add('Company name');
        keyList.add('Opened by');
        keyList.add('Request #');
        keyList.add('Incident #');
        keyList.add('Opened date');
        keyList.add('GSD Phone');
        keyList.add('Aldi location');
        keyList.add('Address');
        keyList.add('Phone');
        keyList.add('Service');
        keyList.add('Quantity');
        keyList.add('Comments');
        keyList.add('Ref');
        keyList.add('Urgency');
        keyList.add('Service Date/Time');
        keyList.add('Store Format');
        keyList.add('Type of Service');
        List<String> emailBodyLines = null;
        if(String.isNotBlank(email.plainTextBody)) {
            emailBodyLines = email.plainTextBody.split('\\n');
            System.debug('emailBodyLines from plaintextbody' + emailBodyLines);
        } else if (String.isNotBlank(email.htmlBody)) {
            emailBodyLines = email.htmlBody.split('\\n');
            System.debug('emailBodyLines from htmlBody' + emailBodyLines);
        } else {
            System.debug('Neither HTML or PLAIN body specified');
            return result;
        }
        //To append lines of a sentence that are broken down to new lines by class.
        //Starting FROM 2nd line.
        emailBodyLines = EmailHandler.concatinatingValidLines(emailBodyLines,keyList);
        String plainTextBody = '';
        for(String s : emailBodyLines){
            if(String.isBlank(s) || s == null) continue;
            System.debug('lines 1-> ' + s);
            plainTextBody += s + '\n' + '\n';
        }
        System.debug('plainTextBody-> ' + plainTextBody);
        Case c = new Case();
        Account acc = new Account();
        Map<String,String> PriorityPairs = new Map<String,String>();
        Map<String,String> DefaultPairs = new Map<String,String>();
        List<Email_To_Case_Mapping__mdt> caseFields = Email_To_Case_Mapping__mdt.getAll().values();
        System.debug('caseFields-> ' + caseFields);
        for(Email_To_Case_Mapping__mdt mt : caseFields){
            if(String.isBlank(mt.Value__c)) continue;
            if(mt.Case_Field__c == 'Priority' && mt.Default__c == null){
                PriorityPairs.put(mt.MasterLabel,mt.Value__c);
            }
            if(mt.Default__c != null){
                DefaultPairs.put(mt.MasterLabel,mt.Value__c);
            }
        }
        System.debug('PriorityPairs-> ' + PriorityPairs);
        System.debug('DefaultPairs-> ' + DefaultPairs);
        try{
            String locNum;
            String stroetimezone;
            for(Email_To_Case_Mapping__mdt mt : caseFields){
                for(String l : emailBodyLines){
                    if(String.isBlank(l) || !l.startsWithIgnoreCase(mt.MasterLabel)) continue;
                    System.debug('lines 2-> ' + l);
                    if(l.startsWithIgnoreCase('Aldi location')){
                        //Account Name
                        String input = l.substringAfter(':');

                        //466-046 Bettendorf
                        String pattern1 = '(\\d+)-(\\d+)';
                        Pattern regex1 = Pattern.compile(pattern1);
                        Matcher matcher1 = regex1.matcher(input);
                        if (matcher1.find()) {
                            String beforeDash = matcher1.group(1);
                            String afterDash = matcher1.group(2);
                        
                            System.debug('Number before dash pattern1: ' + beforeDash); // Output: 466
                            System.debug('Number after dash pattern1: ' + afterDash); // Output: 046
                            String temp = beforeDash + '-' + afterDash;
                            locNum = '%' + temp + '%';
                        }

                        //466 - 046 Bettendorf
                        String pattern2 = '(\\d+)\\s*-\\s*(\\d+)';
                        Pattern regex2 = Pattern.compile(pattern2);
                        Matcher matcher2 = regex2.matcher(input);
                        if (matcher2.find()) {
                            String beforeDash = matcher2.group(1);
                            String afterDash = matcher2.group(2);
                        
                            System.debug('Number before dash pattern2: ' + beforeDash); // Output: 466
                            System.debug('Number after dash pattern2: ' + afterDash); // Output: 046
                            String temp = beforeDash + '-' + afterDash;
                            locNum = '%' + temp + '%';
                        }

                        //Bettendorf 466-046
                        String pattern3 = '.*?(\\d+)-(\\d+)';
                        Pattern regex3 = Pattern.compile(pattern3);
                        Matcher matcher3 = regex3.matcher(input);
                        if (matcher3.find()) {
                            String beforeDash = matcher3.group(1);
                            String afterDash = matcher3.group(2);
                        
                            System.debug('Number before dash pattern3: ' + beforeDash); // Output: 466
                            System.debug('Number after dash pattern3: ' + afterDash); // Output: 046
                            String temp = beforeDash + '-' + afterDash;
                            locNum = '%' + temp + '%';
                        }

                        //Bettendorf 466 - 046
                        String pattern4 = '.*?(\\d+)\\s*-\\s*(\\d+)';
                        Pattern regex4 = Pattern.compile(pattern4);
                        Matcher matcher4 = regex4.matcher(input);
                        if (matcher4.find()) {
                            String beforeDash = matcher4.group(1);
                            String afterDash = matcher4.group(2);
                        
                            System.debug('Number before dash pattern4: ' + beforeDash); // Output: 466
                            System.debug('Number after dash pattern4: ' + afterDash); // Output: 046
                            String temp = beforeDash + '-' + afterDash;
                            locNum = '%' + temp + '%';
                        }
                    }
                }
            }
            //Account & Root Account
            if(String.isNotBlank(locNum)){
                acc = [SELECT Id,Name,Root_Account__c,ShippingCountry,Type,Timezone__c FROM Account WHERE Name like :locNum AND Type = 'Store' limit 1];
                if(acc != null){
                    c.AccountId = acc.Id;
                    c.Root_Account__c  = acc.Root_Account__c;
                }
            }
            //Account Timezone
            if(String.isNotBlank(acc.Timezone__c)){
                List<Timezone_Id__mdt> tzList = [SELECT MasterLabel, QualifiedApiName, Timezon_Id__c FROM Timezone_Id__mdt];
                for(Timezone_Id__mdt tz : tzList) {
                    if(tz.MasterLabel == acc.Timezone__c){
                        stroetimezone = tz.Timezon_Id__c;
                    }
                }
            }
            //Description. Populated when updating as content is getting chopped off.
            String description = '';
            for(String ln : emailBodyLines){
                if(String.isBlank(ln)) continue;
                ln = ln.trim();
                System.debug('lines 3-> ' + ln);
                if(ln.startsWithIgnoreCase('Urgency') || ln.startsWithIgnoreCase('Service Date/Time') || 
                    ln.startsWithIgnoreCase('Store Format') || ln.startsWithIgnoreCase('Type of Service') || 
                    ln.startsWithIgnoreCase('Comments')){
                    description += ln + '\n';
                }
            }
            for(Email_To_Case_Mapping__mdt mt : caseFields){
                for(String ln : emailBodyLines){
                    if(String.isBlank(ln) || !ln.startsWithIgnoreCase(mt.MasterLabel) || ln.startsWithIgnoreCase('Aldi location')) continue;
                    ln = ln.trim();
                    System.debug('lines 4-> ' + ln);
                    //Priority
                    /*P1 - High - Critical - Severity 1
                    P2 - Medium - Expedited - Severity 2
                    P3 - Low - Standard - Severity 3*/
                    if(ln.startsWithIgnoreCase('Urgency')){
                        for(String s : PriorityPairs.keySet()){
                            if(!ln.containsIgnoreCase(s)) continue;
                            c.Priority = PriorityPairs.get(s);
                        }
                    } else if (ln.startsWithIgnoreCase('Comments') && c.Priority == null){
                        for(String s : PriorityPairs.keySet()){
                            if(!ln.containsIgnoreCase(s)) continue;
                            c.Priority = PriorityPairs.get(s);
                        }
                    } else if(ln.startsWithIgnoreCase('Service Date/Time')){
                        //Preffered Time -> ALDI = MM/DD/YYYY HH:MM
                        String val = ln.substringAfter(':').trim();
                        List<String> tempList = val.split(' ');
                        Date dt;
                        Time tm;
                        for(String s : tempList){
                            if((s == '-') || s.isNumeric() || s.isAlpha() || s.isAlphaSpace() || s.isAlphanumeric() || s.isAlphanumericSpace()) continue;
                            System.debug('characters in comments-> ' + s);
                            if(s.contains('/') && s.countMatches('/') == 2){
                                String[] strDateSplit = s.split('/');
                                Integer mn = Integer.valueOf(strDateSplit[0]);
                                Integer dy = Integer.valueOf(strDateSplit[1]);
                                Integer yr = Integer.valueOf(strDateSplit[2]);
                                dt = Date.newInstance(yr,mn,dy);
                                //dt = date.valueOf(s);
                                System.debug('date value-> ' + dt);
                            }
                            if(s.contains(':') && s.countMatches(':') == 2 || s.countMatches(':') == 1){
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
                        if(dt != null && tm == null){
                            tm = Time.newInstance(23,0,0,0);
                        }
                        if(dt != null && tm != null){
                            DateTime tempdt = DateTime.newInstance(dt,tm);
                            if(String.isNotBlank(stroetimezone)){
                                c.Preferred_Time__c = DateTime.parse(tempdt.format('MM/dd/yyyy, hh:mm a', stroetimezone));
                            } else {
                                c.Preferred_Time__c = DateTime.parse(tempdt.format('MM/dd/yyyy, hh:mm a'));
                            }
                            System.debug('c.Preferred_Time__c FROM emailhandler-> ' + c.Preferred_Time__c);
                        }
                    } else {
                        //All Remaining fields except Lookups and fields FROM comments.
                        String val = ln.substringAfter(':').trim();
                        System.debug('val-> ' + val);
                        c.put(mt.Case_Field__c, val);
                    }
                }
            }
            //Default Priority
            if(String.isBlank(c.Priority)){
                c.Priority = DefaultPairs.get('Default Priority');
            }
            //Service Type
            if(String.isNotBlank(c.Priority)){
                if(c.Priority == 'Severity 1'){
                    c.Service_Type__c = 'Onsite IMAC - Critical';
                } else if(c.Priority == 'Severity 2'){
                    c.Service_Type__c = 'Onsite IMAC - Expedited';
                } else if(c.Priority == 'Severity 3'){
                    c.Service_Type__c = 'Onsite IMAC';
                }
            }
            //Service Contract
            if(String.isNotBlank(c.Service_Type__c) && acc != null){
                List<ServiceContract> scList = [SELECT Id,Service_Type__c,Country__c,AccountId FROM ServiceContract 
                                                WHERE Service_Type__c =:c.Service_Type__c AND Status = 'Active' AND 
                                                Include_in_Service_Type_Picklist__c = true];
                for(ServiceContract sc : scList){
                    if(acc.Root_Account__c != sc.AccountId) continue;
                    if(sc.Service_Type__c == c.Service_Type__c && sc.Country__c == acc.ShippingCountry){
                        c.ServiceContractId = sc.Id;
                        break;
                    }
                }
            }
            //Business Hours
            if(c.Priority != null && acc != null && acc.Timezone__c != null){
                String bhName = acc.Timezone__c + ' - ' + c.Priority + ' - ALDI';
                List<BusinessHours> bhs = [SELECT Id, Name FROM BusinessHours WHERE Name =: bhName];
                if((bhs.size() != 0)){
                    c.BusinessHoursId = bhs[0].Id;
                }
            }
            //Support Team and Tech Notes.
            Support_Team__c sp = [SELECT Id,Name,Tech_Notes__c FROM Support_Team__c WHERE Name = 'ALDI GSD' limit 1];
            if(sp != null){
                c.Support_Team__c = sp.Id;
                if(!String.isBlank(sp.Tech_Notes__c)){
                    c.Tech_Notes__c = sp.Tech_Notes__c;
                }
            }
            //Storing Original Email Body
            c.Origin = 'Email';
            if(email.htmlBody != null){
                c.ALDI_Email_Body__c = email.htmlBody;
            } else if(email.plainTextBody != null){
                c.ALDI_Email_Body__c = plainTextBody;
            }
            System.debug('c.ALDI_Email_Body__c-> ' + c.ALDI_Email_Body__c);
            // creating case
            insert c;
            //To invoke flow for WO creation
            Case c2 = [SELECT Id,CaseNumber,Create_Work_Order__c,Incident__c,Account.Name,Priority FROM Case WHERE Id =: c.Id];
            c2.Create_Work_Order__c = true;
            String subject = 'NEW | CASE #' + c2.CaseNumber + ' | INC #' + c2.Incident__c + ' | '+ c2.Account.Name + ' | ' + c2.Priority;
            c2.ALDI_Email_Subject__c = subject;
            c2.Description = description;
            update c2;
            //Associating Original Email with Case.
            String toAdd = email.toAddresses[0];
            String fromAdd = email.fromAddress;
            Case cs = [SELECT Id,CaseNumber,Incident__c,Account.Name,Priority FROM Case WHERE Id =: c.Id];
            EmailMessage createWhatEmail = new EmailMessage();
            createWhatEmail.Subject                = subject;
            createWhatEmail.Status                 = '3';
            createWhatEmail.ToAddress              = toAdd;
            createWhatEmail.FromAddress            = fromAdd;
            createWhatEmail.FromName               = 'ALDI Inc';
            if(email.htmlBody != null){
                createWhatEmail.HtmlBody           = email.htmlBody;
            } else if(email.plainTextBody != null){
                createWhatEmail.HtmlBody      = plainTextBody;
            }
            System.debug('createWhatEmail.HtmlBody-> ' + createWhatEmail.HtmlBody);
            createWhatEmail.Incoming               = false;
            createWhatEmail.MessageDate            = DateTime.now();
            createWhatEmail.RelatedToId            = c.Id;
            
            insert createWhatEmail;
        }
        catch (Exception e) {
            System.debug('Exception : ' + e);
            plainTextBody += '\n' + '\n' + 'Error : ' + e;
            String toAdd = email.toAddresses[0];
            String fromAdd = email.fromAddress;
            String inc;
            String prty;
            for(String ln : emailBodyLines){
                if(ln.containsIgnoreCase('Request')){
                    inc = ln.substringAfter(':');
                }
                if(ln.startsWithIgnoreCase('Urgency')){
                    for(String s : PriorityPairs.keySet()){
                        if(!ln.containsIgnoreCase(s)) continue;
                        prty = PriorityPairs.get(s);
                    }
                } else if (ln.startsWithIgnoreCase('Comments') && prty == null){
                    for(String s : PriorityPairs.keySet()){
                        if(!ln.containsIgnoreCase(s)) continue;
                        prty = PriorityPairs.get(s);
                    }
                }
            }
            //Default Priority
            if(String.isBlank(prty)){
                prty = DefaultPairs.get('Default Priority');
            }
            String subject = 'NEW | CASE | INC #' + inc + '| '+ acc.Name + '| ' + prty;
            EmailMessage createWhatEmail = new EmailMessage();
            createWhatEmail.Subject                = subject;
            createWhatEmail.Status                 = '3';
            createWhatEmail.ToAddress              = toAdd;
            createWhatEmail.FromAddress            = fromAdd;
            createWhatEmail.FromName               = 'ALDI Inc';
            if(email.htmlBody != null){
                createWhatEmail.HtmlBody           = email.htmlBody + '\n' + '\n' + 'Error : ' + e;
            } else if(email.plainTextBody != null){
                createWhatEmail.HtmlBody      = plainTextBody;
            }
            System.debug('createWhatEmail.HtmlBody-> ' + createWhatEmail.HtmlBody);
            createWhatEmail.Incoming               = false;
            createWhatEmail.MessageDate            = DateTime.now();
            createWhatEmail.RelatedToId            = acc.Root_Account__c;
            
            insert createWhatEmail;
            if(acc.Root_Account__c != null){
                Account rAcc = new Account(Id = acc.Root_Account__c);
                if(email.htmlBody != null){
                    rAcc.ALDI_Email_Body_Failed__c  = email.htmlBody + '\n' + '\n' + 'Error : ' + e;
                } else if(email.plainTextBody != null){
                    rAcc.ALDI_Email_Body_Failed__c  = plainTextBody;
                }
                update rAcc;
            } else if (acc != null){
                Account childAcc = new Account(Id = acc.Id);
                if(email.htmlBody != null){
                    childAcc.ALDI_Email_Body_Failed__c  = email.htmlBody + '\n' + '\n' + 'Error : ' + e;
                } else if(email.plainTextBody != null){
                    childAcc.ALDI_Email_Body_Failed__c  = plainTextBody;
                }
                update childAcc;
            }
        }
        return result;
    }

    public static List<String> concatinatingValidLines(List<String> emailBodyLines, Set<String> keyList){
        for(Integer l=1; l<emailBodyLines.size(); l++){
            if(String.isBlank(emailBodyLines[l])) continue;
            System.debug('emailBodyLines[l]-> ' + emailBodyLines[l]);
            Boolean valid = true;
            if(emailBodyLines[l].contains(':')){
                String temp = emailBodyLines[l].substringBefore(':').trim();
                if(keyList.contains(temp)){
                    valid = false;
                }
            }
            System.debug('concatinating lines which are-> ' + valid);
            if(!valid) continue;
            String temp  = emailBodyLines[l-1] + ' ' + emailBodyLines[l];
            if(emailBodyLines[l-1] == temp) continue;
            emailBodyLines[l-1] += ' ' + emailBodyLines[l];
            System.debug('emailBodyLines[l-1]-> ' + emailBodyLines[l-1]);
            emailBodyLines.remove(l);
            l--;
        }
        return emailBodyLines;
    }
}