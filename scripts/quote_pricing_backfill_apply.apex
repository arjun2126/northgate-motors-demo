// Northgate Motors - Quote pricing backfill APPLY (guarded).
//
// Re-evaluates CP2 for every Quote and backfills Adjusted_Subtotal__c plus
// Rule_Applied_Count__c for OPEN quotes (Draft, Presented) whose result is
// deterministic. Terminal quotes (Accepted, Rejected, Denied) are historical
// snapshots and are never updated.
//
// The script is idempotent: only quotes with a null Adjusted_Subtotal__c are
// selected for update, so a second run is a no-op.
//
// SAFETY: EXECUTE is false. Set it to true only after the dry run is approved.
// Run: sf apex run --target-org ng-demo --file scripts/quote_pricing_backfill_apply.apex

Boolean EXECUTE = false;

Set<String> HISTORICAL = new Set<String>{'Accepted', 'Rejected', 'Denied'};

List<Quote> quotes = [
    SELECT Id, Name, Status, Subtotal, Adjusted_Subtotal__c, Rule_Applied_Count__c,
        Buyer_Contact__c, OpportunityId,
        Opportunity.AccountId,
        Opportunity.Vehicle__c,
        Opportunity.Vehicle__r.Vehicle_Model__r.Name,
        Opportunity.Vehicle__r.Vehicle_Model__r.Trim__c,
        Opportunity.Vehicle__r.Inventory_Age_Days__c
    FROM Quote
    ORDER BY Name
];

Map<Id, List<QuoteLineItem>> linesByQuote = new Map<Id, List<QuoteLineItem>>();
for (QuoteLineItem line : [
    SELECT Id, QuoteId, UnitPrice, Quantity,
        PricebookEntry.Product2.Name, PricebookEntry.Product2.Category__c
    FROM QuoteLineItem
]) {
    if (!linesByQuote.containsKey(line.QuoteId)) {
        linesByQuote.put(line.QuoteId, new List<QuoteLineItem>());
    }
    linesByQuote.get(line.QuoteId).add(line);
}

List<Price_Rule__mdt> rules = [
    SELECT DeveloperName, Rule_Type__c, Attribute__c, Operator__c, Value__c,
        Percent_Adjustment__c, Priority__c, Is_Active__c
    FROM Price_Rule__mdt
];

Map<Id, QuotePricingService.BuyerContext> buyerByQuote = new Map<Id, QuotePricingService.BuyerContext>();
for (Quote q : quotes) {
    if (q.Buyer_Contact__c == null) {
        continue;
    }
    QuotePricingService.BuyerContext buyer = new QuotePricingService.BuyerContext();
    Contact buyerContact = [
        SELECT Id, AccountId FROM Contact WHERE Id = :q.Buyer_Contact__c LIMIT 1
    ];
    if (buyerContact.AccountId == q.Opportunity.AccountId) {
        List<Loyalty_Member__c> members = [
            SELECT Tier__c, Member_Number__c, Tier_Evaluated_On__c
            FROM Loyalty_Member__c
            WHERE Contact__c = :q.Buyer_Contact__c AND Status__c = 'Active'
        ];
        String tier = bestTier(members);
        if (tier != null) {
            buyer.tier = tier;
            buyer.associated = true;
        }
    }
    buyerByQuote.put(q.Id, buyer);
}

List<Quote> updates = new List<Quote>();
Integer blocked = 0;
Integer frozen = 0;

for (Quote q : quotes) {
    if (q.Adjusted_Subtotal__c != null) {
        continue;
    }
    if (HISTORICAL.contains(q.Status)) {
        frozen++;
        continue;
    }

    QuotePricingService.VehicleContext vehicle = new QuotePricingService.VehicleContext();
    vehicle.hasVehicle = q.Opportunity.Vehicle__c != null;
    vehicle.modelName = q.Opportunity.Vehicle__r.Vehicle_Model__r.Name;
    vehicle.trim = q.Opportunity.Vehicle__r.Vehicle_Model__r.Trim__c;
    vehicle.ageDays = q.Opportunity.Vehicle__r.Inventory_Age_Days__c;

    QuotePricingService.BuyerContext buyer = buyerByQuote.containsKey(q.Id)
        ? buyerByQuote.get(q.Id)
        : new QuotePricingService.BuyerContext();

    List<QuoteLineItem> lines = linesByQuote.containsKey(q.Id)
        ? linesByQuote.get(q.Id)
        : new List<QuoteLineItem>();

    QuotePricingService.QuotePricingResult result =
        QuotePricingService.evaluate(q, lines, rules, vehicle, buyer);

    if (result.blockerMessage != null) {
        blocked++;
        System.debug('APPLY_BLOCKED|' + q.Name + '|' + result.blockerMessage);
        continue;
    }

    updates.add(new Quote(
        Id = q.Id,
        Adjusted_Subtotal__c = result.adjustedSubtotal,
        Rule_Applied_Count__c = result.rulesApplied
    ));
    System.debug('APPLY_CANDIDATE|' + q.Name + '|' + q.Status
        + '|' + result.adjustedSubtotal + '|' + result.rulesApplied);
}

System.debug('APPLY_SUMMARY|execute=' + EXECUTE
    + '; candidates=' + updates.size()
    + '; blocked=' + blocked
    + '; frozen_historical=' + frozen);

if (!EXECUTE) {
    System.debug('APPLY_DRY_ONLY|No DML performed. Set EXECUTE=true to apply.');
} else if (!updates.isEmpty()) {
    List<Database.SaveResult> results = Database.update(updates, false);
    Integer ok = 0;
    Integer failed = 0;
    for (Integer i = 0; i < results.size(); i++) {
        if (results[i].isSuccess()) {
            ok++;
        } else {
            failed++;
            System.debug('APPLY_FAILED|' + updates[i].Name + '|'
                + results[i].getErrors()[0].getMessage());
        }
    }
    System.debug('APPLY_RESULT|updated=' + ok + '; failed=' + failed);
}

Integer rank(String tier) {
    if (tier == 'Platinum') return 4;
    if (tier == 'Gold') return 3;
    if (tier == 'Silver') return 2;
    if (tier == 'Bronze') return 1;
    return 0;
}

String bestTier(List<Loyalty_Member__c> memberships) {
    Loyalty_Member__c best;
    Integer bestRank = 0;
    String bestNumber = '~~~~~~~~~~';
    Date bestDate = Date.valueOf('1900-01-01');
    for (Loyalty_Member__c m : memberships) {
        if (m.Tier__c == null) continue;
        Integer r = rank(m.Tier__c);
        String n = m.Member_Number__c == null ? '~~~~~~~~~~' : m.Member_Number__c;
        Date d = m.Tier_Evaluated_On__c == null ? Date.valueOf('1900-01-01') : m.Tier_Evaluated_On__c;
        Boolean better = false;
        if (best == null) {
            better = true;
        } else if (r != bestRank) {
            better = r > bestRank;
        } else if (n != bestNumber) {
            better = n.compareTo(bestNumber) < 0;
        } else if (d != bestDate) {
            better = d > bestDate;
        }
        if (better) {
            best = m;
            bestRank = r;
            bestNumber = n;
            bestDate = d;
        }
    }
    return best == null ? null : best.Tier__c;
}
