public with sharing class LeadRoutingHandler {
    private static final Map<String, List<String>> LANE_BY_ROOFTOP = new Map<String, List<String>>{
        'Northgate Downtown' => new List<String>(),
        'Northgate North' => new List<String>(),
        'Northgate Airport' => new List<String>(),
        'Northgate Service Centre' => new List<String>()
    };

    // Production lane resolution: rooftop name -> (sales role, queue).
    // Matches the approved per-rooftop lane table; resolved live so no IDs are
    // hard-coded. Test seam configureLanes() takes precedence when populated.
    private static final Map<String, List<String>> ROLE_QUEUE_BY_ROOFTOP = new Map<String, List<String>>{
        'Northgate Downtown' => new List<String>{ 'Sales_Rep', 'Q_Inbound_Leads' },
        'Northgate North' => new List<String>{ 'Sales_Rep', 'Q_Inbound_Leads' },
        'Northgate Airport' => new List<String>{ 'Sales_Rep', 'Q_Inbound_Leads' },
        'Northgate Service Centre' => new List<String>{ 'Service_Advisor', 'Q_Service_Intake' }
    };

    private static Boolean inFlight = false;

    public static void configureLanes(String rooftopName, String userId, String queueId) {
        List<String> lane = LANE_BY_ROOFTOP.containsKey(rooftopName) ? LANE_BY_ROOFTOP.get(rooftopName) : new List<String>();
        if (userId != null) {
            lane.add(userId);
        }
        if (queueId != null) {
            lane.add(queueId);
        }
        LANE_BY_ROOFTOP.put(rooftopName, lane);
    }

    private static List<String> resolveLane(String rooftopName) {
        List<String> lane = LANE_BY_ROOFTOP.get(rooftopName);
        if (lane != null && !lane.isEmpty()) {
            return lane;
        }
        List<String> spec = ROLE_QUEUE_BY_ROOFTOP.get(rooftopName);
        if (spec == null) {
            return new List<String>();
        }
        lane = new List<String>();
        List<User> users = [
            SELECT Id FROM User
            WHERE IsActive = true AND UserRole.DeveloperName = :spec[0]
            ORDER BY Username LIMIT 1
        ];
        if (!users.isEmpty()) {
            lane.add(users[0].Id);
        }
        List<Group> queues = [
            SELECT Id FROM Group
            WHERE Type = 'Queue' AND DeveloperName = :spec[1]
            LIMIT 1
        ];
        if (!queues.isEmpty()) {
            lane.add(queues[0].Id);
        }
        return lane;
    }

    public static String fsaPrefix(String postalCode) {
        if (String.isBlank(postalCode)) {
            return 'UNROUTED';
        }
        String cleaned = postalCode.replaceAll('\\s+', '');
        if (cleaned.length() == 0) {
            return 'UNROUTED';
        }
        if (cleaned.substring(0, 1) == 'M') {
            return 'M';
        }
        if (cleaned.substring(0, 1) == 'L' && cleaned.length() >= 3) {
            return cleaned.substring(0, 3);
        }
        return 'UNROUTED';
    }

    public static void onAfter(List<Lead> scope, Map<Id, Lead> oldMap) {
        if (inFlight) {
            return;
        }
        if (scope == null || scope.isEmpty()) {
            return;
        }
        Set<Id> rooftopIds = new Set<Id>();
        for (Lead l : scope) {
            if (l.Rooftop__c != null) {
                rooftopIds.add(l.Rooftop__c);
            }
        }
        if (rooftopIds.isEmpty()) {
            return;
        }
        Map<Id, String> rooftopNames = new Map<Id, String>();
        for (Rooftop__c r : [SELECT Id, Name FROM Rooftop__c WHERE Id IN :rooftopIds]) {
            rooftopNames.put(r.Id, r.Name);
        }
        List<Lead> toUpdate = new List<Lead>();
        for (Lead l : scope) {
            if (oldMap != null) {
                Lead old = oldMap.get(l.Id);
                if (old != null && old.Assigned_Batch__c == l.Assigned_Batch__c) {
                    continue;
                }
            }
            if (l.Rooftop__c == null) {
                continue;
            }
            String rooftopName = rooftopNames.get(l.Rooftop__c);
            if (rooftopName == null) {
                continue;
            }
            List<String> lane = resolveLane(rooftopName);
            if (lane.isEmpty()) {
                continue;
            }
            String prefix = fsaPrefix(l.PostalCode);
            if (prefix == 'UNROUTED') {
                // Use the rooftop's configured fallback queue (second lane entry).
                // Bypass nextSlot so the unmatched lead does not consume a slot
                // for the matched rooftop's prefix counter.
                String fallbackQueue = lane.size() > 1 ? lane[1] : lane[0];
                Lead updateLead = new Lead(Id = l.Id, OwnerId = fallbackQueue, Assigned_Batch__c = 'UNROUTED');
                toUpdate.add(updateLead);
                continue;
            }
            LeadRoundRobinRequest req = new LeadRoundRobinRequest();
            req.fsaPrefix = prefix;
            req.ownerIds = lane;
            List<LeadRoundRobinResponse> res = LeadRoundRobin.nextSlot(new List<LeadRoundRobinRequest>{ req });
            if (res.isEmpty()) {
                continue;
            }
            LeadRoundRobinResponse slot = res[0];
            Lead updateLead = new Lead(Id = l.Id, OwnerId = slot.ownerId, Assigned_Batch__c = slot.batch);
            toUpdate.add(updateLead);
        }
        if (toUpdate.isEmpty()) {
            return;
        }
        inFlight = true;
        try {
            update toUpdate;
        } finally {
            inFlight = false;
        }
    }
}