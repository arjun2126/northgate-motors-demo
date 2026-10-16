public with sharing class FinancingApprovalService {
    public class ApprovalOutcome {
        @AuraEnabled public Id processInstanceId;
        @AuraEnabled public Boolean alreadySubmitted;
        @AuraEnabled public Boolean requiresApproval;
        @AuraEnabled public List<String> errors;
    }

    private static final String EXCEPTION_PROCESS = 'Financing_Exception_Approval';
    private static final String QUEUE_DEV_NAME = 'Q_Finance_Approvals';
    private static final Set<String> EXCEPTION_TIERS = new Set<String>{ 'Sub_Prime' };
    private static final Set<String> EXCEPTION_RATE_SOURCES = new Set<String>{ 'Manual_Exception' };

    @AuraEnabled
    public static ApprovalOutcome submitForExceptionApproval(Id financingId) {
        ApprovalOutcome outcome = new ApprovalOutcome();
        outcome.errors = new List<String>();
        outcome.requiresApproval = false;
        outcome.alreadySubmitted = false;
        if (financingId == null) {
            outcome.errors.add('Financing record is required.');
            return outcome;
        }
        List<Financing__c> records = [
            SELECT Id, Rate_Source__c, Credit_Tier__c, Status__c, Opportunity__c
            FROM Financing__c
            WHERE Id = :financingId
            WITH USER_MODE
            LIMIT 1
        ];
        if (records.isEmpty()) {
            outcome.errors.add('Financing record not found or inaccessible.');
            return outcome;
        }
        Financing__c record = records[0];
        if (!requiresExceptionApproval(record)) {
            outcome.requiresApproval = false;
            outcome.errors.add(
                'This financing does not require exception approval (Rate_Source__c is Rate_Table and Credit_Tier__c is not Sub_Prime).'
            );
            return outcome;
        }
        outcome.requiresApproval = true;
        List<ProcessInstance> existing = [
            SELECT Id, Status FROM ProcessInstance
            WHERE TargetObjectId = :financingId AND Status = 'Pending'
            LIMIT 1
        ];
        if (!existing.isEmpty()) {
            outcome.alreadySubmitted = true;
            outcome.processInstanceId = existing[0].Id;
            return outcome;
        }
        Id approverId = deriveApproverId();
        if (approverId == null) {
            outcome.errors.add('Approval approver could not be derived (Q_Finance_Approvals queue missing).');
            return outcome;
        }
        Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
        request.setObjectId(record.Id);
        request.setProcessDefinitionNameOrId(EXCEPTION_PROCESS);
        request.setComments('Submitting for finance manager exception approval.');
        request.setNextApproverIds(new List<Id>{ approverId });
        Approval.ProcessResult result = Approval.process(request);
        if (!result.isSuccess()) {
            outcome.errors.add('Approval submission failed: ' + result.getErrors());
            return outcome;
        }
        outcome.processInstanceId = result.getInstanceId();
        return outcome;
    }

    public static Boolean requiresExceptionApproval(Financing__c record) {
        if (record == null) {
            return false;
        }
        if (record.Rate_Source__c != null && EXCEPTION_RATE_SOURCES.contains(record.Rate_Source__c)) {
            return true;
        }
        if (record.Credit_Tier__c != null && EXCEPTION_TIERS.contains(record.Credit_Tier__c)) {
            return true;
        }
        return false;
    }

    private static Id deriveApproverId() {
        List<Group> queues = [
            SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = :QUEUE_DEV_NAME LIMIT 1
        ];
        return queues.isEmpty() ? null : queues[0].Id;
    }
}
