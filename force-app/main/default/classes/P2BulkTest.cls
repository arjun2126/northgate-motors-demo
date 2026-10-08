@isTest
private class P2BulkTest {
    @isTest
    static void twoHundredVehiclesInsertAndValidate() {
        Test.startTest();
        List<Vehicle__c> v = P2TestDataFactory.makeVehicleBulk(200);
        Test.stopTest();
        System.assertEquals(200, v.size());
        for (Vehicle__c row : v) {
            System.assertEquals('Available', row.Status__c);
            System.assertNotEquals(null, row.Id);
        }
    }

    @isTest
    static void contactsAndAccountsBulk() {
        Test.startTest();
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 50; i++) {
            accounts.add(new Account(Name = 'P2 Acct ' + i));
        }
        insert accounts;
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 50; i++) {
            contacts.add(new Contact(LastName = 'Contact ' + i, AccountId = accounts[i].Id));
        }
        insert contacts;
        Test.stopTest();
        System.assertEquals(50, [SELECT COUNT() FROM Account WHERE Name LIKE 'P2 Acct %']);
        System.assertEquals(50, [SELECT COUNT() FROM Contact WHERE LastName LIKE 'Contact %']);
    }
}
