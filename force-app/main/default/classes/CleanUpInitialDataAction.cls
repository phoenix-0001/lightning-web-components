public class CleanUpInitialDataAction {
  @InvocableMethod(label='Clean Up Initial Data' description='Deletes sample records for Opportunity, Case, Account and Contact objects.')
  public static void performCleanUp() {
    // delete all opportunity records
    List<Opportunity> opportunitiesToDelete = [SELECT Id FROM Opportunity];
    delete opportunitiesToDelete;

    // delete all case records
    List<Case> casesToDelete = [SELECT Id FROM Case];
    delete casesToDelete;

    // delete all account records
    List<Account> accountsToDelete = [SELECT Id FROM Account WHERE Name NOT IN ('Sample Account for Entitlements', 'RAVG Vehicles')];
    delete accountsToDelete;

    // delete all contact records
    List<Contact> contactsToDelete = [SELECT Id FROM Contact];
    delete contactsToDelete;
  }
}