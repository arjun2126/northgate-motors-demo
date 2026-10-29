String seed = 'UAT-2026-10-19-FIN-EXCEPTION';
Id expectedPersonaId = '005aj00000gE0b3AAC';
Id expectedFinanceRoleId = '00Eaj00000QC9uzEAD';
Id expectedFinancePsgId = '0PGaj000005miOrGAI';
Id expectedQueueId = '00Gaj00000ZYezlEAD';
String expectedProcess = 'Financing_Exception_Approval';
Id productId = '01taj00000YGzDhAAL';
Decimal expectedAmount = 30742;
Decimal expectedRate = 7.25;
Decimal expectedPayment = 612.36;
Decimal expectedInterest = 5999.60;

List<Account> existingAccounts = [
    SELECT Id
    FROM Account
    WHERE Seed_Tag__c = :seed
    LIMIT 1
];
if (!existingAccounts.isEmpty()) {
    throw new IllegalArgumentException('Finance UAT account already exists: ' + existingAccounts[0].Id);
}

List<Opportunity> existingOpportunities = [
    SELECT Id
    FROM Opportunity
    WHERE Seed_Tag__c = :seed
    LIMIT 1
];
if (!existingOpportunities.isEmpty()) {
    throw new IllegalArgumentException('Finance UAT already exists: ' + existingOpportunities[0].Id);
}

List<Financing__c> existingFinancings = [
    SELECT Id
    FROM Financing__c
    WHERE Seed_Tag__c = :seed
    LIMIT 1
];
if (!existingFinancings.isEmpty()) {
    throw new IllegalArgumentException('Finance UAT financing already exists: ' + existingFinancings[0].Id);
}

List<User> financeUsers = [
    SELECT Id, Username, UserRoleId, UserRole.DeveloperName, ManagerId, ProfileId, IsActive
    FROM User
    WHERE UserRole.DeveloperName = 'Finance_Manager' AND IsActive = true
    ORDER BY CreatedDate, Id
];
if (financeUsers.size() != 1 || financeUsers[0].Id != expectedPersonaId) {
    throw new IllegalArgumentException('Expected exactly ngpersona as the sole active Finance_Manager user.');
}
User persona = financeUsers[0];
if (persona.UserRoleId != expectedFinanceRoleId) {
    throw new IllegalArgumentException('Unexpected Finance_Manager role ID: ' + persona.UserRoleId);
}
if (persona.ManagerId != null) {
    throw new IllegalArgumentException('ngpersona must have a null ManagerId during Finance UAT.');
}
if (persona.ProfileId != '00eaj00000TnZaFAAV') {
    throw new IllegalArgumentException('Unexpected ngpersona profile ID: ' + persona.ProfileId);
}

List<PermissionSetAssignment> psgAssignments = [
    SELECT Id
    FROM PermissionSetAssignment
    WHERE AssigneeId = :expectedPersonaId AND PermissionSetGroupId = :expectedFinancePsgId
];
if (psgAssignments.size() != 1) {
    throw new IllegalArgumentException('Expected exactly one PSG_Finance assignment for ngpersona.');
}

List<Group> queues = [
    SELECT Id, DeveloperName, Type, DoesIncludeBosses
    FROM Group
    WHERE Id = :expectedQueueId AND Type = 'Queue'
];
if (queues.size() != 1 || queues[0].DeveloperName != 'Q_Finance_Approvals') {
    throw new IllegalArgumentException('Expected Q_Finance_Approvals queue.');
}
Group queue = queues[0];
if (!queue.DoesIncludeBosses) {
    throw new IllegalArgumentException('Q_Finance_Approvals must include bosses.');
}

List<Group> financeRoleGroups = [
    SELECT Id
    FROM Group
    WHERE Type = 'Role' AND RelatedId = :expectedFinanceRoleId
];
if (financeRoleGroups.size() != 1) {
    throw new IllegalArgumentException('Finance_Manager role group not found exactly once.');
}
List<GroupMember> roleMembers = [
    SELECT Id
    FROM GroupMember
    WHERE GroupId = :expectedQueueId AND UserOrGroupId = :financeRoleGroups[0].Id
];
if (roleMembers.size() != 1) {
    throw new IllegalArgumentException('Q_Finance_Approvals must contain Finance_Manager exactly once.');
}

