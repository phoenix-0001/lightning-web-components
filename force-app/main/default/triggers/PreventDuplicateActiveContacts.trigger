// trigger to prevent creating more than one contact for the same account
trigger PreventDuplicateActiveContacts on Contact (before insert, before update) {
    // Collect all AccountIds from the contact records being inserted or updated where status is 'Active'
    Set<Id> accountIds = new Set<Id>();
    for(Contact c: Trigger.New){
        if(c.AccountId != null && c.status__c == 'Active'){
            accountIds.add(c.AccountId);
        }
    }
    // Prepare a map to store existing active contacts count for each Account
    Map<Id,Integer> activeCountMap = new Map<Id, Integer>();
    
    // Query existing active contacts related to the AccountIds collected above
    for(Contact c: [SELECT Id, AccountId FROM Contact WHERE status__c='Active' AND AccountId IN: accountIds]){
        // If an account already has an active contact store it in the map
        if(!activeCountMap.containsKey(c.AccountId)){
            activeCountMap.put(c.AccountId, 1);
        }
    }
    // Iterate again over the contact records being inserted or updated
    for(Contact c: Trigger.New){
        if(c.AccountId != null && c.status__c=='Active'){
            // Check if the current AccountId already has an active contact
            if(activeCountMap.containsKey(c.AccountId)){
                c.addError('Only one Active Contact is allowed per Account');
            }
        }
    }
    
}