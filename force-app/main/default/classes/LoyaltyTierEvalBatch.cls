public without sharing class LoyaltyTierEvalBatch implements Database.Batchable<SObject>, Schedulable {
    public Database.QueryLocator start(Database.BatchableContext context) {
        LoyaltyLedgerService.Rules rules = new LoyaltyLedgerService.Rules();
        return Database.getQueryLocator([SELECT Id FROM Loyalty_Member__c WHERE Managed_From__c != null AND Status__c = 'Active' WITH SYSTEM_MODE]);
    }
    public void execute(Database.BatchableContext context, List<SObject> scope) {
        LoyaltyLedgerService.evaluateTiers(new Map<Id, SObject>(scope).keySet());
    }
    public void finish(Database.BatchableContext context) {}
    public void execute(SchedulableContext context) { Database.executeBatch(this, 200); }
}
