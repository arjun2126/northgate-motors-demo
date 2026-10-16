public with sharing class RateTableService {
    // Rate-selection contract for P4-04 (reused by P4-02 Finance Wizard).
    // All table rates are illustrative demo values, not real lender offers.
    // Units: rates and LTV values are PERCENT (e.g. 6.49 = 6.49%, 110 = 110%),
    // matching Rate_Table__mdt storage and PaymentCalculatorService input.
    // The caller-supplied LTV is a caller-computed value in percent; this
    // service gates it against Max_LTV__c but does NOT define the vehicle
    // valuation formula (no authoritative LTV definition exists — see D3).
    private static final Set<String> VALID_TIERS = new Set<String>{
        'A', 'B', 'C', 'D', 'Sub_Prime'
    };
    private static final Set<Integer> VALID_TERMS = new Set<Integer>{
        36, 48, 60, 72, 84, 96
    };

    public class RateResolution {
        public String tier;
        public Integer termMonths;
        public Decimal baseRate;
        public Decimal maxLtv;
    }

    public static RateResolution resolve(String tier, Integer termMonths) {
        validateTierAndTerm(tier, termMonths);
        List<Rate_Table__mdt> matches = [
            SELECT Credit_Tier__c, Term_Months__c, Base_Rate__c, Max_LTV__c
            FROM Rate_Table__mdt
            WHERE Credit_Tier__c = :tier
                AND Term_Months__c = :termMonths
                AND Is_Active__c = true
            WITH USER_MODE
        ];
        if (matches.isEmpty()) {
            throw new IllegalArgumentException(
                'No active rate for tier ' + tier + ' and term ' + termMonths + ' months.'
            );
        }
        if (matches.size() > 1) {
            throw new IllegalArgumentException(
                'Multiple active rates for tier ' + tier + ' and term ' + termMonths + ' months.'
            );
        }
        Rate_Table__mdt row = matches[0];
        RateResolution resolution = new RateResolution();
        resolution.tier = row.Credit_Tier__c;
        resolution.termMonths = Integer.valueOf(row.Term_Months__c);
        resolution.baseRate = row.Base_Rate__c;
        resolution.maxLtv = row.Max_LTV__c;
        return resolution;
    }

    public static RateResolution resolve(String tier, Integer termMonths, Decimal ltvPercent) {
        if (ltvPercent == null) {
            throw new IllegalArgumentException('LTV percent is required for the eligibility check.');
        }
        if (ltvPercent < 0) {
            throw new IllegalArgumentException('LTV percent cannot be negative.');
        }
        RateResolution resolution = resolve(tier, termMonths);
        if (resolution.maxLtv != null && ltvPercent > resolution.maxLtv) {
            throw new IllegalArgumentException(
                'LTV ' + ltvPercent + '% exceeds the ' + resolution.maxLtv + '% limit for tier ' + tier + '.'
            );
        }
        return resolution;
    }

    public static Decimal manualRate(Decimal annualRatePercent, String exceptionReason) {
        if (annualRatePercent == null || annualRatePercent < 0 || annualRatePercent > 25) {
            throw new IllegalArgumentException('Manual rate must be between 0% and 25%.');
        }
        if (String.isBlank(exceptionReason)) {
            throw new IllegalArgumentException('A manual exception requires a nonblank reason.');
        }
        return annualRatePercent;
    }

    private static void validateTierAndTerm(String tier, Integer termMonths) {
        if (String.isBlank(tier) || !VALID_TIERS.contains(tier)) {
            throw new IllegalArgumentException('Credit tier must be one of A, B, C, D, Sub_Prime.');
        }
        if (termMonths == null || !VALID_TERMS.contains(termMonths)) {
            throw new IllegalArgumentException('Term must be one of 36, 48, 60, 72, 84, 96 months.');
        }
    }
}
