@isTest
public class ProcessCascadingPendingAccsBatchTest {
    
    private static Map<String,Id> accRececTypeNameVsId = new Map<String,Id>();
    static{
        for(RecordType eachAccRecType : [SELECT Id, DeveloperName, SobjectType FROM RecordType WHERE SobjectType = 'Account']){
            accRececTypeNameVsId.put(eachAccRecType.DeveloperName, eachAccRecType.Id);
        }
    }
    @testSetup
    static void setup() {
        // Create a set of test Accounts with different segments and hierarchy
        Account ultimateAcc = new Account(Name = 'Ultimate Account', 
                                          RecordTypeId = accRececTypeNameVsId.get(Label.UltimateAccountRecordType));
        insert ultimateAcc;
        Account parentAccount1 = new Account(Name = 'Parent Account 1', ParentId = ultimateAcc.Id,
                                             RecordTypeId = accRececTypeNameVsId.get(Label.PartnerAccountRecordType),
                                             BusinessReviewSegment__c = Label.Enterprise, CascadingPending__c = true,
                                             BillingCountry = 'Canada', BillingCountryCode = 'CA');
        Account parentAccount2 = new Account(Name = 'Parent Account 2', CascadingPending__c = true,
                                             RecordTypeId = accRececTypeNameVsId.get(Label.PartnerAccountRecordType), 
                                             BusinessReviewSegment__c = Label.MidMarket, 
                                             BillingCountry = 'India', BillingCountryCode = 'IN');
        Account childAccount1 = new Account(Name = 'Child Account 1', ParentId = parentAccount1.Id, 
                                            BusinessReviewSegment__c = Label.Smb, CascadingPending__c = true,
                                            RecordTypeId = accRececTypeNameVsId.get(Label.PartnerAccountRecordType),
                                            BillingCountry = 'United States', BillingCountryCode = 'US');
        Account childAccount2 = new Account(Name = 'Child Account 2', ParentId = parentAccount2.Id,
                                            RecordTypeId = accRececTypeNameVsId.get(Label.PartnerAccountRecordType),
                                            BusinessReviewSegment__c = Label.Smb, CascadingPending__c = true, 
                                            BillingCountry = 'France', BillingCountryCode = 'FR');
        
        insert new List<Account>{ parentAccount1, parentAccount2, childAccount1, childAccount2 };
    }
    
    @isTest
    static void testBatchWithCascadingUpdate() {
        // Query all accounts created during setup
        List<Account> parentAccounts = [SELECT Id, BusinessReviewSegment__c, CascadingPending__c FROM Account WHERE CascadingPending__c = TRUE];
        
        // Execute the batch process
        Test.startTest();
        ProcessCascadingPendingAccsBatch batch = new ProcessCascadingPendingAccsBatch(parentAccounts);
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Query child accounts to verify if they were updated
        List<Account> childAccounts = [SELECT Name, BusinessReviewSegment__c, CascadingPending__c FROM Account WHERE ParentId != NULL];
        
        // Assert that child accounts' segments have been updated to match their parents' segments
        for (Account childAcc : childAccounts) {
            if (childAcc.Name.contains('Child Account 1')) {
                System.assertEquals(Label.Enterprise, childAcc.BusinessReviewSegment__c, 'Child Account 1 should have been updated to Enterprise.');
            } else if (childAcc.Name.contains('Child Account 2')) {
                System.assertEquals(Label.MidMarket, childAcc.BusinessReviewSegment__c, 'Child Account 2 should have been updated to MidMarket.');
            }
            System.assertEquals(false, childAcc.CascadingPending__c, 'CascadingPending__c should be set to FALSE.');
        }
    }
    
    @isTest
    static void testBatchWithNoCascadingUpdate() {
        // Create a parent account that has a lower or equal priority segment than its child
        Account parentAccount3 = new Account(Name = 'Parent Account 3', BusinessReviewSegment__c = Label.Smb, 
                                             CascadingPending__c = true, 
                                             RecordTypeId = accRececTypeNameVsId.get(Label.PartnerAccountRecordType),
                                             BillingCountry = 'Canada', BillingCountryCode = 'CA');
        insert parentAccount3;
        
        Account childAccount3 = new Account(Name = 'Child Account 3', ParentId = parentAccount3.Id, 
                                            BusinessReviewSegment__c = Label.Enterprise, CascadingPending__c = true,
                                            RecordTypeId = accRececTypeNameVsId.get(Label.PartnerAccountRecordType),
                                            BillingCountry = 'Canada', BillingCountryCode = 'CA');
        insert childAccount3;
        
        // Execute the batch process
        Test.startTest();
        ProcessCascadingPendingAccsBatch batch = new ProcessCascadingPendingAccsBatch(new List<Account>{ parentAccount3 });
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Query the child account to verify if it was NOT updated
        Account updatedChildAccount3 = [SELECT Id, BusinessReviewSegment__c, CascadingPending__c FROM Account WHERE Id = :childAccount3.Id];
        
        // Assert that child account's segment has NOT been updated
        System.assertEquals(Label.Enterprise, updatedChildAccount3.BusinessReviewSegment__c, 'Child Account 3 should NOT have been updated.');
        System.assertEquals(false, updatedChildAccount3.CascadingPending__c, 'CascadingPending__c should be set to FALSE.');
    }
    
