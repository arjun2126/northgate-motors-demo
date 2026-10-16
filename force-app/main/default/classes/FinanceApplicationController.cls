public with sharing class FinanceApplicationController {
    @TestVisible private static final Decimal MAX_AMOUNT = 10000000;

    public class WizardData {
        @AuraEnabled public Id opportunityId;
        @AuraEnabled public Id recordId;
        @AuraEnabled public Id quoteId;
        @AuraEnabled public String mode;
        @AuraEnabled public Integer draftCount;
        @AuraEnabled public Decimal adjustedSubtotal;
        @AuraEnabled public Decimal downPayment;
        @AuraEnabled public Decimal tradeEquity;
        @AuraEnabled public Integer tradeInCount;
        @AuraEnabled public List<QuoteOption> eligibleQuotes;
        @AuraEnabled public Id applicantContactId;
        @AuraEnabled public Decimal annualRate;
        @AuraEnabled public Integer termMonths;
        @AuraEnabled public String rateSource;
        @AuraEnabled public String exceptionReason;
        @AuraEnabled public String status;
        @AuraEnabled public Boolean exceptionApproved;
        @AuraEnabled public Boolean requiresExceptionApproval;
    }

    public class QuoteOption {
        @AuraEnabled public Id quoteId;
        @AuraEnabled public String name;
        @AuraEnabled public Decimal adjustedSubtotal;
        @AuraEnabled public Id buyerContactId;
    }

    public class SaveResult {
        @AuraEnabled public Id financingId;
        @AuraEnabled public Decimal adjustedSubtotal;
        @AuraEnabled public Decimal tradeEquity;
        @AuraEnabled public Decimal amountFinanced;
        @AuraEnabled public Decimal monthlyPayment;
        @AuraEnabled public Decimal totalInterest;
        @AuraEnabled public List<String> errors;
    }

    @AuraEnabled(cacheable=true)
    public static WizardData load(Id opportunityId) {
        validateOpportunityAccess(opportunityId);
        WizardData data = new WizardData();
        data.opportunityId = opportunityId;
        data.eligibleQuotes = new List<QuoteOption>();
        for (Quote q : [
            SELECT Id, Name, OpportunityId, Adjusted_Subtotal__c, Buyer_Contact__c
            FROM Quote
            WHERE OpportunityId = :opportunityId
            WITH USER_MODE
            ORDER BY CreatedDate DESC
        ]) {
            QuoteOption opt = new QuoteOption();
            opt.quoteId = q.Id;
            opt.name = q.Name;
            opt.adjustedSubtotal = q.Adjusted_Subtotal__c == null ? 0 : q.Adjusted_Subtotal__c;
            opt.buyerContactId = q.Buyer_Contact__c;
            data.eligibleQuotes.add(opt);
        }
        data.draftCount = [SELECT COUNT() FROM Financing__c WHERE Opportunity__c = :opportunityId AND Status__c = 'Draft' WITH USER_MODE];
        for (Financing__c f : [
            SELECT Id, Quote__c, Down_Payment__c, Term_Months__c, Annual_Rate__c,
                Rate_Source__c, Exception_Reason__c, Applicant__c, Status__c,
                Finance_Exception_Approved__c, Credit_Tier__c
                FROM Financing__c
                WHERE Opportunity__c = :opportunityId AND Status__c = 'Draft' WITH USER_MODE
                LIMIT 2
            ]) {
                if (f.Id == null) {
                    continue;
                }
                if (data.recordId == null) {
                    data.recordId = f.Id;
                    data.quoteId = f.Quote__c;
                    data.downPayment = f.Down_Payment__c;
                    data.termMonths = (Integer) f.Term_Months__c;
                    data.annualRate = f.Annual_Rate__c;
                    data.rateSource = f.Rate_Source__c;
                    data.exceptionReason = f.Exception_Reason__c;
                    data.applicantContactId = f.Applicant__c;
                    data.status = f.Status__c;
                    data.exceptionApproved = f.Finance_Exception_Approved__c == true;
                    data.requiresExceptionApproval = FinancingApprovalService.requiresExceptionApproval(f);
                }
            }
        if (data.draftCount != null && data.draftCount > 1) {
            data.mode = 'ambiguous';
        } else {
            data.mode = data.recordId == null ? 'new' : 'edit';
        }
        populateDerived(data);
        return data;
    }

    @AuraEnabled(cacheable=true)
    public static SaveResult preview(
        Id opportunityId, Id quoteId, Decimal downPayment,
        String creditTier, Integer termMonths,
        String rateSource, Decimal manualRate, String exceptionReason
    ) {
        SaveResult result = new SaveResult();
        result.errors = new List<String>();
        try {
            Quote quote = validateAndLoadQuote(opportunityId, quoteId);
            validateFinancialInputs(downPayment, termMonths, quote);
            Decimal equity = sumAcceptedTradeEquity(opportunityId);
            Decimal principal = quote.Adjusted_Subtotal__c - downPayment - equity;
            validatePrincipal(principal);
            result.adjustedSubtotal = quote.Adjusted_Subtotal__c;
            result.tradeEquity = equity;
            Decimal rate = pickRate(creditTier, termMonths, rateSource, manualRate, exceptionReason, result);
            if (rate == null) {
                return result;
            }
            result.amountFinanced = principal;
            result.monthlyPayment = PaymentCalculatorService.monthlyPayment(principal, rate, termMonths);
            result.totalInterest = PaymentCalculatorService.totalInterest(principal, rate, termMonths);
        } catch (Exception e) {
            result.errors.add(e.getMessage());
        }
        return result;
    }

    @AuraEnabled
    public static SaveResult saveApplication(
        Id recordId, Id opportunityId, Id quoteId,
        Id applicantContactId, Decimal downPayment,
        String creditTier, Integer termMonths,
        String rateSource, Decimal manualRate, String exceptionReason
    ) {
        SaveResult result = new SaveResult();
        result.errors = new List<String>();
        if (opportunityId == null || quoteId == null) {
            result.errors.add('Opportunity and Quote are required.');
            return result;
        }
        Savepoint sp = Database.setSavepoint();
        try {
            Opportunity lock = [
                SELECT Id FROM Opportunity WHERE Id = :opportunityId WITH USER_MODE FOR UPDATE
            ];
            System.assertNotEquals(null, lock, 'opportunity lock acquired');
            Quote quote = validateAndLoadQuote(opportunityId, quoteId);
            validateFinancialInputs(downPayment, termMonths, quote);
            Decimal equity = sumAcceptedTradeEquity(opportunityId);
            Decimal principal = quote.Adjusted_Subtotal__c - downPayment - equity;
            validatePrincipal(principal);
            Decimal rate = pickRate(creditTier, termMonths, rateSource, manualRate, exceptionReason, result);
            if (rate == null) {
                return result;
            }
            Id applicant = applicantContactId != null
                ? applicantContactId
                : (quote.Buyer_Contact__c != null ? quote.Buyer_Contact__c : null);
            if (applicant == null) {
                result.errors.add('Applicant is required; select a buyer Contact.');
                return result;
            }
            Financing__c record;
            if (recordId == null) {
                List<Financing__c> existing = [
                    SELECT Id FROM Financing__c
                    WHERE Opportunity__c = :opportunityId AND Status__c = 'Draft' WITH USER_MODE
                    LIMIT 2
                ];
                if (existing.size() > 1) {
                    result.errors.add('Multiple Draft applications exist; reconcile before creating another.');
                    return result;
                }
                if (existing.size() == 1) {
                    result.errors.add('A Draft already exists for this Opportunity; opening it instead.');
                    return result;
                }
                record = new Financing__c();
                record.Status__c = 'Draft';
            } else {
                List<Financing__c> recs = [
                    SELECT Id, Opportunity__c, Status__c FROM Financing__c
                    WHERE Id = :recordId WITH USER_MODE FOR UPDATE
                ];
                record = recs[0];
                if (record.Opportunity__c != opportunityId) {
                    result.errors.add('Financing record does not belong to the supplied Opportunity.');
                    return result;
                }
                if (record.Status__c != 'Draft') {
                    result.errors.add('Only Draft financing applications can be edited.');
                    return result;
                }
            }
            record.Opportunity__c = opportunityId;
            record.Quote__c = quoteId;
            record.Applicant__c = applicant;
            record.Amount_Financed__c = principal;
            record.Down_Payment__c = downPayment;
            record.Term_Months__c = termMonths;
            record.Annual_Rate__c = rate;
            record.Credit_Tier__c = creditTier;
            record.Rate_Source__c = rateSource;
            record.Exception_Reason__c = rateSource == 'Manual_Exception' ? exceptionReason : null;
            record.Monthly_Payment__c = PaymentCalculatorService.monthlyPayment(principal, rate, termMonths);
            record.Total_Interest__c = PaymentCalculatorService.totalInterest(principal, rate, termMonths);
            record.Lender__c = 'Northgate Financial';
            record.Application_Date__c = Date.today();
            if (recordId == null) {
                insert record;
            } else {
                update record;
            }
            result.financingId = record.Id;
            result.amountFinanced = principal;
            result.monthlyPayment = record.Monthly_Payment__c;
            result.totalInterest = record.Total_Interest__c;
        } catch (Exception e) {
            Database.rollback(sp);
            result.errors.add(e.getMessage());
        }
        return result;
    }

    @AuraEnabled
    public static FinancingApprovalService.ApprovalOutcome submitForExceptionApproval(Id recordId) {
        return FinancingApprovalService.submitForExceptionApproval(recordId);
    }

    private static Quote validateAndLoadQuote(Id opportunityId, Id quoteId) {
        if (opportunityId == null || quoteId == null) {
            throw new IllegalArgumentException('Opportunity and Quote are required.');
        }
        List<Quote> quotes = [
            SELECT Id, OpportunityId, Adjusted_Subtotal__c, Buyer_Contact__c
            FROM Quote WHERE Id = :quoteId WITH USER_MODE LIMIT 1
        ];
        if (quotes.isEmpty()) {
            throw new IllegalArgumentException('Quote not found.');
        }
        Quote quote = quotes[0];
        if (quote.OpportunityId != opportunityId) {
            throw new IllegalArgumentException('Selected Quote does not belong to this Opportunity.');
        }
        if (quote.Adjusted_Subtotal__c == null || quote.Adjusted_Subtotal__c <= 0) {
            throw new IllegalArgumentException('Selected Quote has no positive CP2-adjusted selling price.');
        }
        return quote;
    }

    private static Decimal sumAcceptedTradeEquity(Id opportunityId) {
        List<Trade_In__c> trades = [
            SELECT Trade_Equity__c FROM Trade_In__c
            WHERE Opportunity__c = :opportunityId AND Status__c = 'Accepted' WITH USER_MODE
        ];
        if (trades.size() > 1) {
            throw new IllegalArgumentException(
                'Multiple Accepted trade-ins found (' + trades.size() + '); cannot pick deterministically.'
            );
        }
        return trades.isEmpty() ? 0 : (trades[0].Trade_Equity__c == null ? 0 : trades[0].Trade_Equity__c);
    }

    private static void validateFinancialInputs(Decimal downPayment, Integer termMonths, Quote quote) {
        if (downPayment == null || downPayment < 0) {
            throw new IllegalArgumentException('Down payment must be zero or positive.');
        }
        if (downPayment > quote.Adjusted_Subtotal__c) {
            throw new IllegalArgumentException('Down payment cannot exceed the CP2-adjusted selling price.');
        }
        Set<Integer> valid = new Set<Integer>{ 36, 48, 60, 72, 84, 96 };
        if (termMonths == null || !valid.contains(termMonths)) {
            throw new IllegalArgumentException('Term must be one of 36, 48, 60, 72, 84, or 96 months.');
        }
    }

    private static void validatePrincipal(Decimal principal) {
        if (principal == null || principal <= 0) {
            throw new IllegalArgumentException('Amount financed must be positive.');
        }
        if (principal > MAX_AMOUNT) {
            throw new IllegalArgumentException('Amount financed exceeds the maximum supported value.');
        }
    }

    private static Decimal pickRate(
        String creditTier, Integer termMonths, String rateSource,
        Decimal manualRate, String exceptionReason, SaveResult result
    ) {
        if (rateSource == 'Rate_Table') {
            RateTableService.RateResolution r = RateTableService.resolve(creditTier, termMonths);
            return r.baseRate;
        }
        if (rateSource == 'Manual_Exception') {
            return RateTableService.manualRate(manualRate, exceptionReason);
        }
        result.errors.add('Select a rate source (Rate_Table or Manual_Exception).');
        return null;
    }

    private static void validateOpportunityAccess(Id opportunityId) {
        if (opportunityId == null) {
            throw new IllegalArgumentException('Opportunity is required.');
        }
        List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE Id = :opportunityId WITH USER_MODE];
        if (opps.isEmpty()) {
            throw new IllegalArgumentException('Opportunity not found or inaccessible.');
        }
    }

    private static void populateDerived(WizardData data) {
        if (data.quoteId == null) {
            data.adjustedSubtotal = 0;
            data.downPayment = data.downPayment == null ? 0 : data.downPayment;
            data.tradeEquity = 0;
            data.tradeInCount = 0;
            return;
        }
        Quote q;
        if (data.recordId == null) {
            q = [SELECT Id, Adjusted_Subtotal__c, Buyer_Contact__c FROM Quote WHERE Id = :data.quoteId WITH USER_MODE LIMIT 1];
        } else {
            Financing__c f = [SELECT Id, Quote__c FROM Financing__c WHERE Id = :data.recordId WITH USER_MODE LIMIT 1];
            q = [SELECT Id, Adjusted_Subtotal__c, Buyer_Contact__c FROM Quote WHERE Id = :f.Quote__c WITH USER_MODE LIMIT 1];
        }
        data.adjustedSubtotal = q == null || q.Adjusted_Subtotal__c == null ? 0 : q.Adjusted_Subtotal__c;
        if (q != null && q.Buyer_Contact__c != null && data.applicantContactId == null) {
            data.applicantContactId = q.Buyer_Contact__c;
        }
        try {
            data.tradeEquity = sumAcceptedTradeEquity(data.opportunityId);
        } catch (Exception e) {
            data.tradeEquity = 0;
        }
        data.tradeInCount = [SELECT COUNT() FROM Trade_In__c WHERE Opportunity__c = :data.opportunityId AND Status__c = 'Accepted' WITH USER_MODE];
    }
}
