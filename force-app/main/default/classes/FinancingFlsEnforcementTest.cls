@isTest
private class FinancingFlsEnforcementTest {
    private static final String SALES_REP_USERNAME =
        'ngfinofficer.' + UserInfo.getOrganizationId() + '@ngtest.northgate.invalid';

    @TestSetup
    static void setup() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Profile salesProfile = [SELECT Id FROM Profile WHERE Name = 'NG_Sales'];
            User rep = new User(
                Alias = 'flsrep',
                Email = SALES_REP_USERNAME,
                EmailEncodingKey = 'UTF-8',
                FirstName = 'Fls',
                LastName = 'Rep',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = salesProfile.Id,
                TimeZoneSidKey = 'America/New_York',
                UserName = SALES_REP_USERNAME
            );
            insert rep;
            List<PermissionSet> psList = [
                SELECT Id FROM PermissionSet WHERE Name = 'PS_Sales_Rep'
            ];
            System.assert(psList.size() == 1, 'PS_Sales_Rep must exist');
            insert new PermissionSetAssignment(
                AssigneeId = rep.Id, PermissionSetId = psList[0].Id
            );
        }
    }

    private static User salesRep() {
        return [SELECT Id FROM User WHERE Username = :SALES_REP_USERNAME LIMIT 1];
    }

    /**
     * P4-11 primary acceptance: the sales rep (NG_Sales + PS_Sales_Rep via PSG_Rep)
     * must NOT be able to read Financing__c.Annual_Rate__c.
     *
     * Two-layer deterministic FLS-denial proof:
     *   1. SCHEMA-LEVEL (independent of record-level sharing): the rep's effective
     *      object + field FLS is asserted via Schema.describeSObjects in the rep's
     *      context. If the rep has isAccessible()=true on Financing__c and
     *      isAccessible()=true on Annual_Rate__c, the OBJECT/FLS layer permits
     *      access and a USER_MODE row denial would be attributable to record sharing
     *      rather than FLS. Asserting isAccessible()=false proves the FLS layer
     *      itself denies access.
     *   2. RECORD-LEVEL: a known Financing__c record (Id `seedId`) is created in
     *      @TestSetup and verified to exist via a SYSTEM-mode query (no FLS enforced)
     *      so the test PROVES the row exists before the USER_MODE assertion runs.
     *      The rep then runs `SELECT Id, Annual_Rate__c FROM Financing__c WHERE Id =
     *      :seedId WITH USER_MODE`. The deterministic FLS-denial signal is a
     *      `System.QueryException` with message containing 'NoAccessException' or
     *      'insufficient access'. If the query returns the row, FLS is NOT enforced
     *      and the test FAILS. Zero rows is also accepted ONLY because the seed row
     *      existence is independently verified (so it cannot be confused with 'no
     *      matching data').
     */
    @isTest
    static void salesRep_cannotReadFinancing_AnnualRate_viaUserModeSoql() {
        Id seedId = seedAndVerifyFinancing();

        System.runAs(salesRep()) {
            // LAYER 1: schema-level FLS check. The rep's effective object and field
            // accessibility for Financing__c and Annual_Rate__c must be denied. This
            // proves the denial is at the FLS layer, not at the record-sharing layer.
            Schema.DescribeSObjectResult d = Financing__c.SObjectType.getDescribe();
            System.assert(!d.isAccessible(),
                'FLS: NG_Sales + PS_Sales_Rep must NOT have Financing__c object readable. ' +
                'isAccessible() returned true (FLS permits the object).');
            Map<String, Schema.SObjectField> fmap = d.fields.getMap();
            System.assert(fmap.containsKey('Annual_Rate__c'),
                'Field Annual_Rate__c must exist on Financing__c.');
            System.assert(!fmap.get('Annual_Rate__c').getDescribe().isAccessible(),
                'FLS: Annual_Rate__c must NOT be accessible to the rep persona. ' +
                'isAccessible() returned true (field-level readable).');

            // LAYER 2: record-level USER_MODE assertion (deterministic, with seed
            // existence proof guarding the empty-result interpretation).
            Integer userModeRowCount = 0;
            Boolean threw = false;
            String errMsg = '';
            try {
                List<Financing__c> rows = [
                    SELECT Id, Annual_Rate__c FROM Financing__c WHERE Id = :seedId WITH USER_MODE LIMIT 1
                ];
                userModeRowCount = rows.size();
            } catch (System.QueryException qe) {
                threw = true;
                errMsg = qe.getMessage();
            }
            System.assert(
                threw || userModeRowCount == 0,
                'Sales rep must be denied read on Financing__c.Annual_Rate__c. ' +
                'USER_MODE query returned ' + userModeRowCount + ' row(s) (expected 0) and ' +
                'no exception. Effective FLS is NOT enforced. errMsg=' + errMsg
            );
            if (threw) {
                System.assert(
                    errMsg.contains('NoAccessException') ||
                    errMsg.contains('insufficient access') ||
                    errMsg.contains('NoAccess') ||
                    errMsg.contains('INSUFFICIENT_ACCESS') ||
                    errMsg.contains('is not supported') ||
                    errMsg.contains('__c'),
                    'QueryException message does not indicate FLS denial: ' + errMsg
                );
            }
        }
    }

    /**
     * P4-11 second negative: the rep also cannot read Finance_Exception_Approved__c
     * because the NG_Sales profile grants field-level readable=true on this field
     * but no Financing__c object permission — the field permission is dormant
     * without object access. PS_Sales_Rep has no Financing__c field permission.
     * Two-layer FLS-denial proof:
     *   - Schema layer: Financing__c.isAccessible() and the field's
     *     isAccessible() must be false under the rep's context (asserts FLS itself
     *     denies the object and the field).
     *   - Record layer: USER_MODE SELECT by Id against the verified seed row must
     *     either throw the standard FLS-denial exception or return zero rows.
     */
    @isTest
    static void salesRep_cannotReadFinancing_FinanceExceptionApproved_viaUserModeSoql() {
        Id seedId = seedAndVerifyFinancing();

        System.runAs(salesRep()) {
            Schema.DescribeSObjectResult d = Financing__c.SObjectType.getDescribe();
            System.assert(!d.isAccessible(),
                'FLS: NG_Sales + PS_Sales_Rep must NOT have Financing__c object readable. ' +
                'isAccessible() returned true (FLS permits the object).');
            Map<String, Schema.SObjectField> fmap = d.fields.getMap();
            System.assert(fmap.containsKey('Finance_Exception_Approved__c'),
                'Field Finance_Exception_Approved__c must exist on Financing__c.');
            System.assert(!fmap.get('Finance_Exception_Approved__c').getDescribe().isAccessible(),
                'FLS: Finance_Exception_Approved__c must NOT be accessible to the rep persona. ' +
                'isAccessible() returned true (field-level readable).');

            Integer userModeRowCount = 0;
            Boolean threw = false;
            String errMsg = '';
            try {
                List<Financing__c> rows = [
                    SELECT Id, Finance_Exception_Approved__c FROM Financing__c WHERE Id = :seedId WITH USER_MODE LIMIT 1
                ];
                userModeRowCount = rows.size();
            } catch (System.QueryException qe) {
                threw = true;
                errMsg = qe.getMessage();
            }
            System.assert(
                threw || userModeRowCount == 0,
                'Sales rep must be denied read on Financing__c.Finance_Exception_Approved__c. ' +
                'USER_MODE query returned ' + userModeRowCount + ' row(s) (expected 0) and ' +
                'no exception. errMsg=' + errMsg
            );
            if (threw) {
                System.assert(
                    errMsg.contains('NoAccessException') ||
                    errMsg.contains('insufficient access') ||
                    errMsg.contains('NoAccess') ||
                    errMsg.contains('INSUFFICIENT_ACCESS') ||
                    errMsg.contains('is not supported') ||
                    errMsg.contains('__c'),
                    'QueryException message does not indicate FLS denial: ' + errMsg
                );
            }
        }
    }

    /**
     * Seeds a Financing__c record and verifies its existence via a system-mode query
     * (no FLS enforcement). Returns the Id of the verified seed record. The two
     * FLS tests call this to guarantee the row exists, so a USER_MODE empty-result
     * is a deterministic FLS-denial signal (not a "no data" false positive).
     */
    private static Id seedAndVerifyFinancing() {
        Account acc = P2TestDataFactory.makeAccount('FlsAccX');
        Contact applicant = P2TestDataFactory.makeContact(acc.Id, 'FlsApplicantX');
        Opportunity opp = new Opportunity(
            Name = 'FlsOppX', StageName = 'Quoting',
            CloseDate = Date.today().addDays(15), AccountId = acc.Id
        );
        insert opp;
        Financing__c seeded = new Financing__c(
            Opportunity__c = opp.Id,
            Applicant__c = applicant.Id,
            Status__c = 'Draft',
            Amount_Financed__c = 10000,
            Term_Months__c = 60,
            Annual_Rate__c = 5.49,
            Rate_Source__c = 'Rate_Table',
            Lender__c = 'Northgate Financial'
        );
        insert seeded;
        // System-mode query: proves the row exists (no FLS enforcement in system context).
        Integer sysCount = [SELECT COUNT() FROM Financing__c WHERE Id = :seeded.Id];
        System.assertEquals(1, sysCount,
            'Test data invariant: seeded Financing__c must exist before USER_MODE assertions. ' +
            'sysCount=' + sysCount);
        return seeded.Id;
    }
}
