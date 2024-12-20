public without sharing class MaintenancePlanTriggerHandler {
    public static void handleAfterUpdate(Map<Id, MaintenancePlan> newMap, Map<Id, MaintenancePlan> oldMap) {
        correctingNextSuggestedMaintenanceDate(newMap,oldMap);
    }
    
    public static void correctingNextSuggestedMaintenanceDate(map<Id, MaintenancePlan> newMap, map<Id, MaintenancePlan> oldMap){
        List<MaintenanceAsset> maList = [SELECT Id,MaintenancePlanId,NextSuggestedMaintenanceDate FROM MaintenanceAsset 
                                         WHERE MaintenancePlanId IN: newMap.keySet()];
        List<MaintenanceAsset> maListToUpdate = new List<MaintenanceAsset>();
        for(MaintenancePlan mp : newMap.values()){
            for(MaintenanceAsset ma : maList){
                if(ma.MaintenancePlanId != mp.Id) continue;
                // MaintenanceAsset.NextSuggestedMaintenanceDate must be equal or greater then MaintenancePlan.NextSuggestedMaintenanceDate
                if(mp.NextSuggestedMaintenanceDate > ma.NextSuggestedMaintenanceDate){
                    ma.NextSuggestedMaintenanceDate = mp.NextSuggestedMaintenanceDate;
                    maListToUpdate.add(ma);
                }
            }
        }
        if(!maListToUpdate.isEmpty()){
            update maListToUpdate;
        }
    }
}