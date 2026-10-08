@isTest
private class LeadRoundRobinTest {
    @isTest
    static void cyclesOwnersWithinSamePrefix() {
        LeadRoundRobin.prefixCounts.clear();
        LeadRoundRobin.Request first = new LeadRoundRobin.Request();
        first.fsaPrefix = 'M';
        first.ownerIds = new List<String>{ '005000000000000AAA', '00G000000000000EAA' };
        LeadRoundRobin.Request second = new LeadRoundRobin.Request();
        second.fsaPrefix = 'M';
        second.ownerIds = new List<String>{ '005000000000000AAA', '00G000000000000EAA' };
        LeadRoundRobin.Request other = new LeadRoundRobin.Request();
        other.fsaPrefix = 'L4H';
        other.ownerIds = new List<String>{ '005000000000000AAA', '00G000000000000EAA' };

        List<LeadRoundRobin.Response> results = LeadRoundRobin.nextSlot(
            new List<LeadRoundRobin.Request>{ first, second, other }
        );

        System.assertEquals(3, results.size());
        System.assertEquals(1, results[0].slot);
        System.assertEquals('005000000000000AAA', results[0].ownerId);
        System.assertEquals('M-R1', results[0].batch);
        System.assertEquals(2, results[1].slot);
        System.assertEquals('00G000000000000EAA', results[1].ownerId);
        System.assertEquals('M-R2', results[1].batch);
        System.assertEquals(1, results[2].slot);
        System.assertEquals('L4H-R1', results[2].batch);
        LeadRoundRobin.prefixCounts.clear();
    }
}
