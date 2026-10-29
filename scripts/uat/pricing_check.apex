Map<String, Object> out = new Map<String, Object>();
List<Price_Rule__mdt> rules = [
    SELECT DeveloperName, Rule_Type__c, Attribute__c, Operator__c, Value__c,
        Percent_Adjustment__c, Fixed_Adjustment__c, Priority__c, Max_Applies__c,
        Is_Active__c, Target__c
    FROM Price_Rule__mdt
];
List<Quote> quotes = [
    SELECT Id, Name, OpportunityId,
        Opportunity.Vehicle__r.Vehicle_Model__r.Name,
        Opportunity.Vehicle__r.Vehicle_Model__r.Trim__c,
        Opportunity.Vehicle__r.Inventory_Age_Days__c,
        (SELECT Id, UnitPrice, Quantity, PricebookEntry.Product2.Name, PricebookEntry.Product2.Category__c FROM QuoteLineItems)
    FROM Quote
    WHERE Opportunity.Vehicle__c != null
    ORDER BY Name
    LIMIT 200
];
for (Quote q : quotes) {
    String model = q.Opportunity.Vehicle__r.Vehicle_Model__r.Name;
    if (model == null) continue;
    Integer matches = 0;
    String matchedName = null;
    for (QuoteLineItem l : q.QuoteLineItems) {
        if (l.PricebookEntry.Product2.Category__c == 'Vehicle_Trim' && l.PricebookEntry.Product2.Name == model) {
            matches++;
            matchedName = l.PricebookEntry.Product2.Name;
        }
    }
    if (matches != 1) continue;
    QuotePricingService.VehicleContext v = new QuotePricingService.VehicleContext();
    v.hasVehicle = true;
    v.modelName = model;
    v.trim = q.Opportunity.Vehicle__r.Vehicle_Model__r.Trim__c;
    v.ageDays = q.Opportunity.Vehicle__r.Inventory_Age_Days__c;
    QuotePricingService.BuyerContext b = new QuotePricingService.BuyerContext();
    b.associated = false;
    QuotePricingService.QuotePricingResult pr = QuotePricingService.evaluate(q, q.QuoteLineItems, rules, v, b);
    out.put('quoteId', q.Id);
    out.put('quoteName', q.Name);
    out.put('model', model);
    out.put('trim', v.trim);
    out.put('ageDays', v.ageDays);
    out.put('lineCount', q.QuoteLineItems.size());
    out.put('listSubtotal', pr.listSubtotal);
    out.put('adjustedSubtotal', pr.adjustedSubtotal);
    out.put('netDiscountPercent', pr.netDiscountPercent);
    out.put('rulesApplied', pr.rulesApplied);
    out.put('vehicleBasisIdentified', pr.vehicleBasisIdentified);
    out.put('blockerMessage', pr.blockerMessage);
    List<Map<String, Object>> applied = new List<Map<String, Object>>();
    for (QuotePricingService.AppliedRule ar : pr.appliedRules) {
        Map<String, Object> m = new Map<String, Object>();
        m.put('rule', ar.developerName);
        m.put('direction', ar.direction);
        m.put('percent', ar.percent);
        m.put('base', ar.base);
        m.put('adjustment', ar.adjustment);
        applied.add(m);
    }
    out.put('appliedRules', applied);
    break;
}
System.debug('UAT_PRICING=' + JSON.serialize(out));
