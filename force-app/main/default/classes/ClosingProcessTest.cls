@isTest
public class ClosingProcessTest {
    @isTest static void testMehtod1(){
        Account acc = TestDataFactory.createAccount();
        insert acc;
        ServiceContract sc = TestDataFactory.createServiceContract(acc);
        insert sc;
        Case cs = TestDataFactory.createCase(acc, sc);
        insert cs;
        WorkOrder wo = TestDataFactory.createWorkOrder(cs, sc, acc);
        insert wo;
        
        Test.startTest();
        Boolean existWOLI = ClosingProcess.checkForLiftWOLI(wo.Id);
        System.assert(existWOLI == false);
        WorkOrder woCheck = ClosingProcess.getwoRec(wo.Id);
        System.assert(woCheck != null);
        Case csCheck = ClosingProcess.getCaseRec(cs.Id);
        System.assert(csCheck != null);
        Boolean prodTransfersExistInWO = ClosingProcess.checkForProductTransfers(wo.Id);
        System.assert(prodTransfersExistInWO == false);
        Boolean prodTransfersExistInCase = ClosingProcess.checkForProductTransfers2(cs.Id);
        System.assert(prodTransfersExistInWO == false);
        Test.stopTest();
    }   
}