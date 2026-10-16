@isTest
private class FinancingStatusServiceTest {
    private static Financing__c make(Decimal termMonths) {
        Account acc = P2TestDataFactory.makeAccount('Fin' + String.valueOf(Math.abs((termMonths == null ? 0 : termMonths).hashCode())));
        Contact applicant = P2TestDataFactory.makeContact(acc.Id, 'FinApplicant');
        Opportunity opp = new Opportunity(
            Name = 'Financing Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id
        );
        insert opp;
        return new Financing__c(
            Opportunity__c = opp.Id,
            Applicant__c = applicant.Id,
            Term_Months__c = termMonths
        );
    }

    @isTest
    static void blankStatusOnInsert_defaultsToDraft() {
        Financing__c record = make(null);
        insert record;
        record = [SELECT Id, Status__c, Previous_Status__c FROM Financing__c WHERE Id = :record.Id];
        System.assertEquals('Draft', record.Status__c, 'blank Status__c defaults to Draft');
        System.assertEquals(null, record.Previous_Status__c, 'Draft insert has no Previous_Status__c');
    }

    @isTest
    static void initialStatusDraft_stampsNullPrevious() {
        Financing__c record = make(60);
        record.Status__c = 'Draft';
        insert record;
        record = [SELECT Id, Previous_Status__c FROM Financing__c WHERE Id = :record.Id];
        System.assertEquals(null, record.Previous_Status__c, 'Draft initial has null Previous_Status__c');
    }

    @isTest
    static void initialStatusNonDraft_blockedExceptDraft() {
        for (String forbidden : new List<String>{ 'Submitted', 'Conditional', 'Approved', 'Declined', 'Funded' }) {
            Financing__c record = make(60);
            record.Status__c = forbidden;
            try {
                insert record;
                System.assert(false, 'insert with Status__c=' + forbidden + ' must block');
            } catch (DmlException e) {
                System.assert(
                    e.getDmlMessage(0).contains('Initial status must be Draft') ||
                    e.getDmlMessage(0).contains('not a valid initial status'),
                    'expected initial-status guard, got: ' + e.getDmlMessage(0)
                );
            }
        }
    }

    @isTest
    static void allValidSequences_completeLifecycle() {
        Financing__c record = make(60);
        insert record;
        record = [SELECT Status__c, Previous_Status__c FROM Financing__c WHERE Id = :record.Id];
        System.assertEquals('Draft', record.Status__c, 'starts Draft');

        record.Status__c = 'Submitted';
        update record;
        record = [SELECT Status__c, Previous_Status__c FROM Financing__c WHERE Id = :record.Id];
        System.assertEquals('Submitted', record.Status__c);
        System.assertEquals('Draft', record.Previous_Status__c);

        record.Status__c = 'Conditional';
        update record;
        record = [SELECT Status__c, Previous_Status__c FROM Financing__c WHERE Id = :record.Id];
        System.assertEquals('Conditional', record.Status__c);
        System.assertEquals('Submitted', record.Previous_Status__c);

        record.Status__c = 'Approved';
        update record;
        record = [SELECT Status__c, Previous_Status__c FROM Financing__c WHERE Id = :record.Id];
        System.assertEquals('Approved', record.Status__c);
        System.assertEquals('Conditional', record.Previous_Status__c);

        record.Status__c = 'Funded';
        update record;
        record = [SELECT Status__c, Previous_Status__c FROM Financing__c WHERE Id = :record.Id];
        System.assertEquals('Funded', record.Status__c);
        System.assertEquals('Approved', record.Previous_Status__c);
    }

    @isTest
    static void declinedFollowedByCancel_landsCancelled() {
        Financing__c record = make(60);
        insert record;
        record.Status__c = 'Submitted';
        update record;
        record.Status__c = 'Declined';
        update record;
        record = [SELECT Status__c, Previous_Status__c FROM Financing__c WHERE Id = :record.Id];
        System.assertEquals('Declined', record.Status__c);
        System.assertEquals('Submitted', record.Previous_Status__c);
        record.Status__c = 'Cancelled';
        update record;
        record = [SELECT Status__c, Previous_Status__c FROM Financing__c WHERE Id = :record.Id];
        System.assertEquals('Cancelled', record.Status__c);
        System.assertEquals('Declined', record.Previous_Status__c);
    }

    @isTest
    static void skippingIntermediateStatuses_isBlocked() {
        Financing__c record = make(60);
        insert record;
        Map<Id, Financing__c> oldMap = new Map<Id, Financing__c>{ record.Id => record.clone(true, true, true, true) };
        record.Status__c = 'Approved';
        DmlException caught;
        try {
            update record;
        } catch (DmlException e) {
            caught = e;
        }
        System.assertNotEquals(null, caught, 'Draft -> Approved must be blocked');
        System.assert(caught.getDmlMessage(0).contains('Draft -> Approved'),
            'expected Draft -> Approved in error, got: ' + caught.getDmlMessage(0));
    }

