public with sharing class TestDriveFollowUp {
    public static void onCreate(List<Test_Drive__c> scope) {
        if (scope == null || scope.isEmpty()) {
            return;
        }
        List<Task> tasks = new List<Task>();
        for (Test_Drive__c td : scope) {
            tasks.add(buildTask(td, 'Created'));
        }
        insert as system tasks;
        sendConfirmation(scope);
    }

    public static void onStatusChange(List<Test_Drive__c> scope, Map<Id, Test_Drive__c> oldById) {
        if (scope == null || scope.isEmpty()) {
            return;
        }
        List<Task> tasks = new List<Task>();
        List<Test_Drive__c> toConfirm = new List<Test_Drive__c>();
        for (Test_Drive__c td : scope) {
            Test_Drive__c old = (oldById == null) ? null : oldById.get(td.Id);
            if (old == null || old.Status__c == td.Status__c) {
                continue;
            }
            if (td.Status__c == 'Completed') {
                tasks.add(buildTask(td, td.Status__c));
            }
            if (td.Status__c == 'Scheduled' && old.Status__c != 'Scheduled') {
                toConfirm.add(td);
            }
        }
        if (!tasks.isEmpty()) {
            insert as system tasks;
        }
        if (!toConfirm.isEmpty()) {
            sendConfirmation(toConfirm);
        }
    }

    private static Task buildTask(Test_Drive__c td, String label) {
        Task t = new Task();
        t.Subject = 'Test drive: ' + label + ' ' + td.Id;
        t.ActivityDate = Date.today().addDays(1);
        t.Status = 'Not Started';
        t.Priority = 'Normal';
        t.Description = 'Auto-created by TestDriveFollowUp on ' + label + '.';
        if (td.Contact__c != null) {
            t.WhoId = td.Contact__c;
        }
        return t;
    }

    private static void sendConfirmation(List<Test_Drive__c> drives) {
        Set<Id> contactIds = new Set<Id>();
        for (Test_Drive__c td : drives) {
            if (td.Contact__c != null) {
                contactIds.add(td.Contact__c);
            }
        }
        if (contactIds.isEmpty()) {
            return;
        }
        // Authorize record access before reading notification-only fields in system mode.
        Set<Id> readableContactIds = new Map<Id, Contact>([
            SELECT Id FROM Contact WHERE Id IN :contactIds WITH USER_MODE
        ]).keySet();
        if (readableContactIds.isEmpty()) {
            return;
        }
        Map<Id, Contact> contacts = new Map<Id, Contact>([
            SELECT Id, Email, FirstName, LastName
            FROM Contact WHERE Id IN :readableContactIds WITH SYSTEM_MODE
        ]);
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        for (Test_Drive__c td : drives) {
            if (td.Contact__c == null) {
                continue;
            }
            Contact c = contacts.get(td.Contact__c);
            if (c == null || c.Email == null) {
                continue;
            }
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTargetObjectId(c.Id);
            mail.setSaveAsActivity(true);
            mail.setSubject('Your Northgate test drive is confirmed');
            mail.setPlainTextBody(
                'Hello ' + c.FirstName +
                ',\n\nYour test drive at ' + td.Scheduled_Start__c +
                ' is confirmed. Please bring a valid driver’s licence.\n\nNorthgate Motors'
            );
            mails.add(mail);
        }
        if (!mails.isEmpty()) {
            try {
                Messaging.sendEmail(mails);
            } catch (Exception e) {
                // Email deliverability may be set to System Only in DE; swallow without failing the save
            }
        }
    }
}
