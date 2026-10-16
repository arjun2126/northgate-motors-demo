@isTest
private class RateTableServiceTest {
    private static Map<String, Decimal> expectedRates() {
        Map<String, Decimal> rates = new Map<String, Decimal>{
            'A_36' => 4.49, 'A_48' => 4.99, 'A_60' => 5.49, 'A_72' => 5.99, 'A_84' => 6.49, 'A_96' => 6.99,
            'B_36' => 6.49, 'B_48' => 6.99, 'B_60' => 7.49, 'B_72' => 7.99, 'B_84' => 8.49, 'B_96' => 8.99,
            'C_36' => 8.99, 'C_48' => 9.49, 'C_60' => 9.99, 'C_72' => 10.49, 'C_84' => 10.99, 'C_96' => 11.49,
            'D_36' => 12.49, 'D_48' => 12.99, 'D_60' => 13.49, 'D_72' => 13.99, 'D_84' => 14.49, 'D_96' => 14.99,
            'Sub_Prime_36' => 16.49, 'Sub_Prime_48' => 16.99, 'Sub_Prime_60' => 17.49,
            'Sub_Prime_72' => 17.99, 'Sub_Prime_84' => 18.49, 'Sub_Prime_96' => 18.99
        };
        return rates;
    }

    @isTest
    static void allThirtyCombinations_resolveExactRates() {
        Map<String, Decimal> expected = expectedRates();
        System.assertEquals(30, expected.size(), 'all approved combinations covered');
        List<String> tiers = new List<String>{ 'A', 'B', 'C', 'D', 'Sub_Prime' };
        List<Integer> terms = new List<Integer>{ 36, 48, 60, 72, 84, 96 };
        for (String tier : tiers) {
            for (Integer term : terms) {
                RateTableService.RateResolution resolution =
                    RateTableService.resolve(tier, term);
                System.assertEquals(
                    expected.get(tier + '_' + term), resolution.baseRate,
                    'rate for ' + tier + ' x ' + term
                );
                System.assertEquals(tier, resolution.tier, 'tier echoed');
                System.assertEquals(term, resolution.termMonths, 'term echoed');
            }
        }
    }

    @isTest
    static void inactiveRow_isIgnored() {
        // A_36_INACTIVE carries a decoy 0.01 rate with Is_Active__c = false.
        RateTableService.RateResolution resolution = RateTableService.resolve('A', 36);
        System.assertEquals(4.49, resolution.baseRate, 'inactive row must not win');
        System.assertEquals(125.00, resolution.maxLtv, 'active row LTV mapping');
    }

    @isTest
    static void missingCombination_throws() {
        try {
            RateTableService.resolve('Z', 60);
            System.assert(false, 'unknown tier must throw');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Credit tier'), e.getMessage());
        }
        try {
            RateTableService.resolve('A', 24);
            System.assert(false, 'unsupported term must throw');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Term'), e.getMessage());
        }
        try {
            RateTableService.resolve(null, null);
            System.assert(false, 'null inputs must throw');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'null rejected');
        }
    }

    @isTest
    static void ltvLimit_enforcedAtBoundary() {
        RateTableService.RateResolution atLimit = RateTableService.resolve('A', 36, 125);
        System.assertEquals(4.49, atLimit.baseRate, 'LTV exactly at limit passes');
        try {
            RateTableService.resolve('A', 36, 125.01);
            System.assert(false, 'LTV above limit must throw');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('exceeds'), e.getMessage());
        }
        try {
            RateTableService.resolve('A', 36, null);
            System.assert(false, 'null LTV must throw');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('LTV'), e.getMessage());
        }
        try {
            RateTableService.resolve('A', 36, -5);
            System.assert(false, 'negative LTV must throw');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('negative'), e.getMessage());
        }
    }

    @isTest
    static void manualException_validatesRateAndReason() {
        System.assertEquals(
            6.49, RateTableService.manualRate(6.49, 'Loyalty pricing approved by manager.'),
            'valid manual rate passes through unchanged'
        );
        try {
            RateTableService.manualRate(6.49, '   ');
            System.assert(false, 'blank reason must throw');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('reason'), e.getMessage());
        }
        try {
            RateTableService.manualRate(null, 'Has reason.');
            System.assert(false, 'null rate must throw');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('between'), e.getMessage());
        }
        try {
            RateTableService.manualRate(26, 'Has reason.');
            System.assert(false, 'rate above 25 must throw');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('between'), e.getMessage());
        }
        try {
            RateTableService.manualRate(-1, 'Has reason.');
            System.assert(false, 'negative rate must throw');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('between'), e.getMessage());
        }
    }
}
