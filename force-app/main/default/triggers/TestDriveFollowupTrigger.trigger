trigger TestDriveFollowupTrigger on Test_Drive__c (after insert, after update) {
    Automation_Settings__c settings = Automation_Settings__c.getOrgDefaults();
    if (settings != null && settings.Bypass_Triggers__c == true) {
        return;
    }
    if (Trigger.isAfter && Trigger.isInsert) {
        TestDriveFollowUp.onCreate(Trigger.new);
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
        TestDriveFollowUp.onStatusChange(Trigger.new, Trigger.oldMap);
    }
    TestDriveCounters.maintain(Trigger.new, Trigger.oldMap);
}
