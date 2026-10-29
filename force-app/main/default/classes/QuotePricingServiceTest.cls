@isTest
private class QuotePricingServiceTest {
    private static final Id STD_PB = Test.getStandardPricebookId();

    private static Vehicle_Model__c makeModel(String trim) {
        Vehicle_Model__c m = new Vehicle_Model__c(Name = 'Test Model ' + trim, Trim__c = trim);
        insert m;
        return m;
    }

    private static Vehicle__c makeVehicle(Id modelId, Integer acquisitionDaysAgo) {
        Vehicle__c v = new Vehicle__c(
            VIN__c = '1HGBH41JXMN109186',
            Vehicle_Model__c = modelId,
            Status__c = 'Available',
            Acquisition_Date__c = Date.today().addDays(-acquisitionDaysAgo)
        );
        insert v;
        return v;
    }

    private static Product2 makeProduct(String name, String category, Decimal unitPrice) {
        Product2 p = new Product2(Name = name, Category__c = category, IsActive = true);
        insert p;
        insert new PricebookEntry(Pricebook2Id = STD_PB, Product2Id = p.Id, IsActive = true, UnitPrice = unitPrice);
        return p;
    }

    private static Quote makeQuote(Id opportunityId, Id buyerContactId) {
        return new Quote(
            OpportunityId = opportunityId,
            Name = 'Test Quote',
            Pricebook2Id = STD_PB,
            ExpirationDate = Date.today().addDays(30),
            Quote_Valid_Until__c = Date.today().addDays(30),
            Buyer_Contact__c = buyerContactId
        );
    }

    private static QuoteLineItem makeLine(Id quoteId, Id productId, Decimal qty) {
        PricebookEntry entry = [SELECT Id, UnitPrice FROM PricebookEntry WHERE Product2Id = :productId AND Pricebook2Id = :STD_PB LIMIT 1];
        QuoteLineItem line = new QuoteLineItem(
            QuoteId = quoteId,
            PricebookEntryId = entry.Id,
            Quantity = qty,
            UnitPrice = entry.UnitPrice
        );
        insert line;
        return line;
    }

    private static List<QuoteLineItem> listedAndQueriedLines(Id quoteId, Decimal qty, Id vehicleProductId) {
        makeLine(quoteId, vehicleProductId, qty);
        return [SELECT Id, UnitPrice, Quantity, PricebookEntry.Product2.Category__c, PricebookEntry.Product2.Name
            FROM QuoteLineItem WHERE QuoteId = :quoteId];
    }

