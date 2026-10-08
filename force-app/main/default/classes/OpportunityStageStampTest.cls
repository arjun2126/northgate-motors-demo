@isTest
private class OpportunityStageStampTest {
    @isTest
    static void insertStampsChangeTime() {
        Opportunity o = new Opportunity(
            Name = 'P2 Stamp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount = 1000
        );
        insert o;
        o = [SELECT Stage_Last_Changed__c, Previous_Stage__c FROM Opportunity WHERE Id = :o.Id];
        System.assertNotEquals(null, o.Stage_Last_Changed__c);
        System.assertEquals(null, o.Previous_Stage__c);
    }

    @isTest
    static void stageChangeUpdatesPreviousAndTimestamp() {
        Opportunity o = new Opportunity(
            Name = 'P2 Stamp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount = 1000
        );
        insert o;
        o.StageName = 'Qualification';
        update o;
        o = [SELECT StageName, Stage_Last_Changed__c, Previous_Stage__c FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Qualification', o.StageName);
        System.assertEquals('Prospecting', o.Previous_Stage__c);
        System.assertNotEquals(null, o.Stage_Last_Changed__c);
    }

    @isTest
    static void nonStageEditLeavesStampAlone() {
        Opportunity o = new Opportunity(
            Name = 'P2 Stamp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount = 1000
        );
        insert o;
        Datetime first = [SELECT Stage_Last_Changed__c FROM Opportunity WHERE Id = :o.Id].Stage_Last_Changed__c;
        o.Amount = 2000;
        update o;
        Opportunity after = [SELECT Stage_Last_Changed__c, Previous_Stage__c FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals(first, after.Stage_Last_Changed__c);
        System.assertEquals(null, after.Previous_Stage__c);
    }
}
