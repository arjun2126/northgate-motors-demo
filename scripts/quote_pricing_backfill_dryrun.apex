// Northgate Motors - Quote pricing backfill DRY RUN (read-only).
//
// Re-evaluates the CP2 pricing engine for every Quote and reports what a
// backfill would change. This script performs NO DML.
//
// Policy encoded here:
//   - Terminal statuses (Accepted, Rejected, Denied) are historical snapshots
//     and are never proposed for update.
//   - Open statuses (Draft, Presented) are eligible for backfill only when
//     CP2 returns a deterministic result (no blocker).
//   - Quotes whose CP2 result carries a blocker are reported as needing a
//     data fix, not a pricing backfill.
//
// Run: sf apex run --target-org ng-demo --file scripts/quote_pricing_backfill_dryrun.apex

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

// Buyer context cache: quote Id -> BuyerContext (only quotes with a buyer are queried).
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

Integer nullAdjusted = 0;
Integer openCount = 0;
Integer terminalCount = 0;
Integer blockerCount = 0;
Integer eligibleBackfill = 0;
Integer frozenHistorical = 0;
Integer blockedNeedsDataFix = 0;
Integer unchangedOpen = 0;

System.debug('DRYRUN_HEADER|quote|status|historical|subtotal|calc_adjusted|rules|basis|blocker|eligible|action');

for (Quote q : quotes) {
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

    Boolean historical = HISTORICAL.contains(q.Status);
    if (historical) {
        terminalCount++;
    } else {
        openCount++;
    }
    if (q.Adjusted_Subtotal__c == null) {
        nullAdjusted++;
    }

    String action = 'NO_OP';
    Boolean eligible = false;
    if (result.blockerMessage != null) {
        blockerCount++;
        action = 'DATA_FIX_REQUIRED';
        if (!historical) {
            blockedNeedsDataFix++;
        }
    } else if (historical) {
        action = 'FROZEN_HISTORICAL';
        frozenHistorical++;
    } else if (q.Adjusted_Subtotal__c == null) {
        eligible = true;
        eligibleBackfill++;
        action = 'BACKFILL_OPEN';
    } else if (q.Adjusted_Subtotal__c != result.adjustedSubtotal) {
        eligible = true;
        eligibleBackfill++;
        action = 'BACKFILL_OPEN';
    } else {
        unchangedOpen++;
    }

    System.debug('DRYRUN|' + q.Name
        + '|' + q.Status
        + '|' + historical
        + '|' + q.Subtotal
        + '|' + result.adjustedSubtotal
        + '|' + result.rulesApplied
        + '|' + result.vehicleBasisIdentified
        + '|' + (result.blockerMessage == null ? '' : result.blockerMessage)
        + '|' + eligible
        + '|' + action);
}

System.debug('DRYRUN_SUMMARY|total=' + quotes.size()
    + '; null_adjusted=' + nullAdjusted
    + '; open=' + openCount
    + '; terminal=' + terminalCount
    + '; blockers=' + blockerCount
    + '; eligible_backfill=' + eligibleBackfill
    + '; frozen_historical=' + frozenHistorical
    + '; blocked_needs_data_fix=' + blockedNeedsDataFix
    + '; unchanged_open=' + unchangedOpen);

// Mirrors QuoteBuilderController.deterministicTier so the dry run matches the builder.
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