    @isTest
    static void forbiddenTransitions_coverEachCell() {
        Map<String, Set<String>> forbidden = new Map<String, Set<String>>{
            'Draft' => new Set<String>{ 'Conditional', 'Approved', 'Declined', 'Funded' },
            'Submitted' => new Set<String>{ 'Draft', 'Approved', 'Funded' },
            'Conditional' => new Set<String>{ 'Draft', 'Submitted', 'Funded' },
            'Approved' => new Set<String>{ 'Draft', 'Submitted', 'Conditional', 'Declined' },
            'Declined' => new Set<String>{ 'Draft', 'Submitted', 'Conditional', 'Approved', 'Funded' }
        };
        Map<String, List<String>> pathTo = new Map<String, List<String>>{
            'Draft' => new List<String>(),
            'Submitted' => new List<String>{ 'Submitted' },
            'Conditional' => new List<String>{ 'Submitted', 'Conditional' },
            'Approved' => new List<String>{ 'Submitted', 'Conditional', 'Approved' },
            'Declined' => new List<String>{ 'Submitted', 'Declined' }
        };
        for (String originStatus : forbidden.keySet()) {
            for (String targetStatus : forbidden.get(originStatus)) {
                Financing__c seed = make(60);
                insert seed;
                for (String hop : pathTo.get(originStatus)) {
                    seed.Status__c = hop;
                    update seed;
                }
                Financing__c transition = [SELECT Id, Status__c FROM Financing__c WHERE Id = :seed.Id];
                System.assertEquals(originStatus, transition.Status__c, 'setup path must reach ' + originStatus);
                transition.Status__c = targetStatus;
                DmlException caught;
                try {
                    update transition;
                } catch (DmlException e) {
                    caught = e;
                }
                System.assertNotEquals(null, caught, originStatus + ' -> ' + targetStatus + ' must block');
                System.assert(caught.getDmlMessage(0).contains('Invalid financing status transition'),
                    'expected lifecycle error for ' + originStatus + ' -> ' + targetStatus + ', got: ' + caught.getDmlMessage(0));
            }
        }
    }

    @isTest
    static void fundedAndCancelled_areTerminal() {
        Map<String, List<String>> fullPath = new Map<String, List<String>>{
            'Funded' => new List<String>{ 'Submitted', 'Conditional', 'Approved', 'Funded' },
            'Cancelled' => new List<String>{ 'Submitted', 'Declined', 'Cancelled' }
        };
        Map<String, String> parentStatus = new Map<String, String>{ 'Funded' => 'Approved', 'Cancelled' => 'Declined' };
        for (String terminal : fullPath.keySet()) {
            Financing__c record = make(60);
            insert record;
            for (String hop : fullPath.get(terminal)) {
                record.Status__c = hop;
                update record;
            }
            record = [SELECT Status__c, Previous_Status__c FROM Financing__c WHERE Id = :record.Id];
            System.assertEquals(terminal, record.Status__c, 'should reach ' + terminal);
            System.assertEquals(parentStatus.get(terminal), record.Previous_Status__c, 'Previous_Status__c stamp');
            record.Status__c = 'Draft';
            DmlException caught;
            try {
                update record;
            } catch (DmlException e) {
                caught = e;
            }
            System.assertNotEquals(null, caught, terminal + ' -> Draft must block');
            System.assert(caught.getDmlMessage(0).contains('Invalid financing status transition'),
                'expected terminal -> Draft to block, got: ' + caught.getDmlMessage(0));
        }
    }

    @isTest
    static void sameStatusUpdate_preservesPreviousStatus() {
        Financing__c record = make(60);
        insert record;
        record.Status__c = 'Submitted';
        update record;
        record = [SELECT Id, Status__c, Previous_Status__c FROM Financing__c WHERE Id = :record.Id];
        System.assertEquals('Draft', record.Previous_Status__c);
        Financing__c same = [SELECT Id, Status__c, Previous_Status__c, Opportunity__c, Applicant__c, Term_Months__c FROM Financing__c WHERE Id = :record.Id];
        same.Term_Months__c = 48;
        update same;
        same = [SELECT Status__c, Previous_Status__c FROM Financing__c WHERE Id = :same.Id];
        System.assertEquals('Submitted', same.Status__c, 'status preserved');
        System.assertEquals('Draft', same.Previous_Status__c, 'Previous_Status__c preserved');
    }

    @isTest
    static void sameStatusUpdate_cannotSpoofPreviousStatus() {
        Financing__c record = make(60);
        insert record;
        record.Status__c = 'Submitted';
        update record;
        Financing__c forged = [SELECT Id, Status__c, Previous_Status__c, Opportunity__c, Applicant__c, Term_Months__c FROM Financing__c WHERE Id = :record.Id];
        System.assertEquals('Draft', forged.Previous_Status__c, 'after legit transition, Previous_Status__c is Draft');
        forged.Previous_Status__c = 'Approved';
        update forged;
        forged = [SELECT Previous_Status__c FROM Financing__c WHERE Id = :forged.Id];
        System.assertEquals('Draft', forged.Previous_Status__c,
            'same-status update must restore Previous_Status__c from Trigger.oldMap, not honor caller value');
    }

