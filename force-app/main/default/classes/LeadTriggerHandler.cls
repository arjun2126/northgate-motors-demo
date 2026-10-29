public without sharing class LeadTriggerHandler {
    public static void run() {
        Automation_Settings__c settings = Automation_Settings__c.getOrgDefaults();
        if (settings != null && settings.Bypass_Triggers__c == true) return;
        List<Lead> rows = (List<Lead>) Trigger.new;
        Map<Id, Lead> oldRows = (Map<Id, Lead>) Trigger.oldMap;
        if (Trigger.isBefore) {
            beforeUpdate(rows, oldRows);
        } else {
            LeadRoutingHandler.onAfter(rows, oldRows);
            if (Trigger.isUpdate) clearConvertedSeedTags(rows, oldRows);
        }
    }

    @TestVisible private static void beforeUpdate(List<Lead> rows, Map<Id, Lead> oldRows) {
        for (Lead row : rows) {
            Lead old = oldRows.get(row.Id);
            if (old != null && row.IsConverted == true && old.IsConverted == false
                && row.ConvertedAccountId == null) {
                row.addError('Convert with an Account selected. The converted Account, Contact and Opportunity will be created.');
            }
        }
    }

    @TestVisible private static void clearConvertedSeedTags(List<Lead> rows, Map<Id, Lead> oldRows) {
        Set<Id> contacts = new Set<Id>();
        Set<Id> accounts = new Set<Id>();
        Set<Id> opportunities = new Set<Id>();
        for (Lead row : rows) {
            Lead old = oldRows.get(row.Id);
            if (old == null || row.IsConverted != true || old.IsConverted != false) continue;
            if (row.ConvertedContactId != null) contacts.add(row.ConvertedContactId);
            if (row.ConvertedAccountId != null) accounts.add(row.ConvertedAccountId);
            if (row.ConvertedOpportunityId != null) opportunities.add(row.ConvertedOpportunityId);
        }
        if (contacts.isEmpty() && accounts.isEmpty() && opportunities.isEmpty()) return;
        // Preserve the former trigger-owned seed cleanup context; this is not a user-facing API.
        List<Contact> contactUpdates = [SELECT Id, Seed_Tag__c FROM Contact WHERE Id IN :contacts AND Seed_Tag__c != null];
        List<Account> accountUpdates = [SELECT Id, Seed_Tag__c FROM Account WHERE Id IN :accounts AND Seed_Tag__c != null];
        List<Opportunity> opportunityUpdates = [SELECT Id, Seed_Tag__c FROM Opportunity WHERE Id IN :opportunities AND Seed_Tag__c != null];
        for (Contact row : contactUpdates) row.Seed_Tag__c = null;
        for (Account row : accountUpdates) row.Seed_Tag__c = null;
        for (Opportunity row : opportunityUpdates) row.Seed_Tag__c = null;
        if (!contactUpdates.isEmpty()) update contactUpdates;
        if (!accountUpdates.isEmpty()) update accountUpdates;
        if (!opportunityUpdates.isEmpty()) update opportunityUpdates;
    }
}
