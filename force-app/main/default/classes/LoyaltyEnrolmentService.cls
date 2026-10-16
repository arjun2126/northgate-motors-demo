public without sharing class LoyaltyEnrolmentService {
    public static final String DEFAULT_TIER = 'Bronze';
    public static final String DEFAULT_STATUS = 'Active';

    public static Loyalty_Member__c enrolOnDelivery(Delivery__c delivery) {
        if (delivery == null || delivery.Buyer__c == null) {
            return null;
        }
        Id contactId = delivery.Buyer__c;
        List<Loyalty_Member__c> existing = [
            SELECT Id FROM Loyalty_Member__c WHERE Contact__c = :contactId WITH USER_MODE LIMIT 1
        ];
        if (!existing.isEmpty()) {
            return existing[0];
        }
        Loyalty_Member__c member = new Loyalty_Member__c(
            Contact__c = contactId,
            Status__c = DEFAULT_STATUS,
            Tier__c = DEFAULT_TIER,
            Points_Balance__c = 0,
            Lifetime_Points_Earned__c = 0,
            Lifetime_Points_Redeemed__c = 0,
            Join_Date__c = Date.today(),
            Last_Activity_Date__c = Date.today(),
            Member_Number__c = generateMemberNumber()
        );
        insert member;
        return member;
    }

    public static String generateMemberNumber() {
        Long now = DateTime.now().getTime();
        Long rand = Math.abs(Crypto.getRandomLong());
        Long body = Math.mod(now + rand, 100000000L);
        return 'NG-' + String.valueOf(Math.mod(body, 10000L).intValue()).leftPad(4, '0')
            + '-' + String.valueOf(Math.mod(body / 10000L, 10000L).intValue()).leftPad(4, '0');
    }
}
