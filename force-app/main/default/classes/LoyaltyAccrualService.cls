public without sharing class LoyaltyAccrualService {
    public class Source {
        public Id contactId;
        public Id visitId;
        public Id opportunityId;
        public Decimal spend;
        public String identity;
    }
    public static Integer process(String kind, Set<Id> ids) { return LoyaltyLedgerService.accrue(kind, ids); }
    public static List<Source> resolve(String kind, Set<Id> ids, LoyaltyLedgerService.Rules rules, Boolean locking) {
        Datetime boundary = rules.program.Eligible_From__c;
        List<Source> result = new List<Source>();
        if (kind == 'Service') {
            String query = 'SELECT Id, Contact__c, Total_Cost__c FROM Service_Visit__c WHERE Id IN :ids'
                + ' AND CreatedDate >= :boundary AND Status__c = \'Completed\''
                + ' AND (Service_Type__c = null OR Service_Type__c NOT IN (\'Recall\',\'Warranty_Repair\'))';
            if (locking) query += ' FOR UPDATE';
            for (Service_Visit__c visit : (List<Service_Visit__c>) Database.query(query)) {
                Source item = new Source();
                item.contactId = visit.Contact__c; item.visitId = visit.Id;
                item.spend = visit.Total_Cost__c; item.identity = 'Service:' + visit.Id;
                result.add(item);
            }
        } else if (kind == 'Sale') {
            String query = 'SELECT Id, Buyer__c, Opportunity__c FROM Delivery__c WHERE Id IN :ids'
                + ' AND CreatedDate >= :boundary AND Status__c = \'Completed\' AND Buyer__c != null';
            if (locking) query += ' FOR UPDATE';
            Map<Id, Id> buyerByOpportunity = new Map<Id, Id>();
            for (Delivery__c delivery : (List<Delivery__c>) Database.query(query)) {
                if (delivery.Opportunity__c != null) buyerByOpportunity.put(delivery.Opportunity__c, delivery.Buyer__c);
            }
            Set<Id> opportunityIds = buyerByOpportunity.keySet();
            for (Delivery__c delivery : [SELECT Opportunity__c, Buyer__c FROM Delivery__c
                WHERE Opportunity__c IN :opportunityIds AND Status__c = 'Completed' AND Buyer__c != null]) {
                if (buyerByOpportunity.get(delivery.Opportunity__c) != delivery.Buyer__c) {
                    throw new LoyaltyLedgerService.LoyaltyException('Sale has conflicting delivery buyers; manual review is required.');
                }
            }
            String opportunityQuery = 'SELECT Id, Amount FROM Opportunity WHERE Id IN :opportunityIds AND IsWon = true';
            if (locking) opportunityQuery += ' FOR UPDATE';
            for (Opportunity opportunity : (List<Opportunity>) Database.query(opportunityQuery)) {
                Source item = new Source(); item.contactId = buyerByOpportunity.get(opportunity.Id);
                item.opportunityId = opportunity.Id; item.spend = opportunity.Amount;
                item.identity = 'Sale:' + opportunity.Id; result.add(item);
            }
        } else { throw new LoyaltyLedgerService.LoyaltyException('Unsupported loyalty source type.'); }
        return result;
    }
}
