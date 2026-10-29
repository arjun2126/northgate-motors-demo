trigger ContactConsentTrigger on Contact (after update) {
    Automation_Settings__c settings = Automation_Settings__c.getOrgDefaults();
    if (settings != null && settings.Bypass_Triggers__c) return;
    Set<Id> ids = new Set<Id>();
    for (Contact row : Trigger.new) if (row.HasOptedOutOfEmail != Trigger.oldMap.get(row.Id).HasOptedOutOfEmail) ids.add(row.Id);
    ConsentGateService.refreshContacts(ids);
}
