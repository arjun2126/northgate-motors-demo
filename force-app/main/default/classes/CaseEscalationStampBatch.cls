public without sharing class CaseEscalationStampBatch implements Database.Batchable<SObject>, Schedulable {
    private final Datetime rolloutBoundary;

    public CaseEscalationStampBatch(Datetime rolloutBoundary) {
        this.rolloutBoundary = rolloutBoundary;
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator([
            SELECT Id
            FROM Case
            WHERE RecordType.DeveloperName = 'Service'
                AND Escalated_On__c = NULL
                AND CreatedDate >= :rolloutBoundary
        ]);
    }

    public void execute(Database.BatchableContext context, List<SObject> scope) {
        Set<Id> caseIds = new Map<Id, SObject>(scope).keySet();
        reconcile(caseIds, [
            SELECT CaseId, CreatedDate, Field
            FROM CaseHistory
            WHERE CaseId IN :caseIds AND Field = 'ownerEscalated'
        ]);
    }

    // The private seam accepts in-memory evidence in tests; production always queries CaseHistory.
    @TestVisible
    private void reconcile(Set<Id> caseIds, List<CaseHistory> histories) {
        Map<Id, List<Datetime>> eventTimes = new Map<Id, List<Datetime>>();
        for (CaseHistory history : histories) {
            if (!caseIds.contains(history.CaseId) || history.Field != 'ownerEscalated' || history.CreatedDate == null) {
                continue;
            }
            if (!eventTimes.containsKey(history.CaseId)) {
                eventTimes.put(history.CaseId, new List<Datetime>());
            }
            eventTimes.get(history.CaseId).add(history.CreatedDate);
        }
        Map<Id, Datetime> earliest = earliestByCase(eventTimes);
        if (earliest.isEmpty()) {
            return;
        }
        List<Case> updates = new List<Case>();
        for (Case current : [
            SELECT Id, Escalated_On__c
            FROM Case
            WHERE Id IN :earliest.keySet()
                AND RecordType.DeveloperName = 'Service'
                AND Escalated_On__c = NULL
                AND CreatedDate >= :rolloutBoundary
            FOR UPDATE
        ]) {
            updates.add(new Case(Id = current.Id, Escalated_On__c = earliest.get(current.Id)));
        }
        if (!updates.isEmpty()) {
            update updates;
        }
    }

    public void finish(Database.BatchableContext context) {
    }

    public void execute(SchedulableContext context) {
        Database.executeBatch(this, 200);
    }

    @TestVisible
    private static Map<Id, Datetime> earliestByCase(Map<Id, List<Datetime>> eventTimes) {
        Map<Id, Datetime> result = new Map<Id, Datetime>();
        for (Id caseId : eventTimes.keySet()) {
            for (Datetime eventTime : eventTimes.get(caseId)) {
                if (!result.containsKey(caseId) || eventTime < result.get(caseId)) {
                    result.put(caseId, eventTime);
                }
            }
        }
        return result;
    }
}
