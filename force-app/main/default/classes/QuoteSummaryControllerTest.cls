@isTest
private class QuoteSummaryControllerTest {
    private static final Id STD_PB = Test.getStandardPricebookId();

    private static Account makeAccount(String seed) {
        return P2TestDataFactory.makeAccount(seed);
    }

    private static Product2 makeProduct(String name, String category, Decimal unitPrice) {
        Product2 p = new Product2(Name = name, Category__c = category, IsActive = true);
        insert p;
        insert new PricebookEntry(Pricebook2Id = STD_PB, Product2Id = p.Id, IsActive = true, UnitPrice = unitPrice);
        return p;
    }

    private static Vehicle__c makeVehicle(Id modelId, Integer daysAgo) {
        Vehicle__c v = new Vehicle__c(
            VIN__c = '3HGBH41JXMN109188',
            Vehicle_Model__c = modelId,
            Status__c = 'Available',
            Acquisition_Date__c = Date.today().addDays(-daysAgo)
        );
        insert v;
        return v;
    }

    @TestSetup
    static void setup() {
        insert new Rooftop__c(Name = 'Northgate Downtown');
        // Setup-object DML is isolated from business data and rolls back with the test.
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Id profileId = [SELECT Id FROM Profile WHERE Name = 'NG_Sales' LIMIT 1].Id;
            PermissionSet quoteAccess = [SELECT Id FROM PermissionSet WHERE Name = 'PS_Quote_Workflows'];
            PermissionSet salesAccess = [SELECT Id FROM PermissionSet WHERE Name = 'PS_Sales_Rep'];
            for (String mode : new List<String>{'workflow', 'sales', 'none', 'quote', 'product', 'opportunity'}) {
                User persona = new User(
                    Alias = 'qs' + mode.left(6), LastName = 'QuoteSecurity' + mode,
                    Email = 'quote.security.' + mode + '@northgate.example',
                    Username = 'quote.security.' + mode + '.' + UserInfo.getOrganizationId() + '@northgate.example',
                    ProfileId = profileId, EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US',
                    LocaleSidKey = 'en_US', TimeZoneSidKey = 'America/New_York'
                );
                insert persona;
                if (mode == 'workflow' || mode == 'sales') {
                    insert new PermissionSetAssignment(AssigneeId = persona.Id, PermissionSetId = quoteAccess.Id);
                    if (mode == 'sales') {
                        insert new PermissionSetAssignment(AssigneeId = persona.Id, PermissionSetId = salesAccess.Id);
                    }
                } else if (mode != 'none') {
                    PermissionSet limited = new PermissionSet(Name = 'QuoteSummaryTest_' + mode, Label = 'Quote Summary Test ' + mode);
                    insert limited;
                    insert new List<ObjectPermissions>{
                        new ObjectPermissions(ParentId = limited.Id, SobjectType = 'Opportunity', PermissionsRead = true),
                        new ObjectPermissions(ParentId = limited.Id, SobjectType = 'Quote', PermissionsRead = true),
                        new ObjectPermissions(ParentId = limited.Id, SobjectType = 'Product2', PermissionsRead = true)
                    };
                    List<FieldPermissions> fields = new List<FieldPermissions>();
                    for (String field : new List<String>{
                        'Quote.Adjusted_Subtotal__c', 'Quote.Rule_Applied_Count__c',
                        'Quote.Quote_Valid_Until__c', 'Quote.GrandTotal', 'Product2.Category__c',
                        'Opportunity.Discount_Percent__c', 'Opportunity.Approval_Status__c'
                    }) {
                        if ((mode == 'quote' && field == 'Quote.Adjusted_Subtotal__c') ||
                            (mode == 'product' && field == 'Product2.Category__c') ||
                            (mode == 'opportunity' && field == 'Opportunity.Discount_Percent__c')) {
                            continue;
                        }
                        fields.add(new FieldPermissions(
                            ParentId = limited.Id, SobjectType = field.substringBefore('.'),
                            Field = field, PermissionsRead = true
                        ));
                    }
                    insert fields;
                    insert new PermissionSetAssignment(AssigneeId = persona.Id, PermissionSetId = limited.Id);
                }
            }
        }
    }

    @isTest
    static void getSummary_returnsQuoteLinesAndStamps() {
        Account acc = makeAccount('Sum');
        Contact buyer = P2TestDataFactory.makeContact(acc.Id, 'Buyer');
        insert new Loyalty_Member__c(Contact__c = buyer.Id, Tier__c = 'Gold', Status__c = 'Active');
        Vehicle_Model__c model = new Vehicle_Model__c(Name = 'Test Model Premium', Trim__c = 'Premium');
        insert model;
        Vehicle__c vehicle = makeVehicle(model.Id, 120);
        Product2 vehicleProduct = makeProduct('Test Model Premium', 'Vehicle_Trim', 30000);
        Product2 accessory = makeProduct('Floor Mats', 'Accessory', 2000);
        Opportunity opp = new Opportunity(
            Name = 'Summary Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id,
            Vehicle__c = vehicle.Id
        );
        insert opp;
        Quote quote = new Quote(
            OpportunityId = opp.Id,
            Name = 'Summary Quote',
            Pricebook2Id = STD_PB,
            ExpirationDate = Date.today().addDays(30),
            Quote_Valid_Until__c = Date.today().addDays(30),
            Buyer_Contact__c = buyer.Id,
            Adjusted_Subtotal__c = 290159.20,
            Rule_Applied_Count__c = 4
        );
        insert quote;
        PricebookEntry vehicleEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id = :vehicleProduct.Id AND Pricebook2Id = :STD_PB LIMIT 1];
        PricebookEntry accessoryEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id = :accessory.Id AND Pricebook2Id = :STD_PB LIMIT 1];
        List<QuoteLineItem> lines = new List<QuoteLineItem>{
            new QuoteLineItem(QuoteId = quote.Id, PricebookEntryId = vehicleEntry.Id, Quantity = 12, UnitPrice = 30000),
            new QuoteLineItem(QuoteId = quote.Id, PricebookEntryId = accessoryEntry.Id, Quantity = 1, UnitPrice = 2000)
        };
        insert lines;
        opp.Discount_Percent__c = 19.85;
        opp.Approval_Status__c = 'Pending';
        update opp;

        Test.startTest();
        QuoteSummaryController.SummaryDto summary = QuoteSummaryController.getSummary(quote.Id);
        Test.stopTest();

        System.assertEquals(quote.Id, summary.quoteId, 'quote id');
        System.assertEquals('Summary Quote', summary.quoteName, 'quote name');
        System.assertEquals('Summary Opp', summary.opportunityName, 'opportunity name');
        System.assertEquals(290159.20, summary.adjustedSubtotal, 'adjusted subtotal from quote');
        System.assertEquals(4, summary.rulesApplied, 'rule count from quote');
        System.assertEquals(Date.today().addDays(30), summary.validUntil, 'valid until from quote');
        System.assertEquals(19.85, summary.discountPercent, 'discount percent from opportunity');
        System.assertEquals('Pending', summary.approvalStatus, 'approval status from opportunity');
        System.assertEquals(362000.00, summary.listSubtotal, 'list subtotal from summed line subtotals');
        System.assertEquals(2, summary.lines.size(), 'two quote lines returned');
        System.assertEquals(12, summary.lines[0].quantity == 12 ? 12 : summary.lines[1].quantity, 'vehicle line qty 12');
        System.assertEquals('Vehicle_Trim', summary.lines[0].quantity == 12 ? summary.lines[0].category : summary.lines[1].category, 'vehicle line category');
        System.assertEquals(30000, summary.lines[0].quantity == 12 ? summary.lines[0].unitPrice : summary.lines[1].unitPrice, 'vehicle line unit price');
    }

    @isTest
    static void getSummary_readsGrandTotalField() {
        // Guards the FLS regression that surfaced in the live smoke test:
        // the controller queries `Quote.GrandTotal`; without Read FLS on
        // the persona, the SOQL throws at runtime. Asserting the
        // controller reads `grandTotal` end-to-end.
        Account acc = makeAccount('GT');
        Opportunity opp = new Opportunity(
            Name = 'GT Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id
        );
        insert opp;
        Product2 vehicleProduct = makeProduct('Test Model GT', 'Vehicle_Trim', 28000);
        Quote quote = new Quote(
            Name = 'GT Quote',
            OpportunityId = opp.Id,
            Pricebook2Id = STD_PB
        );
        insert quote;
        insert new QuoteLineItem(QuoteId = quote.Id, PricebookEntryId = [SELECT Id FROM PricebookEntry WHERE Product2Id = :vehicleProduct.Id AND Pricebook2Id = :STD_PB].Id, Quantity = 1, UnitPrice = 28000);
        // Baseline: the running user can read GrandTotal
        System.assertNotEquals(null, [SELECT GrandTotal FROM Quote WHERE Id = :quote.Id].GrandTotal, 'baseline read must succeed');
        QuoteSummaryController.SummaryDto summary = QuoteSummaryController.getSummary(quote.Id);
        System.assertEquals(quote.Id, summary.quoteId, 'summary returned');
        System.assertNotEquals(null, summary.grandTotal, 'controller surfaces grandTotal');
    }

    @isTest
    static void getSummary_separatesAdjustedFromStandard() {
        Account acc = makeAccount('Plain');
        Vehicle_Model__c model = new Vehicle_Model__c(Name = 'Test Model LX', Trim__c = 'LX');
        insert model;
        Vehicle__c vehicle = makeVehicle(model.Id, 10);
        Product2 vehicleProduct = makeProduct('Test Model LX', 'Vehicle_Trim', 30000);
        Opportunity opp = new Opportunity(
            Name = 'Plain Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id,
            Vehicle__c = vehicle.Id
        );
        insert opp;
        Quote quote = new Quote(
            OpportunityId = opp.Id,
            Name = 'Plain Quote',
            Pricebook2Id = STD_PB,
            ExpirationDate = Date.today().addDays(30),
            Quote_Valid_Until__c = Date.today().addDays(30),
            Adjusted_Subtotal__c = 30000
        );
        insert quote;
        PricebookEntry vehicleEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id = :vehicleProduct.Id AND Pricebook2Id = :STD_PB LIMIT 1];
        insert new QuoteLineItem(QuoteId = quote.Id, PricebookEntryId = vehicleEntry.Id, Quantity = 1, UnitPrice = 30000);
        opp.Discount_Percent__c = 0;
        opp.Approval_Status__c = 'Not_Required';
        update opp;

        Test.startTest();
        QuoteSummaryController.SummaryDto summary = QuoteSummaryController.getSummary(quote.Id);
        Test.stopTest();

        System.assertEquals(30000, summary.adjustedSubtotal, 'adjusted subtotal stored separately');
        System.assertEquals(30000, summary.listSubtotal, 'list subtotal from summed lines');
        System.assertEquals(0, summary.discountPercent, 'zero net discount when no rules apply');
        System.assertEquals('Not_Required', summary.approvalStatus, 'no approval required');
    }

    private static User persona(String mode) {
        String lastName = 'QuoteSecurity' + mode;
        return [SELECT Id FROM User WHERE LastName = :lastName LIMIT 1];
    }

    private static Quote securityQuote(User owner) {
        Account account = makeAccount('Security');
        account.OwnerId = owner.Id;
        update account;
        Opportunity opportunity = new Opportunity(
            Name = 'Security Opportunity', AccountId = account.Id, OwnerId = owner.Id,
            StageName = 'Prospecting', CloseDate = Date.today().addDays(30)
        );
        insert opportunity;
        Product2 product = makeProduct('Security Vehicle', 'Vehicle_Trim', 28000);
        Quote quote = new Quote(
            Name = 'Security Quote', OpportunityId = opportunity.Id, Pricebook2Id = STD_PB,
            Adjusted_Subtotal__c = 28000, Rule_Applied_Count__c = 0
        );
        insert quote;
        insert new QuoteLineItem(
            QuoteId = quote.Id, Quantity = 1, UnitPrice = 28000,
            PricebookEntryId = [SELECT Id FROM PricebookEntry WHERE Product2Id = :product.Id AND Pricebook2Id = :STD_PB].Id
        );
        return quote;
    }

    @isTest
    static void getSummary_preservesExistingSalesRepAccess() {
        User rep = persona('sales');
        Quote quote = securityQuote(rep);
        System.runAs(rep) {
            QuoteSummaryController.SummaryDto summary = QuoteSummaryController.getSummary(quote.Id);
            System.assertEquals(28000, summary.adjustedSubtotal, 'sales rep retains adjusted subtotal');
            System.assertEquals(28000, summary.grandTotal, 'sales rep retains standard total');
            System.assertEquals('Vehicle_Trim', summary.lines[0].category, 'relationship FLS permits category');
        }
    }

    @isTest
    static void quoteWorkflow_permissionsAndFullStackPricing() {
        User rep = persona('workflow');
        Account account = makeAccount('ScopedWorkflow');
        Contact buyer = P2TestDataFactory.makeContact(account.Id, 'WorkflowBuyer');
        insert new Loyalty_Member__c(Contact__c = buyer.Id, Tier__c = 'Gold', Status__c = 'Active');
        Vehicle_Model__c model = new Vehicle_Model__c(Name = 'Test Model Premium', Trim__c = 'Premium');
        insert model;
        Vehicle__c vehicle = makeVehicle(model.Id, 120);
        Product2 vehicleProduct = makeProduct('Test Model Premium', 'Vehicle_Trim', 30000);
        Product2 accessory = makeProduct('Floor Mats', 'Accessory', 2000);
        account.OwnerId = rep.Id;
        update account;
        Opportunity opportunity = new Opportunity(
            Name = 'Scoped Workflow Opportunity', AccountId = account.Id, OwnerId = rep.Id,
            Vehicle__c = vehicle.Id, StageName = 'Prospecting', CloseDate = Date.today().addDays(30)
        );
        insert opportunity;

        // Direct Apex calls do not enforce the LWC entry-point class gate, so check it separately.
        Id permissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'PS_Quote_Workflows'].Id;
        Set<Id> controllerIds = new Map<Id, ApexClass>([
            SELECT Id FROM ApexClass WHERE Name IN ('QuoteBuilderController', 'QuoteSummaryController')
        ]).keySet();
        System.assertEquals(2, controllerIds.size(), 'both controllers exist');
        System.assertEquals(2, [SELECT COUNT() FROM SetupEntityAccess WHERE ParentId = :permissionSetId AND SetupEntityId IN :controllerIds],
            'both LWC controller entry points are explicitly granted');

        System.runAs(rep) {
            System.assert(Schema.SObjectType.Quote.isCreateable(), 'quote creation is authorized');
            System.assert(!Schema.SObjectType.Quote.isDeletable(), 'quote deletion is not granted');
            System.assert(!Schema.SObjectType.Vehicle__c.isUpdateable(), 'vehicle writes are not granted');
            System.assert(!Schema.SObjectType.Loyalty_Member__c.isCreateable(), 'loyalty writes are not granted');
            System.assert(!Schema.SObjectType.Vehicle__c.fields.Invoice_Cost__c.isAccessible(), 'invoice cost stays hidden');
            System.assert(!Schema.SObjectType.Financing__c.isAccessible(), 'finance access stays absent');
            System.assert(!QuoteBuilderController.getCatalog('Vehicle_Trim').isEmpty(), 'catalog loads');
            System.assertEquals(1, QuoteBuilderController.getBuyerContacts(opportunity.Id).size(), 'buyer relationship is readable');
            QuoteBuilderController.LineInput vehicleLine = new QuoteBuilderController.LineInput();
            vehicleLine.productId = vehicleProduct.Id;
            vehicleLine.quantity = 12;
            QuoteBuilderController.LineInput accessoryLine = new QuoteBuilderController.LineInput();
            accessoryLine.productId = accessory.Id;
            accessoryLine.quantity = 1;
            Test.startTest();
            QuoteBuilderController.QuoteResult result = QuoteBuilderController.createQuote(
                opportunity.Id, buyer.Id, new List<QuoteBuilderController.LineInput>{vehicleLine, accessoryLine}
            );
            QuoteSummaryController.SummaryDto summary = QuoteSummaryController.getSummary(result.quoteId);
            Test.stopTest();
            System.assertEquals(null, result.blockerMessage, 'pricing is not blocked');
            System.assertEquals(362000, result.listSubtotal, 'CP2 list subtotal is unchanged');
            System.assertEquals(290159.20, result.adjustedSubtotal, 'CP2 stacked price is unchanged');
            System.assertEquals(19.85, result.netDiscountPercent, 'CP2 net discount is unchanged');
            System.assertEquals(4, result.rulesApplied, 'same four rules apply');
            System.assertEquals(362000, summary.grandTotal, 'standard total remains separate');
            System.assertEquals(result.adjustedSubtotal, summary.adjustedSubtotal, 'summary returns the stored CP2 amount');
            System.assertEquals(result.netDiscountPercent, summary.discountPercent, 'summary returns the stored discount');
            System.assertEquals(2, summary.lines.size(), 'both lines remain visible');
            System.assertEquals('Pending', summary.approvalStatus, 'approval stamp is unchanged');
        }
    }

    @isTest
    static void getSummary_rejectsMissingQuoteObjectRead() {
        User restricted = persona('none');
        Quote quote = securityQuote(restricted);
        System.runAs(restricted) {
            System.assert(!Schema.SObjectType.Quote.isAccessible(), 'baseline persona has no Quote Read');
            try {
                QuoteSummaryController.getSummary(quote.Id);
                System.assert(false, 'object restriction must be enforced');
            } catch (QueryException expected) {
                System.assertNotEquals(null, expected.getMessage(), 'user-mode query rejects object access');
            }
        }
    }

    private static void assertFieldDenied(String mode, Schema.SObjectField deniedField) {
        User restricted = persona(mode);
        Quote quote = securityQuote(restricted);
        System.runAs(restricted) {
            System.assert(Schema.SObjectType.Quote.isAccessible(), 'Quote object access is present');
            System.assert(Schema.SObjectType.Product2.isAccessible(), 'Product object access is present');
            System.assert(Schema.SObjectType.Opportunity.isAccessible(), 'Opportunity object access is present');
            System.assert(!deniedField.getDescribe().isAccessible(), 'the intended field is specifically restricted');
            for (Schema.SObjectField field : new List<Schema.SObjectField>{
                Schema.SObjectType.Quote.fields.Adjusted_Subtotal__c.getSObjectField(),
                Schema.SObjectType.Quote.fields.Rule_Applied_Count__c.getSObjectField(),
                Schema.SObjectType.Quote.fields.Quote_Valid_Until__c.getSObjectField(),
                Schema.SObjectType.Quote.fields.GrandTotal.getSObjectField(),
                Schema.SObjectType.Product2.fields.Category__c.getSObjectField(),
                Schema.SObjectType.Opportunity.fields.Discount_Percent__c.getSObjectField(),
                Schema.SObjectType.Opportunity.fields.Approval_Status__c.getSObjectField()
            }) {
                if (field != deniedField) {
                    System.assert(field.getDescribe().isAccessible(), 'other queried fields remain readable: ' + field);
                }
            }
            try {
                QuoteSummaryController.getSummary(quote.Id);
                System.assert(false, 'restricted field must not be returned');
            } catch (QueryException expected) {
                System.assertNotEquals(null, expected.getMessage(), 'user-mode query rejects field access');
            }
        }
    }

    @isTest
    static void getSummary_rejectsMissingQuoteFieldRead() {
        assertFieldDenied('quote', Schema.SObjectType.Quote.fields.Adjusted_Subtotal__c.getSObjectField());
    }

    @isTest
    static void getSummary_rejectsMissingProductRelationshipFieldRead() {
        assertFieldDenied('product', Schema.SObjectType.Product2.fields.Category__c.getSObjectField());
    }

    @isTest
    static void getSummary_rejectsMissingOpportunityFieldRead() {
        assertFieldDenied('opportunity', Schema.SObjectType.Opportunity.fields.Discount_Percent__c.getSObjectField());
    }

    @isTest
    static void getSummary_rejectsUnsharedQuote() {
        Quote quote = securityQuote(new User(Id = UserInfo.getUserId()));
        System.runAs(persona('workflow')) {
            System.assert(Schema.SObjectType.Quote.isAccessible(), 'object access is present');
            try {
                QuoteSummaryController.getSummary(quote.Id);
                System.assert(false, 'unshared quote must remain inaccessible');
            } catch (QueryException expected) {
                System.assertEquals(0, [SELECT COUNT() FROM Quote WHERE Id = :quote.Id WITH USER_MODE], 'no record becomes visible');
            }
        }
    }

    @isTest
    static void getSummary_adminPreservesStoredNullPricingFields() {
        User administrator = new User(Id = UserInfo.getUserId());
        Quote quote = securityQuote(administrator);
        quote.Adjusted_Subtotal__c = null;
        quote.Rule_Applied_Count__c = 1;
        update quote;
        System.runAs(administrator) {
            QuoteSummaryController.SummaryDto summary = QuoteSummaryController.getSummary(quote.Id);
            System.assertEquals(null, summary.adjustedSubtotal, 'missing stored pricing is not manufactured');
            System.assertEquals(null, summary.discountPercent, 'missing stored discount remains null');
            System.assertEquals(1, summary.rulesApplied, 'stored rule count remains independent');
            System.assertEquals(28000, summary.grandTotal, 'standard grand total still renders');
            System.assertEquals(1, summary.lines.size(), 'standard quote lines remain readable');
        }
    }
}
