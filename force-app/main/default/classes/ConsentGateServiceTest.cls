@isTest
private class ConsentGateServiceTest {
    private static CampaignMember stored(Id id) {
        return [SELECT Id, Status, Consent_Managed__c, Nurture_Eligible__c FROM CampaignMember WHERE Id = :id WITH SYSTEM_MODE];
    }
    @isTest static void bulkPartialSaveAdmitsOnlyMatchingGrantsAndRetriesSafely() {
        List<Contact> contacts = Batch3TestData.contacts(200);
        List<Contact> granted = new List<Contact>(); for (Integer i = 0; i < 100; i++) granted.add(contacts[i]);
        Batch3TestData.grants(granted); Campaign campaign = Batch3TestData.campaign(true);
        List<CampaignMember> rows = new List<CampaignMember>();
        for (Contact contact : contacts) rows.add(new CampaignMember(CampaignId = campaign.Id, ContactId = contact.Id));
        Test.startTest();
        Integer queries = Limits.getQueries();
        Database.SaveResult[] results = Database.insert(rows, false, AccessLevel.SYSTEM_MODE);
        System.assert(Limits.getQueries() - queries < 20, 'No query per member.');
        Test.stopTest();
        for (Integer i = 0; i < results.size(); i++) {
            System.assertEquals(i < 100, results[i].isSuccess(), JSON.serialize(results[i].getErrors()));
            if (i >= 100) System.assertEquals('A current matching consent grant is required for managed campaign membership.', results[i].getErrors()[0].getMessage());
        }
        System.assertEquals(100, [SELECT COUNT() FROM CampaignMember WHERE CampaignId = :campaign.Id]);
        System.assertEquals(100, [SELECT COUNT() FROM CampaignMember WHERE CampaignId = :campaign.Id AND Nurture_Eligible__c = true WITH SYSTEM_MODE]);
        System.assertEquals(0, Limits.getEmailInvocations());
    }
    @isTest static void wrongTupleFutureMissingAndDenyRowsDoNotGrantConsent() {
        List<Contact> contacts = Batch3TestData.contacts(5);
        List<Consent__c> grants = Batch3TestData.grants(contacts);
        grants[0].Channel__c = 'SMS'; grants[1].Purpose__c = 'Loyalty';
        grants[2].Granted_On__c = ConsentGateService.today().addDays(1); grants[3].Granted_On__c = null;
        update as system grants;
        insert as system new Consent__c(Contact__c = contacts[4].Id, Purpose__c = 'Marketing', Channel__c = 'Email',
            Status__c = 'Revoked', Revoked_On__c = ConsentGateService.today());
        Campaign campaign = Batch3TestData.campaign(true);
        List<CampaignMember> rows = new List<CampaignMember>();
        for (Contact contact : contacts) rows.add(new CampaignMember(CampaignId = campaign.Id, ContactId = contact.Id));
        for (Database.SaveResult result : Database.insert(rows, false, AccessLevel.SYSTEM_MODE)) System.assert(!result.isSuccess());
        Lead lead = new Lead(LastName = 'Batch3 lead', Company = 'Isolated demo'); insert lead;
        System.assert(!Database.insert(new CampaignMember(CampaignId = campaign.Id, LeadId = lead.Id), false, AccessLevel.SYSTEM_MODE).isSuccess());
        System.assertEquals(0, [SELECT COUNT() FROM CampaignMember WHERE CampaignId = :campaign.Id]);
    }
    @isTest static void revocationDeletionUndeleteAndPolicyChangesSuppressWithoutDeletingHistory() {
        Contact contact = Batch3TestData.contacts(1)[0];
        Consent__c grant = Batch3TestData.grants(new List<Contact>{contact})[0];
        Campaign campaign = Batch3TestData.campaign(true);
        CampaignMember member = new CampaignMember(CampaignId = campaign.Id, ContactId = contact.Id); insert as system member;
        String originalStatus = stored(member.Id).Status;
        grant.Status__c = 'Revoked'; grant.Revoked_On__c = ConsentGateService.today(); update as system grant;
        System.assert(!stored(member.Id).Nurture_Eligible__c);
        System.assertEquals(originalStatus, stored(member.Id).Status);
        grant.Status__c = 'Granted'; grant.Revoked_On__c = null; update as system grant;
        System.assert(stored(member.Id).Nurture_Eligible__c);
        delete as system grant; System.assert(!stored(member.Id).Nurture_Eligible__c);
        undelete grant; System.assert(stored(member.Id).Nurture_Eligible__c);
        campaign.Consent_Channel__c = 'SMS'; update as system campaign;
        System.assert(!stored(member.Id).Nurture_Eligible__c);
        campaign.Consent_Channel__c = 'Email'; update as system campaign;
        System.assert(stored(member.Id).Nurture_Eligible__c);
        campaign.IsActive = false; update as system campaign;
        System.assert(!stored(member.Id).Nurture_Eligible__c);
        System.assertEquals(1, [SELECT COUNT() FROM CampaignMember WHERE Id = :member.Id]);
    }
    @isTest static void emailOptOutAndConsentReparentRefreshBothContacts() {
        List<Contact> contacts = Batch3TestData.contacts(2);
        Consent__c grant = Batch3TestData.grants(new List<Contact>{contacts[0]})[0];
        Campaign campaign = Batch3TestData.campaign(true);
        CampaignMember member = new CampaignMember(CampaignId = campaign.Id, ContactId = contacts[0].Id); insert as system member;
        contacts[0].HasOptedOutOfEmail = true; update as system contacts[0];
        System.assert(!stored(member.Id).Nurture_Eligible__c);
        contacts[0].HasOptedOutOfEmail = false; update as system contacts[0]; System.assert(stored(member.Id).Nurture_Eligible__c);
        grant.Contact__c = contacts[1].Id; update as system grant;
        System.assert(!stored(member.Id).Nurture_Eligible__c);
        grant.Status__c = 'Expired'; update as system grant;
        System.assert(!Database.insert(new CampaignMember(CampaignId = campaign.Id, ContactId = contacts[1].Id), false, AccessLevel.SYSTEM_MODE).isSuccess());
    }
    @isTest static void unmanagedCampaignsRemainLegacyAndInvalidPolicyFailsClosed() {
        Contact contact = Batch3TestData.contacts(1)[0]; Campaign legacy = Batch3TestData.campaign(false);
        CampaignMember member = new CampaignMember(CampaignId = legacy.Id, ContactId = contact.Id, Nurture_Eligible__c = true);
        insert as system member;
        System.assert(!stored(member.Id).Consent_Managed__c); System.assert(!stored(member.Id).Nurture_Eligible__c);
        legacy.Nurture_Managed__c = true;
        System.assert(!Database.update(legacy, false, AccessLevel.SYSTEM_MODE).isSuccess());
        legacy.Consent_Purpose__c = 'Marketing'; legacy.Consent_Channel__c = 'Email'; update as system legacy;
        System.assert(stored(member.Id).Consent_Managed__c); System.assert(!stored(member.Id).Nurture_Eligible__c);
        legacy.Nurture_Managed__c = false; update as system legacy;
        System.assert(stored(member.Id).Consent_Managed__c); System.assert(!stored(member.Id).Nurture_Eligible__c);
    }
}
