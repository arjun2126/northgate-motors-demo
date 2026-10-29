public without sharing class ServiceIntakeCaseService {
    private static final Set<String> CONSUMING_STATUSES = new Set<String>{
        'Requested', 'Scheduled', 'Checked_In', 'In_Progress'
    };

    public static void createForNewVisits(List<Service_Visit__c> visits) {
        List<Service_Visit__c> candidates = new List<Service_Visit__c>();
        Set<Id> contactIds = new Set<Id>();
        for (Service_Visit__c visit : visits) {
            if (visit.Case__c == null && CONSUMING_STATUSES.contains(visit.Status__c)) {
                candidates.add(visit);
                contactIds.add(visit.Contact__c);
            }
        }
        if (candidates.isEmpty()) {
            return;
        }

        Id serviceRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Service').getRecordTypeId();
        Id intakeQueueId = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Q_Service_Intake' WITH SYSTEM_MODE LIMIT 1].Id;
        Map<Id, Contact> contacts = contactIds.isEmpty() ? new Map<Id, Contact>() : new Map<Id, Contact>([
            SELECT Id, AccountId FROM Contact WHERE Id IN :contactIds WITH SYSTEM_MODE
        ]);
        List<Case> cases = new List<Case>();
        for (Service_Visit__c visit : candidates) {
            cases.add(new Case(
                RecordTypeId = serviceRecordTypeId,
                OwnerId = intakeQueueId,
                Status = 'New',
                Priority = 'Medium',
                Origin = 'Web',
                Subject = 'Service visit intake',
                ContactId = visit.Contact__c,
                AccountId = contacts.containsKey(visit.Contact__c) ? contacts.get(visit.Contact__c).AccountId : null,
                Vehicle__c = visit.Vehicle__c,
                Service_Type__c = visit.Service_Type__c
            ));
        }
        insert as system cases;

        List<Service_Visit__c> links = new List<Service_Visit__c>();
        for (Integer index = 0; index < candidates.size(); index++) {
            links.add(new Service_Visit__c(Id = candidates[index].Id, Case__c = cases[index].Id));
        }
        update as system links;
    }
}
