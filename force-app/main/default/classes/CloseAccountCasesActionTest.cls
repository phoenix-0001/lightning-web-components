/**
 * @description Unit tests for CloseAccountCasesAction invocable Apex class.
 */
@IsTest
private class CloseAccountCasesActionTest {

    @TestSetup
    static void setupTestData() {
        Account testAcc1 = new Account(Name = 'Test Account Alpha');
        Account testAcc2 = new Account(Name = 'Test Account Beta');
        insert new List<Account>{ testAcc1, testAcc2 };

        List<Case> cases = new List<Case>{
            new Case(Subject = 'Open Case 1', Status = 'New', Product__c = 'GC1040', AccountId = testAcc1.Id),
            new Case(Subject = 'Open Case 2', Status = 'Working', Product__c = 'GC1040', AccountId = testAcc1.Id),
            new Case(Subject = 'Already Closed Case', Status = 'Closed', Product__c = 'GC1040', AccountId = testAcc1.Id),
            new Case(Subject = 'Beta Open Case', Status = 'New', Product__c = 'GC1040', AccountId = testAcc2.Id)
        };
        insert cases;
    }

    @IsTest
    static void testCloseAccountCasesSuccess() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account Alpha' LIMIT 1];

        CloseAccountCasesAction.Request req = new CloseAccountCasesAction.Request();
        req.accountId = acc.Id;

        Test.startTest();
        List<CloseAccountCasesAction.Response> responses = CloseAccountCasesAction.closeAccountCases(
            new List<CloseAccountCasesAction.Request>{ req }
        );
        Test.stopTest();

        Assert.areEqual(1, responses.size(), 'Should return 1 response object');
        CloseAccountCasesAction.Response res = responses[0];
        Assert.isTrue(res.isSuccess, 'Operation should succeed');
        Assert.areEqual(2, res.closedCaseCount, 'Should close 2 open cases');
        Assert.isTrue(res.message.contains('Successfully closed 2 open case(s)'), 'Message should indicate 2 cases closed');

        List<Case> openCasesLeft = [SELECT Id FROM Case WHERE AccountId = :acc.Id AND IsClosed = false];
        Assert.areEqual(0, openCasesLeft.size(), 'All open cases for testAcc1 should now be closed');
    }

    @IsTest
    static void testCloseAccountCasesNoOpenCases() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account Alpha' LIMIT 1];

        // First close all cases
        List<Case> casesToClose = [SELECT Id, Status FROM Case WHERE AccountId = :acc.Id AND IsClosed = false];
        for (Case c : casesToClose) {
            c.Status = 'Closed';
        }
        update casesToClose;

        CloseAccountCasesAction.Request req = new CloseAccountCasesAction.Request();
        req.accountId = acc.Id;

        Test.startTest();
        List<CloseAccountCasesAction.Response> responses = CloseAccountCasesAction.closeAccountCases(
            new List<CloseAccountCasesAction.Request>{ req }
        );
        Test.stopTest();

        Assert.areEqual(1, responses.size(), 'Should return 1 response object');
        CloseAccountCasesAction.Response res = responses[0];
        Assert.isTrue(res.isSuccess, 'Operation should succeed with 0 closed cases');
        Assert.areEqual(0, res.closedCaseCount, 'Closed count should be 0');
        Assert.isTrue(res.message.contains('No open cases were found'), 'Message should state no open cases found');
    }

    @IsTest
    static void testCloseAccountCasesNullOrEmptyInput() {
        Test.startTest();
        List<CloseAccountCasesAction.Response> emptyResp = CloseAccountCasesAction.closeAccountCases(
            new List<CloseAccountCasesAction.Request>()
        );
        List<CloseAccountCasesAction.Response> nullResp = CloseAccountCasesAction.closeAccountCases(null);

        CloseAccountCasesAction.Request invalidReq = new CloseAccountCasesAction.Request();
        invalidReq.accountId = null;
        List<CloseAccountCasesAction.Response> invalidResp = CloseAccountCasesAction.closeAccountCases(
            new List<CloseAccountCasesAction.Request>{ invalidReq }
        );
        Test.stopTest();

        Assert.areEqual(0, emptyResp.size(), 'Empty request list should return empty response list');
        Assert.areEqual(0, nullResp.size(), 'Null request list should return empty response list');
        Assert.areEqual(1, invalidResp.size(), 'Invalid request should return 1 error response');
        Assert.isFalse(invalidResp[0].isSuccess, 'Invalid request should not succeed');
    }
}
