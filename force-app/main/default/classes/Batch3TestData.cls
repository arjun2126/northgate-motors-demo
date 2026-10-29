@isTest
public class Batch3TestData {
    public static List<Contact> contacts(Integer count) {
        Account account = new Account(Name = 'Batch 3 isolated account'); insert account;
        List<Contact> rows = new List<Contact>();
        for (Integer i = 0; i < count; i++) rows.add(new Contact(LastName = 'Batch3 driver ' + i, AccountId = account.Id));
        insert rows; return rows;
    }
    public static Campaign campaign(Boolean managed) {
        Campaign row = new Campaign(Name = 'Batch3 isolated campaign', IsActive = true,
            Nurture_Managed__c = managed, Consent_Purpose__c = managed ? 'Marketing' : null,
            Consent_Channel__c = managed ? 'Email' : null); insert as system row; return row;
    }
    public static List<Consent__c> grants(List<Contact> contacts) {
        List<Consent__c> rows = new List<Consent__c>();
        for (Contact contact : contacts) rows.add(new Consent__c(Contact__c = contact.Id, Purpose__c = 'Marketing',
            Channel__c = 'Email', Status__c = 'Granted', Granted_On__c = ConsentGateService.today()));
        insert as system rows; return rows;
    }
    public static User actor(String name, List<String> permissionNames, Id roleId) {
        User actor = new User(Alias = 'b3test', LastName = name,
            Username = 'batch3.' + name.replace(' ', '.') + '.' + UserInfo.getOrganizationId() + '@northgate.example',
            Email = 'batch3@northgate.example', ProfileId = [SELECT Id FROM Profile WHERE Name = 'NG_Service' LIMIT 1].Id,
            UserRoleId = roleId, TimeZoneSidKey = 'America/Toronto', LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US', EmailEncodingKey = 'UTF-8'); insert actor;
        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
        for (PermissionSet permission : [SELECT Id FROM PermissionSet WHERE Name IN :permissionNames]) {
            assignments.add(new PermissionSetAssignment(AssigneeId = actor.Id, PermissionSetId = permission.Id));
        }
        insert assignments; return actor;
    }
}
