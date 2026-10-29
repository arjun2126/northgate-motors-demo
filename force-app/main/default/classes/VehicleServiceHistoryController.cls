public with sharing class VehicleServiceHistoryController {
    public class VisitRow {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public Datetime scheduledStart;
        @AuraEnabled public String status;
        @AuraEnabled public String serviceType;
        @AuraEnabled public Decimal mileage;
    }
    public class CaseRow {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public Datetime createdAt;
        @AuraEnabled public String status;
    }
    public class VisitPage {
        @AuraEnabled public List<VisitRow> rows = new List<VisitRow>();
        @AuraEnabled public Boolean hasMore = false;
    }
    public class CasePage {
        @AuraEnabled public List<CaseRow> rows = new List<CaseRow>();
        @AuraEnabled public Boolean hasMore = false;
    }
    private static Boolean visibleVehicle(Id vehicleId) {
        return vehicleId != null && ![SELECT Id FROM Vehicle__c WHERE Id = :vehicleId WITH USER_MODE].isEmpty();
    }
    @AuraEnabled(cacheable=true)
    public static VisitPage getVisits(Id vehicleId, Datetime beforeTime, Id beforeId) {
        VisitPage page = new VisitPage();
        if (!visibleVehicle(vehicleId)) return page;
        String query = 'SELECT Id, Name, Scheduled_Start__c, Status__c, Service_Type__c, Mileage_At_Checkin__c'
            + ' FROM Service_Visit__c WHERE Vehicle__c = :vehicleId';
        if (beforeTime != null) query += ' AND (Scheduled_Start__c < :beforeTime OR (Scheduled_Start__c = :beforeTime AND Id < :beforeId))';
        query += ' WITH USER_MODE ORDER BY Scheduled_Start__c DESC, Id DESC LIMIT 21';
        List<Service_Visit__c> visits = Database.query(query);
        page.hasMore = visits.size() > 20;
        for (Integer i = 0; i < Math.min(visits.size(), 20); i++) {
            Service_Visit__c visit = visits[i];
            VisitRow row = new VisitRow(); row.id = visit.Id; row.name = visit.Name;
            row.scheduledStart = visit.Scheduled_Start__c; row.status = visit.Status__c;
            row.serviceType = visit.Service_Type__c; row.mileage = visit.Mileage_At_Checkin__c;
            page.rows.add(row);
        }
        return page;
    }
    @AuraEnabled(cacheable=true)
    public static CasePage getCases(Id vehicleId, Datetime beforeTime, Id beforeId) {
        CasePage page = new CasePage();
        if (!visibleVehicle(vehicleId)) return page;
        Set<Id> linkedCases = new Set<Id>();
        for (Service_Visit__c visit : [SELECT Case__c FROM Service_Visit__c
            WHERE Vehicle__c = :vehicleId AND Case__c != null WITH USER_MODE]) linkedCases.add(visit.Case__c);
        String query = 'SELECT Id, CaseNumber, CreatedDate, Status FROM Case'
            + ' WHERE (Vehicle__c = :vehicleId OR Id IN :linkedCases)';
        if (beforeTime != null) query += ' AND (CreatedDate < :beforeTime OR (CreatedDate = :beforeTime AND Id < :beforeId))';
        query += ' WITH USER_MODE ORDER BY CreatedDate DESC, Id DESC LIMIT 21';
        List<Case> cases = Database.query(query);
        page.hasMore = cases.size() > 20;
        for (Integer i = 0; i < Math.min(cases.size(), 20); i++) {
            Case item = cases[i]; CaseRow row = new CaseRow(); row.id = item.Id;
            row.name = item.CaseNumber; row.createdAt = item.CreatedDate; row.status = item.Status;
            page.rows.add(row);
        }
        return page;
    }
}
