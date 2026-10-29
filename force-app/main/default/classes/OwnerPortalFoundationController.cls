public with sharing class OwnerPortalFoundationController {
    private static final String DENIED = 'Portal access is unavailable for this identity or site.';

    public class CustomerContext {
        @AuraEnabled public Id contactId;
        @AuraEnabled public Id accountId;
    }

    @AuraEnabled
    public static CustomerContext getContext() {
        Boolean permitted = FeatureManagement.checkPermission('Access_Northgate_Owner_Portal');
        if (UserInfo.getUserType() != 'PowerCustomerSuccess' || !permitted) throw unavailable();
        String networkId = Network.getNetworkId();
        List<Network> sites = String.isBlank(networkId) ? new List<Network>() :
            [SELECT Name, UrlPathPrefix, Status FROM Network
             WHERE Id = :networkId WITH SYSTEM_MODE LIMIT 1];
        return contextForSite(networkId, sites);
    }

    // Only environmental facts are supplied here. Caller identity, permission and customer
    // reads remain real. No public/Aura entry point accepts a site or customer selector.
    @TestVisible private static CustomerContext contextForSite(String networkId, List<Network> sites) {
        Boolean permitted = FeatureManagement.checkPermission('Access_Northgate_Owner_Portal');
        if (UserInfo.getUserType() != 'PowerCustomerSuccess' || !permitted) throw unavailable();
        // Read only the caller's identity/licensing metadata, never another customer's data.
        User actor = [SELECT Id, IsActive, ContactId, Profile.UserLicense.Name
                      FROM User WHERE Id = :UserInfo.getUserId() WITH SYSTEM_MODE];
        if (!eligible(UserInfo.getUserType(), actor.Profile.UserLicense.Name,
                      actor.IsActive, actor.ContactId, permitted, networkId)) throw unavailable();
        if (sites == null || sites.size() != 1 || !allowedSite(sites[0].Name, sites[0].UrlPathPrefix, sites[0].Status)) throw unavailable();
        try {
            List<Contact> contacts = [SELECT Id, AccountId FROM Contact
                                      WHERE Id = :actor.ContactId WITH USER_MODE LIMIT 1];
            if (contacts.isEmpty() || contacts[0].AccountId == null) throw unavailable();
            List<Account> accounts = [SELECT Id FROM Account WHERE Id = :contacts[0].AccountId
                                      WITH USER_MODE LIMIT 1];
            if (accounts.isEmpty()) throw unavailable();
            CustomerContext result = new CustomerContext();
            result.contactId = contacts[0].Id;
            result.accountId = accounts[0].Id;
            return result;
        } catch (QueryException deniedRead) {
            throw unavailable();
        }
    }

    @TestVisible private static Boolean eligible(String userType, String licenseName, Boolean active,
                                                Id contactId, Boolean permitted, String networkId) {
        return userType == 'PowerCustomerSuccess' && licenseName == 'Customer Community Plus'
            && active == true && contactId != null && permitted == true && !String.isBlank(networkId);
    }

    @TestVisible private static Boolean allowedSite(String name, String path, String status) {
        return name == 'Northgate Owner Portal' && path == 'owners' && status == 'Live';
    }

    private static AuraHandledException unavailable() {
        AuraHandledException error = new AuraHandledException(DENIED);
        error.setMessage(DENIED);
        return error;
    }
}
