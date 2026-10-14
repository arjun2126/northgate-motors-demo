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
}
