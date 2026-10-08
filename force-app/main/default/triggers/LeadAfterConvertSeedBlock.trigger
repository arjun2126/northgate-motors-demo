trigger LeadAfterConvertSeedBlock on Lead (after update) {
    Automation_Settings__c settings = Automation_Settings__c.getOrgDefaults();
    if (settings != null && settings.Bypass_Triggers__c == true) {
        return;
    }
    Map<Id, Lead> converted = new Map<Id, Lead>();
    for (Lead l : Trigger.new) {
        Lead old = Trigger.oldMap.get(l.Id);
        if (old == null) { continue; }
        if (l.IsConverted == true && old.IsConverted == false) {
            converted.put(l.Id, l);
        }
    }
    if (converted.isEmpty()) {
        return;
    }
    Set<Id> contactIds = new Set<Id>();
    Set<Id> accountIds = new Set<Id>();
    Set<Id> opportunityIds = new Set<Id>();
    for (Lead l : converted.values()) {
        if (l.ConvertedContactId != null) { contactIds.add(l.ConvertedContactId); }
        if (l.ConvertedAccountId != null) { accountIds.add(l.ConvertedAccountId); }
        if (l.ConvertedOpportunityId != null) { opportunityIds.add(l.ConvertedOpportunityId); }
    }
    List<Contact> contacts = [SELECT Id, Seed_Tag__c FROM Contact WHERE Id IN :contactIds AND Seed_Tag__c != null];
    for (Contact c : contacts) { c.Seed_Tag__c = null; update c; }
    List<Account> accounts = [SELECT Id, Seed_Tag__c FROM Account WHERE Id IN :accountIds AND Seed_Tag__c != null];
    for (Account a : accounts) { a.Seed_Tag__c = null; update a; }
    List<Opportunity> opportunities = [SELECT Id, Seed_Tag__c FROM Opportunity WHERE Id IN :opportunityIds AND Seed_Tag__c != null];
    for (Opportunity o : opportunities) { o.Seed_Tag__c = null; update o; }
}
