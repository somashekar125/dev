public class BatchSendProductInventoryEmails implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc){
        String query = 'SELECT Id, Name, Quantity_Available__c, Reorder_Point__c, Critical_Quantity__c, '+
            		   ' Inventory_Email_Sent__c, Critical_Email_Sent__c, Account_Item_Belongs_To__c FROM product2 WHERE '+
            		   ' ((Quantity_less_than_Critical__c = True AND Critical_Email_Sent__c = False AND Critical_Quantity__c != null) OR '+
            		   ' (Quantity_Less_than_Reorder_Point__c = True AND Inventory_Email_Sent__c = False AND Reorder_Point__c != null)) '+
            		   ' AND Portal_Access__c = True AND Original_Part__c = null';
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext bc, List<product2> scope){
        Set<Id> accountIdsReorder = new Set<Id>();
        for(Product2 pr : scope){
            accountIdsReorder.add(pr.Account_Item_Belongs_To__c);
        }
        System.debug('accountIdsReorder:'+accountIdsReorder);
        if(accountIdsReorder.size() != 0){
            List<Account> accList = [SELECT Id, Name, (SELECT Id, ContactId, Contact.Name, Contact.Email, Contact.Receive_Inventory_Notifications__c FROM AccountContactRelations WHERE Contact.Receive_Inventory_Notifications__c = true AND Contact.Email != null) FROM Account WHERE Id IN : accountIdsReorder];
            List<Messaging.SingleEmailMessage>  allEmails = new List<Messaging.SingleEmailMessage>();
            List<EmailTemplate> emailTemplete = [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName =: System.Label.Product_Quantity_Mail_Developer_Name OR DeveloperName =: System.Label.Product_Quantity_less_than_Critical_Quantity_Email_Template];
            OrgWideEmailAddress[] owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'services@iwcr.com'];
            String reorderEmailTemplateId = '';
            String criticalEmailTemplateId = '';
            for(EmailTemplate et : emailTemplete){
                if(et.DeveloperName == System.Label.Product_Quantity_Mail_Developer_Name){
                    reorderEmailTemplateId = et.Id;
                }else{
                    criticalEmailTemplateId = et.Id;
                }
            }
            System.debug('emailTemplete:'+emailTemplete);
            for(Account acc : accList){
                Set<String> toAddres = new Set<String>();
                for(AccountContactRelation con : acc.AccountContactRelations){
                    toAddres.add(con.Contact.Email);
                }
                List<String> toAddresses = new List<String>();
                toAddresses.addAll(toAddres);
                System.debug('toAddresses:'+toAddresses);
                for(Product2 p : scope){
                    if(acc.Id != p.Account_Item_Belongs_To__c || acc.AccountContactRelations.size() == 0) continue;
                    if(p.Quantity_Available__c <= p.Reorder_Point__c){
                        Messaging.singleEmailMessage mail = new Messaging.singleEmailMessage();
                        mail.setTargetObjectId(acc.AccountContactRelations[0].ContactId);
                        mail.setTreatTargetObjectAsRecipient(false);
                        mail.toAddresses = toAddresses;
                        mail.setTemplateID(reorderEmailTemplateId);
                        mail.setWhatId(p.Id);
                        if(owea.size() != 0){
                            mail.setOrgWideEmailAddressId(owea[0].Id);
                        }
                        allEmails.add(mail);
                        p.Inventory_Email_Sent__c = true;
                    }
                    if(p.Quantity_Available__c <= p.Critical_Quantity__c){
                        p.Critical_Email_Sent__c = true;
                        Messaging.singleEmailMessage mail = new Messaging.singleEmailMessage();
                        mail.setTargetObjectId(acc.AccountContactRelations[0].ContactId);
                        mail.setTreatTargetObjectAsRecipient(false);
                        mail.toAddresses = toAddresses;
                        mail.setTemplateID(criticalEmailTemplateId);
                        mail.setWhatId(p.Id);
                        if(owea.size() != 0){
                            mail.setOrgWideEmailAddressId(owea[0].Id);
                        }
                        allEmails.add(mail);
                    }
                }
            }
            System.debug('allEmails:'+allEmails);
            if(allEmails.size() != 0){
                Messaging.sendEmail(allEmails);
                update scope;
            }
        }
    }
    public void finish(Database.BatchableContext bc){
        BatchSendProductInventoryEmails bse = new BatchSendProductInventoryEmails();
        if(!test.isRunningTest()){
            List<CronTrigger> ctList = [SELECT Id, CronJobDetail.Name FROM CronTrigger WHERE CronJobDetail.Name = 'BatchSendProductInventoryEmails'];
            if(ctList.isEmpty()){
                //Should be uncomment when deploying
                //System.scheduleBatch(bse, 'BatchSendProductInventoryEmails', 15, 1);
            }
        }
    }
}