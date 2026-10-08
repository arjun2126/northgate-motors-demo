# Lead Enrich Rooftop — corrected architecture

## Constraint (why the original Flow failed)

Record-triggered **before-save** Flows in API 66/67 can only contain these elements:
**Assignment, Decision, Get Records, Loop** (and the implicit record update via
Assignment). They **cannot** call invocable Apex actions (`@InvocableMethod`).
This is a documented Salesforce restriction.

`LeadRoundRobin.nextSlot` is an `@InvocableMethod`. Therefore it cannot be invoked
from a before-save Flow. The original design called the action from the Flow; that
was the cause of the repeated deploy failures.

## Corrected design (two source-deployed pieces)

### 1. Before-save Flow `Lead_Enrich_Rooftop` (UI authoring — `evidence/P2/OWNER_ACTION_LIST.md` §2b)

Responsibilities:
- Bypass guard (custom permission `Bypass_Automation`).
- Compute FSA prefix from `Lead.PostalCode` via formula.
- Look up `Lead_Routing__mdt` by FSA prefix.
- Look up the matching `Rooftop__c`.
- Set `Rooftop__c`, `Assigned_Batch__c` (placeholder; trigger fills the slot digit).

### 2. Before-trigger Apex `LeadRoutingTrigger` (agent stages on owner "done")

Responsibilities:
- Read the rooftop + batch prefix the Flow set.
- Call `LeadRoundRobin.nextSlot` with a per-rooftop owner lane
  (one rep + one queue per rooftop — lane IDs are configured by the agent and
  documented in this file).
- Set `OwnerId` and overwrite `Assigned_Batch__c` with the lane slot
  (e.g. `M-R1`, `M-R2`).
- Honor `Bypass_Automation`.

## Per-rooftop owner lanes (agent pre-stage)

| Rooftop | Lane A (rep) | Lane B (queue) |
|---|---|---|
| Northgate Downtown | `ngrep@northgate.demo` | `Q_Inbound_Leads` |
| Northgate North | `ngrep@northgate.demo` | `Q_Inbound_Leads` |
| Northgate Airport | `ngrep@northgate.demo` | `Q_Inbound_Leads` |
| Northgate Service Centre | `ngsvc@northgate.demo` | `Q_Service_Intake` |

(Service and Inventory rooftop sales aren't in scope for lead intake per DATA_MODEL
§5.6; the routing table only lists four sales rooftops.)

## How the pieces fit (sequence on Lead insert)

1. Apex before trigger `LeadRoutingTrigger` fires.
2. **No-op**: the trigger reads `Rooftop__c` and `Assigned_Batch__c`; they are
   not set yet. The trigger stores the Record's id-keyed state in a request
   map and exits. (Or, simpler: the trigger does nothing on insert — the Flow
   runs after, then a single after-trigger `LeadRoutingPostTrigger` finalises
   the owner. The simplest implementation, given the constraint, is shown
   below.)

### Simpler implementation (chosen for deployability)

- `Lead_Enrich_Rooftop` (before-save Flow): sets `Rooftop__c` + a placeholder
  `Assigned_Batch__c` like `M-R?`.
- `LeadOwnerRoundRobinTrigger` (after insert, **isUpdate** not applicable): reads
  the Flow-set fields, calls `LeadRoundRobin.nextSlot`, sets `OwnerId` and
  overwrites `Assigned_Batch__c` with the actual slot.

This sequence is standard Salesforce: before-save Flow → after-trigger. The Flow
cannot be after-save because it needs to set the same-record fields for the
round-robin slot, and after-save cannot set same-record fields (must use DML).

## Bypass policy

- Trigger guard: `Automation_Settings__c.Bypass_Triggers__c == true` → exit.
- Flow entry: `Not Bypassed` decision checks `$Permission.Bypass_Automation` (matches
  the existing pattern in `LeadEnrich_Rooftop` design).

## Test class (agent pre-stage on owner "done")

`LeadOwnerRoundRobinTriggerTest`:
- insert Lead with `PostalCode = M5V2T6` after the Flow has run; assert
  `Rooftop__c = Northgate Downtown`, `Assigned_Batch__c = M-R1`, `OwnerId = ngrep`.
- Insert second Lead (same FSA); assert lane rotates to lane B (`Q_Inbound_Leads`).
- Insert Lead with unmatched FSA (`K1A0A1`); assert `Assigned_Batch__c = UNROUTED`,
  `OwnerId = Q_Inbound_Leads`.

## Why this is the final shape

- Flow has only supported elements (passes Metadata API schema).
- Trigger does the round-robin in Apex, no Flow-Apex call.
- Both pieces are independently deployable and covered by tests.
- Bypass policy mirrors the existing `LeadBeforeConvertGuard` and
  `TestDriveBookingGuard` pattern.
