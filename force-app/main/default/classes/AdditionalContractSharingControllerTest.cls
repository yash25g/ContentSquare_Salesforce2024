@isTest
public class AdditionalContractSharingControllerTest {
    
    private static Map<String,Id> accRececTypeNameVsId = new Map<String,Id>();
    static{
        for(RecordType eachAccRecType : [SELECT Id, DeveloperName, SobjectType FROM RecordType WHERE SobjectType = 'Account']){
            accRececTypeNameVsId.put(eachAccRecType.DeveloperName, eachAccRecType.Id);
        }
    }
    
    @testSetup
    static void setupData(){
        
        // Create test Accounts.
        Account ultimateAcc = new Account(Name = 'Ultimate Account',
                                          RecordTypeId = accRececTypeNameVsId.get(Label.UltimateAccountRecordType));
        insert ultimateAcc;
        
        List<Account> accsToInsert = new List<Account>();
        
        Account businessAccount = new Account(Name = 'Business Account', ParentId = ultimateAcc.Id,
                                              RecordTypeId = accRececTypeNameVsId.get(Label.BusinessAccountRecordType),
                                              BusinessReviewSegment__c = Label.Enterprise,
                                              BillingCountry = 'Canada', BillingCountryCode = 'CA');
        insert businessAccount;
        
        Account partnerAccount = new Account(Name = 'Partner Account', ParentId = businessAccount.Id,
                                             BusinessReviewSegment__c = Label.MidMarket,
                                             RecordTypeId = accRececTypeNameVsId.get(Label.PartnerAccountRecordType),
                                             BillingCountry = 'India', BillingCountryCode = 'IN');
        
        Account partnerAccount1 = new Account(Name = 'Partner Account1', BusinessReviewSegment__c = Label.Enterprise,
                                              RecordTypeId = accRececTypeNameVsId.get(Label.PartnerAccountRecordType),
                                              BillingCountry = 'India', BillingCountryCode = 'IN');
        accsToInsert.add(partnerAccount);
        accsToInsert.add(partnerAccount1);
        insert accsToInsert;
    }
    
    @isTest
    static void testGetAccountToDisplay() {
        // Retrieve root account and bill to account
        Account rootAccount = [SELECT Id FROM Account WHERE Name = 'Ultimate Account' LIMIT 1];
        Account billToAccount = [SELECT Id FROM Account WHERE Name = 'Business Account' LIMIT 1];
        Account partnerAccount = [SELECT Id FROM Account WHERE Name = 'Partner Account' LIMIT 1];
        List<Account> accs = [SELECT Name FROM Account WHERE RootAccount__c = :rootAccount.Id];
        // Test getAccountToDisplay method
        List<String> accIdsToExclude = new List<String>{};
        List<AdditionalContractSharingController.AccountWrapper> accsToDisplay;
        Test.startTest();
        accsToDisplay = AdditionalContractSharingController.getAccountToDisplay(rootAccount.Id,Label.BusinessAccountRecordType,
                                                                                billToAccount.Id,accIdsToExclude);
        Test.stopTest();
        
        System.assertEquals(1, accsToDisplay.size());
        accIdsToExclude = new List<String>{};
        accsToDisplay = AdditionalContractSharingController.getAccountToDisplay(rootAccount.Id,Label.PartnerAccountRecordType,
                                                                                partnerAccount.Id,accIdsToExclude);
        
        System.assertEquals(2, accsToDisplay.size());
                accIdsToExclude = new List<String>{};
        accsToDisplay = AdditionalContractSharingController.getAccountToDisplay(null,Label.PartnerAccountRecordType,
                                                                                partnerAccount.Id,accIdsToExclude);
        
        System.assertEquals(2, accsToDisplay.size());
    }
    
    @isTest
    static void testCreateContractForAdditionalAccounts() {
        // Retrieve customer account
        Account businessAccount = [SELECT Id, AccountStatus__c FROM Account WHERE Name = 'Business Account' LIMIT 1];
        Account partnerAccount = [SELECT Id, AccountStatus__c FROM Account WHERE Name = 'Partner Account' LIMIT 1];
        Contact testContact = new Contact(LastName = 'TestConName', AccountId = businessAccount.Id);
        insert testContact;
        Opportunity testOpp = new Opportunity(AccountId = businessAccount.Id, OppPrimaryContact__c = testContact.Id, CloseDate = System.today(), 
                                              Name = 'Test Opp', StageName = '2- Sales Accepted');
        insert testOpp;
        
        Contract__c contract = new Contract__c(Name = 'Test Contract', BillToAccount__c = businessAccount.Id,
                                               ContractSignedDate__c = System.today(), WorkdayReferenceId__c = testOpp.Id);
        insert contract;
        
        // Create a List of AccountWrapper JSON
        List<AdditionalContractSharingController.AccountWrapper> accountWrapperList = new List<AdditionalContractSharingController.AccountWrapper>();
        
        AdditionalContractSharingController.AccountWrapper accWrapper = new AdditionalContractSharingController.AccountWrapper();
        accWrapper.accId = partnerAccount.Id;
        accWrapper.accStatus = 'Target';
        accountWrapperList.add(accWrapper);
        
        String jsonAccountWrapper = JSON.serialize(accountWrapperList);
        
        // Prepare parameters for createContractForAdditionalAccounts method
        List<String> parameters = new List<String>{jsonAccountWrapper, contract.Id};
        List<List<String>> flowParameters = new List<List<String>>{parameters};
        
        // Call the createContractForAdditionalAccounts method
        Test.startTest();
        AdditionalContractSharingController.createContractForAdditionalAccounts(flowParameters);
        Test.stopTest();
        
        // Verify the ContractShipToAccount__c was created
        List<ContractShipToAccount__c> contractSharings = [SELECT Id FROM ContractShipToAccount__c WHERE Account__c = :partnerAccount.Id];
        System.assertEquals(1, contractSharings.size());
        
        // Verify the Account status was updated
        partnerAccount = [SELECT Id, AccountStatus__c FROM Account WHERE Id = :partnerAccount.Id];
        System.assertEquals('Customer', partnerAccount.AccountStatus__c);
    }
}