trigger LeadRoutingTrigger on Lead (before update, after insert, after update) {
    LeadTriggerHandler.run();
}
