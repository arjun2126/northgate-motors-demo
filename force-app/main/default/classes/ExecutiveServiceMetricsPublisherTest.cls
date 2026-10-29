@isTest
private class ExecutiveServiceMetricsPublisherTest {
    @TestSetup
    static void actors() {
        Id salesProfile = [SELECT Id FROM Profile WHERE Name = 'NG_Sales' LIMIT 1].Id;
        Map<String, Id> permissions = new Map<String, Id>();
        for (PermissionSet permission : [
            SELECT Id, Name FROM PermissionSet
            WHERE Name IN ('PS_Demo_Admin', 'PS_VP_Executive_Reporting', 'PS_Management_Reports')
        ]) permissions.put(permission.Name, permission.Id);
        System.assertEquals(3, permissions.size());
        for (String mode : new List<String>{'Toronto', 'LosAngeles', 'VP'}) {
            User actor = new User(
                Alias = 'esm', LastName = 'ExecutiveMetrics' + mode,
                Email = 'executive.metrics.' + mode + '@northgate.example',
                Username = 'executive.metrics.' + mode + '.' + UserInfo.getOrganizationId() + '@northgate.example',
                ProfileId = mode == 'VP' ? salesProfile : UserInfo.getProfileId(),
                TimeZoneSidKey = mode == 'LosAngeles' ? 'America/Los_Angeles' : 'America/Toronto',
                LocaleSidKey = 'en_US', LanguageLocaleKey = 'en_US', EmailEncodingKey = 'UTF-8'
            );
            insert actor;
            insert new PermissionSetAssignment(
                AssigneeId = actor.Id,
                PermissionSetId = permissions.get(mode == 'VP' ? 'PS_VP_Executive_Reporting' : 'PS_Demo_Admin')
            );
            if (mode == 'VP') insert new PermissionSetAssignment(
                AssigneeId = actor.Id, PermissionSetId = permissions.get('PS_Management_Reports')
            );
        }
    }

    private static User actor(String mode) {
        String lastName = 'ExecutiveMetrics' + mode;
        return [SELECT Id FROM User WHERE LastName = :lastName LIMIT 1];
    }

    private static List<Service_Visit__c> visits(List<Datetime> starts, List<String> statuses, List<Decimal> scores) {
        System.assert(FeatureManagement.checkPermission('Bypass_Automation'), 'Only the isolated test writer bypasses past-visit creation validation.');
        Account account = new Account(Name = 'Executive metrics test');
        insert account;
        Contact contact = new Contact(LastName = 'Metrics test driver', AccountId = account.Id);
        insert contact;
        Vehicle_Model__c model = new Vehicle_Model__c(Name = 'Executive metrics test model');
        insert model;
        Vehicle__c vehicle = new Vehicle__c(Vehicle_Model__c = model.Id, VIN__c = 'METRCCST000000001');
        insert vehicle;
        Rooftop__c rooftop = new Rooftop__c(Name = 'Executive metrics test rooftop', Service_Capacity__c = 500);
        insert rooftop;
        List<Service_Visit__c> rows = new List<Service_Visit__c>();
        for (Integer i = 0; i < starts.size(); i++) {
            rows.add(new Service_Visit__c(
                Contact__c = contact.Id, Vehicle__c = vehicle.Id, Rooftop__c = rooftop.Id,
                Scheduled_Start__c = starts[i], Status__c = statuses[i], CSI_Score__c = scores[i]
            ));
        }
        Rooftop__c storedRooftop = [SELECT Id, Service_Capacity__c FROM Rooftop__c WHERE Id = :rooftop.Id];
        System.assertEquals(500, storedRooftop.Service_Capacity__c);
        System.assertEquals(rooftop.Id, rows[0].Rooftop__c);
        Map<Id, Rooftop__c> guardRooftops = ServiceVisitCapacityGuard.loadRooftops(
            new Set<Id>{rows[0].Rooftop__c}
        );
        System.assertEquals(500, guardRooftops.get(rows[0].Rooftop__c).Service_Capacity__c);
        insert rows;
        return rows;
    }

    private static Executive_Service_Metrics__c stored() {
        return [
            SELECT Id, Metric_Key__c, Overdue_Count__c, CSI_Score_Total__c,
                CSI_Response_Count__c, Captured_At__c
            FROM Executive_Service_Metrics__c WHERE Metric_Key__c = 'DEALERSHIP' WITH SYSTEM_MODE
        ];
    }

