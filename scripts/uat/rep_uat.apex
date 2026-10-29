// SUPERSEDED 2026-10-20. System.runAs is test-only and this anonymous script fails.
// Use scripts/uat/rep_setup.apex, then browser Login As, then scripts/uat/rep_verify.apex.
User rep = [SELECT Id, Username FROM User WHERE Id = '005aj00000gE0b3AAC'];
Map<String, Object> r = new Map<String, Object>();
r.put('tag', 'UAT-2026-10-19');
System.runAs(rep) {
    try {
        Account a = new Account(Name = 'UAT-2026-10-19 Household', Type = 'Household');
        insert a;
        r.put('accountId', a.Id);

        Contact c = new Contact(LastName = 'UAT Buyer', AccountId = a.Id);
        insert c;
        r.put('contactId', c.Id);

        Date cd = Date.today().addDays(30);
        Opportunity o = new Opportunity(
            Name = 'UAT-2026-10-19 QUOTE',
            AccountId = a.Id,
            CloseDate = cd,
            StageName = 'Quoting',
            Vehicle__c = 'a0Daj00001D2FPZEA3'
        );
        insert o;
        r.put('opportunityId', o.Id);

        Delivery__c d = new Delivery__c(
            Opportunity__c = o.Id,
            Vehicle__c = 'a0Daj00001D2FPZEA3',
            Status__c = 'Scheduled',
            Scheduled_Date__c = cd
        );
        insert d;
        r.put('deliveryId', d.Id);

        Test_Drive__c td = new Test_Drive__c(
            Contact__c = c.Id,
            Vehicle__c = 'a0Daj00001D2FPZEA3',
            Scheduled_Start__c = Datetime.now().addDays(1)
        );
        insert td;
        r.put('testDriveId', td.Id);

        Trade_In__c ti = new Trade_In__c(Opportunity__c = o.Id);
        insert ti;
        r.put('tradeInId', ti.Id);

        Loyalty_Member__c lm = new Loyalty_Member__c(Contact__c = c.Id, Status__c = 'Active');
        insert lm;
        r.put('loyaltyMemberId', lm.Id);

        List<QuoteBuilderController.CatalogItem> catalog = QuoteBuilderController.getCatalog('Vehicle_Trim');
        r.put('catalogCount', catalog.size());

        try {
            QuoteBuilderController.LineInput li = new QuoteBuilderController.LineInput();
            li.productId = '01taj00000YGzDyAAL';
            li.quantity = 1;
            QuoteBuilderController.createQuote(o.Id, c.Id, new List<QuoteBuilderController.LineInput>{ li });
            r.put('quoteBuilder', 'UNEXPECTED_SUCCESS');
        } catch (Exception qe) {
            r.put('quoteBuilderError', qe.getMessage());
        }

        r.put('oppVisible', [SELECT Id FROM Opportunity WITH USER_MODE].size());
        r.put('accountVisible', [SELECT Id FROM Account WITH USER_MODE].size());
        r.put('leadVisible', [SELECT Id FROM Lead WITH USER_MODE].size());
        r.put('deliveryVisible', [SELECT Id FROM Delivery__c WITH USER_MODE].size());
        r.put('loyaltyVisible', [SELECT Id FROM Loyalty_Member__c WITH USER_MODE].size());
        r.put('vehicleVisible', [SELECT Id FROM Vehicle__c WITH USER_MODE].size());
        r.put('testDriveVisible', [SELECT Id FROM Test_Drive__c WITH USER_MODE].size());
        r.put('tradeInVisible', [SELECT Id FROM Trade_In__c WITH USER_MODE].size());

        r.put('vehicleCreateFls', Schema.sObjectType.Vehicle__c.isCreateable());
    } catch (Exception e) {
        r.put('fatalError', e.getMessage() + ' :: ' + e.getStackTraceString());
    }
}
System.debug('UAT_RESULT=' + JSON.serialize(r));
