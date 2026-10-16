@isTest
private class DeliveryCloseServiceTest {
    @TestSetup
    static void setup() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Profile repProfile = [SELECT Id FROM Profile WHERE Id = :UserInfo.getProfileId()];
            User rep = new User(
                Alias = 'delrep',
                Email = 'arjun.ngdev+delrep@northgate.demo',
                EmailEncodingKey = 'UTF-8',
                FirstName = 'Del',
                LastName = 'Rep',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = repProfile.Id,
                TimeZoneSidKey = 'America/New_York',
                UserName = 'arjun.ngdev+delrep@northgate.demo'
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
        return [SELECT Id FROM User WHERE Username = 'arjun.ngdev+delrep@northgate.demo' LIMIT 1];
    }

    private static Account makeAccount(String seed) {
        return P2TestDataFactory.makeAccount('DelAcc' + seed);
    }

    private static Contact makeContact(Id accId, String last) {
        return P2TestDataFactory.makeContact(accId, last);
    }

    private static Vehicle_Model__c makeModel(String seed) {
        return P2TestDataFactory.makeModel(seed);
    }

    private static Vehicle__c makeVehicle(Id modelId, String vin) {
        Vehicle__c v = new Vehicle__c(
            Vehicle_Model__c = modelId, VIN__c = vin, Status__c = 'Available',
            Acquisition_Date__c = Date.today().addDays(-30)
        );
        insert v;
        return v;
    }

    private static Opportunity makeOpportunity(Id accId, String name) {
        Opportunity opp = new Opportunity(
            Name = name, StageName = 'Quoting',
            CloseDate = Date.today().addDays(15), AccountId = accId
        );
        insert opp;
        return opp;
    }

    private static Delivery__c makeDelivery(Id oppId, Id buyerId, Id vehicleId, String status) {
        Delivery__c d = new Delivery__c(
            Opportunity__c = oppId, Buyer__c = buyerId, Vehicle__c = vehicleId,
            Status__c = status,
            Scheduled_Date__c = Date.today(),
            Checklist_Documents__c = false, Checklist_Inspection__c = false,
            Checklist_Walkthrough__c = false, Checklist_Signature__c = false
        );
        System.runAs(rep()) {
            insert d;
        }
        return d;
    }

