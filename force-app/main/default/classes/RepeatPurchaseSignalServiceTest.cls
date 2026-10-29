@isTest
private class RepeatPurchaseSignalServiceTest {
    @isTest static void signalUsesExplicitBuyerNotOtherHouseholdContactAndExcludesClosedOpportunity() {
        List<Contact> contacts = Batch3TestData.contacts(2);
        Loyalty_Member__c fixture = new Loyalty_Member__c(Contact__c = contacts[0].Id);
        Service_Visit__c visit = LoyaltyBatch2TestData.sources(fixture, 1, 0)[0];
        Opportunity opportunity = new Opportunity(Name = 'Batch3 open interest', AccountId = contacts[0].AccountId,
            StageName = 'Quoting', CloseDate = Date.today().addDays(30)); insert opportunity;
        Quote quote = new Quote(Name = 'Explicit buyer quote', OpportunityId = opportunity.Id, Buyer_Contact__c = contacts[1].Id); insert quote;
        System.assertEquals(0, RepeatPurchaseSignalService.candidates().size(), 'A household peer is not the serviced buyer.');
        quote.Buyer_Contact__c = contacts[0].Id; update quote;
        List<Contact> candidates = RepeatPurchaseSignalService.candidates();
        System.assertEquals(1, candidates.size()); System.assertEquals(contacts[0].Id, candidates[0].Id);
        System.assert([SELECT Repeat_Purchase_Open__c FROM Quote WHERE Id = :quote.Id WITH SYSTEM_MODE].Repeat_Purchase_Open__c);
        opportunity.StageName = 'Closed Won'; opportunity.Delivery_Completed__c = true; update opportunity;
        System.assertEquals(0, RepeatPurchaseSignalService.candidates().size());
        System.assert(![SELECT Repeat_Purchase_Open__c FROM Quote WHERE Id = :quote.Id WITH SYSTEM_MODE].Repeat_Purchase_Open__c);
        System.assertEquals('Completed', [SELECT Status__c FROM Service_Visit__c WHERE Id = :visit.Id].Status__c);
    }
}
