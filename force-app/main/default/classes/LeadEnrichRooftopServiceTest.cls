@isTest
private class LeadEnrichRooftopServiceTest {
    private static final String DOWNTOWN = 'Northgate Downtown';
    private static final String NORTH = 'Northgate North';
    private static final String AIRPORT = 'Northgate Airport';
    private static final String SERVICE = 'Northgate Service Centre';

    @TestSetup
    static void setup() {
        insert new List<Rooftop__c>{
            new Rooftop__c(Name = DOWNTOWN),
            new Rooftop__c(Name = NORTH),
            new Rooftop__c(Name = AIRPORT),
            new Rooftop__c(Name = SERVICE)
        };
        setBypass(false);
    }

    private static void setBypass(Boolean value) {
        Automation_Settings__c settings = Automation_Settings__c.getOrgDefaults();
        if (settings == null) {
            settings = new Automation_Settings__c(
                SetupOwnerId = UserInfo.getOrganizationId()
            );
        }
        settings.Bypass_Triggers__c = value;
        upsert settings;
    }

    private static Map<String, Id> rooftopIds() {
        Map<String, Id> ids = new Map<String, Id>();
        for (Rooftop__c r : [SELECT Id, Name FROM Rooftop__c]) {
            ids.put(r.Name, r.Id);
        }
        return ids;
    }

    private static Lead makeLead(String postalCode) {
        return new Lead(
            LastName = 'Enrich',
            Company = 'Enrich Co',
            PostalCode = postalCode
        );
    }

    @isTest
    static void blankPostalCodeIsUntouched() {
        LeadEnrichRooftopService.setRouteOverrideForTest(
            new Map<String, String>{ 'M' => DOWNTOWN }
        );
        List<Lead> scope = new List<Lead>{ makeLead(null) };

        LeadEnrichRooftopService.enrich(scope);

        System.assertEquals(null, scope[0].Rooftop__c);
        System.assertEquals(null, scope[0].Assigned_Batch__c);
    }

    @isTest
    static void prefixMRoutesToMappedRooftop() {
        Map<String, Id> ids = rooftopIds();
        LeadEnrichRooftopService.setRouteOverrideForTest(
            new Map<String, String>{ 'M' => DOWNTOWN }
        );
        List<Lead> scope = new List<Lead>{ makeLead('M5V 2T6') };

        LeadEnrichRooftopService.enrich(scope);

        System.assertEquals(ids.get(DOWNTOWN), scope[0].Rooftop__c);
        System.assertEquals(null, scope[0].Assigned_Batch__c);
    }

    @isTest
    static void prefixL4HRoutesToMappedRooftop() {
        Map<String, Id> ids = rooftopIds();
        LeadEnrichRooftopService.setRouteOverrideForTest(
            new Map<String, String>{ 'L4H' => NORTH }
        );
        List<Lead> scope = new List<Lead>{ makeLead('L4H 1A1') };

        LeadEnrichRooftopService.enrich(scope);

        System.assertEquals(ids.get(NORTH), scope[0].Rooftop__c);
        System.assertEquals(null, scope[0].Assigned_Batch__c);
    }

    @isTest
    static void unmatchedPrefixSetsUnroutedWithoutOwner() {
        LeadEnrichRooftopService.setRouteOverrideForTest(
            new Map<String, String>{ 'M' => DOWNTOWN }
        );
        List<Lead> scope = new List<Lead>{ makeLead('K1A 0A1') };

        LeadEnrichRooftopService.enrich(scope);

        System.assertEquals('UNROUTED', scope[0].Assigned_Batch__c);
        System.assertEquals(null, scope[0].Rooftop__c);
        System.assertEquals(null, scope[0].OwnerId);
    }

    @isTest
    static void matchedRouteWithMissingRooftopSetsUnrouted() {
        LeadEnrichRooftopService.setRouteOverrideForTest(
            new Map<String, String>{ 'M' => 'Nonexistent Rooftop' }
        );
        List<Lead> scope = new List<Lead>{ makeLead('M5V 2T6') };

        LeadEnrichRooftopService.enrich(scope);

        System.assertEquals('UNROUTED', scope[0].Assigned_Batch__c);
        System.assertEquals(null, scope[0].Rooftop__c);
    }

    @isTest
    static void bypassSettingSkipsEnrichment() {
        setBypass(true);
        LeadEnrichRooftopService.setRouteOverrideForTest(
            new Map<String, String>{ 'M' => DOWNTOWN }
        );
        List<Lead> scope = new List<Lead>{ makeLead('M5V 2T6') };

        LeadEnrichRooftopService.enrich(scope);

        System.assertEquals(null, scope[0].Rooftop__c);
        System.assertEquals(null, scope[0].Assigned_Batch__c);
    }

    @isTest
    static void bypassOffEnriches() {
        setBypass(false);
        Map<String, Id> ids = rooftopIds();
        LeadEnrichRooftopService.setRouteOverrideForTest(
            new Map<String, String>{ 'M' => DOWNTOWN }
        );
        List<Lead> scope = new List<Lead>{ makeLead('M5V 2T6') };

        LeadEnrichRooftopService.enrich(scope);

        System.assertEquals(ids.get(DOWNTOWN), scope[0].Rooftop__c);
    }

    @isTest
    static void bulkScopeResolvedPerLead() {
        Map<String, Id> ids = rooftopIds();
        LeadEnrichRooftopService.setRouteOverrideForTest(new Map<String, String>{
            'M' => DOWNTOWN,
            'L4H' => NORTH,
            'L5V' => AIRPORT,
            'L1G' => SERVICE
        });
        List<Lead> scope = new List<Lead>();
        for (Integer i = 0; i < 200; i++) {
            Integer bucket = Math.mod(i, 4);
            if (bucket == 0) {
                scope.add(makeLead('M5V 2T6'));
            } else if (bucket == 1) {
                scope.add(makeLead('L4H 1A1'));
            } else if (bucket == 2) {
                scope.add(makeLead('L5V 1M5'));
            } else {
                scope.add(makeLead('L1G 1A1'));
            }
        }

        LeadEnrichRooftopService.enrich(scope);

        System.assertEquals(200, scope.size());
        System.assertEquals(ids.get(DOWNTOWN), scope[0].Rooftop__c);
        System.assertEquals(ids.get(NORTH), scope[1].Rooftop__c);
        System.assertEquals(ids.get(AIRPORT), scope[2].Rooftop__c);
        System.assertEquals(ids.get(SERVICE), scope[3].Rooftop__c);
        System.assertEquals(null, scope[0].Assigned_Batch__c);
    }
}
