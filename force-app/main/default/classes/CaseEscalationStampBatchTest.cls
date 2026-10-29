@isTest
private class CaseEscalationStampBatchTest {
    private static Case caseRow(String subject) {
        Case row = new Case(Subject = subject, Status = 'New', Priority = 'High', Origin = 'Web');
        insert row;
        return row;
    }

    @isTest
    static void choosesEarliestSyntheticEventAndCollapsesDuplicates() {
        Case first = caseRow('Batch first');
        Case second = caseRow('Batch second');
        Datetime earliest = Datetime.now().addHours(-2);
        Map<Id, Datetime> result = CaseEscalationStampBatch.earliestByCase(new Map<Id, List<Datetime>>{
            first.Id => new List<Datetime>{Datetime.now(), earliest, earliest},
            second.Id => new List<Datetime>{Datetime.now().addHours(-1)}
        });
        System.assertEquals(earliest, result.get(first.Id));
        System.assertEquals(2, result.size());
    }

    @isTest
    static void missingHistoryAndExistingTimestampAreNoOps() {
        Case blank = caseRow('Batch blank');
        Case stamped = caseRow('Batch stamped');
        Datetime expected = Datetime.now().addHours(-1);
        stamped.Escalated_On__c = expected;
        update stamped;

        new CaseEscalationStampBatch(Datetime.now().addDays(-1)).execute(null, new List<SObject>{blank, stamped});
        Map<Id, Case> afterRun = new Map<Id, Case>([
            SELECT Escalated_On__c FROM Case WHERE Id IN :new Set<Id>{blank.Id, stamped.Id}
        ]);
        System.assertEquals(null, afterRun.get(blank.Id).Escalated_On__c);
        System.assertEquals(expected, afterRun.get(stamped.Id).Escalated_On__c);
    }

    @isTest
    static void processesWorkingAndClosedCasesWithoutInventingEvidence() {
        List<Case> cases = new List<Case>();
        for (Integer index = 0; index < 200; index++) {
            cases.add(new Case(Subject = 'Batch case ' + index,
                Status = 'New', Priority = 'High', Origin = 'Web'));
        }
        insert cases;
        cases[0].Status = 'Working';
        cases[1].Status = 'Closed';
        update new List<Case>{cases[0], cases[1]};

        List<SObject> scope = new List<SObject>();
        scope.addAll(cases);
        new CaseEscalationStampBatch(Datetime.now().addDays(-1)).execute(null, scope);
        Set<Id> caseIds = new Map<Id, Case>(cases).keySet();
        System.assertEquals(0, [SELECT COUNT() FROM Case WHERE Id IN :caseIds AND Escalated_On__c != NULL]);
    }

    private static Id serviceRecordTypeId() {
        return Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Service').getRecordTypeId();
    }

    // Read-only history fields are deserialized in memory only. No synthetic history is inserted.
    private static CaseHistory event(Id caseId, Datetime occurred, String field) {
        return (CaseHistory) JSON.deserialize(JSON.serialize(new Map<String, Object>{
            'CaseId' => caseId, 'CreatedDate' => occurred, 'Field' => field
        }), CaseHistory.class);
    }

    @isTest
    static void stampsEarliestEvidenceAfterStatusChangesAndNeverOverwrites() {
        Datetime boundary = Datetime.now().addDays(-2);
        Datetime earliest = Datetime.now().addHours(-1);
        List<Case> cases = new List<Case>{
            new Case(RecordTypeId = serviceRecordTypeId(), Subject = 'Working evidence', Status = 'Working', Priority = 'Low', Origin = 'Web'),
            new Case(RecordTypeId = serviceRecordTypeId(), Subject = 'Closed evidence', Status = 'Closed', Priority = 'Medium', Origin = 'Web')
        };
        insert as system cases;
        Set<Id> ids = new Map<Id, Case>(cases).keySet();
        CaseEscalationStampBatch job = new CaseEscalationStampBatch(boundary);
        job.reconcile(ids, new List<CaseHistory>{
            event(cases[0].Id, earliest.addMinutes(5), 'ownerEscalated'),
            event(cases[0].Id, earliest, 'ownerEscalated'),
            event(cases[0].Id, earliest, 'ownerEscalated'),
            event(cases[1].Id, earliest, 'ownerEscalated')
        });
        for (Case row : [SELECT Escalated_On__c, Status, Priority, IsEscalated, OwnerId FROM Case WHERE Id IN :ids]) {
            System.assertEquals(earliest, row.Escalated_On__c);
            System.assertEquals(false, row.IsEscalated, 'Reconciliation does not escalate Cases.');
            System.assertEquals(UserInfo.getUserId(), row.OwnerId, 'Reconciliation does not reassign Cases.');
        }
        Map<Id, Case> stored = new Map<Id, Case>([SELECT Status, Priority FROM Case WHERE Id IN :ids]);
        System.assertEquals('Working', stored.get(cases[0].Id).Status);
        System.assertEquals('Low', stored.get(cases[0].Id).Priority);
        System.assertEquals('Closed', stored.get(cases[1].Id).Status);
        Integer writesBefore = Limits.getDmlStatements();
        job.reconcile(ids, new List<CaseHistory>{event(cases[0].Id, earliest.addMinutes(-5), 'ownerEscalated')});
        System.assertEquals(writesBefore, Limits.getDmlStatements(), 'Repeated reconciliation performs no DML.');
        System.assertEquals(earliest, [SELECT Escalated_On__c FROM Case WHERE Id = :cases[0].Id].Escalated_On__c);
    }

