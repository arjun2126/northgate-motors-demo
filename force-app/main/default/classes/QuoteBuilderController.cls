public with sharing class QuoteBuilderController {
    private static final Decimal MANAGER_APPROVAL_THRESHOLD = 5;
    private static final String LOYALTY_GOOD_STATUS = 'Active';

    public class CatalogItem {
        @AuraEnabled public Id productId;
        @AuraEnabled public String name;
        @AuraEnabled public String category;
        @AuraEnabled public Decimal unitPrice;
    }

    public class LineInput {
        @AuraEnabled public Id productId { get; set; }
        @AuraEnabled public Decimal quantity { get; set; }
    }

    public class BuyerOption {
        @AuraEnabled public String label;
        @AuraEnabled public Id value;
    }

    public class AppliedRuleDto {
        @AuraEnabled public String developerName;
        @AuraEnabled public String category;
        @AuraEnabled public String direction;
        @AuraEnabled public Decimal percent;
        @AuraEnabled public Decimal base;
        @AuraEnabled public Decimal adjustment;
    }

    public class QuoteResult {
        @AuraEnabled public Id quoteId;
        @AuraEnabled public Decimal listSubtotal;
        @AuraEnabled public Decimal adjustedSubtotal;
        @AuraEnabled public Decimal netDiscountPercent;
        @AuraEnabled public Integer rulesApplied;
        @AuraEnabled public Boolean vehicleBasisIdentified;
        @AuraEnabled public String blockerMessage;
        @AuraEnabled public List<AppliedRuleDto> appliedRules;
    }

    @AuraEnabled(cacheable=true)
    public static List<CatalogItem> getCatalog(String category) {
        List<CatalogItem> items = new List<CatalogItem>();
        Id pbId = standardPricebookId();
        for (PricebookEntry entry : [
            SELECT Product2Id, Product2.Name, Product2.Category__c, UnitPrice
            FROM PricebookEntry
            WHERE Pricebook2Id = :pbId
                AND Product2.Category__c = :category
                AND Product2.IsActive = true
                AND IsActive = true
            WITH USER_MODE
            ORDER BY Product2.Name
        ]) {
            CatalogItem item = new CatalogItem();
            item.productId = entry.Product2Id;
            item.name = entry.Product2.Name;
            item.category = entry.Product2.Category__c;
            item.unitPrice = entry.UnitPrice;
            items.add(item);
        }
        return items;
    }

    @AuraEnabled(cacheable=true)
    public static List<BuyerOption> getBuyerContacts(Id opportunityId) {
        Opportunity opp = [SELECT AccountId FROM Opportunity WHERE Id = :opportunityId WITH USER_MODE];
        List<BuyerOption> options = new List<BuyerOption>();
        if (opp.AccountId == null) {
            return options;
        }
        for (Contact contact : [
            SELECT Id, Name FROM Contact WHERE AccountId = :opp.AccountId WITH USER_MODE ORDER BY Name
        ]) {
            BuyerOption option = new BuyerOption();
            option.label = contact.Name;
            option.value = contact.Id;
            options.add(option);
        }
        return options;
    }

    @AuraEnabled
    public static QuoteResult createQuote(Id opportunityId, Id buyerContactId, List<LineInput> lines) {
        if (opportunityId == null) {
            throw new IllegalArgumentException('Opportunity is required.');
        }
        if (lines == null || lines.isEmpty()) {
            throw new IllegalArgumentException('At least one product line is required.');
        }

        Integer existingQuoteCount = [
            SELECT COUNT()
            FROM Quote
            WHERE OpportunityId = :opportunityId
            WITH USER_MODE
        ];
        if (existingQuoteCount > 0) {
            throw new IllegalArgumentException(
                'This Opportunity already has a quote. Only one quote is allowed per Opportunity.'
            );
        }

        Opportunity opp = [
            SELECT Id, Name, AccountId, Vehicle__r.Vehicle_Model__r.Name, Vehicle__r.Vehicle_Model__r.Trim__c,
                Vehicle__r.Inventory_Age_Days__c
            FROM Opportunity
            WHERE Id = :opportunityId WITH USER_MODE
        ];

        Id pbId = standardPricebookId();
        if (pbId == null) {
            throw new IllegalArgumentException('Standard Price Book is not active. Activate it before creating quotes.');
        }

        Map<Id, PricebookEntry> entryByProduct = new Map<Id, PricebookEntry>();
        for (PricebookEntry entry : [
            SELECT Product2Id, UnitPrice
            FROM PricebookEntry
            WHERE Pricebook2Id = :pbId AND Product2Id IN :productIds(lines) WITH USER_MODE
        ]) {
            entryByProduct.put(entry.Product2Id, entry);
        }

        Date validUntil = Date.today().addDays(30);
        Quote quote = new Quote(
            Name = opp.Name + ' - Quote',
            OpportunityId = opp.Id,
            Pricebook2Id = pbId,
            ExpirationDate = validUntil,
            Quote_Valid_Until__c = validUntil,
            Buyer_Contact__c = buyerContactId
        );
        insertUserMode(quote);

        List<QuoteLineItem> newLines = new List<QuoteLineItem>();
        for (LineInput line : lines) {
            PricebookEntry entry = entryByProduct.get(line.productId);
            if (entry == null) {
                continue;
            }
            Decimal qty = line.quantity == null ? 1 : line.quantity;
            newLines.add(new QuoteLineItem(
                QuoteId = quote.Id,
                PricebookEntryId = entry.Id,
                Quantity = qty,
                UnitPrice = entry.UnitPrice
            ));
        }
        insertUserMode(newLines);
        if (newLines.isEmpty()) {
            throw new IllegalArgumentException('No line matched the standard price book.');
        }

        List<QuoteLineItem> queriedLines = [
            SELECT Id, UnitPrice, Quantity, PricebookEntry.Product2.Category__c, PricebookEntry.Product2.Name
            FROM QuoteLineItem
            WHERE QuoteId = :quote.Id WITH USER_MODE
        ];

        QuotePricingService.VehicleContext vehicle = buildVehicleContext(opp);
        QuotePricingService.BuyerContext buyer = buildBuyerContext(opp.AccountId, buyerContactId);
        List<Price_Rule__mdt> rules = [
            SELECT DeveloperName, Rule_Type__c, Attribute__c, Operator__c, Value__c,
                Percent_Adjustment__c, Fixed_Adjustment__c, Priority__c, Max_Applies__c,
                Is_Active__c, Target__c
            FROM Price_Rule__mdt WITH USER_MODE
        ];

        QuotePricingService.QuotePricingResult result =
            QuotePricingService.evaluate(quote, queriedLines, rules, vehicle, buyer);

        QuoteResult wrapper = new QuoteResult();
        wrapper.quoteId = quote.Id;
        wrapper.listSubtotal = result.listSubtotal;
        wrapper.adjustedSubtotal = result.adjustedSubtotal;
        wrapper.netDiscountPercent = result.netDiscountPercent;
        wrapper.rulesApplied = result.rulesApplied;
        wrapper.vehicleBasisIdentified = result.vehicleBasisIdentified;
        wrapper.blockerMessage = result.blockerMessage;
        wrapper.appliedRules = new List<AppliedRuleDto>();
        for (QuotePricingService.AppliedRule applied : result.appliedRules) {
            AppliedRuleDto dto = new AppliedRuleDto();
            dto.developerName = applied.developerName;
            dto.category = applied.category;
            dto.direction = applied.direction;
            dto.percent = applied.percent;
            dto.base = applied.base;
            dto.adjustment = applied.adjustment;
            wrapper.appliedRules.add(dto);
        }

        if (result.blockerMessage == null) {
            quote.Adjusted_Subtotal__c = result.adjustedSubtotal;
            quote.Rule_Applied_Count__c = result.rulesApplied;
            updateUserMode(quote);

            Opportunity stamp = new Opportunity(Id = opp.Id);
            stamp.Discount_Percent__c = result.netDiscountPercent;
            stamp.Approval_Status__c = result.netDiscountPercent > MANAGER_APPROVAL_THRESHOLD ? 'Pending' : 'Not_Required';
            updateUserMode(stamp);
        }

        return wrapper;
    }

    private static Set<Id> productIds(List<LineInput> lines) {
        Set<Id> ids = new Set<Id>();
        for (LineInput line : lines) {
            if (line.productId != null) {
                ids.add(line.productId);
            }
        }
        return ids;
    }

    private static Id standardPricebookId() {
        if (Test.isRunningTest()) {
            return Test.getStandardPricebookId();
        }
        List<Pricebook2> standards = [SELECT Id FROM Pricebook2 WHERE IsStandard = true AND IsActive = true WITH USER_MODE LIMIT 1];
        if (standards.isEmpty()) {
            return null;
        }
        return standards[0].Id;
    }

    private static QuotePricingService.VehicleContext buildVehicleContext(Opportunity opp) {
        QuotePricingService.VehicleContext context = new QuotePricingService.VehicleContext();
        context.hasVehicle = opp.Vehicle__c != null;
        context.modelName = opp.Vehicle__r.Vehicle_Model__r.Name;
        context.trim = opp.Vehicle__r.Vehicle_Model__r.Trim__c;
        context.ageDays = opp.Vehicle__r.Inventory_Age_Days__c;
        return context;
    }

    private static QuotePricingService.BuyerContext buildBuyerContext(Id accountId, Id buyerContactId) {
        QuotePricingService.BuyerContext context = new QuotePricingService.BuyerContext();
        context.tier = null;
        context.associated = false;
        if (buyerContactId == null || accountId == null) {
            return context;
        }
        Contact buyer = [SELECT AccountId FROM Contact WHERE Id = :buyerContactId WITH USER_MODE];
        if (buyer.AccountId != accountId) {
            return context;
        }
        String tier = deterministicTier([SELECT Tier__c, Member_Number__c, Tier_Evaluated_On__c
            FROM Loyalty_Member__c
            WHERE Contact__c = :buyerContactId AND Status__c = :LOYALTY_GOOD_STATUS WITH USER_MODE]);
        if (tier != null) {
            context.tier = tier;
            context.associated = true;
        }
        return context;
    }

    private static final Map<String, Integer> TIER_RANK = new Map<String, Integer>{
        'Bronze' => 1, 'Silver' => 2, 'Gold' => 3, 'Platinum' => 4
    };

    private static String deterministicTier(List<Loyalty_Member__c> memberships) {
        if (memberships == null || memberships.isEmpty()) {
            return null;
        }
        Loyalty_Member__c best = null;
        Integer bestRank = 0;
        String bestMemberNumber = '~~~~~~~~~~';
        Date bestEvaluatedOn = Date.valueOf('1900-01-01');
        for (Loyalty_Member__c membership : memberships) {
            if (membership.Tier__c == null) {
                continue;
            }
            Integer currentRank = TIER_RANK.containsKey(membership.Tier__c) ? TIER_RANK.get(membership.Tier__c) : 0;
            String currentMemberNumber = membership.Member_Number__c == null
                ? '~~~~~~~~~~'
                : membership.Member_Number__c;
            Date currentEvaluatedOn = membership.Tier_Evaluated_On__c == null
                ? Date.valueOf('1900-01-01')
                : membership.Tier_Evaluated_On__c;
            if (best == null) {
                best = membership;
                bestRank = currentRank;
                bestMemberNumber = currentMemberNumber;
                bestEvaluatedOn = currentEvaluatedOn;
                continue;
            }
            Boolean better = false;
            if (currentRank != bestRank) {
                better = currentRank > bestRank;
            } else if (currentMemberNumber != bestMemberNumber) {
                better = currentMemberNumber.compareTo(bestMemberNumber) < 0;
            } else if (currentEvaluatedOn != bestEvaluatedOn) {
                better = currentEvaluatedOn > bestEvaluatedOn;
            }
            if (better) {
                best = membership;
                bestRank = currentRank;
                bestMemberNumber = currentMemberNumber;
                bestEvaluatedOn = currentEvaluatedOn;
            }
        }
        return best == null ? null : best.Tier__c;
    }

    @AuraEnabled
    public static Id submitForApproval(Id quoteId) {
        if (quoteId == null) {
            throw new IllegalArgumentException('Quote is required.');
        }
        Quote quote = [SELECT Id, OpportunityId FROM Quote WHERE Id = :quoteId WITH USER_MODE];
        Opportunity opp = [
            SELECT Id, Discount_Percent__c, Approval_Status__c
            FROM Opportunity WHERE Id = :quote.OpportunityId WITH USER_MODE
        ];
        if (opp.Approval_Status__c != 'Pending') {
            throw new IllegalArgumentException('Quote is not pending approval.');
        }
        if (opp.Discount_Percent__c == null || opp.Discount_Percent__c <= MANAGER_APPROVAL_THRESHOLD) {
            throw new IllegalArgumentException('Discount does not require approval.');
        }
        Id approverId;
        if (opp.Discount_Percent__c <= 10) {
            User submitter = [SELECT ManagerId FROM User WHERE Id = :UserInfo.getUserId() WITH USER_MODE];
            approverId = submitter.ManagerId;
            if (approverId == null) {
                throw new IllegalArgumentException('No manager found for the submitter.');
            }
        } else {
            List<User> vps = [
                SELECT Id FROM User
                WHERE UserRole.DeveloperName = 'VP_Sales' AND IsActive = true
                WITH USER_MODE ORDER BY CreatedDate, Id LIMIT 1
            ];
            if (vps.isEmpty()) {
                throw new IllegalArgumentException('No VP approver available.');
            }
            approverId = vps[0].Id;
        }
        if (approverId == UserInfo.getUserId()) {
            throw new IllegalArgumentException('Submitter cannot be the approver.');
        }
        Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
        request.setObjectId(opp.Id);
        request.setComments('Discount requires approval.');
        request.setNextApproverIds(new List<Id>{ approverId });
        Approval.ProcessResult result = Approval.process(request);
        if (!result.isSuccess()) {
            throw new DmlException(String.valueOf(result.getErrors()));
        }
        return result.getInstanceId();
    }

    private static void insertUserMode(sObject record) {
        Database.SaveResult sr = Database.insert(record, AccessLevel.USER_MODE);
        if (!sr.isSuccess()) {
            throw new DmlException(sr.getErrors()[0].getMessage());
        }
    }

    private static void insertUserMode(List<sObject> records) {
        Database.SaveResult[] results = Database.insert(records, AccessLevel.USER_MODE);
        for (Database.SaveResult sr : results) {
            if (!sr.isSuccess()) {
                throw new DmlException(sr.getErrors()[0].getMessage());
            }
        }
    }

    private static void updateUserMode(sObject record) {
        Database.SaveResult sr = Database.update(record, AccessLevel.USER_MODE);
        if (!sr.isSuccess()) {
            throw new DmlException(sr.getErrors()[0].getMessage());
        }
    }
}