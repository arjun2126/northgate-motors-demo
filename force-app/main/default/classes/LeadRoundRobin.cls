public with sharing class LeadRoundRobin {
    @TestVisible
    private static Map<String, Integer> prefixCounts = new Map<String, Integer>();

    public class Request {
        @InvocableVariable(label='FSA Prefix' required=true)
        public String fsaPrefix;

        @InvocableVariable(label='Owner Ids' required=true)
        public List<String> ownerIds;
    }

    public class Response {
        @InvocableVariable(label='Slot')
        public Integer slot;

        @InvocableVariable(label='Owner Id')
        public String ownerId;

        @InvocableVariable(label='Batch')
        public String batch;
    }

    @InvocableMethod(label='Next round-robin slot' description='Returns the next sequential owner and batch label within the same transaction for an FSA prefix.')
    public static List<Response> nextSlot(List<Request> requests) {
        List<Response> responses = new List<Response>();
        for (Request req : requests) {
            Response res = new Response();
            String key = String.isBlank(req.fsaPrefix) ? 'UNROUTED' : req.fsaPrefix;
            Integer seenCount = prefixCounts.containsKey(key) ? prefixCounts.get(key) : 0;
            Integer laneCount = (req.ownerIds == null || req.ownerIds.isEmpty()) ? 0 : req.ownerIds.size();
            Integer lane = (laneCount == 0) ? 0 : Math.mod(seenCount, laneCount);
            res.slot = lane + 1;
            res.ownerId = (laneCount == 0) ? null : req.ownerIds[lane];
            res.batch = key + '-R' + String.valueOf(res.slot);
            prefixCounts.put(key, seenCount + 1);
            responses.add(res);
        }
        return responses;
    }
}
