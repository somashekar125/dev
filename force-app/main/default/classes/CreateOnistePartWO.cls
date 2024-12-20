public class CreateOnistePartWO {
    @InvocableMethod(label='Insert Part WO' description='Inserts Work Order for Hardware Products.')
    public static void CreateOnistePartWO(List<Id> CaseIds) {
        Set<Id> caseIdsFromFlow = new Set<Id>(CaseIds);
        CaseTriggerHandler.createOnsitePartWO(caseIdsFromFlow);
    }
}