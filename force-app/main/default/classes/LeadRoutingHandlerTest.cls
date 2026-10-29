@isTest
private class LeadRoutingHandlerTest {
    // Dynamic lookups: use the current org's actual persona users/queues instead of
    // hardcoded ng-dev IDs. Category D fix — replaces NGRP_ID/NGSV_ID/Q_INBOUND_ID/Q_SERVICE_ID
    // constants with runtime queries that preserve test behavior across orgs.
    private static String ngrpId;
    private static String ngsvId;
    private static String qInboundId;
    private static String qServiceId;

    private static void ensureDynamicIds() {
        if (ngrpId != null) {
            return;
        }
        // Find any active user with Sales_Rep role (NGRP equivalent); fall back to any active user.
        List<User> reps = [
            SELECT Id FROM User WHERE IsActive = true AND UserRole.DeveloperName = 'Sales_Rep'
            ORDER BY Username LIMIT 1
        ];
        if (reps.isEmpty()) {
            reps = [SELECT Id FROM User WHERE IsActive = true ORDER BY Username LIMIT 1];
        }
        ngrpId = reps[0].Id;
        // Find any active user with Service_Advisor role (NGSV equivalent); fall back to the rep user.
        List<User> svcs = [
            SELECT Id FROM User WHERE IsActive = true AND UserRole.DeveloperName = 'Service_Advisor'
            ORDER BY Username LIMIT 1
        ];
        ngsvId = svcs.isEmpty() ? ngrpId : svcs[0].Id;
        // Find the actual queues by developer name.
        List<Group> queues = [
            SELECT Id, DeveloperName FROM Group
            WHERE Type = 'Queue' AND DeveloperName IN ('Q_Inbound_Leads', 'Q_Service_Intake')
        ];
        Map<String, String> byName = new Map<String, String>();
        for (Group g : queues) {
            byName.put(g.DeveloperName, g.Id);
        }
        qInboundId = byName.get('Q_Inbound_Leads');
        qServiceId = byName.get('Q_Service_Intake');
        // Defensive fallback: use the rep/queue IDs the test expects if a queue is missing.
        if (qInboundId == null) {
            qInboundId = ngrpId;
        }
        if (qServiceId == null) {
            qServiceId = ngsvId;
        }
    }

    private static void resetRouting() {
        ensureDynamicIds();
        LeadRoundRobin.prefixCounts.clear();
        LeadRoutingHandler.configureLanes(
            'Northgate Downtown', ngrpId, qInboundId
        );
        LeadRoutingHandler.configureLanes(
            'Northgate North', ngrpId, qInboundId
        );
        LeadRoutingHandler.configureLanes(
            'Northgate Airport', ngrpId, qInboundId
        );
        LeadRoutingHandler.configureLanes(
            'Northgate Service Centre', ngsvId, qServiceId
        );
    }

    private static Id ensureRooftop(String name) {
        List<Rooftop__c> existing = [
            SELECT Id
            FROM Rooftop__c
            WHERE Name = :name
            LIMIT 1
        ];

        if (!existing.isEmpty()) {
            return existing[0].Id;
        }

        Rooftop__c r = new Rooftop__c(Name = name);
        insert r;
        return r.Id;
    }

    private static Lead seedLead(Id rooftopId, String postalCode) {
        return new Lead(
            LastName = 'P2 Route',
            Company = 'P2 Route Co',
            PostalCode = postalCode,
            Rooftop__c = rooftopId
        );
    }

    @isTest
    static void fsaPrefixClassifier() {
        System.assertEquals(
            'M', LeadRoutingHandler.fsaPrefix('M5V2T6')
        );
        System.assertEquals(
            'L4H', LeadRoutingHandler.fsaPrefix('L4H 1A1')
        );
        System.assertEquals(
            'L5V', LeadRoutingHandler.fsaPrefix('L5V1M5')
        );
        System.assertEquals(
            'L1G', LeadRoutingHandler.fsaPrefix('L1G1A1')
        );
        System.assertEquals(
            'UNROUTED', LeadRoutingHandler.fsaPrefix('K1A0A1')
        );
        System.assertEquals(
            'UNROUTED', LeadRoutingHandler.fsaPrefix(null)
        );
    }

