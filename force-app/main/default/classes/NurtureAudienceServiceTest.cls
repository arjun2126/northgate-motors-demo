@isTest
private class NurtureAudienceServiceTest {
    @TestSetup static void actors() {
        Batch3TestData.actor('Audience reader', new List<String>{'PS_Nurture_Audience'}, null);
        Batch3TestData.actor('Audience denied', new List<String>(), null);
    }
    @isTest static void previewRechecksConsentAndFiltersHiddenContactsWithoutSending() {
        User actor = [SELECT Id FROM User WHERE LastName = 'Audience reader' LIMIT 1];
        List<Contact> contacts = Batch3TestData.contacts(2);
        contacts[0].OwnerId = actor.Id; update contacts[0];
        List<Consent__c> grants = Batch3TestData.grants(contacts);
        Campaign campaign = Batch3TestData.campaign(true); campaign.OwnerId = actor.Id; update as system campaign;
        List<CampaignMember> rows = new List<CampaignMember>();
        for (Contact contact : contacts) rows.add(new CampaignMember(CampaignId = campaign.Id, ContactId = contact.Id));
        insert as system rows;
        System.runAs(actor) {
            System.assert(!FeatureManagement.checkPermission('Bypass_Automation'));
            System.assert(!Schema.SObjectType.Consent__c.isAccessible(), 'Raw consent access is not granted.');
            NurtureAudienceService.AudiencePage page = NurtureAudienceService.preview(campaign.Id, null);
            System.assertEquals(new List<Id>{rows[0].Id}, page.memberIds);
            System.assert(!page.hasMore);
            System.assertEquals(0, NurtureAudienceService.preview(campaign.Id, page.nextId).memberIds.size());
        }
        grants[0].Status__c = 'Revoked'; grants[0].Revoked_On__c = ConsentGateService.today(); update as system grants[0];
        System.runAs(actor) { System.assertEquals(0, NurtureAudienceService.preview(campaign.Id, null).memberIds.size()); }
        System.assertEquals(0, Limits.getEmailInvocations());
    }
    @isTest static void unauthorizedActorCannotPreviewAndUnmanagedCampaignIsEmpty() {
        Campaign campaign = Batch3TestData.campaign(false);
        User denied = [SELECT Id FROM User WHERE LastName = 'Audience denied' LIMIT 1];
        System.runAs(denied) {
            Boolean rejected = false;
            try { NurtureAudienceService.preview(campaign.Id, null); } catch (AuraHandledException expected) { rejected = true; }
            System.assert(rejected);
        }
        User reader = [SELECT Id FROM User WHERE LastName = 'Audience reader' LIMIT 1];
        campaign.OwnerId = reader.Id; update as system campaign;
        System.runAs(reader) { System.assertEquals(0, NurtureAudienceService.preview(campaign.Id, null).memberIds.size()); }
    }
    @isTest static void paginationPreservesAllMembersAndInactiveCampaignReturnsEmpty() {
        User reader = [SELECT Id FROM User WHERE LastName = 'Audience reader' LIMIT 1];
        List<Contact> contacts = Batch3TestData.contacts(201);
        for (Contact contact : contacts) contact.OwnerId = reader.Id;
        update as system contacts;
        Batch3TestData.grants(contacts);
        Campaign campaign = Batch3TestData.campaign(true);
        campaign.OwnerId = reader.Id; update as system campaign;
        List<CampaignMember> rows = new List<CampaignMember>();
        for (Contact contact : contacts) rows.add(new CampaignMember(CampaignId = campaign.Id, ContactId = contact.Id));
        insert as system rows;
        Set<Id> expected = new Map<Id, CampaignMember>(rows).keySet();
        Test.startTest();
        System.runAs(reader) {
            System.assert(Schema.SObjectType.Campaign.fields.IsActive.isAccessible());
            System.assert(!Schema.SObjectType.Campaign.fields.IsActive.isUpdateable());
            NurtureAudienceService.AudiencePage first = NurtureAudienceService.preview(campaign.Id, null);
            System.assertEquals(200, first.memberIds.size());
            System.assert(first.hasMore);
            NurtureAudienceService.AudiencePage last = NurtureAudienceService.preview(campaign.Id, first.nextId);
            System.assertEquals(1, last.memberIds.size());
            System.assert(!last.hasMore);
            Set<Id> actual = new Set<Id>(first.memberIds); actual.addAll(last.memberIds);
            System.assertEquals(expected, actual, 'Pagination must neither skip nor repeat members.');
        }
        Test.stopTest();
        campaign.IsActive = false; update as system campaign;
        System.runAs(reader) {
            System.assertEquals(0, NurtureAudienceService.preview(campaign.Id, null).memberIds.size());
            System.assertEquals(0, NurtureAudienceService.preview(null, null).memberIds.size());
        }
        System.assertEquals(0, Limits.getEmailInvocations());
    }
}
