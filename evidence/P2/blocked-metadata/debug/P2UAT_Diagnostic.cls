@isTest
private class P2UAT_Diagnostic {
    @isTest
    static void fieldAccessAsNgrep() {
        User rep = [
            SELECT Id, Username, Profile.Name
            FROM User
            WHERE Username = 'ngrep@northgate.demo'
            LIMIT 1
        ];

        Map<String, Schema.SObjectField> fmap = Schema.SObjectType.Lead.fields.getMap();
        String[] names = new String[] { 'LastName', 'Company', 'PostalCode', 'Address', 'Status', 'Seed_Tag__c' };

        String report = '';
        System.runAs(rep) {
            for (String n : names) {
                Schema.DescribeFieldResult d = fmap.get(n).getDescribe();
                report += ' ' + n + '[create=' + d.isCreateable() + ' access=' + d.isAccessible() + ' type=' + d.getType() + ']';
            }

            // Use allOrNone=false so we can read field-level SaveResult errors
            Lead p = new Lead(LastName = 'Probe Postal', Company = 'Probe Co', PostalCode = 'M5V2T6');
            Database.SaveResult[] sr = Database.insert(new List<Lead>{ p }, false);
            String detail = '';
            for (Database.SaveResult r : sr) {
                if (!r.isSuccess()) {
                    for (Database.Error err : r.getErrors()) {
                        detail += ' statusCode=' + err.getStatusCode()
                            + ' message=' + err.getMessage()
                            + ' fields=' + (err.getFields() == null ? 'null' : String.join(err.getFields(), ','));
                    }
                }
            }
            System.assert(false, 'DIAG|user=' + rep.Username
                + '|profile=' + rep.Profile.Name
                + '|fields=' + report
                + '|saveResult=' + (detail == '' ? 'SUCCESS' : detail));
        }
    }
}
