public class BatchOrderHistoryInProductsScheduler implements Schedulable {
    public void execute(SchedulableContext sc){
        Batch12WeeksOrderHistoryInProducts prodBatch = new Batch12WeeksOrderHistoryInProducts();
        Database.executeBatch(prodBatch);
    }
}