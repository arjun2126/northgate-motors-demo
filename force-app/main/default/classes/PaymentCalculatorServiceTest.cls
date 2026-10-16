@isTest
private class PaymentCalculatorServiceTest {
    @isTest
    static void zeroPercent_dividesPrincipalEvenly() {
        System.assertEquals(
            500.00,
            PaymentCalculatorService.monthlyPayment(30000, 0, 60),
            '0% over 60 months is principal / term'
        );
        System.assertEquals(
            0.00,
            PaymentCalculatorService.totalInterest(30000, 0, 60),
            '0% accrues no interest'
        );
    }

    @isTest
    static void standardRate_matchesAmortizationSchedule() {
        // Independently verified: 30000 @ 6.49% x 60.
        System.assertEquals(
            586.84,
            PaymentCalculatorService.monthlyPayment(30000, 6.49, 60),
            'standard-rate monthly payment to the cent'
        );
        System.assertEquals(
            5210.40,
            PaymentCalculatorService.totalInterest(30000, 6.49, 60),
            'standard-rate total interest to the cent'
        );
    }

    @isTest
    static void highRate_matchesAmortizationSchedule() {
        // Independently verified: 15000 @ 18.99% x 36.
        System.assertEquals(
            549.76,
            PaymentCalculatorService.monthlyPayment(15000, 18.99, 36),
            'high-rate monthly payment to the cent'
        );
        System.assertEquals(
            4791.36,
            PaymentCalculatorService.totalInterest(15000, 18.99, 36),
            'high-rate total interest to the cent'
        );
    }

    @isTest
    static void midRate_matchesAmortizationSchedule() {
        // Independently verified: 25000 @ 3.9% x 48.
        System.assertEquals(
            563.36,
            PaymentCalculatorService.monthlyPayment(25000, 3.9, 48),
            'mid-rate monthly payment to the cent'
        );
        System.assertEquals(
            2041.28,
            PaymentCalculatorService.totalInterest(25000, 3.9, 48),
            'mid-rate total interest to the cent'
        );
    }

    @isTest
    static void invalidInputs_throwInsteadOfZeroPayment() {
        try {
            PaymentCalculatorService.monthlyPayment(null, 5, 60);
            System.assert(false, 'null principal must throw');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Principal'), e.getMessage());
        }
        try {
            PaymentCalculatorService.monthlyPayment(30000, null, 60);
            System.assert(false, 'null rate must throw');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('rate'), e.getMessage());
        }
        try {
            PaymentCalculatorService.monthlyPayment(30000, 5, null);
            System.assert(false, 'null term must throw');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Term'), e.getMessage());
        }
        try {
            PaymentCalculatorService.monthlyPayment(30000, 5, 0);
            System.assert(false, 'zero term must throw');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Term'), e.getMessage());
        }
        try {
            PaymentCalculatorService.monthlyPayment(-1000, 5, 60);
            System.assert(false, 'negative principal must throw');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Principal'), e.getMessage());
        }
        try {
            PaymentCalculatorService.monthlyPayment(30000, -1, 60);
            System.assert(false, 'negative rate must throw');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('rate'), e.getMessage());
        }
    }
}
