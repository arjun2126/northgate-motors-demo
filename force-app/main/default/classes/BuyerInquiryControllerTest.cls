@isTest
private class BuyerInquiryControllerTest {
    @TestSetup static void data() {
        Rooftop__c roof = new Rooftop__c(Name = 'Buyer Inquiry Roof'); insert as system roof;
        Vehicle_Model__c model = new Vehicle_Model__c(Name = 'Aurelia Sport', Make__c = 'Aurelia',
            Model__c = 'Aurelia Sport', Trim__c = 'Sport', Body_Style__c = 'Coupe',
            Image_Path__c = '/resource/NG_VehicleImages/aurelia_sport.webp', Is_Active__c = true);
        insert as system model;
        insert as system new List<Vehicle__c>{
            new Vehicle__c(Vehicle_Model__c = model.Id, Rooftop__c = roof.Id, VIN__c = '1HGCM82633A004360',
                Year__c = 2025, Colour__c = 'Red', Condition__c = 'New', Status__c = 'Available', List_Price__c = 30000),
            new Vehicle__c(Vehicle_Model__c = model.Id, Rooftop__c = roof.Id, VIN__c = '1HGCM82633A004361',
                Year__c = 2024, Colour__c = 'Blue', Condition__c = 'Used', Status__c = 'Sold', List_Price__c = 20000)
        };
    }

    private static User buyer() {
        User actor = new User(Alias = 'buyerin', LastName = 'Buyer Inquiry',
            Username = 'buyer.inquiry.' + UserInfo.getOrganizationId() + '@northgate.example',
            Email = 'buyer@northgate.test',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Toronto', LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US', EmailEncodingKey = 'UTF-8');
        insert as system actor;
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'PS_Buyer_Website' LIMIT 1];
        insert as system new PermissionSetAssignment(AssigneeId = actor.Id, PermissionSetId = ps.Id);
        return actor;
    }

    @isTest static void testDriveCreatesRoutedLead() {
        Vehicle__c vehicle = [SELECT Id, Name FROM Vehicle__c WHERE Status__c = 'Available' LIMIT 1];
        User actor = buyer();
        String reference;
        Test.startTest();
        System.runAs(actor) {
            reference = BuyerInquiryController.submit('Jamie Buyer', 'jamie@northgate.test', '416-555-0100',
                'Saturday morning please', vehicle.Id, 'Test Drive');
        }
        Test.stopTest();
        System.assert(reference.startsWith('NG-'));
        Lead lead = [SELECT LastName, Company, Email, Phone, LeadSource, OwnerId, Description
            FROM Lead WHERE Email = 'jamie@northgate.test' LIMIT 1];
        System.assertEquals('Jamie Buyer', lead.LastName);
        System.assertEquals('Northgate Motors Website', lead.Company);
        System.assertEquals('Web', lead.LeadSource);
        System.assertEquals(Id.valueOf(Label.Buyer_Lead_Queue_Id), lead.OwnerId, 'website Leads must use the configured queue');
        System.assert(lead.Description.contains('Test Drive request'));
        System.assert(lead.Description.contains(vehicle.Name));
        System.assert(lead.Description.contains('Aurelia Sport'));
    }

    @isTest static void generalPurchaseInquiryDoesNotRequireVehicle() {
        User actor = buyer();
        System.runAs(actor) {
            BuyerInquiryController.submit('Alex Buyer', 'alex@northgate.test', '', 'Please call me',
                null, 'Purchase Inquiry');
        }
        Lead lead = [SELECT Description FROM Lead WHERE Email = 'alex@northgate.test' LIMIT 1];
        System.assert(lead.Description.contains('Purchase Inquiry'));
        System.assert(lead.Description.contains('General inquiry'));
    }


    @isTest static void guestCanSubmitWithoutGroupAccess() {
        Vehicle__c vehicle = [SELECT Id FROM Vehicle__c WHERE Status__c = 'Available' LIMIT 1];
        List<User> guests = [SELECT Id FROM User WHERE UserType = 'Guest' LIMIT 1];
        System.assert(!guests.isEmpty(), 'guest user must exist');
        String reference;
        Boolean groupBlocked = false;
        System.runAs(guests[0]) {
            try {
                List<Group> groups = [SELECT Id FROM Group LIMIT 1];
                groupBlocked = groups.isEmpty();
                System.assert(false, 'guest Group query unexpectedly succeeded');
            } catch (System.QueryException expected) {
                groupBlocked = true;
            }
            reference = BuyerInquiryController.submit('Guest Buyer', 'guest@northgate.test', '',
                'Anonymous site request', vehicle.Id, 'Test Drive');
        }
        System.assert(groupBlocked, 'guest Group query must be blocked to reproduce the original failure');
        System.assert(reference.startsWith('NG-'));
        Lead lead = [SELECT OwnerId, Description FROM Lead WHERE Email = 'guest@northgate.test' LIMIT 1];
        System.assertNotEquals(null, lead.OwnerId);
        System.assert(lead.Description.contains('Test Drive'));
    }

    @isTest static void invalidInputsAndClosedInventoryAreRejectedBeforeInsert() {
        User actor = buyer();
        Vehicle__c sold = [SELECT Id FROM Vehicle__c WHERE Status__c = 'Sold' LIMIT 1];
        Vehicle__c available = [SELECT Id FROM Vehicle__c WHERE Status__c = 'Available' LIMIT 1];
        Integer before = [SELECT COUNT() FROM Lead WITH SYSTEM_MODE];
        System.runAs(actor) {
            assertRejected('', 'buyer@northgate.test', null, 'Test Drive');
            assertRejected('Buyer', 'buyer@gmail.com', null, 'Purchase Inquiry');
            assertRejected('Buyer', 'not-an-email', null, 'Purchase Inquiry');
            assertRejected('Buyer', 'buyer@northgate.test', null, 'Test Drive');
            assertRejected('Buyer', 'buyer@northgate.test', sold.Id, 'Test Drive');
            assertRejected('Buyer', 'buyer@northgate.test', available.Id, 'Trade In');
        }
        System.assertEquals(before, [SELECT COUNT() FROM Lead WITH SYSTEM_MODE]);
    }

    private static void assertRejected(String name, String email, Id vehicleId, String type) {
        Boolean rejected = false;
        try {
            BuyerInquiryController.submit(name, email, null, null, vehicleId, type);
        } catch (AuraHandledException expected) {
            rejected = true;
        }
        System.assert(rejected, 'Expected rejection for ' + type);
    }
}
