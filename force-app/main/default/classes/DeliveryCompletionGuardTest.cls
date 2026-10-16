@isTest
private class DeliveryCompletionGuardTest {
    @TestSetup
    static void setup() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Profile repProfile = [SELECT Id FROM Profile WHERE Id = :UserInfo.getProfileId()];
            User rep = new User(
                Alias = 'delv',
                Email = 'arjun.ngdev+delv@northgate.demo',
                EmailEncodingKey = 'UTF-8',
                FirstName = 'Delivery',
                LastName = 'Guard',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = repProfile.Id,
                TimeZoneSidKey = 'America/New_York',
                UserName = 'arjun.ngdev+delv@northgate.demo'
            );
            insert rep;
            List<PermissionSet> ps = [
                SELECT Id FROM PermissionSet WHERE Name = 'PS_Sales_Rep'
            ];
            System.assert(ps.size() == 1, 'PS_Sales_Rep must exist');
            insert new PermissionSetAssignment(
                AssigneeId = rep.Id, PermissionSetId = ps[0].Id
            );
        }
    }

    private static User rep() {
        return [SELECT Id FROM User WHERE Username = 'arjun.ngdev+delv@northgate.demo' LIMIT 1];
    }

    private static Account makeAccount(String seed) {
        return P2TestDataFactory.makeAccount('DelVAcc' + seed);
    }

    private static Contact makeContact(Id accId, String last) {
        return P2TestDataFactory.makeContact(accId, last);
    }

    private static Opportunity makeOpp(Id accId) {
        Opportunity o = new Opportunity(
            Name = 'DelVOpp', StageName = 'Quoting',
            CloseDate = Date.today().addDays(15), AccountId = accId
        );
        insert o;
        return o;
    }

    private static Integer vehicleCounter = 0;
    private static Id makeVehicle() {
        vehicleCounter++;
        Vehicle_Model__c model = new Vehicle_Model__c(Name = 'DelVModel' + vehicleCounter);
        insert model;
        String vin = 'TESTVNDELV' + String.valueOf(10000000 + vehicleCounter).right(7);
        Vehicle__c v = new Vehicle__c(
            Vehicle_Model__c = model.Id, VIN__c = vin,
            Status__c = 'Available', Acquisition_Date__c = Date.today().addDays(-30)
        );
        insert v;
        return v.Id;
    }

    @isTest
    static void completedWithIncompleteChecklist_isBlockedByValidationRule() {
        Account acc = makeAccount('V1');
        Contact buyer = makeContact(acc.Id, 'V1');
        Opportunity opp = makeOpp(acc.Id);
        Delivery__c d = new Delivery__c(
            Opportunity__c = opp.Id, Buyer__c = buyer.Id, Vehicle__c = makeVehicle(),
            Status__c = 'Completed',
            Checklist_Documents__c = true, Checklist_Inspection__c = true,
            Checklist_Walkthrough__c = true, Checklist_Signature__c = false
        );
        Boolean threw = false;
        System.runAs(rep()) {
            try {
                insert d;
            } catch (DmlException e) {
                threw = true;
                System.assert(
                    e.getDmlMessage(0).contains('All four checklist items'),
                    'expected VR error: ' + e.getDmlMessage(0)
                );
            }
        }
        System.assert(threw, 'VR must block insert with incomplete checklist');
    }

    @isTest
    static void completedWithAllFourChecklist_succeeds() {
        Account acc = makeAccount('V2');
        Contact buyer = makeContact(acc.Id, 'V2');
        Opportunity opp = makeOpp(acc.Id);
        Delivery__c d = new Delivery__c(
            Opportunity__c = opp.Id, Buyer__c = buyer.Id, Vehicle__c = makeVehicle(),
            Status__c = 'Completed',
            Checklist_Documents__c = true, Checklist_Inspection__c = true,
            Checklist_Walkthrough__c = true, Checklist_Signature__c = true
        );
        System.runAs(rep()) {
            insert d;
        }
        Delivery__c inserted = [SELECT Id, Status__c FROM Delivery__c WHERE Id = :d.Id];
        System.assertEquals('Completed', inserted.Status__c, 'delivery inserted as Completed');
    }

    @isTest
    static void transitioningToCompletedWithoutChecklist_isBlockedByValidationRule() {
        Account acc = makeAccount('V3');
        Contact buyer = makeContact(acc.Id, 'V3');
        Opportunity opp = makeOpp(acc.Id);
        Delivery__c d = new Delivery__c(
            Opportunity__c = opp.Id, Buyer__c = buyer.Id, Vehicle__c = makeVehicle(),
            Status__c = 'Scheduled',
            Checklist_Documents__c = false, Checklist_Inspection__c = false,
            Checklist_Walkthrough__c = false, Checklist_Signature__c = false
        );
        System.runAs(rep()) {
            insert d;
            d.Status__c = 'Completed';
            Boolean threw = false;
            try {
                update d;
            } catch (DmlException e) {
                threw = true;
                System.assert(
                    e.getDmlMessage(0).contains('All four checklist items'),
                    'expected VR error: ' + e.getDmlMessage(0)
                );
            }
            System.assert(threw, 'VR must block update to Completed without full checklist');
        }
    }

    @isTest
    static void checklistCompleteFormula_isTrueWhenAllFour() {
        Account acc = makeAccount('V4');
        Contact buyer = makeContact(acc.Id, 'V4');
        Opportunity opp = makeOpp(acc.Id);
        Delivery__c d = new Delivery__c(
            Opportunity__c = opp.Id, Buyer__c = buyer.Id, Vehicle__c = makeVehicle(),
            Status__c = 'Scheduled',
            Checklist_Documents__c = true, Checklist_Inspection__c = true,
            Checklist_Walkthrough__c = true, Checklist_Signature__c = true
        );
        System.runAs(rep()) {
            insert d;
        }
        Delivery__c inserted = [SELECT Checklist_Complete__c FROM Delivery__c WHERE Id = :d.Id];
        System.assertEquals(true, inserted.Checklist_Complete__c, 'formula true when all four checked');
    }
}
