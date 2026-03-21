public class GenerateCasesForPLCCurriculum {
  @InvocableMethod(label='Generate Cases' description='Generate records for Case object required in PLC learning course.')
  public static void generateCases() {

    Map<String, String> contactCollection = new Map<String, String>();
    List<Contact> allContacts = [SELECT Id, External_ID__c FROM Contact];
    for (Contact c : allContacts) {
      contactCollection.put(c.External_ID__c, c.Id);
    }

    List<Case> cases = new List<Case>();
    Case case1 = new Case(Origin = 'Phone', ContactId = contactCollection.get('c0110c52-b07e-44bf-a70e-ba8c8ffac7ca'), Reason = 'Roadside Assistance', CreatedDate = Datetime.valueOf('2023-02-18 11:32:44'), Description = 'Forgot to refil the tank yesterday and run out of petrol in the middle of the road.', IsEscalated = false, Priority = 'High', Status = 'Closed', Subject = 'Require roadside assistance - run out of fuel', Type = 'Problem', ClosedDate = Datetime.valueOf('2023-02-18 13:03:12')); cases.add(case1);
    Case case2 = new Case(Origin = 'Web', ContactId = contactCollection.get('c0072c54-5ad2-4e5b-acbb-b71c944e6f61'), Reason = 'Mileage Report Enquiry', CreatedDate = Datetime.valueOf('2023-03-12 15:44:04'), Description = 'Would it be possible to generate the mileage report for the rental that I did in January this year? I need it for the business trip report. Thank you.', IsEscalated = false, Priority = 'Low', Status = 'New', Subject = 'Need mileage report for my old rental', Type = 'Question'); cases.add(case2);
    Case case3 = new Case(Origin = 'Web', ContactId = contactCollection.get('c0080c00-e036-466f-8e34-e8c0468cd17f'), Reason = 'Billing Enquiry', CreatedDate = Datetime.valueOf('2023-03-10 09:12:31'), Description = 'Hi, it appears I was charged twice for my last rental. Can someone please look at this urgently as I need to clear my work credit card.', IsEscalated = true, Priority = 'High', Status = 'Escalated', Subject = 'Double billing for the rental', Type = 'Problem'); cases.add(case3);
    Case case4 = new Case(Origin = 'Phone', ContactId = contactCollection.get('ctravcd6-3dbf-4671-8192-df8e3e6041bf'), Reason = 'Roadside Assistance', CreatedDate = Datetime.valueOf('2022-11-11 14:33:52'), Description = 'Was driving on the highway when suddenly heard a loud noise and realized that one of the tires had gone flat. Not able to change the tire themselves and had to call for roadside assistance.', IsEscalated = false, Priority = 'Medium', Status = 'Closed', Subject = 'Assistance with flat tyre', Type = 'Problem', ClosedDate = Datetime.valueOf('2022-11-11 16:12:05')); cases.add(case4);
    Case case5 = new Case(Origin = 'Phone', ContactId = contactCollection.get('cVALLc3-5d39-44b0-aabf-f2f90cb7dd22'), Reason = 'Roadside Assistance', CreatedDate = Datetime.valueOf('2023-04-08 07:36:41'), Description = 'I am having trouble starting my car, and I suspect that the battery may be flat. I have tried jump-starting the car, but it still won\'t start. Could you provide me with some advice on what to do next? We are in the midst of the short holiday and this prevents us from completing our trip.', IsEscalated = true, Priority = 'High', Status = 'Closed', Subject = 'Flat battery', Type = 'Problem', ClosedDate = Datetime.valueOf('2023-04-08 10:15:33')); cases.add(case5);

    insert cases;
  }
}