List<ProcessDefinition> definitions = [
    SELECT Id, State
    FROM ProcessDefinition
    WHERE DeveloperName = :expectedProcess
];
if (definitions.size() != 1 || definitions[0].State != 'Active') {
    throw new IllegalArgumentException('Financing_Exception_Approval must be active.');
}

List<ProcessInstance> pendingFinance = [
    SELECT Id
    FROM ProcessInstance
    WHERE Status = 'Pending' AND ProcessDefinition.DeveloperName = :expectedProcess
];
if (!pendingFinance.isEmpty()) {
    throw new IllegalArgumentException('Pending Finance approvals already exist: ' + pendingFinance.size());
}

List<ProcessInstanceWorkitem> pendingQueueItems = [
    SELECT Id
    FROM ProcessInstanceWorkitem
    WHERE ProcessInstance.Status = 'Pending' AND ActorId = :expectedQueueId
];
if (!pendingQueueItems.isEmpty()) {
    throw new IllegalArgumentException('Pending Finance queue work items already exist: ' + pendingQueueItems.size());
}

List<Pricebook2> standardPricebooks = [
    SELECT Id
    FROM Pricebook2
    WHERE IsStandard = true AND IsActive = true
    LIMIT 1
];
if (standardPricebooks.isEmpty()) {
    throw new IllegalArgumentException('Active Standard Price Book not found.');
}
Id standardPricebookId = standardPricebooks[0].Id;

List<PricebookEntry> entries = [
    SELECT Id, UnitPrice
    FROM PricebookEntry
    WHERE Pricebook2Id = :standardPricebookId
        AND Product2Id = :productId
        AND IsActive = true
];
if (entries.size() != 1 || entries[0].UnitPrice != expectedAmount) {
    throw new IllegalArgumentException('Expected one active Aurelia LX 2020 entry at 30742.');
}

Account account = new Account(
    Name = 'UAT-2026-10-19 FIN Exception Household',
    Type = 'Household',
    Seed_Tag__c = seed
);
insert account;

Contact buyer = new Contact(
    LastName = 'FIN UAT Buyer',
    AccountId = account.Id
);
insert buyer;

Opportunity opportunity = new Opportunity(
    Name = 'UAT-2026-10-19 FIN Exception',
    AccountId = account.Id,
    StageName = 'Financing',
    CloseDate = Date.today().addDays(30),
    Amount = expectedAmount,
    Seed_Tag__c = seed
);
insert opportunity;

QuoteBuilderController.LineInput line = new QuoteBuilderController.LineInput();
line.productId = productId;
line.quantity = 1;

QuoteBuilderController.QuoteResult quoteResult = QuoteBuilderController.createQuote(
    opportunity.Id,
    buyer.Id,
    new List<QuoteBuilderController.LineInput>{ line }
);
if (quoteResult.blockerMessage != null) {
    throw new IllegalArgumentException('Quote blocked: ' + quoteResult.blockerMessage);
}
if (quoteResult.quoteId == null) {
    throw new IllegalArgumentException('Quote was not created.');
}

Quote quote = [
    SELECT Id, Name, Subtotal, Adjusted_Subtotal__c, Rule_Applied_Count__c, OpportunityId, Buyer_Contact__c
    FROM Quote
    WHERE Id = :quoteResult.quoteId
];
if (quote.Subtotal != expectedAmount
    || quote.Adjusted_Subtotal__c != expectedAmount
    || quote.Rule_Applied_Count__c != 0
    || quoteResult.netDiscountPercent != 0
    || quote.OpportunityId != opportunity.Id
    || quote.Buyer_Contact__c != buyer.Id) {
    throw new IllegalArgumentException(
        'Unexpected quote: ' + quote.Subtotal + '|' + quote.Adjusted_Subtotal__c + '|' + quote.Rule_Applied_Count__c
    );
}

List<QuoteLineItem> quoteLines = [
    SELECT Id, Quantity, UnitPrice
    FROM QuoteLineItem
    WHERE QuoteId = :quote.Id
];
if (quoteLines.size() != 1 || quoteLines[0].Quantity != 1 || quoteLines[0].UnitPrice != expectedAmount) {
    throw new IllegalArgumentException('Expected one quote line at 30742.');
}

