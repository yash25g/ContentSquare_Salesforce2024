public with sharing class CheckCreateLeadPermission{

    @InvocableMethod(label='Check Create Lead Permission' description='Checks if user has Create Lead permission or not.')
    public static List<Boolean> userHasCreateLeadPermission(){
        return new List<Boolean>{Schema.sObjectType.Lead.isCreateable()};
    }
}