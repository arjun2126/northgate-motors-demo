String processName = 'Financing_Exception_Approval';
Id queueId = '00Gaj00000ZYezlEAD';

List<ProcessInstance> pendingFinance = [
    SELECT Id, TargetObjectId, Status
    FROM ProcessInstance
    WHERE Status = 'Pending' AND ProcessDefinition.DeveloperName = :processName
    ORDER BY Id
];
List<ProcessInstanceWorkitem> pendingQueue = [
    SELECT Id, ProcessInstanceId, ActorId
    FROM ProcessInstanceWorkitem
    WHERE ProcessInstance.Status = 'Pending' AND ActorId = :queueId
    ORDER BY Id
];

if (!pendingFinance.isEmpty() || !pendingQueue.isEmpty()) {
    List<String> details = new List<String>();
    for (ProcessInstance item : pendingFinance) {
        details.add(item.Id + '|' + item.TargetObjectId);
    }
    for (ProcessInstanceWorkitem item : pendingQueue) {
        details.add(item.Id + '|' + item.ProcessInstanceId + '|' + item.ActorId);
    }
    throw new IllegalArgumentException('Finance approvals still pending: ' + String.join(details, ', '));
}

Map<String, Object> out = new Map<String, Object>{
    'pendingFinanceApprovals' => pendingFinance.size(),
    'pendingFinanceQueueWorkItems' => pendingQueue.size(),
    'status' => 'PASS'
};
System.debug('FIN_PRE_RESTORE_GUARD=' + JSON.serialize(out));
