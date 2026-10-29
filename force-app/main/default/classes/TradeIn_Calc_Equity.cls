public with sharing class TradeIn_Calc_Equity {
    public static Decimal computeEquity(Decimal appraisalAmount, Decimal payoffAmount) {
        if (appraisalAmount == null) appraisalAmount = 0;
        if (payoffAmount == null) payoffAmount = 0;
        return appraisalAmount - payoffAmount;
    }

    public static Decimal computeEquity(Id tradeInId) {
        Trade_In__c ti = [
            SELECT Appraisal_Amount__c, Payoff_Amount__c
            FROM Trade_In__c
            WHERE Id = :tradeInId
            LIMIT 1
        ];
        return computeEquity(ti.Appraisal_Amount__c, ti.Payoff_Amount__c);
    }
}