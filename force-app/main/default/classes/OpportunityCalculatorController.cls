public with sharing class OpportunityCalculatorController {
    public class Estimate {
        @AuraEnabled public Decimal equity;
        @AuraEnabled public Decimal principal;
        @AuraEnabled public Decimal annualRate;
        @AuraEnabled public Decimal monthlyPayment;
        @AuraEnabled public Decimal totalInterest;
        @AuraEnabled public String rateSource;
    }
    @AuraEnabled(cacheable=true)
    public static Decimal amount(Id opportunityId) {
        List<Opportunity> rows = [SELECT Id, Amount FROM Opportunity WHERE Id = :opportunityId WITH USER_MODE];
        if (rows.isEmpty()) throw new AuraHandledException('Opportunity is unavailable.');
        return rows[0].Amount;
    }
    @AuraEnabled(cacheable=true)
    public static Estimate preview(Id opportunityId, Decimal sellingPrice, Decimal downPayment, Decimal appraisal,
        Decimal payoff, String creditTier, Integer termMonths, Decimal manualRate, String manualReason) {
        List<Opportunity> accessible = [SELECT Id FROM Opportunity WHERE Id = :opportunityId WITH USER_MODE];
        if (accessible.isEmpty()) throw new AuraHandledException('Opportunity is unavailable.');
        if (sellingPrice == null || sellingPrice < 0 || sellingPrice > 10000000 || downPayment == null || downPayment < 0
            || appraisal == null || appraisal < 0 || payoff == null || payoff < 0 || appraisal > 10000000 || payoff > 10000000
            || termMonths == null || termMonths < 1 || termMonths > 120) throw new AuraHandledException('Enter valid estimate amounts and term (1–120 months).');
        Estimate estimate = new Estimate();
        estimate.equity = TradeIn_Calc_Equity.computeEquity(appraisal, payoff);
        estimate.principal = sellingPrice - downPayment - estimate.equity;
        if (estimate.principal < 0 || estimate.principal > 10000000) throw new AuraHandledException('Estimated principal is outside the supported range.');
        estimate.annualRate = manualRate == null ? RateTableService.resolve(creditTier, termMonths).baseRate
            : RateTableService.manualRate(manualRate, manualReason);
        estimate.rateSource = manualRate == null ? 'Configured illustrative rate' : 'Manual illustrative rate';
        estimate.monthlyPayment = PaymentCalculatorService.monthlyPayment(estimate.principal, estimate.annualRate, termMonths);
        estimate.totalInterest = PaymentCalculatorService.totalInterest(estimate.principal, estimate.annualRate, termMonths);
        return estimate;
    }
}
