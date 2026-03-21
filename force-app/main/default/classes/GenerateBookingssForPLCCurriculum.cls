public class GenerateBookingssForPLCCurriculum {
  @InvocableMethod(label='Generate Bookings' description='Generate records for Booking__c object required in PLC learning course.')
  public static void generateBookings() {

    Map<String, String> contactCollection = new Map<String, String>();
    List<Contact> allContacts = [SELECT Id, External_ID__c FROM Contact];
    for (Contact c : allContacts) {
      contactCollection.put(c.External_ID__c, c.Id);
    }

    Map<String, String> assetCollection = new Map<String, String>();
    List<Asset> allAssets = [SELECT Id, External_ID__c FROM Asset];
    for (Asset a : allAssets) {
      assetCollection.put(a.External_ID__c, a.Id);
    }

    // check and clean up existing records if any
    List<Booking__c> bookings = [SELECT Id from Booking__c];
    if (bookings.size() > 0) {
      delete bookings;
    }

    bookings = new List<Booking__c>();

    Booking__c refb001 = new Booking__c(External_ID__c = 'b001cf73-cefe-474b-86d9-d9d8aa701c0f', Customer__c = contactCollection.get('c0080c00-e036-466f-8e34-e8c0468cd17f'), Fleet_Vehicle__c = assetCollection.get('V0119'), Booking_Date__c = Date.valueOf('2023-04-03'), Pick_Up_Location_Code__c = 'SYDT01', Pick_Up_Location_Name__c = 'Sydney Airport', Planned_Start_Date__c = Date.valueOf('2023-04-05'), Drop_Off_Location_Code__c = 'SYDT01', Drop_Off_Location_Name__c = 'Sydney Airport', Planned_End_Date__c = Date.valueOf('2023-04-07'), Protection_Coverage__c = 'Premium', Total_Quoted_Price__c = 365.662, Is_Business__c = true); bookings.add(refb001);
    Booking__c refb002 = new Booking__c(External_ID__c = 'b002c266-9a60-49ee-8b47-5931aa7686e9', Customer__c = contactCollection.get('cVALLc3-5d39-44b0-aabf-f2f90cb7dd22'), Fleet_Vehicle__c = assetCollection.get('V0066'), Booking_Date__c = Date.valueOf('2023-04-02'), Pick_Up_Location_Code__c = 'OOLT01', Pick_Up_Location_Name__c = 'Gold Coast Airport', Planned_Start_Date__c = Date.valueOf('2023-04-07'), Drop_Off_Location_Code__c = 'OOLT01', Drop_Off_Location_Name__c = 'Gold Coast Airport', Planned_End_Date__c = Date.valueOf('2023-04-11'), Protection_Coverage__c = 'Basic', Total_Quoted_Price__c = 998.888, Is_Leisure__c = true, Baby_Seat_Count__c = 1, Booster_Seat_Count__c = 1); bookings.add(refb002);
    Booking__c refb003 = new Booking__c(External_ID__c = 'b003d4fa-7626-4323-a970-ab22a3185d68', Customer__c = contactCollection.get('c0115c3a-a115-4821-8d00-ed32508ce3a6'), Fleet_Vehicle__c = assetCollection.get('V0072'), Booking_Date__c = Date.valueOf('2023-03-07'), Pick_Up_Location_Code__c = 'MELC02', Pick_Up_Location_Name__c = 'Melbourne Downtown', Planned_Start_Date__c = Date.valueOf('2023-03-17'), Drop_Off_Location_Code__c = 'MELC02', Drop_Off_Location_Name__c = 'Melbourne Downtown', Planned_End_Date__c = Date.valueOf('2023-03-19'), Protection_Coverage__c = 'Ultimate', Total_Quoted_Price__c = 775.502, Is_Leisure__c = true); bookings.add(refb003);
    Booking__c refb004 = new Booking__c(External_ID__c = 'b004c6c8-eafe-47fa-96d4-c56d6e1d3a8f', Customer__c = contactCollection.get('c0123cc1-d1af-49a9-9f8a-608b3d0a5bd7'), Fleet_Vehicle__c = assetCollection.get('V0080'), Booking_Date__c = Date.valueOf('2023-02-08'), Pick_Up_Location_Code__c = 'LSTT01', Pick_Up_Location_Name__c = 'Launceston Airport', Planned_Start_Date__c = Date.valueOf('2023-02-09'), Drop_Off_Location_Code__c = 'LSTC04', Drop_Off_Location_Name__c = 'Launceston Downtown', Planned_End_Date__c = Date.valueOf('2023-02-10'), Protection_Coverage__c = 'Basic', Total_Quoted_Price__c = 112.2); bookings.add(refb004);
    Booking__c refb005 = new Booking__c(External_ID__c = 'b005e962-34e8-443f-9878-bb84918415b2', Customer__c = contactCollection.get('con1mc29-1b47-41c1-b714-db1661400712'), Fleet_Vehicle__c = assetCollection.get('V0069'), Booking_Date__c = Date.valueOf('2023-02-12'), Pick_Up_Location_Code__c = 'OOLT01', Pick_Up_Location_Name__c = 'Gold Coast Airport', Planned_Start_Date__c = Date.valueOf('2023-02-22'), Drop_Off_Location_Code__c = 'OOLT01', Drop_Off_Location_Name__c = 'Gold Coast Airport', Planned_End_Date__c = Date.valueOf('2023-02-24'), Protection_Coverage__c = 'Basic', Total_Quoted_Price__c = 380.798); bookings.add(refb005);
    Booking__c refb006 = new Booking__c(External_ID__c = 'b006ebf4-35df-4eda-a395-85ce884fc728', Customer__c = contactCollection.get('ces1vce9-5392-4ea1-a1a8-0ba401ed0dcf'), Fleet_Vehicle__c = assetCollection.get('V0088'), Booking_Date__c = Date.valueOf('2023-03-02'), Pick_Up_Location_Code__c = 'ADLT01', Pick_Up_Location_Name__c = 'Adelaide Airport', Planned_Start_Date__c = Date.valueOf('2023-03-15'), Drop_Off_Location_Code__c = 'ADLC02', Drop_Off_Location_Name__c = 'Adelaide Downtown', Planned_End_Date__c = Date.valueOf('2023-03-17'), Protection_Coverage__c = 'Basic', Total_Quoted_Price__c = 301.664); bookings.add(refb006);
    Booking__c refb007 = new Booking__c(External_ID__c = 'b007fcda-ef73-413d-921c-955f3a75c5b4', Customer__c = contactCollection.get('ces1vce9-5392-4ea1-a1a8-0ba401ed0dcf'), Fleet_Vehicle__c = assetCollection.get('V0088'), Booking_Date__c = Date.valueOf('2023-03-12'), Pick_Up_Location_Code__c = 'ADLT01', Pick_Up_Location_Name__c = 'Adelaide Airport', Planned_Start_Date__c = Date.valueOf('2023-03-15'), Drop_Off_Location_Code__c = 'ADLC02', Drop_Off_Location_Name__c = 'Adelaide Downtown', Planned_End_Date__c = Date.valueOf('2023-03-16'), Protection_Coverage__c = 'Basic', Total_Quoted_Price__c = 150.832); bookings.add(refb007);
    Booking__c refb008 = new Booking__c(External_ID__c = 'b008d379-80eb-4deb-ad9e-9438cb766d7e', Customer__c = contactCollection.get('ces29c76-86fe-4d02-b2a9-389954f088ff'), Fleet_Vehicle__c = assetCollection.get('V0059'), Booking_Date__c = Date.valueOf('2023-02-11'), Pick_Up_Location_Code__c = 'SYDN59', Pick_Up_Location_Name__c = 'Sydney Downtown', Planned_Start_Date__c = Date.valueOf('2023-02-13'), Drop_Off_Location_Code__c = 'SYDN59', Drop_Off_Location_Name__c = 'Sydney Downtown', Planned_End_Date__c = Date.valueOf('2023-02-15'), Protection_Coverage__c = 'Premium', Total_Quoted_Price__c = 395.64, Is_Leisure__c = true); bookings.add(refb008);

    insert bookings;
  }
}