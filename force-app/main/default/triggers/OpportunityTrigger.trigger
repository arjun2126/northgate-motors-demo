trigger OpportunityTrigger on Opportunity (before insert, before update) {
    Automation_Settings__c settings = Automation_Settings__c.getOrgDefaults();
    if (settings != null && settings.Bypass_Triggers__c == true) {
        return;
    }
    OpportunityStageStamp.stamp(Trigger.new, Trigger.oldMap);
}
