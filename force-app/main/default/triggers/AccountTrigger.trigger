trigger AccountTrigger on Account (before update, after update) {
    if(Trigger.isAfter && Trigger.isUpdate){
        AccountTriggerHandler.handleAfterUpdateActions(Trigger.New, Trigger.oldMap);
    }
}