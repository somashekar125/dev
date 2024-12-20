@isTest
public class ProductTriggerTest {
    @testSetup static void setup() {
        Account rootAcc = TestDataFactory.createAccount();
        rootAcc.Name = 'Test PBS';
        rootAcc.Source_Key__c = '3450987';
        rootAcc.NS_Id__c = 'ax001';
        insert rootAcc;
        
        Account acc = TestDataFactory.createAccount();
        acc.Root_Account__c = rootAcc.Id;
        acc.Source_Key__c = '1265865';
        acc.NS_Id__c = 'ax0012';
        insert acc;
        
        ServiceContract sc = TestDataFactory.createServiceContract(rootAcc);
        insert sc;
        Case cs = TestDataFactory.createCase(acc, sc);
        insert cs;
        Sales_Order__c so = TestDataFactory.createSalesOrder(rootAcc, cs);
        insert so;
    }
    
   /* @isTest static void testMethod1(){
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test PBS' LIMIT 1];
        Case cs = [SELECT Id FROM Case LIMIT 1];
        Sales_Order__c so = [SELECT Id FROM Sales_Order__c LIMIT 1];
        
        Test.startTest();
        Product2 originalProduct = TestDataFactory.createProduct2(acc);
        insert originalProduct;
        
        list<Product2> prodList = new list<Product2>();
        Product2 prod1 = TestDataFactory.createProduct2(acc);
        prod1.Product_Condition__c = 'New';
        
        Product2 prod2 = TestDataFactory.createProduct2(acc);
        prod2.Product_Condition__c = 'Refurbished';
        
        Product2 prod3 = TestDataFactory.createProduct2(acc);
        prod3.Product_Condition__c = 'Defective';
        
        Product2 prod4 = TestDataFactory.createProduct2(acc);
        prod4.Product_Condition__c = 'Tested Defective';
        prod4.Base_Price__c = null;
        
        prodList.add(prod1);
        prodList.add(prod2);
        prodList.add(prod3);
        prodList.add(prod4);
        insert prodList;
        
        List<Sales_Order_Line__c> soliList = new List<Sales_Order_Line__c>();
        for(Product2 p : prodList) {
            Sales_Order_Line__c soli = new Sales_Order_Line__c(Sales_Order__c = so.Id, Product__c = p.Id, Quantity__c = 1);
            soliList.add(soli);
        }
        insert soliList;
        
        List<Product2> variantList = [SELECT Id, Original_Part__c, Burn_Rate__c From Product2 
                                      WHERE Id =: new Map<Id, Product2>(prodList).keySet()];
        for(Product2 p : variantList) {
            System.assert(p.Original_Part__c == originalProduct.Id);
        }
        
        originalProduct.Name = 'Test Original Product';
        ProductTriggerHandler.runOnceBeforeUpdate = true;
        ProductTriggerHandler.runOnceAfterUpdate = true;
        update originalProduct;
        originalProduct = [SELECT Id, Burn_Rate__c FROM Product2 WHERE Id =:originalProduct.Id];
        System.assert(originalProduct.Burn_Rate__c == 0.34);
        
        List<Product2> variantsList = [SELECT Id, Original_Part__c, Burn_Rate__c From Product2 WHERE Original_Part__c =: originalProduct.Id];
        System.assert(variantsList.size() == 4);
        for(Product2 p : variantsList) {
            System.assert(p.Original_Part__c == originalProduct.Id);
            System.assert(p.Burn_Rate__c != 0);
        }
        
    List<Product2> prodList2 = new List<Product2>(prodList);
        prodList2[0].Original_Part__c = null;
        prodList2[0].Base_Price__c = 20;
        prodList2.add(originalProduct);
        ProductTriggerHandler.runOnceBeforeUpdate = true;
        ProductTriggerHandler.runOnceAfterUpdate = true;
        update prodList2;
        Test.stopTest();
        
        List<Product2> variantsList2 = [SELECT Id, Original_Part__c, Burn_Rate__c From Product2 WHERE Original_Part__c =: originalProduct.Id];
        System.assert(variantsList2.size() == 4);
        for(Product2 p : variantsList2) {
            System.assert(p.Original_Part__c == originalProduct.Id);
            System.assert(p.Burn_Rate__c != 0);
        }
    } */
    
