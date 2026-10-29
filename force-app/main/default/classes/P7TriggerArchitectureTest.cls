@isTest
private class P7TriggerArchitectureTest {
    private static void bypass(Boolean enabled) {
        Automation_Settings__c settings = Automation_Settings__c.getOrgDefaults();
        settings.SetupOwnerId = UserInfo.getOrganizationId();
        settings.Bypass_Triggers__c = enabled;
        upsert settings;
    }

    private static List<Lead> leads(Id rooftop, Integer count) {
        List<Lead> rows = new List<Lead>();
        for (Integer i = 0; i < count; i++) rows.add(new Lead(
            LastName = 'P7 Bulk ' + i, Company = 'P7 isolated routing',
            Rooftop__c = rooftop, PostalCode = 'M5V2T6'));
        return rows;
    }

    @isTest static void unconfiguredLaneHandles200AndLaterSaves() {
        Rooftop__c roof = new Rooftop__c(Name = 'Northgate Downtown'); insert roof;
        List<Lead> rows = leads(roof.Id, 200);
        Test.startTest();
        Integer beforeQueries = Limits.getQueries();
        insert rows;
        System.assert(Limits.getQueries() - beforeQueries < 30, 'Lane resolution must not query per Lead');
        Set<Id> ids = new Map<Id, Lead>(rows).keySet();
        System.assertEquals(200, [SELECT COUNT() FROM Lead WHERE Id IN :ids AND Assigned_Batch__c != null]);
        for (Lead row : rows) row.Company = 'P7 neutral update';
        update rows;
        Lead later = leads(roof.Id, 1)[0]; insert later;
        System.assertNotEquals(null, [SELECT Assigned_Batch__c FROM Lead WHERE Id = :later.Id].Assigned_Batch__c,
            'Recursion guard must reset, not suppress later saves');
        Test.stopTest();
    }

    @isTest static void partialLeadInsertRetainsRoutingAndAllowsReentry() {
        Rooftop__c roof = new Rooftop__c(Name = 'Northgate Downtown'); insert roof;
        List<Lead> rows = leads(roof.Id, 200);
        rows[0].LastName = null;
        Test.startTest();
        Database.SaveResult[] results = Database.insert(rows, false);
        System.assert(!results[0].isSuccess(), 'Required-field failure remains isolated');
        Set<Id> successful = new Set<Id>();
        for (Integer i = 1; i < results.size(); i++) {
            System.assert(results[i].isSuccess(), 'Valid row survives partial save');
            successful.add(results[i].getId());
        }
        System.assertEquals(199, [SELECT COUNT() FROM Lead WHERE Id IN :successful AND Assigned_Batch__c != null]);
        Lead later = leads(roof.Id, 1)[0]; insert later;
        System.assertNotEquals(null, [SELECT Assigned_Batch__c FROM Lead WHERE Id = :later.Id].Assigned_Batch__c);
        Test.stopTest();
    }

    @isTest static void convertedSeedCleanupIsBulkAndTransitionOnly() {
        List<Account> accounts = new List<Account>();
        List<Contact> contacts = new List<Contact>();
        List<Opportunity> opportunities = new List<Opportunity>();
        for (Integer i = 0; i < 200; i++) {
            accounts.add(new Account(Name = 'P7 converted ' + i, Seed_Tag__c = 'P7-ISOLATED-' + i));
            contacts.add(new Contact(LastName = 'P7 converted ' + i, Seed_Tag__c = 'P7-ISOLATED-' + i));
            opportunities.add(new Opportunity(Name = 'P7 converted ' + i, Seed_Tag__c = 'P7-ISOLATED-' + i,
                StageName = 'Prospecting', CloseDate = Date.today().addDays(30)));
        }
        insert accounts; insert contacts; insert opportunities;
        List<Lead> rows = new List<Lead>();
        Map<Id, Lead> previous = new Map<Id, Lead>();
        for (Integer i = 0; i < 200; i++) {
            String leadId = '00Q' + String.valueOf(100000000000L + i);
            Lead row = (Lead) JSON.deserialize(JSON.serialize(new Map<String, Object>{
                'Id' => leadId, 'IsConverted' => true, 'ConvertedAccountId' => accounts[i].Id,
                'ConvertedContactId' => contacts[i].Id, 'ConvertedOpportunityId' => opportunities[i].Id}), Lead.class);
            rows.add(row);
            previous.put(row.Id, (Lead) JSON.deserialize('{"Id":"' + leadId + '","IsConverted":false}', Lead.class));
        }
        Test.startTest();
        Integer statements = Limits.getDmlStatements();
        LeadTriggerHandler.clearConvertedSeedTags(rows, previous);
        System.assertEquals(3, Limits.getDmlStatements() - statements, 'One update per target object, not per row');
        System.assertEquals(0, [SELECT COUNT() FROM Account WHERE Seed_Tag__c != null]);
        System.assertEquals(0, [SELECT COUNT() FROM Contact WHERE Seed_Tag__c != null]);
        System.assertEquals(0, [SELECT COUNT() FROM Opportunity WHERE Seed_Tag__c != null]);
        LeadTriggerHandler.clearConvertedSeedTags(rows, new Map<Id, Lead>(rows));
        Test.stopTest();
    }

