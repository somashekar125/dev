@isTest
public class MaintenancePlanTriggerHandlerTest {
    @testSetup static void setup() {
        Test.startTest();
        Account acc = TestDataFactory.createAccount();
        insert acc;
        Product2 prod = TestDataFactory.createProduct2(acc);
        insert prod;
        Test.stopTest();
    }
    
    @isTest static void testMethod1(){
        Account acc = [SELECT Id FROM Account WHERE Name = 'test account' LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 WHERE Account_Item_Belongs_To__c =: acc.Id LIMIT 1];
        
        Asset a = new Asset();
        a.Name = 'Test';
        a.AccountId = acc.Id;
        a.Product2Id = prod.Id;
        insert a;
        
        MaintenancePlan mp = new MaintenancePlan();
        mp.AccountId = acc.Id;
        mp.StartDate = System.now().date();
        mp.Frequency = 1;
        mp.FrequencyType = 'Months';
        mp.GenerationTimeframe = 1;
        mp.GenerationTimeframeType = 'Months';
        mp.NextSuggestedMaintenanceDate = System.now().date();
        insert mp;
        
        MaintenanceAsset ma = new MaintenanceAsset();
        ma.MaintenancePlanId = mp.Id;
        ma.NextSuggestedMaintenanceDate = System.now().date();
        ma.AssetId = a.Id;
        insert ma;
        
        Test.startTest();
        mp.NextSuggestedMaintenanceDate = System.now().date().addDays(1);
        update mp;
        Test.stopTest();
        MaintenanceAsset maCheck = [SELECT Id,NextSuggestedMaintenanceDate FROM MaintenanceAsset WHERE Id =: ma.Id];
        System.assert(maCheck.NextSuggestedMaintenanceDate == System.now().date().addDays(1));
    }
}