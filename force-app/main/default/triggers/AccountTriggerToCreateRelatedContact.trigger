// Trigger to create a related Contact of Account with same phone as Account's phone if 
// custom checkbox field on Account is checked
trigger AccountTriggerToCreateRelatedContact on Account (after insert, after update){
	List<Contact> listConsToInsert = new List<Contact>();
	if(trigger.isAfter && (trigger.isUpdate || trigger.isInsert)){
		if(!trigger.new.isEmpty()){
			for(Account acc : trigger.new){
				if(acc.Create_Related_Contact__c){
					Contact con = new Contact();
					con.FirstName = 'Test Con FirstName';
					con.LastName = acc.Name;
					con.AccountId = acc.Id;
					con.Phone = acc.Phone;
					listConsToInsert.add(con);
				}
			}
			if(!listConsToInsert.isEmpty()){
				insert listConsToInsert;
			}	
		}
	}
}