    @isTest
    static void firstLeadGetsRepSecondGetsQueue() {
        resetRouting();
        Id downtown = ensureRooftop('Northgate Downtown');

        Lead first = seedLead(downtown, 'M5V2T6');
        insert first;

        first = [
            SELECT OwnerId, Assigned_Batch__c
            FROM Lead
            WHERE Id = :first.Id
        ];

        System.assertEquals(
            ngrpId,
            first.OwnerId,
            'First lead in lane should be the rep'
        );
        System.assertEquals(
            'M-R1',
            first.Assigned_Batch__c,
            'First slot label'
        );

        Lead second = seedLead(downtown, 'M5V2T6');
        insert second;

        second = [
            SELECT OwnerId, Assigned_Batch__c
            FROM Lead
            WHERE Id = :second.Id
        ];

        System.assertEquals(
            qInboundId,
            second.OwnerId,
            'Second lead in lane should rotate to the queue'
        );
        System.assertEquals(
            'M-R2',
            second.Assigned_Batch__c,
            'Second slot label'
        );

        Lead third = seedLead(downtown, 'M5V2T6');
        insert third;

        third = [
            SELECT OwnerId, Assigned_Batch__c
            FROM Lead
            WHERE Id = :third.Id
        ];

        System.assertEquals(
            ngrpId,
            third.OwnerId,
            'Third lead wraps back to the rep'
        );
        System.assertEquals(
            'M-R1',
            third.Assigned_Batch__c,
            'Third slot label'
        );
    }

    @isTest
    static void lanesAreRooftopScoped() {
        resetRouting();

        Id downtown = ensureRooftop('Northgate Downtown');
        Id north = ensureRooftop('Northgate North');
        Id airport = ensureRooftop('Northgate Airport');
        Id service = ensureRooftop('Northgate Service Centre');

        Lead leadDowntown = seedLead(downtown, 'M5V2T6');
        insert leadDowntown;

        Lead leadNorth = seedLead(north, 'L4H1A1');
        insert leadNorth;

        Lead leadAirport = seedLead(airport, 'L5V1M5');
        insert leadAirport;

        Lead leadService = seedLead(service, 'L1G1A1');
        insert leadService;

        leadDowntown = [
            SELECT Assigned_Batch__c
            FROM Lead
            WHERE Id = :leadDowntown.Id
        ];
        leadNorth = [
            SELECT Assigned_Batch__c
            FROM Lead
            WHERE Id = :leadNorth.Id
        ];
        leadAirport = [
            SELECT Assigned_Batch__c
            FROM Lead
            WHERE Id = :leadAirport.Id
        ];
        leadService = [
            SELECT Assigned_Batch__c
            FROM Lead
            WHERE Id = :leadService.Id
        ];

        System.assertEquals(
            'M-R1', leadDowntown.Assigned_Batch__c
        );
        System.assertEquals(
            'L4H-R1', leadNorth.Assigned_Batch__c
        );
        System.assertEquals(
            'L5V-R1', leadAirport.Assigned_Batch__c
        );
        System.assertEquals(
            'L1G-R1', leadService.Assigned_Batch__c
        );
    }

    @isTest
    static void leadWithNoRooftopIsLeftAlone() {
        resetRouting();

        Lead l = new Lead(
            LastName = 'NoRooftop',
            Company = 'P2 Route Co'
        );
        insert l;

        l = [
            SELECT OwnerId, Assigned_Batch__c, Rooftop__c
            FROM Lead
            WHERE Id = :l.Id
        ];

        System.assertEquals(
            null,
            l.Rooftop__c,
            'Rooftop__c should remain null when trigger runs without it'
        );
        System.assertEquals(
            null,
            l.Assigned_Batch__c,
            'No batch label should be assigned'
        );
    }

    @isTest
    static void unmatchedFsaIsMarkedUnrouted() {
        resetRouting();
        Id downtown = ensureRooftop('Northgate Downtown');

        Lead l = seedLead(downtown, 'K1A0A1');
        insert l;

        l = [
            SELECT OwnerId, Assigned_Batch__c
            FROM Lead
            WHERE Id = :l.Id
        ];

        System.assertEquals(
            qInboundId,
            l.OwnerId,
            'Unmatched FSA falls back to the queue'
        );
        System.assertEquals(
            'UNROUTED', l.Assigned_Batch__c
        );
    }

    @isTest
    static void unmatchedThenMatchedInSameRooftopLeavesMatchedAtR1() {
        resetRouting();
        Id downtown = ensureRooftop('Northgate Downtown');

        Lead unmatched = seedLead(downtown, 'K1A0A1');
        insert unmatched;

        Lead matched = seedLead(downtown, 'M5V2T6');
        insert matched;

        matched = [
            SELECT OwnerId, Assigned_Batch__c
            FROM Lead
            WHERE Id = :matched.Id
        ];

        System.assertEquals(
            ngrpId,
            matched.OwnerId,
            'Matched lead after unmatched must be the rep (slot 1)'
        );
        System.assertEquals(
            'M-R1',
            matched.Assigned_Batch__c,
            'Matched lead after unmatched must be at slot 1'
        );
    }
}