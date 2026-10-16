@isTest
private class LoyaltyEnrolmentServiceTest {
    private static final String FINANCE_OFFICER_USERNAME =
        'ngfinofficer.' + UserInfo.getOrganizationId() + '@ngtest.northgate.invalid';

    @TestSetup
    static void setup() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Profile financeProfile = [SELECT Id FROM Profile WHERE Id = :UserInfo.getProfileId()];
            User officer = new User(
                Alias = 'loyofc',
                Email = FINANCE_OFFICER_USERNAME,
                EmailEncodingKey = 'UTF-8',
                FirstName = 'Loyalty',
                LastName = 'Officer',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = financeProfile.Id,
                TimeZoneSidKey = 'America/New_York',
                UserName = FINANCE_OFFICER_USERNAME
            );
            insert officer;
            List<PermissionSet> ps = [
                SELECT Id FROM PermissionSet WHERE Name = 'PS_Finance_Officer'
            ];
            System.assert(ps.size() == 1, 'PS_Finance_Officer must exist');
            insert new PermissionSetAssignment(
                AssigneeId = officer.Id, PermissionSetId = ps[0].Id
            );
        }
    }

    private static User financeUser() {
        return [SELECT Id FROM User WHERE Username = :FINANCE_OFFICER_USERNAME LIMIT 1];
    }

    @isTest
    static void enrolOnDelivery_createsMemberWithDefaults() {
        Account acc = P2TestDataFactory.makeAccount('LoyAcc1');
        Contact buyer = P2TestDataFactory.makeContact(acc.Id, 'LoyContact1');
        Opportunity opp = new Opportunity(
            Name = 'LoyOpp1', StageName = 'Closed Won',
            CloseDate = Date.today().addDays(-1), AccountId = acc.Id,
            Delivery_Completed__c = true
        );
        insert opp;
        Vehicle_Model__c model = new Vehicle_Model__c(Name = 'LoyModel'+Math.rint(Math.random()*1000));
        insert model;
        Vehicle__c v = new Vehicle__c(Vehicle_Model__c = model.Id, VIN__c = 'ABCDEFGH123456789', Status__c = 'Available', Acquisition_Date__c = Date.today().addDays(-30));
        insert v;
        Delivery__c d = new Delivery__c(
            Opportunity__c = opp.Id, Buyer__c = buyer.Id, Vehicle__c = v.Id,
            Status__c = 'Completed',
            Checklist_Documents__c = true, Checklist_Inspection__c = true,
            Checklist_Walkthrough__c = true, Checklist_Signature__c = true
        );
        insert d;
        System.runAs(financeUser()) {
            Loyalty_Member__c member = LoyaltyEnrolmentService.enrolOnDelivery(d);
            System.assertNotEquals(null, member, 'member returned');
            Loyalty_Member__c fetched = [
                SELECT Contact__c, Status__c, Tier__c, Points_Balance__c, Join_Date__c, Member_Number__c
                FROM Loyalty_Member__c WHERE Id = :member.Id
            ];
            System.assertEquals(buyer.Id, fetched.Contact__c, 'member linked to buyer');
            System.assertEquals('Active', fetched.Status__c, 'member is Active');
            System.assertEquals('Bronze', fetched.Tier__c, 'Bronze default');
            System.assertEquals(0, fetched.Points_Balance__c, 'zero balance');
            System.assertEquals(Date.today(), fetched.Join_Date__c, 'Join_Date today');
            System.assert(String.isNotBlank(fetched.Member_Number__c), 'member number assigned');
        }
    }

    @isTest
    static void enrolOnDelivery_isIdempotent_secondCallReturnsExisting() {
        Account acc = P2TestDataFactory.makeAccount('LoyAcc2');
        Contact buyer = P2TestDataFactory.makeContact(acc.Id, 'LoyContact2');
        Opportunity opp = new Opportunity(
            Name = 'LoyOpp2', StageName = 'Closed Won',
            CloseDate = Date.today().addDays(-1), AccountId = acc.Id,
            Delivery_Completed__c = true
        );
        insert opp;
        Vehicle_Model__c model = new Vehicle_Model__c(Name = 'LoyModel'+Math.rint(Math.random()*1000));
        insert model;
        Vehicle__c v = new Vehicle__c(Vehicle_Model__c = model.Id, VIN__c = 'ABCDEFGH123456788', Status__c = 'Available', Acquisition_Date__c = Date.today().addDays(-30));
        insert v;
        Delivery__c d = new Delivery__c(
            Opportunity__c = opp.Id, Buyer__c = buyer.Id, Vehicle__c = v.Id,
            Status__c = 'Completed',
            Checklist_Documents__c = true, Checklist_Inspection__c = true,
            Checklist_Walkthrough__c = true, Checklist_Signature__c = true
        );
        insert d;
        System.runAs(financeUser()) {
            Loyalty_Member__c first = LoyaltyEnrolmentService.enrolOnDelivery(d);
            Loyalty_Member__c second = LoyaltyEnrolmentService.enrolOnDelivery(d);
            System.assertEquals(first.Id, second.Id, 'second call returns same member');
            Integer countMembers = [SELECT COUNT() FROM Loyalty_Member__c WHERE Contact__c = :buyer.Id];
            System.assertEquals(1, countMembers, 'exactly one member exists');
        }
    }

    @isTest
    static void enrolOnDelivery_nullBuyer_returnsNullAndDoesNotInsert() {
        Delivery__c d = new Delivery__c(
            Status__c = 'Completed',
            Checklist_Documents__c = true, Checklist_Inspection__c = true,
            Checklist_Walkthrough__c = true, Checklist_Signature__c = true
        );
        System.runAs(financeUser()) {
            Loyalty_Member__c result = LoyaltyEnrolmentService.enrolOnDelivery(d);
            System.assertEquals(null, result, 'no member returned without buyer');
        }
    }

    @isTest
    static void generateMemberNumber_producesNGPrefix() {
        String number1 = LoyaltyEnrolmentService.generateMemberNumber();
        String number2 = LoyaltyEnrolmentService.generateMemberNumber();
        System.assert(number1.startsWith('NG-'), 'NG- prefix: ' + number1);
        System.assertEquals('NG-', number1.substring(0, 3), 'first 3 chars NG-');
        System.assert(number1 != number2, 'random between calls: ' + number1 + ' vs ' + number2);
    }
}
