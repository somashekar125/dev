// Tests for MassDeleteExtension
@isTest
private class MassDeleteExtensionTest {
    @isTest static void testDeleteRecords() {
        List<Lead> leads = new List<Lead>();
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(leads);
        MassDeleteExtension extension = new MassDeleteExtension(sc);

        System.assertNotEquals(null, extension.deleteRecords());
    }
    
    @isTest static void testDeleteRecords2() {
        List<WorkOrder> woList = new List<WorkOrder>();
        WorkOrder wo = new WorkOrder();
        wo.NetsuiteId__c = '1234';
        woList.add(wo);
        insert woList;
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(woList);
        sc.setSelected(woList);
        MassDeleteExtension extension = new MassDeleteExtension(sc);
        System.assertNotEquals(null, extension.deleteRecords());
        
    }

    @isTest static void testSelectedSize() {
        List<Lead> leads = new List<Lead>();
        leads.add(new Lead(LastName='test'));

        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(leads);
        sc.setSelected(leads);
        MassDeleteExtension extension = new MassDeleteExtension(sc);

        System.assertEquals('1', extension.getMySelectedSize());
    }
}