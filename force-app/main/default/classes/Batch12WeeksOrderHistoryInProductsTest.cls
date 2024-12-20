@isTest
public class Batch12WeeksOrderHistoryInProductsTest {
    @isTest static void testMethod1(){
        Account acc = TestDataFactory.createAccount();
        insert acc;
        
        ServiceContract sc = TestDataFactory.createServiceContract(acc);
        sc.Include_In_Burn_Rate_Calculation__c = true;
        insert sc;
        
        Case cs = TestDataFactory.createCase(acc, sc);
        insert cs;
        
        Product2 origProd = TestDataFactory.createProduct2(acc);
        insert origProd;
        
        List<Product2> prodList = new List<Product2>();
        Product2 childProd = TestDataFactory.createProduct2(acc);
        childProd.Original_Part__c = origProd.Id;
        childProd.Product_Condition__c = 'New';
        childProd.NS_Quantity_Available__c = 10;
        childProd.NS_Quantity_On_Hand__c = 10;
        prodList.add(childProd);
        
        Product2 childProd2 = TestDataFactory.createProduct2(acc);
        childProd2.Original_Part__c = origProd.Id; 
        childProd2.Product_Condition__c = 'Tested Defective';
        childProd2.Defective_Quantity_Available__c = 10;
        childProd2.Defective_Quantity_on_Hand__c = 10;
        prodList.add(childProd2);
        
        Product2 childProd3 = TestDataFactory.createProduct2(acc);
        childProd3.Original_Part__c = origProd.Id; 
        childProd3.Product_Condition__c = 'Defective';
        childProd3.Tested_Defective_QA__c = 10;
        childProd3.Tested_Defective_QOH__c = 10;
        prodList.add(childProd3);
        
        Product2 childProd4 = TestDataFactory.createProduct2(acc);
        childProd4.Original_Part__c = origProd.Id;
        childProd4.Name = 'Tested Defective';
        childProd4.Product_Condition__c = '';
        childProd4.Tested_Defective_QA__c = 10;
        childProd4.Tested_Defective_QOH__c = 10;
        prodList.add(childProd4);
        insert prodList;
        
        Sales_Order__c so = TestDataFactory.createSalesOrder(acc, cs);
        insert so;
        List<Sales_Order_Line__c> soliList = new List<Sales_Order_Line__c>();
        for(Product2 p : prodList) {
            Sales_Order_Line__c soli = new Sales_Order_Line__c(Sales_Order__c = so.Id, Product__c = p.Id, Quantity__c = 1);
            soliList.add(soli);
        }
        insert soliList;
        
        List<Case_Product__c> cpList = new List<Case_Product__c>();
        for(Product2 p : prodList) {
            Case_Product__c cp = new Case_Product__c(Case__c = cs.Id, Product__c = p.Id, Quantity__c = 1);
            cpList.add(cp);
        }
        insert cpList;
        
        Test.startTest();
        Batch12WeeksOrderHistoryInProducts sch = new Batch12WeeksOrderHistoryInProducts();
        Database.executeBatch(sch);
        Test.stopTest();
        
        Product2 origProdCheck = [SELECT Id, Burn_Rate__c, X12_Weeks_Order_History__c, Quantity_Available__c, 
                                  Quantity_on_Hand__c, Defective_Quantity_Available__c, Defective_Quantity_on_Hand__c, 
                                  Tested_Defective_QA__c, Tested_Defective_QOH__c FROM Product2 WHERE Id =:origProd.Id];
        System.assertEquals(20, origProdCheck.Quantity_Available__c, 'Expected Quantity_Available__c not matching');
        System.assertEquals(10, origProdCheck.Quantity_on_Hand__c, 'Expected Quantity_on_Hand__c not matching');
        System.assertEquals(10, origProdCheck.Defective_Quantity_Available__c, 'Expected Defective_Quantity_Available__c not matching');
        System.assertEquals(10, origProdCheck.Defective_Quantity_on_Hand__c, 'Expected Defective_Quantity_on_Hand__c not matching');
        System.assertEquals(10, origProdCheck.Tested_Defective_QA__c, 'Expected Tested_Defective_QA__c not matching');
        System.assertEquals(10, origProdCheck.Tested_Defective_QOH__c, 'Expected Tested_Defective_QOH__c not matching');
        System.assertEquals(0.34, origProdCheck.Burn_Rate__c, 'Expected Burn_Rate__c not matching');
        
        List<Product2> variantsList = [SELECT Id, Burn_Rate__c, X12_Weeks_Order_History__c FROM Product2 WHERE Original_Part__c =:origProd.Id];
        System.assertEquals(4, variantsList.size(), 'Expected 4 child products');
        for(Product2 p : variantsList) {
            System.assertNotEquals(0, p.Burn_Rate__c, 'Expected Burn_Rate__c not to be 0');
        }
    }
}