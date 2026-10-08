public class LeadRoundRobinRequest {
    @InvocableVariable(label='FSA Prefix' required=true)
    public String fsaPrefix;

    @InvocableVariable(label='Owner Ids' required=true)
    public List<String> ownerIds;
}
