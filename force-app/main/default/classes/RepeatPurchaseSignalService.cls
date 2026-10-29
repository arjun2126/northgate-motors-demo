public with sharing class RepeatPurchaseSignalService {
    public static List<Contact> candidates() {
        return [SELECT Id, Name FROM Contact WHERE Id IN
            (SELECT Contact__c FROM Service_Visit__c WHERE Status__c = 'Completed')
            AND Id IN (SELECT Buyer_Contact__c FROM Quote WHERE Opportunity.IsClosed = false AND Buyer_Contact__c != null)
            WITH USER_MODE ORDER BY Id];
    }
}
