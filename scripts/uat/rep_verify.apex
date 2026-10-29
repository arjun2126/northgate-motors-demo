String seed = 'UAT-2026-10-20-REP-QUOTE';
Id personaId = '005aj00000gE0b3AAC';
Id vehicleId = 'a0Daj00001D2FPZEA3';
Id productId = '01taj00000YGzDyAAL';

List<Opportunity> opps = [
    SELECT Id, Name, OwnerId, AccountId, Vehicle__c, StageName, Amount,
        Discount_Percent__c, Approval_Status__c
    FROM Opportunity
    WHERE Seed_Tag__c = :seed
];
if (opps.size() != 1) {
    throw new IllegalArgumentException('Expected exactly one REP UAT Opportunity; found ' + opps.size() + '.');
}
Opportunity opp = opps[0];
if (opp.OwnerId != personaId) {
    throw new IllegalArgumentException('Opportunity owner is not ngpersona.');
}

List<Quote> quotes = [
    SELECT Id, Name, OpportunityId, Subtotal, Adjusted_Subtotal__c, Rule_Applied_Count__c,
        Status, Pricebook2Id, Buyer_Contact__c
    FROM Quote
    WHERE OpportunityId = :opp.Id
];
if (quotes.size() != 1) {
    throw new IllegalArgumentException('Expected exactly one Quote; found ' + quotes.size() + '.');
}
Quote quote = quotes[0];

List<QuoteLineItem> lines = [
    SELECT Id, Product2Id, Quantity, UnitPrice, Subtotal
    FROM QuoteLineItem
    WHERE QuoteId = :quote.Id
];
if (lines.size() != 1) {
    throw new IllegalArgumentException('Expected exactly one QuoteLineItem; found ' + lines.size() + '.');
}
QuoteLineItem line = lines[0];

if (line.Product2Id != productId || line.Quantity != 1 || line.UnitPrice != 50615) {
    throw new IllegalArgumentException(
        'Unexpected QuoteLineItem: ' + line.Product2Id + '|' + line.Quantity + '|' + line.UnitPrice
    );
}
if (quote.Subtotal != 50615 || quote.Adjusted_Subtotal__c != 43022.75 || quote.Rule_Applied_Count__c != 1) {
    throw new IllegalArgumentException(
        'Unexpected Quote totals: ' + quote.Subtotal + '|' + quote.Adjusted_Subtotal__c + '|' + quote.Rule_Applied_Count__c
    );
}
if (opp.Discount_Percent__c != 15 || opp.Approval_Status__c != 'Pending') {
    throw new IllegalArgumentException(
        'Unexpected Opportunity stamp: ' + opp.Discount_Percent__c + '|' + opp.Approval_Status__c
    );
}
if (opp.Vehicle__c != vehicleId || opp.StageName != 'Prospecting') {
    throw new IllegalArgumentException('Opportunity vehicle or stage changed unexpectedly.');
}

Map<String, Object> out = new Map<String, Object>();
out.put('status', 'PASS');
out.put('opportunityId', opp.Id);
out.put('quoteId', quote.Id);
out.put('quoteLineItemId', line.Id);
out.put('ownerId', opp.OwnerId);
out.put('listSubtotal', quote.Subtotal);
out.put('adjustedSubtotal', quote.Adjusted_Subtotal__c);
out.put('rulesApplied', quote.Rule_Applied_Count__c);
out.put('discountPercent', opp.Discount_Percent__c);
out.put('approvalStatus', opp.Approval_Status__c);
System.debug('REP_UAT_VERIFY=' + JSON.serialize(out));