    @isTest static void testMethod2(){
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test PBS' LIMIT 1];
        Case cs = [SELECT Id FROM Case LIMIT 1];
        Sales_Order__c so = [SELECT Id FROM Sales_Order__c LIMIT 1];
        
        Test.startTest();
        Product2 originalProduct = TestDataFactory.createProduct2(acc);
        originalProduct.Product_Condition__c = null;
        insert originalProduct;
        
        list<Product2> prodList = new list<Product2>();
        Product2 prod1 = TestDataFactory.createProduct2(acc);
        prod1.Name = 'Test Product (New)';
        prod1.Product_Condition__c = null;
        
        Product2 prod2 = TestDataFactory.createProduct2(acc);
        prod2.Name = 'Test Product (Refurbished)';
        prod2.Product_Condition__c = null;
        
        Product2 prod3 = TestDataFactory.createProduct2(acc);
        prod3.Name = 'Test Product (Defective)';
        prod3.Product_Condition__c = null;
        
        Product2 prod4 = TestDataFactory.createProduct2(acc);
        prod4.Name = 'Test Product (Tested Defective)';
        prod4.Product_Condition__c = null;
        prod4.Base_Price__c = null;
        
        prodList.add(prod1);
        prodList.add(prod2);
        prodList.add(prod3);
        prodList.add(prod4);
        insert prodList;
        
        List<Sales_Order_Line__c> soliList = new List<Sales_Order_Line__c>();
        for(Product2 p : prodList) {
            Sales_Order_Line__c soli = new Sales_Order_Line__c(Sales_Order__c = so.Id, Product__c = p.Id, Quantity__c = 1);
            soliList.add(soli);
        }
        insert soliList;
        
        List<Product2> variantList = [SELECT Id, Original_Part__c, Burn_Rate__c From Product2 
                                      WHERE Id =: new Map<Id, Product2>(prodList).keySet()];
        for(Product2 p : variantList) {
            System.assert(p.Original_Part__c == originalProduct.Id);
        }
        
    List<Product2> prodList2 = new List<Product2>(prodList);
        prodList2[0].Original_Part__c = null;
        prodList2[0].Base_Price__c = 20;
        prodList2.add(originalProduct);
        ProductTriggerHandler.runOnceBeforeUpdate = true;
        ProductTriggerHandler.runOnceAfterUpdate = true;
        update prodList2;
        
        List<Product2> variantsList2 = [SELECT Id, Original_Part__c, Burn_Rate__c From Product2 WHERE Original_Part__c =: originalProduct.Id];
        System.assert(variantsList2.size() == 4);
        for(Product2 p : variantsList2) {
            System.assert(p.Original_Part__c == originalProduct.Id);
            //System.assert(p.Burn_Rate__c != 0);
        }
        originalProduct = [SELECT Id, Burn_Rate__c FROM Product2 WHERE Id =:originalProduct.Id];
        //System.assert(originalProduct.Burn_Rate__c == 0.34);
        
        delete variantsList2;
        Test.stopTest();
    }
    
    @isTest static void testMethod3(){
        Account acc = TestDataFactory.createAccount();
        acc.Name = 'IW Technologies - United Natural Foods';
        acc.Source_Key__c = '6789876';
        acc.NS_Id__c = 'ax003';
        insert acc;
        
        Test.startTest();
        Product2 originalProduct = TestDataFactory.createProduct2(acc);
        originalProduct.Name = 'Test Product<br>';
        originalProduct.Family = 'InventoryItem';
        insert originalProduct;
        
        List<Product2> childProdList = new List<Product2>();
        Product2 childProduct = TestDataFactory.createProduct2(acc);
        childProduct.Product_Condition__c = 'Defective';
        childProduct.Defective_Quantity_Available__c = 10;
        childProduct.Defective_Quantity_on_Hand__c = 10;         
        childProdList.add(childProduct);
        
        Product2 childProduct2 = TestDataFactory.createProduct2(acc);
        childProduct2.Product_Condition__c = 'Tested Defective';
        childProduct2.Defective_Quantity_Available__c = 10;
        childProduct2.Defective_Quantity_on_Hand__c = 10;
        childProdList.add(childProduct2);
        
        Product2 childProduct3 = TestDataFactory.createProduct2(acc);
        childProduct3.Product_Condition__c = 'New';
        childProduct3.Defective_Quantity_Available__c = 10;
        childProduct3.Defective_Quantity_on_Hand__c = 10;
        childProdList.add(childProduct3);
        insert childProdList;
        
        childProduct2.IsActive = false;
        childProduct2.Name = 'Test Product (Test Defective)';
        childProduct2.Original_Part__c = null;
        ProductTriggerHandler.runOnceBeforeUpdate = true;
        ProductTriggerHandler.runOnceAfterUpdate = true;
        update childProduct2;
        
        Product2 origProdCheck = [SELECT Id,Name,NS_Quantity_Available__c,NS_Quantity_On_Hand__c,Defective_Quantity_Available__c,
                                  Defective_Quantity_on_Hand__c FROM Product2 WHERE Id =: originalProduct.Id];
        System.assert(origProdCheck.Name == 'Test Product');
        
        childProduct2.IsActive = true;
        ProductTriggerHandler.runOnceBeforeUpdate = true;
        ProductTriggerHandler.runOnceAfterUpdate = true;
        update childProduct2;
        
        delete childProdList;
        Test.stopTest();
    }
}