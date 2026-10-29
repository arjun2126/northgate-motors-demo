public with sharing class InventoryGalleryController {
    public class InventoryPage {
        @AuraEnabled public List<Card> cards = new List<Card>();
        @AuraEnabled public Id nextId;
        @AuraEnabled public Boolean hasMore;
    }
    public class Card {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String vin;
        @AuraEnabled public String status;
        @AuraEnabled public String make;
        @AuraEnabled public String bodyStyle;
        @AuraEnabled public String photoHtml;
        @AuraEnabled public String imagePath;
        @AuraEnabled public Decimal price;
        @AuraEnabled public Boolean reservable;
    }
    @AuraEnabled(cacheable=true)
    public static InventoryPage browse(String make, String bodyStyle, Decimal minPrice, Decimal maxPrice, String status, Id afterId) {
        if ((minPrice != null && minPrice < 0) || (maxPrice != null && maxPrice < 0)
            || (minPrice != null && maxPrice != null && minPrice > maxPrice)) {
            throw new AuraHandledException('Enter a valid nonnegative price range.');
        }
        if (afterId != null && afterId.getSObjectType() != Vehicle__c.SObjectType) throw new AuraHandledException('Invalid inventory cursor.');
        Map<String, Object> binds = new Map<String, Object>();
        String soql = 'SELECT Id, Name, VIN__c, Status__c, List_Price__c, Reserved_By__c, Photo__c, '
            + 'Vehicle_Model__r.Make__c, Vehicle_Model__r.Body_Style__c, Vehicle_Model__r.Image_Path__c FROM Vehicle__c WHERE Id != null';
        if (!String.isBlank(make)) { soql += ' AND Vehicle_Model__r.Make__c = :make'; binds.put('make', make); }
        if (!String.isBlank(bodyStyle)) { soql += ' AND Vehicle_Model__r.Body_Style__c = :body'; binds.put('body', bodyStyle); }
        if (!String.isBlank(status)) { soql += ' AND Status__c = :status'; binds.put('status', status); }
        if (minPrice != null) { soql += ' AND List_Price__c >= :minimum'; binds.put('minimum', minPrice); }
        if (maxPrice != null) { soql += ' AND List_Price__c <= :maximum'; binds.put('maximum', maxPrice); }
        if (afterId != null) { soql += ' AND Id > :afterId'; binds.put('afterId', afterId); }
        soql += ' ORDER BY Id LIMIT 51';
        List<Vehicle__c> rows = Database.queryWithBinds(soql, binds, AccessLevel.USER_MODE);
        InventoryPage page = new InventoryPage(); page.hasMore = rows.size() > 50;
        if (page.hasMore) rows.remove(50);
        for (Vehicle__c row : rows) {
            Card card = new Card(); card.id = row.Id; card.name = row.Name; card.vin = row.VIN__c;
            card.status = row.Status__c; card.price = row.List_Price__c; card.photoHtml = row.Photo__c;
            card.make = row.Vehicle_Model__r.Make__c; card.bodyStyle = row.Vehicle_Model__r.Body_Style__c;
            String path = row.Vehicle_Model__r.Image_Path__c;
            if (!String.isBlank(row.Photo__c) && path != null && Pattern.matches('/resource/NG_VehicleImages/[a-z0-9_]+\\.webp', path)) card.imagePath = path;
            card.reservable = row.Status__c == 'Available' && row.Reserved_By__c == null;
            page.cards.add(card); page.nextId = row.Id;
        }
        return page;
    }
    @AuraEnabled
    public static void reserve(Id vehicleId, Id contactId) {
        if (!FeatureManagement.checkPermission('Reserve_Inventory_Vehicle')) throw new AuraHandledException('Inventory reservation permission is required.');
        Automation_Settings__c settings = Automation_Settings__c.getOrgDefaults();
        if (FeatureManagement.checkPermission('Bypass_Automation') || (settings != null && settings.Bypass_Triggers__c)) {
            throw new AuraHandledException('Reservations are unavailable while automation is bypassed.');
        }
        if (vehicleId == null || contactId == null || vehicleId.getSObjectType() != Vehicle__c.SObjectType
            || contactId.getSObjectType() != Contact.SObjectType) throw new AuraHandledException('Select a vehicle and an accessible Contact.');
        List<Contact> contacts = [SELECT Id FROM Contact WHERE Id = :contactId WITH USER_MODE];
        if (contacts.isEmpty()) throw new AuraHandledException('Select an accessible Contact.');
        List<Vehicle__c> rows = [SELECT Id, Status__c, Reserved_By__c FROM Vehicle__c WHERE Id = :vehicleId WITH USER_MODE FOR UPDATE];
        if (rows.isEmpty() || rows[0].Status__c != 'Available' || rows[0].Reserved_By__c != null) {
            throw new AuraHandledException('Vehicle is no longer available. Refresh inventory.');
        }
        // The permission-gated writer changes only the reserver. Existing triggers own status/time/counters/events.
        update as system new Vehicle__c(Id = vehicleId, Reserved_By__c = contactId);
    }
}
