public with sharing class PaymentCalculatorService {
    private static final Integer INTERMEDIATE_SCALE = 28;

    public static Decimal monthlyPayment(Decimal principal, Decimal annualRatePercent, Integer termMonths) {
        if (principal == null) {
            throw new IllegalArgumentException('Principal amount is required.');
        }
        if (principal < 0) {
            throw new IllegalArgumentException('Principal amount cannot be negative.');
        }
        if (annualRatePercent == null) {
            throw new IllegalArgumentException('Annual rate is required.');
        }
        if (annualRatePercent < 0) {
            throw new IllegalArgumentException('Annual rate cannot be negative.');
        }
        if (termMonths == null || termMonths <= 0) {
            throw new IllegalArgumentException('Term must be a positive number of months.');
        }
        if (annualRatePercent == 0) {
            return principal.divide(termMonths, INTERMEDIATE_SCALE, System.RoundingMode.HALF_UP).setScale(2, System.RoundingMode.HALF_UP);
        }
        Decimal monthlyRate = annualRatePercent.divide(1200, INTERMEDIATE_SCALE, System.RoundingMode.HALF_UP);
        Decimal factor = 1;
        Decimal growth = 1 + monthlyRate;
        for (Integer i = 0; i < termMonths; i++) {
            factor = factor * growth;
        }
        Decimal numerator = principal * monthlyRate * factor;
        return numerator.divide(factor - 1, INTERMEDIATE_SCALE, System.RoundingMode.HALF_UP)
            .setScale(2, System.RoundingMode.HALF_UP);
    }

    public static Decimal totalInterest(Decimal principal, Decimal annualRatePercent, Integer termMonths) {
        Decimal monthly = monthlyPayment(principal, annualRatePercent, termMonths);
        return (monthly * termMonths - principal).setScale(2, System.RoundingMode.HALF_UP);
    }
}
