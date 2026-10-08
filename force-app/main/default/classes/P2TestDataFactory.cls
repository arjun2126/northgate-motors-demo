@isTest
public class P2TestDataFactory {
    public static Account makeAccount(String seed) {
        Account a = new Account(Name = 'P2 Account ' + seed);
        insert a;
        return a;
    }

    public static Contact makeContact(Id accountId, String lastName) {
        Contact c = new Contact(LastName = lastName, AccountId = accountId);
        insert c;
        return c;
    }

    public static Vehicle_Model__c makeModel(String seed) {
        Vehicle_Model__c m = new Vehicle_Model__c(Name = 'P2 Model ' + seed);
        insert m;
        return m;
    }

    public static Vehicle__c makeVehicle(Id modelId, String vin) {
        Vehicle__c v = new Vehicle__c(VIN__c = vin, Vehicle_Model__c = modelId, Status__c = 'Available');
        insert v;
        return v;
    }

    public static List<Vehicle__c> makeVehicleBulk(Integer count) {
        Vehicle_Model__c m = makeModel('Bulk' + count + 'TS');
        List<Vehicle__c> v = new List<Vehicle__c>();
        Long nowMs = Datetime.now().getTime();
        for (Integer i = 0; i < count; i++) {
            Long rawMs = (nowMs * 1000) + i;
            String tail = String.valueOf(rawMs);
            tail = tail.leftPad(15, '0').substring(Math.max(0, tail.length() - 15));
            String vin = ('B' + tail).rightPad(17, '0');
            v.add(new Vehicle__c(
                VIN__c = vin,
                Vehicle_Model__c = m.Id,
                Status__c = 'Available'
            ));
        }
        insert v;
        return v;
    }
}
