trigger QuoteTrigger on Quote (before insert) {
    Automation_Settings__c settings = Automation_Settings__c.getOrgDefaults();
    if (settings != null && settings.Bypass_Triggers__c == true) {
        return;
    }
    QuoteTradeInGuard.guard(Trigger.new);
}