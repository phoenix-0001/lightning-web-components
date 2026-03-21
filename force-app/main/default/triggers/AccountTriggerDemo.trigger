trigger AccountTriggerDemo on Account(before insert){
    if(Trigger.isInsert && Trigger.isBefore){
        //AccountTriggerHandler.beforeInsert(Trigger.new);
    }
}