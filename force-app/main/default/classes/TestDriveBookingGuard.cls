public with sharing class TestDriveBookingGuard {
    private static final Set<String> BLOCKING_STATUSES = new Set<String>{ 'Requested', 'Scheduled' };

    public static void guard(List<Test_Drive__c> scope) {
        if (scope == null || scope.isEmpty()) {
            return;
        }

        Map<Id, List<Test_Drive__c>> scopeByVehicle = new Map<Id, List<Test_Drive__c>>();
        Set<Id> scopeIds = new Set<Id>();
        Datetime minStart;
        Datetime maxEnd;

        for (Test_Drive__c td : scope) {
            if (td.Id != null) {
                scopeIds.add(td.Id);
            }
            if (td.Vehicle__c == null || td.Scheduled_Start__c == null || td.Scheduled_End__c == null) {
                continue;
            }
            if (!isBlocking(td.Status__c)) {
                continue;
            }
            if (!scopeByVehicle.containsKey(td.Vehicle__c)) {
                scopeByVehicle.put(td.Vehicle__c, new List<Test_Drive__c>());
            }
            scopeByVehicle.get(td.Vehicle__c).add(td);
            if (minStart == null || td.Scheduled_Start__c < minStart) {
                minStart = td.Scheduled_Start__c;
            }
            if (maxEnd == null || td.Scheduled_End__c > maxEnd) {
                maxEnd = td.Scheduled_End__c;
            }
        }

        if (scopeByVehicle.isEmpty()) {
            return;
        }

        for (List<Test_Drive__c> vehicleScope : scopeByVehicle.values()) {
            vehicleScope.sort(new StartComparator());
            for (Integer i = 1; i < vehicleScope.size(); i++) {
                Test_Drive__c previous = vehicleScope[i - 1];
                Test_Drive__c current = vehicleScope[i];
                if (current.Scheduled_Start__c < previous.Scheduled_End__c) {
                    current.addError('That vehicle is already booked for the selected time.');
                }
            }
        }

        List<Test_Drive__c> existing = [
            SELECT Id, Vehicle__c, Scheduled_Start__c, Scheduled_End__c
            FROM Test_Drive__c
            WHERE Vehicle__c IN :scopeByVehicle.keySet()
                AND Status__c IN :BLOCKING_STATUSES
                AND Scheduled_Start__c < :maxEnd
                AND Scheduled_End__c > :minStart
                AND Id NOT IN :scopeIds
        ];
        Map<Id, List<Test_Drive__c>> existingByVehicle = new Map<Id, List<Test_Drive__c>>();
        for (Test_Drive__c row : existing) {
            if (!existingByVehicle.containsKey(row.Vehicle__c)) {
                existingByVehicle.put(row.Vehicle__c, new List<Test_Drive__c>());
            }
            existingByVehicle.get(row.Vehicle__c).add(row);
        }

        for (Id vehicleId : scopeByVehicle.keySet()) {
            if (!existingByVehicle.containsKey(vehicleId)) {
                continue;
            }
            for (Test_Drive__c candidate : scopeByVehicle.get(vehicleId)) {
                for (Test_Drive__c booked : existingByVehicle.get(vehicleId)) {
                    if (candidate.Scheduled_Start__c < booked.Scheduled_End__c
                        && candidate.Scheduled_End__c > booked.Scheduled_Start__c) {
                        candidate.addError('That vehicle is already booked for the selected time.');
                        break;
                    }
                }
            }
        }
    }

    private static Boolean isBlocking(String status) {
        return BLOCKING_STATUSES.contains(status);
    }

    private class StartComparator implements Comparator<Test_Drive__c> {
        public Integer compare(Test_Drive__c a, Test_Drive__c b) {
            if (a.Scheduled_Start__c == b.Scheduled_Start__c) {
                return 0;
            }
            return a.Scheduled_Start__c < b.Scheduled_Start__c ? -1 : 1;
        }
    }
}
