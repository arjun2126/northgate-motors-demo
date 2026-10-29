public without sharing class LoyaltyAccrualBatch implements Database.Batchable<SObject> {
    private String kind;
    public LoyaltyAccrualBatch(String kind) { this.kind = kind; }
    public Database.QueryLocator start(Database.BatchableContext context) {
        Datetime boundary = new LoyaltyLedgerService.Rules().program.Eligible_From__c;
        if (kind == 'Service') return Database.getQueryLocator([
            SELECT Id FROM Service_Visit__c WHERE CreatedDate >= :boundary AND Status__c = 'Completed']);
        if (kind == 'Sale') return Database.getQueryLocator([
            SELECT Id FROM Delivery__c WHERE CreatedDate >= :boundary AND Status__c = 'Completed']);
        throw new LoyaltyLedgerService.LoyaltyException('Unsupported loyalty source type.');
    }
    public void execute(Database.BatchableContext context, List<SObject> scope) {
        LoyaltyAccrualService.process(kind, new Map<Id, SObject>(scope).keySet());
    }
    public void finish(Database.BatchableContext context) {}
}