    @isTest
    static void testBatchForReparenting() {
       
        Account childAcc = [SELECT ParentId,BusinessReviewSegment__c FROM Account WHERE Name = 'Child Account 2'];
        Account parentAcc = [SELECT ParentId,BusinessReviewSegment__c FROM Account WHERE Name = 'Parent Account 1'];        
        childAcc.ParentId = parentAcc.Id;
        update childAcc;
        // Execute the batch process
        Test.startTest();
        ProcessCascadingPendingAccsBatch batch = new ProcessCascadingPendingAccsBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Query the child account to verify if it was updated
        Account updatedChildAccount = [SELECT Id, BusinessReviewSegment__c, CascadingPending__c FROM Account WHERE Id = :childAcc.Id];
        
        // Assert that child account's segment has been updated
        System.assertEquals(Label.Enterprise, updatedChildAccount.BusinessReviewSegment__c, 'Child Account should have been updated.');
        System.assertEquals(false, updatedChildAccount.CascadingPending__c, 'CascadingPending__c should be set to FALSE.');
    }
    
    @isTest
    static void testBatchForReparentingRootParentWithSchedulable() {
        Account parentAcc1 = [SELECT ParentId,BusinessReviewSegment__c FROM Account WHERE Name = 'Parent Account 1'];
        Account parentAcc2 = [SELECT ParentId,BusinessReviewSegment__c FROM Account WHERE Name = 'Parent Account 2'];
        Account childAccount = [SELECT Parent.Name, BusinessReviewSegment__c, CascadingPending__c FROM Account WHERE Name = 'Child Account 2'];
        childAccount.ParentId = parentAcc2.Id;
        update childAccount;
        parentAcc2.CascadingPending__c = false;
        parentAcc2.ParentId = parentAcc1.Id;
        update parentAcc2;
        // Execute the batch process
        Test.startTest();        
        ProcessCascadingPendingAccsBatchSchedule scheduler = new ProcessCascadingPendingAccsBatchSchedule();
		scheduler.execute(null);
        Test.stopTest();
        childAccount = [SELECT Parent.Name, BusinessReviewSegment__c, CascadingPending__c FROM Account WHERE Name = 'Child Account 2'];
        System.assertEquals(Label.Enterprise, childAccount.BusinessReviewSegment__c, 'Child Account should have been updated.');
        System.assertEquals(false, childAccount.CascadingPending__c, 'CascadingPending__c should be set to FALSE.');
    }
    
    @isTest
    static void testBatchForChaining() {
        Account parentAcc1 = [SELECT ParentId,BusinessReviewSegment__c FROM Account WHERE Name = 'Parent Account 1'];
        Account parentAcc2 = [SELECT ParentId,BusinessReviewSegment__c FROM Account WHERE Name = 'Parent Account 2'];
        Account childAccount = [SELECT Parent.Name, BusinessReviewSegment__c, CascadingPending__c FROM Account WHERE Name = 'Child Account 2'];
        childAccount.ParentId = parentAcc2.Id;
        update childAccount;
        parentAcc2.CascadingPending__c = false;
        parentAcc2.ParentId = parentAcc1.Id;
        update parentAcc2;
        // Execute the batch process
        Test.startTest();
        ProcessCascadingPendingAccsBatch batch = new ProcessCascadingPendingAccsBatch();
        batch.queryLimitForTestClass = 1;
        Database.executeBatch(batch);
        Test.stopTest();
        Account ultimateAcc = [SELECT Id FROM Account WHERE Name = 'Ultimate Account'];
        parentAcc2 = [SELECT CascadingPending__c,BusinessReviewSegment__c,UltimateAccount__c FROM Account WHERE Name = 'Parent Account 2'];
        childAccount = [SELECT UltimateAccount__c, BusinessReviewSegment__c, CascadingPending__c FROM Account WHERE Name = 'Child Account 2'];
        System.assertEquals(Label.Enterprise, childAccount.BusinessReviewSegment__c, 'Child Account should have been updated.');
        System.assertEquals(false, childAccount.CascadingPending__c, 'CascadingPending__c should be set to FALSE.');
        System.assertEquals(ultimateAcc.Id,childAccount.UltimateAccount__c,'Ultimate Acc should be set on grand child account');
    }
    
    @isTest
    static void testBatchForRemovingUltimateAccount() {
        Account parentAcc1 = [SELECT ParentId,BusinessReviewSegment__c FROM Account WHERE Name = 'Parent Account 1'];
        Account parentAcc2 = [SELECT ParentId,BusinessReviewSegment__c FROM Account WHERE Name = 'Parent Account 2'];
        Account childAcc1 = [SELECT BusinessReviewSegment__c,UltimateAccount__c FROM Account WHERE Name = 'Child Account 1'];
        Account ultimateAcc = [SELECT Id FROM Account WHERE Name = 'Ultimate Account'];
        parentAcc1.ParentId = parentAcc2.Id;
        childAcc1.ParentId = parentAcc1.Id;
        update childAcc1;
        childAcc1 = [SELECT UltimateAccount__c FROM Account WHERE Id = :childAcc1.Id];
        System.assertEquals(ultimateAcc.Id,childAcc1.UltimateAccount__c,'Ultimate Acc should be set on grand child account');
        update parentAcc1;
        // Execute the batch process
        Test.startTest();
        ProcessCascadingPendingAccsBatch batch = new ProcessCascadingPendingAccsBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        childAcc1 = [SELECT UltimateAccount__c FROM Account WHERE Id = :childAcc1.Id];
        System.assertEquals(null,childAcc1.UltimateAccount__c,'Ultimate Acc should be removed from grand child account');
    }
}