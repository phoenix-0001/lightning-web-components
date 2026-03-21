trigger PreventActiveAccountDeletion on Account (before delete) {
    //This trigger prevents deletion of Active Accounts
    if(Trigger.isBefore && Trigger.isDelete){
        // Loop though the account records being deleted
        for(Account acc : Trigger.old){
            if(acc.Active__c != null && acc.Active__c =='Yes'){
                acc.addError(Label.account_deletion_lable);
            }
        }
    }
}