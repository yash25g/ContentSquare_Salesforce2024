@IsTest
public class CheckCreateLeadPermissionTest{
    
    @IsTest
    static void testUserHasCreateLeadPermission(){
        Profile standardUserProfile = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'CheckCreateLeadTestUser@example.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            Alias = 'tuser',
            ProfileId = standardUserProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        
        System.runAs(testUser){
            List<Boolean> result = CheckCreateLeadPermission.userHasCreateLeadPermission();
            System.assertEquals(false, result[0], 'The user should not have create permission on Lead.');
        }
        
        User adminUser = [SELECT Id FROM User WHERE IsActive = true AND Profile.Name = 'System Administrator' LIMIT 1];
        System.runAs(adminUser){            
            List<Boolean> resultAdmin = CheckCreateLeadPermission.userHasCreateLeadPermission();
            System.assertEquals(true, resultAdmin[0], 'The admin user should have create permission on Lead');
        }
    }
}