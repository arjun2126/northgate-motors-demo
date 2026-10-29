@isTest
private class FinanceApplicationControllerTest {
    private static final Id STD_PB = Test.getStandardPricebookId();

    private static Account makeAccount(String seed) {
        return P2TestDataFactory.makeAccount(seed);
    }

    private static Contact makeContact(Id accId, String last) {
        return P2TestDataFactory.makeContact(accId, last);
    }

    private static Vehicle_Model__c makeModel(String seed) {
        return P2TestDataFactory.makeModel(seed);
    }

    private static Vehicle__c makeVehicle(Id modelId, String vin, Integer daysAgo) {
        Vehicle__c v = new Vehicle__c(
            Vehicle_Model__c = modelId, VIN__c = vin, Status__c = 'Available',
            Acquisition_Date__c = Date.today().addDays(-daysAgo)
        );
        insert v;
        return v;
    }

    private static PricebookEntry makeEntry(String name, String cat, Decimal price) {
        Product2 p = new Product2(Name = name, Category__c = cat, IsActive = true);
        insert p;
        PricebookEntry e = new PricebookEntry(Pricebook2Id = STD_PB, Product2Id = p.Id, IsActive = true, UnitPrice = price);
        insert e;
        return e;
    }

    private static Quote makeQuote(Opportunity opp, Contact buyer, Decimal adjustedSubtotal) {
        Quote q = new Quote(
            Name = opp.Name + ' - Quote', OpportunityId = opp.Id, Pricebook2Id = STD_PB,
            ExpirationDate = Date.today().addDays(30), Quote_Valid_Until__c = Date.today().addDays(30),
            Buyer_Contact__c = buyer.Id, Adjusted_Subtotal__c = adjustedSubtotal,
            Rule_Applied_Count__c = 1
        );
        insert q;
        return q;
    }

    private static Trade_In__c makeTradeIn(Opportunity opp, Decimal appraisal, Decimal payoff, String status) {
        Trade_In__c t = new Trade_In__c(
            Opportunity__c = opp.Id, Status__c = status,
            Appraisal_Amount__c = appraisal, Payoff_Amount__c = payoff
        );
        insert t;
        return t;
    }

    private static Financing__c makeExistingDraft(Opportunity opp, Quote q, Id applicant) {
        Financing__c f = new Financing__c(
            Opportunity__c = opp.Id, Quote__c = q.Id, Applicant__c = applicant,
            Status__c = 'Draft', Amount_Financed__c = 10000, Term_Months__c = 60,
            Annual_Rate__c = 5.49, Rate_Source__c = 'Rate_Table', Lender__c = 'Northgate Financial'
        );
        System.runAs(financeUser()) {
            insert f;
        }
        return f;
    }

    private static final String FINANCE_OFFICER_USERNAME =
        'ngfinofficer.' + UserInfo.getOrganizationId() + '@ngtest.northgate.invalid';

    private static User financeUser() {
        return [SELECT Id FROM User WHERE Username = :FINANCE_OFFICER_USERNAME LIMIT 1];
    }