    @isTest static void missingConvertedAccountRetainsGuard() {
        Id leadId = '00Q100000000001';
        Lead row = (Lead) JSON.deserialize('{"Id":"' + leadId + '","IsConverted":true}', Lead.class);
        Lead old = (Lead) JSON.deserialize('{"Id":"' + leadId + '","IsConverted":false}', Lead.class);
        LeadTriggerHandler.beforeUpdate(new List<Lead>{row}, new Map<Id, Lead>{leadId => old});
        System.assert(row.hasErrors());
        System.assert(row.getErrors()[0].getMessage().contains('Convert with an Account selected'));
    }

    @isTest static void bulkVehiclePartialReservationAndLaterTransition() {
        List<Vehicle__c> rows = P7Batch1TestData.vehicles(200);
        Contact first = P7Batch1TestData.contact(UserInfo.getUserId(), 'P7 original');
        Contact second = P7Batch1TestData.contact(UserInfo.getUserId(), 'P7 next');
        rows[0].Reserved_By__c = first.Id; update rows[0];
        for (Vehicle__c row : rows) row.Reserved_By__c = second.Id;
        Test.startTest();
        Database.SaveResult[] results = Database.update(rows, false);
        System.assert(!results[0].isSuccess(), 'Existing reservation must not be taken over');
        System.assert(results[0].getErrors()[0].getMessage().contains('already reserved'));
        for (Integer i = 1; i < 200; i++) System.assert(results[i].isSuccess());
        System.assertEquals(199, [SELECT COUNT() FROM Vehicle__c WHERE Reserved_By__c = :second.Id]);
        Vehicle__c released = new Vehicle__c(Id = rows[0].Id, Reserved_By__c = null, Status__c = 'Available');
        update released;
        released.Reserved_By__c = second.Id; update released;
        Vehicle__c stored = [SELECT Status__c, Reserved_On__c FROM Vehicle__c WHERE Id = :released.Id];
        System.assertEquals('Reserved', stored.Status__c);
        System.assertNotEquals(null, stored.Reserved_On__c);
        System.assertEquals(200, [SELECT Vehicles_On_Hand__c FROM Rooftop__c WHERE Id = :rows[0].Rooftop__c].Vehicles_On_Hand__c);
        Test.stopTest();
    }

