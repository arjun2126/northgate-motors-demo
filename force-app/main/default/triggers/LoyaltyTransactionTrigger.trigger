trigger LoyaltyTransactionTrigger on Loyalty_Transaction__c (before insert, before update, before delete, after undelete) {
    Automation_Settings__c settings = Automation_Settings__c.getOrgDefaults();
    if (settings != null && settings.Bypass_Triggers__c) return;
    LoyaltyLedgerService.guardTransactions(Trigger.isDelete ? Trigger.old : Trigger.new, Trigger.oldMap);
}
