@isTest
private class OwnerPortalEmailCapabilityTest {
    @isTest static void currentBackendFlagsDoNotGrantTemplateOrOrgEmailWrites() {
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'NG_Owner_Portal_User'].Id;
        PermissionSet base = [SELECT PermissionsEmailAdministration, PermissionsEmailTemplateManagement,
                             PermissionsApiEnabled, PermissionsViewSetup, PermissionsCustomizeApplication
                             FROM PermissionSet WHERE ProfileId = :profileId];
        System.assertEquals(true, base.PermissionsEmailAdministration, 'Probe observes the current deployed profile, not the candidate deny');
        System.assertEquals(true, base.PermissionsEmailTemplateManagement);
        System.assertEquals(false, base.PermissionsApiEnabled);
        System.assertEquals(false, base.PermissionsViewSetup);
        System.assertEquals(false, base.PermissionsCustomizeApplication);
        UserRole role = new UserRole(Name = 'P8 email capability fixture'); insert role;
        String token = EncodingUtil.convertToHex(Crypto.generateAesKey(128));
        User owner = new User(ProfileId = UserInfo.getProfileId(), UserRoleId = role.Id,
            Username = 'p8email.owner.' + token + '@example.invalid', Email = 'p8email@example.invalid',
            Alias = 'p8email', LastName = 'P8 Email Owner', TimeZoneSidKey = 'America/Toronto',
            LocaleSidKey = 'en_CA', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US');
        insert owner;
        User customer;
        System.runAs(owner) {
            Account account = new Account(Name = 'P8 email test only', OwnerId = owner.Id); insert account;
            Contact contact = new Contact(LastName = 'P8 Email Customer', AccountId = account.Id); insert contact;
            customer = new User(ProfileId = profileId, ContactId = contact.Id,
                Username = 'p8email.customer.' + token + '@example.invalid', Email = 'p8email@example.invalid',
                CommunityNickname = 'p8email' + token, Alias = 'p8ecust', LastName = 'P8 Email Customer',
                TimeZoneSidKey = 'America/Toronto', LocaleSidKey = 'en_CA', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US');
            insert customer;
        }
        // No additional permission set or membership, no messages sent, all rows roll back.
        System.runAs(customer) {
            System.assertEquals('PowerCustomerSuccess', UserInfo.getUserType());
            System.assertEquals(false, Schema.sObjectType.EmailTemplate.isCreateable());
            System.assertEquals(false, Schema.sObjectType.EmailTemplate.isUpdateable());
            System.assertEquals(false, Schema.sObjectType.OrgWideEmailAddress.isCreateable());
            System.assertEquals(false, Schema.sObjectType.OrgWideEmailAddress.isUpdateable());
        }
    }
}
