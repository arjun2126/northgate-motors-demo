@isTest
private class VehicleReservationGuardTest {
    private static Vehicle__c vehicle(String vin) {
        Vehicle_Model__c m = new Vehicle_Model__c(Name = 'P2 Reserve Model');
        insert m;
        Vehicle__c v = new Vehicle__c(VIN__c = vin, Vehicle_Model__c = m.Id, Status__c = 'Available');
        insert v;
        return v;
    }

    private static Contact contact(String lastName) {
        Account a = new Account(Name = 'P2 Reserve ' + lastName);
        insert a;
        Contact c = new Contact(LastName = lastName, AccountId = a.Id);
        insert c;
        return c;
    }

    @isTest
    static void reservingSetsStatusAndTimestamp() {
        Vehicle__c v = vehicle('TESTVNM0000000011');
        Contact c = contact('Reserve One');
        v.Reserved_By__c = c.Id;
        update v;
        v = [SELECT Status__c, Reserved_By__c, Reserved_On__c FROM Vehicle__c WHERE Id = :v.Id];
        System.assertEquals('Reserved', v.Status__c);
        System.assertEquals(c.Id, v.Reserved_By__c);
        System.assertNotEquals(null, v.Reserved_On__c);
    }

    @isTest
    static void secondReservationIsBlocked() {
        Vehicle__c v = vehicle('TESTVNM0000000022');
        Contact first = contact('Reserve Two');
        Contact second = contact('Reserve Three');
        v.Reserved_By__c = first.Id;
        update v;
        v.Reserved_By__c = second.Id;
        try {
            update v;
            System.assert(false, 'Second reservation should be blocked.');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('already reserved'), e.getMessage());
        }
    }
}
