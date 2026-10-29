// Approved capability broker: no native customer Vehicle/ledger CRUD or Visit Create grant.
// No generic query/DML endpoint, client identity selector or sharing/grant writer.
public without sharing class OwnerPortalVehicleBroker {
    private static final String DENIED = 'Vehicle or appointment access is unavailable. Refresh and check eligibility.';
    private static final Set<String> CONSUMING = new Set<String>{'Requested','Scheduled','Checked_In','In_Progress'};
    public class VehicleDetail {
        @AuraEnabled public Id vehicleId;
        @AuraEnabled public String label;
        @AuraEnabled public String model;
        @AuraEnabled public Decimal year;
        @AuraEnabled public String colour;
        @AuraEnabled public String condition;
        @AuraEnabled public String photoUrl;
        @AuraEnabled public Boolean canRequestService;
    }
    public class VehiclePage {
        @AuraEnabled public List<VehicleDetail> rows = new List<VehicleDetail>();
        @AuraEnabled public Boolean hasMore = false;
        @AuraEnabled public Id beforeId;
        @AuraEnabled public String unavailableReason;
    }
    public class Choice {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        public Choice(String label, String value) { this.label = label; this.value = value; }
    }
    public class Options {
        @AuraEnabled public List<Choice> rooftops = new List<Choice>();
        @AuraEnabled public List<Choice> services = new List<Choice>();
    }
    public static VehiclePage vehicles(Id beforeId) {
        return vehiclesFor(OwnerPortalFoundationController.getContext().contactId, beforeId);
    }
    public static Options options(Id vehicleId) {
        return optionsFor(OwnerPortalFoundationController.getContext().contactId, vehicleId);
    }
    public static Id book(Id vehicleId, Id rooftopId, Datetime startsAt, String serviceType, String requestKey) {
        return bookFor(OwnerPortalFoundationController.getContext().contactId, vehicleId, rooftopId, startsAt, serviceType, requestKey);
    }
    private static Contact caller(Id contactId) {
        if (UserInfo.getUserType() != 'PowerCustomerSuccess' || !FeatureManagement.checkPermission('Access_Northgate_Owner_Portal')) throw denied();
        User actor = [SELECT ContactId, IsActive, Profile.UserLicense.Name FROM User WHERE Id = :UserInfo.getUserId() WITH SYSTEM_MODE];
        if (!actor.IsActive || actor.ContactId == null || actor.ContactId != contactId ||
            actor.Profile.UserLicense.Name != 'Customer Community Plus') throw denied();
        List<Contact> contacts = [SELECT Id, AccountId FROM Contact WHERE Id = :contactId WITH USER_MODE];
        if (contacts.size() != 1 || contacts[0].AccountId == null ||
            [SELECT Id FROM Account WHERE Id = :contacts[0].AccountId WITH USER_MODE].isEmpty()) throw denied();
        return contacts[0];
    }
    @TestVisible private static Boolean verified(Contact_Vehicle_Relationship__c row, Datetime instant) {
        return row.Status__c == 'Verified' && row.Verified_By__c != null && row.Verified_At__c != null &&
            row.Verified_At__c <= instant && !String.isBlank(row.Evidence_Reference__c) &&
            row.Effective_From__c != null && row.Effective_From__c <= instant &&
            (row.Effective_To__c == null || instant < row.Effective_To__c) &&
            (row.Revoked_At__c == null || instant < row.Revoked_At__c);
    }
    // Count all temporally current owners, including invalid evidence, not a caller-visible subset.
    @TestVisible private static Map<Id, Boolean> eligibility(Id contactId,
            List<Contact_Vehicle_Relationship__c> rows, Datetime instant) {
        Map<Id, List<Contact_Vehicle_Relationship__c>> owners = new Map<Id, List<Contact_Vehicle_Relationship__c>>();
        Map<Id, Integer> consents = new Map<Id, Integer>();
        for (Contact_Vehicle_Relationship__c row : rows) {
            if (row.Status__c != 'Verified' || row.Effective_From__c == null || row.Effective_From__c > instant ||
                (row.Effective_To__c != null && row.Effective_To__c <= instant) ||
                (row.Revoked_At__c != null && row.Revoked_At__c <= instant)) continue;
            if (row.Relationship_Type__c == 'Ownership') {
                if (!owners.containsKey(row.Vehicle__c)) owners.put(row.Vehicle__c, new List<Contact_Vehicle_Relationship__c>());
                owners.get(row.Vehicle__c).add(row);
            } else if (row.Relationship_Type__c == 'Service_Authorization' && row.Contact__c == contactId) {
                Integer count = consents.containsKey(row.Vehicle__c) ? consents.get(row.Vehicle__c) : 0;
                consents.put(row.Vehicle__c, !verified(row, instant) ||
                    !new Set<String>{'Reviewed_Service_Consent','Approved_Synthetic_Fixture'}.contains(row.Evidence_Type__c) ? 1000 : count + 1);
            }
        }
        Map<Id, Boolean> result = new Map<Id, Boolean>();
        for (Id vehicleId : owners.keySet()) {
            List<Contact_Vehicle_Relationship__c> candidates = owners.get(vehicleId);
            if (candidates.size() != 1) continue;
            Contact_Vehicle_Relationship__c row = candidates[0];
            if (row.Contact__c == contactId && verified(row, instant) &&
                new Set<String>{'Reviewed_Purchase','Reviewed_Transfer','Approved_Synthetic_Fixture'}.contains(row.Evidence_Type__c)) {
                result.put(vehicleId, consents.get(vehicleId) == 1);
            }
        }
        return result;
    }
    private static Map<Id, Boolean> current(Id contactId, Set<Id> vehicleIds) {
        return eligibility(contactId, [SELECT Id, Vehicle__c, Contact__c, Relationship_Type__c,
            Status__c, Effective_From__c, Effective_To__c, Revoked_At__c, Verified_By__c, Verified_At__c,
            Evidence_Type__c, Evidence_Reference__c FROM Contact_Vehicle_Relationship__c
            WHERE Vehicle__c IN :vehicleIds AND Status__c = 'Verified' WITH SYSTEM_MODE], Datetime.now());
    }
    @TestVisible private static VehiclePage vehiclesFor(Id contactId, Id beforeId) {
        caller(contactId);
        if (beforeId != null && beforeId.getSObjectType() != Vehicle__c.SObjectType) throw denied();
        Datetime instant = Datetime.now();
        List<Contact_Vehicle_Relationship__c> candidates = [SELECT Vehicle__c FROM Contact_Vehicle_Relationship__c
            WHERE Contact__c = :contactId AND Relationship_Type__c = 'Ownership' AND Status__c = 'Verified'
            AND Effective_From__c <= :instant AND (Effective_To__c = null OR Effective_To__c > :instant)
            AND (Revoked_At__c = null OR Revoked_At__c > :instant) WITH SYSTEM_MODE LIMIT 1001];
        if (candidates.size() > 1000) throw denied();
        Set<Id> ids = new Set<Id>();
        for (Contact_Vehicle_Relationship__c row : candidates) ids.add(row.Vehicle__c);
        Map<Id, Boolean> allowed = current(contactId, ids);
        Set<Id> approved = allowed.keySet();
        List<Vehicle__c> vehicles = beforeId == null ?
            [SELECT Id, Name, Year__c, Colour__c, Condition__c, Photo__c, Vehicle_Model__r.Name, Vehicle_Model__r.Image_Path__c
                FROM Vehicle__c WHERE Id IN :approved WITH SYSTEM_MODE ORDER BY Id DESC LIMIT 21] :
            [SELECT Id, Name, Year__c, Colour__c, Condition__c, Photo__c, Vehicle_Model__r.Name, Vehicle_Model__r.Image_Path__c
                FROM Vehicle__c WHERE Id IN :approved AND Id < :beforeId WITH SYSTEM_MODE ORDER BY Id DESC LIMIT 21];
        VehiclePage page = new VehiclePage(); page.hasMore = vehicles.size() > 20;
        if (page.hasMore) vehicles.remove(20);
        allowed = current(contactId, approved);
        for (Vehicle__c row : vehicles) {
            if (!allowed.containsKey(row.Id)) continue;
            VehicleDetail detail = new VehicleDetail(); detail.vehicleId = row.Id;
            detail.label = row.Name; detail.year = row.Year__c; detail.colour = row.Colour__c;
            detail.condition = row.Condition__c; detail.model = row.Vehicle_Model__r.Name;
            String path = row.Vehicle_Model__r.Image_Path__c;
            detail.photoUrl = !String.isBlank(row.Photo__c) && path != null &&
                Pattern.matches('/resource/NG_VehicleImages/[a-z0-9_]+\\.webp', path) ? path : null;
            detail.canRequestService = allowed.get(row.Id); page.rows.add(detail);
        }
        if (!vehicles.isEmpty()) page.beforeId = vehicles[vehicles.size()-1].Id;
        if (page.rows.isEmpty()) page.unavailableReason = 'No current verified owned vehicles are available. Reservations and Account membership do not establish ownership.';
        return page;
    }
    private static List<Rooftop__c> rooftops(Id rooftopId) {
        Set<String> types = new Set<String>{'Service_Center','Full_Service'};
        return rooftopId == null ? [SELECT Id, Name FROM Rooftop__c WHERE Is_Active__c = true
            AND Service_Capacity__c > 0 AND Type__c IN :types WITH SYSTEM_MODE ORDER BY Name, Id LIMIT 100] :
            [SELECT Id, Name FROM Rooftop__c WHERE Id = :rooftopId AND Is_Active__c = true
                AND Service_Capacity__c > 0 AND Type__c IN :types WITH SYSTEM_MODE LIMIT 1];
    }
    private static Map<String, String> serviceTypes() {
        Map<String, String> result = new Map<String, String>();
        for (Schema.PicklistEntry item : Service_Visit__c.Service_Type__c.getDescribe().getPicklistValues()) {
            if (item.isActive()) result.put(item.getValue(), item.getLabel());
        }
        return result;
    }
    @TestVisible private static Options optionsFor(Id contactId, Id vehicleId) {
        caller(contactId);
        if (vehicleId == null || vehicleId.getSObjectType() != Vehicle__c.SObjectType ||
            current(contactId, new Set<Id>{vehicleId}).get(vehicleId) != true) throw denied();
        Options result = new Options();
        for (Rooftop__c roof : rooftops(null)) result.rooftops.add(new Choice(roof.Name, String.valueOf(roof.Id)));
        Map<String, String> types = serviceTypes(); List<String> values = new List<String>(types.keySet()); values.sort();
        for (String value : values) result.services.add(new Choice(types.get(value), value));
        return result;
    }
    private static String digest(String value) { return EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(value))); }
    private static String fingerprint(Id vehicleId, Id roofId, Datetime start, String service) {
        return digest(String.valueOf(vehicleId) + '|' + String.valueOf(roofId) + '|' + start.getTime() + '|' + service);
    }
    private static Id replay(String key, String payload, Id contactId) {
        List<Service_Visit__c> prior = [SELECT Id, Contact__c, Vehicle__c, Rooftop__c, Scheduled_Start__c,
            Service_Type__c, Portal_Request_Fingerprint__c FROM Service_Visit__c WHERE Portal_Request_Key__c = :key WITH SYSTEM_MODE LIMIT 1];
        if (prior.isEmpty()) return null;
        Service_Visit__c row = prior[0];
        if (row.Contact__c != contactId || row.Portal_Request_Fingerprint__c != payload ||
            fingerprint(row.Vehicle__c, row.Rooftop__c, row.Scheduled_Start__c, row.Service_Type__c) != payload) throw denied();
        return row.Id;
    }
    @TestVisible private static Id bookFor(Id contactId, Id vehicleId, Id rooftopId, Datetime startsAt, String serviceType, String requestKey) {
        caller(contactId);
        if (vehicleId == null || rooftopId == null || startsAt == null || startsAt <= Datetime.now() ||
            vehicleId.getSObjectType() != Vehicle__c.SObjectType || rooftopId.getSObjectType() != Rooftop__c.SObjectType ||
            !serviceTypes().containsKey(serviceType) || requestKey == null || !Pattern.matches('[A-Za-z0-9_-]{16,64}', requestKey)) throw denied();
        // Persist/hash the same precision Salesforce returns from DateTime fields; Apex now()
        // and API inputs can carry subsecond values that must not break an identical retry.
        startsAt = Datetime.valueOfGmt(startsAt.formatGmt('yyyy-MM-dd HH:mm:ss'));
        if (startsAt <= Datetime.now()) throw denied();
        List<Vehicle__c> locked = [SELECT Id FROM Vehicle__c WHERE Id = :vehicleId WITH SYSTEM_MODE FOR UPDATE];
        if (locked.size() != 1 || current(contactId, new Set<Id>{vehicleId}).get(vehicleId) != true || rooftops(rooftopId).isEmpty()) throw denied();
        Automation_Settings__c settings = Automation_Settings__c.getOrgDefaults();
        if (settings != null && settings.Bypass_Triggers__c == true) throw denied();
        String key = digest(String.valueOf(contactId) + '|' + requestKey);
        String payload = fingerprint(vehicleId, rooftopId, startsAt, serviceType);
        Id prior = replay(key, payload, contactId); if (prior != null) return prior;
        if (![SELECT Id FROM Service_Visit__c WHERE Contact__c = :contactId AND Vehicle__c = :vehicleId
            AND Rooftop__c = :rooftopId AND Scheduled_Start__c = :startsAt AND Service_Type__c = :serviceType
            AND Status__c IN :CONSUMING WITH SYSTEM_MODE LIMIT 1].isEmpty()) throw denied();
        if (current(contactId, new Set<Id>{vehicleId}).get(vehicleId) != true) throw denied();
        Service_Visit__c row = new Service_Visit__c(Contact__c = contactId, Vehicle__c = vehicleId,
            Rooftop__c = rooftopId, Scheduled_Start__c = startsAt, Service_Type__c = serviceType,
            Status__c = 'Requested', OwnerId = UserInfo.getUserId(), Portal_Request_Key__c = key,
            Portal_Request_Fingerprint__c = payload);
        Savepoint boundary = Database.setSavepoint();
        try {
            insert as system row;
            if (current(contactId, new Set<Id>{vehicleId}).get(vehicleId) != true) throw denied();
            return row.Id;
        } catch (DmlException failure) {
            Database.rollback(boundary);
            if (failure.getNumDml() > 0 && failure.getDmlStatusCode(0) == 'DUPLICATE_VALUE' &&
                current(contactId, new Set<Id>{vehicleId}).get(vehicleId) == true) {
                Id concurrent = replay(key, payload, contactId); if (concurrent != null) return concurrent;
            }
            throw denied();
        } catch (AuraHandledException failure) { Database.rollback(boundary); throw failure; }
    }
    private static AuraHandledException denied() {
        AuraHandledException error = new AuraHandledException(DENIED); error.setMessage(DENIED); return error;
    }
}
