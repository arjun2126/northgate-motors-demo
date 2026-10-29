# P6-03 final design — read-only evidence

Date: 2026-10-23. All Salesforce commands explicitly target ng-demo.
The blocks below are raw command-output excerpts; recommendations are in the final design
specification, not substituted for verification evidence. No credentials or customer data are included.

## CONFIRMED — target organization

Command: `sf data query --target-org ng-demo --query "SELECT Id FROM Organization" --json`

```json
"Id": "00Daj00001Ae3iWEAR"
```

## REFUTED — an existing staffed Service persona is available

Command:

```sh
sf data query --target-org ng-demo --query "SELECT Id, IsActive, Profile.Name, UserRole.DeveloperName FROM User WHERE Profile.Name = 'NG_Service' OR UserRole.DeveloperName IN ('Service_Manager','Service_Advisor','Service_Technician')" --json
```

```json
"records": [],
"totalSize": 0,
"done": true
```

## CONFIRMED — Service roles exist

Command:

```sh
sf data query --target-org ng-demo --query "SELECT Id, DeveloperName, ParentRoleId FROM UserRole WHERE DeveloperName IN ('Service_Manager','Service_Advisor','Service_Technician') ORDER BY DeveloperName" --result-format csv
```

```csv
Id,DeveloperName,ParentRoleId
00Eaj00000QCxlREAT,Service_Advisor,00Eaj00000QCxlJEAT
00Eaj00000QCxlJEAT,Service_Manager,00Eaj00000PlON3EAN
00Eaj00000QCxlKEAT,Service_Technician,00Eaj00000QCxlJEAT
```

## CONFIRMED — existing queue and membership boundary

Command:

```sh
sf data query --target-org ng-demo --query "SELECT Id, DeveloperName, Type, DoesIncludeBosses FROM Group WHERE Type = 'Queue' ORDER BY DeveloperName" --result-format csv
```

```csv
Id,DeveloperName,Type,DoesIncludeBosses
00Gaj00000ZYezlEAD,Q_Finance_Approvals,Queue,true
00Gaj00000ZYezmEAD,Q_Inbound_Leads,Queue,true
00Gaj00000ZYeznEAD,Q_Service_Intake,Queue,true
```

Commands:

```sh
sf data query --target-org ng-demo --query "SELECT GroupId, UserOrGroupId FROM GroupMember WHERE GroupId = '00Gaj00000ZYeznEAD'" --json
sf data query --target-org ng-demo --query "SELECT QueueId, SobjectType FROM QueueSobject ORDER BY QueueId, SobjectType" --json
```

```json
"GroupId": "00Gaj00000ZYeznEAD",
"UserOrGroupId": "00Gaj00000Zb1inEAB"
```

```json
"QueueId": "00Gaj00000ZYeznEAD",
"SobjectType": "Case"
```

Retrieved `queues/Q_Service_Intake.queue-meta.xml`, lines 3–9:

```xml
    <doesIncludeBosses>true</doesIncludeBosses>
    <doesSendEmailToMembers>false</doesSendEmailToMembers>
    <name>Service Intake</name>
    <queueMembers>
        <roles>
            <role>Service_Advisor</role>
        </roles>
```

## CONFIRMED — existing native recipient is an active administrator

Command:

```sh
sf data query --target-org ng-demo --query "SELECT Id, IsActive, Profile.Name, UserRoleId FROM User WHERE Id = '005aj00000feqbNAAQ'" --result-format csv
```

```csv
Id,IsActive,Profile.Name,UserRoleId
005aj00000feqbNAAQ,true,System Administrator,
```

The retrieved Standard action entries identify that existing administrator. Full unchanged
actions remain in `retrieved/p6_03_final_design/escalationRules/Case.escalationRules-meta.xml`.
No generated document needs to copy the user's name or email address.

## CONFIRMED — fresh metadata retrieval and source match

Command:

```sh
sf project retrieve start --target-org ng-demo --metadata "EscalationRules:Case" --metadata "Workflow:Case" --metadata "CustomField:Case.Escalated_On__c" --metadata "Queue:Q_Service_Intake" --output-dir "retrieved/p6_03_final_design" --json
```

```json
"id": "09Saj00000mZPWAEA4",
"status": "Succeeded",
"success": true
```

Command:

```sh
git diff --no-index -- "force-app/main/default/escalationRules/Case.escalationRules-meta.xml" "retrieved/p6_03_final_design/escalationRules/Case.escalationRules-meta.xml"
```

```text
(no output)
```

Retrieved `workflows/Case.workflow-meta.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>ChangePriorityToHigh</fullName>
        <field>Priority</field>
        <literalValue>High</literalValue>
        <name>Changes the case priority to high.</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
</Workflow>
```

