public class ContactEmailActivityInsights {
    
    @InvocableMethod(label='Get Contact Activity Insights for Sales Strategies')
    public static List<Response> getContactActivityInsights(List<Request> requests) {
        List<Response> responses = new List<Response>();
        try {
            System.debug('ContactEmailActivityInsights: Method started.');

            Date threeYearsAgo = System.today().addYears(-3);
            System.debug('Fetching activities from date: ' + threeYearsAgo);

            Set<Id> contactIds = new Set<Id>();
            for (Request req : requests) {
                if (req.contact != null && req.contact.Id != null) {
                    contactIds.add(req.contact.Id);
                    System.debug('Added Contact Id: ' + req.contact.Id);
                }
            }

            // ─────────────────────────────────────────────────────────
            // 1. Fetch EmailMessage IDs linked to Contacts via EmailMessageRelation
            // ─────────────────────────────────────────────────────────
            Map<Id, Set<Id>> contactToEmailIdsMap = new Map<Id, Set<Id>>();
            Set<Id> allEmailIds = new Set<Id>();

            for (EmailMessageRelation emr : [
                SELECT EmailMessageId, RelationId
                FROM EmailMessageRelation
                WHERE RelationId IN :contactIds WITH SYSTEM_MODE
            ]) {
                if (!contactToEmailIdsMap.containsKey(emr.RelationId)) {
                    contactToEmailIdsMap.put(emr.RelationId, new Set<Id>());
                }
                contactToEmailIdsMap.get(emr.RelationId).add(emr.EmailMessageId);
                allEmailIds.add(emr.EmailMessageId);
                System.debug('Found EmailMessageRelation - ContactId: ' + emr.RelationId + ' | EmailMessageId: ' + emr.EmailMessageId);
            }

            // Fetch full EmailMessage details
            Map<Id, EmailMessage> emailMessageMap = new Map<Id, EmailMessage>([
                SELECT Id, Subject, FromName, ToAddress, CreatedDate, TextBody
                FROM EmailMessage
                WHERE Id IN :allEmailIds AND CreatedDate >= :threeYearsAgo WITH SYSTEM_MODE
                ORDER BY CreatedDate DESC
            ]);

            // ─────────────────────────────────────────────────────────
            // 2. Fetch ALL Tasks linked to Contacts in a single query
            //    Then separate them in Apex by TaskSubtype:
            //      - 'Call'  → Log a Call records
            //      - 'Email' → Email-type tasks (handled by Email section)
            //      - Others  → Standard Tasks (null, 'Task', etc.)
            // ─────────────────────────────────────────────────────────
            Map<Id, List<Task>> contactTaskMap = new Map<Id, List<Task>>();
            Map<Id, List<Task>> contactCallLogMap = new Map<Id, List<Task>>();

            for (Task t : [
                SELECT Id, Subject, Status, Priority, ActivityDate, Description,
                       TaskSubtype, Type, CallType, CallDurationInSeconds,
                       WhoId, CreatedDate
                FROM Task
                WHERE WhoId IN :contactIds
                  AND CreatedDate >= :threeYearsAgo
                WITH SYSTEM_MODE
                ORDER BY CreatedDate DESC
            ]) {
                // Route to Call Logs if TaskSubtype is 'Call' OR CallType is populated
                if (t.TaskSubtype == 'Call' || t.CallType != null) {
                    if (!contactCallLogMap.containsKey(t.WhoId)) {
                        contactCallLogMap.put(t.WhoId, new List<Task>());
                    }
                    contactCallLogMap.get(t.WhoId).add(t);
                    System.debug('Fetched Call Log for ContactId: ' + t.WhoId
                        + ' | Subject: ' + t.Subject
                        + ' | TaskSubtype: ' + t.TaskSubtype
                        + ' | CallType: ' + t.CallType);
                }
                // Skip email-subtype tasks (already covered by EmailMessage query)
                else if (t.TaskSubtype == 'Email' || t.TaskSubtype == 'ListEmail') {
                    System.debug('Skipping email-type Task for ContactId: ' + t.WhoId
                        + ' | Subject: ' + t.Subject);
                }
                // Everything else is a standard Task
                else {
                    if (!contactTaskMap.containsKey(t.WhoId)) {
                        contactTaskMap.put(t.WhoId, new List<Task>());
                    }
                    contactTaskMap.get(t.WhoId).add(t);
                    System.debug('Fetched Task for ContactId: ' + t.WhoId
                        + ' | Subject: ' + t.Subject
                        + ' | TaskSubtype: ' + t.TaskSubtype);
                }
            }

            // ─────────────────────────────────────────────────────────
            // 3. Fetch Events (Meetings, Scheduled Calls) linked to Contacts
            // ─────────────────────────────────────────────────────────
            Map<Id, List<Event>> contactEventMap = new Map<Id, List<Event>>();
            for (Event e : [
                SELECT Id, Subject, StartDateTime, EndDateTime, Description,
                       Location, Type, EventSubtype, WhoId, CreatedDate,
                       DurationInMinutes
                FROM Event
                WHERE WhoId IN :contactIds
                  AND CreatedDate >= :threeYearsAgo
                WITH SYSTEM_MODE
                ORDER BY CreatedDate DESC
            ]) {
                if (!contactEventMap.containsKey(e.WhoId)) {
                    contactEventMap.put(e.WhoId, new List<Event>());
                }
                contactEventMap.get(e.WhoId).add(e);
                System.debug('Fetched Event for ContactId: ' + e.WhoId
                    + ' | Subject: ' + e.Subject
                    + ' | EventSubtype: ' + e.EventSubtype);
            }

            // ─────────────────────────────────────────────────────────
            // 4. Build response for each Contact
            // ─────────────────────────────────────────────────────────
            for (Id contactId : contactIds) {
                System.debug('Processing Contact Id: ' + contactId);

                Map<String, Object> contactWrapper = new Map<String, Object>();
                contactWrapper.put('Id', contactId);

                // --- Emails ---
                List<EmailMessage> emailsList = new List<EmailMessage>();
                if (contactToEmailIdsMap.containsKey(contactId)) {
                    for (Id emId : contactToEmailIdsMap.get(contactId)) {
                        if (emailMessageMap.containsKey(emId)) {
                            emailsList.add(emailMessageMap.get(emId));
                        }
                    }
                }
                System.debug('Number of emails found for ContactId ' + contactId + ': ' + emailsList.size());

                List<Object> emails = (List<Object>) JSON.deserializeUntyped(JSON.serialize(emailsList));
                for (Object email : emails) {
                    Map<String, Object> emailMap = (Map<String, Object>) email;
                    emailMap.remove('attributes');
                    emailMap.remove('Id');
                }
                contactWrapper.put('Emails', emails);

                // --- Tasks ---
                List<Task> tasksList = contactTaskMap.containsKey(contactId)
                    ? contactTaskMap.get(contactId)
                    : new List<Task>();
                System.debug('Number of tasks found for ContactId ' + contactId + ': ' + tasksList.size());

                List<Object> tasks = (List<Object>) JSON.deserializeUntyped(JSON.serialize(tasksList));
                for (Object taskObj : tasks) {
                    Map<String, Object> taskMap = (Map<String, Object>) taskObj;
                    taskMap.remove('attributes');
                    taskMap.remove('Id');
                    taskMap.remove('WhoId');
                }
                contactWrapper.put('Tasks', tasks);

                // --- Log a Call ---
                List<Task> callLogsList = contactCallLogMap.containsKey(contactId)
                    ? contactCallLogMap.get(contactId)
                    : new List<Task>();
                System.debug('Number of call logs found for ContactId ' + contactId + ': ' + callLogsList.size());

                List<Object> callLogs = (List<Object>) JSON.deserializeUntyped(JSON.serialize(callLogsList));
                for (Object callObj : callLogs) {
                    Map<String, Object> callMap = (Map<String, Object>) callObj;
                    callMap.remove('attributes');
                    callMap.remove('Id');
                    callMap.remove('WhoId');
                }
                contactWrapper.put('CallLogs', callLogs);

                // --- Events (Meetings / Scheduled Calls) ---
                List<Event> eventsList = contactEventMap.containsKey(contactId)
                    ? contactEventMap.get(contactId)
                    : new List<Event>();
                System.debug('Number of events found for ContactId ' + contactId + ': ' + eventsList.size());

                List<Object> events = (List<Object>) JSON.deserializeUntyped(JSON.serialize(eventsList));
                for (Object eventObj : events) {
                    Map<String, Object> eventMap = (Map<String, Object>) eventObj;
                    eventMap.remove('attributes');
                    eventMap.remove('Id');
                    eventMap.remove('WhoId');
                }
                contactWrapper.put('Events', events);

                // --- Activity Summary counts ---
                Map<String, Object> summary = new Map<String, Object>();
                summary.put('TotalEmails', emailsList.size());
                summary.put('TotalTasks', tasksList.size());
                summary.put('TotalCallLogs', callLogsList.size());
                summary.put('TotalEvents', eventsList.size());
                summary.put('TotalActivities', emailsList.size() + tasksList.size() + callLogsList.size() + eventsList.size());
                contactWrapper.put('ActivitySummary', summary);

                Response resp = new Response();
                resp.Prompt = JSON.serializePretty(contactWrapper);
                responses.add(resp);
                System.debug('Added response for ContactId ' + contactId + ': ' + resp.Prompt);
            }

            System.debug('ContactEmailActivityInsights: Method completed successfully.');

        } catch (Exception exc) {
            System.debug('Exception in ContactEmailActivityInsights: ' + exc.getMessage());
            System.debug('Stack Trace: ' + exc.getStackTraceString());
        }

        return responses;
    }
    
    public class Request {
        @InvocableVariable(label='Contact' required=true)
        public Contact contact;
    }

    public class Response {
        @InvocableVariable(label='Prompt')
        public String Prompt;
    }
}
