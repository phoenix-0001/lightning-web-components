@IsTest
private class CaseMergeControllerTest {

    @TestSetup
    static void setupData() {
        // Create a Contact and Account for test cases
        Account testAccount = new Account(Name = 'Test Merge Account');
        insert testAccount;

        Contact testContact = new Contact(
            FirstName = 'John',
            LastName = 'MergeTest',
            AccountId = testAccount.Id
        );
        insert testContact;

        // Create a test Product2 to satisfy REQUIRED_FIELD_MISSING Product__c on Case
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert testProduct;

        // Create 6 test cases to verify merging beyond the 3-record limit
        List<Case> testCases = new List<Case>();
        for (Integer i = 1; i <= 6; i++) {
            testCases.add(new Case(
                Subject = 'Merge Test Case ' + i,
                Status = 'New',
                Priority = 'Medium',
                ContactId = testContact.Id,
                AccountId = testAccount.Id,
                Description = 'Description for test case ' + i,
                Product__c = testProduct.Id
            ));
        }
        insert testCases;

        // Add CaseComments to cases 2-6 (duplicates)
        List<CaseComment> comments = new List<CaseComment>();
        for (Integer i = 1; i < testCases.size(); i++) {
            comments.add(new CaseComment(
                ParentId = testCases[i].Id,
                CommentBody = 'Comment on case ' + (i + 1)
            ));
        }
        insert comments;

        // Add Tasks to cases 2-6
        List<Task> tasks = new List<Task>();
        for (Integer i = 1; i < testCases.size(); i++) {
            tasks.add(new Task(
                Subject = 'Task for case ' + (i + 1),
                WhatId = testCases[i].Id,
                Status = 'Not Started',
                Priority = 'Normal'
            ));
        }
        insert tasks;

        // Add a child case to case 3
        insert new Case(
            Subject = 'Child Case of Case 3',
            Status = 'New',
            Priority = 'Low',
            ParentId = testCases[2].Id,
            Product__c = testProduct.Id
        );
    }

    @IsTest
    static void testSearchCases_ByCaseNumber() {
        Case testCase = [SELECT CaseNumber FROM Case WHERE Subject = 'Merge Test Case 1' LIMIT 1];

        Test.startTest();
        List<CaseMergeController.CaseSearchResult> results =
            CaseMergeController.searchCases(testCase.CaseNumber);
        Test.stopTest();

        System.assertNotEquals(0, results.size(), 'Should find at least 1 case by number');
        System.assertEquals(testCase.CaseNumber, results[0].caseNumber);
    }

    @IsTest
    static void testSearchCases_BySubject() {
        Test.startTest();
        List<CaseMergeController.CaseSearchResult> results =
            CaseMergeController.searchCases('Merge Test');
        Test.stopTest();

        System.assert(results.size() >= 6, 'Should find at least 6 test cases by subject');
    }

    @IsTest
    static void testSearchCases_ByContactName() {
        Test.startTest();
        List<CaseMergeController.CaseSearchResult> results =
            CaseMergeController.searchCases('MergeTest');
        Test.stopTest();

        System.assert(results.size() >= 6, 'Should find cases by contact last name');
    }

    @IsTest
    static void testSearchCases_EmptyTerm() {
        Test.startTest();
        List<CaseMergeController.CaseSearchResult> results =
            CaseMergeController.searchCases('');
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Empty search term should return no results');
    }

    @IsTest
    static void testSearchCases_ShortTerm() {
        Test.startTest();
        List<CaseMergeController.CaseSearchResult> results =
            CaseMergeController.searchCases('a');
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Single character search should return no results');
    }

    @IsTest
    static void testGetCaseDetails() {
        List<Case> cases = [SELECT Id FROM Case WHERE Subject LIKE 'Merge Test Case%' ORDER BY Subject];
        List<Id> caseIds = new List<Id>();
        for (Case c : cases) {
            caseIds.add(c.Id);
        }

        Test.startTest();
        List<CaseMergeController.CaseDetail> details =
            CaseMergeController.getCaseDetails(caseIds);
        Test.stopTest();

        System.assertEquals(6, details.size(), 'Should return 6 case details');

        Boolean foundCaseWithRecords = false;
        for (CaseMergeController.CaseDetail d : details) {
            if (d.commentCount > 0 || d.taskCount > 0) {
                foundCaseWithRecords = true;
            }
        }
        System.assert(foundCaseWithRecords, 'At least one case should have related records');
    }

    @IsTest
    static void testGetCaseDetails_EmptyList() {
        Test.startTest();
        List<CaseMergeController.CaseDetail> details =
            CaseMergeController.getCaseDetails(new List<Id>());
        Test.stopTest();

        System.assertEquals(0, details.size(), 'Empty ID list should return empty results');
    }

