Id accountId = '001aj0000467u6PAAQ';
Id contactId = '003aj00002WPAQXAA5';
Id productId = '01taj00000YGzDhAAL';

Opportunity opp = new Opportunity(
    Name = 'UAT-2026-10-19 MANAGER 8PCT',
    AccountId = accountId,
    StageName = 'Prospecting',
    CloseDate = Date.today().addDays(30),
    Amount = 100000
);
insert opp;
System.debug('OPP_ID=' + opp.Id);

QuoteBuilderController.LineInput line = new QuoteBuilderController.LineInput();
line.productId = productId;
line.quantity = 11;

QuoteBuilderController.QuoteResult result = QuoteBuilderController.createQuote(
    opp.Id, contactId, new List<QuoteBuilderController.LineInput>{ line }
);
System.debug('QUOTE_ID=' + result.quoteId);
System.debug('SUBTOTALS=' + result.listSubtotal + '|' + result.adjustedSubtotal + '|' + result.netDiscountPercent);
System.debug('RULES=' + result.rulesApplied + '|basis=' + result.vehicleBasisIdentified + '|blocker=' + result.blockerMessage);

Opportunity stamped = [
    SELECT Id, Discount_Percent__c, Approval_Status__c
    FROM Opportunity WHERE Id = :opp.Id
];
System.debug('STAMP=' + stamped.Discount_Percent__c + '|' + stamped.Approval_Status__c);

Id instanceId = QuoteBuilderController.submitForApproval(result.quoteId);
System.debug('INSTANCE_ID=' + instanceId);
