public with sharing class OwnerPortalBatchBController {
    private static final String DENIED = 'This portal request is unavailable. Check access and try again.';
    private static final String OWNERSHIP = 'Verified ownership and independent service authorization determine eligibility in My vehicles.';
    public class HistoryPage {
        @AuraEnabled public List<Service_Visit__c> visits;
        @AuraEnabled public List<Case> cases;
        @AuraEnabled public Boolean hasMore;
    }
    public class CasePage {
        @AuraEnabled public List<Case> rows;
        @AuraEnabled public Boolean hasMore;
    }
    public class LoyaltyPage {
        @AuraEnabled public List<Loyalty_Member__c> members;
        @AuraEnabled public List<Loyalty_Transaction__c> transactions;
        @AuraEnabled public Boolean hasMore;
    }
    public class VehiclePage {
        @AuraEnabled public List<Vehicle__c> rows = new List<Vehicle__c>();
        @AuraEnabled public String unavailableReason = OWNERSHIP;
    }
    public class Dashboard {
        @AuraEnabled public Integer openCaseCount;
        @AuraEnabled public List<Service_Visit__c> nextAppointment;
        @AuraEnabled public List<Loyalty_Member__c> membership;
        @AuraEnabled public String caseError;
        @AuraEnabled public String appointmentError;
        @AuraEnabled public String loyaltyError;
        @AuraEnabled public String vehicleMessage = OWNERSHIP;
    }

    @AuraEnabled
    public static Dashboard getDashboard() {
        return dashboard(OwnerPortalFoundationController.getContext().contactId);
    }
    @TestVisible private static Dashboard dashboard(Id contactId) {
        requireCaller(contactId);
        Dashboard result = new Dashboard();
        try {
            result.openCaseCount = [SELECT COUNT() FROM Case WHERE ContactId = :contactId AND IsClosed = false WITH USER_MODE];
        } catch (QueryException failure) { result.caseError = DENIED; }
        try {
            Datetime nowTime = Datetime.now();
            Set<String> active = new Set<String>{'Requested', 'Scheduled', 'Checked_In', 'In_Progress'};
            result.nextAppointment = [SELECT Id, Scheduled_Start__c, Status__c, Service_Type__c
                FROM Service_Visit__c WHERE Contact__c = :contactId AND Status__c IN :active
                AND Scheduled_Start__c >= :nowTime WITH USER_MODE ORDER BY Scheduled_Start__c, Id LIMIT 1];
        } catch (QueryException failure) { result.appointmentError = DENIED; }
        try {
            result.membership = [SELECT Id, Points_Balance__c, Tier__c, Status__c FROM Loyalty_Member__c
                WHERE Contact__c = :contactId WITH USER_MODE LIMIT 2];
            if (result.membership.size() > 1) { result.membership = null; result.loyaltyError = DENIED; }
        } catch (QueryException failure) { result.loyaltyError = DENIED; }
        return result;
    }

    @AuraEnabled
    public static HistoryPage getHistory(Id beforeId) {
        return history(OwnerPortalFoundationController.getContext().contactId, beforeId);
    }
    @AuraEnabled
    public static CasePage getCases(Id beforeId) {
        return casesFor(OwnerPortalFoundationController.getContext().contactId, beforeId);
    }
    @AuraEnabled
    public static LoyaltyPage getLoyalty(Id beforeId) {
        return loyalty(OwnerPortalFoundationController.getContext().contactId, beforeId);
    }
    @AuraEnabled
    public static OwnerPortalVehicleBroker.VehiclePage getVehicles() {
        return OwnerPortalVehicleBroker.vehicles(null);
    }
    @AuraEnabled
    public static OwnerPortalVehicleBroker.VehiclePage getVehiclePage(Id beforeId) {
        return OwnerPortalVehicleBroker.vehicles(beforeId);
    }
    @AuraEnabled
    public static OwnerPortalVehicleBroker.Options getAppointmentOptions(Id vehicleId) {
        return OwnerPortalVehicleBroker.options(vehicleId);
    }
    @AuraEnabled
    public static Id bookAppointment(Id vehicleId, Id rooftopId, Datetime startsAt, String serviceType, String requestKey) {
        return OwnerPortalVehicleBroker.book(vehicleId, rooftopId, startsAt, serviceType, requestKey);
    }
    @AuraEnabled
    public static Id requestAppointment(Id vehicleId, Id rooftopId, Datetime startsAt, String serviceType) {
        OwnerPortalFoundationController.getContext();
        // Legacy no-token endpoint remains no-write; bookAppointment supplies durable idempotency.
        throw unavailable(OWNERSHIP);
    }
    @AuraEnabled
    public static Id createCase(String subject, String description) {
        OwnerPortalFoundationController.CustomerContext actor = OwnerPortalFoundationController.getContext();
        return createOwnCase(actor.contactId, subject, description);
    }
    @AuraEnabled
    public static Id addComment(Id caseId, String body) {
        return comment(OwnerPortalFoundationController.getContext().contactId, caseId, body);
    }
    @AuraEnabled
    public static List<CaseComment> getComments(Id caseId) {
        return comments(OwnerPortalFoundationController.getContext().contactId, caseId);
    }

    // Private test boundaries do not trust their Contact argument: compare to the actual caller.
    // All public endpoints additionally require the real foundation's Live Network context.
    private static void requireCaller(Id contactId) {
        if (UserInfo.getUserType() != 'PowerCustomerSuccess' ||
            !FeatureManagement.checkPermission('Access_Northgate_Owner_Portal')) throw unavailable(DENIED);
        User actor = [SELECT ContactId, IsActive FROM User WHERE Id = :UserInfo.getUserId() WITH SYSTEM_MODE];
        if (!actor.IsActive || contactId == null || actor.ContactId != contactId) throw unavailable(DENIED);
    }
    @TestVisible private static HistoryPage history(Id contactId, Id beforeId) {
        requireCaller(contactId);
        try {
            HistoryPage page = new HistoryPage();
            page.visits = beforeId == null ?
                [SELECT Id, Scheduled_Start__c, Status__c, Service_Type__c, Mileage_At_Checkin__c, Case__c
                 FROM Service_Visit__c WHERE Contact__c = :contactId WITH USER_MODE ORDER BY Id DESC LIMIT 21] :
                [SELECT Id, Scheduled_Start__c, Status__c, Service_Type__c, Mileage_At_Checkin__c, Case__c
                 FROM Service_Visit__c WHERE Contact__c = :contactId AND Id < :beforeId WITH USER_MODE ORDER BY Id DESC LIMIT 21];
            page.hasMore = page.visits.size() > 20;
            if (page.hasMore) page.visits.remove(20);
            Set<Id> linked = new Set<Id>();
            for (Service_Visit__c row : page.visits) if (row.Case__c != null) linked.add(row.Case__c);
            // A shared Vehicle or even an inconsistent linked Case must not widen Contact scope.
            page.cases = [SELECT Id, CaseNumber, Status, CreatedDate FROM Case
                WHERE Id IN :linked AND ContactId = :contactId WITH USER_MODE ORDER BY CreatedDate DESC LIMIT 20];
            Set<Id> visibleCases = new Map<Id, Case>(page.cases).keySet();
            for (Service_Visit__c row : page.visits) if (!visibleCases.contains(row.Case__c)) row.Case__c = null;
            return page;
        } catch (QueryException failure) { throw unavailable(DENIED); }
    }
    @TestVisible private static CasePage casesFor(Id contactId, Id beforeId) {
        requireCaller(contactId);
        try {
            CasePage page = new CasePage();
            page.rows = beforeId == null ?
                [SELECT Id, CaseNumber, Subject, Status, IsClosed, CreatedDate FROM Case
                 WHERE ContactId = :contactId WITH USER_MODE ORDER BY Id DESC LIMIT 21] :
                [SELECT Id, CaseNumber, Subject, Status, IsClosed, CreatedDate FROM Case
                 WHERE ContactId = :contactId AND Id < :beforeId WITH USER_MODE ORDER BY Id DESC LIMIT 21];
            page.hasMore = page.rows.size() > 20;
            if (page.hasMore) page.rows.remove(20);
            return page;
        } catch (QueryException failure) { throw unavailable(DENIED); }
    }
    @TestVisible private static LoyaltyPage loyalty(Id contactId, Id beforeId) {
        requireCaller(contactId);
        try {
            LoyaltyPage page = new LoyaltyPage();
            page.members = [SELECT Id, Points_Balance__c, Tier__c, Status__c FROM Loyalty_Member__c
                WHERE Contact__c = :contactId WITH USER_MODE LIMIT 2];
            if (page.members.size() > 1) throw unavailable(DENIED);
            Set<Id> memberIds = new Map<Id, Loyalty_Member__c>(page.members).keySet();
            page.transactions = beforeId == null ?
                [SELECT Id, Transaction_Date__c, Points__c, Type__c FROM Loyalty_Transaction__c
                 WHERE Loyalty_Member__c IN :memberIds AND Loyalty_Member__r.Contact__c = :contactId
                 WITH USER_MODE ORDER BY Id DESC LIMIT 21] :
                [SELECT Id, Transaction_Date__c, Points__c, Type__c FROM Loyalty_Transaction__c
                 WHERE Loyalty_Member__c IN :memberIds AND Loyalty_Member__r.Contact__c = :contactId AND Id < :beforeId
                 WITH USER_MODE ORDER BY Id DESC LIMIT 21];
            page.hasMore = page.transactions.size() > 20;
            if (page.hasMore) page.transactions.remove(20);
            return page;
        } catch (QueryException failure) { throw unavailable(DENIED); }
    }
    @TestVisible private static Id createOwnCase(Id contactId, String subject, String description) {
        requireCaller(contactId);
        if (String.isBlank(subject) || subject.length() > 255 || (description != null && description.length() > 4000)) throw unavailable(DENIED);
        try {
            Contact own = [SELECT Id, AccountId FROM Contact WHERE Id = :contactId WITH USER_MODE];
            // Reuse the established P6-02 service queue and Service record type, not caller routing.
            Id queueId = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Q_Service_Intake' WITH SYSTEM_MODE LIMIT 1].Id;
            Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Service').getRecordTypeId();
            Case row = new Case(ContactId = own.Id, AccountId = own.AccountId, Subject = subject.trim(),
                Description = description, Status = 'New', Origin = 'Web', Priority = 'Medium',
                OwnerId = queueId, RecordTypeId = recordTypeId);
            insert as user row;
            return row.Id;
        } catch (QueryException failure) { throw unavailable(DENIED); }
          catch (DmlException failure) { throw unavailable(DENIED); }
          catch (TypeException failure) { throw unavailable(DENIED); }
    }
    private static void requireOwnCase(Id contactId, Id caseId) {
        requireCaller(contactId);
        if (caseId == null || [SELECT Id FROM Case WHERE Id = :caseId AND ContactId = :contactId WITH USER_MODE LIMIT 1].isEmpty()) throw unavailable(DENIED);
    }
    @TestVisible private static Id comment(Id contactId, Id caseId, String body) {
        if (String.isBlank(body) || body.length() > 4000) throw unavailable(DENIED);
        try {
            requireOwnCase(contactId, caseId);
            CaseComment row = new CaseComment(ParentId = caseId, CommentBody = body.trim(), IsPublished = true);
            insert as user row;
            return row.Id;
        } catch (QueryException failure) { throw unavailable(DENIED); }
          catch (DmlException failure) { throw unavailable(DENIED); }
          catch (TypeException failure) { throw unavailable(DENIED); }
    }
    @TestVisible private static List<CaseComment> comments(Id contactId, Id caseId) {
        try {
            requireOwnCase(contactId, caseId);
            return [SELECT Id, CommentBody, CreatedDate FROM CaseComment
                WHERE ParentId = :caseId AND IsPublished = true WITH USER_MODE ORDER BY CreatedDate DESC, Id DESC LIMIT 20];
        } catch (QueryException failure) { throw unavailable(DENIED); }
    }
    private static AuraHandledException unavailable(String message) {
        AuraHandledException error = new AuraHandledException(message);
        error.setMessage(message);
        return error;
    }
}
