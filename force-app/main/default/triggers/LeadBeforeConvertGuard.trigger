trigger LeadBeforeConvertGuard on Lead (before update) {
    Automation_Settings__c settings = Automation_Settings__c.getOrgDefaults();
    if (settings != null && settings.Bypass_Triggers__c == true) {
        return;
    }
    for (Lead l : Trigger.new) {
        Lead old = Trigger.oldMap.get(l.Id);
        if (old == null) {
            continue;
        }
        if (l.IsConverted == true && old.IsConverted == false) {
            if (l.ConvertedAccountId == null) {
                l.addError('Convert with an Account selected. The converted Account, Contact and Opportunity will be created.');
            }
        }
    }
}
