@isTest
public class FeedCommentTriggerHandlerTest {
    @isTest static void testMethod1(){
        //FeedItemId fi = new
        Test.startTest();
        FeedComment fc = new FeedComment();
        fc.CommentBody = 'Test';
        insert fc;
        Test.stopTest();
    }
}