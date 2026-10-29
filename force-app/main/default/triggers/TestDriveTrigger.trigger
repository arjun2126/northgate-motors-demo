trigger TestDriveTrigger on Test_Drive__c (before insert, before update, after insert, after update) {
    TestDriveTriggerHandler.run();
}
