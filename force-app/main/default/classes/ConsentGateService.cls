public without sharing class ConsentGateService {
    public static void lockContacts(Set<Id> ids) {
        List<Contact> locked = [SELECT Id FROM Contact WHERE Id IN :ids WITH SYSTEM_MODE FOR UPDATE];
    }
    public static Set<Id> consentContacts(List<Consent__c> rows, Map<Id, Consent__c> oldRows) {
        Set<Id> ids = new Set<Id>();
        for (Consent__c row : rows) {
            if (row.Contact__c != null) ids.add(row.Contact__c);
            if (oldRows != null && oldRows.containsKey(row.Id)) ids.add(oldRows.get(row.Id).Contact__c);
        }
        return ids;
    }
    public static Date today() { return Date.valueOf(Datetime.now().format('yyyy-MM-dd', 'America/Toronto')); }
    private static String tuple(Id id, String purpose, String channel) {
        return String.valueOf(id) + ':' + purpose + ':' + channel;
    }
    public static Map<Id, Boolean> decisions(List<CampaignMember> members, Map<Id, Campaign> campaigns) {
        Map<String, Boolean> evaluated = evaluate(members, campaigns);
        Map<Id, Boolean> result = new Map<Id, Boolean>();
        for (CampaignMember member : members) {
            result.put(member.Id, evaluated.get(tuple(member.ContactId, String.valueOf(member.CampaignId), 'member')));
        }
        return result;
    }
    public static void gateMembers(List<CampaignMember> rows, Map<Id, CampaignMember> oldRows) {
        Set<Id> campaignIds = new Set<Id>(); Set<Id> contacts = new Set<Id>();
        for (CampaignMember row : rows) { campaignIds.add(row.CampaignId); if (row.ContactId != null) contacts.add(row.ContactId); }
        Map<Id, Campaign> campaigns = new Map<Id, Campaign>([
            SELECT Id, IsActive, Nurture_Managed__c, Consent_Purpose__c, Consent_Channel__c
            FROM Campaign WHERE Id IN :campaignIds WITH SYSTEM_MODE
        ]);
        Boolean managed = false;
        for (Campaign campaign : campaigns.values()) if (campaign.Nurture_Managed__c) managed = true;
        for (CampaignMember row : rows) if (oldRows != null && oldRows.get(row.Id).Consent_Managed__c) managed = true;
        if (!managed) {
            for (CampaignMember row : rows) { row.Consent_Managed__c = false; row.Nurture_Eligible__c = false; }
            return;
        }
        lockContacts(contacts);
        // New members have no Id; assign no synthetic IDs or persisted diagnostic records.
        Map<String, Boolean> allowedByTuple = evaluate(rows, campaigns);
        for (CampaignMember row : rows) {
            Campaign campaign = campaigns.get(row.CampaignId);
            CampaignMember old = oldRows == null ? null : oldRows.get(row.Id);
            Boolean scoped = (campaign != null && campaign.Nurture_Managed__c) || (old != null && old.Consent_Managed__c);
            row.Consent_Managed__c = scoped;
            row.Nurture_Eligible__c = scoped && allowedByTuple.get(tuple(row.ContactId, String.valueOf(row.CampaignId), 'member')) == true;
            if (scoped && old == null && !row.Nurture_Eligible__c) {
                row.addError('A current matching consent grant is required for managed campaign membership.');
            }
        }
    }
    private static Map<String, Boolean> evaluate(List<CampaignMember> rows, Map<Id, Campaign> campaigns) {
        Set<Id> contactIds = new Set<Id>();
        for (CampaignMember row : rows) if (row.ContactId != null) contactIds.add(row.ContactId);
        Map<Id, Contact> contacts = new Map<Id, Contact>([SELECT Id, HasOptedOutOfEmail FROM Contact WHERE Id IN :contactIds WITH SYSTEM_MODE]);
        Set<String> grants = new Set<String>(); Set<String> denies = new Set<String>(); Date asOf = today();
        for (Consent__c consent : [SELECT Contact__c, Purpose__c, Channel__c, Status__c, Granted_On__c, Revoked_On__c
            FROM Consent__c WHERE Contact__c IN :contactIds WITH SYSTEM_MODE]) {
            String key = tuple(consent.Contact__c, consent.Purpose__c, consent.Channel__c);
            if (consent.Status__c == 'Granted' && consent.Granted_On__c != null && consent.Granted_On__c <= asOf && consent.Revoked_On__c == null) grants.add(key);
            else denies.add(key);
        }
        Map<String, Boolean> result = new Map<String, Boolean>();
        for (CampaignMember row : rows) {
            Campaign campaign = campaigns.get(row.CampaignId);
            String key = campaign == null ? null : tuple(row.ContactId, campaign.Consent_Purpose__c, campaign.Consent_Channel__c);
            Boolean allowed = campaign != null && campaign.Nurture_Managed__c && campaign.IsActive
                && contacts.containsKey(row.ContactId) && grants.contains(key) && !denies.contains(key)
                && (campaign.Consent_Channel__c != 'Email' || !contacts.get(row.ContactId).HasOptedOutOfEmail);
            result.put(tuple(row.ContactId, String.valueOf(row.CampaignId), 'member'), allowed);
        }
        return result;
    }
    public static void refreshContacts(Set<Id> ids) {
        if (ids.isEmpty()) return;
        lockContacts(ids);
        refresh([SELECT Id FROM CampaignMember WHERE ContactId IN :ids
            AND (Campaign.Nurture_Managed__c = true OR Consent_Managed__c = true) WITH SYSTEM_MODE]);
    }
    public static void refreshCampaigns(Set<Id> ids) {
        if (!ids.isEmpty()) refresh([SELECT Id FROM CampaignMember WHERE CampaignId IN :ids WITH SYSTEM_MODE]);
    }
    private static void refresh(List<CampaignMember> rows) {
        if (rows.isEmpty()) return;
        update as system rows;
    }
    public static void validateCampaigns(List<Campaign> rows) {
        Set<String> purposes = new Set<String>{'Marketing','Loyalty','Service_Notices','Recall_Alerts'};
        Set<String> channels = new Set<String>{'Email','SMS','Phone','Mail'};
        for (Campaign row : rows) if (row.Nurture_Managed__c
            && (!purposes.contains(row.Consent_Purpose__c) || !channels.contains(row.Consent_Channel__c))) {
            row.addError('Managed campaigns require an explicit supported consent purpose and channel.');
        }
    }
}
