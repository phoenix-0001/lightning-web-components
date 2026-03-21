public class GenerateAccountAndAssetsForPLCCurriculum {
  @InvocableMethod(label='Generate Account and Assets' description='Generate records for Account and Asset objects required in PLC learning course.')
  public static void generateAccountAndAssets() {

    Account accountForAssets;
    // check for existing account, so we don't re-create it
    List<Account> existingAccount = [SELECT Id FROM Account WHERE Name = 'RAVG Vehicles'];
    if (existingAccount.size() > 0) {
      accountForAssets = existingAccount[0];
    } else {
      accountForAssets = new Account(Name = 'RAVG Vehicles');
      insert accountForAssets;
    }

    // check and clean up existing records if any
    List<Asset> existingVehicles = [SELECT Id from Asset];
    if (existingVehicles.size() > 0) {
      delete existingVehicles;
    }

    List<Asset> vehicles = new List<Asset>();
    Asset vehicle1 = new Asset(AccountId = accountForAssets.Id, Name = 'Suzuki Swift or similar', External_ID__c = 'V0056', Vehicle_Type__c = 'Car', Vehicle_Category__c = 'Economy', Daily_Rate__c = 147.16, Description = 'Small and nimble, perfect for your city or beach holiday.'); vehicles.add(vehicle1);
    Asset vehicle2 = new Asset(AccountId = accountForAssets.Id, Name = 'Toyota Kluger or similar', External_ID__c = 'V0057', Vehicle_Type__c = 'Family', Vehicle_Category__c = 'Fullsize;SUV;7 Seat', Daily_Rate__c = 223.67, Description = 'An enjoyable driving experience with ample space to travel with family or friends.'); vehicles.add(vehicle2);
    Asset vehicle3 = new Asset(AccountId = accountForAssets.Id, Name = 'Toyota Kluger Hybrid', External_ID__c = 'V0058', Vehicle_Type__c = 'Family', Vehicle_Category__c = 'Hybrid', Daily_Rate__c = 234.85, Description = 'An enjoyable driving experience with ample space to travel with family or friends.'); vehicles.add(vehicle3);
    Asset vehicle4 = new Asset(AccountId = accountForAssets.Id, Name = 'Kia Sportage or similar', External_ID__c = 'V0059', Vehicle_Type__c = 'SUV', Vehicle_Category__c = 'Compact;SUV', Daily_Rate__c = 164.85, Description = 'An enjoyable driving experience with ample space to travel with family or friends.'); vehicles.add(vehicle4);
    Asset vehicle5 = new Asset(AccountId = accountForAssets.Id, Name = 'Toyota C-HR Hybrid or similar', External_ID__c = 'V0060', Vehicle_Type__c = 'SUV', Vehicle_Category__c = 'Compact;SUV;Hybrid', Daily_Rate__c = 196.08, Description = 'Deceptively spacious with plenty of room to pack in more fun on the road for your trip away.'); vehicles.add(vehicle5);
    Asset vehicle6 = new Asset(AccountId = accountForAssets.Id, Name = 'Toyota Corolla Hybrid or similar', External_ID__c = 'V0062', Vehicle_Type__c = 'Car', Vehicle_Category__c = 'Hybrid', Daily_Rate__c = 123.14, Description = 'Small and nimble, perfect for your city or beach holiday.'); vehicles.add(vehicle6);
    Asset vehicle7 = new Asset(AccountId = accountForAssets.Id, Name = 'Nissan X-TRAIL or similar', External_ID__c = 'V0063', Vehicle_Type__c = 'SUV', Vehicle_Category__c = 'Intermediate;SUV;2WD', Daily_Rate__c = 188.54, Description = 'An enjoyable driving experience with ample space to travel with family or friends.'); vehicles.add(vehicle7);
    Asset vehicle8 = new Asset(AccountId = accountForAssets.Id, Name = 'Toyota RAV4 Hybrid or similar', External_ID__c = 'V0064', Vehicle_Type__c = 'SUV', Vehicle_Category__c = 'Hybrid', Daily_Rate__c = 181.34, Description = 'An enjoyable driving experience with ample space to travel with family or friends.'); vehicles.add(vehicle8);
    Asset vehicle9 = new Asset(AccountId = accountForAssets.Id, Name = 'Kia Carnival or similar', External_ID__c = 'V0066', Vehicle_Type__c = 'Family', Vehicle_Category__c = 'Fullsize;Van;8 Seat', Daily_Rate__c = 227.02, Description = 'Large and spacious, perfect for family holidays or getaways with mum, dad, kids, and maybe even grandparents.'); vehicles.add(vehicle9);
    Asset vehicle10 = new Asset(AccountId = accountForAssets.Id, Name = 'Subaru Forester or similar', External_ID__c = 'V0069', Vehicle_Type__c = 'SUV', Vehicle_Category__c = 'Intermediate;SUV;AWD', Daily_Rate__c = 173.09, Description = 'An enjoyable driving experience with ample space to travel with family or friends.'); vehicles.add(vehicle10);
    Asset vehicle11 = new Asset(AccountId = accountForAssets.Id, Name = 'VW Golf GTI', External_ID__c = 'V0070', Vehicle_Type__c = 'Prestige', Vehicle_Category__c = 'Sport;Elite', Daily_Rate__c = 255.03, Description = 'Small and nimble, perfect for your city or beach holiday.'); vehicles.add(vehicle11);
    Asset vehicle12 = new Asset(AccountId = accountForAssets.Id, Name = 'Ford Mustang', External_ID__c = 'V0071', Vehicle_Type__c = 'Prestige', Vehicle_Category__c = 'Sport;Elite', Daily_Rate__c = 279.59, Description = 'Big and powerful for when you\'re feeling a little more adventurous.'); vehicles.add(vehicle12);
    Asset vehicle13 = new Asset(AccountId = accountForAssets.Id, Name = 'Audi SQ5', External_ID__c = 'V0072', Vehicle_Type__c = 'Prestige', Vehicle_Category__c = 'Luxury;SUV', Daily_Rate__c = 298.27, Description = 'Perfect for a business trip or a road trip with enough seats and plenty of boot space.'); vehicles.add(vehicle13);
    Asset vehicle14 = new Asset(AccountId = accountForAssets.Id, Name = 'Mitsubishi Pajero Sport or similar', External_ID__c = 'V0073', Vehicle_Type__c = '4WD', Vehicle_Category__c = 'Fullsize;SUV;4WD', Daily_Rate__c = 214.85, Description = 'An enjoyable driving experience with ample space to travel with family or friends.'); vehicles.add(vehicle14);
    Asset vehicle15 = new Asset(AccountId = accountForAssets.Id, Name = 'Toyota Prado or similar', External_ID__c = 'V0074', Vehicle_Type__c = '4WD', Vehicle_Category__c = 'Premium;SUV;4WD', Daily_Rate__c = 238.72, Description = 'An enjoyable driving experience with ample space to travel with family or friends.'); vehicles.add(vehicle15);
    Asset vehicle16 = new Asset(AccountId = accountForAssets.Id, Name = 'Toyota LC 200 or similar', External_ID__c = 'V0075', Vehicle_Type__c = '4WD', Vehicle_Category__c = 'Premium;Elite;SUV;4WD', Daily_Rate__c = 257.12, Description = 'An enjoyable driving experience with ample space to travel with family or friends.'); vehicles.add(vehicle16);
    Asset vehicle17 = new Asset(AccountId = accountForAssets.Id, Name = 'Ford Ranger or similar', External_ID__c = 'V0076', Vehicle_Type__c = 'Commercial', Vehicle_Category__c = 'Premium;Ute;4WD', Daily_Rate__c = 231.77, Description = 'An Aussie classic. Ready to take on any task.'); vehicles.add(vehicle17);
    Asset vehicle18 = new Asset(AccountId = accountForAssets.Id, Name = 'Toyota HiLux 2WD', External_ID__c = 'V0077', Vehicle_Type__c = 'Commercial', Vehicle_Category__c = 'Single Cab;Ute;2WD', Daily_Rate__c = 80, Description = 'An Aussie classic. Ready to take on any task.'); vehicles.add(vehicle18);
    Asset vehicle19 = new Asset(AccountId = accountForAssets.Id, Name = 'Toyota HiLux 4WD', External_ID__c = 'V0078', Vehicle_Type__c = 'Commercial', Vehicle_Category__c = 'Double Cab;Ute;4WD', Daily_Rate__c = 135, Description = 'An Aussie classic. Ready to take on any task.'); vehicles.add(vehicle19);
    Asset vehicle20 = new Asset(AccountId = accountForAssets.Id, Name = 'Toyota HiAce Bus', External_ID__c = 'V0079', Vehicle_Type__c = 'Commercial', Vehicle_Category__c = '12 Seat;Bus', Daily_Rate__c = 167.89, Description = 'Large and spacious, perfect for family holidays or getaways with mum, dad, kids, and maybe even grandparents.'); vehicles.add(vehicle20);
    Asset vehicle21 = new Asset(AccountId = accountForAssets.Id, Name = 'Toyota HiAce Van', External_ID__c = 'V0080', Vehicle_Type__c = 'Commercial', Vehicle_Category__c = '6 Cubic Metre;Van', Daily_Rate__c = 102, Description = 'Whether you\'re moving in or moving on, nothing beats a van for space.'); vehicles.add(vehicle21);
    Asset vehicle22 = new Asset(AccountId = accountForAssets.Id, Name = 'Hino 300', External_ID__c = 'V0085', Vehicle_Type__c = 'Commercial', Vehicle_Category__c = '19-22 Cubic Metre;Van', Daily_Rate__c = 205.16, Description = 'Whether you\'re moving in or moving on, nothing beats a van for space.'); vehicles.add(vehicle22);
    Asset vehicle23 = new Asset(AccountId = accountForAssets.Id, Name = 'Mercedes Sprinter or similar', External_ID__c = 'V0088', Vehicle_Type__c = 'Commercial', Vehicle_Category__c = '9 Cubic Metre;Van', Daily_Rate__c = 137.12, Description = 'Whether you\'re moving in or moving on, nothing beats a van for space.'); vehicles.add(vehicle23);
    Asset vehicle24 = new Asset(AccountId = accountForAssets.Id, Name = 'Toyota Camry Hybrid or similar', External_ID__c = 'V0119', Vehicle_Type__c = 'Car', Vehicle_Category__c = 'Fullsize;Sedan;Hybrid', Daily_Rate__c = 166.21, Description = 'An enjoyable driving experience with ample space to travel with family or friends.'); vehicles.add(vehicle24);
    Asset vehicle25 = new Asset(AccountId = accountForAssets.Id, Name = 'Toyota Corolla Sedan Hybrid or similar', External_ID__c = 'V0122', Vehicle_Type__c = 'Car', Vehicle_Category__c = 'Standard;Sedan;Hybrid', Daily_Rate__c = 146.57, Description = 'An enjoyable Hybrid driving experience with ample space to travel with family or friends.'); vehicles.add(vehicle25);
    insert vehicles;
  }
}