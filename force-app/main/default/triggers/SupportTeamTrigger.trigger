trigger SupportTeamTrigger on Support_Team__c (before update) {
    for(Support_Team__c st : trigger.new){
        if(st.Tech_Notes__c != Trigger.oldMap.get(st.Id).Tech_Notes__c){
            st.Tech_Notes__c = Trigger.oldMap.get(st.Id).Tech_Notes__c;
        }
    }
}