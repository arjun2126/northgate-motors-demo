public without sharing class LoyaltyLedgerService {
    public class LoyaltyException extends Exception {}
    @TestVisible private static Loyalty_Program__mdt programOverride;
    @TestVisible private static List<Loyalty_Tier__mdt> tiersOverride;
    @TestVisible private static Date dateOverride;
    private static Boolean writing = false;

    public class Rules {
        public Loyalty_Program__mdt program;
        public List<Loyalty_Tier__mdt> tiers;
        public Rules() {
            program = programOverride == null ? Loyalty_Program__mdt.getInstance('Default') : programOverride;
            tiers = tiersOverride == null ? Loyalty_Tier__mdt.getAll().values() : tiersOverride;
            if (program == null || !program.Is_Active__c || program.Eligible_From__c == null
                || program.Service_Points_Per_CAD__c == null || program.Service_Points_Per_CAD__c <= 0
                || program.Sale_Points_Per_CAD__c == null || program.Sale_Points_Per_CAD__c <= 0
                || program.Redemption_Value__c == null || program.Redemption_Value__c <= 0) {
                throw new LoyaltyException('Loyalty program is inactive or configuration is invalid.');
            }
            List<Loyalty_Tier__mdt> active = new List<Loyalty_Tier__mdt>();
            Set<String> names = new Set<String>();
            Set<Decimal> thresholds = new Set<Decimal>();
            for (Loyalty_Tier__mdt tier : tiers) {
                if (!tier.Is_Active__c) continue;
                if (!new Set<String>{'Bronze','Silver','Gold','Platinum'}.contains(tier.Tier__c)
                    || names.contains(tier.Tier__c) || tier.Threshold_Amount__c == null
                    || tier.Threshold_Amount__c < 0 || tier.Threshold_Amount__c > 999999999
                    || tier.Threshold_Amount__c != tier.Threshold_Amount__c.setScale(0)
                    || thresholds.contains(tier.Threshold_Amount__c) || tier.Accrual_Multiplier__c == null
                    || tier.Accrual_Multiplier__c <= 0 || tier.Expiry_Days__c == null || tier.Expiry_Days__c <= 0) {
                    throw new LoyaltyException('Loyalty tier configuration is invalid.');
                }
                active.add(tier);
                names.add(tier.Tier__c);
                thresholds.add(tier.Threshold_Amount__c);
            }
            active.sort(new TierOrder());
            if (active.size() != 4 || active[0].Tier__c != 'Bronze' || active[0].Threshold_Amount__c != 0
                || active[1].Tier__c != 'Silver' || active[2].Tier__c != 'Gold' || active[3].Tier__c != 'Platinum') {
                throw new LoyaltyException('Four ordered loyalty tiers are required.');
            }
            tiers = active;
        }
        public Loyalty_Tier__mdt tier(String name) {
            for (Loyalty_Tier__mdt value : tiers) if (value.Tier__c == name) return value;
            throw new LoyaltyException('Member tier is not configured.');
        }
    }
    private class TierOrder implements Comparator<Loyalty_Tier__mdt> {
        public Integer compare(Loyalty_Tier__mdt a, Loyalty_Tier__mdt b) {
            return a.Threshold_Amount__c == b.Threshold_Amount__c ? 0 : (a.Threshold_Amount__c < b.Threshold_Amount__c ? -1 : 1);
        }
    }
    public static Date torontoDay(Datetime instant) {
        return Date.valueOf(instant.format('yyyy-MM-dd', 'America/Toronto'));
    }
    public static Date today() { return dateOverride == null ? torontoDay(Datetime.now()) : dateOverride; }
    public static String key(String value) {
        return EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(value)));
    }
    private static Decimal zero(Decimal value) { return value == null ? 0 : value; }
    private static Map<Id, Loyalty_Member__c> lockMembers(Set<Id> ids) {
        return new Map<Id, Loyalty_Member__c>([
            SELECT Id, Contact__c, Status__c, Tier__c, Points_Balance__c, Lifetime_Spend__c,
                Lifetime_Points_Earned__c, Lifetime_Points_Redeemed__c, Managed_From__c
            FROM Loyalty_Member__c WHERE Id IN :ids WITH SYSTEM_MODE FOR UPDATE
        ]);
    }

    public static Integer accrue(String kind, Set<Id> sourceIds) {
        Rules rules = new Rules();
        List<LoyaltyAccrualService.Source> initial = LoyaltyAccrualService.resolve(kind, sourceIds, rules, false);
        Set<Id> contacts = new Set<Id>();
        for (LoyaltyAccrualService.Source source : initial) contacts.add(source.contactId);
        Map<Id, Id> memberByContact = new Map<Id, Id>();
        Set<Id> ambiguous = new Set<Id>();
        for (Loyalty_Member__c member : [SELECT Id, Contact__c FROM Loyalty_Member__c WHERE Contact__c IN :contacts WITH SYSTEM_MODE]) {
            if (memberByContact.containsKey(member.Contact__c)) ambiguous.add(member.Contact__c);
            memberByContact.put(member.Contact__c, member.Id);
        }
        Map<Id, Loyalty_Member__c> members = lockMembers(new Set<Id>(memberByContact.values()));
        List<LoyaltyAccrualService.Source> sources = LoyaltyAccrualService.resolve(kind, sourceIds, rules, true);
        Set<String> keys = new Set<String>();
        for (LoyaltyAccrualService.Source source : sources) keys.add(key(source.identity));
        Map<String, Loyalty_Transaction__c> existing = new Map<String, Loyalty_Transaction__c>();
        List<Loyalty_Transaction__c> postedEvents = [SELECT Event_Key__c, Source_Spend__c, Loyalty_Member__c
            FROM Loyalty_Transaction__c WHERE Event_Key__c IN :keys WITH SYSTEM_MODE];
        for (Loyalty_Transaction__c row : postedEvents) existing.put(row.Event_Key__c, row);
        List<Loyalty_Transaction__c> events = new List<Loyalty_Transaction__c>();
        Map<Id, Loyalty_Member__c> changed = new Map<Id, Loyalty_Member__c>();
        Integer skipped = 0;
        for (LoyaltyAccrualService.Source source : sources) {
            Id memberId = memberByContact.get(source.contactId);
            Loyalty_Member__c member = members.get(memberId);
            if (member == null || ambiguous.contains(source.contactId) || member.Contact__c != source.contactId
                || member.Status__c != 'Active') { skipped++; continue; }
            String eventKey = key(source.identity);
            if (existing.containsKey(eventKey)) {
                Loyalty_Transaction__c prior = existing.get(eventKey);
                if (prior.Loyalty_Member__c != member.Id || prior.Source_Spend__c != source.spend) {
                    throw new LoyaltyException('Posted source changed; manual review is required.');
                }
                continue;
            }
            if (source.spend == null || source.spend < 0) throw new LoyaltyException('Eligible spend must be nonnegative.');
            Loyalty_Tier__mdt tier = rules.tier(member.Tier__c);
            Decimal rate = kind == 'Service' ? rules.program.Service_Points_Per_CAD__c : rules.program.Sale_Points_Per_CAD__c;
            Decimal points = (source.spend * rate * tier.Accrual_Multiplier__c).setScale(0, RoundingMode.FLOOR);
            if (points == 0) continue;
            if (points > 99999999) throw new LoyaltyException('Accrual exceeds the supported points limit.');
            events.add(new Loyalty_Transaction__c(Loyalty_Member__c = member.Id, Type__c = 'Accrual',
                Reason__c = kind == 'Service' ? 'Service_Spend' : 'Vehicle_Purchase', Points__c = points,
                Remaining_Points__c = points, Source_Spend__c = source.spend, Event_Key__c = eventKey,
                Source_Reference__c = source.identity, Service_Visit__c = source.visitId, Opportunity__c = source.opportunityId,
                Transaction_Date__c = today(), Expiry_Date__c = today().addDays(Integer.valueOf(tier.Expiry_Days__c)),
                Applied_Rate__c = rate, Applied_Multiplier__c = tier.Accrual_Multiplier__c, Applied_Tier__c = member.Tier__c));
            member.Points_Balance__c = zero(member.Points_Balance__c) + points;
            member.Lifetime_Points_Earned__c = zero(member.Lifetime_Points_Earned__c) + points;
            member.Lifetime_Spend__c = zero(member.Lifetime_Spend__c) + source.spend;
            member.Last_Activity_Date__c = today();
            if (member.Managed_From__c == null) member.Managed_From__c = Datetime.now();
            changed.put(member.Id, member);
            // A repeated source in the same scope must not receive a second credit.
            existing.put(eventKey, events[events.size() - 1]);
        }
        persist(changed.values(), new List<Loyalty_Transaction__c>(), events);
        System.debug(LoggingLevel.INFO, 'Loyalty accrual: posted=' + events.size() + ', ineligibleMemberships=' + skipped);
        return events.size();
    }

    public static Decimal redeem(Id memberId, Decimal points, String token) {
        Rules rules = new Rules();
        if (points == null || points <= 0 || points > 99999999 || points != points.setScale(0)
            || String.isBlank(token) || token.length() > 80) throw new LoyaltyException('Enter positive integer points and a request token.');
        Loyalty_Member__c member = lockMembers(new Set<Id>{memberId}).get(memberId);
        if (member == null || member.Status__c != 'Active' || member.Managed_From__c == null) {
            throw new LoyaltyException('An active managed membership is required.');
        }
        String requestKey = key(String.valueOf(memberId) + ':' + token);
        List<Loyalty_Transaction__c> prior = [SELECT Points__c FROM Loyalty_Transaction__c
            WHERE Loyalty_Member__c = :memberId AND Request_Key__c = :requestKey AND Type__c = 'Redemption' WITH SYSTEM_MODE];
        if (!prior.isEmpty()) {
            Decimal posted = 0;
            for (Loyalty_Transaction__c row : prior) posted -= row.Points__c;
            if (posted != points) throw new LoyaltyException('Request token was already used with different points.');
            return member.Points_Balance__c;
        }
        List<Loyalty_Transaction__c> lots = loadLots(new Set<Id>{memberId});
        lots.sort(new LotOrder());
        Decimal available = 0;
        for (Loyalty_Transaction__c lot : lots) if (lot.Expiry_Date__c == null || lot.Expiry_Date__c >= today()) available += lot.Remaining_Points__c;
        if (points > zero(member.Points_Balance__c) || points > available) throw new LoyaltyException('Insufficient available loyalty points.');
        Decimal remaining = points;
        List<Loyalty_Transaction__c> updates = new List<Loyalty_Transaction__c>();
        List<Loyalty_Transaction__c> events = new List<Loyalty_Transaction__c>();
        for (Loyalty_Transaction__c lot : lots) {
            if (remaining == 0) break;
            if (lot.Expiry_Date__c != null && lot.Expiry_Date__c < today()) continue;
            Decimal consumed = Math.min(remaining, lot.Remaining_Points__c);
            updates.add(new Loyalty_Transaction__c(Id = lot.Id, Remaining_Points__c = lot.Remaining_Points__c - consumed));
            events.add(new Loyalty_Transaction__c(Loyalty_Member__c = memberId, Type__c = 'Redemption',
                Reason__c = 'Service_Redemption', Points__c = -consumed, Source_Accrual__c = lot.Id,
                Request_Key__c = requestKey, Event_Key__c = key(requestKey + ':' + lot.Id), Transaction_Date__c = today()));
            remaining -= consumed;
        }
        member.Points_Balance__c -= points;
        member.Lifetime_Points_Redeemed__c = zero(member.Lifetime_Points_Redeemed__c) + points;
        member.Last_Activity_Date__c = today();
        persist(new List<Loyalty_Member__c>{member}, updates, events);
        return member.Points_Balance__c;
    }

    public static Integer expire(Set<Id> memberIds) {
        Rules rules = new Rules();
        Map<Id, Loyalty_Member__c> members = lockMembers(memberIds);
        Map<Id, Loyalty_Member__c> changed = new Map<Id, Loyalty_Member__c>();
        List<Loyalty_Transaction__c> updates = new List<Loyalty_Transaction__c>();
        List<Loyalty_Transaction__c> events = new List<Loyalty_Transaction__c>();
        for (Loyalty_Transaction__c lot : loadLots(memberIds)) {
            Loyalty_Member__c member = members.get(lot.Loyalty_Member__c);
            if (member.Managed_From__c == null || lot.Expiry_Date__c == null || lot.Expiry_Date__c >= today()) continue;
            Decimal points = lot.Remaining_Points__c;
            member.Points_Balance__c = zero(member.Points_Balance__c) - points;
            if (member.Points_Balance__c < 0) throw new LoyaltyException('Managed lots and balance disagree; manual review is required.');
            updates.add(new Loyalty_Transaction__c(Id = lot.Id, Remaining_Points__c = 0));
            events.add(new Loyalty_Transaction__c(Loyalty_Member__c = member.Id, Type__c = 'Expiry',
                Reason__c = 'Annual_Expiry', Points__c = -points, Source_Accrual__c = lot.Id,
                Event_Key__c = key('Expiry:' + lot.Id), Transaction_Date__c = today()));
            changed.put(member.Id, member);
        }
        persist(changed.values(), updates, events);
        return events.size();
    }

    public static void evaluateTiers(Set<Id> ids) {
        Rules rules = new Rules();
        List<Loyalty_Member__c> updates = new List<Loyalty_Member__c>();
        for (Loyalty_Member__c member : lockMembers(ids).values()) {
            if (member.Managed_From__c == null || member.Status__c != 'Active') continue;
            Loyalty_Tier__mdt chosen = rules.tiers[0];
            for (Loyalty_Tier__mdt tier : rules.tiers) if (zero(member.Lifetime_Spend__c) >= tier.Threshold_Amount__c) chosen = tier;
            if (!rules.program.Allow_Downgrades__c && rules.tier(member.Tier__c).Threshold_Amount__c > chosen.Threshold_Amount__c) chosen = rules.tier(member.Tier__c);
            if (chosen.Tier__c != member.Tier__c) {
                member.Previous_Tier__c = member.Tier__c;
                member.Tier_Changed_On__c = Datetime.now();
                member.Tier__c = chosen.Tier__c;
            }
            member.Next_Tier_Threshold__c = null;
            for (Loyalty_Tier__mdt tier : rules.tiers) if (tier.Threshold_Amount__c > chosen.Threshold_Amount__c) {
                member.Next_Tier_Threshold__c = tier.Threshold_Amount__c; break;
            }
            member.Tier_Evaluated_On__c = today();
            updates.add(member);
        }
        persist(updates, new List<Loyalty_Transaction__c>(), new List<Loyalty_Transaction__c>());
    }

    private static List<Loyalty_Transaction__c> loadLots(Set<Id> ids) {
        return [SELECT Id, Loyalty_Member__c, Remaining_Points__c, Expiry_Date__c FROM Loyalty_Transaction__c
            WHERE Loyalty_Member__c IN :ids AND Event_Key__c != null AND Type__c = 'Accrual'
                AND Remaining_Points__c > 0 WITH SYSTEM_MODE FOR UPDATE];
    }
    private class LotOrder implements Comparator<Loyalty_Transaction__c> {
        public Integer compare(Loyalty_Transaction__c a, Loyalty_Transaction__c b) {
            if (a.Expiry_Date__c == b.Expiry_Date__c) return String.valueOf(a.Id).compareTo(String.valueOf(b.Id));
            if (a.Expiry_Date__c == null) return 1;
            if (b.Expiry_Date__c == null) return -1;
            return a.Expiry_Date__c < b.Expiry_Date__c ? -1 : 1;
        }
    }
    private static void persist(List<Loyalty_Member__c> members, List<Loyalty_Transaction__c> lots, List<Loyalty_Transaction__c> events) {
        if (members.isEmpty() && lots.isEmpty() && events.isEmpty()) return;
        Savepoint checkpoint = Database.setSavepoint();
        writing = true;
        try {
            if (!events.isEmpty()) insert as system events;
            if (!lots.isEmpty()) update as system lots;
            if (!members.isEmpty()) {
                update as system members;
            }
        } catch (Exception error) {
            Database.rollback(checkpoint);
            throw error;
        } finally { writing = false; }
    }
    public static void guardTransactions(List<Loyalty_Transaction__c> rows, Map<Id, Loyalty_Transaction__c> oldRows) {
        if (writing) return;
        for (Loyalty_Transaction__c row : rows) {
            Loyalty_Transaction__c old = oldRows == null ? null : oldRows.get(row.Id);
            if (row.Event_Key__c != null || row.Source_Accrual__c != null || row.Remaining_Points__c != null
                || row.Request_Key__c != null || (old != null && old.Event_Key__c != null)) {
                row.addError('Managed loyalty transactions can only be changed by the loyalty service.');
            }
        }
    }
    public static void guardMembers(List<Loyalty_Member__c> rows, Map<Id, Loyalty_Member__c> oldRows, Boolean deleting) {
        if (writing) return;
        for (Loyalty_Member__c row : rows) {
            Loyalty_Member__c old = oldRows == null ? null : oldRows.get(row.Id);
            if (row.Managed_From__c == null && (old == null || old.Managed_From__c == null)) continue;
            if (deleting || old == null) { row.addError('Managed memberships can only be changed by the loyalty service.'); continue; }
            for (String field : new List<String>{'Managed_From__c','Contact__c','Points_Balance__c','Lifetime_Spend__c',
                'Lifetime_Points_Earned__c','Lifetime_Points_Redeemed__c','Tier__c','Next_Tier_Threshold__c',
                'Tier_Evaluated_On__c','Previous_Tier__c','Tier_Changed_On__c','Last_Activity_Date__c'}) {
                if (row.get(field) != old.get(field)) { row.addError('Managed loyalty values can only be changed by the loyalty service.'); break; }
            }
        }
    }
}
