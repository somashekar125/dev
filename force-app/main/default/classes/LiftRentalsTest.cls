@isTest
public class LiftRentalsTest {
    @isTest public static void coverLiftRentals(){
        Account acc = TestDataFactory.createAccount();
        acc.Source_Key__c = '1265865';
        insert acc;
        list<Product2> prodList = new list<Product2>();
        Product2 prod1 = new Product2(Name = 'ES-ONSITE-EQUIPMENT-RENTAL-COST',Source_Key__c = '22222', isActive =  true,
                                      Family = 'Service', Account_Item_Belongs_To__c = acc.Id,No_Return_Shipment__c = true);
        Product2 prod2 = new Product2(Name = 'ES-ONSITE-EQUIPMENT-RENTAL-CHARGE',Source_Key__c = '22222',isActive =  true,
                                      Family = 'Service', Account_Item_Belongs_To__c = acc.Id);
        prodList.add(prod1);
        prodList.add(prod2);
        insert prodList;
        list<PricebookEntry> pbeList = new list<PricebookEntry>();
        PricebookEntry standardPrice = TestDataFactory.createPricebookEntry(prodList[0]);
        PricebookEntry standardPrice1 = TestDataFactory.createPricebookEntry(prodList[1]);
        pbeList.add(standardPrice);
        pbeList.add(standardPrice1); 
		insert pbeList;
        ServiceContract sc = TestDataFactory.createServiceContract(acc);
        insert sc;
        Case cs = TestDataFactory.createCase(acc, sc);
        insert cs;
        WorkOrder wo = TestDataFactory.createWorkOrder(cs, sc, acc);
        wo.Preferred_Time_IMAC__c = System.now();
        insert wo;
        
        Test.startTest();
        Boolean existWOLI = LiftRentals.checkForExistingWOLI(wo.Id);
        System.assert(existWOLI == false);
        Boolean isLiftRequested = LiftRentals.orderingLift(wo.Id,'Sunbelt Rentals',wo.Preferred_Time_IMAC__c.date(),'07:00:00.000Z');
        System.assert(isLiftRequested == true);
        Boolean isReturnLiftRequested  = LiftRentals.returningLift(wo.Id);
        System.assert(isReturnLiftRequested == true);
        WorkOrder woCheck = [SELECT Id,Order_Lift__c,Return_Lift__c FROM WorkOrder WHERE Id =:wo.Id];
        System.assert(woCheck.Order_Lift__c == true);
        System.assert(woCheck.Return_Lift__c == true);
        Test.stopTest();
    }
}