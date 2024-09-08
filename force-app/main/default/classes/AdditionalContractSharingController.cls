public class AdditionalContractSharingController{
    
    private static final String CLASS_NAME = AdditionalContractSharingController.class.getName();
    private static List<String> accStatuses = new List<String>{Constants.TARGET, Constants.PROSPECT, Constants.INACTIVATED_CUSTOMER};

        @AuraEnabled
        public static List<AccountWrapper> getAccountToDisplay(String rootAccId, String recordTypeDeveloperName, String billToAccId, List<String> accIdsToExclude){
            List<Account> accsToDisplay;
            List<AccountWrapper> accWrapperList = new List<AccountWrapper>();
            try{
                if(String.isBlank(rootAccId)){
                    rootAccId = billToAccId; //set Root Account Id in case the bill to account is the root account.
                }
                accIdsToExclude.add(billToAccId);               
                if(Label.BusinessAccountRecordType.equalsIgnoreCase(recordTypeDeveloperName)){
                    accsToDisplay = [SELECT Name, RecordType.DeveloperName, AccountStatus__c, Domain__c, BusinessReviewSegment__c,
                                     BillingCountry, Region__c
                                     FROM Account 
                                     WHERE Id NOT IN: accIdsToExclude 
                                     AND RecordType.DeveloperName != :Label.UltimateAccountRecordType
                                     AND (RootAccount__c = :rootAccId OR Id = :rootAccId) WITH USER_MODE];
                }
                else if(Label.PartnerAccountRecordType.equalsIgnoreCase(recordTypeDeveloperName)){
                    accsToDisplay = [SELECT Name, RecordType.DeveloperName, AccountStatus__c, Domain__c, BusinessReviewSegment__c,
                                     BillingCountry, Region__c
                                     FROM Account
                                     WHERE Id NOT IN: accIdsToExclude 
                                     AND RecordType.DeveloperName != :Label.UltimateAccountRecordType WITH USER_MODE];
                }
                for(Account eachAccount : accsToDisplay){
                    AccountWrapper newAccWrapper = new AccountWrapper();
                    newAccWrapper.accId = eachAccount.Id;
                    newAccWrapper.accName = eachAccount.Name;
                    newAccWrapper.accRecordType = eachAccount.RecordType.DeveloperName;
                    newAccWrapper.accStatus = eachAccount.AccountStatus__c;
                    newAccWrapper.accDomain = eachAccount.Domain__c;
                    newAccWrapper.accBusinessReviewSegment = eachAccount.BusinessReviewSegment__c;
                    newAccWrapper.accCountry = eachAccount.BillingCountry;
                    newAccWrapper.accRegion = eachAccount.Region__c;
                    accWrapperList.add(newAccWrapper);
                }
                return accWrapperList;
            }
            catch(Exception ex){
                ErrorLogHelper.createErrorLog(CLASS_NAME, 'getAccountToDisplay', ex.getTypeName(), ex.getMessage(), ex.getStackTraceString());
                return accWrapperList;
            }        
        }
    
    @InvocableMethod
    public static void createContractForAdditionalAccounts(List<List<String>> flowParameter){        
        try{
            List<Account> accsToUpdate = new List<Account>();
            List<String> originalParametersPassed = flowParameter[0];
            String selectedAccRecords = originalParametersPassed[0];
            String contractId = originalParametersPassed[1];
            List<AccountWrapper> listOfAccountWrapper = (List<AccountWrapper>) JSON.deserialize(selectedAccRecords, List<AccountWrapper>.class);
            List<ContractShipToAccount__c> contractSharings = new List<ContractShipToAccount__c>();
            for(AccountWrapper eachAccWrapper : listOfAccountWrapper){
                contractSharings.add(new ContractShipToAccount__c(Account__c = eachAccWrapper.accId , Contract__c = contractId));
                if(accStatuses.contains(eachAccWrapper.accStatus)){
                    accsToUpdate.add(new Account(Id = eachAccWrapper.accId, AccountStatus__c = Constants.CUSTOMER));
                }
            }
            insert contractSharings;
            if(!accsToUpdate.isEmpty()){
               update accsToUpdate;
            } 
        }
        catch(Exception ex){
            ErrorLogHelper.createErrorLog(CLASS_NAME, 'createContractForAdditionalAccounts', ex.getTypeName(), ex.getMessage(), ex.getStackTraceString());
        }        
    }
    
    public Class AccountWrapper{
        @AuraEnabled public String accId;
        @AuraEnabled public String accName;
        @AuraEnabled public String accRecordType;
        @AuraEnabled public String accStatus;
        @AuraEnabled public String accDomain;
        @AuraEnabled public String accBusinessReviewSegment;
        @AuraEnabled public String accCountry;
        @AuraEnabled public String accRegion;
    }
}