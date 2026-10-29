trigger ConsentTrigger on Consent__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    Automation_Settings__c settings = Automation_Settings__c.getOrgDefaults();
    if (settings != null && settings.Bypass_Triggers__c) return;
    Set<Id> ids = ConsentGateService.consentContacts(Trigger.isDelete ? Trigger.old : Trigger.new, Trigger.oldMap);
    if (Trigger.isBefore) ConsentGateService.lockContacts(ids);
    else ConsentGateService.refreshContacts(ids);
}
