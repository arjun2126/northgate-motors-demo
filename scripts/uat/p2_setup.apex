// Prepared only. Execute after explicit owner approval and rep activation.
Id expectedOrg = '00Daj00001Ae3iWEAR';
if (UserInfo.getOrganizationId() != expectedOrg) {
    throw new IllegalArgumentException('ng-demo only.');
}
User rep = [SELECT Id, UserRole.DeveloperName FROM User
    WHERE Username = 'ngpersona.ngdemo@northgate.demo' AND IsActive = true];
if (rep.UserRole == null || rep.UserRole.DeveloperName != 'Sales_Rep') {
    throw new IllegalArgumentException('Activate the approved Sales Rep persona first.');
}
String prefix = 'UAT-P2-20261020-';
if ([SELECT COUNT() FROM Lead WHERE Seed_Tag__c LIKE 'UAT-P2-20261020-%'] != 0) {
    throw new IllegalArgumentException('P2 fixtures already exist; do not duplicate or overwrite them.');
}
Automation_Settings__c settings = Automation_Settings__c.getOrgDefaults();
if (FeatureManagement.checkPermission('Bypass_Automation') ||
    (settings != null && (settings.Bypass_Triggers__c || settings.Bypass_Flows__c || settings.Bypass_Validation__c))) {
    throw new IllegalArgumentException('Disable bypass before Phase 2 UAT.');
}
String openStatus = [SELECT MasterLabel FROM LeadStatus WHERE IsConverted = false ORDER BY SortOrder LIMIT 1].MasterLabel;
List<String> postalCodes = new List<String>{'M5V2T6','M4C1B5','L4H1A1','L4H2R5','L5V1M5','L5V2N5','L1G1A1','L1G2H1','K2A9J1','P1B1A1'};
List<Lead> fixtures = new List<Lead>();
for (Integer i = 0; i < postalCodes.size(); i++) {
    fixtures.add(new Lead(LastName = 'P2 Buyer ' + (i + 1), Company = 'Fictional P2 Household ' + (i + 1),
        Email = 'p2.buyer.' + (i + 1) + '@northgate-demo.test', Phone = '4165550101',
        Country = 'Canada', State = 'Ontario', PostalCode = postalCodes[i],
        LeadSource = 'Web', Status = openStatus, OwnerId = rep.Id, Seed_Tag__c = prefix + (i + 1)));
}
insert fixtures;
List<Lead> observed = [SELECT Id, OwnerId, PostalCode, Rooftop__c, Assigned_Batch__c
    FROM Lead WHERE Id IN :fixtures ORDER BY Seed_Tag__c];
System.debug('P2_UAT_SETUP=' + JSON.serialize(observed));
