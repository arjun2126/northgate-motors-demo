@isTest
public class P7Batch1TestData {
    public static User actor(String label, Boolean gallery, Boolean calculator, Boolean sales) {
        String profileName = sales ? 'NG_Sales' : 'NG_Service';
        User actor = new User(Alias = 'p7test', LastName = label, Username = 'p7.' + label.replace(' ', '.') + '.' + UserInfo.getOrganizationId() + '@northgate.example',
            Email = 'p7@northgate.example', ProfileId = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1].Id,
            TimeZoneSidKey = 'America/Toronto', LocaleSidKey = 'en_US', LanguageLocaleKey = 'en_US', EmailEncodingKey = 'UTF-8');
        insert as system actor;
        Set<String> names = new Set<String>();
        if (sales) names.add('PS_Sales_Rep');
        if (gallery) names.add('PS_Inventory_Gallery');
        if (calculator) names.add('PS_Opportunity_Calculator');
        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
        for (PermissionSet ps : [SELECT Id FROM PermissionSet WHERE Name IN :names]) assignments.add(new PermissionSetAssignment(AssigneeId = actor.Id, PermissionSetId = ps.Id));
        insert as system assignments; return actor;
    }
    public static Contact contact(Id ownerId, String label) {
        Account account = new Account(Name = 'P7 isolated ' + label); insert as system account;
        Contact contact = new Contact(LastName = label, AccountId = account.Id, OwnerId = ownerId); insert as system contact; return contact;
    }
    public static List<Vehicle__c> vehicles(Integer count) {
        Vehicle_Model__c model = new Vehicle_Model__c(Name = 'P7 isolated model', Make__c = 'Aurelia', Body_Style__c = 'Sedan', Image_Path__c = '/resource/NG_VehicleImages/aurelia_ex.webp');
        insert as system model;
        Rooftop__c roof = new Rooftop__c(Name = 'P7 isolated rooftop'); insert as system roof;
        List<Vehicle__c> rows = new List<Vehicle__c>();
        for (Integer i = 0; i < count; i++) rows.add(new Vehicle__c(Vehicle_Model__c = model.Id, Rooftop__c = roof.Id,
            VIN__c = String.valueOf(10000000000000000L + i), List_Price__c = 20000, Status__c = 'Available'));
        insert as system rows; return rows;
    }
}