    @isTest
    static void overdueUsesLocalMidnightNotCurrentTimeAndCSIIncludesZeroScores() {
        System.runAs(actor('Toronto')) {
            // DST ends on Nov 1: Toronto midnight is 04:00 UTC on Nov 1, 05:00 UTC on Nov 2.
            Date day = Date.newInstance(2026, 11, 2);
            Datetime midnight = Datetime.newInstance(day, Time.newInstance(0, 0, 0, 0));
            System.assertEquals(Datetime.newInstanceGmt(2026, 11, 2, 5, 0, 0), midnight);
            System.assertEquals(Datetime.newInstanceGmt(2026, 11, 1, 4, 0, 0),
                Datetime.newInstance(day.addDays(-1), Time.newInstance(0, 0, 0, 0)));
            visits(
                new List<Datetime>{midnight.addSeconds(-1), midnight, midnight.addSeconds(1), midnight.addDays(-1), midnight.addDays(-1)},
                new List<String>{'Scheduled', 'Scheduled', 'Scheduled', 'Completed', 'Cancelled'},
                new List<Decimal>{80, 70, null, null, 0}
            );
            Executive_Service_Metrics__c result = ExecutiveServiceMetricsPublisher.calculate(day);
            System.assertEquals(1, result.Overdue_Count__c, 'Only Scheduled visits strictly before local midnight count.');
            System.assertEquals(150, result.CSI_Score_Total__c, 'CSI filter is nonblank score, not a status filter.');
            System.assertEquals(3, result.CSI_Response_Count__c, 'A zero score is a response, not missing data.');
            System.assertEquals(50, result.CSI_Score_Total__c / result.CSI_Response_Count__c);
        }
    }

    @isTest
    static void boundaryFollowsPublisherTimezone() {
        Date day = Date.newInstance(2026, 11, 2);
        System.runAs(actor('Toronto')) {
            visits(new List<Datetime>{Datetime.newInstanceGmt(2026, 11, 2, 7, 0, 0)},
                new List<String>{'Scheduled'}, new List<Decimal>{null});
            System.assertEquals(0, ExecutiveServiceMetricsPublisher.calculate(day).Overdue_Count__c);
        }
        System.runAs(actor('LosAngeles')) {
            System.assertEquals(1, ExecutiveServiceMetricsPublisher.calculate(day).Overdue_Count__c,
                'The same UTC instant is yesterday in Los Angeles but today in Toronto.');
        }
    }

    @isTest
    static void emptyDatasetPublishesExplicitZeroValues() {
        System.runAs(actor('Toronto')) {
            ExecutiveServiceMetricsPublisher.publish();
            Executive_Service_Metrics__c result = stored();
            System.assertEquals(0, result.Overdue_Count__c);
            System.assertEquals(0, result.CSI_Score_Total__c);
            System.assertEquals(0, result.CSI_Response_Count__c, 'Reports treat this as N/A, not zero average.');
            System.assertNotEquals(null, result.Captured_At__c);
        }
    }

    @isTest
    static void noQualifyingOverdueVisitsStillCountsCSI() {
        System.runAs(actor('Toronto')) {
            visits(new List<Datetime>{Datetime.now().addDays(1), Datetime.now().addDays(-2)},
                new List<String>{'Scheduled', 'Completed'}, new List<Decimal>{null, 75});
            ExecutiveServiceMetricsPublisher.publish();
            Executive_Service_Metrics__c result = stored();
            System.assertEquals(0, result.Overdue_Count__c);
            System.assertEquals(75, result.CSI_Score_Total__c);
            System.assertEquals(1, result.CSI_Response_Count__c);
        }
    }

    @isTest
    static void repeatedPublicationKeepsOneRecordAndClearsOldTotals() {
        System.runAs(actor('Toronto')) {
            List<Service_Visit__c> rows = visits(new List<Datetime>{Datetime.now().addDays(-2)},
                new List<String>{'Scheduled'}, new List<Decimal>{90});
            ExecutiveServiceMetricsPublisher.publish();
            Executive_Service_Metrics__c first = stored();
            System.assertEquals(1, first.Overdue_Count__c);
            rows[0].Status__c = 'Completed';
            rows[0].CSI_Score__c = null;
            update rows;
            // Invoke the scheduler delegate without creating any scheduled job, even in the test.
            new ExecutiveServiceMetricsPublisher().execute(null);
            Executive_Service_Metrics__c second = stored();
            System.assertEquals(first.Id, second.Id);
            System.assertEquals(1, [SELECT COUNT() FROM Executive_Service_Metrics__c]);
            System.assertEquals(0, second.Overdue_Count__c);
            System.assertEquals(0, second.CSI_Score_Total__c);
            System.assertEquals(0, second.CSI_Response_Count__c);
        }
    }

