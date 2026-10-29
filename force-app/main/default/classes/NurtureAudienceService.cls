public with sharing class NurtureAudienceService {
    public class AudiencePage {
        @AuraEnabled public List<Id> memberIds = new List<Id>();
        @AuraEnabled public Id nextId;
        @AuraEnabled public Boolean hasMore = false;
    }
    @AuraEnabled
    public static AudiencePage preview(Id campaignId, Id afterId) {
        if (!FeatureManagement.checkPermission('Preview_Nurture_Audience')) throw new AuraHandledException('Nurture audience permission is required.');
        AudiencePage page = new AudiencePage();
        List<Campaign> campaigns = [SELECT Id, IsActive, Nurture_Managed__c, Consent_Purpose__c, Consent_Channel__c
            FROM Campaign WHERE Id = :campaignId WITH USER_MODE];
        if (campaigns.isEmpty() || !campaigns[0].Nurture_Managed__c || !campaigns[0].IsActive) return page;
        String query = 'SELECT Id, ContactId, CampaignId FROM CampaignMember WHERE CampaignId = :campaignId';
        if (afterId != null) query += ' AND Id > :afterId';
        query += ' WITH USER_MODE ORDER BY Id LIMIT 201';
        List<CampaignMember> candidates = Database.query(query);
        page.hasMore = candidates.size() > 200;
        if (page.hasMore) candidates.remove(200);
        Set<Id> ids = new Set<Id>(); for (CampaignMember member : candidates) if (member.ContactId != null) ids.add(member.ContactId);
        Set<Id> visible = new Map<Id, Contact>([SELECT Id FROM Contact WHERE Id IN :ids WITH USER_MODE]).keySet();
        Map<Id, Boolean> allowed = ConsentGateService.decisions(candidates, new Map<Id, Campaign>(campaigns));
        for (CampaignMember member : candidates) if (visible.contains(member.ContactId) && allowed.get(member.Id) == true) page.memberIds.add(member.Id);
        if (!candidates.isEmpty()) page.nextId = candidates[candidates.size() - 1].Id;
        return page;
    }
}
