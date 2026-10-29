Savepoint sp = Database.setSavepoint();
Map<String, Object> r = new Map<String, Object>();
Decimal discount = 12;
String routeName = 'VP';
Account a = new Account(Name = 'UAT-2026-10-19 PROBE-HOUSEHOLD');
insert a;
Contact c = new Contact(LastName = 'UAT Probe', AccountId = a.Id);
insert c;
Opportunity o = new Opportunity(
    Name = 'UAT-2026-10-19 PROBE-' + routeName,
    AccountId = a.Id,
    CloseDate = Date.today().addDays(30),
    StageName = 'Quoting',
    Discount_Percent__c = discount,
    Approval_Status__c = 'Pending'
);
insert o;
Quote q = new Quote(
    Name = 'UAT-2026-10-19 PROBE-' + routeName + ' Quote',
    OpportunityId = o.Id,
    Pricebook2Id = '01saj00000NvczNAAR',
    ExpirationDate = Date.today().addDays(30)
);
insert q;
try {
    Id instanceId = QuoteBuilderController.submitForApproval(q.Id);
    r.put('submitted', true);
    r.put('instanceId', instanceId);
    List<ProcessInstanceWorkitem> wis = [
        SELECT Id, ActorId, ProcessInstanceId, ProcessInstance.TargetObjectId
        FROM ProcessInstanceWorkitem WHERE ProcessInstanceId = :instanceId
    ];
    r.put('workitemCount', wis.size());
    if (!wis.isEmpty()) {
        r.put('actorId', wis[0].ActorId);
        r.put('targetObjectId', wis[0].ProcessInstance.TargetObjectId);
    }
} catch (Exception e) {
    r.put('error', e.getMessage());
}
Database.rollback(sp);
System.debug('UAT_RESULT=' + JSON.serialize(r));