    @TestSetup
    static void setup() {
        insert new Rooftop__c(Name = 'Northgate Downtown');

        // Persona user + permission assignment are setup-object DML; run them inside System.runAs
        // so they aren't mixed with the non-setup Rooftop__c insert above (MIXED_DML_OPERATION).
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Profile financeProfile = [SELECT Id FROM Profile WHERE Id = :UserInfo.getProfileId()];
            User officer = new User(
                Alias = 'finoffic',
                Email = FINANCE_OFFICER_USERNAME,
                EmailEncodingKey = 'UTF-8',
                FirstName = 'Finance',
                LastName = 'Officer',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = financeProfile.Id,
                TimeZoneSidKey = 'America/New_York',
                UserName = FINANCE_OFFICER_USERNAME
            );
            insert officer;
            List<PermissionSet> permissionSets = [
                SELECT Id FROM PermissionSet WHERE Name = 'PS_Finance_Officer'
            ];
            System.assert(permissionSets.size() == 1, 'PS_Finance_Officer must exist.');
            insert new PermissionSetAssignment(AssigneeId = officer.Id, PermissionSetId = permissionSets[0].Id);

            Id salesProfileId = [SELECT Id FROM Profile WHERE Name = 'NG_Sales' LIMIT 1].Id;
            Id quoteAccessId = [SELECT Id FROM PermissionSet WHERE Name = 'PS_Quote_Workflows' LIMIT 1].Id;
            for (String mode : new List<String>{'authorized', 'denied'}) {
                User actor = new User(
                    Alias = 'finctx', LastName = 'FinanceContext' + mode,
                    Email = 'finance.context.' + mode + '@northgate.example',
                    Username = 'finance.context.' + mode + '.' + UserInfo.getOrganizationId() + '@northgate.example',
                    ProfileId = salesProfileId, EmailEncodingKey = 'UTF-8',
                    LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', TimeZoneSidKey = 'America/New_York'
                );
                insert actor;
                insert new PermissionSetAssignment(
                    AssigneeId = actor.Id,
                    PermissionSetId = mode == 'authorized' ? permissionSets[0].Id : quoteAccessId
                );
            }
        }
    }

    @isTest
    static void draftCreate_derivesAmountFromQuoteMinusDownMinusTrade() {
        Account acc = makeAccount('FinAcc1');
        Contact buyer = makeContact(acc.Id, 'FinBuyer1');
        Opportunity opp = new Opportunity(
            Name = 'FinOpp1', StageName = 'Prospecting', CloseDate = Date.today().addDays(30), AccountId = acc.Id
        );
        insert opp;
        Quote q = makeQuote(opp, buyer, 30000);
        makeTradeIn(opp, 20000, 5000, 'Accepted');
        System.runAs(financeUser()) {
            FinanceApplicationController.SaveResult result = FinanceApplicationController.saveApplication(
                null, opp.Id, q.Id, null, 2000, 'A', 60, 'Rate_Table', null, null
            );
            System.assertEquals(0, result.errors.size(),
                'no errors: ' + String.join(result.errors, ' | '));
            System.assertEquals(13000, result.amountFinanced, '30000 - 2000 - (20000 - 5000)');
            Financing__c f = [SELECT Status__c, Amount_Financed__c, Term_Months__c, Annual_Rate__c, Rate_Source__c, Applicant__c, Quote__c, Monthly_Payment__c, Total_Interest__c, Opportunity__c
                               FROM Financing__c WHERE Id = :result.financingId];
            System.assertEquals('Draft', f.Status__c);
            System.assertEquals(13000, f.Amount_Financed__c);
            System.assertEquals(60, f.Term_Months__c);
            System.assertEquals(5.49, f.Annual_Rate__c, 'table rate for A60');
            System.assertEquals('Rate_Table', f.Rate_Source__c);
            System.assertEquals(buyer.Id, f.Applicant__c, 'applicant defaulted from Quote.Buyer_Contact__c');
            System.assertEquals(q.Id, f.Quote__c);
            System.assertEquals(opp.Id, f.Opportunity__c);
            System.assertEquals(PaymentCalculatorService.monthlyPayment(13000, 5.49, 60), f.Monthly_Payment__c, 'PaymentCalculatorService rate verified');
            System.assert(result.totalInterest > 0, 'interest recorded');
        }
    }

    @isTest
    static void negativeTradeEquity_increasesFinancing() {
        Account acc = makeAccount('FinAcc2');
        Contact buyer = makeContact(acc.Id, 'FinBuyer2');
        Opportunity opp = new Opportunity(
            Name = 'FinOpp2', StageName = 'Prospecting', CloseDate = Date.today().addDays(30), AccountId = acc.Id
        );
        insert opp;
        Quote q = makeQuote(opp, buyer, 30000);
        makeTradeIn(opp, 8000, 20000, 'Accepted');
        System.runAs(financeUser()) {
            FinanceApplicationController.SaveResult result = FinanceApplicationController.saveApplication(
                null, opp.Id, q.Id, null, 1000, 'A', 60, 'Rate_Table', null, null
            );
            System.assertEquals(0, result.errors.size(), String.join(result.errors, ' | '));
            System.assertEquals(41000, result.amountFinanced, '30000 - 1000 - (8000 - 20000)');
        }
    }

    @isTest
    static void multipleAcceptedTradeIns_isAmbiguous() {
        Account acc = makeAccount('FinAcc3');
        Contact buyer = makeContact(acc.Id, 'FinBuyer3');
        Opportunity opp = new Opportunity(
            Name = 'FinOpp3', StageName = 'Prospecting', CloseDate = Date.today().addDays(30), AccountId = acc.Id
        );
        insert opp;
        Quote q = makeQuote(opp, buyer, 30000);
        makeTradeIn(opp, 12000, 2000, 'Accepted');
        makeTradeIn(opp, 15000, 5000, 'Accepted');
        System.runAs(financeUser()) {
            FinanceApplicationController.SaveResult result = FinanceApplicationController.saveApplication(
                null, opp.Id, q.Id, null, 1000, 'A', 60, 'Rate_Table', null, null
            );
            System.assertEquals(1, result.errors.size(), 'exactly one ambiguity error');
            System.assert(result.errors[0].contains('Multiple Accepted trade-ins'),
                'error names the cause: ' + result.errors[0]);
        }
    }

    @isTest
    static void zeroAcceptedTradeIns_zerosEquity() {
        Account acc = makeAccount('FinAcc4');
        Contact buyer = makeContact(acc.Id, 'FinBuyer4');
        Opportunity opp = new Opportunity(
            Name = 'FinOpp4', StageName = 'Prospecting', CloseDate = Date.today().addDays(30), AccountId = acc.Id
        );
        insert opp;
        Quote q = makeQuote(opp, buyer, 25000);
        System.runAs(financeUser()) {
            FinanceApplicationController.SaveResult result = FinanceApplicationController.saveApplication(
                null, opp.Id, q.Id, null, 5000, 'A', 60, 'Rate_Table', null, null
            );
            System.assertEquals(0, result.errors.size(), String.join(result.errors, ' | '));
            System.assertEquals(20000, result.amountFinanced, '25000 - 5000 - 0');
        }
    }

    @isTest
    static void downPaymentExceedingAdjusted_isRejected() {
        Account acc = makeAccount('FinAcc5');
        Contact buyer = makeContact(acc.Id, 'FinBuyer5');
        Opportunity opp = new Opportunity(
            Name = 'FinOpp5', StageName = 'Prospecting', CloseDate = Date.today().addDays(30), AccountId = acc.Id
        );
        insert opp;
        Quote q = makeQuote(opp, buyer, 20000);
        System.runAs(financeUser()) {
            FinanceApplicationController.SaveResult result = FinanceApplicationController.saveApplication(
                null, opp.Id, q.Id, null, 25000, 'A', 60, 'Rate_Table', null, null
            );
            System.assertEquals(1, result.errors.size());
            System.assert(result.errors[0].contains('exceed'), 'rejected with clear message');
        }
    }

    @isTest
    static void negativePrincipal_isRejected() {
        Account acc = makeAccount('FinAcc6');
        Contact buyer = makeContact(acc.Id, 'FinBuyer6');
        Opportunity opp = new Opportunity(
            Name = 'FinOpp6', StageName = 'Prospecting', CloseDate = Date.today().addDays(30), AccountId = acc.Id
        );
        insert opp;
        Quote q = makeQuote(opp, buyer, 5000);
        makeTradeIn(opp, 10000, 0, 'Accepted');
        System.runAs(financeUser()) {
            FinanceApplicationController.SaveResult result = FinanceApplicationController.saveApplication(
                null, opp.Id, q.Id, null, 1000, 'A', 60, 'Rate_Table', null, null
            );
            System.assertEquals(1, result.errors.size());
            System.assert(result.errors[0].contains('positive'), 'rejected with clear message');
        }
    }

    @isTest
    static void crossOpportunityQuote_isRejected() {
        Account acc = makeAccount('FinAcc7');
        Contact buyer = makeContact(acc.Id, 'FinBuyer7');
        Opportunity opp1 = new Opportunity(
            Name = 'FinOpp7a', StageName = 'Prospecting', CloseDate = Date.today().addDays(30), AccountId = acc.Id
        );
        Opportunity opp2 = new Opportunity(
            Name = 'FinOpp7b', StageName = 'Prospecting', CloseDate = Date.today().addDays(30), AccountId = acc.Id
        );
        insert new List<Opportunity>{ opp1, opp2 };
        Quote q1 = makeQuote(opp1, buyer, 30000);
        System.runAs(financeUser()) {
            FinanceApplicationController.SaveResult result = FinanceApplicationController.saveApplication(
                null, opp2.Id, q1.Id, null, 1000, 'A', 60, 'Rate_Table', null, null
            );
            System.assertEquals(1, result.errors.size());
            System.assert(result.errors[0].contains('does not belong'),
                'cross-opp substitution rejected: ' + result.errors[0]);
        }
    }

    @isTest
    static void draftUpdate_preservesRecord() {
        Account acc = makeAccount('FinAcc8');
        Contact buyer = makeContact(acc.Id, 'FinBuyer8');
        Opportunity opp = new Opportunity(
            Name = 'FinOpp8', StageName = 'Prospecting', CloseDate = Date.today().addDays(30), AccountId = acc.Id
        );
        insert opp;
        Quote q = makeQuote(opp, buyer, 30000);
        Financing__c existing = makeExistingDraft(opp, q, buyer.Id);
        System.runAs(financeUser()) {
            FinanceApplicationController.SaveResult result = FinanceApplicationController.saveApplication(
                existing.Id, opp.Id, q.Id, buyer.Id, 5000, 'A', 72, 'Rate_Table', null, null
            );
            System.assertEquals(0, result.errors.size(), String.join(result.errors, ' | '));
            System.assertEquals(25000, result.amountFinanced);
            Financing__c f = [SELECT Amount_Financed__c, Term_Months__c, Annual_Rate__c FROM Financing__c WHERE Id = :existing.Id];
            System.assertEquals(25000, f.Amount_Financed__c);
            System.assertEquals(72, f.Term_Months__c);
            System.assertEquals(5.99, f.Annual_Rate__c, 'table rate A72');
        }
    }

    @isTest
    static void nonDraftUpdate_isRejected() {
        Account acc = makeAccount('FinAcc9');
        Contact buyer = makeContact(acc.Id, 'FinBuyer9');
        Opportunity opp = new Opportunity(
            Name = 'FinOpp9', StageName = 'Prospecting', CloseDate = Date.today().addDays(30), AccountId = acc.Id
        );
        insert opp;
        Quote q = makeQuote(opp, buyer, 30000);
        Financing__c existing = makeExistingDraft(opp, q, buyer.Id);
        System.runAs(financeUser()) {
            existing.Status__c = 'Submitted';
            update existing;
        }
        System.runAs(financeUser()) {
            FinanceApplicationController.SaveResult result = FinanceApplicationController.saveApplication(
                existing.Id, opp.Id, q.Id, buyer.Id, 1000, 'A', 60, 'Rate_Table', null, null
            );
            System.assertEquals(1, result.errors.size());
            System.assert(result.errors[0].contains('Draft'), 'rejected: ' + result.errors[0]);
        }
    }

    @isTest
    static void existingDraftPreventsNewDraft() {
        Account acc = makeAccount('FinAcc10');
        Contact buyer = makeContact(acc.Id, 'FinBuyer10');
        Opportunity opp = new Opportunity(
            Name = 'FinOpp10', StageName = 'Prospecting', CloseDate = Date.today().addDays(30), AccountId = acc.Id
        );
        insert opp;
        Quote q = makeQuote(opp, buyer, 30000);
        makeExistingDraft(opp, q, buyer.Id);
        System.runAs(financeUser()) {
            FinanceApplicationController.SaveResult result = FinanceApplicationController.saveApplication(
                null, opp.Id, q.Id, null, 1000, 'A', 60, 'Rate_Table', null, null
            );
            System.assertEquals(1, result.errors.size());
            System.assert(result.errors[0].contains('Draft already exists'),
                'uniqueness enforced server-side: ' + result.errors[0]);
        }
    }

    @isTest
    static void manualException_stampsReasonAndRate() {
        Account acc = makeAccount('FinAcc11');
        Contact buyer = makeContact(acc.Id, 'FinBuyer11');
        Opportunity opp = new Opportunity(
            Name = 'FinOpp11', StageName = 'Prospecting', CloseDate = Date.today().addDays(30), AccountId = acc.Id
        );
        insert opp;
        Quote q = makeQuote(opp, buyer, 30000);
        System.runAs(financeUser()) {
            FinanceApplicationController.SaveResult result = FinanceApplicationController.saveApplication(
                null, opp.Id, q.Id, null, 1000, 'A', 60, 'Manual_Exception', 6.25, 'Loyalty override approved by manager.'
            );
            System.assertEquals(0, result.errors.size(), String.join(result.errors, ' | '));
            Financing__c f = [SELECT Annual_Rate__c, Rate_Source__c, Exception_Reason__c FROM Financing__c WHERE Id = :result.financingId];
            System.assertEquals(6.25, f.Annual_Rate__c);
            System.assertEquals('Manual_Exception', f.Rate_Source__c);
            System.assertEquals('Loyalty override approved by manager.', f.Exception_Reason__c);
        }
    }

    @isTest
    static void multipleDrafts_surfacesAmbiguityAndBlocksNew() {
        Account acc = makeAccount('FinAccMulti');
        Contact buyer = makeContact(acc.Id, 'FinMulti');
        Opportunity opp = new Opportunity(
            Name = 'FinOppMulti', StageName = 'Prospecting', CloseDate = Date.today().addDays(30), AccountId = acc.Id
        );
        insert opp;
        Quote q = makeQuote(opp, buyer, 30000);
        Financing__c a = makeExistingDraft(opp, q, buyer.Id);
        Financing__c b = new Financing__c(
            Opportunity__c = opp.Id, Quote__c = q.Id, Applicant__c = buyer.Id,
            Status__c = 'Draft', Amount_Financed__c = 12000, Term_Months__c = 60,
            Annual_Rate__c = 5.49, Rate_Source__c = 'Rate_Table', Lender__c = 'Northgate Financial'
        );
        System.runAs(financeUser()) {
            insert b;
        }
        System.runAs(financeUser()) {
            FinanceApplicationController.WizardData load = FinanceApplicationController.load(opp.Id);
            System.assertEquals('ambiguous', load.mode, 'multiple Drafts surface ambiguous mode');
            System.assertEquals(2, load.draftCount, 'draftCount matches org count');
            FinanceApplicationController.SaveResult result = FinanceApplicationController.saveApplication(
                null, opp.Id, q.Id, null, 1000, 'A', 60, 'Rate_Table', null, null
            );
            System.assert(result.errors.size() > 0, 'new create blocked when multiple Drafts exist');
            System.assert(result.errors[0].contains('Multiple Draft') || result.errors[0].contains('Draft already'),
                'error names the cause: ' + result.errors[0]);
        }
    }

    @isTest
    static void manualExceptionWithoutReason_isRejected() {
        Account acc = makeAccount('FinAcc12');
        Contact buyer = makeContact(acc.Id, 'FinBuyer12');
        Opportunity opp = new Opportunity(
            Name = 'FinOpp12', StageName = 'Prospecting', CloseDate = Date.today().addDays(30), AccountId = acc.Id
        );
        insert opp;
        Quote q = makeQuote(opp, buyer, 30000);
        System.runAs(financeUser()) {
            FinanceApplicationController.SaveResult result = FinanceApplicationController.saveApplication(
                null, opp.Id, q.Id, null, 1000, 'A', 60, 'Manual_Exception', 6.25, null
            );
            System.assertEquals(1, result.errors.size());
            System.assert(result.errors[0].contains('reason'), 'reason required: ' + result.errors[0]);
        }
    }

    @isTest
    static void preview_newApplication_returnsSelectedQuoteFigures() {
        Account acc = makeAccount('FinAccPrev1');
        Contact buyer = makeContact(acc.Id, 'FinPrevBuyer1');
        Opportunity opp = new Opportunity(
            Name = 'FinOppPrev1', StageName = 'Prospecting', CloseDate = Date.today().addDays(30), AccountId = acc.Id
        );
        insert opp;
        Quote q = makeQuote(opp, buyer, 30000);
        System.runAs(financeUser()) {
            FinanceApplicationController.SaveResult result = FinanceApplicationController.preview(
                opp.Id, q.Id, 2000, 'A', 60, 'Rate_Table', null, null
            );
            System.assertEquals(0, result.errors.size(), 'no errors: ' + String.join(result.errors, ' | '));
            System.assertEquals(30000, result.adjustedSubtotal, 'server-adjusted selling price from the selected Quote');
            System.assertEquals(0, result.tradeEquity, 'no Accepted trade-in means zero equity');
            System.assertEquals(28000, result.amountFinanced, '30000 - 2000 - 0');
            System.assertEquals(
                PaymentCalculatorService.monthlyPayment(28000, 5.49, 60),
                result.monthlyPayment,
                'table rate A60'
            );
        }
    }

    @isTest
    static void applicantRequired_whenNoApplicantAndQuoteBuyerNull_isRejected() {
        Account acc = makeAccount('FinAccNoBuyer');
        Opportunity opp = new Opportunity(
            Name = 'FinOppNoBuyer', StageName = 'Prospecting', CloseDate = Date.today().addDays(30), AccountId = acc.Id
        );
        insert opp;
        Quote q = new Quote(
            Name = opp.Name + ' - Quote', OpportunityId = opp.Id, Pricebook2Id = STD_PB,
            ExpirationDate = Date.today().addDays(30), Quote_Valid_Until__c = Date.today().addDays(30),
            Buyer_Contact__c = null, Adjusted_Subtotal__c = 30000, Rule_Applied_Count__c = 1
        );
        insert q;
        System.runAs(financeUser()) {
            FinanceApplicationController.SaveResult result = FinanceApplicationController.saveApplication(
                null, opp.Id, q.Id, null, 0, 'A', 60, 'Rate_Table', null, null
            );
            System.assertEquals(1, result.errors.size(), 'applicant required: ' + String.join(result.errors, ' | '));
            System.assert(result.errors[0].contains('Applicant is required'), result.errors[0]);
            System.assertEquals(null, result.financingId, 'no financing created without a Contact');
        }
    }

    @isTest
    static void preview_signedTradeEquity_includedInFinancing() {
        Account acc = makeAccount('FinAccPrev2');
        Contact buyer = makeContact(acc.Id, 'FinPrevBuyer2');
        Opportunity opp = new Opportunity(
            Name = 'FinOppPrev2', StageName = 'Prospecting', CloseDate = Date.today().addDays(30), AccountId = acc.Id
        );
        insert opp;
        Quote q = makeQuote(opp, buyer, 30000);
        makeTradeIn(opp, 8000, 20000, 'Accepted');
        System.runAs(financeUser()) {
            FinanceApplicationController.SaveResult result = FinanceApplicationController.preview(
                opp.Id, q.Id, 1000, 'A', 60, 'Rate_Table', null, null
            );
            System.assertEquals(0, result.errors.size(), String.join(result.errors, ' | '));
            System.assertEquals(30000, result.adjustedSubtotal);
            System.assertEquals(-12000, result.tradeEquity, '8000 appraisal - 20000 payoff');
            System.assertEquals(41000, result.amountFinanced, '30000 - 1000 - (-12000)');
        }
    }

    private static User contextActor(String mode) {
        String lastName = 'FinanceContext' + mode;
        return [SELECT Id FROM User WHERE LastName = :lastName LIMIT 1];
    }

    private class LaunchFixture {
        Opportunity opportunity;
        Quote quote;
        Financing__c draft;
    }

    private static LaunchFixture launchFixture(User owner, Boolean withDraft) {
        Account account = new Account(Name = 'Finance launch context', OwnerId = owner.Id);
        insert account;
        Contact buyer = new Contact(LastName = 'Finance launch buyer', AccountId = account.Id, OwnerId = owner.Id);
        insert buyer;
        LaunchFixture f = new LaunchFixture();
        f.opportunity = new Opportunity(
            Name = 'Finance launch context', AccountId = account.Id, OwnerId = owner.Id,
            StageName = 'Prospecting', CloseDate = Date.today().addDays(30)
        );
        insert f.opportunity;
        f.quote = makeQuote(f.opportunity, buyer, 30000);
        if (withDraft) {
            f.draft = new Financing__c(
                Opportunity__c = f.opportunity.Id, Quote__c = f.quote.Id, Applicant__c = buyer.Id,
                OwnerId = owner.Id, Status__c = 'Draft', Amount_Financed__c = 28000,
                Down_Payment__c = 2000, Term_Months__c = 60, Annual_Rate__c = 5.49,
                Rate_Source__c = 'Rate_Table', Credit_Tier__c = 'A', Lender__c = 'Northgate Financial'
            );
            insert f.draft;
        }
        return f;
    }

    @isTest
    static void launchContextsResolveSameOpportunityAndDraft() {
        User actor = contextActor('authorized');
        LaunchFixture f = launchFixture(actor, true);
        System.runAs(actor) {
            System.assert(Schema.SObjectType.Financing__c.isAccessible(), 'Use the authorized non-admin persona.');
            FinanceApplicationController.WizardData direct = FinanceApplicationController.loadForRecord(f.opportunity.Id);
            FinanceApplicationController.WizardData related = FinanceApplicationController.loadForRecord(f.draft.Id);
            System.assertEquals(f.opportunity.Id, related.opportunityId);
            System.assertEquals(direct.mode, related.mode);
            System.assertEquals('edit', related.mode);
            System.assertEquals(f.draft.Id, related.recordId);
            System.assertEquals(f.quote.Id, related.quoteId);
            System.assertEquals(1, related.draftCount);
            System.assertEquals(direct.adjustedSubtotal, related.adjustedSubtotal);
            System.assertEquals(direct.downPayment, related.downPayment);
            System.assertEquals(direct.applicantContactId, related.applicantContactId);
            System.assertEquals(1, related.eligibleQuotes.size());
            FinanceApplicationController.SaveResult preview = FinanceApplicationController.preview(
                related.opportunityId, related.quoteId, related.downPayment, 'A', 60, 'Rate_Table', null, null
            );
            System.assertEquals(0, preview.errors.size(), String.join(preview.errors, ' | '));
            System.assertEquals(28000, preview.amountFinanced);
            System.assertEquals(PaymentCalculatorService.monthlyPayment(28000, 5.49, 60), preview.monthlyPayment);
        }
        System.assertEquals(1, [SELECT COUNT() FROM Financing__c WHERE Opportunity__c = :f.opportunity.Id], 'Loading never creates a draft.');
    }

    @isTest
    static void opportunityLaunchWithoutDraftKeepsNewMode() {
        User actor = contextActor('authorized');
        LaunchFixture f = launchFixture(actor, false);
        System.runAs(actor) {
            FinanceApplicationController.WizardData data = FinanceApplicationController.loadForRecord(f.opportunity.Id);
            System.assertEquals('new', data.mode);
            System.assertEquals(null, data.recordId);
            System.assertEquals(0, data.draftCount);
            System.assertEquals(f.opportunity.Id, data.opportunityId);
        }
        System.assertEquals(0, [SELECT COUNT() FROM Financing__c WHERE Opportunity__c = :f.opportunity.Id]);
    }

    @isTest
    static void financingLaunchPreservesAmbiguousDraftSelection() {
        User actor = contextActor('authorized');
        LaunchFixture f = launchFixture(actor, true);
        Financing__c second = f.draft.clone(false, false, false, false);
        insert second;
        System.runAs(actor) {
            FinanceApplicationController.WizardData direct = FinanceApplicationController.loadForRecord(f.opportunity.Id);
            FinanceApplicationController.WizardData related = FinanceApplicationController.loadForRecord(f.draft.Id);
            System.assertEquals('ambiguous', related.mode);
            System.assertEquals(direct.mode, related.mode);
            System.assertEquals(2, related.draftCount);
        }
    }

    @isTest
    static void financingLaunchRejectsUnsharedRecordEvenWithVisibleOpportunity() {
        User actor = contextActor('authorized');
        LaunchFixture f = launchFixture(actor, true);
        f.draft.OwnerId = financeUser().Id;
        update f.draft;
        System.runAs(actor) {
            System.assertEquals(1, [SELECT COUNT() FROM Opportunity WHERE Id = :f.opportunity.Id WITH USER_MODE]);
            System.assertEquals(0, [SELECT COUNT() FROM Financing__c WHERE Id = :f.draft.Id WITH USER_MODE]);
            try {
                FinanceApplicationController.loadForRecord(f.draft.Id);
                System.assert(false, 'A visible parent must not authorize an unshared Financing record.');
            } catch (IllegalArgumentException expected) {
                System.assertEquals('Financing record or linked Opportunity not found or inaccessible.', expected.getMessage());
            }
        }
    }

    @isTest
    static void financingLaunchRejectsUnsharedOpportunityEvenWithVisibleFinancing() {
        User actor = contextActor('authorized');
        LaunchFixture f = launchFixture(financeUser(), true);
        f.draft.OwnerId = actor.Id;
        update f.draft;
        System.runAs(actor) {
            System.assertEquals(1, [SELECT COUNT() FROM Financing__c WHERE Id = :f.draft.Id WITH USER_MODE]);
            System.assertEquals(0, [SELECT COUNT() FROM Opportunity WHERE Id = :f.opportunity.Id WITH USER_MODE]);
            try {
                FinanceApplicationController.loadForRecord(f.draft.Id);
                System.assert(false, 'Financing ownership must not authorize its private Opportunity.');
            } catch (IllegalArgumentException expected) {
                System.assertEquals('Opportunity not found or inaccessible.', expected.getMessage());
            }
        }
    }

    @isTest
    static void financingLaunchRejectsMissingObjectAccess() {
        User actor = contextActor('denied');
        LaunchFixture f = launchFixture(actor, true);
        System.runAs(actor) {
            System.assert(!Schema.SObjectType.Financing__c.isAccessible(), 'Actor genuinely lacks Financing object access.');
            try {
                FinanceApplicationController.loadForRecord(f.draft.Id);
                System.assert(false, 'Context resolution must enforce user-mode object access.');
            } catch (QueryException expected) {
                System.assertNotEquals(null, expected.getMessage());
            }
        }
    }

    @isTest
    static void launchRejectsMissingAndUnsupportedContexts() {
        User actor = contextActor('authorized');
        LaunchFixture f = launchFixture(actor, true);
        Id removedId = f.draft.Id;
        delete f.draft;
        System.runAs(actor) {
            for (Id contextId : new List<Id>{null, actor.Id, removedId}) {
                try {
                    FinanceApplicationController.loadForRecord(contextId);
                    System.assert(false, 'Missing or unsupported context must not initialize.');
                } catch (IllegalArgumentException expected) {
                    System.assertNotEquals(null, expected.getMessage());
                }
            }
        }
    }
}
