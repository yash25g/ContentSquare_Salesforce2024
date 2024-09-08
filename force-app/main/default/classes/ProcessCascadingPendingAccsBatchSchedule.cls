public class ProcessCascadingPendingAccsBatchSchedule implements Schedulable {
    public void execute(SchedulableContext ctx) {
        ProcessCascadingPendingAccsBatch batch = new ProcessCascadingPendingAccsBatch();
        Database.executeBatch(batch);
    }
}