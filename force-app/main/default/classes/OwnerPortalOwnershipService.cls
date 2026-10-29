public with sharing class OwnerPortalOwnershipService {
    public static void verify(Id relationshipId) {
        requireReviewer();
        Contact_Vehicle_Relationship__c row = [SELECT Id, Status__c FROM Contact_Vehicle_Relationship__c
            WHERE Id = :relationshipId WITH USER_MODE];
        row.Status__c = 'Verified';
        update as user row;
    }

    public static void revoke(Id relationshipId, String reason) {
        requireReviewer();
        Contact_Vehicle_Relationship__c row = [SELECT Id, Status__c FROM Contact_Vehicle_Relationship__c
            WHERE Id = :relationshipId WITH USER_MODE];
        row.Status__c = 'Revoked';
        row.Revocation_Reason__c = reason;
        update as user row;
    }

    public static Boolean isReviewer() {
        return UserInfo.getUserType() == 'Standard' &&
            FeatureManagement.checkPermission('Manage_Northgate_Vehicle_Entitlements');
    }

    private static void requireReviewer() {
        if (!isReviewer()) throw new SecurityException('Entitlement review is unavailable for this identity.');
    }
}
