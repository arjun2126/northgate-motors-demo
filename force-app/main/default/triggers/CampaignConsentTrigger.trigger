trigger CampaignConsentTrigger on Campaign (before insert, before update, after update) {
    Automation_Settings__c settings = Automation_Settings__c.getOrgDefaults();
    if (settings != null && settings.Bypass_Triggers__c) return;
    if (Trigger.isBefore) ConsentGateService.validateCampaigns(Trigger.new);
    else {
        Set<Id> ids = new Set<Id>();
        for (Campaign row : Trigger.new) {
            Campaign old = Trigger.oldMap.get(row.Id);
            if ((row.Nurture_Managed__c || old.Nurture_Managed__c) && (row.Nurture_Managed__c != old.Nurture_Managed__c
                || row.Consent_Purpose__c != old.Consent_Purpose__c || row.Consent_Channel__c != old.Consent_Channel__c || row.IsActive != old.IsActive)) ids.add(row.Id);
        }
        ConsentGateService.refreshCampaigns(ids);
    }
}
