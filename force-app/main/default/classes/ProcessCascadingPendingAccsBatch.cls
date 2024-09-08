public class ProcessCascadingPendingAccsBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    private static final String CLASS_NAME = ProcessCascadingPendingAccsBatch.class.getName();
	@testVisible
    private Integer queryLimitForTestClass = 101;
    private List<Account> parentAccs = new List<Account>();
    private Map<String, Integer> segmentPriority = new Map<String, Integer>{
        Label.Enterprise => 3, //high value means high priority
        Label.MidMarket => 2,
        Label.Smb => 1
    };

    public ProcessCascadingPendingAccsBatch(List<Account> accsToProcess){
        parentAccs = accsToProcess;
    }
    
    public ProcessCascadingPendingAccsBatch(){
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        if(parentAccs.isEmpty()){
            return Database.getQueryLocator([
                SELECT Name, CascadingPending__c, BusinessReviewSegment__c, UltimateAccount__c, RootAccount__c, ParentId 
                FROM Account
                WHERE CascadingPending__c = TRUE
            ]);   
        }
        return Database.getQueryLocator([
            SELECT Name, CascadingPending__c, BusinessReviewSegment__c, UltimateAccount__c, RootAccount__c, ParentId 
            FROM Account
            WHERE Id IN :parentAccs
        ]);
    }
    
    public void execute(Database.BatchableContext bc, List<Account> pendingCascadingAccounts) {
        Map<Id,Account> accsToUpdate = new Map<Id,Account>();        
        Map<Id,Account> accIdVsAccount = new Map<Id,Account>();
        Set<Id> accsIdsToQuery = new Set<Id>();
        try{
            for(Account eachAcc : pendingCascadingAccounts){
                if(eachAcc.CascadingPending__c){
                    eachAcc.CascadingPending__c = FALSE;
                    accsToUpdate.put(eachAcc.Id,eachAcc);
                }            
                accIdVsAccount.put(eachAcc.Id, eachAcc);
                accsIdsToQuery.add(eachAcc.Id);
            }
            for(Account eachAcc : pendingCascadingAccounts){
                if(accIdVsAccount.containsKey(eachAcc.ParentId)){
                    accsIdsToQuery.remove(eachAcc.Id);
                }
            }
            do{            
                parentAccs = [SELECT BusinessReviewSegment__c,RootAccount__c, ParentId, Name FROM Account WHERE ParentId IN :(accsIdsToQuery)];
                accsIdsToQuery.clear();
                for(Account eachChildAcc : parentAccs){
                    Account parentAccOfCurrentAcc = accIdVsAccount.get(eachChildAcc.ParentId);               
                    String childSegment = eachChildAcc.BusinessReviewSegment__c;
                    String parentSegment = parentAccOfCurrentAcc.BusinessReviewSegment__c;
                    accsIdsToQuery.add(eachChildAcc.Id);
                    eachChildAcc.CascadingPending__c = FALSE;
                    eachChildAcc.RootAccount__c = parentAccOfCurrentAcc.RootAccount__c;
                    eachChildAcc.UltimateAccount__c = parentAccOfCurrentAcc.UltimateAccount__c;
                    if (segmentPriority.containsKey(childSegment) &&
                        segmentPriority.containsKey(parentSegment) &&
                        segmentPriority.get(parentSegment) > segmentPriority.get(childSegment)){
                            eachChildAcc.BusinessReviewSegment__c = parentSegment;  
                        }
                    accIdVsAccount.put(eachChildAcc.Id, eachChildAcc);
                    accsToUpdate.put(eachChildAcc.Id,eachChildAcc);
                }
            }while( (Limits.getQueries() < 101 && Limits.getQueries() < queryLimitForTestClass) && !parentAccs.isEmpty());
            Database.update(accsToUpdate.values(),false);            
        }
        catch(Exception ex){
            ErrorLogHelper.createErrorLog(CLASS_NAME, 'execute', ex.getTypeName(), ex.getMessage(), ex.getStackTraceString());
        }        
    }
    
    public void finish(Database.BatchableContext bc) {
        if(!parentAccs.isEmpty()){
			ProcessCascadingPendingAccsBatch pendingCascadeBatch = new ProcessCascadingPendingAccsBatch(parentAccs);
			Database.executeBatch(pendingCascadeBatch);
		}
    }
}