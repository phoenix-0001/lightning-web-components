public class LeadEmailActivityInsights {
    
    @InvocableMethod(label='Get Lead Email Chains for Sales Strategies')
    public static List<Response> getLeadEmailChains(List<Request> requests) {
        List<Response> responses = new List<Response>();
        try {
            System.debug('LeadEmailActivityInsights: Method started.');

            Date threeYearsAgo = System.today().addYears(-3);
            System.debug('Fetching emails from date: ' + threeYearsAgo);

            Set<Id> leadIds = new Set<Id>();
            for (Request req : requests) {
                if (req.lead != null && req.lead.Id != null) {
                    leadIds.add(req.lead.Id);
                    System.debug('Added Lead Id: ' + req.lead.Id);
                }
            }

            // Fetch Emails linked to Lead
            Map<Id, List<EmailMessage>> leadEmailMap = new Map<Id, List<EmailMessage>>();
            for (EmailMessage em : [
                SELECT Id, Subject, FromName, ToAddress, CreatedDate, TextBody, RelatedToId
                FROM EmailMessage
                WHERE RelatedToId IN :leadIds AND CreatedDate >= :threeYearsAgo with System_Mode 
                ORDER BY CreatedDate DESC
            ]) {
                if (!leadEmailMap.containsKey(em.RelatedToId)) {
                    leadEmailMap.put(em.RelatedToId, new List<EmailMessage>());
                }
                leadEmailMap.get(em.RelatedToId).add(em);
                System.debug('Fetched Email for LeadId: ' + em.RelatedToId + ' | Subject: ' + em.Subject);
            }

            // Build response for each Lead
            for (Id leadId : leadIds) {
                System.debug('Processing Lead Id: ' + leadId);

                Map<String, Object> leadWrapper = new Map<String, Object>();
                leadWrapper.put('Id', leadId);

                List<EmailMessage> emailsList = leadEmailMap.containsKey(leadId) ? leadEmailMap.get(leadId) : new List<EmailMessage>();
                System.debug('Number of emails found for LeadId ' + leadId + ': ' + emailsList.size());

                List<Object> emails = (List<Object>) JSON.deserializeUntyped(JSON.serialize(emailsList));
                for (Object email : emails) {
                    Map<String, Object> emailMap = (Map<String, Object>) email;
                    emailMap.remove('attributes');
                    emailMap.remove('Id');
                    emailMap.remove('RelatedToId');
                }

                leadWrapper.put('Emails', emails);

                Response resp = new Response();
                resp.Prompt = JSON.serializePretty(leadWrapper);
                responses.add(resp);
                System.debug('Added response for LeadId ' + leadId + ': ' + resp.Prompt);
            }

            System.debug('LeadEmailActivityInsights: Method completed successfully.');

        } catch (Exception exc) {
            System.debug('Exception in LeadEmailActivityInsights: ' + exc.getMessage());
            System.debug('Stack Trace: ' + exc.getStackTraceString());
        }

        return responses;
    }
    
    public class Request {
        @InvocableVariable(label='Lead' required=true)
        public Lead lead;
    }

    public class Response {
        @InvocableVariable(label='Prompt')
        public String Prompt;
    }
}