    @IsTest
    static void testMergeCases_SuccessWithFiveDuplicates() {
        // KEY test — merging 6 cases (1 master + 5 duplicates)
        List<Case> cases = [
            SELECT Id FROM Case
            WHERE Subject LIKE 'Merge Test Case%'
            ORDER BY Subject
        ];
        System.assertEquals(6, cases.size(), 'Should have 6 test cases');

        Id masterCaseId = cases[0].Id;
        List<Id> duplicateIds = new List<Id>();
        for (Integer i = 1; i < cases.size(); i++) {
            duplicateIds.add(cases[i].Id);
        }

        Test.startTest();
        CaseMergeController.MergeResult result =
            CaseMergeController.mergeCases(masterCaseId, duplicateIds);
        Test.stopTest();

        System.assert(result.success, 'Merge should succeed: ' + result.message);
        System.assertEquals(masterCaseId, result.masterCaseId);

        // Verify CaseComments were reparented to master
        Integer masterComments = [
            SELECT COUNT() FROM CaseComment WHERE ParentId = :masterCaseId
        ];
        System.assert(masterComments >= 5, 'All comments should be reparented to master case');

        // Verify Tasks were reparented to master
        Integer masterTasks = [
            SELECT COUNT() FROM Task WHERE WhatId = :masterCaseId
        ];
        System.assert(masterTasks >= 5, 'All tasks should be reparented to master case');

        // Verify child case was reparented
        Integer masterChildCases = [
            SELECT COUNT() FROM Case WHERE ParentId = :masterCaseId
        ];
        System.assert(masterChildCases >= 1, 'Child case should be reparented to master');

        // Verify duplicates are CLOSED (not deleted)
        List<Case> closedDuplicates = [
            SELECT Id, Status, Subject, Description FROM Case
            WHERE Id IN :duplicateIds
        ];
        System.assertEquals(duplicateIds.size(), closedDuplicates.size(),
            'All duplicate cases should still exist (not deleted)');

        for (Case dup : closedDuplicates) {
            System.assertEquals('Closed', dup.Status,
                'Duplicate case should have Status = Closed');
            System.assert(dup.Subject.startsWith('Merged - '),
                'Duplicate Subject should start with "Merged - ", got: ' + dup.Subject);
            System.assert(dup.Description.contains('Master Case Link:'),
                'Duplicate Description should contain a hyperlink to master case');
        }
    }

    @IsTest
    static void testMergeCases_SubjectAndDescriptionFormat() {
        // Verify the exact format of the merged case Subject and Description
        Case masterCase = [SELECT Id, CaseNumber FROM Case WHERE Subject = 'Merge Test Case 1' LIMIT 1];
        Case dupCase = [SELECT Id FROM Case WHERE Subject = 'Merge Test Case 2' LIMIT 1];

        Test.startTest();
        CaseMergeController.MergeResult result =
            CaseMergeController.mergeCases(masterCase.Id, new List<Id>{ dupCase.Id });
        Test.stopTest();

        System.assert(result.success, 'Merge should succeed');

        Case updatedDup = [SELECT Subject, Description FROM Case WHERE Id = :dupCase.Id];
        System.assertEquals('Merged - Merge Test Case 2', updatedDup.Subject,
            'Subject should be "Merged - " + original subject');
        System.assert(updatedDup.Description.contains(masterCase.CaseNumber),
            'Description should contain the master case number');
        System.assert(updatedDup.Description.contains('/lightning/r/Case/'),
            'Description should contain a Lightning record URL');
    }

    @IsTest
    static void testMergeCases_NullMasterCaseId() {
        Test.startTest();
        CaseMergeController.MergeResult result =
            CaseMergeController.mergeCases(null, new List<Id>{ '500000000000001' });
        Test.stopTest();

        System.assert(!result.success, 'Should fail with null master case ID');
        System.assert(result.message.contains('Master Case ID is required'));
    }

    @IsTest
    static void testMergeCases_EmptyDuplicateList() {
        Case masterCase = [SELECT Id FROM Case WHERE Subject = 'Merge Test Case 1' LIMIT 1];

        Test.startTest();
        CaseMergeController.MergeResult result =
            CaseMergeController.mergeCases(masterCase.Id, new List<Id>());
        Test.stopTest();

        System.assert(!result.success, 'Should fail with empty duplicate list');
        System.assert(result.message.contains('At least one duplicate'));
    }

    @IsTest
    static void testMergeCases_MasterInDuplicateList() {
        Case masterCase = [SELECT Id FROM Case WHERE Subject = 'Merge Test Case 1' LIMIT 1];
        Case dupCase = [SELECT Id FROM Case WHERE Subject = 'Merge Test Case 2' LIMIT 1];

        List<Id> duplicateIds = new List<Id>{ masterCase.Id, dupCase.Id };

        Test.startTest();
        CaseMergeController.MergeResult result =
            CaseMergeController.mergeCases(masterCase.Id, duplicateIds);
        Test.stopTest();

        System.assert(result.success, 'Should succeed after removing master from duplicate list');
    }

    @IsTest
    static void testMergeCases_SelfMerge() {
        Case masterCase = [SELECT Id FROM Case WHERE Subject = 'Merge Test Case 1' LIMIT 1];

        Test.startTest();
        CaseMergeController.MergeResult result =
            CaseMergeController.mergeCases(masterCase.Id, new List<Id>{ masterCase.Id });
        Test.stopTest();

        System.assert(!result.success, 'Should fail when merging a case with itself');
        System.assert(result.message.contains('Cannot merge a case with itself'));
    }
}
