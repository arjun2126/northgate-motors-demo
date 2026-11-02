@isTest
private class BuyerShowcaseControllerTest {
    @TestSetup static void data() {
        Rooftop__c roof = new Rooftop__c(Name = 'Buyer Downtown'); insert as system roof;
        Vehicle_Model__c aurelia = new Vehicle_Model__c(Name = 'Aurelia Sport', Make__c = 'Aurelia',
            Model__c = 'Aurelia Sport', Trim__c = 'Sport', Body_Style__c = 'Coupe', Drivetrain__c = 'AWD',
            Transmission__c = 'Automatic', Fuel_Type__c = 'EV', Base_MSRP__c = 40000,
            Image_Path__c = '/resource/NG_VehicleImages/aurelia_sport.webp', Is_Active__c = true);
        Vehicle_Model__c cascadia = new Vehicle_Model__c(Name = 'Cascadia LX', Make__c = 'Cascadia',
            Model__c = 'Cascadia', Trim__c = 'LX', Body_Style__c = 'Truck', Drivetrain__c = 'RWD',
            Transmission__c = 'Manual', Fuel_Type__c = 'Diesel', Base_MSRP__c = 30000,
            Image_Path__c = 'https://unapproved.example/cascadia.webp', Is_Active__c = true);
        Vehicle_Model__c inactive = new Vehicle_Model__c(Name = 'Retired', Make__c = 'Retired',
            Model__c = 'Retired', Is_Active__c = false);
        insert as system new List<Vehicle_Model__c>{aurelia, cascadia, inactive};
        List<Vehicle__c> vehicles = new List<Vehicle__c>{
            vehicle(aurelia.Id, roof.Id, '1HGCM82633A004352', 2025, 'Red', 'New', 'Available', 30000, 12),
            vehicle(aurelia.Id, roof.Id, '1HGCM82633A004353', 2024, 'Blue', 'Certified_Pre_Owned', 'Available', 25000, 12000),
            vehicle(aurelia.Id, roof.Id, '1HGCM82633A004354', 2025, 'Red', 'New', 'Reserved', 28000, 5),
            vehicle(aurelia.Id, roof.Id, '1HGCM82633A004355', 2026, 'White', 'New', 'In_Transit', 32000, 1),
            vehicle(aurelia.Id, roof.Id, '1HGCM82633A004356', 2023, 'Silver', 'Used', 'Sold', 20000, 30000),
            vehicle(cascadia.Id, roof.Id, '1HGCM82633A004357', 2025, 'Green', 'New', 'Available', 40000, 8)
        };
        insert as system vehicles;
    }

    private static Vehicle__c vehicle(Id modelId, Id roofId, String vin, Integer year, String colour,
            String condition, String status, Decimal price, Integer odometer) {
        return new Vehicle__c(Vehicle_Model__c = modelId, Rooftop__c = roofId, VIN__c = vin,
            Year__c = year, Colour__c = colour, Condition__c = condition, Status__c = status,
            List_Price__c = price, Odometer__c = odometer);
    }

