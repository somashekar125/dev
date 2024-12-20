trigger ServiceAppointmentTrigger on ServiceAppointment ( After insert) {
    if(trigger.isInsert && trigger.isAfter){
        ServiceAppointmentTriggerHandler.handleAfterInsert(trigger.new);
    }
    /*if(trigger.isUpdate && trigger.isAfter){
        ServiceAppointmentTriggerHandler.handleAfterUpdate(trigger.newMap, trigger.oldMap);
    }*/
}