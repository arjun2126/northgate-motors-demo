@isTest
private class TradeIn_Calc_EquityTest {
    @isTest
    static void equityPositive() {
        Decimal eq = TradeIn_Calc_Equity.computeEquity(25000, 15000);
        System.assertEquals(10000, eq);
    }

    @isTest
    static void equityNegative() {
        Decimal eq = TradeIn_Calc_Equity.computeEquity(15000, 25000);
        System.assertEquals(-10000, eq);
    }

    @isTest
    static void equityZeroPayoff() {
        Decimal eq = TradeIn_Calc_Equity.computeEquity(25000, 0);
        System.assertEquals(25000, eq);
    }

    @isTest
    static void equityNulls() {
        Decimal eq = TradeIn_Calc_Equity.computeEquity(null, null);
        System.assertEquals(0, eq);
    }
}