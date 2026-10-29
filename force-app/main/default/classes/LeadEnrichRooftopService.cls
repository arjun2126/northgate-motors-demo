public with sharing class LeadEnrichRooftopService {
    @TestVisible
    private static Map<String, String> routeOverride;

    @TestVisible
    static void setRouteOverrideForTest(Map<String, String> routesByPrefix) {
        routeOverride = routesByPrefix;
    }

    public static void enrich(List<Lead> scope) {
        if (scope == null || scope.isEmpty()) {
            return;
        }
        if (isBypassed()) {
            return;
        }

        Set<String> prefixes = new Set<String>();
        for (Lead l : scope) {
            if (l.PostalCode == null) {
                continue;
            }
            prefixes.add(LeadRoutingHandler.fsaPrefix(l.PostalCode));
        }
        if (prefixes.isEmpty()) {
            return;
        }

        Map<String, String> rooftopNameByPrefix = routeOverride != null
            ? routeOverride
            : queryRooftopNameByPrefix(prefixes);

        Set<String> rooftopNames = new Set<String>();
        for (String prefix : prefixes) {
            String name = rooftopNameByPrefix.get(prefix);
            if (name != null) {
                rooftopNames.add(name);
            }
        }
        Map<String, Id> rooftopIdByName = rooftopNames.isEmpty()
            ? new Map<String, Id>()
            : queryRooftopIdByName(rooftopNames);

        for (Lead l : scope) {
            if (l.PostalCode == null) {
                continue;
            }
            String prefix = LeadRoutingHandler.fsaPrefix(l.PostalCode);
            String name = rooftopNameByPrefix.get(prefix);
            Id rooftopId = name == null ? null : rooftopIdByName.get(name);
            if (rooftopId != null) {
                l.Rooftop__c = rooftopId;
            } else {
                l.Assigned_Batch__c = 'UNROUTED';
            }
        }
    }

    private static Boolean isBypassed() {
        Automation_Settings__c settings = Automation_Settings__c.getOrgDefaults();
        return settings != null && settings.Bypass_Triggers__c == true;
    }

    private static Map<String, String> queryRooftopNameByPrefix(Set<String> prefixes) {
        Map<String, String> names = new Map<String, String>();
        for (Lead_Routing__mdt route : [
            SELECT FSA_Prefix__c, Rooftop__c
            FROM Lead_Routing__mdt
            WHERE FSA_Prefix__c IN :prefixes AND Is_Active__c = true
        ]) {
            if (!names.containsKey(route.FSA_Prefix__c)) {
                names.put(route.FSA_Prefix__c, route.Rooftop__c);
            }
        }
        return names;
    }

    private static Map<String, Id> queryRooftopIdByName(Set<String> names) {
        Map<String, Id> ids = new Map<String, Id>();
        for (Rooftop__c r : [
            SELECT Id, Name
            FROM Rooftop__c
            WHERE Name IN :names
        ]) {
            ids.put(r.Name, r.Id);
        }
        return ids;
    }
}
