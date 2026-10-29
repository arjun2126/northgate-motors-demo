// Privileged ledger integrity/revocation infrastructure, not a customer data endpoint.
// No grant writer: external Vehicle Read remains blocked on native timed-revocation proof.
public without sharing class OwnerPortalOwnershipGuard {
    private static final String DENIED = 'Entitlement review is unavailable for this identity.';

    public static void validate(List<Contact_Vehicle_Relationship__c> rows,
                                Map<Id, Contact_Vehicle_Relationship__c> oldRows) {
        if (!OwnerPortalOwnershipService.isReviewer()) {
            for (Contact_Vehicle_Relationship__c row : rows) row.addError(DENIED);
            return;
        }
        Set<Id> vehicles = new Set<Id>();
        Set<Id> deliveries = new Set<Id>();
        Set<Id> changedIds = new Set<Id>();
        for (Contact_Vehicle_Relationship__c row : rows) {
            vehicles.add(row.Vehicle__c);
            if (row.Source_Delivery__c != null) deliveries.add(row.Source_Delivery__c);
            if (row.Id != null) changedIds.add(row.Id);
        }
        // Every approval/termination locks its Vehicle before reading competing intervals.
        // Lock failure rolls back; there is no speculative retry or grant on lock failure.
        List<Vehicle__c> lockedVehicles = [SELECT Id FROM Vehicle__c WHERE Id IN :vehicles WITH SYSTEM_MODE FOR UPDATE];
        // Evidence review respects the reviewer's Delivery CRUD/FLS. Synthetic evidence with
        // no source Delivery must not require unrelated Delivery field permissions.
        Map<Id, Delivery__c> evidence = deliveries.isEmpty() ? new Map<Id, Delivery__c>() :
            new Map<Id, Delivery__c>([SELECT Id, Buyer__c, Vehicle__c, Status__c
                FROM Delivery__c WHERE Id IN :deliveries WITH USER_MODE]);
        List<Contact_Vehicle_Relationship__c> existing = [SELECT Id, Contact__c, Vehicle__c,
            Relationship_Type__c, Status__c, Effective_From__c, Effective_To__c, Revoked_At__c,
            Verified_By__c, Verified_At__c FROM Contact_Vehicle_Relationship__c
            WHERE Vehicle__c IN :vehicles AND Status__c IN ('Verified', 'Revoked') AND Id NOT IN :changedIds WITH SYSTEM_MODE];

        for (Contact_Vehicle_Relationship__c row : rows) {
            Contact_Vehicle_Relationship__c prior = oldRows == null ? null : oldRows.get(row.Id);
            if (String.isBlank(row.Evidence_Reference__c) || row.Effective_From__c == null ||
                (row.Effective_To__c != null && row.Effective_To__c <= row.Effective_From__c)) {
                row.addError('Evidence and a valid half-open effective interval are required.');
            }
            if ((row.Relationship_Type__c == 'Ownership' && row.Evidence_Type__c == 'Reviewed_Service_Consent') ||
                (row.Relationship_Type__c == 'Service_Authorization' &&
                 !new Set<String>{'Reviewed_Service_Consent', 'Approved_Synthetic_Fixture'}.contains(row.Evidence_Type__c))) {
                row.addError('Ownership evidence and servicing consent are separate requirements.');
            }
            if (prior == null) {
                if (row.Status__c != 'Pending' || row.Verified_By__c != null ||
                    row.Verified_At__c != null || row.Revoked_At__c != null) {
                    row.addError('Create Pending evidence first; verification stamps are server controlled.');
                }
            } else {
                if (row.Verified_By__c != prior.Verified_By__c || row.Verified_At__c != prior.Verified_At__c ||
                    row.Revoked_At__c != prior.Revoked_At__c) row.addError('Verification and revocation stamps are server controlled.');
                if (prior.Status__c == 'Revoked' || prior.Status__c == 'Rejected') row.addError('Terminal evidence is immutable.');
                if (prior.Status__c == 'Verified') {
                    for (String field : new List<String>{'Contact__c','Vehicle__c','Relationship_Type__c',
                        'Effective_From__c','Source_Delivery__c','Evidence_Type__c','Evidence_Reference__c'}) {
                        if (row.get(field) != prior.get(field)) row.addError('Verified identity and evidence are immutable; revoke and review a new row.');
                    }
                    if (row.Status__c != 'Verified' && row.Status__c != 'Revoked') row.addError('Verified evidence can only be terminated or revoked.');
                    if (row.Effective_To__c != prior.Effective_To__c &&
                        (row.Effective_To__c == null ||
                         (prior.Effective_To__c != null && row.Effective_To__c > prior.Effective_To__c) ||
                         String.isBlank(row.Revocation_Reason__c))) row.addError('Termination can only shorten the interval with a reason.');
                } else if (row.Status__c == 'Revoked') row.addError('Only verified evidence can be revoked.');
                if (prior.Status__c == 'Pending' && row.Status__c == 'Verified') {
                    row.Verified_By__c = UserInfo.getUserId();
                    row.Verified_At__c = Datetime.now();
                }
                if (row.Status__c == 'Revoked' && prior.Status__c == 'Verified') {
                    if (String.isBlank(row.Revocation_Reason__c)) row.addError('A revocation reason is required.');
                    row.Revoked_At__c = Datetime.now();
                }
            }
            if (row.Status__c == 'Verified' && row.Source_Delivery__c != null) {
                Delivery__c source = evidence.get(row.Source_Delivery__c);
                if (source == null || source.Status__c != 'Completed' ||
                    source.Buyer__c != row.Contact__c || source.Vehicle__c != row.Vehicle__c) {
                    row.addError('Source Delivery must match the reviewed Contact and Vehicle and be Completed.');
                }
            }
        }
        List<Contact_Vehicle_Relationship__c> candidates = new List<Contact_Vehicle_Relationship__c>();
        candidates.addAll(existing); candidates.addAll(rows);
        for (Contact_Vehicle_Relationship__c row : rows) {
            if (row.hasErrors() || row.Status__c != 'Verified') continue;
            for (Contact_Vehicle_Relationship__c other : candidates) {
                if (row === other || (row.Id != null && row.Id == other.Id) || other.hasErrors() ||
                    row.Vehicle__c != other.Vehicle__c || row.Relationship_Type__c != other.Relationship_Type__c ||
                    (row.Relationship_Type__c == 'Service_Authorization' && row.Contact__c != other.Contact__c)) continue;
                if (overlaps(row, other)) {
                    row.addError('Conflicting or duplicate verified entitlement intervals are not allowed.');
                    break;
                }
            }
        }
    }

    private static Datetime endsAt(Contact_Vehicle_Relationship__c row) {
        if (row.Effective_To__c == null) return row.Revoked_At__c;
        return row.Revoked_At__c != null && row.Revoked_At__c < row.Effective_To__c ? row.Revoked_At__c : row.Effective_To__c;
    }

    @TestVisible private static Boolean overlaps(Contact_Vehicle_Relationship__c a, Contact_Vehicle_Relationship__c b) {
        if (!new Set<String>{'Verified','Revoked'}.contains(b.Status__c) ||
            b.Verified_By__c == null || b.Verified_At__c == null) return false;
        Datetime aEnd = endsAt(a), bEnd = endsAt(b);
        if ((aEnd != null && aEnd <= a.Effective_From__c) || (bEnd != null && bEnd <= b.Effective_From__c)) return false;
        return (aEnd == null || b.Effective_From__c < aEnd) && (bEnd == null || a.Effective_From__c < bEnd);
    }

    public static void revokeNativeAccess(List<Contact_Vehicle_Relationship__c> rows,
                                           Map<Id, Contact_Vehicle_Relationship__c> oldRows) {
        if (!OwnerPortalOwnershipService.isReviewer()) throw new SecurityException(DENIED);
        Map<Id, Set<Id>> lostContactsByVehicle = new Map<Id, Set<Id>>();
        Set<Id> endedRows = new Set<Id>();
        for (Contact_Vehicle_Relationship__c row : rows) {
            Contact_Vehicle_Relationship__c prior = oldRows.get(row.Id);
            if (prior.Status__c == 'Verified' && (row.Status__c == 'Revoked' ||
                (row.Effective_To__c != prior.Effective_To__c && row.Effective_To__c != null && row.Effective_To__c <= Datetime.now()))) {
                endedRows.add(row.Id);
                if (row.Relationship_Type__c == 'Ownership') {
                    if (!lostContactsByVehicle.containsKey(row.Vehicle__c)) lostContactsByVehicle.put(row.Vehicle__c, new Set<Id>());
                    lostContactsByVehicle.get(row.Vehicle__c).add(row.Contact__c);
                }
            }
        }
        if (endedRows.isEmpty()) return;
        // Application-owned grants only. Never delete Manual or unrelated customer grants.
        delete as system [SELECT Id FROM Contact_Vehicle_Relationship__Share
            WHERE ParentId IN :endedRows AND RowCause = 'Portal_Entitlement__c' WITH SYSTEM_MODE];
        if (lostContactsByVehicle.isEmpty()) return;
        Set<Id> contacts = new Set<Id>();
        for (Set<Id> ids : lostContactsByVehicle.values()) contacts.addAll(ids);
        Map<Id, Id> contactByUser = new Map<Id, Id>();
        for (User actor : [SELECT Id, ContactId FROM User WHERE ContactId IN :contacts WITH SYSTEM_MODE]) contactByUser.put(actor.Id, actor.ContactId);
        Set<Id> vehicles = lostContactsByVehicle.keySet();
        Set<Id> users = contactByUser.keySet();
        List<Vehicle__Share> revokedShares = new List<Vehicle__Share>();
        for (Vehicle__Share grant : [SELECT Id, ParentId, UserOrGroupId FROM Vehicle__Share
            WHERE ParentId IN :vehicles AND UserOrGroupId IN :users AND RowCause = 'Portal_Entitlement__c' WITH SYSTEM_MODE]) {
            if (lostContactsByVehicle.get(grant.ParentId).contains(contactByUser.get(grant.UserOrGroupId))) revokedShares.add(grant);
        }
        delete as system revokedShares;
        List<Contact_Vehicle_Relationship__c> serviceRevocations = new List<Contact_Vehicle_Relationship__c>();
        for (Contact_Vehicle_Relationship__c consent : [SELECT Id, Vehicle__c, Contact__c FROM Contact_Vehicle_Relationship__c
            WHERE Vehicle__c IN :vehicles AND Contact__c IN :contacts AND Relationship_Type__c = 'Service_Authorization' AND Status__c = 'Verified' WITH SYSTEM_MODE]) {
            if (lostContactsByVehicle.get(consent.Vehicle__c).contains(consent.Contact__c)) {
                consent.Status__c = 'Revoked'; consent.Revocation_Reason__c = 'Ownership ended; servicing authority requires new review.';
                serviceRevocations.add(consent);
            }
        }
        update as system serviceRevocations;
    }
}