    @isTest
    static void failedWritePreservesLastSuccessfulCaptureAndValues() {
        System.runAs(actor('Toronto')) {
            Datetime previousCapture = Datetime.now().addDays(-2);
            Executive_Service_Metrics__c previous = new Executive_Service_Metrics__c(
                Metric_Key__c = 'DEALERSHIP', Overdue_Count__c = 13,
                CSI_Score_Total__c = 80, CSI_Response_Count__c = 1, Captured_At__c = previousCapture
            );
            insert as system previous;
            Executive_Service_Metrics__c baseline = stored();
            Executive_Service_Metrics__c invalid = new Executive_Service_Metrics__c(
                Metric_Key__c = 'DEALERSHIP', Overdue_Count__c = 14,
                CSI_Score_Total__c = Decimal.valueOf('999999999999999999999'),
                CSI_Response_Count__c = 1, Captured_At__c = Datetime.now()
            );
            Boolean failed = false;
            try {
                ExecutiveServiceMetricsPublisher.persist(invalid);
            } catch (DmlException expected) {
                failed = true;
            }
            System.assert(failed, 'Exercise a real failed upsert of the same DEALERSHIP key.');
            Executive_Service_Metrics__c result = stored();
            System.assertEquals(previous.Id, result.Id);
            System.assertEquals(baseline.Captured_At__c, result.Captured_At__c);
            System.assertEquals(13, result.Overdue_Count__c);
            System.assertEquals(80, result.CSI_Score_Total__c);
            System.assertEquals(1, result.CSI_Response_Count__c);
        }
    }

    @isTest
    static void vpReadsOnlyPublishedMetricsAndCannotPublishOrWrite() {
        System.runAs(actor('Toronto')) {
            visits(new List<Datetime>{Datetime.now().addDays(-2)}, new List<String>{'Scheduled'}, new List<Decimal>{85});
            ExecutiveServiceMetricsPublisher.publish();
        }
        Executive_Service_Metrics__c previous = stored();
        System.runAs(actor('VP')) {
            System.assert(!Schema.SObjectType.Service_Visit__c.isAccessible(), 'No direct Service Read.');
            System.assert(!Schema.SObjectType.Financing__c.isAccessible(), 'No Finance application access.');
            System.assert(!Schema.SObjectType.Executive_Service_Metrics__c.isCreateable());
            System.assert(!Schema.SObjectType.Executive_Service_Metrics__c.isUpdateable());
            System.assert(!Schema.SObjectType.Executive_Service_Metrics__c.isDeletable());
            List<Executive_Service_Metrics__c> visible = [
                SELECT Metric_Key__c, Overdue_Count__c, CSI_Score_Total__c, CSI_Response_Count__c, Captured_At__c
                FROM Executive_Service_Metrics__c WITH USER_MODE
            ];
            System.assertEquals(1, visible.size());
            System.assertEquals(1, visible[0].Overdue_Count__c);
            Integer dmlBefore = Limits.getDmlStatements();
            Boolean denied = false;
            try {
                ExecutiveServiceMetricsPublisher.publish();
            } catch (SecurityException expected) {
                System.assert(expected.getMessage().contains('Service_Visit__c') && expected.getMessage().contains('denied'),
                    'Failure must specifically deny access to Service Visit data: ' + expected.getMessage());
                denied = true;
            }
            System.assert(denied, 'User-mode source queries reject the VP even when Apex tests call publish directly.');
            System.assertEquals(dmlBefore, Limits.getDmlStatements(), 'Denied publication makes no writes.');
            denied = false;
            try {
                insert as user new Executive_Service_Metrics__c(
                    Metric_Key__c = 'UNAUTHORIZED', Overdue_Count__c = 0, CSI_Score_Total__c = 0,
                    CSI_Response_Count__c = 0, Captured_At__c = Datetime.now()
                );
            } catch (TypeException expected) {
                System.assert(expected.getMessage().contains('INSERT not allowed on Executive_Service_Metrics__c'), expected.getMessage());
                denied = true;
            }
            System.assert(denied, 'User-mode metrics creation must remain denied.');
            denied = false;
            try {
                update as user new Executive_Service_Metrics__c(Id = previous.Id, Overdue_Count__c = 999);
            } catch (TypeException expected) {
                denied = true;
            }
            System.assert(denied, 'User-mode operational write must remain denied.');
            denied = false;
            try {
                delete as user new Executive_Service_Metrics__c(Id = previous.Id);
            } catch (TypeException expected) {
                System.assert(expected.getMessage().contains('DELETE not allowed on Executive_Service_Metrics__c'), expected.getMessage());
                denied = true;
            }
            System.assert(denied, 'User-mode metrics deletion must remain denied.');
            System.assertEquals(1, [SELECT COUNT() FROM Executive_Service_Metrics__c WHERE Id = :previous.Id WITH USER_MODE],
                'Read-only access remains available after all denied operations.');
        }
        Executive_Service_Metrics__c after = stored();
        System.assertEquals(previous.Captured_At__c, after.Captured_At__c);
        System.assertEquals(previous.Overdue_Count__c, after.Overdue_Count__c);
        System.assertEquals(previous.CSI_Score_Total__c, after.CSI_Score_Total__c);
        System.assertEquals(previous.CSI_Response_Count__c, after.CSI_Response_Count__c);
        System.assertEquals(1, [SELECT COUNT() FROM Executive_Service_Metrics__c WITH SYSTEM_MODE]);
    }
}