## CONFIRMED — timestamp field and documented history event are available

Raw filtered JSON from `sf sobject describe --target-org ng-demo --sobject Case --json`:

```json
{
  "status": 0,
  "fields": [
    {"name": "IsEscalated", "type": "boolean", "calculated": false, "updateable": true},
    {"name": "Escalated_On__c", "type": "datetime", "calculated": false, "updateable": true}
  ]
}
```

Raw filtered JSON from `sf sobject describe --target-org ng-demo --sobject CaseHistory --json`:

```json
{
  "status": 0,
  "name": "CaseHistory",
  "queryable": true,
  "fields": [
    {"name": "CaseId", "type": "reference", "filterable": true, "picklistValues": []},
    {"name": "CreatedDate", "type": "datetime", "filterable": true, "picklistValues": []},
    {"name": "Field", "type": "picklist", "filterable": true, "picklistValues": ["ownerEscalated"]}
  ]
}
```

## REFUTED — an existing live escalation event can establish end-to-end behavior

Commands:

```sh
sf data query --target-org ng-demo --query "SELECT COUNT() FROM Case WHERE IsEscalated = true" --json
sf data query --target-org ng-demo --query "SELECT COUNT() FROM Case WHERE Escalated_On__c != null" --json
sf data query --target-org ng-demo --query "SELECT Id, CaseId, CreatedDate, Field FROM CaseHistory WHERE Field = 'ownerEscalated' ORDER BY CreatedDate ASC LIMIT 10" --json
```

Each result:

```json
"records": [],
"totalSize": 0,
"done": true
```

## Official platform evidence, inspected in the browser

- [EscalationRules / EscalationAction](https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/meta_escalationrules.htm):
  assignment, templates, minutes and notification fields; no field-update action. None is a
  valid businessHoursSource; CaseCreation is a valid escalationStartTime.
- [Escalation Actions](https://help.salesforce.com/s/articleView?id=service.rules_escalation_actions.htm&type=5):
  reassignment changes owner; notification recipients/templates are native actions.
- [Escalation Rule Entries](https://help.salesforce.com/s/articleView?id=service.rules_escalation_rule_entry.htm&type=5):
  first matching entry wins; Ignore business hours and creation/last-modified clock options.
- [CaseHistory](https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_casehistory.htm):
  read-only; ownerEscalated means the owner changed due to Case escalation. History does not
  expose the triggering escalation-rule identifier in the documented fields.
- [Triggers and Order of Execution](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_triggers_order_of_execution.htm):
  ordinary save sequencing; not proof of a timed native escalation callback.

These establish a supported design, not live native-timer acceptance or universally available
history for same-owner escalations. Browser documentation navigation succeeded after an
intermittent click timeout; no Salesforce record interaction occurred.

## Stopped query and owner action

Command attempted once:

```sh
sf data query --target-org ng-demo --use-tooling-api --query "SELECT Id, Name, Active FROM ApexTrigger WHERE TableEnumOrId = 'Case'" --json
```

Exact decisive error:

```text
ERROR at Row:1:Column:18
No such column 'Active' on entity 'ApexTrigger'.
```

No retry or source correction followed. No fresh Case-trigger inventory is claimed from that
attempt. Independent supported history/schema inspection continued. Last successful relevant
state: metadata retrieval 09Saj00000mZPWAEA4 and the describe/query results above.
No feature source changed; only the planning documents and retrieved local snapshot changed.

If a refreshed inventory is required, the owner can run this corrected read-only command or
authorize its execution; do not treat it as already run:

```sh
sf data query --target-org ng-demo --use-tooling-api --query "SELECT Id, Name, Status FROM ApexTrigger WHERE TableEnumOrId = 'Case'" --json
```

No feature tests, dry-run/check-only deployment, native timer test, record changes, security
changes, scheduling, staging, commit or push occurred during this planning task.

## CONFIRMED — local documentation whitespace checks and empty staging area

Commands:

```sh
git diff --check -- "DEMO_ORG_BACKLOG.md" "NORTHGATE_PROJECT_HANDOFF.md"
git diff --no-index --check -- /dev/null "docs/planning/P6_BATCH1_IMPLEMENTATION_PLAN_2026-10-23.md"
git diff --no-index --check -- /dev/null "docs/planning/P6_BATCH1_FINAL_DESIGN_AND_EXECUTION_SPEC_2026-10-23.md"
git diff --no-index --check -- /dev/null "docs/planning/P6_03_FINAL_DESIGN_EVIDENCE_2026-10-23.md"
git diff --cached --stat
```

Each command output:

```text
(no output)
```
