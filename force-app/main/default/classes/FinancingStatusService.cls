public with sharing class FinancingStatusService {
    private static final Set<String> VALID_STATUSES = new Set<String>{
        'Draft', 'Submitted', 'Conditional', 'Approved', 'Declined', 'Funded', 'Cancelled'
    };

    private static final Map<String, Set<String>> ALLOWED_TRANSITIONS = new Map<String, Set<String>>{
        'Draft' => new Set<String>{ 'Submitted', 'Cancelled' },
        'Submitted' => new Set<String>{ 'Conditional', 'Declined', 'Cancelled' },
        'Conditional' => new Set<String>{ 'Approved', 'Declined', 'Cancelled' },
        'Approved' => new Set<String>{ 'Funded', 'Cancelled' },
        'Declined' => new Set<String>{ 'Cancelled' },
        'Funded' => new Set<String>(),
        'Cancelled' => new Set<String>()
    };

    public static void enforce(List<Financing__c> newRecords, Map<Id, Financing__c> oldMap) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }
        for (Financing__c record : newRecords) {
            applyRules(record, oldMap == null ? null : oldMap.get(record.Id));
        }
    }

    private static void applyRules(Financing__c record, Financing__c prior) {
        Boolean isInsert = prior == null;
        String proposed = record.Status__c;

        if (isInsert) {
            if (proposed == null) {
                record.Status__c = 'Draft';
                record.Previous_Status__c = null;
                return;
            }
            if (proposed == 'Funded') {
                record.addError('Funded is not a valid initial status; start at Draft.');
                return;
            }
            if (!VALID_STATUSES.contains(proposed)) {
                record.addError('Unknown Status__c value: ' + proposed);
                return;
            }
            if (proposed == 'Draft') {
                record.Previous_Status__c = null;
                return;
            }
            record.addError('Initial status must be Draft; transition from Draft via the documented lifecycle.');
            return;
        }

        if (!VALID_STATUSES.contains(prior.Status__c)) {
            record.addError('Existing Status__c is invalid: ' + prior.Status__c);
            return;
        }
        if (proposed == null) {
            record.addError('Status__c cannot be cleared.');
            return;
        }
        if (!VALID_STATUSES.contains(proposed)) {
            record.addError('Unknown Status__c value: ' + proposed);
            return;
        }
        if (proposed == prior.Status__c) {
            record.Previous_Status__c = prior.Previous_Status__c;
            return;
        }

        Set<String> allowed = ALLOWED_TRANSITIONS.get(prior.Status__c);
        if (allowed == null || !allowed.contains(proposed)) {
            record.addError(
                'Invalid financing status transition: ' + prior.Status__c +
                ' -> ' + proposed + '. Allowed next statuses: ' + renderAllowed(allowed)
            );
            return;
        }

        record.Previous_Status__c = prior.Status__c;
    }

    private static String renderAllowed(Set<String> allowed) {
        if (allowed == null || allowed.isEmpty()) {
            return '(terminal — no further transitions)';
        }
        List<String> names = new List<String>(allowed);
        names.sort();
        return String.join(names, ', ');
    }
}
