public with sharing class InventoryReconciliationJob implements Queueable {
    private Set<Id> rooftopIds;

    public InventoryReconciliationJob(Set<Id> rooftopIds) {
        authorize();
        if (rooftopIds == null || rooftopIds.isEmpty() || rooftopIds.size() > 200 || rooftopIds.contains(null)) {
            throw new IllegalArgumentException('Provide between 1 and 200 Rooftop IDs.');
        }
        for (Id rooftopId : rooftopIds) {
            if (rooftopId.getSObjectType() != Rooftop__c.SObjectType) {
                throw new IllegalArgumentException('Only Rooftop IDs are supported.');
            }
        }
        this.rooftopIds = new Set<Id>(rooftopIds);
    }

    public void execute(QueueableContext context) {
        authorize();
        List<Vehicle__c> scope = new List<Vehicle__c>();
        for (Rooftop__c roof : [SELECT Id FROM Rooftop__c WHERE Id IN :rooftopIds WITH USER_MODE]) {
            scope.add(new Vehicle__c(Rooftop__c = roof.Id));
        }
        // ponytail: one bounded job, no chain/retry; split scopes explicitly if more than 200 rooftops are needed.
        VehicleCounters.maintain(scope, null);
    }

    private static void authorize() {
        if (!FeatureManagement.checkPermission('Bypass_Automation')
            || !Schema.sObjectType.Vehicle__c.isAccessible()
            || !Schema.sObjectType.Rooftop__c.isUpdateable()
            || !Schema.sObjectType.Rooftop__c.fields.Vehicles_On_Hand__c.isUpdateable()) {
            throw new SecurityException('Inventory maintenance requires authorized administrative access.');
        }
    }
}
