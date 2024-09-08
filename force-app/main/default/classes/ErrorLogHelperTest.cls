@isTest
public class ErrorLogHelperTest {

    @isTest
    static void testCreateErrorLog() {
        // test variables
        String className = 'MyClass';
        String methodName = 'myMethod';
        String errorType = 'Exception';
        String errorMessage = 'An unexpected error occurred.';
        String errorStackTrace = 'SomeStackTraceHere';

        Test.startTest();
        ErrorLogHelper.createErrorLog(className, methodName, errorType, errorMessage, errorStackTrace);
        Test.stopTest();

        ErrorLog__c log = [SELECT ClassName__c, MethodName__c, ErrorType__c, ErrorMessage__c, StackTrace__c 
                           FROM ErrorLog__c ];
        
        System.assertNotEquals(null, log, 'ErrorLog__c record should be inserted.');
        System.assertEquals(className, log.ClassName__c, 'ClassName__c should match.');
        System.assertEquals(methodName, log.MethodName__c, 'MethodName__c should match.');
        System.assertEquals(errorType, log.ErrorType__c, 'ErrorType__c should match.');
        System.assertEquals(errorMessage, log.ErrorMessage__c, 'ErrorMessage__c should match.');
        System.assertEquals(errorStackTrace, log.StackTrace__c, 'StackTrace__c should match.');
    }
}