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
    @isTest static void triggerSetsIsVinValid() {
        Vehicle_Model__c vm = new Vehicle_Model__c(Name = 'Test Model');
        insert vm;
        Vehicle__c v = new Vehicle__c(VIN__c = '4NDM4NJ96V8L0KGCJ', Vehicle_Model__c = vm.Id);
        insert v;
        v = [SELECT Is_VIN_Valid__c FROM Vehicle__c WHERE Id = :v.Id];
        System.assertEquals(true, v.Is_VIN_Valid__c, 'Trigger should set Is_VIN_Valid__c for valid VIN');
    }
}
