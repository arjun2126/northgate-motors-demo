trigger LoyaltyMemberTrigger on Loyalty_Member__c (before insert, before update, before delete) {
    Automation_Settings__c settings = Automation_Settings__c.getOrgDefaults();
    if (settings != null && settings.Bypass_Triggers__c) return;
    LoyaltyLedgerService.guardMembers(Trigger.isDelete ? Trigger.old : Trigger.new, Trigger.oldMap, Trigger.isDelete);
}
