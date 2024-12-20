trigger FeedCommentTrigger on FeedComment (before insert) {
    if(trigger.isInsert && trigger.isBefore) {
        //FeedCommentTriggerHandler.handleBeforeInsert(Trigger.new);
    }
}