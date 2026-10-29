@isTest
private class InventoryGalleryControllerTest {
    @TestSetup static void actors() {
        P7Batch1TestData.actor('Gallery allowed', true, false, true);
        P7Batch1TestData.actor('Gallery denied', false, false, true);
    }
    @isTest static void filtersAndPagesPreserveReadBoundary() {
        List<Vehicle__c> rows = P7Batch1TestData.vehicles(51);
        User actor = [SELECT Id FROM User WHERE LastName = 'Gallery allowed' LIMIT 1];
        System.runAs(actor) {
            System.assert(!Schema.SObjectType.Vehicle__c.fields.Invoice_Cost__c.isAccessible());
            InventoryGalleryController.InventoryPage first = InventoryGalleryController.browse('Aurelia', 'Sedan', 10000, 30000, 'Available', null);
            System.assertEquals(50, first.cards.size()); System.assert(first.hasMore);
            System.assertEquals('/resource/NG_VehicleImages/aurelia_ex.webp', first.cards[0].imagePath);
            System.assert(!String.isBlank(first.cards[0].photoHtml));
            InventoryGalleryController.InventoryPage last = InventoryGalleryController.browse('Aurelia', 'Sedan', 10000, 30000, 'Available', first.nextId);
            System.assertEquals(1, last.cards.size()); System.assert(!last.hasMore);
            Set<Id> actual = new Set<Id>(); for (InventoryGalleryController.Card card : first.cards) actual.add(card.id);
            for (InventoryGalleryController.Card card : last.cards) actual.add(card.id);
            System.assertEquals(new Map<Id, Vehicle__c>(rows).keySet(), actual);
            System.assertEquals(0, InventoryGalleryController.browse('Aurelia\' OR Name != null', null, null, null, null, null).cards.size());
            System.assertEquals(0, InventoryGalleryController.browse(null, null, null, 1, null, null).cards.size());
            Boolean rejected = false;
            try { InventoryGalleryController.browse(null, null, 2, 1, null, null); } catch (AuraHandledException expected) { rejected = true; }
            System.assert(rejected);
        }
    }
    @isTest static void permissionGatedReadOnlySalesActorReservesAndCannotRepeat() {
        User actor = [SELECT Id FROM User WHERE LastName = 'Gallery allowed' LIMIT 1];
        Contact contact = P7Batch1TestData.contact(actor.Id, 'Gallery visible');
        Vehicle__c vehicle = P7Batch1TestData.vehicles(1)[0];
        System.runAs(actor) {
            System.assert(!Schema.SObjectType.Vehicle__c.isUpdateable(), 'Gallery must not grant direct Vehicle Edit.');
            InventoryGalleryController.reserve(vehicle.Id, contact.Id);
            Boolean rejected = false;
            try { InventoryGalleryController.reserve(vehicle.Id, contact.Id); } catch (AuraHandledException expected) { rejected = true; }
            System.assert(rejected);
        }
        Vehicle__c stored = [SELECT Status__c,Reserved_By__c,Reserved_On__c FROM Vehicle__c WHERE Id = :vehicle.Id WITH SYSTEM_MODE];
        System.assertEquals('Reserved', stored.Status__c); System.assertEquals(contact.Id, stored.Reserved_By__c); System.assertNotEquals(null, stored.Reserved_On__c);
    }
    @isTest static void deniedHiddenSoldAndBypassNeverMutateInventory() {
        User actor = [SELECT Id FROM User WHERE LastName = 'Gallery allowed' LIMIT 1];
        User denied = [SELECT Id FROM User WHERE LastName = 'Gallery denied' LIMIT 1];
        Contact hidden = P7Batch1TestData.contact(UserInfo.getUserId(), 'Gallery hidden');
        Contact visible = P7Batch1TestData.contact(actor.Id, 'Gallery own');
        Vehicle__c row = P7Batch1TestData.vehicles(1)[0];
        System.runAs(denied) { assertRejected(row.Id, visible.Id); }
        System.runAs(actor) { assertRejected(row.Id, hidden.Id); assertRejected(null, visible.Id); }
        row.Status__c = 'Sold'; update as system row;
        System.runAs(actor) { assertRejected(row.Id, visible.Id); }
        row.Status__c = 'Available'; update as system row;
        insert as system new Automation_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), Bypass_Triggers__c = true);
        System.runAs(actor) { assertRejected(row.Id, visible.Id); }
        System.assertEquals(null, [SELECT Reserved_By__c FROM Vehicle__c WHERE Id = :row.Id WITH SYSTEM_MODE].Reserved_By__c);
    }
    @isTest static void unsafePhotoPathIsNotRenderedAndCursorTypesAreChecked() {
        Vehicle__c row = P7Batch1TestData.vehicles(1)[0];
        update as system new Vehicle_Model__c(Id = row.Vehicle_Model__c, Image_Path__c = 'https://unapproved.example/image.webp');
        User actor = [SELECT Id FROM User WHERE LastName = 'Gallery allowed' LIMIT 1];
        System.runAs(actor) {
            System.assertEquals(null, InventoryGalleryController.browse(null, null, null, null, null, null).cards[0].imagePath);
            Boolean rejected = false;
            try { InventoryGalleryController.browse(null, null, null, null, null, actor.Id); } catch (AuraHandledException expected) { rejected = true; }
            System.assert(rejected);
        }
    }
    @isTest static void legacyAuthorizedWriterDoesNotRequireNewEventPermission() {
        User actor = [SELECT Id FROM User WHERE LastName = 'Gallery denied' LIMIT 1];
        Contact contact = P7Batch1TestData.contact(actor.Id, 'Legacy event actor');
        Vehicle__c row = P7Batch1TestData.vehicles(1)[0];
        System.runAs(actor) {
            System.assert(!Schema.SObjectType.Vehicle_Reserved__e.isCreateable());
            update as system new Vehicle__c(Id = row.Id, Reserved_By__c = contact.Id);
        }
        System.assertEquals('Reserved', [SELECT Status__c FROM Vehicle__c WHERE Id = :row.Id WITH SYSTEM_MODE].Status__c);
    }
    private static void assertRejected(Id vehicleId, Id contactId) {
        Boolean rejected = false;
        try { InventoryGalleryController.reserve(vehicleId, contactId); } catch (AuraHandledException expected) { rejected = true; }
        System.assert(rejected);
    }
}
