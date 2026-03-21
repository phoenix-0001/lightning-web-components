/**
 * @description Invocable Apex action to retrieve specific case details for Agent Workspace
 */
global with sharing class GetBasicCaseDetailsAction {
    
    /**
     * @description Input parameters for the invocable action
     */
    global class ActionRequest {
        @InvocableVariable(required=true label='Case Number' description='The Number of the case to retrieve')
        global String caseNumber;
    }
    
    /**
     * @description Output parameters for the invocable action
     */
    global class ActionResult {
        @InvocableVariable(label='Case Details')
        global String caseDetails;
    }
    
    /**
     * @description Invocable method that retrieves basic case details
     * @param requests List of ActionRequest objects
     * @return List<ActionResult> containing case details as a single string
     */
    @InvocableMethod(label='Get Basic Case Details part 2' description='Retrieves basic case details (subject, origin, description, account) as a single formatted string' category='Case')
    global static List<ActionResult> getBasicCaseDetails(List<ActionRequest> requests) {
        List<ActionResult> results = new List<ActionResult>();
        
        if (requests == null || requests.isEmpty()) {
            return results;
        }
        
        String caseNumber = requests[0].caseNumber;
        if (caseNumber == null) {
            return results;
        }
        
        // Query only the needed fields
        List<Case> cases = [
            SELECT Subject, Origin, Description, Account.Name
            FROM Case
            WHERE CaseNumber = :caseNumber
            LIMIT 1
        ];
        
        if (!cases.isEmpty()) {
            Case c = cases[0];
            ActionResult result = new ActionResult();
            
            result.caseDetails = 'Subject: ' + (c.Subject != null ? c.Subject : 'N/A') + '\n' +
                                 'Origin: ' + (c.Origin != null ? c.Origin : 'N/A') + '\n' +
                                 'Description: ' + (c.Description != null ? c.Description : 'N/A') + '\n' +
                                 'Account Name: ' + (c.Account != null ? c.Account.Name : 'N/A');
            
            results.add(result);
        }
        
        return results;
    }
}