    private static Opportunity makeOpportunity(Id vehicleId, Id accountId) {
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Vehicle__c = vehicleId,
            AccountId = accountId
        );
        insert opp;
        return opp;
    }

    private static List<Price_Rule__mdt> catalog() {
        return new List<Price_Rule__mdt>{
            catalogRule('Trim_Premium_Premium', 'Premium', 'Trim', 'Equals', 'Premium', 5, 10),
            catalogRule('Trim_Premium_Limited', 'Premium', 'Trim', 'Equals', 'Limited', 3, 10),
            catalogRule('Aged_Inventory_Discount_60', 'Discount', 'Age_Days', 'Greater_Than', '60', 10, 20),
            catalogRule('Aged_Inventory_Discount_90', 'Discount', 'Age_Days', 'Greater_Than', '90', 15, 21),
            catalogRule('Loyalty_Bronze_Discount', 'Discount', 'Loyalty_Tier', 'Equals', 'Bronze', 1, 28),
            catalogRule('Loyalty_Silver_Discount', 'Discount', 'Loyalty_Tier', 'Equals', 'Silver', 2, 29),
            catalogRule('Loyalty_Gold_Member_Discount', 'Discount', 'Loyalty_Tier', 'Equals', 'Gold', 3, 30),
            catalogRule('Loyalty_Platinum_Discount', 'Discount', 'Loyalty_Tier', 'Equals', 'Platinum', 5, 31),
            catalogRule('Volume_Discount_Over_10', 'Discount', 'Volume', 'Greater_Than', '10', 8, 35),
            catalogRule('Fleet_Discount_Over_5', 'Discount', 'Volume', 'Greater_Than', '5', 5, 40)
        };
    }

    private static Price_Rule__mdt catalogRule(String name, String type, String attribute, String operator, String value, Decimal percent, Decimal priority) {
        return new Price_Rule__mdt(
            DeveloperName = name,
            Rule_Type__c = type,
            Attribute__c = attribute,
            Operator__c = operator,
            Value__c = value,
            Percent_Adjustment__c = percent,
            Fixed_Adjustment__c = 0,
            Priority__c = priority,
            Is_Active__c = true,
            Target__c = 'Quote_Line'
        );
    }

    private static QuotePricingService.VehicleContext vehicleContext(Id modelId, Id vehicleProductId, Decimal ageDays) {
        QuotePricingService.VehicleContext context = new QuotePricingService.VehicleContext();
        context.hasVehicle = modelId != null;
        if (modelId != null) {
            context.modelName = [SELECT Name FROM Product2 WHERE Id = :vehicleProductId].Name;
            context.trim = [SELECT Trim__c FROM Vehicle_Model__c WHERE Id = :modelId].Trim__c;
            context.ageDays = ageDays;
        }
        return context;
    }

    private static QuotePricingService.BuyerContext buyerContext(String tier, Boolean associated) {
        QuotePricingService.BuyerContext context = new QuotePricingService.BuyerContext();
        context.tier = tier;
        context.associated = associated;
        return context;
    }

    @TestSetup
    static void setup() {
        insert new Rooftop__c(Name = 'Northgate Downtown');
    }

    @isTest
    static void fullStack_appliesAllWinners_inApprovedOrder() {
        // Calculation trace (W-1–W-4 approved order: discounts first by Priority__c,
        // then premiums; vehicle-only basis for Trim/Age; per-rule round2).
        //   listSubtotal  = 12 * 30000 (Vehicle_Trim) + 1 * 2000 (Accessory) = 362000
        //   Age 90 (Discount, vehicle, 15%):    vehicleRun 360000 * 0.85 = 306000
        //   Loyalty Gold (Discount, quote, 3%):  run 308000 * 0.97 = 298760
        //   Volume Over_10 (Discount, quote, 8%): run 298760 * 0.92 = 274859.20
        //   Trim Premium (Premium, vehicle, 5%): vehicleRun 306000 * 1.05 = 321300
        //                                          run 274859.20 - 306000 + 321300 = 290159.20
        //   netDiscountPercent = (362000 - 290159.20) / 362000 * 100 = 19.85
        Account acc = P2TestDataFactory.makeAccount('Stack');
        Contact buyer = P2TestDataFactory.makeContact(acc.Id, 'Buyer');
        Vehicle_Model__c model = makeModel('Premium');
        Product2 vehicleProduct = makeProduct('Test Model Premium', 'Vehicle_Trim', 30000);
        Product2 accessory = makeProduct('Floor Mats', 'Accessory', 2000);
        Opportunity opp = makeOpportunity(makeVehicle(model.Id, 120).Id, acc.Id);
        Quote quote = makeQuote(opp.Id, buyer.Id);
        insert quote;
        makeLine(quote.Id, accessory.Id, 1);
        List<QuoteLineItem> lines = listedAndQueriedLines(quote.Id, 12, vehicleProduct.Id);

        QuotePricingService.QuotePricingResult result = QuotePricingService.evaluate(
            quote, lines, catalog(),
            vehicleContext(model.Id, vehicleProduct.Id, 120),
            buyerContext('Gold', true)
        );

        System.assertEquals(362000, result.listSubtotal, 'list subtotal: 12*30000 + 1*2000');
        System.assertEquals(290159.20, result.adjustedSubtotal, 'adjusted with all four categories at qty=12');
        System.assertEquals(19.85, result.netDiscountPercent, 'net discount percent at qty=12');
        System.assertEquals(4, result.rulesApplied, 'four rules applied');
        System.assertEquals(4, result.appliedRules.size(), 'four applied rule records');
        System.assertEquals('Aged_Inventory_Discount_90', result.appliedRules[0].developerName, 'age 90 first discount');
        System.assertEquals('Loyalty_Gold_Member_Discount', result.appliedRules[1].developerName, 'loyalty gold second discount');
        System.assertEquals('Volume_Discount_Over_10', result.appliedRules[2].developerName, 'volume over10 third discount');
        System.assertEquals('Trim_Premium_Premium', result.appliedRules[3].developerName, 'trim premium after discounts');
        System.assertEquals(321300, result.vehicleAdjustedPrice, 'vehicle basis after age 90 then trim premium at qty=12');
    }

    @isTest
    static void age60_boundary_applies60only() {
        Account acc = P2TestDataFactory.makeAccount('A60');
        Vehicle_Model__c model = makeModel('LX');
        Product2 vehicleProduct = makeProduct('Test Model LX', 'Vehicle_Trim', 30000);
        Opportunity opp = makeOpportunity(makeVehicle(model.Id, 70).Id, acc.Id);
        Quote quote = makeQuote(opp.Id, null);
        insert quote;
        List<QuoteLineItem> lines = listedAndQueriedLines(quote.Id, 1, vehicleProduct.Id);

        QuotePricingService.QuotePricingResult result = QuotePricingService.evaluate(
            quote, lines, catalog(),
            vehicleContext(model.Id, vehicleProduct.Id, 70),
            buyerContext(null, false)
        );

        System.assertEquals(27000, result.adjustedSubtotal, 'age 60 applies at 70 days');
        System.assertEquals(1, result.appliedRules.size(), 'only age 60');
        System.assertEquals('Aged_Inventory_Discount_60', result.appliedRules[0].developerName, 'age 60 winner');
    }

    @isTest
    static void age90_boundary_applies90only() {
        Account acc = P2TestDataFactory.makeAccount('A90');
        Vehicle_Model__c model = makeModel('LX');
        Product2 vehicleProduct = makeProduct('Test Model LX', 'Vehicle_Trim', 30000);
        Opportunity opp = makeOpportunity(makeVehicle(model.Id, 95).Id, acc.Id);
        Quote quote = makeQuote(opp.Id, null);
        insert quote;
        List<QuoteLineItem> lines = listedAndQueriedLines(quote.Id, 1, vehicleProduct.Id);

        QuotePricingService.QuotePricingResult result = QuotePricingService.evaluate(
            quote, lines, catalog(),
            vehicleContext(model.Id, vehicleProduct.Id, 95),
            buyerContext(null, false)
        );

        System.assertEquals(25500, result.adjustedSubtotal, 'age 90 applies at 95 days');
        System.assertEquals(1, result.appliedRules.size(), 'only age 90');
        System.assertEquals('Aged_Inventory_Discount_90', result.appliedRules[0].developerName, 'age 90 wins over age 60');
    }

    @isTest
    static void ageBelow60_noDiscount() {
        Account acc = P2TestDataFactory.makeAccount('A10');
        Vehicle_Model__c model = makeModel('LX');
        Product2 vehicleProduct = makeProduct('Test Model LX', 'Vehicle_Trim', 30000);
        Opportunity opp = makeOpportunity(makeVehicle(model.Id, 10).Id, acc.Id);
        Quote quote = makeQuote(opp.Id, null);
        insert quote;
        List<QuoteLineItem> lines = listedAndQueriedLines(quote.Id, 1, vehicleProduct.Id);

        QuotePricingService.QuotePricingResult result = QuotePricingService.evaluate(
            quote, lines, catalog(),
            vehicleContext(model.Id, vehicleProduct.Id, 10),
            buyerContext(null, false)
        );

        System.assertEquals(30000, result.adjustedSubtotal, 'no age rule before 60 days');
        System.assertEquals(0, result.rulesApplied, 'no rules');
    }

    @isTest
    static void volume12_picksOver10NotFleet() {
        Account acc = P2TestDataFactory.makeAccount('V12');
        Vehicle_Model__c model = makeModel('LX');
        Product2 vehicleProduct = makeProduct('Test Model LX', 'Vehicle_Trim', 10000);
        Opportunity opp = makeOpportunity(makeVehicle(model.Id, 0).Id, acc.Id);
        Quote quote = makeQuote(opp.Id, null);
        insert quote;
        List<QuoteLineItem> lines = listedAndQueriedLines(quote.Id, 12, vehicleProduct.Id);

        QuotePricingService.QuotePricingResult result = QuotePricingService.evaluate(
            quote, lines, catalog(),
            vehicleContext(model.Id, vehicleProduct.Id, 0),
            buyerContext(null, false)
        );

        System.assertEquals(1, result.appliedRules.size(), 'one volume winner');
        System.assertEquals('Volume_Discount_Over_10', result.appliedRules[0].developerName, 'over10 beats fleet 8 vs 5');
        System.assertEquals(110400, result.adjustedSubtotal, '120000 minus 8 percent');
    }

    @isTest
    static void volume4_noDiscount() {
        Account acc = P2TestDataFactory.makeAccount('V4');
        Vehicle_Model__c model = makeModel('LX');
        Product2 vehicleProduct = makeProduct('Test Model LX', 'Vehicle_Trim', 10000);
        Opportunity opp = makeOpportunity(makeVehicle(model.Id, 0).Id, acc.Id);
        Quote quote = makeQuote(opp.Id, null);
        insert quote;
        List<QuoteLineItem> lines = listedAndQueriedLines(quote.Id, 4, vehicleProduct.Id);

        QuotePricingService.QuotePricingResult result = QuotePricingService.evaluate(
            quote, lines, catalog(),
            vehicleContext(model.Id, vehicleProduct.Id, 0),
            buyerContext(null, false)
        );

        System.assertEquals(40000, result.adjustedSubtotal, 'no volume discount under 5');
        System.assertEquals(0, result.rulesApplied, 'no rules');
    }

    @isTest
    static void trimMismatch_noPremium_noOtherRules() {
        Account acc = P2TestDataFactory.makeAccount('TM');
        Vehicle_Model__c model = makeModel('Sport');
        Product2 vehicleProduct = makeProduct('Test Model Sport', 'Vehicle_Trim', 30000);
        Opportunity opp = makeOpportunity(makeVehicle(model.Id, 0).Id, acc.Id);
        Quote quote = makeQuote(opp.Id, null);
        insert quote;
        List<QuoteLineItem> lines = listedAndQueriedLines(quote.Id, 1, vehicleProduct.Id);

        QuotePricingService.QuotePricingResult result = QuotePricingService.evaluate(
            quote, lines, catalog(),
            vehicleContext(model.Id, vehicleProduct.Id, 0),
            buyerContext(null, false)
        );

        System.assertEquals(30000, result.adjustedSubtotal, 'Sport trim has no premium rule');
        System.assertEquals(0, result.rulesApplied, 'no rules');
    }

    @isTest
    static void loyalty_noBuyer_noDiscount() {
        Account acc = P2TestDataFactory.makeAccount('NB');
        Vehicle_Model__c model = makeModel('LX');
        Product2 vehicleProduct = makeProduct('Test Model LX', 'Vehicle_Trim', 30000);
        Opportunity opp = makeOpportunity(makeVehicle(model.Id, 0).Id, acc.Id);
        Quote quote = makeQuote(opp.Id, null);
        insert quote;
        List<QuoteLineItem> lines = listedAndQueriedLines(quote.Id, 1, vehicleProduct.Id);

        QuotePricingService.QuotePricingResult result = QuotePricingService.evaluate(
            quote, lines, catalog(),
            vehicleContext(model.Id, vehicleProduct.Id, 0),
            buyerContext(null, false)
        );

        System.assertEquals(0, result.rulesApplied, 'no buyer means no loyalty');
        System.assertEquals(30000, result.adjustedSubtotal, 'unchanged');
    }

    @isTest
    static void loyalty_buyerMismatchedAccount_noDiscount() {
        Account acc = P2TestDataFactory.makeAccount('MA');
        Vehicle_Model__c model = makeModel('LX');
        Product2 vehicleProduct = makeProduct('Test Model LX', 'Vehicle_Trim', 30000);
        Opportunity opp = makeOpportunity(makeVehicle(model.Id, 0).Id, acc.Id);
        Quote quote = makeQuote(opp.Id, null);
        insert quote;
        List<QuoteLineItem> lines = listedAndQueriedLines(quote.Id, 1, vehicleProduct.Id);

        QuotePricingService.QuotePricingResult result = QuotePricingService.evaluate(
            quote, lines, catalog(),
            vehicleContext(model.Id, vehicleProduct.Id, 0),
            buyerContext('Gold', false)
        );

        System.assertEquals(0, result.appliedRules.size(), 'mismatched buyer yields no loyalty');
        System.assertEquals(30000, result.adjustedSubtotal, 'unchanged');
    }

    @isTest
    static void loyalty_bronze_applies() {
        Account acc = P2TestDataFactory.makeAccount('LB');
        Contact buyer = P2TestDataFactory.makeContact(acc.Id, 'Bronze');
        Vehicle_Model__c model = makeModel('LX');
        Product2 vehicleProduct = makeProduct('Test Model LX', 'Vehicle_Trim', 30000);
        Opportunity opp = makeOpportunity(makeVehicle(model.Id, 0).Id, acc.Id);
        Quote quote = makeQuote(opp.Id, buyer.Id);
        insert quote;
        List<QuoteLineItem> lines = listedAndQueriedLines(quote.Id, 1, vehicleProduct.Id);

        QuotePricingService.QuotePricingResult result = QuotePricingService.evaluate(
            quote, lines, catalog(),
            vehicleContext(model.Id, vehicleProduct.Id, 0),
            buyerContext('Bronze', true)
        );

        System.assertEquals(29700, result.adjustedSubtotal, 'Bronze minus 1 percent');
        System.assertEquals(1, result.appliedRules.size(), 'one loyalty rule');
    }

    @isTest
    static void inactiveRule_skipped() {
        Account acc = P2TestDataFactory.makeAccount('IN');
        Vehicle_Model__c model = makeModel('LX');
        Product2 vehicleProduct = makeProduct('Test Model LX', 'Vehicle_Trim', 30000);
        Opportunity opp = makeOpportunity(makeVehicle(model.Id, 75).Id, acc.Id);
        Quote quote = makeQuote(opp.Id, null);
        insert quote;
        List<QuoteLineItem> lines = listedAndQueriedLines(quote.Id, 1, vehicleProduct.Id);

        List<Price_Rule__mdt> rules = catalog();
        rules[2].Is_Active__c = false;

        QuotePricingService.QuotePricingResult result = QuotePricingService.evaluate(
            quote, lines, rules,
            vehicleContext(model.Id, vehicleProduct.Id, 75),
            buyerContext(null, false)
        );

        System.assertEquals(30000, result.adjustedSubtotal, 'inactive age 60 skipped');
        System.assertEquals(0, result.rulesApplied, 'only the inactive rule matched');
    }

    @isTest
    static void zeroPricedLines_zeroFloor() {
        Account acc = P2TestDataFactory.makeAccount('ZERO');
        Vehicle_Model__c model = makeModel('Premium');
        Product2 vehicleProduct = makeProduct('Test Model Premium', 'Vehicle_Trim', 0);
        Opportunity opp = makeOpportunity(makeVehicle(model.Id, 120).Id, acc.Id);
        Quote quote = makeQuote(opp.Id, null);
        insert quote;
        List<QuoteLineItem> lines = listedAndQueriedLines(quote.Id, 1, vehicleProduct.Id);

        QuotePricingService.QuotePricingResult result = QuotePricingService.evaluate(
            quote, lines, catalog(),
            vehicleContext(model.Id, vehicleProduct.Id, 120),
            buyerContext(null, false)
        );

        System.assertEquals(0, result.adjustedSubtotal, 'zero list stays zero');
        System.assertEquals(0, result.netDiscountPercent, 'no negative discount');
    }

    @isTest
    static void rounding2dp_applied() {
        Account acc = P2TestDataFactory.makeAccount('R2');
        Contact buyer = P2TestDataFactory.makeContact(acc.Id, 'Each');
        Vehicle_Model__c model = makeModel('LX');
        Product2 vehicleProduct = makeProduct('Test Model LX', 'Vehicle_Trim', 1999.99);
        Opportunity opp = makeOpportunity(makeVehicle(model.Id, 0).Id, acc.Id);
        Quote quote = makeQuote(opp.Id, buyer.Id);
        insert quote;
        List<QuoteLineItem> lines = listedAndQueriedLines(quote.Id, 3, vehicleProduct.Id);

        QuotePricingService.QuotePricingResult result = QuotePricingService.evaluate(
            quote, lines, catalog(),
            vehicleContext(model.Id, vehicleProduct.Id, 0),
            buyerContext('Silver', true)
        );

        System.assertEquals(5879.97, result.adjustedSubtotal, '5999.97 times 0.98 rounded to 2dp');
        System.assertEquals(1, result.appliedRules.size(), 'one loyalty rule');
    }

    @isTest
    static void malformedNegativePercent_surfaces() {
        Account acc = P2TestDataFactory.makeAccount('MAL');
        Vehicle_Model__c model = makeModel('LX');
        Product2 vehicleProduct = makeProduct('Test Model LX', 'Vehicle_Trim', 30000);
        Opportunity opp = makeOpportunity(makeVehicle(model.Id, 70).Id, acc.Id);
        Quote quote = makeQuote(opp.Id, null);
        insert quote;
        List<QuoteLineItem> lines = listedAndQueriedLines(quote.Id, 1, vehicleProduct.Id);

        List<Price_Rule__mdt> rules = catalog();
        rules[2].Percent_Adjustment__c = -10;

        try {
            QuotePricingService.evaluate(
                quote, lines, rules,
                vehicleContext(model.Id, vehicleProduct.Id, 70),
                buyerContext(null, false)
            );
            System.assert(false, 'Negative percent must surface');
        } catch (QuotePricingService.QuotePricingException e) {
            System.assert(e.getMessage().contains('negative percent'), 'message names the convention violation');
        }
    }

    @isTest
    static void malformedNullPercent_surfaces() {
        Account acc = P2TestDataFactory.makeAccount('MAL2');
        Vehicle_Model__c model = makeModel('LX');
        Product2 vehicleProduct = makeProduct('Test Model LX', 'Vehicle_Trim', 30000);
        Opportunity opp = makeOpportunity(makeVehicle(model.Id, 70).Id, acc.Id);
        Quote quote = makeQuote(opp.Id, null);
        insert quote;
        List<QuoteLineItem> lines = listedAndQueriedLines(quote.Id, 1, vehicleProduct.Id);

        List<Price_Rule__mdt> rules = catalog();
        rules[2].Percent_Adjustment__c = null;

        try {
            QuotePricingService.evaluate(
                quote, lines, rules,
                vehicleContext(model.Id, vehicleProduct.Id, 70),
                buyerContext(null, false)
            );
            System.assert(false, 'Null percent must surface');
        } catch (QuotePricingService.QuotePricingException e) {
            System.assert(e.getMessage().contains('Percent_Adjustment__c'), 'message names the missing field');
        }
    }

    @isTest
    static void malformedNullValue_surfaces() {
        Account acc = P2TestDataFactory.makeAccount('MAL3');
        Vehicle_Model__c model = makeModel('LX');
        Product2 vehicleProduct = makeProduct('Test Model LX', 'Vehicle_Trim', 30000);
        Opportunity opp = makeOpportunity(makeVehicle(model.Id, 0).Id, acc.Id);
        Quote quote = makeQuote(opp.Id, null);
        insert quote;
        List<QuoteLineItem> lines = listedAndQueriedLines(quote.Id, 1, vehicleProduct.Id);

        List<Price_Rule__mdt> rules = catalog();
        rules[4].Value__c = null;

        try {
            QuotePricingService.evaluate(
                quote, lines, rules,
                vehicleContext(model.Id, vehicleProduct.Id, 0),
                buyerContext(null, false)
            );
            System.assert(false, 'Null value must surface');
        } catch (QuotePricingService.QuotePricingException e) {
            System.assert(e.getMessage().contains('Value__c'), 'message names the missing field');
        }
    }

    @isTest
    static void basisNotIdentified_reportsBlocker() {
        Account acc = P2TestDataFactory.makeAccount('BLK');
        Vehicle_Model__c model = makeModel('Premium');
        Product2 vehicleProduct = makeProduct('Different Product Name', 'Vehicle_Trim', 30000);
        Opportunity opp = makeOpportunity(makeVehicle(model.Id, 120).Id, acc.Id);
        Quote quote = makeQuote(opp.Id, null);
        insert quote;
        List<QuoteLineItem> lines = listedAndQueriedLines(quote.Id, 1, vehicleProduct.Id);

        // Independently supply the Vehicle_Model context so the basis mismatch
        // is not self-fulfilling via the Product2's own name.
        QuotePricingService.VehicleContext mismatchedContext = new QuotePricingService.VehicleContext();
        mismatchedContext.hasVehicle = true;
        mismatchedContext.modelName = model.Name;
        mismatchedContext.trim = model.Trim__c;
        mismatchedContext.ageDays = 120;

        QuotePricingService.QuotePricingResult result = QuotePricingService.evaluate(
            quote, lines, catalog(),
            mismatchedContext,
            buyerContext(null, false)
        );

        System.assertEquals(false, result.vehicleBasisIdentified, 'basis not identified');
        System.assert(result.blockerMessage != null && result.blockerMessage.contains('QuoteLineItem'), 'blocker message set');
        System.assertEquals(0, result.rulesApplied, 'no rules run when basis blocked');
        System.assertEquals(30000, result.adjustedSubtotal, 'quote unchanged on blocker');
    }

    @isTest
    static void modelNameMissing_noBlocker_noVehicleRules() {
        Account acc = P2TestDataFactory.makeAccount('NMN');
        Vehicle_Model__c model = makeModel('Premium');
        Product2 vehicleProduct = makeProduct('Test Model Premium', 'Vehicle_Trim', 30000);
        Opportunity opp = makeOpportunity(makeVehicle(model.Id, 120).Id, acc.Id);
        Quote quote = makeQuote(opp.Id, null);
        insert quote;
        List<QuoteLineItem> lines = listedAndQueriedLines(quote.Id, 1, vehicleProduct.Id);

        QuotePricingService.VehicleContext context = new QuotePricingService.VehicleContext();
        context.hasVehicle = true;

        QuotePricingService.QuotePricingResult result = QuotePricingService.evaluate(
            quote, lines, catalog(),
            context,
            buyerContext(null, false)
        );

        System.assert(result.blockerMessage == null, 'no model context is not a blocker');
        System.assertEquals(0, result.rulesApplied, 'vehicle rules need model context');
        System.assertEquals(30000, result.adjustedSubtotal, 'unchanged');
    }

    @isTest
    static void premiumOnly_negativeNetDocumented() {
        Account acc = P2TestDataFactory.makeAccount('PRE');
        Vehicle_Model__c model = makeModel('Premium');
        Product2 vehicleProduct = makeProduct('Test Model Premium', 'Vehicle_Trim', 30000);
        Opportunity opp = makeOpportunity(makeVehicle(model.Id, 0).Id, acc.Id);
        Quote quote = makeQuote(opp.Id, null);
        insert quote;
        List<QuoteLineItem> lines = listedAndQueriedLines(quote.Id, 1, vehicleProduct.Id);

        QuotePricingService.QuotePricingResult result = QuotePricingService.evaluate(
            quote, lines, catalog(),
            vehicleContext(model.Id, vehicleProduct.Id, 0),
            buyerContext(null, false)
        );

        System.assertEquals(31500, result.adjustedSubtotal, 'premium-only: 30000 + 5 percent');
        System.assertEquals(-5.00, result.netDiscountPercent, 'signed net is negative for premium uplift');
        System.assertEquals(1, result.rulesApplied, 'one premium rule');
    }

    @isTest
    static void bulk200Lines_stillWorks() {
        // Calculation trace: 200 Accessory lines * 100 + 1 Vehicle_Trim * qty 12 * 30000
        //   listSubtotal  = 20000 + 360000 = 380000
        //   No age rule (age 0), no loyalty, no trim premium (LX).
        //   Volume Over_10 (Discount, quote, 8%): run 380000 * 0.92 = 349600
        Account acc = P2TestDataFactory.makeAccount('BULK');
        Vehicle_Model__c model = makeModel('LX');
        Product2 vehicleProduct = makeProduct('Test Model LX', 'Vehicle_Trim', 30000);
        Product2 accessory = makeProduct('Cargo Net', 'Accessory', 100);
        Opportunity opp = makeOpportunity(makeVehicle(model.Id, 0).Id, acc.Id);
        Quote quote = makeQuote(opp.Id, null);
        insert quote;
        List<QuoteLineItem> lines = new List<QuoteLineItem>();
        PricebookEntry vehicleEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id = :vehicleProduct.Id AND Pricebook2Id = :STD_PB LIMIT 1];
        PricebookEntry accessoryEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id = :accessory.Id AND Pricebook2Id = :STD_PB LIMIT 1];
        for (Integer i = 0; i < 200; i++) {
            lines.add(new QuoteLineItem(QuoteId = quote.Id, PricebookEntryId = accessoryEntry.Id, Quantity = 1, UnitPrice = 100));
        }
        lines.add(new QuoteLineItem(QuoteId = quote.Id, PricebookEntryId = vehicleEntry.Id, Quantity = 12, UnitPrice = 30000));
        insert lines;

        List<QuoteLineItem> queried = [SELECT Id, UnitPrice, Quantity, PricebookEntry.Product2.Category__c, PricebookEntry.Product2.Name
            FROM QuoteLineItem WHERE QuoteId = :quote.Id];

        QuotePricingService.QuotePricingResult result = QuotePricingService.evaluate(
            quote, queried, catalog(),
            vehicleContext(model.Id, vehicleProduct.Id, 0),
            buyerContext(null, false)
        );

        System.assertEquals(201, queried.size(), 'at least 200 lines queried (200 accessory + 1 vehicle)');
        System.assertEquals(1, result.vehicleLineCount, 'one vehicle trim line');
        System.assertEquals(12, result.volumeVehicleQuantity, 'vehicle quantity included in volume');
        System.assertEquals(349600, result.adjustedSubtotal, '380000 minus 8 percent volume');
    }

    @isTest
    static void nullQuote_throws() {
        try {
            QuotePricingService.evaluate(null, new List<QuoteLineItem>(), new List<Price_Rule__mdt>(),
                new QuotePricingService.VehicleContext(), new QuotePricingService.BuyerContext());
            System.assert(false, 'null quote must throw');
        } catch (QuotePricingService.QuotePricingException e) {
            System.assert(e.getMessage().contains('Quote is required'), 'message names the requirement');
        }
    }

    @isTest
    static void nonNumericValue_throws() {
        Account acc = P2TestDataFactory.makeAccount('NNV');
        Vehicle_Model__c model = makeModel('LX');
        Product2 vehicleProduct = makeProduct('Test Model LX', 'Vehicle_Trim', 30000);
        Opportunity opp = makeOpportunity(makeVehicle(model.Id, 70).Id, acc.Id);
        Quote quote = makeQuote(opp.Id, null);
        insert quote;
        List<QuoteLineItem> lines = listedAndQueriedLines(quote.Id, 1, vehicleProduct.Id);

        // A non-numeric Value__c for the age rule: decimalValue() now throws
        // a QuotePricingException so the malformed rule is surfaced, not silently
        // coerced to zero and skipped.
        List<Price_Rule__mdt> badCatalog = new List<Price_Rule__mdt>{
            catalogRule('Age_BadValue', 'Discount', 'Age_Days', 'Greater_Than', 'not-a-number', 10, 20)
        };

        try {
            QuotePricingService.evaluate(
                quote, lines, badCatalog,
                vehicleContext(model.Id, vehicleProduct.Id, 70),
                buyerContext(null, false)
            );
            System.assert(false, 'non-numeric Value__c must throw');
        } catch (QuotePricingService.QuotePricingException e) {
            System.assert(e.getMessage().contains('non-numeric Value__c'), 'message names the rule defect');
            System.assert(e.getMessage().contains('Age_BadValue'), 'message names the rule');
        }
    }

    @isTest
    static void noRulesQualify_returnsUnchanged() {
        Account acc = P2TestDataFactory.makeAccount('NRQ');
        Vehicle_Model__c model = makeModel('Sport');
        Product2 vehicleProduct = makeProduct('Test Model Sport', 'Vehicle_Trim', 30000);
        Opportunity opp = makeOpportunity(makeVehicle(model.Id, 5).Id, acc.Id);
        Quote quote = makeQuote(opp.Id, null);
        insert quote;
        List<QuoteLineItem> lines = listedAndQueriedLines(quote.Id, 1, vehicleProduct.Id);

        // No catalog rule matches Sport trim, age 5, no buyer, qty 1.
        QuotePricingService.QuotePricingResult result = QuotePricingService.evaluate(
            quote, lines, catalog(),
            vehicleContext(model.Id, vehicleProduct.Id, 5),
            buyerContext(null, false)
        );

        System.assertEquals(0, result.rulesApplied, 'no winners');
        System.assertEquals(30000, result.adjustedSubtotal, 'list price unchanged');
        System.assertEquals(0, result.netDiscountPercent, 'zero signed net');
    }
}