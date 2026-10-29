@isTest
private class QuoteBuilderControllerTest {
    private static final Id STD_PB = Test.getStandardPricebookId();
    private static final String PERSONA_REP_USERNAME = 'persona.save.rep@northgate.example';

    private static Account makeAccount(String seed) {
        return P2TestDataFactory.makeAccount(seed);
    }

    private static Product2 makeProduct(String name, String category, Decimal unitPrice) {
        Product2 p = new Product2(Name = name, Category__c = category, IsActive = true);
        insert p;
        insert new PricebookEntry(Pricebook2Id = STD_PB, Product2Id = p.Id, IsActive = true, UnitPrice = unitPrice);
        return p;
    }

    private static Opportunity makeOpp(Id accountId, Id vehicleId) {
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = accountId,
            Vehicle__c = vehicleId
        );
        insert opp;
        return opp;
    }

    private static User personaRep() {
        return [SELECT Id FROM User WHERE Username = :PERSONA_REP_USERNAME LIMIT 1];
    }

    private static Vehicle__c makeVehicle(Id modelId, Integer daysAgo) {
        Vehicle__c v = new Vehicle__c(
            VIN__c = '2HGBH41JXMN109187',
            Vehicle_Model__c = modelId,
            Status__c = 'Available',
            Acquisition_Date__c = Date.today().addDays(-daysAgo)
        );
        insert v;
        return v;
    }

    private static QuoteBuilderController.LineInput line(Id productId, Decimal qty) {
        QuoteBuilderController.LineInput input = new QuoteBuilderController.LineInput();
        input.productId = productId;
        input.quantity = qty;
        return input;
    }

    @TestSetup
    static void setup() {
        insert new Rooftop__c(Name = 'Northgate Downtown');

        // Persona user + permission assignment are setup-object DML; run them inside System.runAs
        // so they aren't mixed with the non-setup Rooftop__c insert above (MIXED_DML_OPERATION).
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Profile salesProfile = [SELECT Id FROM Profile WHERE Name = 'NG_Sales' LIMIT 1];
            User rep = new User(
                Alias = 'psnsave',
                Email = PERSONA_REP_USERNAME,
                EmailEncodingKey = 'UTF-8',
                LastName = 'PersonaSaveRep',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = salesProfile.Id,
                TimeZoneSidKey = 'America/New_York',
                UserName = PERSONA_REP_USERNAME
            );
            insert rep;
            List<PermissionSet> permissionSets = [
                SELECT Id FROM PermissionSet WHERE Name IN ('PS_Sales_Rep', 'NG_Lightning_Access')
            ];
            List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
            for (PermissionSet ps : permissionSets) {
                assignments.add(new PermissionSetAssignment(AssigneeId = rep.Id, PermissionSetId = ps.Id));
            }
            insert assignments;
        }
    }

    @isTest
    static void getCatalog_returnsOnlyRequestedCategory() {
        Product2 accessory = makeProduct('Cargo Net', 'Accessory', 100);
        makeProduct('Floor Tray', 'Accessory', 250);

        List<QuoteBuilderController.CatalogItem> items = QuoteBuilderController.getCatalog('Accessory');

        System.assertEquals(2, items.size(), 'both accessories returned');
        for (QuoteBuilderController.CatalogItem item : items) {
            System.assertEquals('Accessory', item.category, 'category filtered');
        }
    }

    @isTest
    static void getBuyerContacts_returnsAccountContacts() {
        Account acc = makeAccount('Contacts');
        Contact first = P2TestDataFactory.makeContact(acc.Id, 'Alpha');
        P2TestDataFactory.makeContact(acc.Id, 'Beta');
        Opportunity opp = makeOpp(acc.Id, null);

        List<QuoteBuilderController.BuyerOption> options = QuoteBuilderController.getBuyerContacts(opp.Id);

        System.assertEquals(2, options.size(), 'both account contacts returned');
        System.assertEquals(first.Id, options[0].value, 'sorted by name');
        System.assertEquals('Alpha', options[0].label, 'label is contact name');
    }

    @isTest
    static void createQuote_happyPath_writesEngineAndStamps() {
        Account acc = makeAccount('Happy');
        Contact buyer = P2TestDataFactory.makeContact(acc.Id, 'Buyer');
        insert new Loyalty_Member__c(Contact__c = buyer.Id, Tier__c = 'Gold', Status__c = 'Active');
        Vehicle_Model__c model = new Vehicle_Model__c(Name = 'Test Model Premium', Trim__c = 'Premium');
        insert model;
        Vehicle__c vehicle = makeVehicle(model.Id, 120);
        Product2 vehicleProduct = makeProduct('Test Model Premium', 'Vehicle_Trim', 30000);
        Product2 accessory = makeProduct('Floor Mats', 'Accessory', 2000);
        Opportunity opp = makeOpp(acc.Id, vehicle.Id);

        List<QuoteBuilderController.LineInput> lines = new List<QuoteBuilderController.LineInput>{
            line(vehicleProduct.Id, 12),
            line(accessory.Id, 1)
        };

        Test.startTest();
        QuoteBuilderController.QuoteResult result = QuoteBuilderController.createQuote(opp.Id, buyer.Id, lines);
        Test.stopTest();

        System.assert(result.quoteId != null, 'quote created');
        System.assertEquals(true, result.vehicleBasisIdentified, 'basis identified');
        System.assertEquals(290159.2, result.adjustedSubtotal, 'engine result written to wrapper');
        System.assertEquals(4, result.rulesApplied, 'four categories applied');
        System.assertEquals(19.85, result.netDiscountPercent, 'net discount percent');

        Quote quote = [SELECT Adjusted_Subtotal__c, Rule_Applied_Count__c, Quote_Valid_Until__c, Buyer_Contact__c,
            GrandTotal FROM Quote WHERE Id = :result.quoteId];
        System.assertEquals(290159.2, quote.Adjusted_Subtotal__c, 'adjusted subtotal written to quote');
        System.assertEquals(4, quote.Rule_Applied_Count__c, 'rule count written');
        System.assertEquals(Date.today().addDays(30), quote.Quote_Valid_Until__c, 'valid-until default set');
        System.assertEquals(buyer.Id, quote.Buyer_Contact__c, 'buyer stored');

        Opportunity stamped = [SELECT Discount_Percent__c, Approval_Status__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(19.85, stamped.Discount_Percent__c, 'discount percent stamped');
        System.assertEquals('Pending', stamped.Approval_Status__c, 'above 5 percent goes pending');
    }

    @isTest
    static void createQuote_noRules_keepsListAndNotRequired() {
        Account acc = makeAccount('Plain');
        Vehicle_Model__c model = new Vehicle_Model__c(Name = 'Test Model LX', Trim__c = 'LX');
        insert model;
        Vehicle__c vehicle = makeVehicle(model.Id, 10);
        Product2 vehicleProduct = makeProduct('Test Model LX', 'Vehicle_Trim', 30000);
        Opportunity opp = makeOpp(acc.Id, vehicle.Id);

        List<QuoteBuilderController.LineInput> lines = new List<QuoteBuilderController.LineInput>{
            line(vehicleProduct.Id, 1)
        };

        QuoteBuilderController.QuoteResult result = QuoteBuilderController.createQuote(opp.Id, null, lines);

        System.assertEquals(0, result.rulesApplied, 'no rules for fresh LX');
        System.assertEquals(30000, result.adjustedSubtotal, 'list price remains');

        Opportunity stamped = [SELECT Discount_Percent__c, Approval_Status__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(0, stamped.Discount_Percent__c, 'no discount');
        System.assertEquals('Not_Required', stamped.Approval_Status__c, 'no approval needed');
    }

    @isTest
    static void createQuote_buyerMismatch_noLoyalty() {
        Account acc = makeAccount('Mismatch');
        Account other = makeAccount('Other');
        Contact buyer = P2TestDataFactory.makeContact(other.Id, 'WrongAccount');
        insert new Loyalty_Member__c(Contact__c = buyer.Id, Tier__c = 'Platinum', Status__c = 'Active');
        Vehicle_Model__c model = new Vehicle_Model__c(Name = 'Test Model LX', Trim__c = 'LX');
        insert model;
        Vehicle__c vehicle = makeVehicle(model.Id, 0);
        Product2 vehicleProduct = makeProduct('Test Model LX', 'Vehicle_Trim', 30000);
        Opportunity opp = makeOpp(acc.Id, vehicle.Id);

        List<QuoteBuilderController.LineInput> lines = new List<QuoteBuilderController.LineInput>{
            line(vehicleProduct.Id, 1)
        };

        QuoteBuilderController.QuoteResult result = QuoteBuilderController.createQuote(opp.Id, buyer.Id, lines);

        System.assertEquals(30000, result.adjustedSubtotal, 'no loyalty for out-of-account buyer');
        System.assertEquals(0, result.rulesApplied, 'no rules');
    }

    @isTest
    static void createQuote_crossCategoryNoVehicle_keepsListAndStoresBothLines() {
        // Regression for the LWC-to-Apex boundary and cross-category selection:
        // Vehicle_Trim + Service_Package with no Opportunity.Vehicle__c must save both
        // lines and apply no rules (S-3 browser scenario).
        Account acc = makeAccount('CrossCat');
        Contact buyer = P2TestDataFactory.makeContact(acc.Id, 'BuyerCC');
        Product2 vehicleProduct = makeProduct('Test Model LX', 'Vehicle_Trim', 25000);
        Product2 serviceProduct = makeProduct('Test Service Package', 'Service_Package', 1500);
        Opportunity opp = makeOpp(acc.Id, null);

        List<QuoteBuilderController.LineInput> lines = new List<QuoteBuilderController.LineInput>{
            line(vehicleProduct.Id, 1),
            line(serviceProduct.Id, 1)
        };

        QuoteBuilderController.QuoteResult result = QuoteBuilderController.createQuote(opp.Id, buyer.Id, lines);

        System.assertEquals(26500, result.listSubtotal, 'list subtotal sums both categories');
        System.assertEquals(26500, result.adjustedSubtotal, 'no rules with no vehicle');
        System.assertEquals(0, result.rulesApplied, 'no rules applied');
        System.assertEquals(false, result.vehicleBasisIdentified, 'no vehicle basis');

        List<QuoteLineItem> qlis = [
            SELECT Quantity, UnitPrice, PricebookEntry.Product2.Category__c
            FROM QuoteLineItem
            WHERE QuoteId = :result.quoteId
            ORDER BY PricebookEntry.Product2.Category__c
        ];
        System.assertEquals(2, qlis.size(), 'both lines created');
        System.assertEquals('Service_Package', qlis[0].PricebookEntry.Product2.Category__c, 'service line stored');
        System.assertEquals('Vehicle_Trim', qlis[1].PricebookEntry.Product2.Category__c, 'vehicle line stored');

        Opportunity stamped = [SELECT Discount_Percent__c, Approval_Status__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(0, stamped.Discount_Percent__c, 'no discount');
        System.assertEquals('Not_Required', stamped.Approval_Status__c, 'not required');
    }

    @isTest
    static void createQuote_emptyLines_throws() {
        Account acc = makeAccount('Empty');
        Opportunity opp = makeOpp(acc.Id, null);

        try {
            QuoteBuilderController.createQuote(opp.Id, null, new List<QuoteBuilderController.LineInput>());
            System.assert(false, 'empty lines must throw');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('At least one product line is required.'), 'message names the requirement');
        }
    }

    @isTest
    static void createQuote_existingQuote_throwsAndLeavesApprovalUntouched() {
        Account acc = makeAccount('ExistingQuote');
        Contact buyer = P2TestDataFactory.makeContact(acc.Id, 'BuyerExisting');
        Product2 product = makeProduct('Test Accessory Existing', 'Accessory', 100);
        Opportunity opp = makeOpp(acc.Id, null);
        List<QuoteBuilderController.LineInput> lines = new List<QuoteBuilderController.LineInput>{
            line(product.Id, 1)
        };

        QuoteBuilderController.QuoteResult first = QuoteBuilderController.createQuote(opp.Id, buyer.Id, lines);
        System.assertNotEquals(null, first.quoteId, 'first quote created');

        opp.Discount_Percent__c = 8.92;
        opp.Approval_Status__c = 'Pending';
        update opp;

        Opportunity before = [
            SELECT Discount_Percent__c, Approval_Status__c
            FROM Opportunity WHERE Id = :opp.Id
        ];
        try {
            QuoteBuilderController.createQuote(opp.Id, buyer.Id, lines);
            System.assert(false, 'a second quote must be rejected');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('already has a quote'), 'message names the existing quote: ' + e.getMessage());
        }

        Opportunity after = [
            SELECT Discount_Percent__c, Approval_Status__c
            FROM Opportunity WHERE Id = :opp.Id
        ];
        System.assertEquals(before.Discount_Percent__c, after.Discount_Percent__c, 'discount unchanged');
        System.assertEquals(before.Approval_Status__c, after.Approval_Status__c, 'approval status unchanged');
        System.assertEquals(1, [SELECT COUNT() FROM Quote WHERE OpportunityId = :opp.Id], 'no second quote created');
    }

    @isTest
    static void createQuote_blocker_doesNotStampOpportunity() {
        Account acc = makeAccount('Blocker');
        Contact buyer = P2TestDataFactory.makeContact(acc.Id, 'BuyerBlocker');
        Vehicle_Model__c model = new Vehicle_Model__c(Name = 'Test Model Blocker A', Trim__c = 'LX');
        insert model;
        Vehicle__c vehicle = makeVehicle(model.Id, 10);
        Product2 product = makeProduct('Test Model Blocker B', 'Vehicle_Trim', 30000);
        Opportunity opp = makeOpp(acc.Id, vehicle.Id);
        List<QuoteBuilderController.LineInput> lines = new List<QuoteBuilderController.LineInput>{
            line(product.Id, 1)
        };

        Opportunity before = [
            SELECT Discount_Percent__c, Approval_Status__c
            FROM Opportunity WHERE Id = :opp.Id
        ];
        QuoteBuilderController.QuoteResult result = QuoteBuilderController.createQuote(opp.Id, buyer.Id, lines);
        System.assertNotEquals(null, result.blockerMessage, 'ambiguous vehicle basis blocks pricing');

        Opportunity after = [
            SELECT Discount_Percent__c, Approval_Status__c
            FROM Opportunity WHERE Id = :opp.Id
        ];
        System.assertEquals(before.Discount_Percent__c, after.Discount_Percent__c, 'blocked pricing must not stamp discount');
        System.assertEquals(before.Approval_Status__c, after.Approval_Status__c, 'blocked pricing must not stamp approval status');
    }

    @isTest
    static void getCatalog_loadsUnderSalesPersonaAccess() {
        // Regression test: sales rep (NG_Sales profile + PS_Sales_Rep) must be able
        // to load the catalog. getCatalog runs WITH USER_MODE, so the persona needs
        // Read on Pricebook2, PricebookEntry, Product2 and FLS on Product2.Category__c.
        // Missing grants surface as enforced-query failures (browser 'tmpVar1').
        // Self-contained: creates its own user, data, and permission assignment.

        Product2 vehicleProduct = makeProduct('Test Model SP', 'Vehicle_Trim', 30000);

        User salesRep = personaRep();

        System.runAs(salesRep) {
            List<QuoteBuilderController.CatalogItem> items = QuoteBuilderController.getCatalog('Vehicle_Trim');
            System.assert(!items.isEmpty(), 'catalog must load at least one Vehicle_Trim item under sales-persona access');
            Boolean found = false;
            for (QuoteBuilderController.CatalogItem item : items) {
                if (item.productId == vehicleProduct.Id) {
                    found = true;
                    System.assertEquals('Test Model SP', item.name, 'name matches Product2.Name');
                    System.assertEquals('Vehicle_Trim', item.category, 'category matches Product2.Category__c');
                    System.assertEquals(30000, item.unitPrice, 'unitPrice matches PricebookEntry.UnitPrice');
                    break;
                }
            }
            System.assert(found, 'the test product must be visible in the catalog under sales-persona access');
        }
    }

    @isTest
    static void getBuyerContacts_loadsUnderSalesPersonaAccess() {
        // Regression test: buyer dropdown must load for the sales persona.
        // Self-contained: creates its own user, data, and permission assignment.

        Account acc = makeAccount('SalesPersonaBuyers');
        Contact c1 = P2TestDataFactory.makeContact(acc.Id, 'AlphaSP');
        Contact c2 = P2TestDataFactory.makeContact(acc.Id, 'BetaSP');
        Opportunity opp = makeOpp(acc.Id, null);

        User salesRep = personaRep();
        acc.OwnerId = salesRep.Id;
        update acc;
        opp.OwnerId = salesRep.Id;
        update opp;

        System.runAs(salesRep) {
            List<QuoteBuilderController.BuyerOption> options = QuoteBuilderController.getBuyerContacts(opp.Id);
            System.assertEquals(2, options.size(), 'both contacts must be visible under sales-persona access');
            System.assertEquals('AlphaSP', options[0].label, 'first contact sorted by name');
            System.assertEquals(c1.Id, options[0].value, 'value is the first contact Id');
        }
    }

    @isTest
    static void createQuote_savesUnderSalesPersonaAccess() {
        // Regression: the sales persona (NG_Sales profile + PS_Sales_Rep) must be able to
        // save a quote. createQuote traverses Vehicle__r.Vehicle_Model__r (Name, Trim) and
        // Vehicle__r.Inventory_Age_Days__c. Without object Read on Vehicle_Model__c and FLS
        // on its fields, the traversal is denied and Salesforce masks the failure as
        // "Didn't understand relationship 'Vehicle_Model__r' in field path." (browser Save).
        // User + permission assignment come from @TestSetup (separate transaction).

        Account acc = makeAccount('PersonaSave');
        Contact buyer = P2TestDataFactory.makeContact(acc.Id, 'BuyerPS');
        insert new Loyalty_Member__c(Contact__c = buyer.Id, Tier__c = 'Gold', Status__c = 'Active');
        Vehicle_Model__c model = new Vehicle_Model__c(Name = 'Test Model Persona', Trim__c = 'Limited');
        insert model;
        Vehicle__c vehicle = makeVehicle(model.Id, 30);
        Product2 vehicleProduct = makeProduct('Test Model Persona', 'Vehicle_Trim', 28000);
        Opportunity opp = makeOpp(acc.Id, vehicle.Id);

        User salesRep = personaRep();
        acc.OwnerId = salesRep.Id;
        update acc;
        opp.OwnerId = salesRep.Id;
        update opp;

        List<QuoteBuilderController.LineInput> lines = new List<QuoteBuilderController.LineInput>{
            line(vehicleProduct.Id, 1)
        };

        System.runAs(salesRep) {
            QuoteBuilderController.QuoteResult result =
                QuoteBuilderController.createQuote(opp.Id, buyer.Id, lines);
            System.assert(result.quoteId != null, 'quote created under sales-persona access');
            System.assertEquals(28000, result.listSubtotal, 'list subtotal from the standard price book');
        }
    }

    private static Quote pendingQuote(Decimal discountPercent) {
        Account acc = makeAccount('Submit' + String.valueOf(discountPercent).replace('.', ''));
        Opportunity opp = makeOpp(acc.Id, null);
        opp.Discount_Percent__c = discountPercent;
        opp.Approval_Status__c = 'Pending';
        opp.OwnerId = personaRep().Id;
        acc.OwnerId = personaRep().Id;
        update acc;
        update opp;
        Quote quote = new Quote(
            Name = 'Submit Test Quote',
            OpportunityId = opp.Id,
            Pricebook2Id = STD_PB
        );
        insert quote;
        return quote;
    }

    @isTest
    static void submitForApproval_belowThreshold_rejectedWithoutApprovalCall() {
        Quote quote = pendingQuote(3);
        System.runAs(personaRep()) {
            try {
                QuoteBuilderController.submitForApproval(quote.Id);
                System.assert(false, 'discount at or below 5 must not submit');
            } catch (Exception e) {
                System.assert(
                    e.getMessage().contains('does not require approval'),
                    'tier guard rejects below-threshold submit: ' + e.getMessage()
                );
            }
        }
    }

    @isTest
    static void submitForApproval_above10ResolvesVpApprover() {
        // Requires VP_Discount_Approval active and a live VP_Sales user.
        // Verifies end-to-end controller derivation: >10% resolves the VP,
        // submits, and the VP becomes the sole workitem actor.
        List<ProcessDefinition> defs = [SELECT State FROM ProcessDefinition WHERE DeveloperName = 'VP_Discount_Approval'];
        System.assert(!defs.isEmpty() && defs[0].State == 'Active', 'Activate VP_Discount_Approval before this test runs.');
        Id vpId = [SELECT Id FROM User WHERE UserRole.DeveloperName = 'VP_Sales' AND IsActive = true ORDER BY CreatedDate, Id LIMIT 1].Id;
        Quote quote = pendingQuote(12);
        Id instanceId;
        System.runAs(personaRep()) {
            instanceId = QuoteBuilderController.submitForApproval(quote.Id);
        }
        System.assertNotEquals(null, instanceId, 'submission creates a process instance');
        List<Id> actors = new List<Id>();
        for (ProcessInstanceWorkitem workitem : [
            SELECT ActorId FROM ProcessInstanceWorkitem WHERE ProcessInstanceId = :instanceId
        ]) {
            actors.add(workitem.ActorId);
        }
        System.assertEquals(1, actors.size(), 'one VP actor');
        System.assertEquals(vpId, actors[0], 'controller derived the VP approver');
    }
}