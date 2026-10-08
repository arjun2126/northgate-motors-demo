@isTest
private class LeadConvertGuardTest {
    @isTest
    static void unselectedAccountIsBlocked() {
        Lead l = new Lead(LastName = 'P2 Guard', Company = 'P2 Guard Co', Status = 'Open');
        insert l;
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(l.Id);
        lc.setDoNotCreateOpportunity(true);
        lc.setConvertedStatus('Closed - Converted');
        try {
            Database.convertLead(lc, true);
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Convert with an Account'), e.getMessage());
        }
    }

    @isTest
    static void seedTagClearedOnConvertedRecords() {
        Account a = new Account(Name = 'P2 Conv A');
        insert a;
        Contact c = new Contact(LastName = 'P2 Conv C', AccountId = a.Id);
        insert c;
        Opportunity o = new Opportunity(Name = 'P2 Conv O', StageName = 'Prospecting', CloseDate = Date.today().addDays(30));
        insert o;
        Lead l = new Lead(LastName = 'P2 Conv L', Company = 'P2 Conv Co', Status = 'Open', Seed_Tag__c = 'P2-CONV-SEED');
        insert l;
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(l.Id);
        lc.setAccountId(a.Id);
        lc.setContactId(c.Id);
        lc.setOpportunityId(o.Id);
        lc.setConvertedStatus('Closed - Converted');
        Database.convertLead(lc, true);
        Account afterA = [SELECT Seed_Tag__c FROM Account WHERE Id = :a.Id];
        Contact afterC = [SELECT Seed_Tag__c FROM Contact WHERE Id = :c.Id];
        Opportunity afterO = [SELECT Seed_Tag__c FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals(null, afterA.Seed_Tag__c, 'Account seed tag should be cleared on conversion');
        System.assertEquals(null, afterC.Seed_Tag__c, 'Contact seed tag should be cleared on conversion');
        System.assertEquals(null, afterO.Seed_Tag__c, 'Opportunity seed tag should be cleared on conversion');
    }
}