Opportunity stamped = [
    SELECT Id, Discount_Percent__c, Approval_Status__c
    FROM Opportunity
    WHERE Id = :opportunity.Id
];
if (stamped.Discount_Percent__c != 0 || stamped.Approval_Status__c != 'Not_Required') {
    throw new IllegalArgumentException(
        'Unexpected Opportunity stamp: ' + stamped.Discount_Percent__c + '|' + stamped.Approval_Status__c
    );
}

FinanceApplicationController.SaveResult saveResult = FinanceApplicationController.saveApplication(
    null,
    opportunity.Id,
    quote.Id,
    buyer.Id,
    0,
    'A',
    60,
    'Manual_Exception',
    expectedRate,
    'UAT: manual rate exception for Finance Manager approval.'
);
if (!saveResult.errors.isEmpty()) {
    throw new IllegalArgumentException('Financing save failed: ' + String.join(saveResult.errors, ' | '));
}
if (saveResult.financingId == null
    || saveResult.amountFinanced != expectedAmount
    || saveResult.monthlyPayment != expectedPayment
    || saveResult.totalInterest != expectedInterest) {
    throw new IllegalArgumentException(
        'Unexpected financing math: ' + saveResult.amountFinanced + '|'
            + saveResult.monthlyPayment + '|' + saveResult.totalInterest
    );
}

Financing__c seedUpdate = new Financing__c(
    Id = saveResult.financingId,
    Seed_Tag__c = seed,
    Status__c = 'Draft'
);
update seedUpdate;

Financing__c financing = [
    SELECT Id, Name, Status__c, Amount_Financed__c, Down_Payment__c, Annual_Rate__c,
           Term_Months__c, Monthly_Payment__c, Total_Interest__c, Rate_Source__c,
           Credit_Tier__c, Exception_Reason__c, Finance_Exception_Approved__c,
           Decision_Date__c, Seed_Tag__c, Opportunity__c, Quote__c, Applicant__c
    FROM Financing__c
    WHERE Id = :saveResult.financingId
];
if (financing.Status__c != 'Draft'
    || financing.Amount_Financed__c != expectedAmount
    || financing.Down_Payment__c != 0
    || financing.Annual_Rate__c != expectedRate
    || financing.Term_Months__c != 60
    || financing.Monthly_Payment__c != expectedPayment
    || financing.Total_Interest__c != expectedInterest
    || financing.Rate_Source__c != 'Manual_Exception'
    || financing.Credit_Tier__c != 'A'
    || financing.Exception_Reason__c != 'UAT: manual rate exception for Finance Manager approval.'
    || financing.Finance_Exception_Approved__c
    || financing.Decision_Date__c != null
    || financing.Seed_Tag__c != seed
    || financing.Opportunity__c != opportunity.Id
    || financing.Quote__c != quote.Id
    || financing.Applicant__c != buyer.Id) {
    throw new IllegalArgumentException('Unexpected Financing record after save.');
}

Financing__Share financingShare = new Financing__Share(
    ParentId = financing.Id,
    UserOrGroupId = expectedPersonaId,
    AccessLevel = 'Read',
    RowCause = 'Manual'
);
insert financingShare;

OpportunityShare opportunityShare = new OpportunityShare(
    OpportunityId = opportunity.Id,
    UserOrGroupId = expectedPersonaId,
    OpportunityAccessLevel = 'Read'
);
insert opportunityShare;

ContactShare contactShare = new ContactShare(
    ContactId = buyer.Id,
    UserOrGroupId = expectedPersonaId,
    ContactAccessLevel = 'Read'
);
insert contactShare;