    @isTest
    static void completingDelivery_setsOppClosedWonAndDeliveryCompletedFlag() {
        Account acc = makeAccount('D1');
        Contact buyer = makeContact(acc.Id, 'D1');
        Vehicle_Model__c model = makeModel('D1');
        Vehicle__c vehicle = makeVehicle(model.Id, 'DEL1DEL1DEL1DEL1A');
        Opportunity opp = makeOpportunity(acc.Id, 'DelOpp1');
        Delivery__c d = makeDelivery(opp.Id, buyer.Id, vehicle.Id, 'Scheduled');
        d.Checklist_Documents__c = true;
        d.Checklist_Inspection__c = true;
        d.Checklist_Walkthrough__c = true;
        d.Checklist_Signature__c = true;
        System.runAs(rep()) {
            d.Status__c = 'Completed';
            update d;
        }
        Opportunity finalOpp = [SELECT StageName, Delivery_Completed__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Closed Won', finalOpp.StageName, 'opp moved to Closed Won');
        System.assertEquals(true, finalOpp.Delivery_Completed__c, 'Delivery_Completed__c stamped true');
        Delivery__c finalDelivery = [SELECT Completed_Date__c FROM Delivery__c WHERE Id = :d.Id];
        System.assertEquals(Date.today(), finalDelivery.Completed_Date__c, 'Completed_Date__c stamped today');
    }

    @isTest
    static void completingDelivery_enrolsBuyerInLoyalty() {
        Account acc = makeAccount('D2');
        Contact buyer = makeContact(acc.Id, 'D2');
        Vehicle_Model__c model = makeModel('D2');
        Vehicle__c vehicle = makeVehicle(model.Id, 'DEL2DEL2DEL2DEL1A');
        Opportunity opp = makeOpportunity(acc.Id, 'DelOpp2');
        Delivery__c d = makeDelivery(opp.Id, buyer.Id, vehicle.Id, 'Scheduled');
        d.Checklist_Documents__c = true;
        d.Checklist_Inspection__c = true;
        d.Checklist_Walkthrough__c = true;
        d.Checklist_Signature__c = true;
        System.runAs(rep()) {
            d.Status__c = 'Completed';
            update d;
        }
        List<Loyalty_Member__c> members = [SELECT Id, Status__c, Tier__c, Points_Balance__c, Member_Number__c
            FROM Loyalty_Member__c WHERE Contact__c = :buyer.Id];
        System.assertEquals(1, members.size(), 'one loyalty member created');
        System.assertEquals('Active', members[0].Status__c, 'member is Active');
        System.assertEquals('Bronze', members[0].Tier__c, 'member starts at Bronze');
        System.assertEquals(0, members[0].Points_Balance__c, 'zero balance');
        System.assert(String.isNotBlank(members[0].Member_Number__c), 'member number assigned');
    }

    @isTest
    static void completingDelivery_incrementsContactLifetimeVehicles() {
        Account acc = makeAccount('D3');
        Contact buyer = makeContact(acc.Id, 'D3');
        Vehicle_Model__c model = makeModel('D3');
        Vehicle__c vehicle = makeVehicle(model.Id, 'DEL3DEL3DEL3DEL1A');
        Opportunity opp = makeOpportunity(acc.Id, 'DelOpp3');
        Delivery__c d = makeDelivery(opp.Id, buyer.Id, vehicle.Id, 'Scheduled');
        d.Checklist_Documents__c = true;
        d.Checklist_Inspection__c = true;
        d.Checklist_Walkthrough__c = true;
        d.Checklist_Signature__c = true;
        Integer before = ([SELECT Lifetime_Vehicles_Owned__c FROM Contact WHERE Id = :buyer.Id].Lifetime_Vehicles_Owned__c == null) ? 0 : Integer.valueOf([SELECT Lifetime_Vehicles_Owned__c FROM Contact WHERE Id = :buyer.Id].Lifetime_Vehicles_Owned__c);
        System.runAs(rep()) {
            d.Status__c = 'Completed';
            update d;
        }
        Integer after = ([SELECT Lifetime_Vehicles_Owned__c FROM Contact WHERE Id = :buyer.Id].Lifetime_Vehicles_Owned__c == null) ? 0 : Integer.valueOf([SELECT Lifetime_Vehicles_Owned__c FROM Contact WHERE Id = :buyer.Id].Lifetime_Vehicles_Owned__c);
        System.assertEquals(before + 1, after, 'lifetime vehicles incremented by 1');
    }

    @isTest
    static void completingDelivery_isIdempotent() {
        Account acc = makeAccount('D4');
        Contact buyer = makeContact(acc.Id, 'D4');
        Vehicle_Model__c model = makeModel('D4');
        Vehicle__c vehicle = makeVehicle(model.Id, 'DEL4DEL4DEL4DEL1A');
        Opportunity opp = makeOpportunity(acc.Id, 'DelOpp4');
        Delivery__c d = makeDelivery(opp.Id, buyer.Id, vehicle.Id, 'Scheduled');
        d.Checklist_Documents__c = true;
        d.Checklist_Inspection__c = true;
        d.Checklist_Walkthrough__c = true;
        d.Checklist_Signature__c = true;
        System.runAs(rep()) {
            d.Status__c = 'Completed';
            update d;
        }
        System.runAs(rep()) {
            d.Customer_Notes__c = 'Customer returned for follow-up note.';
            update d;
        }
        List<Loyalty_Member__c> members = [SELECT Id FROM Loyalty_Member__c WHERE Contact__c = :buyer.Id];
        System.assertEquals(1, members.size(), 'still one loyalty member after second update');
        Opportunity finalOpp = [SELECT StageName, Delivery_Completed__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Closed Won', finalOpp.StageName, 'stage remains Closed Won');
    }

    @isTest
    static void nonCompletedUpdate_doesNotCloseOpp() {
        Account acc = makeAccount('D5');
        Contact buyer = makeContact(acc.Id, 'D5');
        Vehicle_Model__c model = makeModel('D5');
        Vehicle__c vehicle = makeVehicle(model.Id, 'DEL5DEL5DEL5DEL1A');
        Opportunity opp = makeOpportunity(acc.Id, 'DelOpp5');
        Delivery__c d = makeDelivery(opp.Id, buyer.Id, vehicle.Id, 'Scheduled');
        d.Checklist_Documents__c = true;
        d.Checklist_Inspection__c = true;
        d.Checklist_Walkthrough__c = true;
        d.Checklist_Signature__c = true;
        System.runAs(rep()) {
            d.Status__c = 'In_Progress';
            update d;
        }
        Opportunity finalOpp = [SELECT StageName, Delivery_Completed__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertNotEquals('Closed Won', finalOpp.StageName, 'opp not closed when status not Completed');
        System.assertEquals(false, finalOpp.Delivery_Completed__c, 'Delivery_Completed__c not set');
        List<Loyalty_Member__c> members = [SELECT Id FROM Loyalty_Member__c WHERE Contact__c = :buyer.Id];
        System.assertEquals(0, members.size(), 'no loyalty enrol before Completed');
    }

    private static Delivery__c makeCompletedDeliveryNoBuyer(Id oppId, Id vehicleId) {
        Delivery__c d = new Delivery__c(
            Opportunity__c = oppId, Buyer__c = null, Vehicle__c = vehicleId,
            Status__c = 'Completed',
            Scheduled_Date__c = Date.today(),
            Checklist_Documents__c = true, Checklist_Inspection__c = true,
            Checklist_Walkthrough__c = true, Checklist_Signature__c = true
        );
        System.runAs(rep()) {
            insert d;
        }
        return d;
    }

    @isTest
    static void completedDeliveryWithBuyerAtCompletion_enrols() {
        Account acc = makeAccount('LB1');
        Contact buyer = makeContact(acc.Id, 'LB1');
        Vehicle_Model__c model = makeModel('LB1');
        Vehicle__c vehicle = makeVehicle(model.Id, 'DEL1DEL1DEL1DEL1A');
        Opportunity opp = makeOpportunity(acc.Id, 'DelLateOpp1');
        System.runAs(rep()) {
            Delivery__c d = new Delivery__c(
                Opportunity__c = opp.Id, Buyer__c = buyer.Id, Vehicle__c = vehicle.Id,
                Status__c = 'Completed',
                Scheduled_Date__c = Date.today(),
                Checklist_Documents__c = true, Checklist_Inspection__c = true,
                Checklist_Walkthrough__c = true, Checklist_Signature__c = true
            );
            insert d;
        }
        List<Loyalty_Member__c> members = [SELECT Id FROM Loyalty_Member__c WHERE Contact__c = :buyer.Id];
        System.assertEquals(1, members.size(), 'enrol on Status=Completed insert with Buyer set');
    }

    @isTest
    static void buyerAddedAfterCompletion_enrolsOnLateAssignment() {
        Account acc = makeAccount('LB2');
        Contact buyer = makeContact(acc.Id, 'LB2');
        Vehicle_Model__c model = makeModel('LB2');
        Vehicle__c vehicle = makeVehicle(model.Id, 'DEL2DEL2DEL2DEL2B');
        Opportunity opp = makeOpportunity(acc.Id, 'DelLateOpp2');
        Delivery__c d = makeCompletedDeliveryNoBuyer(opp.Id, vehicle.Id);
        System.assertEquals(0, [SELECT COUNT() FROM Loyalty_Member__c WHERE Contact__c = :buyer.Id], 'no enrol while Buyer null');
        System.runAs(rep()) {
            d.Buyer__c = buyer.Id;
            update d;
        }
        List<Loyalty_Member__c> members = [SELECT Id, Contact__c, Status__c, Tier__c, Points_Balance__c
            FROM Loyalty_Member__c WHERE Contact__c = :buyer.Id];
        System.assertEquals(1, members.size(), 'enrol on null->Buyer transition after Completed');
        System.assertEquals('Active', members[0].Status__c);
        System.assertEquals('Bronze', members[0].Tier__c);
        System.assertEquals(0, members[0].Points_Balance__c);
        Opportunity oppCheck = [SELECT StageName, Delivery_Completed__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Closed Won', oppCheck.StageName, 'opp already closed (not re-closed)');
    }

    @isTest
    static void repeatedUpdatesAfterCompletion_doNotDuplicateEnrolment() {
        Account acc = makeAccount('LB3');
        Contact buyer = makeContact(acc.Id, 'LB3');
        Vehicle_Model__c model = makeModel('LB3');
        Vehicle__c vehicle = makeVehicle(model.Id, 'DEL3DEL3DEL3DEL3C');
        Opportunity opp = makeOpportunity(acc.Id, 'DelLateOpp3');
        Delivery__c d = makeCompletedDeliveryNoBuyer(opp.Id, vehicle.Id);
        System.runAs(rep()) {
            d.Buyer__c = buyer.Id;
            update d;
        }
        System.runAs(rep()) {
            d.Customer_Notes__c = 'follow-up note';
            update d;
        }
        System.runAs(rep()) {
            d.Buyer__c = buyer.Id;
            update d;
        }
        Integer countMembers = [SELECT COUNT() FROM Loyalty_Member__c WHERE Contact__c = :buyer.Id];
        System.assertEquals(1, countMembers, 'still one member after repeated updates');
    }

    @isTest
    static void buyerReplacement_doesNotAutoEnrolNewBuyer() {
        Account acc = makeAccount('LB4');
        Contact buyerA = makeContact(acc.Id, 'LB4A');
        Contact buyerB = makeContact(acc.Id, 'LB4B');
        Vehicle_Model__c model = makeModel('LB4');
        Vehicle__c vehicle = makeVehicle(model.Id, 'DEL4DEL4DEL4DEL4D');
        Opportunity opp = makeOpportunity(acc.Id, 'DelLateOpp4');
        Delivery__c d = new Delivery__c(
            Opportunity__c = opp.Id, Buyer__c = buyerA.Id, Vehicle__c = vehicle.Id,
            Status__c = 'Completed',
            Scheduled_Date__c = Date.today(),
            Checklist_Documents__c = true, Checklist_Inspection__c = true,
            Checklist_Walkthrough__c = true, Checklist_Signature__c = true
        );
        System.runAs(rep()) {
            insert d;
        }
        Integer countA = [SELECT COUNT() FROM Loyalty_Member__c WHERE Contact__c = :buyerA.Id];
        System.assertEquals(1, countA, 'original Buyer enrolled');
        System.runAs(rep()) {
            d.Buyer__c = buyerB.Id;
            update d;
        }
        Integer countB = [SELECT COUNT() FROM Loyalty_Member__c WHERE Contact__c = :buyerB.Id];
        System.assertEquals(0, countB, 'replacement Buyer NOT auto-enrolled (requires review)');
        Integer countA2 = [SELECT COUNT() FROM Loyalty_Member__c WHERE Contact__c = :buyerA.Id];
        System.assertEquals(1, countA2, 'original member preserved');
    }
}
