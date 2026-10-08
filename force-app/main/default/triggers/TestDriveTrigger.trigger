trigger TestDriveTrigger on Test_Drive__c (before insert, before update) {
    Automation_Settings__c settings = Automation_Settings__c.getOrgDefaults();
    if (settings != null && settings.Bypass_Triggers__c == true) {
        return;
    }
    TestDriveBookingGuard.guard(Trigger.new);
}
