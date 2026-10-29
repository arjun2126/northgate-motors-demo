trigger CampaignMemberConsentTrigger on CampaignMember (before insert, before update) {
    Automation_Settings__c settings = Automation_Settings__c.getOrgDefaults();
    if (settings != null && settings.Bypass_Triggers__c) return;
    ConsentGateService.gateMembers(Trigger.new, Trigger.oldMap);
}
