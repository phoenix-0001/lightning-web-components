/*The OpportunityProductInsights Apex class retrieves product details related to one or more Opportunities and formats them for Prompt template.
    
    Purpose: To fetch all OpportunityLineItem (Opp products) details for given Opportunity and return them as structured JSON.
    
    Process:
    
    1. Collects Opportunity IDs from input requests.
    
    2. Queries related OpportunityLineItem records with key fields (Product Name, Quantity, Price, etc.).
    
    3. Groups products by Opportunity and removes unnecessary fields.
    
    4. Builds a clean JSON structure with Opportunity ID and associated product details.
    
    5. Returns the JSON output as the Prompt field in the response list.
    
    6. Error Handling: Logs exceptions and stack traces to debug logs.
 * 
 * 
*/
public with sharing class OpportunityProductInsights {
    
    @InvocableMethod(label='Get Opportunity Product Details for AI Summarization')
    public static List<Response> getOpportunityProducts(List<Request> requests) {
        List<Response> responses = new List<Response>();
        try {
            System.debug('OpportunityProductInsights: Method started.');

            Set<Id> oppIds = new Set<Id>();
            for (Request req : requests) {
                if (req.opportunity != null && req.opportunity.Id != null) {
                    oppIds.add(req.opportunity.Id);
                    System.debug('Added Opportunity Id: ' + req.opportunity.Id);
                }
            }

            if (oppIds.isEmpty()) {
                System.debug('No Opportunity Ids provided.');
                return responses;
            }

            // Fetch related OpportunityLineItems
            Map<Id, List<OpportunityLineItem>> oppProductsMap = new Map<Id, List<OpportunityLineItem>>();
            for (OpportunityLineItem oli : [
                SELECT Id,
                       OpportunityId,
                       Quantity,
                       UnitPrice,
                       TotalPrice,
                       ListPrice,
                       CreatedDate,
                       PricebookEntry.Product2.Name
                FROM OpportunityLineItem
                WHERE OpportunityId IN :oppIds
                ORDER BY CreatedDate DESC
            ]) {
                if (!oppProductsMap.containsKey(oli.OpportunityId)) {
                    oppProductsMap.put(oli.OpportunityId, new List<OpportunityLineItem>());
                }
                oppProductsMap.get(oli.OpportunityId).add(oli);
                System.debug('Fetched Product for OppId: ' + oli.OpportunityId + ' | Product: ' + oli.PricebookEntry.Product2.Name);
            }

            // Build response for each Opportunity
            for (Id oppId : oppIds) {
                System.debug('Processing Opportunity Id: ' + oppId);

                Map<String, Object> oppWrapper = new Map<String, Object>();
                oppWrapper.put('Id', oppId);

                List<OpportunityLineItem> oliList = oppProductsMap.containsKey(oppId) 
                    ? oppProductsMap.get(oppId) 
                    : new List<OpportunityLineItem>();

                System.debug('Number of products found for Opportunity ' + oppId + ': ' + oliList.size());

                // Convert to JSON-safe structure
                List<Object> productList = (List<Object>) JSON.deserializeUntyped(JSON.serialize(oliList));
                for (Object product : productList) {
                    Map<String, Object> prodMap = (Map<String, Object>) product;
                    prodMap.remove('attributes');
                    prodMap.remove('Id');
                    prodMap.remove('OpportunityId');
                }

                oppWrapper.put('Products', productList);

                Response resp = new Response();
                resp.Prompt = JSON.serializePretty(oppWrapper);
                responses.add(resp);

                System.debug('Added response for Opportunity Id ' + oppId);
            }

            System.debug('OpportunityProductInsights: Completed successfully.');

        } catch (Exception exc) {
            System.debug('Exception in OpportunityProductInsights: ' + exc.getMessage());
            System.debug('Stack Trace: ' + exc.getStackTraceString());
        }

        return responses;
    }

    // Request Wrapper
    public class Request {
        @InvocableVariable(label='Opportunity' required=true)
        public Opportunity opportunity;
    }

    // Response Wrapper
    public class Response {
        @InvocableVariable(label='Prompt')
        public String Prompt;
    }
}