    @isTest static void hierarchyBypassPreservesDistinctValidationContracts() {
        List<Vehicle__c> vehicles = P7Batch1TestData.vehicles(1);
        Contact driver = P7Batch1TestData.contact(UserInfo.getUserId(), 'P7 bypass');
        Rooftop__c roof = new Rooftop__c(Name = 'Northgate Downtown'); insert roof;
        bypass(true);
        Lead lead = leads(roof.Id, 1)[0]; insert lead;
        System.assertEquals(null, [SELECT Assigned_Batch__c FROM Lead WHERE Id = :lead.Id].Assigned_Batch__c);
        vehicles[0].Reserved_By__c = driver.Id; update vehicles;
        System.assertEquals('Reserved', [SELECT Status__c FROM Vehicle__c WHERE Id = :vehicles[0].Id].Status__c,
            'Hierarchy bypass never bypassed Vehicle reservation validation');
        Test_Drive__c scheduledDrive = new Test_Drive__c(Vehicle__c = vehicles[0].Id, Contact__c = driver.Id,
            Scheduled_Start__c = Datetime.now().addDays(1), Duration_Minutes__c = 30, Status__c = 'Scheduled');
        insert scheduledDrive;
        System.assertEquals(0, [SELECT COUNT() FROM Task WHERE WhoId = :driver.Id], 'Bypass suppresses follow-up Tasks');
        scheduledDrive.Scheduled_Start__c = Datetime.now().addDays(-1);
        Database.SaveResult result = Database.update(scheduledDrive, false);
        System.assert(!result.isSuccess());
        System.assert(result.getErrors()[0].getMessage().contains('Choose a future start time'));
        bypass(false);
        scheduledDrive.Scheduled_Start__c = Datetime.now().addDays(2);
        scheduledDrive.Status__c = 'Completed'; update scheduledDrive;
        System.assertEquals(1, [SELECT COUNT() FROM Task WHERE WhoId = :driver.Id], 'Later saves must not remain suppressed');
    }

    @isTest static void bulkDriveLifecycleHasNoDuplicateFollowups() {
        Vehicle__c vehicle = P7Batch1TestData.vehicles(1)[0];
        Contact driver = P7Batch1TestData.contact(UserInfo.getUserId(), 'P7 bulk drive');
        List<Test_Drive__c> rows = new List<Test_Drive__c>();
        for (Integer i = 0; i < 200; i++) rows.add(new Test_Drive__c(
            Vehicle__c = vehicle.Id, Contact__c = driver.Id, Status__c = 'Scheduled',
            Scheduled_Start__c = Datetime.now().addDays(2).addMinutes(i * 60), Duration_Minutes__c = 30));
        Test.startTest();
        insert rows;
        System.assertEquals(200, [SELECT COUNT() FROM Task WHERE WhoId = :driver.Id]);
        for (Test_Drive__c row : rows) row.Status__c = 'Completed';
        update rows;
        System.assertEquals(400, [SELECT COUNT() FROM Task WHERE WhoId = :driver.Id]);
        update rows;
        System.assertEquals(400, [SELECT COUNT() FROM Task WHERE WhoId = :driver.Id], 'Neutral re-entry creates no completion duplicates');
        System.assertEquals(200, [SELECT Completed_Test_Drives__c FROM Vehicle_Model__c WHERE Id = :vehicle.Vehicle_Model__c].Completed_Test_Drives__c);
        Test.stopTest();
    }

    @isTest static void partialDriveSaveDoesNotSuppressValidFollowup() {
        Vehicle__c vehicle = P7Batch1TestData.vehicles(1)[0];
        Contact driver = P7Batch1TestData.contact(UserInfo.getUserId(), 'P7 partial drive');
        List<Test_Drive__c> rows = new List<Test_Drive__c>{
            new Test_Drive__c(Vehicle__c = vehicle.Id, Contact__c = driver.Id, Status__c = 'Scheduled',
                Scheduled_Start__c = Datetime.now().addDays(-1), Duration_Minutes__c = 30),
            new Test_Drive__c(Vehicle__c = vehicle.Id, Contact__c = driver.Id, Status__c = 'Scheduled',
                Scheduled_Start__c = Datetime.now().addDays(1), Duration_Minutes__c = 30)};
        Test.startTest();
        Database.SaveResult[] results = Database.insert(rows, false);
        System.assert(!results[0].isSuccess()); System.assert(results[1].isSuccess());
        System.assertEquals(1, [SELECT COUNT() FROM Task WHERE WhoId = :driver.Id]);
        rows[1].Status__c = 'Completed'; update rows[1];
        System.assertEquals(2, [SELECT COUNT() FROM Task WHERE WhoId = :driver.Id]);
        Test.stopTest();
    }
}
