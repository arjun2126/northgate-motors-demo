trigger CaseMilestoneTrigger on Case (after update) {
    Automation_Settings__c settings = Automation_Settings__c.getOrgDefaults();
    if (settings != null && settings.Bypass_Triggers__c) return;
    CaseMilestoneService.complete(Trigger.new, Trigger.oldMap);
}