Financing__Share createdFinancingShare = [
    SELECT Id, ParentId, UserOrGroupId, AccessLevel, RowCause
    FROM Financing__Share
    WHERE Id = :financingShare.Id
];
OpportunityShare createdOpportunityShare = [
    SELECT Id, OpportunityId, UserOrGroupId, OpportunityAccessLevel, RowCause
    FROM OpportunityShare
    WHERE Id = :opportunityShare.Id
];
ContactShare createdContactShare = [
    SELECT Id, ContactId, UserOrGroupId, ContactAccessLevel, RowCause
    FROM ContactShare
    WHERE Id = :contactShare.Id
];
if (createdFinancingShare.ParentId != financing.Id
    || createdFinancingShare.UserOrGroupId != expectedPersonaId
    || createdFinancingShare.AccessLevel != 'Read'
    || createdFinancingShare.RowCause != 'Manual'
    || createdOpportunityShare.OpportunityId != opportunity.Id
    || createdOpportunityShare.UserOrGroupId != expectedPersonaId
    || createdOpportunityShare.OpportunityAccessLevel != 'Read'
    || createdOpportunityShare.RowCause != 'Manual'
    || createdContactShare.ContactId != buyer.Id
    || createdContactShare.UserOrGroupId != expectedPersonaId
    || createdContactShare.ContactAccessLevel != 'Read'
    || createdContactShare.RowCause != 'Manual') {
    throw new IllegalArgumentException('Unexpected manual share state.');
}

FinancingApprovalService.ApprovalOutcome approval = FinanceApplicationController.submitForExceptionApproval(financing.Id);
if (!approval.errors.isEmpty()) {
    throw new IllegalArgumentException('Finance approval submit failed: ' + String.join(approval.errors, ' | '));
}
if (!approval.requiresApproval || approval.alreadySubmitted || approval.processInstanceId == null) {
    throw new IllegalArgumentException('Finance approval was not submitted as a new exception request.');
}

ProcessInstance instance = [
    SELECT Id, Status, TargetObjectId, ProcessDefinition.DeveloperName
    FROM ProcessInstance
    WHERE Id = :approval.processInstanceId
];
if (instance.Status != 'Pending'
    || instance.ProcessDefinition.DeveloperName != expectedProcess
    || instance.TargetObjectId != financing.Id) {
    throw new IllegalArgumentException('Unexpected process instance state.');
}

List<ProcessInstanceWorkitem> workItems = [
    SELECT Id, ActorId, ProcessInstanceId
    FROM ProcessInstanceWorkitem
    WHERE ProcessInstanceId = :instance.Id
];
if (workItems.size() != 1 || workItems[0].ActorId != expectedQueueId) {
    throw new IllegalArgumentException('Expected one Finance queue work item.');
}

Financing__c submitted = [
    SELECT Id, Status__c, Finance_Exception_Approved__c, Decision_Date__c
    FROM Financing__c
    WHERE Id = :financing.Id
];
if (submitted.Status__c != 'Draft' || submitted.Finance_Exception_Approved__c || submitted.Decision_Date__c != null) {
    throw new IllegalArgumentException('Unexpected Financing state after submission.');
}

Map<String, Object> shares = new Map<String, Object>{
    'financing' => createdFinancingShare.Id,
    'opportunity' => createdOpportunityShare.Id,
    'contact' => createdContactShare.Id
};

Map<String, Object> out = new Map<String, Object>();
out.put('seed', seed);
out.put('accountId', account.Id);
out.put('contactId', buyer.Id);
out.put('opportunityId', opportunity.Id);
out.put('opportunityName', opportunity.Name);
out.put('quoteId', quote.Id);
out.put('quoteName', quote.Name);
out.put('financingId', financing.Id);
out.put('financingName', financing.Name);
out.put('amountFinanced', financing.Amount_Financed__c);
out.put('annualRate', financing.Annual_Rate__c);
out.put('termMonths', financing.Term_Months__c);
out.put('monthlyPayment', financing.Monthly_Payment__c);
out.put('totalInterest', financing.Total_Interest__c);
out.put('quoteSubtotal', quote.Subtotal);
out.put('quoteAdjustedSubtotal', quote.Adjusted_Subtotal__c);
out.put('quoteRulesApplied', quote.Rule_Applied_Count__c);
out.put('processInstanceId', instance.Id);
out.put('workItemId', workItems[0].Id);
out.put('workItemActorId', workItems[0].ActorId);
out.put('queueId', queue.Id);
out.put('shares', shares);
out.put('financingUrl', '/lightning/r/Financing__c/' + financing.Id + '/view');
out.put('approvalUrl', '/p/process/ProcessInstanceWorkitemWizardStageManager?id=' + workItems[0].Id);
System.debug('FIN_UAT_RESULT=' + JSON.serialize(out));
