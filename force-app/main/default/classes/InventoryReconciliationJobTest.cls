@isTest
private class InventoryReconciliationJobTest {
    @TestSetup static void actors() {
        Id bypassId = [SELECT Id FROM PermissionSet WHERE Name = 'PS_Bypass_Load'].Id;
        if ([SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSetId = :bypassId] == 0) {
            insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = bypassId);
        }
        P7Batch1TestData.actor('P7 maintenance denied', false, false, true);
    }

    private static void bypass(Boolean enabled) {
        Automation_Settings__c settings = Automation_Settings__c.getOrgDefaults();
        settings.SetupOwnerId = UserInfo.getOrganizationId();
        settings.Bypass_Triggers__c = enabled;
        upsert settings;
    }

    @isTest static void stopTestReconcilesScopedMovesDeletesUndeletesAndIsIdempotent() {
        List<Vehicle__c> rows = P7Batch1TestData.vehicles(200);
        Id original = rows[0].Rooftop__c;
        Rooftop__c destination = new Rooftop__c(Name = 'P7 reconcile destination', Vehicles_On_Hand__c = 99);
        Rooftop__c unrelated = new Rooftop__c(Name = 'P7 untouched', Vehicles_On_Hand__c = 41);
        insert new List<Rooftop__c>{destination, unrelated};
        bypass(true);
        List<Vehicle__c> moved = new List<Vehicle__c>();
        List<Vehicle__c> removed = new List<Vehicle__c>();
        List<Vehicle__c> restored = new List<Vehicle__c>();
        for (Integer i = 0; i < 200; i++) {
            if (i < 50) { rows[i].Rooftop__c = destination.Id; moved.add(rows[i]); }
            else if (i < 100) removed.add(rows[i]);
            else if (i < 125) restored.add(rows[i]);
        }
        moved[0].Acquisition_Date__c = Date.today().addDays(-75);
        moved[0].Status__c = 'Sold';
        update moved; delete removed; delete restored; undelete restored;
        bypass(false);
        Set<Id> scopes = new Set<Id>{original, destination.Id};
        Test.startTest();
        Id jobId = System.enqueueJob(new InventoryReconciliationJob(scopes));
        Test.stopTest();
        System.assertEquals('Completed', [SELECT Status FROM AsyncApexJob WHERE Id = :jobId].Status);
        Map<Id, Rooftop__c> roofs = new Map<Id, Rooftop__c>([SELECT Vehicles_On_Hand__c FROM Rooftop__c]);
        System.assertEquals(100, roofs.get(original).Vehicles_On_Hand__c);
        System.assertEquals(50, roofs.get(destination.Id).Vehicles_On_Hand__c, 'All statuses count, including Sold');
        System.assertEquals(41, roofs.get(unrelated.Id).Vehicles_On_Hand__c, 'Unrelated cache remains untouched');
        System.assertEquals(75, [SELECT Inventory_Age_Days__c FROM Vehicle__c WHERE Id = :moved[0].Id].Inventory_Age_Days__c);
        new InventoryReconciliationJob(scopes).execute(null);
        for (Rooftop__c roof : [SELECT Vehicles_On_Hand__c FROM Rooftop__c]) {
            System.assertEquals(roofs.get(roof.Id).Vehicles_On_Hand__c, roof.Vehicles_On_Hand__c, 'Reconciliation is idempotent');
        }
    }

    @isTest static void emptiedRooftopResetsToZero() {
        Vehicle__c row = P7Batch1TestData.vehicles(1)[0];
        bypass(true); delete row; bypass(false);
        Test.startTest(); System.enqueueJob(new InventoryReconciliationJob(new Set<Id>{row.Rooftop__c})); Test.stopTest();
        System.assertEquals(0, [SELECT Vehicles_On_Hand__c FROM Rooftop__c WHERE Id = :row.Rooftop__c].Vehicles_On_Hand__c);
    }

    @isTest static void unauthorizedPersonaCannotConstructOrEnqueueMaintenance() {
        User actor = [SELECT Id FROM User WHERE LastName = 'P7 maintenance denied'];
        Rooftop__c roof = new Rooftop__c(Name = 'P7 denied', Vehicles_On_Hand__c = 7); insert roof;
        System.runAs(actor) {
            System.assert(!FeatureManagement.checkPermission('Bypass_Automation'));
            try {
                System.enqueueJob(new InventoryReconciliationJob(new Set<Id>{roof.Id}));
                System.assert(false, 'Operational actor must not enqueue administrative reconciliation');
            } catch (SecurityException expected) {
                System.assert(expected.getMessage().contains('administrative access'));
            }
        }
        System.assertEquals(7, [SELECT Vehicles_On_Hand__c FROM Rooftop__c WHERE Id = :roof.Id].Vehicles_On_Hand__c);
    }

    @isTest static void invalidScopesFailBeforeEnqueue() {
        for (Set<Id> scope : new List<Set<Id>>{null, new Set<Id>(), new Set<Id>{null}, new Set<Id>{UserInfo.getUserId()}}) {
            try {
                new InventoryReconciliationJob(scope);
                System.assert(false, 'Invalid scope must fail');
            } catch (IllegalArgumentException expected) {
                System.assertNotEquals(null, expected.getMessage());
            }
        }
    }
}