    @isTest
    static void filtersRecordTypeRolloutEvidenceTypeAndScope() {
        Datetime boundary = Datetime.now().addDays(-1);
        List<Case> cases = new List<Case>();
        for (Integer index = 0; index < 5; index++) {
            cases.add(new Case(RecordTypeId = serviceRecordTypeId(), Subject = 'Scope ' + index, Status = 'New', Origin = 'Web'));
        }
        cases[0].RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Complaint').getRecordTypeId();
        insert as system cases;
        Test.setCreatedDate(cases[1].Id, boundary.addDays(-1));
        Set<Id> scopeIds = new Set<Id>{cases[0].Id, cases[1].Id, cases[2].Id, cases[3].Id};
        new CaseEscalationStampBatch(boundary).reconcile(scopeIds, new List<CaseHistory>{
            event(cases[0].Id, Datetime.now(), 'ownerEscalated'),
            event(cases[1].Id, Datetime.now(), 'ownerEscalated'),
            event(cases[2].Id, Datetime.now(), 'Owner'),
            event(cases[4].Id, Datetime.now(), 'ownerEscalated')
        });
        Set<Id> ids = new Map<Id, Case>(cases).keySet();
        System.assertEquals(0, [SELECT COUNT() FROM Case WHERE Id IN :ids AND Escalated_On__c != null]);

        Set<Id> selected = new Set<Id>();
        Database.QueryLocatorIterator iterator = new CaseEscalationStampBatch(boundary).start(null).iterator();
        while (iterator.hasNext()) {
            selected.add(((Case) iterator.next()).Id);
        }
        System.assertEquals(new Set<Id>{cases[2].Id, cases[3].Id, cases[4].Id}, selected);
    }

    @isTest
    static void stampsTwoHundredCasesInOneWriteAndHandlesEmptyScope() {
        List<Case> cases = new List<Case>();
        for (Integer index = 0; index < 200; index++) {
            cases.add(new Case(RecordTypeId = serviceRecordTypeId(), Subject = 'Bulk evidence ' + index, Status = 'New', Origin = 'Web'));
        }
        insert as system cases;
        Datetime occurred = Datetime.now();
        Set<Id> ids = new Map<Id, Case>(cases).keySet();
        List<CaseHistory> histories = new List<CaseHistory>();
        for (Case row : cases) {
            histories.add(event(row.Id, occurred, 'ownerEscalated'));
        }
        CaseEscalationStampBatch job = new CaseEscalationStampBatch(occurred.addDays(-1));
        Integer writesBefore = Limits.getDmlStatements();
        job.reconcile(ids, histories);
        System.assertEquals(writesBefore + 1, Limits.getDmlStatements());
        System.assertEquals(200, [SELECT COUNT() FROM Case WHERE Id IN :ids AND Escalated_On__c = :occurred]);
        writesBefore = Limits.getDmlStatements();
        job.execute(null, new List<SObject>());
        System.assertEquals(writesBefore, Limits.getDmlStatements());
    }

    @isTest
    static void schedulerDelegateRunsBatchWithoutCreatingSchedule() {
        Case eligible = new Case(RecordTypeId = serviceRecordTypeId(), Subject = 'Scheduler evidence absent', Status = 'New', Origin = 'Web');
        insert as system eligible;
        Integer schedulesBefore = [SELECT COUNT() FROM CronTrigger];
        Test.startTest();
        new CaseEscalationStampBatch(Datetime.now().addDays(-1)).execute((SchedulableContext) null);
        Test.stopTest();
        AsyncApexJob job = [SELECT Status, NumberOfErrors FROM AsyncApexJob
            WHERE ApexClass.Name = 'CaseEscalationStampBatch' AND JobType = 'BatchApex' LIMIT 1];
        System.assertEquals('Completed', job.Status);
        System.assertEquals(0, job.NumberOfErrors);
        System.assertEquals(schedulesBefore, [SELECT COUNT() FROM CronTrigger]);
        System.assertEquals(null, [SELECT Escalated_On__c FROM Case WHERE Id = :eligible.Id].Escalated_On__c);
    }
}
