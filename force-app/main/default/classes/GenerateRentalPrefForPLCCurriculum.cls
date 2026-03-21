public class GenerateRentalPrefForPLCCurriculum {
  @InvocableMethod(label='Generate Rental Preferences' description='Generate records for Rental_Preference__c object required in PLC learning course.')
  public static void generateRentalPreferences() {

    Map<String, String> contactCollection = new Map<String, String>();
    List<Contact> allContacts = [SELECT Id, External_ID__c FROM Contact];
    for (Contact c : allContacts) {
      contactCollection.put(c.External_ID__c, c.Id);
    }

    // check and clean up existing records if any
    List<Rental_Preference__c> preferences = [SELECT Id from Rental_Preference__c];
    if (preferences.size() > 0) {
      delete preferences;
    }
    preferences = new List<Rental_Preference__c>();

    Rental_Preference__c pref1 = new Rental_Preference__c(Leisure_Auto_Transmission__c = true, Leisure_Baby_Seat_Count__c = 1, Leisure_Booster_Seat_Count__c = 1, Customer__c = contactCollection.get('ctravcd6-3dbf-4671-8192-df8e3e6041bf')); preferences.add(pref1);
    Rental_Preference__c pref2 = new Rental_Preference__c(Business_Vehicle_Type__c = 'SUV', Business_Auto_Transmission__c = true, Customer__c = contactCollection.get('c0072c54-5ad2-4e5b-acbb-b71c944e6f61')); preferences.add(pref2);
    Rental_Preference__c pref3 = new Rental_Preference__c(Business_Vehicle_Type__c = 'Car', Business_Manual_Transmission__c = true, Customer__c = contactCollection.get('c0082c44-1841-499f-b6cb-89420032f66d')); preferences.add(pref3);
    Rental_Preference__c pref4 = new Rental_Preference__c(Leisure_Vehicle_Type__c = 'Car', Leisure_EV_Only__c = true, Customer__c = contactCollection.get('cVALLc3-5d39-44b0-aabf-f2f90cb7dd22')); preferences.add(pref4);
    Rental_Preference__c pref5 = new Rental_Preference__c(Business_Vehicle_Type__c = 'Car', Business_EV_Only__c = true, Customer__c = contactCollection.get('c0080c00-e036-466f-8e34-e8c0468cd17f')); preferences.add(pref5);
    Rental_Preference__c pref6 = new Rental_Preference__c(Leisure_Vehicle_Type__c = 'Family', Leisure_Booster_Seat_Count__c = 2, Customer__c = contactCollection.get('cstevcbb-be16-41d5-ab9f-3ad106e919d1')); preferences.add(pref6);
    Rental_Preference__c pref7 = new Rental_Preference__c(Leisure_Manual_Transmission__c = true, Customer__c = contactCollection.get('c0106c9f-3cb6-47fe-b238-b68fc7b87c41')); preferences.add(pref7);

    insert preferences;
  }
}