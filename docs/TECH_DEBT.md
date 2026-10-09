# Tech Debt — known deliberate limitations

Recorded so each item is a visible decision rather than a hidden gap.

## Round-robin is per-transaction only

**Component:** `force-app/main/default/classes/LeadRoundRobin.cls` (+ handler use in `LeadRoutingHandler.onAfter`).

**Spec:** Backlog P2-01 says "round-robin within rooftop"; `DATA_MODEL` §8 documents `Lead.Assigned_Batch__c` as a "Round-robin audit" field.

**Current behaviour:** rotation state is a static map, so the lane index rotates only inside one
transaction. Sequential individual Lead saves each produce the same slot label (e.g.
Massachusetts to Northgate Vinyl gives `M-R1` on the first save and `M-R1` again on the next),
not the intended alternation.

**Not verified:** cross-transaction rotation. Do not record it as working.

**Fix options when prioritized:**
1. Custom counter object per rooftop updated under `SELECT ... FOR UPDATE`, so concurrent saves serialize.
2. Increment a stored counter in a hierarchy custom setting and fall back to queue on contention.

Option 1 is the safer pattern; option 2 is a bit of lazy and can be ready-only. If neither is scheduled,
frame it as an owner decision: state that the LFS routing is proven and only turnover-vs-queue
alternation across separate saves is unproven.

## Service visit slot overlap

**Components:** `ParkEscapeFlowConflictCheck.cls`, `TemptCheckPurchased.cls`.

**Limitation:** the desk-space query subflow (80% catch) is followed by a before-insert comparator,
but rival check is not executed in the checklist he test. two quick concurrent bookings can both show success.
Race window only. The existing cap coverage keeps the honest limitation visible.
EOF
