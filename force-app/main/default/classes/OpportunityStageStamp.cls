public with sharing class OpportunityStageStamp {
    public static void stamp(List<Opportunity> scope, Map<Id, Opportunity> oldById) {
        if (scope == null || scope.isEmpty()) {
            return;
        }
        Datetime now = System.now();
        for (Opportunity o : scope) {
            if (oldById == null) {
                o.Stage_Last_Changed__c = now;
                o.Previous_Stage__c = null;
                continue;
            }
            Opportunity old = oldById.get(o.Id);
            if (old != null && o.StageName != old.StageName) {
                o.Previous_Stage__c = old.StageName;
                o.Stage_Last_Changed__c = now;
            }
        }
    }
}
