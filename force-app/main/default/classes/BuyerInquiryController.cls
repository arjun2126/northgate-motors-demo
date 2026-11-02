/**
 * Buyer website inquiry intake. Creates a standard Lead through the existing sales workflow.
 * Public guest endpoint: the fixed, validated field set is inserted in system mode so the site
 * guest needs no native Lead/object permission and no native record is readable. No custom
 * pricing, no record outside Lead, no email send.
 */
public without sharing class BuyerInquiryController {
    private static final Set<String> REQUEST_TYPES = new Set<String>{'Test Drive', 'Purchase Inquiry'};
    private static final Set<String> CLOSED_STATUSES = new Set<String>{'Sold', 'Delivered', 'In_Appraisal', 'On_Hold'};
    private static final Set<String> PUBLIC_STATUSES = new Set<String>{'Available', 'In_Transit', 'Reserved'};
    private static final String EMAIL_PATTERN = '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$';

    @AuraEnabled
    public static String submit(String name, String email, String phone, String message,
            Id vehicleId, String requestType) {
        String cleanedName = clean(name);
        String cleanedEmail = clean(email);
        String cleanedPhone = clean(phone);
        String cleanedMessage = clean(message);
        String cleanedType = clean(requestType);
        if (String.isBlank(cleanedName) || cleanedName.length() > 80) {
            throw new AuraHandledException('Enter your name (80 characters or fewer).');
        }
        if (String.isBlank(cleanedEmail) || cleanedEmail.length() > 120 || !Pattern.matches(EMAIL_PATTERN, cleanedEmail)) {
            throw new AuraHandledException('Enter a valid email address.');
        }
        // Existing demo validation rule: Lead email must be a .test or .example domain.
        String lowerEmail = cleanedEmail.toLowerCase();
        if (!lowerEmail.endsWith('.test') && !lowerEmail.endsWith('.example')) {
            throw new AuraHandledException('This demo accepts addresses ending in .test or .example (for example buyer@northgate.test).');
        }
        if (String.isNotBlank(cleanedPhone) && cleanedPhone.length() > 40) {
            throw new AuraHandledException('Enter a shorter phone number.');
        }
        if (cleanedMessage.length() > 1200) {
            throw new AuraHandledException('Keep your message to 1200 characters or fewer.');
        }
        if (!REQUEST_TYPES.contains(cleanedType)) {
            throw new AuraHandledException('Choose a test drive or purchase inquiry.');
        }
        Vehicle__c vehicle;
        if (vehicleId != null) {
            if (vehicleId.getSObjectType() != Vehicle__c.SObjectType) {
                throw new AuraHandledException('Choose a valid vehicle.');
            }
            List<Vehicle__c> vehicles = [SELECT Id, Name, Status__c, Colour__c, Year__c,
                    Vehicle_Model__r.Make__c, Vehicle_Model__r.Model__c, Vehicle_Model__r.Trim__c
                FROM Vehicle__c WHERE Id = :vehicleId AND Status__c IN :PUBLIC_STATUSES WITH SYSTEM_MODE LIMIT 1];
            if (vehicles.isEmpty()) throw new AuraHandledException('That vehicle is no longer listed.');
            vehicle = vehicles[0];
            if (CLOSED_STATUSES.contains(vehicle.Status__c)) {
                throw new AuraHandledException('That vehicle is no longer available for this request.');
            }
            if (cleanedType == 'Test Drive' && vehicle.Status__c != 'Available') {
                throw new AuraHandledException('Test drives are available only for currently available vehicles.');
            }
        } else if (cleanedType == 'Test Drive') {
            throw new AuraHandledException('Choose a vehicle for your test drive.');
        }
        String interest = vehicle == null ? 'General inquiry'
            : vehicle.Name + ' - ' + vehicle.Year__c + ' ' + vehicle.Vehicle_Model__r.Make__c + ' '
              + vehicle.Vehicle_Model__r.Model__c + ' ' + vehicle.Vehicle_Model__r.Trim__c
              + (String.isBlank(vehicle.Colour__c) ? '' : ' (' + vehicle.Colour__c + ')');
        String description = 'Northgate website ' + cleanedType + ' request.\nInterest: ' + interest
            + (String.isBlank(cleanedMessage) ? '' : '\nMessage: ' + cleanedMessage);
        Lead lead = new Lead(LastName = cleanedName, Company = 'Northgate Motors Website',
            Email = cleanedEmail, Phone = cleanedPhone, LeadSource = 'Web',
            Description = description.left(32000));
        // Guest users cannot query Group. The queue Id is deployment-scoped configuration, so the
        // fixed queue ownership is resolved from a custom label instead of a guest SOQL call.
        String queueId = Label.Buyer_Lead_Queue_Id;
        if (String.isBlank(queueId)) throw new AuraHandledException('Lead routing is unavailable. Please contact Northgate directly.');
        Id ownerId;
        try {
            ownerId = Id.valueOf(queueId);
        } catch (StringException error) {
            throw new AuraHandledException('Lead routing is unavailable. Please contact Northgate directly.');
        }
        if (ownerId.getSObjectType() != Group.SObjectType) {
            throw new AuraHandledException('Lead routing is unavailable. Please contact Northgate directly.');
        }
        lead.OwnerId = ownerId;
        try {
            Database.insert(lead, AccessLevel.SYSTEM_MODE);
        } catch (DmlException error) {
            throw new AuraHandledException('Your request could not be submitted. Check the details and try again.');
        }
        return 'NG-' + String.valueOf(lead.Id).right(6).toUpperCase();
    }

    private static String clean(String value) { return value == null ? '' : value.trim(); }
}
