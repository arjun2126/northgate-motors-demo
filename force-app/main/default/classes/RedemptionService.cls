public with sharing class RedemptionService {
    public class Result {
        @AuraEnabled public Decimal balance;
        @AuraEnabled public Decimal valueCad;
    }
    @AuraEnabled
    public static Result redeem(Id memberId, Decimal points, String requestToken) {
        if (!FeatureManagement.checkPermission('Redeem_Loyalty_Points')) {
            throw new AuraHandledException('Loyalty redemption permission is required.');
        }
        List<Loyalty_Member__c> visible = [SELECT Id, Points_Balance__c, Status__c FROM Loyalty_Member__c
            WHERE Id = :memberId WITH USER_MODE];
        if (visible.isEmpty()) throw new AuraHandledException('Membership is unavailable.');
        LoyaltyLedgerService.Rules rules = new LoyaltyLedgerService.Rules();
        Result result = new Result();
        result.balance = LoyaltyLedgerService.redeem(memberId, points, requestToken);
        result.valueCad = (points * rules.program.Redemption_Value__c).setScale(2);
        return result;
    }
}
