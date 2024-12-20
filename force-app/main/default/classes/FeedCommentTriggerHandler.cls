public without sharing class FeedCommentTriggerHandler {
    public static void handleBeforeInsert(List<FeedComment> feedCommentList) {
        Set<Id> communityPortalUserProfileIds = new Set<Id>();
        for(Profile pf :[SELECT Id FROM Profile WHERE Name like 'IWCR%']){
            communityPortalUserProfileIds.add(pf.Id);
        }
        SObjectType caseSObjectType = Case.SObjectType;
        Set<Id> communityPortalUserIds = new Set<Id>();
        for (User user : [SELECT Id FROM User WHERE ProfileId IN :communityPortalUserProfileIds]) {
            communityPortalUserIds.add(user.Id);
        }
        Id currentUserId = UserInfo.getUserId();
        for (FeedComment comment : feedCommentList) {
            // Check if the comment's parent is a Case
            if (comment.ParentId != null && comment.ParentId.getSObjectType() == caseSObjectType) {
                // Check if the current user is a community portal user
                if (communityPortalUserIds.contains(currentUserId)) {
                    comment.addError('Users in the community portal are not allowed to comment here.');
                }
            }
        }
    }
}