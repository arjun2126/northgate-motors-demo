public with sharing class ExecutiveServiceMetricsPublisher implements Schedulable {
    public void execute(SchedulableContext context) {
        publish();
    }

    public static void publish() {
        Executive_Service_Metrics__c metrics = calculate(Date.today());
        metrics.Captured_At__c = Datetime.now();
        persist(metrics);
    }

    @TestVisible
    private static Executive_Service_Metrics__c calculate(Date captureDate) {
        // Match the source report's "Scheduled_Start__c < TODAY" in the running user's time zone.
        Datetime midnight = Datetime.newInstance(captureDate, Time.newInstance(0, 0, 0, 0));
        Integer overdue = [
            SELECT COUNT() FROM Service_Visit__c
            WHERE Status__c = 'Scheduled' AND Scheduled_Start__c < :midnight
            WITH USER_MODE
        ];
        AggregateResult scores = [
            SELECT SUM(CSI_Score__c) scoreTotal, COUNT(CSI_Score__c) responses
            FROM Service_Visit__c WHERE CSI_Score__c != null WITH USER_MODE
        ];
        Decimal scoreTotal = (Decimal) scores.get('scoreTotal');
        return new Executive_Service_Metrics__c(
            Metric_Key__c = 'DEALERSHIP', Overdue_Count__c = overdue,
            CSI_Score_Total__c = scoreTotal == null ? 0 : scoreTotal,
            CSI_Response_Count__c = (Integer) scores.get('responses')
        );
    }

    @TestVisible
    private static void persist(Executive_Service_Metrics__c metrics) {
        // One all-or-none write publishes values and capture time together. Failures leave the previous capture intact.
        upsert as system metrics Metric_Key__c;
    }
}
