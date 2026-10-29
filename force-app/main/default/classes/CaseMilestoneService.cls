public without sharing class CaseMilestoneService {
    public static void complete(List<Case> rows, Map<Id, Case> oldRows) {
        Map<Id, Datetime> responses = new Map<Id, Datetime>();
        Set<Id> closures = new Set<Id>();
        for (Case row : rows) {
            Case old = oldRows.get(row.Id);
            if (row.EntitlementId == null) continue;
            if (row.First_Response_On__c != null && old.First_Response_On__c == null) responses.put(row.Id, row.First_Response_On__c);
            if (row.IsClosed && !old.IsClosed) closures.add(row.Id);
        }
        Set<Id> ids = new Set<Id>(responses.keySet()); ids.addAll(closures);
        if (ids.isEmpty()) return;
        List<CaseMilestone> updates = new List<CaseMilestone>();
        for (CaseMilestone milestone : [SELECT Id, CaseId, StartDate, MilestoneType.Name FROM CaseMilestone
            WHERE CaseId IN :ids AND CompletionDate = null
                AND Case.RecordType.DeveloperName = 'Service'
                AND Case.Entitlement.SlaProcess.Name = 'NG Platinum Care'
                AND MilestoneType.Name IN ('NG First Response', 'NG Resolution') WITH SYSTEM_MODE FOR UPDATE]) {
            Datetime completed = milestone.MilestoneType.Name == 'NG First Response'
                ? responses.get(milestone.CaseId) : (closures.contains(milestone.CaseId) ? Datetime.now() : null);
            if (completed != null && completed >= milestone.StartDate && completed <= Datetime.now()) {
                updates.add(new CaseMilestone(Id = milestone.Id, CompletionDate = completed));
            }
        }
        if (!updates.isEmpty()) update as system updates;
    }
}
