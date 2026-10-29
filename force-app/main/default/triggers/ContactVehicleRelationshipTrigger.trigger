trigger ContactVehicleRelationshipTrigger on Contact_Vehicle_Relationship__c (before insert, before update, before delete, after update) {
    // Security invariants deliberately do not honor Automation_Settings__c.Bypass_Triggers__c.
    if (Trigger.isDelete) {
        for (Contact_Vehicle_Relationship__c row : Trigger.old) row.addError('Reviewed entitlement history cannot be deleted.');
    } else if (Trigger.isBefore) {
        OwnerPortalOwnershipGuard.validate(Trigger.new, Trigger.oldMap);
    } else {
        OwnerPortalOwnershipGuard.revokeNativeAccess(Trigger.new, Trigger.oldMap);
    }
}
