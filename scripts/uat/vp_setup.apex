String seed = 'UAT-2026-10-20-VP-12PCT';
String expectedPersonaId = '005aj00000gE0b3AAC';
Id productId = '01taj00000YGzDhAAL';

List<Opportunity> existing = [
    SELECT Id
    FROM Opportunity
    WHERE Seed_Tag__c = :seed
    LIMIT 1
];
if (!existing.isEmpty()) {
    throw new IllegalArgumentException('VP UAT already exists: ' + existing[0].Id);
}

List<User> vpUsers = [
    SELECT Id, Username
    FROM User
    WHERE UserRole.DeveloperName = 'VP_Sales' AND IsActive = true
    ORDER BY CreatedDate, Id
];
if (vpUsers.size() != 1 || vpUsers[0].Id != expectedPersonaId) {
    throw new IllegalArgumentException('Expected exactly ngpersona as the sole active VP_Sales user.');
}

Account account = new Account(
    Name = 'UAT-2026-10-20 VP 12PCT Household',
    Type = 'Household',
    Seed_Tag__c = seed
);
insert account;

Contact buyer = new Contact(
    LastName = 'VP UAT Buyer',
    AccountId = account.Id
);
insert buyer;

Loyalty_Member__c loyalty = new Loyalty_Member__c(
    Contact__c = buyer.Id,
    Tier__c = 'Platinum',
    Status__c = 'Active'
);
insert loyalty;

Opportunity opportunity = new Opportunity(
    Name = 'UAT-2026-10-20 VP 12PCT',
    AccountId = account.Id,
    StageName = 'Prospecting',
    CloseDate = Date.today().addDays(30),
    Amount = 368904,
    Seed_Tag__c = seed
);
insert opportunity;

QuoteBuilderController.LineInput line = new QuoteBuilderController.LineInput();
line.productId = productId;
line.quantity = 12;

QuoteBuilderController.QuoteResult result = QuoteBuilderController.createQuote(
    opportunity.Id,
    buyer.Id,
    new List<QuoteBuilderController.LineInput>{ line }
);

if (result.netDiscountPercent <= 10) {
    throw new IllegalArgumentException('Expected discount above 10; got ' + result.netDiscountPercent);
}

Opportunity stamped = [
    SELECT Id, Discount_Percent__c, Approval_Status__c
    FROM Opportunity
    WHERE Id = :opportunity.Id
];
if (stamped.Discount_Percent__c != 12.60 || stamped.Approval_Status__c != 'Pending') {
    throw new IllegalArgumentException(
        'Unexpected Opportunity stamp: ' + stamped.Discount_Percent__c + '|' + stamped.Approval_Status__c
    );
}

OpportunityShare share = new OpportunityShare(
    OpportunityId = opportunity.Id,
    UserOrGroupId = vpUsers[0].Id,
    OpportunityAccessLevel = 'Read'
);
insert share;

OpportunityShare createdShare = [
    SELECT Id, OpportunityAccessLevel, RowCause
    FROM OpportunityShare
    WHERE Id = :share.Id
];
if (createdShare.OpportunityAccessLevel != 'Read' || createdShare.RowCause != 'Manual') {
    throw new IllegalArgumentException(
        'Unexpected share: ' + createdShare.OpportunityAccessLevel + '|' + createdShare.RowCause
    );
}

Id instanceId = QuoteBuilderController.submitForApproval(result.quoteId);

ProcessInstance instance = [
    SELECT Id, Status, ProcessDefinition.DeveloperName
    FROM ProcessInstance
    WHERE Id = :instanceId
];
if (instance.Status != 'Pending' || instance.ProcessDefinition.DeveloperName != 'VP_Discount_Approval') {
    throw new IllegalArgumentException(
        'Unexpected approval route: ' + instance.Status + '|' + instance.ProcessDefinition.DeveloperName
    );
}

List<ProcessInstanceWorkitem> workItems = [
    SELECT Id, ActorId, ProcessInstanceId
    FROM ProcessInstanceWorkitem
    WHERE ProcessInstanceId = :instanceId
];
if (workItems.size() != 1 || workItems[0].ActorId != expectedPersonaId) {
    throw new IllegalArgumentException('Expected one work item assigned to ngpersona.');
}

Quote quote = [
    SELECT Id, Subtotal, Adjusted_Subtotal__c, Rule_Applied_Count__c
    FROM Quote
    WHERE Id = :result.quoteId
];
if (quote.Subtotal != 368904 || quote.Adjusted_Subtotal__c != 322422.10 || quote.Rule_Applied_Count__c != 2) {
    throw new IllegalArgumentException(
        'Unexpected quote totals: ' + quote.Subtotal + '|' + quote.Adjusted_Subtotal__c + '|' + quote.Rule_Applied_Count__c
    );
}

Map<String, Object> out = new Map<String, Object>();
out.put('seed', seed);
out.put('accountId', account.Id);
out.put('contactId', buyer.Id);
out.put('opportunityId', opportunity.Id);
out.put('quoteId', quote.Id);
out.put('shareId', createdShare.Id);
out.put('listSubtotal', quote.Subtotal);
out.put('adjustedSubtotal', quote.Adjusted_Subtotal__c);
out.put('rulesApplied', quote.Rule_Applied_Count__c);
out.put('netDiscountPercent', result.netDiscountPercent);
out.put('approvalStatus', stamped.Approval_Status__c);
out.put('instanceId', instanceId);
out.put('workItemId', workItems[0].Id);
out.put('workItemActorId', workItems[0].ActorId);
out.put('approvalUrl', '/p/process/ProcessInstanceWorkitemWizardStageManager?id=' + workItems[0].Id);
System.debug('VP_UAT_RESULT=' + JSON.serialize(out));
