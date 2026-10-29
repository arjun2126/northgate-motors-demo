public with sharing class QuoteTradeInGuard {
    public static void guard(List<Quote> scope) {
        if (scope == null || scope.isEmpty()) {
            return;
        }
        if (FeatureManagement.checkPermission('Bypass_Automation')) {
            return;
        }
        Set<Id> oppIds = new Set<Id>();
        for (Quote q : scope) {
            if (q.OpportunityId != null) {
                oppIds.add(q.OpportunityId);
            }
        }
        if (oppIds.isEmpty()) {
            return;
        }
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([
            SELECT Id, Has_Trade_In__c
            FROM Opportunity
            WHERE Id IN :oppIds
        ]);
        Set<Id> tradeInRequiredOppIds = new Set<Id>();
        for (Opportunity opp : oppMap.values()) {
            if (opp.Has_Trade_In__c == true) {
                tradeInRequiredOppIds.add(opp.Id);
            }
        }
        if (tradeInRequiredOppIds.isEmpty()) {
            return;
        }
        Map<Id, Trade_In__c> acceptedByOpp = new Map<Id, Trade_In__c>();
        for (Trade_In__c ti : [
            SELECT Opportunity__c
            FROM Trade_In__c
            WHERE Opportunity__c IN :tradeInRequiredOppIds
              AND Status__c = 'Accepted'
        ]) {
            if (!acceptedByOpp.containsKey(ti.Opportunity__c)) {
                acceptedByOpp.put(ti.Opportunity__c, ti);
            }
        }
        for (Quote q : scope) {
            if (tradeInRequiredOppIds.contains(q.OpportunityId)
                && !acceptedByOpp.containsKey(q.OpportunityId)) {
                q.addError('Trade-in must be Accepted before creating a Quote.');
            }
        }
    }
}