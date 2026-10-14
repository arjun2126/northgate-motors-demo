public with sharing class QuoteSummaryController {
    public class LineDto {
        @AuraEnabled public String name;
        @AuraEnabled public String category;
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public Decimal unitPrice;
        @AuraEnabled public Decimal subtotal;
    }

    public class SummaryDto {
        @AuraEnabled public Id quoteId;
        @AuraEnabled public String quoteName;
        @AuraEnabled public String opportunityName;
        @AuraEnabled public Decimal listSubtotal;
        @AuraEnabled public Decimal adjustedSubtotal;
        @AuraEnabled public Decimal discountPercent;
        @AuraEnabled public Integer rulesApplied;
        @AuraEnabled public String approvalStatus;
        @AuraEnabled public Date validUntil;
        @AuraEnabled public Decimal grandTotal;
        @AuraEnabled public List<LineDto> lines;
    }

    @AuraEnabled(cacheable=true)
    public static SummaryDto getSummary(Id quoteId) {
        Quote quote = [
            SELECT Id, Name, Opportunity.Name, OpportunityId, Adjusted_Subtotal__c, Rule_Applied_Count__c,
                Quote_Valid_Until__c, GrandTotal
            FROM Quote
            WHERE Id = :quoteId
        ];

        List<LineDto> lines = new List<LineDto>();
        for (QuoteLineItem line : [
            SELECT Product2.Name, Product2.Category__c, Quantity, UnitPrice
            FROM QuoteLineItem
            WHERE QuoteId = :quoteId
            ORDER BY Product2.Name
        ]) {
            LineDto dto = new LineDto();
            dto.name = line.Product2.Name;
            dto.category = line.Product2.Category__c;
            dto.quantity = line.Quantity;
            dto.unitPrice = line.UnitPrice;
            dto.subtotal = (line.UnitPrice == null ? 0 : line.UnitPrice) * (line.Quantity == null ? 0 : line.Quantity);
            lines.add(dto);
        }

        SummaryDto summary = new SummaryDto();
        summary.quoteId = quote.Id;
        summary.quoteName = quote.Name;
        summary.opportunityName = quote.Opportunity.Name;
        summary.adjustedSubtotal = quote.Adjusted_Subtotal__c;
        summary.rulesApplied = Integer.valueOf(quote.Rule_Applied_Count__c);
        summary.validUntil = quote.Quote_Valid_Until__c;
        summary.grandTotal = quote.GrandTotal;
        summary.lines = lines;

        Decimal listTotal = 0;
        for (LineDto line : lines) {
            listTotal += line.subtotal;
        }
        summary.listSubtotal = listTotal.setScale(2);

        Opportunity opp = [SELECT Discount_Percent__c, Approval_Status__c FROM Opportunity WHERE Id = :quote.OpportunityId];
        summary.discountPercent = opp.Discount_Percent__c;
        summary.approvalStatus = opp.Approval_Status__c;

        return summary;
    }
}