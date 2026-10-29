Map<String, Object> r = new Map<String, Object>();
r.put('tag', 'UAT-2026-10-19');

Account a = new Account(Name = 'UAT-2026-10-19 Household', Type = 'Household');
insert a;
r.put('accountId', a.Id);

Contact c = new Contact(LastName = 'UAT Buyer', AccountId = a.Id);
insert c;
r.put('contactId', c.Id);

Date cd = Date.today().addDays(30);
Opportunity o = new Opportunity(
    Name = 'UAT-2026-10-19 QUOTE',
    AccountId = a.Id,
    CloseDate = cd,
    StageName = 'Financing',
    Vehicle__c = 'a0Daj00001D2FPZEA3'
);
insert o;
r.put('opportunityId', o.Id);

Delivery__c d = new Delivery__c(
    Opportunity__c = o.Id,
    Vehicle__c = 'a0Daj00001D2FPZEA3',
    Buyer__c = c.Id,
    Status__c = 'Scheduled',
    Scheduled_Date__c = cd,
    Checklist_Documents__c = true,
    Checklist_Inspection__c = true,
    Checklist_Signature__c = true,
    Checklist_Walkthrough__c = true
);
insert d;
r.put('deliveryId', d.Id);

Test_Drive__c td = new Test_Drive__c(
    Contact__c = c.Id,
    Vehicle__c = 'a0Daj00001D2FPZEA3',
    Scheduled_Start__c = Datetime.now().addDays(1)
);
insert td;
r.put('testDriveId', td.Id);

Trade_In__c ti = new Trade_In__c(Opportunity__c = o.Id);
insert ti;
r.put('tradeInId', ti.Id);

List<QuoteBuilderController.CatalogItem> catalog = QuoteBuilderController.getCatalog('Vehicle_Trim');
r.put('catalogCount', catalog.size());

try {
    QuoteBuilderController.LineInput li = new QuoteBuilderController.LineInput();
    li.productId = '01taj00000YGzDyAAL';
    li.quantity = 1;
    QuoteBuilderController.createQuote(o.Id, c.Id, new List<QuoteBuilderController.LineInput>{ li });
    r.put('quoteBuilder', 'UNEXPECTED_SUCCESS');
} catch (Exception qe) {
    r.put('quoteBuilderError', qe.getMessage());
}

d.Status__c = 'Completed';
update d;
r.put('deliveryStatus', [SELECT Id, Status__c, Checklist_Complete__c, Completed_Date__c, Buyer__c FROM Delivery__c WHERE Id = :d.Id].Status__c);
Delivery__c dAfter = [SELECT Id, Checklist_Complete__c, Completed_Date__c FROM Delivery__c WHERE Id = :d.Id];
r.put('deliveryChecklistComplete', dAfter.Checklist_Complete__c);
r.put('deliveryCompletedDate', String.valueOf(dAfter.Completed_Date__c));
Opportunity oAfter = [SELECT Id, StageName, Delivery_Completed__c FROM Opportunity WHERE Id = :o.Id];
r.put('oppStageAfterDelivery', oAfter.StageName);
r.put('oppDeliveryCompleted', oAfter.Delivery_Completed__c);
List<Loyalty_Member__c> members = [SELECT Id, Member_Number__c, Tier__c, Status__c FROM Loyalty_Member__c WHERE Contact__c = :c.Id];
r.put('loyaltyMemberCount', members.size());
if (!members.isEmpty()) {
    r.put('loyaltyMemberId', members[0].Id);
    r.put('loyaltyMemberTier', members[0].Tier__c);
}

System.debug('UAT_RESULT=' + JSON.serialize(r));