    @isTest
    static void fundedInsertIsBlocked_atAnyPath() {
        Financing__c record = make(60);
        record.Status__c = 'Funded';
        DmlException caught;
        try {
            insert record;
        } catch (DmlException e) {
            caught = e;
        }
        System.assertNotEquals(null, caught, 'Funded initial must be blocked');
        System.assert(caught.getDmlMessage(0).contains('Funded is not a valid initial status'),
            'expected Funded-initial block, got: ' + caught.getDmlMessage(0));
    }

    @isTest
    static void previousStatusSpoofing_isOverwrittenOnInsert() {
        Financing__c record = make(60);
        record.Status__c = 'Draft';
        record.Previous_Status__c = 'Approved';
        insert record;
        record = [SELECT Previous_Status__c FROM Financing__c WHERE Id = :record.Id];
        System.assertEquals(null, record.Previous_Status__c, 'caller-supplied Previous_Status__c must be discarded on Draft insert');
    }

    @isTest
    static void previousStatusSpoofing_isOverwrittenOnUpdate() {
        Financing__c record = make(60);
        insert record;
        record.Status__c = 'Submitted';
        record.Previous_Status__c = 'Approved';
        update record;
        record = [SELECT Previous_Status__c FROM Financing__c WHERE Id = :record.Id];
        System.assertEquals('Draft', record.Previous_Status__c, 'service derives from Trigger.oldMap, not caller');
    }

    @isTest
    static void fundedPath_satisfiesFundedRequiresApprovedVR() {
        Financing__c record = make(60);
        insert record;
        for (String hop : new List<String>{ 'Submitted', 'Conditional', 'Approved', 'Funded' }) {
            record.Status__c = hop;
            update record;
        }
        record = [SELECT Status__c, Previous_Status__c FROM Financing__c WHERE Id = :record.Id];
        System.assertEquals('Funded', record.Status__c, 'legal path reaches Funded');
        System.assertEquals('Approved', record.Previous_Status__c,
            'service stamps Approved as predecessor, so VR_Financing_FundedRequiresApproved is satisfied, not tripped');
    }

    @isTest
    static void draftCancelWithoutTerm_worksThroughBothRules() {
        Financing__c record = make(null);
        insert record;
        record.Status__c = 'Cancelled';
        update record;
        record = [SELECT Status__c, Term_Months__c FROM Financing__c WHERE Id = :record.Id];
        System.assertEquals('Cancelled', record.Status__c, 'Draft can cancel without term');
        System.assertEquals(null, record.Term_Months__c, 'term remains blank on cancel');
    }

    @isTest
    static void nonDraftWithoutTerm_isStillBlocked() {
        Financing__c record = make(null);
        insert record;
        record.Status__c = 'Submitted';
        DmlException caught;
        try {
            update record;
        } catch (DmlException e) {
            caught = e;
        }
        System.assertNotEquals(null, caught, 'Submitted without term must fail');
        Boolean found = false;
        for (Integer i = 0; i < caught.getNumDml(); i++) {
            if (caught.getDmlMessage(i).contains('Term is required')) {
                found = true;
                break;
            }
        }
        System.assert(found, 'expected VR_Financing_TermRequired message, got: ' +
            (caught.getNumDml() > 0 ? caught.getDmlMessage(0) : 'no Dml messages'));
    }

    @isTest
    static void bulkInsert_appliesMatrixToEachRecord() {
        List<Decimal> terms = new List<Decimal>{ 36, 48, 60, 72 };
        List<Financing__c> records = new List<Financing__c>();
        for (Decimal term : terms) {
            records.add(make(term));
        }
        insert records;
        records = [SELECT Id, Status__c FROM Financing__c WHERE Id IN :records];
        for (Financing__c record : records) {
            System.assertEquals('Draft', record.Status__c, 'every bulk insert defaults to Draft');
        }
    }

    @isTest
    static void bulkUpdate_succeedsOrFailsAsAWhole() {
        Financing__c draftA = make(60);
        Financing__c draftB = make(60);
        insert new List<Financing__c>{ draftA, draftB };
        draftA.Status__c = 'Submitted';
        draftB.Status__c = 'Funded';
        DmlException caught;
        try {
            update new List<Financing__c>{ draftA, draftB };
        } catch (DmlException e) {
            caught = e;
        }
        System.assertNotEquals(null, caught, 'mixed bulk update must fail');
        System.assertEquals(1, caught.getNumDml(), 'only the invalid row errors');
        System.assert(caught.getDmlMessage(0).contains('Invalid financing status transition'),
            'error names the bad transition, got: ' + caught.getDmlMessage(0));
        draftA = [SELECT Status__c FROM Financing__c WHERE Id = :draftA.Id];
        System.assertEquals('Draft', draftA.Status__c, 'all-or-nothing rollback preserves the valid row');
    }
}
