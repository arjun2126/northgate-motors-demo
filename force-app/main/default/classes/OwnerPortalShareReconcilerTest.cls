@isTest
private class OwnerPortalShareReconcilerTest {
    @isTest static void clockExpiryRevocationAndMissingEvidenceFailClosed() {
        Datetime point = Datetime.newInstanceGmt(2026, 1, 1, 0, 0, 0);
        Contact_Vehicle_Relationship__c row = new Contact_Vehicle_Relationship__c(Status__c = 'Verified',
            Effective_From__c = point, Effective_To__c = point.addHours(1),
            Verified_By__c = UserInfo.getUserId(), Verified_At__c = point, Evidence_Reference__c = 'TEST-ONLY');
        System.assertEquals(true, OwnerPortalShareReconciler.active(row, point));
        System.assertEquals(false, OwnerPortalShareReconciler.active(row, point.addSeconds(-1)));
        // No record edit between these calls; the half-open clock boundary denies at the end.
        System.assertEquals(false, OwnerPortalShareReconciler.active(row, point.addHours(1)));
        row.Effective_To__c = null; row.Revoked_At__c = point.addMinutes(30);
        System.assertEquals(false, OwnerPortalShareReconciler.active(row, point.addMinutes(30)));
        row.Revoked_At__c = null; row.Verified_By__c = null;
        System.assertEquals(false, OwnerPortalShareReconciler.active(row, point));
        row.Verified_By__c = UserInfo.getUserId(); row.Evidence_Reference__c = ' ';
        System.assertEquals(false, OwnerPortalShareReconciler.active(row, point));
        row.Evidence_Reference__c = 'TEST-ONLY'; row.Status__c = 'Pending';
        System.assertEquals(false, OwnerPortalShareReconciler.active(row, point));
        OwnerPortalShareReconciler.prune(new Set<Id>(), point);
    }

    @isTest static void unapprovedInternalCannotStartMaintenanceOrScheduleWork() {
        try { OwnerPortalShareReconciler.reconcileNow(new Set<Id>()); System.assert(false); }
        catch (SecurityException expected) { System.assert(expected.getMessage().contains('unavailable')); }
        try { new OwnerPortalShareReconciler().start(null); System.assert(false); }
        catch (SecurityException expected) { System.assert(expected.getMessage().contains('unavailable')); }
        try { new OwnerPortalShareReconciler().execute((SchedulableContext) null); System.assert(false); }
        catch (SecurityException expected) { System.assert(expected.getMessage().contains('unavailable')); }
    }
}
