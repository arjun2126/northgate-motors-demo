@isTest
private class VinValidatorTest {
    @isTest static void validVinPasses() {
        System.assert(VinValidator.isValid('4NDM4NJ96V8L0KGCJ'), 'Known valid VIN should pass');
    }
    @isTest static void invalidCheckDigitFails() {
        System.assertEquals(false, VinValidator.isValid('4NDM4NJ97V8L0KGCJ'), 'Wrong check digit should fail');
    }
    @isTest static void invalidCharFails() {
        System.assertEquals(false, VinValidator.isValid('4NDM4NJ96V8L0KGCQ'), 'Invalid charset char Q should fail');
    }
    @isTest static void nullAndShortFail() {
        System.assertEquals(false, VinValidator.isValid(null));
        System.assertEquals(false, VinValidator.isValid('123'));
    }
}
