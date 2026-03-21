public with sharing class AccountTriggerHandler {
    public static void handleAfterUpdateActions(List<Account> newRecords, Map<Id, Account> oldMap) {
        Map<Id, String> accToDescriptionMap = new Map<Id, String>();
        
        // Identify Accounts whose Description has changed
        for(Account acc: newRecords){
            String oldDesc = oldMap.get(acc.Id).Description;
            if(acc.Description != oldDesc){
                accToDescriptionMap.put(acc.Id, acc.Description);
            }
        }

        // If any accounts had description changes, update related contacts
        if(!accToDescriptionMap.isEmpty()){
            List<Contact> consToUpdate = new List<Contact>();
            List<Contact> conRecords = [SELECT Id, Description, AccountId FROM Contact where AccountId IN : accToDescriptionMap.Keyset()];
            for(Contact con: conRecords){
                con.Description = accToDescriptionMap.get(con.AccountId);
                consToUpdate.add(con);
            }
            if(!consToUpdate.isEmpty()){
                update consToUpdate;
            }
        }
    }
}