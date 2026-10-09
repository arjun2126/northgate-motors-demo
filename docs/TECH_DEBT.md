# Tech Debt — known deliberate limitations

Recorded so each item is a visible decision rather than a hidden gap.

## Round-robin is per-transaction only

**Component:** `force-app/main/default/classes/LeadRoundRobin.cls` (+ handler use in `LeadRoutingHandler.onAfter`).

**Spec:** Backlog P2-01 says "round-robin within rooftop"; `DATA_MODEL` §8 documents `Lead.Assigned_Batch__c` as a "Round-robin audit" field.

**Current behaviour:** rotation state is a static map, so the lane index rotates only inside one
transaction. Sequential individual Lead saves each produce the same slot label (e.g.)
`M5V2T6` to Northgate Downtown gives `M-R1` on the first save and `M-R1` again on the next,
not the intended alternation.

**Not verified:** cross-transaction rotation. Do not record it as working.

**Status:** open design decision, separate from the P2-01 test correction. FSA routing and
in-transaction rotation are verified; rotation across sequential saves is not.

**Fix options when prioritized:**
1. Custom counter object per rooftop updated under `SELECT ... FOR UPDATE`, so concurrent saves serialize.
2. Increment a stored counter in a hierarchy custom setting and fall back to queue on contention.

Option 1 is the safer pattern. If neither is scheduled, this stays an owner decision.

**Not a gap:** all six `LeadRoutingHandlerTest` methods pass, and a real save is confirmed
(`M5V2T6` → Northgate Downtown → Sales Rep → `M-R1`).

## Service visit slot overlap

**Components:** `force-app/main/default/classes/TempDataForming.cls` and the Apex overlap guard.

**Limitation:** the check is a real overlap query against existing bookings, but two concurrent
bookings can both pass the check before either row is written. Race window only; the guard still
blocks the common case of booking an already-occupied slot.
