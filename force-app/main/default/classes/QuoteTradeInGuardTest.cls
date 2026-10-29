@isTest
private class QuoteTradeInGuardTest {
    private static final String NO_BYPASS_USERNAME = 'guard.nobypass@northgate.example';

    @TestSetup
    static void setup() {
        insert new List<Rooftop__c>{ new Rooftop__c(Name = 'Northgate Downtown'), new Rooftop__c(Name = 'Northgate North') };
        // Category A fix: create a test persona WITHOUT Bypass_Automation permission.
        // Default test runner (arjun.ngdemo) has Bypass_Automation via PS_Demo_Admin,
        // which disables the guard. We run the blocked-path tests as this user instead.
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Profile p = [SELECT Id FROM Profile WHERE Name = 'NG_Sales' LIMIT 1];
            User rep = new User(
                Alias = 'nbypass',
                Email = NO_BYPASS_USERNAME,
                EmailEncodingKey = 'UTF-8',
                LastName = 'GuardNoBypass',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = p.Id,
                TimeZoneSidKey = 'America/New_York',
                UserName = NO_BYPASS_USERNAME
            );
            insert rep;
            // PS_Sales_Rep grants Opportunity.Has_Trade_In__c + related field FLS that
            // the guard reads; without it the persona fails on "No such column 'Has_Trade_In__c'".
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'PS_Sales_Rep' LIMIT 1];
            insert new PermissionSetAssignment(AssigneeId = rep.Id, PermissionSetId = ps.Id);
        }
    }

    private static User noBypassUser() {
        return [SELECT Id FROM User WHERE Username = :NO_BYPASS_USERNAME LIMIT 1];
    }

    private static Map<String, Id> rooftopIds() {
        Map<String, Id> ids = new Map<String, Id>();
        for (Rooftop__c r : [SELECT Id, Name FROM Rooftop__c]) {
            ids.put(r.Name, r.Id);
        }
        return ids;
    }

    private static Opportunity makeOpportunity(Id rooftopId, Boolean hasTradeIn) {
        return new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Rooftop__c = rooftopId,
            Has_Trade_In__c = hasTradeIn
        );
    }

    private static Trade_In__c makeTradeIn(Id opportunityId, String status) {
        return new Trade_In__c(
            Opportunity__c = opportunityId,
            Status__c = status,
            Appraisal_Amount__c = 20000,
            Payoff_Amount__c = 10000,
            Trade_Year__c = 2020,
            Trade_Make__c = 'Toyota',
            Trade_Model__c = 'Camry',
            Trade_Odometer__c = 50000,
            Trade_Condition__c = 'Good',
            Trade_VIN__c = '1HGBH41JXMN109186'
        );
    }

    @isTest
    static void guard_false_noChild_allowed() {
        Opportunity opp = makeOpportunity(null, false);
        insert opp;

        Quote q = new Quote(
            OpportunityId = opp.Id,
            Name = 'Test Quote',
            Pricebook2Id = Test.getStandardPricebookId(),
            ExpirationDate = Date.today().addDays(30)
        );

        List<Quote> scope = new List<Quote>{ q };
        QuoteTradeInGuard.guard(scope);
        System.assertEquals(0, q.getErrors().size(), 'Quote should be allowed when Has_Trade_In__c is false');
    }

    @isTest
    static void guard_false_appraisedChild_allowed() {
        Opportunity opp = makeOpportunity(null, false);
        insert opp;

        Trade_In__c ti = new Trade_In__c(
            Opportunity__c = opp.Id,
            Status__c = 'Appraised',
            Appraisal_Amount__c = 20000,
            Payoff_Amount__c = 5000,
            Trade_Year__c = 2020,
            Trade_Make__c = 'Toyota',
            Trade_Model__c = 'Camry',
            Trade_Odometer__c = 50000,
            Trade_Condition__c = 'Good',
            Trade_VIN__c = '1HGBH41JXMN109186'
        );
        insert ti;

        Quote q = new Quote(
            OpportunityId = opp.Id,
            Name = 'Test Quote',
            Pricebook2Id = Test.getStandardPricebookId(),
            ExpirationDate = Date.today().addDays(30)
        );

        List<Quote> scope = new List<Quote>{ q };
        QuoteTradeInGuard.guard(scope);
        System.assertEquals(0, q.getErrors().size(), 'Quote should be allowed when Has_Trade_In__c is false regardless of child');
    }

    @isTest
    static void guard_true_noChild_blocked() {
        User rep = noBypassUser();
        Opportunity opp = makeOpportunity(null, true);
        opp.OwnerId = rep.Id;
        insert opp;

        Quote q = new Quote(
            OpportunityId = opp.Id,
            Name = 'Test Quote',
            Pricebook2Id = Test.getStandardPricebookId(),
            ExpirationDate = Date.today().addDays(30)
        );

        List<Quote> scope = new List<Quote>{ q };
        System.runAs(rep) {
            QuoteTradeInGuard.guard(scope);
        }
        System.assertEquals(1, q.getErrors().size(), 'Quote should be blocked when Has_Trade_In__c is true and no child exists');
        System.assert(q.getErrors()[0].getMessage().contains('Trade-in must be Accepted'), 'Error message should mention Accepted trade-in');
    }

    @isTest
    static void guard_true_appraisedOnly_blocked() {
        User rep = noBypassUser();
        Opportunity opp = makeOpportunity(null, true);
        opp.OwnerId = rep.Id;
        insert opp;

        Trade_In__c ti = new Trade_In__c(
            Opportunity__c = opp.Id,
            Status__c = 'Appraised',
            Appraisal_Amount__c = 20000,
            Payoff_Amount__c = 5000,
            Trade_Year__c = 2020,
            Trade_Make__c = 'Toyota',
            Trade_Model__c = 'Camry',
            Trade_Odometer__c = 50000,
            Trade_Condition__c = 'Good',
            Trade_VIN__c = '1HGBH41JXMN109186'
        );
        insert ti;

        Quote q = new Quote(
            OpportunityId = opp.Id,
            Name = 'Test Quote',
            Pricebook2Id = Test.getStandardPricebookId(),
            ExpirationDate = Date.today().addDays(30)
        );

        List<Quote> scope = new List<Quote>{ q };
        System.runAs(rep) {
            QuoteTradeInGuard.guard(scope);
        }
        System.assertEquals(1, q.getErrors().size(), 'Quote should be blocked when Has_Trade_In__c is true and only Appraised child exists');
        System.assert(q.getErrors()[0].getMessage().contains('Trade-in must be Accepted'), 'Error message should mention Accepted trade-in');
    }

    @isTest
    static void guard_true_accepted_allowed() {
        Opportunity opp = makeOpportunity(null, true);
        insert opp;

        Trade_In__c ti = new Trade_In__c(
            Opportunity__c = opp.Id,
            Status__c = 'Accepted',
            Appraisal_Amount__c = 20000,
            Payoff_Amount__c = 10000,
            Trade_Year__c = 2020,
            Trade_Make__c = 'Toyota',
            Trade_Model__c = 'Camry',
            Trade_Odometer__c = 50000,
            Trade_Condition__c = 'Good',
            Trade_VIN__c = '1HGBH41JXMN109186'
        );
        insert ti;

        Quote q = new Quote(
            OpportunityId = opp.Id,
            Name = 'Test Quote',
            Pricebook2Id = Test.getStandardPricebookId(),
            ExpirationDate = Date.today().addDays(30)
        );

        List<Quote> scope = new List<Quote>{ q };
        QuoteTradeInGuard.guard(scope);
        System.assertEquals(0, q.getErrors().size(), 'Quote should be allowed when Has_Trade_In__c is true and Accepted child exists');
    }

    @isTest
    static void guard_true_acceptedPlusAppraised_allowed() {
        Opportunity opp = makeOpportunity(null, true);
        insert opp;

        Trade_In__c tiAppraised = new Trade_In__c(
            Opportunity__c = opp.Id,
            Status__c = 'Appraised',
            Appraisal_Amount__c = 20000,
            Payoff_Amount__c = 5000,
            Trade_Year__c = 2020,
            Trade_Make__c = 'Toyota',
            Trade_Model__c = 'Camry',
            Trade_Odometer__c = 50000,
            Trade_Condition__c = 'Good',
            Trade_VIN__c = '1HGBH41JXMN109186'
        );
        insert tiAppraised;

        Trade_In__c tiAccepted = new Trade_In__c(
            Opportunity__c = opp.Id,
            Status__c = 'Accepted',
            Appraisal_Amount__c = 25000,
            Payoff_Amount__c = 5000,
            Trade_Year__c = 2021,
            Trade_Make__c = 'Honda',
            Trade_Model__c = 'Accord',
            Trade_Odometer__c = 30000,
            Trade_Condition__c = 'Excellent',
            Trade_VIN__c = '2HGBH41JXMN109187'
        );
        insert tiAccepted;

        Quote q = new Quote(
            OpportunityId = opp.Id,
            Name = 'Test Quote',
            Pricebook2Id = Test.getStandardPricebookId(),
            ExpirationDate = Date.today().addDays(30)
        );

        List<Quote> scope = new List<Quote>{ q };
        QuoteTradeInGuard.guard(scope);
        System.assertEquals(0, q.getErrors().size(), 'Quote should be allowed when Has_Trade_In__c is true and any Accepted child exists');
    }

    @isTest
    static void guard_bypassEnabled_allowed() {
        Opportunity opp = makeOpportunity(null, true);
        insert opp;

        Trade_In__c ti = new Trade_In__c(
            Opportunity__c = opp.Id,
            Status__c = 'Appraised',
            Appraisal_Amount__c = 20000,
            Payoff_Amount__c = 5000,
            Trade_Year__c = 2020,
            Trade_Make__c = 'Toyota',
            Trade_Model__c = 'Camry',
            Trade_Odometer__c = 50000,
            Trade_Condition__c = 'Good',
            Trade_VIN__c = '1HGBH41JXMN109186'
        );
        insert ti;

        Quote q = new Quote(
            OpportunityId = opp.Id,
            Name = 'Test Quote',
            Pricebook2Id = Test.getStandardPricebookId(),
            ExpirationDate = Date.today().addDays(30)
        );

        List<Quote> scope = new List<Quote>{ q };
        QuoteTradeInGuard.guard(scope);
        System.assert(true, 'Guard executed without exception');
    }
}