public with sharing class CaseServiceHistoryController {
    public class VisitDto {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public Datetime scheduledStart;
        @AuraEnabled public String status;
        @AuraEnabled public String serviceType;
    }

    @AuraEnabled(cacheable=true)
    public static List<VisitDto> getHistory(Id caseId, Integer pageSize, Integer pageOffset) {
        if (caseId == null) {
            return new List<VisitDto>();
        }
        Integer size = pageSize == null ? 20 : Math.min(Math.max(pageSize, 1), 100);
        Integer offsetRows = pageOffset == null ? 0 : Math.max(pageOffset, 0);
        List<Case> cases = [
            SELECT Id, Vehicle__c, ContactId
            FROM Case
            WHERE Id = :caseId
            WITH USER_MODE
        ];
        if (cases.isEmpty() || (cases[0].Vehicle__c == null && cases[0].ContactId == null)) {
            return new List<VisitDto>();
        }
        List<Service_Visit__c> visits;
        if (cases[0].Vehicle__c != null) {
            visits = [
                SELECT Id, Name, Scheduled_Start__c, Status__c, Service_Type__c
                FROM Service_Visit__c
                WHERE Vehicle__c = :cases[0].Vehicle__c
                WITH USER_MODE
                ORDER BY Scheduled_Start__c DESC, Id DESC
                LIMIT :size OFFSET :offsetRows
            ];
        } else {
            visits = [
                SELECT Id, Name, Scheduled_Start__c, Status__c, Service_Type__c
                FROM Service_Visit__c
                WHERE Contact__c = :cases[0].ContactId
                WITH USER_MODE
                ORDER BY Scheduled_Start__c DESC, Id DESC
                LIMIT :size OFFSET :offsetRows
            ];
        }
        List<VisitDto> result = new List<VisitDto>();
        for (Service_Visit__c visit : visits) {
            VisitDto item = new VisitDto();
            item.id = visit.Id;
            item.name = visit.Name;
            item.scheduledStart = visit.Scheduled_Start__c;
            item.status = visit.Status__c;
            item.serviceType = visit.Service_Type__c;
            result.add(item);
        }
        return result;
    }
}
