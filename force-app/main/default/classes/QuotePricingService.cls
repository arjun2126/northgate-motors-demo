public with sharing class QuotePricingService {
    public static final String BLOCKER_BASIS_AMBIGUOUS = 'QuoteLineItem lines cannot identify a unique primary-vehicle pricing basis for Opportunity.Vehicle__c.';

    public class QuotePricingException extends Exception {
    }

    public class VehicleContext {
        public Boolean hasVehicle;
        public String modelName;
        public String trim;
        public Decimal ageDays;

        public VehicleContext() {
            this.hasVehicle = false;
        }
    }

    public class BuyerContext {
        public String tier;
        public Boolean associated;

        public BuyerContext() {
            this.associated = false;
        }
    }

    public class AppliedRule {
        public String developerName;
        public String category;
        public String direction;
        public Decimal percent;
        public Decimal base;
        public Decimal adjustment;

        public AppliedRule(String developerName, String category, String direction, Decimal percent, Decimal base, Decimal adjustment) {
            this.developerName = developerName;
            this.category = category;
            this.direction = direction;
            this.percent = percent;
            this.base = base;
            this.adjustment = adjustment;
        }
    }

    public class QuotePricingResult {
        public Decimal listSubtotal;
        public Decimal adjustedSubtotal;
        public Decimal netDiscountPercent;
        public Integer rulesApplied;
        public Integer vehicleLineCount;
        public Integer basisMatchCount;
        public Decimal volumeVehicleQuantity;
        public Decimal vehicleListPrice;
        public Decimal vehicleAdjustedPrice;
        public Boolean vehicleBasisIdentified;
        public Boolean buyerAssociated;
        public String blockerMessage;
        public List<AppliedRule> appliedRules;

        public QuotePricingResult() {
            this.rulesApplied = 0;
            this.vehicleLineCount = 0;
            this.basisMatchCount = 0;
            this.volumeVehicleQuantity = 0;
            this.vehicleBasisIdentified = true;
            this.netDiscountPercent = 0;
            this.appliedRules = new List<AppliedRule>();
        }
    }

    // netDiscountPercent is a SIGNED net: positive = net discount, negative = net premium uplift,
    // 0 = unchanged. Computed as (listSubtotal - adjustedSubtotal) / listSubtotal * 100.
    // Zero-list-price guard: returns 0 when listSubtotal is 0 (avoids divide-by-zero).

    public static QuotePricingResult evaluate(
        Quote quote,
        List<QuoteLineItem> lines,
        List<Price_Rule__mdt> activeRules,
        VehicleContext vehicle,
        BuyerContext buyer
    ) {
        if (quote == null) {
            throw new QuotePricingException('Quote is required.');
        }
        if (lines == null) {
            lines = new List<QuoteLineItem>();
        }
        if (activeRules == null) {
            activeRules = new List<Price_Rule__mdt>();
        }
        if (vehicle == null) {
            vehicle = new VehicleContext();
        }
        if (buyer == null) {
            buyer = new BuyerContext();
        }

        QuotePricingResult result = new QuotePricingResult();
        result.buyerAssociated = buyer.associated;

        List<Price_Rule__mdt> valid = new List<Price_Rule__mdt>();
        for (Price_Rule__mdt rule : activeRules) {
            if (rule.Is_Active__c != true) {
                continue;
            }
            validateRule(rule);
            valid.add(rule);
        }

        Decimal listSubtotal = 0;
        Decimal vehicleList = 0;
        Decimal vehicleQty = 0;
        Integer vehicleLineCount = 0;
        Integer basisMatchCount = 0;

        for (Integer i = 0; i < lines.size(); i++) {
            QuoteLineItem line = lines[i];
            Decimal unit = (line.UnitPrice == null) ? 0 : line.UnitPrice;
            Decimal qty = (line.Quantity == null) ? 0 : line.Quantity;
            Decimal subtotal = round2(unit * qty);
            listSubtotal = listSubtotal + subtotal;
            listSubtotal = round2(listSubtotal);

            String category = line.PricebookEntry == null ? null : line.PricebookEntry.Product2 == null
                ? null : line.PricebookEntry.Product2.Category__c;
            if (category == null) {
                continue;
            }
            if (category == 'Vehicle_Trim') {
                vehicleLineCount++;
                vehicleQty = vehicleQty + qty;
                vehicleList = round2(vehicleList + subtotal);
                String productName = line.PricebookEntry.Product2.Name;
                if (vehicle.modelName != null && productName == vehicle.modelName) {
                    basisMatchCount++;
                }
            }
        }

        result.listSubtotal = listSubtotal;
        result.adjustedSubtotal = listSubtotal;
        result.vehicleLineCount = vehicleLineCount;
        result.volumeVehicleQuantity = vehicleQty;
        result.vehicleListPrice = vehicleList;
        result.vehicleAdjustedPrice = null;

        Boolean basisIdentified = vehicle.hasVehicle == true
            && vehicle.modelName != null
            && basisMatchCount == 1;
        result.basisMatchCount = basisMatchCount;
        result.vehicleBasisIdentified = basisIdentified;
        Boolean needBasis = vehicle.hasVehicle == true && vehicle.modelName != null;
        if (!basisIdentified && needBasis) {
            result.vehicleBasisIdentified = false;
            result.blockerMessage = BLOCKER_BASIS_AMBIGUOUS + ' Matched Vehicle_Trim lines: ' + basisMatchCount + '.';
            return result;
        }

        VehicleContext vehicleForRules = new VehicleContext();
        vehicleForRules.hasVehicle = basisIdentified;
        vehicleForRules.modelName = vehicle.modelName;
        vehicleForRules.trim = vehicle.trim;
        vehicleForRules.ageDays = vehicle.ageDays;

        Map<String, Price_Rule__mdt> winnersByCategory = selectWinners(valid, vehicleForRules, buyer, vehicleQty);
        if (winnersByCategory.isEmpty()) {
            return result;
        }

        List<Price_Rule__mdt> ordered = orderRules(winnersByCategory.values());

        List<Price_Rule__mdt> discounts = new List<Price_Rule__mdt>();
        List<Price_Rule__mdt> premiums = new List<Price_Rule__mdt>();
        for (Price_Rule__mdt rule : ordered) {
            if (rule.Rule_Type__c == 'Discount') {
                discounts.add(rule);
            } else {
                premiums.add(rule);
            }
        }

        Decimal run = listSubtotal;
        Decimal vehicleRun = basisIdentified ? vehicleList : null;

        for (Price_Rule__mdt rule : discounts) {
            run = applyRule(rule, run, vehicleRun, result, basisIdentified);
            if (rule.Attribute__c == 'Trim' || rule.Attribute__c == 'Age_Days') {
                vehicleRun = result.vehicleAdjustedPrice;
            }
            result.rulesApplied++;
        }
        for (Price_Rule__mdt rule : premiums) {
            run = applyRule(rule, run, vehicleRun, result, basisIdentified);
            if (rule.Attribute__c == 'Trim') {
                vehicleRun = result.vehicleAdjustedPrice;
            }
            result.rulesApplied++;
        }

        if (run < 0) {
            run = 0;
        }
        result.adjustedSubtotal = round2(run);
        if (basisIdentified) {
            result.vehicleAdjustedPrice = round2(vehicleRun);
        }
        result.netDiscountPercent = listSubtotal > 0
            ? round2(((listSubtotal - result.adjustedSubtotal) / listSubtotal * 100).setScale(2))
            : 0;

        return result;
    }

    private static void validateRule(Price_Rule__mdt rule) {
        String name = rule.DeveloperName == null ? 'UNKNOWN' : rule.DeveloperName;
        if (rule.Rule_Type__c == null) {
            throw new QuotePricingException('Active Price_Rule__mdt ' + name + ' has no Rule_Type__c.');
        }
        if (rule.Percent_Adjustment__c == null) {
            throw new QuotePricingException('Active Price_Rule__mdt ' + name + ' has no Percent_Adjustment__c.');
        }
        if (rule.Percent_Adjustment__c < 0) {
            throw new QuotePricingException('Active Price_Rule__mdt ' + name + ' stores a negative percent; store percentages positive and use Rule_Type__c for direction.');
        }
        if (rule.Attribute__c == null) {
            throw new QuotePricingException('Active Price_Rule__mdt ' + name + ' has no Attribute__c.');
        }
        if (rule.Value__c == null && rule.Attribute__c != 'Age_Days' && rule.Attribute__c != 'Volume') {
            throw new QuotePricingException('Active Price_Rule__mdt ' + name + ' has no Value__c.');
        }
    }

    private static Map<String, Price_Rule__mdt> selectWinners(
        List<Price_Rule__mdt> rules,
        VehicleContext vehicle,
        BuyerContext buyer,
        Decimal vehicleQty
    ) {
        Map<String, Price_Rule__mdt> winners = new Map<String, Price_Rule__mdt>();
        for (Price_Rule__mdt rule : rules) {
            if (!qualifies(rule, vehicle, buyer, vehicleQty)) {
                continue;
            }
            String category = rule.Attribute__c;
            Price_Rule__mdt current = winners.get(category);
            if (current == null || rule.Percent_Adjustment__c > current.Percent_Adjustment__c) {
                winners.put(category, rule);
            }
        }
        return winners;
    }

    private static Boolean qualifies(Price_Rule__mdt rule, VehicleContext vehicle, BuyerContext buyer, Decimal vehicleQty) {
        String attribute = rule.Attribute__c;
        String operator = rule.Operator__c == null ? '' : rule.Operator__c;
        if (attribute == 'Trim') {
            return vehicle.hasVehicle == true
                && vehicle.trim != null
                && operator == 'Equals'
                && vehicle.trim == rule.Value__c;
        }
        if (attribute == 'Age_Days') {
            return vehicle.hasVehicle == true
                && vehicle.ageDays != null
                && operator == 'Greater_Than'
                && vehicle.ageDays > decimalValue(rule, rule.Value__c);
        }
        if (attribute == 'Loyalty_Tier') {
            return buyer.tier != null
                && buyer.associated == true
                && operator == 'Equals'
                && buyer.tier == rule.Value__c;
        }
        if (attribute == 'Volume') {
            return operator == 'Greater_Than'
                && vehicleQty > decimalValue(rule, rule.Value__c);
        }
        return false;
    }

    private static Decimal decimalValue(Price_Rule__mdt rule, String value) {
        if (value == null) {
            return 0;
        }
        try {
            return Decimal.valueOf(value);
        } catch (Exception e) {
            String name = rule.DeveloperName == null ? 'UNKNOWN' : rule.DeveloperName;
            throw new QuotePricingException('Active Price_Rule__mdt ' + name + ' has non-numeric Value__c: "' + value + '". Store a numeric value or deactivate the rule.');
        }
    }

    private static List<Price_Rule__mdt> orderRules(List<Price_Rule__mdt> winners) {
        List<Price_Rule__mdt> ordered = new List<Price_Rule__mdt>(winners);
        ordered.sort(new RuleComparator());
        return ordered;
    }

    private class RuleComparator implements Comparator<Price_Rule__mdt> {
        public Integer compare(Price_Rule__mdt a, Price_Rule__mdt b) {
            Decimal pa = a.Priority__c == null ? 0 : a.Priority__c;
            Decimal pb = b.Priority__c == null ? 0 : b.Priority__c;
            if (pa < pb) return -1;
            if (pa > pb) return 1;
            String na = a.DeveloperName == null ? '' : a.DeveloperName;
            String nb = b.DeveloperName == null ? '' : b.DeveloperName;
            return na.compareTo(nb);
        }
    }

    private static Decimal applyRule(Price_Rule__mdt rule, Decimal run, Decimal vehicleRun, QuotePricingResult result, Boolean basisIdentified) {
        Boolean vehicleRule = rule.Attribute__c == 'Trim' || rule.Attribute__c == 'Age_Days';
        Boolean isDiscount = rule.Rule_Type__c == 'Discount';
        Decimal pct = rule.Percent_Adjustment__c;
        Decimal factor = pct.divide(100, 6, System.RoundingMode.HALF_UP);

        if (vehicleRule) {
            if (!basisIdentified) {
                return run;
            }
            String category = rule.Attribute__c;
            Decimal base = vehicleRun;
            Decimal newValue = isDiscount
                ? round2(base * (1 - factor))
                : round2(base * (1 + factor));
            Decimal adjustment = isDiscount ? base - newValue : newValue - base;
            result.appliedRules.add(new AppliedRule(rule.DeveloperName, category, rule.Rule_Type__c, pct, base, round2(adjustment)));
            result.vehicleAdjustedPrice = round2(newValue);
            return round2(run - base + newValue);
        }

        Decimal quoteBase = run;
        Decimal quoteNew = isDiscount
            ? round2(quoteBase * (1 - factor))
            : round2(quoteBase * (1 + factor));
        Decimal quoteAdjustment = isDiscount ? quoteBase - quoteNew : quoteNew - quoteBase;
        result.appliedRules.add(new AppliedRule(rule.DeveloperName, rule.Attribute__c, rule.Rule_Type__c, pct, quoteBase, round2(quoteAdjustment)));
        return quoteNew;
    }

    private static Decimal round2(Decimal value) {
        if (value == null) {
            return 0;
        }
        return value.setScale(2, System.RoundingMode.HALF_UP);
    }
}