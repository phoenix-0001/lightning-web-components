/**
 * @description Invocable Apex action to close all open cases related to a specified Account.
 */
public with sharing class CloseAccountCasesAction {

    /**
     * @description Input parameters for closing account cases
     */
    public class Request {
        @InvocableVariable(required=true label='Account ID' description='ID of the Account whose open cases should be closed')
        public Id accountId;
    }

    /**
     * @description Output parameters returned to the Flow
     */
    public class Response {
        @InvocableVariable(label='Is Success' description='True if the case update operation succeeded')
        public Boolean isSuccess;

        @InvocableVariable(label='Message' description='User-friendly result message')
        public String message;

        @InvocableVariable(label='Closed Case Count' description='Number of cases closed')
        public Integer closedCaseCount;

        @InvocableVariable(label='Error Message' description='Error details if the operation failed')
        public String errorMessage;
    }

    /**
     * @description Invocable method to close open cases for selected Accounts
     * @param requests List of Request DTOs containing account IDs
     * @return List of Response DTOs with operation outcome and success message
     */
    @InvocableMethod(
        label='Close Related Cases for Account'
        description='Closes all open cases associated with the specified Account ID and returns a status message.'
        category='Case'
    )
    public static List<Response> closeAccountCases(List<Request> requests) {
        List<Response> responses = new List<Response>();

        if (requests == null || requests.isEmpty()) {
            return responses;
        }

        Set<Id> accountIds = new Set<Id>();
        for (Request req : requests) {
            if (req != null && req.accountId != null) {
                accountIds.add(req.accountId);
            }
        }

        if (accountIds.isEmpty()) {
            for (Request req : requests) {
                Response res = new Response();
                res.isSuccess = false;
                res.closedCaseCount = 0;
                res.message = 'No valid Account ID was provided.';
                res.errorMessage = 'Account ID is null or missing.';
                responses.add(res);
            }
            return responses;
        }

        // Query open cases for the requested accounts
        List<Case> openCases = [
            SELECT Id, AccountId, Status
            FROM Case
            WHERE AccountId IN :accountIds AND IsClosed = false
            WITH USER_MODE
        ];

        // Map open cases by AccountId
        Map<Id, List<Case>> casesByAccountId = new Map<Id, List<Case>>();
        List<Case> casesToUpdate = new List<Case>();

        for (Case c : openCases) {
            c.Status = 'Closed';
            casesToUpdate.add(c);

            if (!casesByAccountId.containsKey(c.AccountId)) {
                casesByAccountId.put(c.AccountId, new List<Case>());
            }
            casesByAccountId.get(c.AccountId).add(c);
        }

        Map<Id, String> errorMapByAccount = new Map<Id, String>();

        if (!casesToUpdate.isEmpty()) {
            try {
                Database.SaveResult[] saveResults = Database.update(casesToUpdate, false, AccessLevel.USER_MODE);
                for (Integer i = 0; i < saveResults.size(); i++) {
                    Database.SaveResult sr = saveResults[i];
                    if (!sr.isSuccess()) {
                        Case failedCase = casesToUpdate[i];
                        List<String> errMsgs = new List<String>();
                        for (Database.Error err : sr.getErrors()) {
                            errMsgs.add(err.getMessage());
                        }
                        String combinedErr = String.join(errMsgs, '; ');
                        errorMapByAccount.put(failedCase.AccountId, combinedErr);
                    }
                }
            } catch (Exception e) {
                for (Id accId : accountIds) {
                    errorMapByAccount.put(accId, e.getMessage());
                }
            }
        }

        for (Request req : requests) {
            Response res = new Response();

            if (req == null || req.accountId == null) {
                res.isSuccess = false;
                res.closedCaseCount = 0;
                res.message = 'No valid Account ID was provided.';
                res.errorMessage = 'Account ID is null or missing.';
            } else if (errorMapByAccount.containsKey(req.accountId)) {
                res.isSuccess = false;
                res.closedCaseCount = 0;
                res.errorMessage = errorMapByAccount.get(req.accountId);
                res.message = 'Failed to close cases for Account: ' + res.errorMessage;
            } else {
                List<Case> accCases = casesByAccountId.get(req.accountId);
                Integer count = (accCases != null) ? accCases.size() : 0;
                res.isSuccess = true;
                res.closedCaseCount = count;
                if (count > 0) {
                    res.message = 'Successfully closed ' + count + ' open case(s) for the selected Account.';
                } else {
                    res.message = 'No open cases were found for the selected Account.';
                }
            }

            responses.add(res);
        }

        return responses;
    }
}
