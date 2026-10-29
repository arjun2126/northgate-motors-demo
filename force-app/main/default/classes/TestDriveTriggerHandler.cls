public with sharing class TestDriveTriggerHandler {
    public static void run() {
        List<Test_Drive__c> rows = (List<Test_Drive__c>) Trigger.new;
        Map<Id, Test_Drive__c> oldRows = (Map<Id, Test_Drive__c>) Trigger.oldMap;
        // Future-date validation deliberately remains active even when trigger automation is bypassed.
        if (Trigger.isBefore) TestDriveBookingGuard.validateSchedule(rows, oldRows);
        Automation_Settings__c settings = Automation_Settings__c.getOrgDefaults();
        if (settings != null && settings.Bypass_Triggers__c == true) return;
        if (Trigger.isBefore) {
            TestDriveBookingGuard.guard(rows);
        } else {
            if (Trigger.isInsert) TestDriveFollowUp.onCreate(rows);
            if (Trigger.isUpdate) TestDriveFollowUp.onStatusChange(rows, oldRows);
            TestDriveCounters.maintain(rows, oldRows);
        }
    }
}
