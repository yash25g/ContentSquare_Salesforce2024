public without sharing class ErrorLogHelper {
    
    public static void createErrorLog(String className, String methodName, String errorType, String errorMessage,
                                      String errorStackTrace)
    {
        ErrorLog__c newErrorLog = new ErrorLog__c();
        newErrorLog.ClassName__c = className;
        newErrorLog.MethodName__c = methodName;        
        newErrorLog.ErrorType__c = errorType;
        newErrorLog.ErrorMessage__c = errorMessage;
        newErrorLog.StackTrace__c = errorStackTrace;
        insert newErrorLog;
    }
    
}