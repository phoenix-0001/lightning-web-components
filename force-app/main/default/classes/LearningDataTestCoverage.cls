@isTest
public class LearningDataTestCoverage {

  @isTest
  static void testPerformCleanUp() {
    // Create test data
    Opportunity testOpp1 = new Opportunity(Name='Test Opp 1', CloseDate=Date.today(), StageName='Prospecting');
    insert testOpp1;
    Opportunity testOpp2 = new Opportunity(Name='Test Opp 2', CloseDate=Date.today(), StageName='Qualification');
    insert testOpp2;
    Account testAccount = new Account(name='Acme corps');
    insert testAccount;
    Contact testContact = new Contact(Firstname='Homer', LastName='Simpson', AccountId=testAccount.Id);
    insert testContact;
    Case testCase = new Case(Subject='Duff Beer Supply shortage', AccountId=testAccount.Id, ContactId=testContact.Id);
    insert testCase;
    
    // Call the method being tested
    Test.startTest();
    CleanUpInitialDataAction.performCleanUp();
    Test.stopTest();
    
    // Verify the results
    List<Opportunity> opps = [SELECT Id FROM Opportunity];
    System.assertEquals(0, opps.size(), 'Opportunities were not deleted');
    List<Case> cases = [SELECT Id FROM Case];
    System.assertEquals(0, cases.size(), 'Cases were not deleted');
    List<Account> accounts = [SELECT Id FROM Account];
    System.assertEquals(0, accounts.size(), 'Accounts were not deleted');
    List<Contact> contacts = [SELECT Id FROM Contact];
    System.assertEquals(0, contacts.size(), 'Contacts were not deleted');
  }

  @isTest
  static void testAccountAndAssets() {
    // Call the method being tested
    Test.startTest();
    GenerateAccountAndAssetsForPLCCurriculum.generateAccountAndAssets();
    Test.stopTest();
          
    // Verify the results
    List<Account> account = [SELECT Id FROM Account WHERE Name = 'RAVG Vehicles'];
    System.assertEquals(1, account.size(), 'Account was not created');
    List<Asset> vehicles = [SELECT Id FROM Asset];
    System.assertEquals(25, vehicles.size(), 'Assets were not created');
  }

  @isTest
  static void testContacts() {
    // Call the method being tested
    Test.startTest();
    GenerateContactsForPLCCurriculum.generateContacts();
    Test.stopTest();
          
    // Verify the results
    List<Contact> contacts = [SELECT Id FROM Contact];
    System.assertEquals(100, contacts.size(), 'Contacts were not created');
  }

  @isTest
  static void testPreferences() {
    // Call the method being tested
    Test.startTest();
    GenerateContactsForPLCCurriculum.generateContacts();
    GenerateRentalPrefForPLCCurriculum.generateRentalPreferences();
    Test.stopTest();
          
    // Verify the results
    List<Rental_Preference__c> preferences = [SELECT Id FROM Rental_Preference__c];
    System.assertEquals(7, preferences.size(), 'Rental Preferences were not created');
  }

  @isTest
  static void testBookings() {
    // Call the method being tested
    Test.startTest();
    GenerateAccountAndAssetsForPLCCurriculum.generateAccountAndAssets();
    GenerateContactsForPLCCurriculum.generateContacts();
    GenerateBookingssForPLCCurriculum.generateBookings();
    Test.stopTest();
          
    // Verify the results
    List<Booking__c> bookings = [SELECT Id FROM Booking__c];
    System.assertEquals(8, bookings.size(), 'Bookings were not created');
  }

  @isTest
  static void testRentals() {
    // Call the method being tested
    Test.startTest();
    GenerateAccountAndAssetsForPLCCurriculum.generateAccountAndAssets();
    GenerateContactsForPLCCurriculum.generateContacts();
    GenerateBookingssForPLCCurriculum.generateBookings();
    GenerateRentalsForPLCCurriculum.generateRentals();
    Test.stopTest();
          
    // Verify the results
    List<Rental__c> rentals = [SELECT Id FROM Rental__c];
    System.assertEquals(22, rentals.size(), 'Rentals were not created');
  }

  @isTest
  static void testCases() {
    // Call the method being tested
    Test.startTest();
    GenerateContactsForPLCCurriculum.generateContacts();
    GenerateCasesForPLCCurriculum.generateCases();
    Test.stopTest();
          
    // Verify the results
    List<Case> cases = [SELECT Id FROM Case];
    System.assertEquals(5, cases.size(), 'Cases were not created');
  }

}