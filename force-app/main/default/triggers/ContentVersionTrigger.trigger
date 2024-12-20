trigger ContentVersionTrigger on ContentVersion (before insert) {
    /*if(trigger.isInsert && trigger.isBefore){
        list<ContentWorkspace> cws = [Select Id, Name from ContentWorkspace where Name = 'Field Nation' limit 1];
        for(ContentVersion cv : trigger.new){
            if(cws.size() != 0){
                //cv.FirstPublishLocationId = cws[0].Id;
            }
        }
    }*/
}