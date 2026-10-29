@isTest
public class LoyaltyBatch2TestData {
    private static Integer serial = 1;
    public static void configure() {
        LoyaltyLedgerService.programOverride = new Loyalty_Program__mdt(Is_Active__c = true,
            Eligible_From__c = Datetime.now().addDays(-1), Service_Points_Per_CAD__c = 1,
            Sale_Points_Per_CAD__c = 0.1, Redemption_Value__c = 0.01, Allow_Downgrades__c = false);
        LoyaltyLedgerService.tiersOverride = new List<Loyalty_Tier__mdt>{
            new Loyalty_Tier__mdt(Tier__c = 'Bronze', Is_Active__c = true, Threshold_Amount__c = 0, Accrual_Multiplier__c = 1, Expiry_Days__c = 365),
            new Loyalty_Tier__mdt(Tier__c = 'Silver', Is_Active__c = true, Threshold_Amount__c = 5000, Accrual_Multiplier__c = 1.25, Expiry_Days__c = 365),
            new Loyalty_Tier__mdt(Tier__c = 'Gold', Is_Active__c = true, Threshold_Amount__c = 25000, Accrual_Multiplier__c = 1.5, Expiry_Days__c = 540),
            new Loyalty_Tier__mdt(Tier__c = 'Platinum', Is_Active__c = true, Threshold_Amount__c = 50000, Accrual_Multiplier__c = 2, Expiry_Days__c = 730)
        };
        LoyaltyLedgerService.dateOverride = Date.newInstance(2026, 11, 28);
    }
    public static Loyalty_Member__c member(String tier, Decimal openingBalance) {
        Account account = new Account(Name = 'Batch 2 isolated account ' + serial++); insert account;
        Contact contact = new Contact(LastName = 'Batch 2 isolated driver', AccountId = account.Id); insert contact;
        Loyalty_Member__c member = new Loyalty_Member__c(Contact__c = contact.Id, Tier__c = tier,
            Status__c = 'Active', Points_Balance__c = openingBalance, Lifetime_Spend__c = 0,
            Lifetime_Points_Earned__c = 0, Lifetime_Points_Redeemed__c = 0,
            Member_Number__c = 'B2-' + String.valueOf(serial++).leftPad(8, '0'));
        insert member; return member;
    }
    public static List<Service_Visit__c> sources(Loyalty_Member__c member, Integer count, Decimal spend) {
        Vehicle_Model__c model = new Vehicle_Model__c(Name = 'Batch 2 isolated model'); insert model;
        Vehicle__c vehicle = new Vehicle__c(Vehicle_Model__c = model.Id,
            VIN__c = String.valueOf(70000000000000000L + serial++)); insert vehicle;
        List<Service_Visit__c> visits = new List<Service_Visit__c>();
        for (Integer index = 0; index < count; index++) visits.add(new Service_Visit__c(
            Contact__c = member.Contact__c, Vehicle__c = vehicle.Id, Status__c = 'Completed',
            Scheduled_Start__c = Datetime.now().addDays(2).addMinutes(index), Service_Type__c = 'Inspection',
            Parts_Cost__c = spend, Labour_Cost__c = 0, Mileage_At_Checkin__c = index * 100));
        insert visits; return visits;
    }
    public static Set<Id> ids(List<Service_Visit__c> visits) { return new Map<Id, Service_Visit__c>(visits).keySet(); }
    public static Loyalty_Member__c stored(Id id) {
        return [SELECT Id, Contact__c, Points_Balance__c, Lifetime_Spend__c, Lifetime_Points_Earned__c,
            Lifetime_Points_Redeemed__c, Tier__c, Previous_Tier__c, Tier_Changed_On__c, Next_Tier_Threshold__c,
            Tier_Evaluated_On__c, Managed_From__c, Last_Activity_Date__c FROM Loyalty_Member__c WHERE Id = :id WITH SYSTEM_MODE];
    }
    public static User user(String roleName, List<String> permissionNames) {
        User actor = new User(Alias = 'b2test', LastName = 'Batch2 ' + roleName,
            Username = 'b2.' + roleName + '.' + UserInfo.getOrganizationId() + '@northgate.example',
            Email = 'b2.' + roleName + '@northgate.example', ProfileId = [SELECT Id FROM Profile WHERE Name = 'NG_Service' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles', LocaleSidKey = 'en_US', LanguageLocaleKey = 'en_US', EmailEncodingKey = 'UTF-8');
        insert actor;
        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
        for (PermissionSet permission : [SELECT Id FROM PermissionSet WHERE Name IN :permissionNames]) {
            assignments.add(new PermissionSetAssignment(AssigneeId = actor.Id, PermissionSetId = permission.Id));
        }
        insert assignments; return actor;
    }
}
