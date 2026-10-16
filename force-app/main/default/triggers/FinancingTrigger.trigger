trigger FinancingTrigger on Financing__c (before insert, before update) {
    Automation_Settings__c settings = Automation_Settings__c.getOrgDefaults();
    if (settings != null && settings.Bypass_Triggers__c == true) {
        return;
    }
    FinancingStatusService.enforce(Trigger.new, Trigger.oldMap);
}
