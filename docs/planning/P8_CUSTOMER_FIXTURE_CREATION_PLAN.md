# Phase 8 customer fixture creation — exact authorized data scope

Owner authorizes exactly two new synthetic Account/Contact pairs in ng-demo
00Daj00001Ae3iWEAR. Verify active Standard/Salesforce owner 005aj00000gE0b3AAC, VP_Sales internal
role, effective Account Read and unique external-ID Seed_Tag fields before data DML.

| Pair | Account name / unique Seed_Tag | Contact name / unique Seed_Tag |
|---|---|---|
| A | Northgate Portal Test Customer A / P8-PORTAL-ACCOUNT-A | Northgate Portal Test Customer A / P8-PORTAL-CONTACT-A |
| B | Northgate Portal Test Customer B / P8-PORTAL-ACCOUNT-B | Northgate Portal Test Customer B / P8-PORTAL-CONTACT-B |

Both new Accounts and Contacts use the verified VP owner from initial insert. Contacts link
only to their corresponding new Account. Email, phone, addresses, Preferred_Rooftop and business
associations are not populated. No invitation or external User is created. P8-prefixed tags avoid
altering the existing SEED-% canonical identity envelope; no Data_Load_Batch record is added.

Execution helper: scripts/portal/create_customer_fixtures.py. Default --plan is read-only;
--apply is authorized here. Preflight rejects same-name collisions, partial/mismatched prior
fixtures or a changed owner. Four inserts use one native Composite REST request with
allOrNone=true, two Account POSTs and two Contact POSTs referencing those Account IDs.
There is no PATCH, upsert, update, delete, bypass flag or metadata operation.

Idempotence: exact unique external IDs are queried first. Complete matching existing fixtures
are reused without DML; partial/conflicting fixtures stop rather than overwrite or duplicate.
Native unique fields also prevent duplicate creation under a racing request. No automatic
write retry. On an unclear response, stop and inspect/read back; never blindly repost/delete.

Preservation: snapshot existing Account/Contact IDs, owner/parent/modification state and related
business-object fingerprints; compare after excluding only inserted fixture IDs. Verify zero
business/portal/territory relationships, exactly one Contact per new Account and unchanged
User role/profile/active/contact state. Capture native request/results and IDs in evidence/P8.
Rerun --apply once after success to prove the existing-fixture path issues zero inserts.

No external users, site creation/publication, explicit shares, permissions/roles/defaults,
Account transfers, deployment, Git release or ng-dev access. Any unexpected API failure or
preservation discrepancy stops affected work; no corrective business edits are authorized.
