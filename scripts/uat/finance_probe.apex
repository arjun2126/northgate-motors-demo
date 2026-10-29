Savepoint sp = Database.setSavepoint();
Map<String, Object> r = new Map<String, Object>();
Account a = new Account(Name = 'UAT-2026-10-19 FIN-HOUSEHOLD');
insert a;
Contact c = new Contact(LastName = 'UAT Fin', AccountId = a.Id);
insert c;
Opportunity o = new Opportunity(
    Name = 'UAT-2026-10-19 FIN',
    AccountId = a.Id,
    CloseDate = Date.today().addDays(30),
    StageName = 'Financing'
);
insert o;
Financing__c f = new Financing__c(
    Opportunity__c = o.Id,
    Applicant__c = c.Id,
    Rate_Source__c = 'Manual_Exception',
    Status__c = 'Draft'
);
insert f;
r.put('financingId', f.Id);
try {
    Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
    req.setObjectId(f.Id);
    req.setComments('UAT-2026-10-19 finance exception');
    Approval.ProcessResult pr = Approval.process(req);
    r.put('success', pr.isSuccess());
    r.put('instanceId', pr.getInstanceId());
    if (pr.isSuccess()) {
        List<ProcessInstanceWorkitem> wis = [
            SELECT Id, ActorId, ProcessInstanceId
            FROM ProcessInstanceWorkitem WHERE ProcessInstanceId = :pr.getInstanceId()
        ];
        r.put('workitemCount', wis.size());
        if (!wis.isEmpty()) {
            r.put('actorId', wis[0].ActorId);
            Group g = [SELECT Id, DeveloperName, Name, Type FROM Group WHERE Id = :wis[0].ActorId];
            r.put('actorGroup', g.DeveloperName);
            r.put('actorGroupType', g.Type);
        }
    }
} catch (Exception e) {
    r.put('error', e.getMessage());
}
Database.rollback(sp);
System.debug('UAT_RESULT=' + JSON.serialize(r));
