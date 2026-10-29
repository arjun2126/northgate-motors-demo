public without sharing class ServiceVisitCapacityGuard {
    private static final Set<String> CONSUMING_STATUSES = new Set<String>{
        'Requested', 'Scheduled', 'Checked_In', 'In_Progress'
    };
    private static final String DEALERSHIP_TIME_ZONE = 'America/Toronto';
    private static final String CAPACITY_ERROR = 'Service capacity is unavailable for this rooftop and day.';

    public static void validate(List<Service_Visit__c> visits, Map<Id, Service_Visit__c> oldById) {
        if (visits == null || visits.isEmpty()) {
            return;
        }

        Set<Id> scopeIds = new Set<Id>();
        Set<Id> rooftopIds = new Set<Id>();
        Date minDay;
        Date maxDay;
        Boolean hasIncrease = false;
        for (Service_Visit__c visit : visits) {
            if (visit.Id != null) {
                scopeIds.add(visit.Id);
            }
            Service_Visit__c oldVisit = oldById == null ? null : oldById.get(visit.Id);
            if (needsCapacityCheck(visit, oldVisit)) {
                hasIncrease = true;
                if (visit.Rooftop__c == null || visit.Scheduled_Start__c == null) {
                    visit.addError('Rooftop__c', CAPACITY_ERROR);
                }
            }
            if (reservationKey(visit) == reservationKey(oldVisit)) {
                continue;
            }
            // Lock both ends of moves and every contributing release, not only destinations.
            for (Service_Visit__c state : new List<Service_Visit__c>{oldVisit, visit}) {
                if (reservationKey(state) != null) {
                    rooftopIds.add(state.Rooftop__c);
                    Date day = localDay(state.Scheduled_Start__c);
                    minDay = minDay == null || day < minDay ? day : minDay;
                    maxDay = maxDay == null || day > maxDay ? day : maxDay;
                }
            }
        }
        if (!hasIncrease || rooftopIds.isEmpty()) {
            return;
        }

        Map<Id, Rooftop__c> rooftops = loadRooftops(rooftopIds);
        Datetime windowStart = localMidnight(minDay);
        Datetime windowEnd = localMidnight(maxDay.addDays(1));
        Map<String, Integer> counts = new Map<String, Integer>();
        for (Service_Visit__c row : [
            SELECT Id, Rooftop__c, Scheduled_Start__c, Status__c
            FROM Service_Visit__c
            WHERE Rooftop__c IN :rooftopIds
                AND Status__c IN :CONSUMING_STATUSES
                AND Scheduled_Start__c >= :windowStart
                AND Scheduled_Start__c < :windowEnd
                AND Id NOT IN :scopeIds
            WITH SYSTEM_MODE
        ]) {
            increment(counts, bucket(row.Rooftop__c, localDay(row.Scheduled_Start__c)));
        }

        List<Service_Visit__c> candidates = new List<Service_Visit__c>();
        for (Service_Visit__c visit : visits) {
            Service_Visit__c oldVisit = oldById == null ? null : oldById.get(visit.Id);
            if (needsCapacityCheck(visit, oldVisit) && !visit.hasErrors()) {
                Rooftop__c rooftop = rooftops.get(visit.Rooftop__c);
                if (rooftop == null || rooftop.Service_Capacity__c == null || rooftop.Service_Capacity__c <= 0) {
                    visit.addError('Rooftop__c', CAPACITY_ERROR);
                } else {
                    candidates.add(visit);
                }
            }
            increment(counts, reservationKey(visit.hasErrors() ? oldVisit : visit));
        }

        // Reject every increase into an overloaded bucket; never pick a winner by input order.
        // Restoring rejected moves can overload their sources, so reject dependent moves to a fixed point.
        // No static cache: partial-save retries recount failed rows from their persisted old state.
        while (true) {
            List<Service_Visit__c> rejected = new List<Service_Visit__c>();
            for (Service_Visit__c visit : candidates) {
                if (!visit.hasErrors() && counts.get(reservationKey(visit)) > rooftops.get(visit.Rooftop__c).Service_Capacity__c) {
                    rejected.add(visit);
                }
            }
            if (rejected.isEmpty()) {
                break;
            }
            for (Service_Visit__c visit : rejected) {
                visit.addError('Scheduled_Start__c', CAPACITY_ERROR);
                decrement(counts, reservationKey(visit));
                increment(counts, reservationKey(oldById == null ? null : oldById.get(visit.Id)));
            }
        }
    }

    private static Boolean needsCapacityCheck(Service_Visit__c visit, Service_Visit__c oldVisit) {
        if (!isConsuming(visit)) {
            return false;
        }
        if (!isConsuming(oldVisit)) {
            return true;
        }
        return visit.Rooftop__c != oldVisit.Rooftop__c
            || visit.Scheduled_Start__c == null || oldVisit.Scheduled_Start__c == null
            || localDay(visit.Scheduled_Start__c) != localDay(oldVisit.Scheduled_Start__c);
    }

    private static Boolean isConsuming(Service_Visit__c visit) {
        return visit != null && CONSUMING_STATUSES.contains(visit.Status__c);
    }

    private static String bucket(Id rooftopId, Date day) {
        return String.valueOf(rooftopId) + ':' + String.valueOf(day);
    }

    private static String reservationKey(Service_Visit__c visit) {
        return isConsuming(visit) && visit.Rooftop__c != null && visit.Scheduled_Start__c != null
            ? bucket(visit.Rooftop__c, localDay(visit.Scheduled_Start__c)) : null;
    }

    private static void increment(Map<String, Integer> counts, String key) {
        if (key != null) {
            counts.put(key, (counts.containsKey(key) ? counts.get(key) : 0) + 1);
        }
    }

    private static void decrement(Map<String, Integer> counts, String key) {
        if (key != null) {
            counts.put(key, counts.get(key) - 1);
        }
    }

    @TestVisible private static Date localDay(Datetime value) {
        return Date.valueOf(value.format('yyyy-MM-dd', DEALERSHIP_TIME_ZONE));
    }

    @TestVisible private static Map<Id, Rooftop__c> loadRooftops(Set<Id> rooftopIds) {
        return new Map<Id, Rooftop__c>([
            SELECT Id, Service_Capacity__c
            FROM Rooftop__c
            WHERE Id IN :rooftopIds
            WITH SYSTEM_MODE
            FOR UPDATE
        ]);
    }

    @TestVisible private static Datetime localMidnight(Date day) {
        Datetime approximateUtc = Datetime.newInstanceGmt(day, Time.newInstance(0, 0, 0, 0));
        return approximateUtc.addSeconds(-TimeZone.getTimeZone(DEALERSHIP_TIME_ZONE).getOffset(approximateUtc) / 1000);
    }
}
