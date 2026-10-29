String seed = 'UAT-2026-10-20-REP-QUOTE';
Id personaId = '005aj00000gE0b3AAC';
Id vehicleId = 'a0Daj00001D2FPZEA3';
Id productId = '01taj00000YGzDyAAL';
Id standardPricebookId = '01saj00000NvczOAAR';
Decimal expectedListPrice = 50615;

User persona = [
    SELECT Id, Username, IsActive, Profile.Name
    FROM User
    WHERE Id = :personaId
];
if (!persona.IsActive || persona.Profile.Name != 'NG_Sales') {
    throw new IllegalArgumentException('Expected active ngpersona with NG_Sales profile.');
}

List<Account> existingAccounts = [SELECT Id FROM Account WHERE Seed_Tag__c = :seed LIMIT 1];
List<Contact> existingContacts = [SELECT Id FROM Contact WHERE Seed_Tag__c = :seed LIMIT 1];
List<Opportunity> existingOpps = [SELECT Id FROM Opportunity WHERE Seed_Tag__c = :seed LIMIT 1];
if (!existingAccounts.isEmpty() || !existingContacts.isEmpty() || !existingOpps.isEmpty()) {
    throw new IllegalArgumentException('Rep UAT seed already exists. Do not create a duplicate.');
}

Pricebook2 pricebook = [
    SELECT Id, IsActive
    FROM Pricebook2
    WHERE Id = :standardPricebookId
];
if (!pricebook.IsActive) {
    throw new IllegalArgumentException('Standard Price Book is not active.');
}

Vehicle__c vehicle = [
    SELECT Id, Status__c, Vehicle_Model__r.Name, Inventory_Age_Days__c
    FROM Vehicle__c
    WHERE Id = :vehicleId
];
if (vehicle.Status__c != 'Available' || vehicle.Inventory_Age_Days__c <= 90) {
    throw new IllegalArgumentException('Expected an Available vehicle aged over 90 days.');
}

Product2 product = [
    SELECT Id, Name, Category__c, IsActive
    FROM Product2
    WHERE Id = :productId
];
if (!product.IsActive || product.Category__c != 'Vehicle_Trim' || product.Name != vehicle.Vehicle_Model__r.Name) {
    throw new IllegalArgumentException('Product must be the active Vehicle_Trim matching the vehicle model.');
}

List<PricebookEntry> entries = [
    SELECT Id, UnitPrice, IsActive
    FROM PricebookEntry
    WHERE Pricebook2Id = :standardPricebookId AND Product2Id = :productId
];
if (entries.size() != 1 || !entries[0].IsActive || entries[0].UnitPrice != expectedListPrice) {
    throw new IllegalArgumentException('Expected one active standard PricebookEntry at ' + expectedListPrice + '.');
}

Account account = new Account(
    Name = 'UAT-2026-10-20 REP Quote Household',
    Type = 'Household',
    Seed_Tag__c = seed,
    OwnerId = personaId
);
insert account;

Contact buyer = new Contact(
    LastName = 'REP UAT Buyer',
    AccountId = account.Id,
    Seed_Tag__c = seed,
    OwnerId = personaId
);
insert buyer;

Opportunity opportunity = new Opportunity(
    Name = 'UAT-2026-10-20 REP Quote',
    AccountId = account.Id,
    StageName = 'Prospecting',
    CloseDate = Date.today().addDays(30),
    Amount = expectedListPrice,
    Vehicle__c = vehicleId,
    Seed_Tag__c = seed,
    OwnerId = personaId
);
insert opportunity;

Opportunity saved = [
    SELECT Id, Name, OwnerId, AccountId, Vehicle__c, StageName, Amount
    FROM Opportunity
    WHERE Id = :opportunity.Id
];
System.assert(saved.OwnerId == personaId, 'Opportunity must be owned by ngpersona.');
System.assert(saved.AccountId == account.Id && saved.Vehicle__c == vehicleId, 'Opportunity links must be set.');
System.assert([SELECT COUNT() FROM Quote WHERE OpportunityId = :saved.Id] == 0, 'Fresh Opportunity must have no Quote.');

Map<String, Object> out = new Map<String, Object>();
out.put('seed', seed);
out.put('accountId', account.Id);
out.put('contactId', buyer.Id);
out.put('opportunityId', opportunity.Id);
out.put('vehicleId', vehicleId);
out.put('productId', productId);
out.put('expectedListPrice', expectedListPrice);
out.put('expectedAdjustedSubtotal', 43022.75);
out.put('expectedNetDiscountPercent', 15);
out.put('expectedRulesApplied', 1);
out.put('expectedApprovalStatus', 'Pending');
out.put('opportunityUrl', '/lightning/r/Opportunity/' + opportunity.Id + '/view');
System.debug('REP_UAT_SETUP=' + JSON.serialize(out));
