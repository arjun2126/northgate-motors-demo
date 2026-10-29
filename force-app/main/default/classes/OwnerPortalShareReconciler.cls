// Remove-only entitlement maintenance. No grants, ownership writes, self-scheduling or public endpoint.
// Async execution has NO hard clock-expiry deadline. Activation needs separate owner approval.
public without sharing class OwnerPortalShareReconciler implements Database.Batchable<SObject>, Schedulable {
    private static void requireReviewer() {
        if (!OwnerPortalOwnershipService.isReviewer()) throw new SecurityException('Entitlement maintenance is unavailable for this identity.');
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        requireReviewer();
        // Include vehicles whose last ledger row disappeared or whose stale grant has no ledger.
        return Database.getQueryLocator('SELECT Id FROM Vehicle__c WITH SYSTEM_MODE');
    }

    public void execute(Database.BatchableContext context, List<SObject> scope) {
        Set<Id> vehicles = new Set<Id>();
        for (SObject row : scope) vehicles.add((Id) row.get('Id'));
        reconcileNow(vehicles);
    }

    public void finish(Database.BatchableContext context) {
        // AsyncApexJob.NumberOfErrors must be monitored by the approved operator.
        // No silent reschedule, retries, data repair or grant creation.
    }

    public void execute(SchedulableContext context) {
        requireReviewer();
        Database.executeBatch(new OwnerPortalShareReconciler(), 50);
    }

    public static void reconcileNow(Set<Id> vehicleIds) {
        requireReviewer();
        prune(vehicleIds, Datetime.now());
    }

    @TestVisible private static Boolean active(Contact_Vehicle_Relationship__c row, Datetime instant) {
        return row.Status__c == 'Verified' && row.Verified_By__c != null && row.Verified_At__c != null &&
            !String.isBlank(row.Evidence_Reference__c) && row.Effective_From__c != null &&
            row.Effective_From__c <= instant && (row.Effective_To__c == null || instant < row.Effective_To__c) &&
            (row.Revoked_At__c == null || instant < row.Revoked_At__c);
    }

    @TestVisible private static void prune(Set<Id> vehicleIds, Datetime instant) {
        if (vehicleIds == null || vehicleIds.isEmpty()) return;
        List<Vehicle__c> locked = [SELECT Id FROM Vehicle__c WHERE Id IN :vehicleIds WITH SYSTEM_MODE FOR UPDATE];
        Map<Id, Contact_Vehicle_Relationship__c> ledger = new Map<Id, Contact_Vehicle_Relationship__c>([
            SELECT Id, Vehicle__c, Contact__c, Relationship_Type__c, Status__c, Effective_From__c,
                Effective_To__c, Revoked_At__c, Verified_By__c, Verified_At__c, Evidence_Reference__c
            FROM Contact_Vehicle_Relationship__c WHERE Vehicle__c IN :vehicleIds WITH SYSTEM_MODE]);
        Map<Id, List<Contact_Vehicle_Relationship__c>> owners = new Map<Id, List<Contact_Vehicle_Relationship__c>>();
        for (Contact_Vehicle_Relationship__c row : ledger.values()) {
            if (row.Relationship_Type__c != 'Ownership' || !active(row, instant)) continue;
            if (!owners.containsKey(row.Vehicle__c)) owners.put(row.Vehicle__c, new List<Contact_Vehicle_Relationship__c>());
            owners.get(row.Vehicle__c).add(row);
        }
        List<Vehicle__Share> vehicleGrants = [SELECT Id, ParentId, UserOrGroupId FROM Vehicle__Share
            WHERE ParentId IN :vehicleIds AND RowCause = 'Portal_Entitlement__c' WITH SYSTEM_MODE];
        Set<Id> ledgerIds = ledger.keySet();
        List<Contact_Vehicle_Relationship__Share> ledgerGrants = [SELECT Id, ParentId, UserOrGroupId
            FROM Contact_Vehicle_Relationship__Share WHERE ParentId IN :ledgerIds AND RowCause = 'Portal_Entitlement__c' WITH SYSTEM_MODE];
        Set<Id> recipients = new Set<Id>();
        for (Vehicle__Share row : vehicleGrants) recipients.add(row.UserOrGroupId);
        for (Contact_Vehicle_Relationship__Share row : ledgerGrants) recipients.add(row.UserOrGroupId);
        Map<Id, User> actors = new Map<Id, User>([SELECT Id, ContactId, IsActive, UserType, Profile.UserLicense.Name
            FROM User WHERE Id IN :recipients WITH SYSTEM_MODE]);
        List<Vehicle__Share> staleVehicles = new List<Vehicle__Share>();
        for (Vehicle__Share grant : vehicleGrants) {
            User actor = actors.get(grant.UserOrGroupId);
            if (!matchesOwner(actor, owners.get(grant.ParentId))) staleVehicles.add(grant);
        }
        List<Contact_Vehicle_Relationship__Share> staleLedger = new List<Contact_Vehicle_Relationship__Share>();
        for (Contact_Vehicle_Relationship__Share grant : ledgerGrants) {
            Contact_Vehicle_Relationship__c row = ledger.get(grant.ParentId);
            User actor = actors.get(grant.UserOrGroupId);
            if (!active(row, instant) || !matchesOwner(actor, owners.get(row.Vehicle__c)) || actor.ContactId != row.Contact__c ||
                !new Set<String>{'Ownership','Service_Authorization'}.contains(row.Relationship_Type__c)) staleLedger.add(grant);
        }
        // Normal all-or-none DML: any exception rolls back this entire batch scope.
        // Manual/Owner/other-reason grants are never removed to hide another access source.
        delete as system staleLedger;
        delete as system staleVehicles;
    }

    private static Boolean matchesOwner(User actor, List<Contact_Vehicle_Relationship__c> owners) {
        return actor != null && actor.IsActive && actor.UserType == 'PowerCustomerSuccess' &&
            actor.Profile.UserLicense.Name == 'Customer Community Plus' && actor.ContactId != null &&
            owners != null && owners.size() == 1 && owners[0].Contact__c == actor.ContactId;
    }
}