    private static User buyer() {
        User actor = new User(Alias = 'bshowcas', LastName = 'Buyer Site',
            Username = 'buyer.site.' + UserInfo.getOrganizationId() + '@northgate.example',
            Email = 'buyer@example.com',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Toronto', LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US', EmailEncodingKey = 'UTF-8');
        insert as system actor;
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'PS_Buyer_Website' LIMIT 1];
        insert as system new PermissionSetAssignment(AssigneeId = actor.Id, PermissionSetId = ps.Id);
        return actor;
    }

    @isTest static void showcaseAggregatesRealInventoryOnly() {
        User actor = buyer();
        Integer before = [SELECT COUNT() FROM Vehicle__c WITH SYSTEM_MODE];
        Test.startTest();
        BuyerShowcaseController.Showcase showcase;
        System.runAs(actor) { showcase = BuyerShowcaseController.getShowcase(); }
        Test.stopTest();
        System.assertEquals(2, showcase.models.size(), 'inactive models are excluded');
        System.assertEquals(5, showcase.vehicles.size(), 'sold inventory is excluded');
        System.assertEquals(3, showcase.availableCount);
        System.assertEquals(Decimal.valueOf(40000), showcase.maxPrice);
        Map<String, BuyerShowcaseController.Model> byTitle = new Map<String, BuyerShowcaseController.Model>();
        for (BuyerShowcaseController.Model model : showcase.models) byTitle.put(model.title, model);
        System.assert(byTitle.containsKey('Aurelia Sport'), 'make/trim duplication is suppressed');
        System.assert(byTitle.containsKey('Cascadia LX'));
        System.assertEquals(Decimal.valueOf(25000), byTitle.get('Aurelia Sport').fromPrice);
        System.assertEquals(2, byTitle.get('Aurelia Sport').availableCount);
        System.assertEquals(null, byTitle.get('Cascadia LX').imageName, 'unsafe image paths are rejected');
        System.assertEquals(5, showcase.vehicles.size());
        Boolean foundTransit = false, foundReserved = false;
        for (BuyerShowcaseController.Vehicle vehicle : showcase.vehicles) {
            if (vehicle.status == 'In_Transit') foundTransit = true;
            if (vehicle.status == 'Reserved') foundReserved = true;
            System.assertNotEquals('Sold', vehicle.status);
        }
        System.assert(foundTransit); System.assert(foundReserved);
        System.assertNotEquals(null, byTitle.get('Aurelia Sport').imageName);
        System.assertEquals(before, [SELECT COUNT() FROM Vehicle__c WITH SYSTEM_MODE], 'read must not mutate inventory');
        Boolean nativeReadBlocked = false;
        System.runAs(actor) {
            try {
                List<Vehicle__c> leaked = [SELECT Id FROM Vehicle__c WITH USER_MODE LIMIT 1];
                System.assert(leaked.isEmpty(), 'Unexpected native Vehicle visibility');
            } catch (System.QueryException expected) {
                nativeReadBlocked = true;
            }
        }
        System.assert(nativeReadBlocked, 'Native Vehicle read must be denied, not merely empty');
    }


    @isTest static void guestPersonaCanReadOnlyThePublicCatalogue() {
        List<User> guests = [SELECT Id FROM User WHERE UserType = 'Guest' LIMIT 1];
        System.assert(!guests.isEmpty(), 'guest user must exist for this contract');
        BuyerShowcaseController.Showcase showcase;
        System.runAs(guests[0]) { showcase = BuyerShowcaseController.getShowcase(); }
        System.assert(showcase.models.size() > 0, 'guest must see active models');
        System.assert(showcase.vehicles.size() > 0, 'guest must see public vehicles');
        for (BuyerShowcaseController.Vehicle vehicle : showcase.vehicles) {
            System.assertNotEquals('Sold', vehicle.status);
            System.assertNotEquals('Delivered', vehicle.status);
        }
        Boolean nativeRead = false;
        System.runAs(guests[0]) {
            try {
                nativeRead = ![SELECT Id FROM Vehicle__c WITH USER_MODE LIMIT 1].isEmpty();
            } catch (System.QueryException expected) {
                nativeRead = false;
            }
        }
        System.assert(!nativeRead, 'guest must not gain native Vehicle access');
    }

    @isTest static void facetingAndPricingAreDerivedFromRecords() {
        User actor = buyer();
        BuyerShowcaseController.Showcase showcase;
        System.runAs(actor) { showcase = BuyerShowcaseController.getShowcase(); }
        Set<String> colours = new Set<String>();
        for (BuyerShowcaseController.Choice choice : showcase.colours) colours.add(choice.value);
        System.assert(colours.contains('Red')); System.assert(colours.contains('Green'));
        Set<String> bodies = new Set<String>();
        for (BuyerShowcaseController.Choice choice : showcase.bodyStyles) bodies.add(choice.value);
        System.assert(bodies.contains('Coupe')); System.assert(bodies.contains('Truck'));
    }
}
