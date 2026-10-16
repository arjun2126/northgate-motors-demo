# Permission Matrix — Northgate Motors demo org

Generated from `ng-dev` org state (2026-10-08). Permission sets are the only access-bearing
components; profiles carry only default app + tab visibility.

## Persona → role → permission set group mapping

| Persona | User | Role | Permission set group | Notes |
|---|---|---|---|---|
| Admin | arjun.ngdev@northgate.demo | — | PS_Demo_Admin | Permanent; also holds `Bypass_Automation` |
| Sales Rep | ngrep@northgate.demo | Sales_Rep | PSG_Rep | Created |
| Service Advisor | ngsvc@northgate.demo | Service_Advisor | PSG_Service | Created |
| Inventory Coordinator | nginv@northgate.demo | Inventory_Coordinator | — | Platform user, NG_Inventory profile |
| Service Technician | ngtech@northgate.demo | Service_Technician | — | Platform user, Standard Platform User profile |
| Integration | dms.integration@northgate.demo | — | — | API-only integration user |
| Sales Manager (switcher) | ngpersona@northgate.demo | Sales_Manager_Airport | PSG_Manager | **Pending**: blocked by OrgFarm EPIC licence slot |
| Finance Officer (switcher) | ngpersona@northgate.demo | Finance_Manager | PSG_Finance | **Pending**: same blocker |

## Object permissions (C=Create, R=Read, U=Update, D=Delete)

| Object | PS_Demo_Admin | PS_Sales_Rep | PS_Sales_Manager | PS_Finance_Officer | PS_Service_Advisor | PS_Bypass_Load |
|---|---|---|---|---|---|---|
| Account |  | CRUD | CRUD | R |  |  |
| Case |  |  |  |  | CRUD |  |
| Consent__c | CRUD |  |  |  |  |  |
| Contact |  | CRUD | CRUD | R | R |  |
| Data_Load_Batch__c | CRUD |  |  |  |  |  |
| Delivery__c | CRUD |  |  |  |  |  |
| Financing__c | CRUD |  | R | CRUD |  |  |
| Lead |  | CRUD | CRUD |  |  |  |
| Loyalty_Member__c | CRUD |  |  |  |  |  |
| Loyalty_Transaction__c | CRUD |  |  |  |  |  |
| Opportunity |  | CRUD | CRUD | R |  |  |
| Quote |  | CRUD | CRUD | R |  |  |
| Rooftop__c | CRUD |  |  |  |  |  |
| Service_Visit__c | CRUD |  |  |  | CRUD |  |
| Staff__c | CRUD |  |  |  |  |  |
| Test_Drive__c | CRUD | CRUD | CRUD |  |  |  |
| Trade_In__c | CRUD | CRUD | CRUD | R |  |  |
| Vehicle_Model__c | CRUD |  |  |  |  |  |
| Vehicle__c | CRUD | R | R | R | R |  |

## Sensitive field access checks

| Field | PS_Demo_Admin | PS_Sales_Rep | PS_Sales_Manager | PS_Finance_Officer | PS_Service_Advisor | PS_Bypass_Load |
|---|---|---|---|---|---|---|
| Financing__c.Annual_Rate__c | RU |  | R | RU |  |  |
| Vehicle__c.Invoice_Cost__c | RU |  |  | R |  |  |
| Trade_In__c.Appraisal_Amount__c | RU | R | RU | R |  |  |

## Role hierarchy and OWD

- Role tree: CEO → Service_Manager; CEO → Finance_Manager; CEO → VP_Sales → {Sales_Manager_Airport, Sales_Manager_Downtown, Sales_Manager_North, Sales_Rep}; CEO → Inventory_Coordinator; Service_Manager → Service_Advisor → Service_Technician.
- OWD: Account, Contact, Lead, Opportunity, Case = Private; Quote = ControlledByParent; Vehicle__c, Rooftop__c, Vehicle_Model__c = Public Read/Write; Financing__c, Service_Visit__c = Private; Loyalty_Member__c = Public Read/Write; Loyalty_Transaction__c = ControlledByParent (master-detail).
- Sharing: Contact read-only from All Internal Users to Service Manager and Service Advisor + subordinates.

## Phase 8 — external customer (portal) access model

**Status:** required design, not yet built. External portal users hold **no role**, so
role-based sharing does not apply. Access is **relationship-anchored** to the user's own
Contact/Account — `with sharing` alone is **not** sufficient (owner decision D6). Full design:
`docs/architecture/EXPERIENCE_PORTAL.md`; data-model requirement: `DEMO_ORG_DATA_MODEL.md` §6.6;
licence model pending verification (no assumption that External Identity suffices).

| Control | Requirement |
|---|---|
| Relationship | Each external user ↔ exactly one Contact/Account; every query filtered by that relationship |
| Sharing | Sharing Set where it supports the Account→object relationship; otherwise Apex managed sharing (`__Share`) — **do not assume Sharing Sets cover every custom object** |
| CRUD/FLS | Enforced in Apex (`Security.stripInaccessible` / `WITH SECURITY_ENFORCED` + CRUD checks) before query/DML |
| Sensitive fields | `Vehicle__c.Invoice_Cost__c`, `Financing__c.Annual_Rate__c`, `Trade_In__c.Appraisal_Amount__c` never exposed |
| Public R/W objects | `Vehicle__c`, `Loyalty_Member__c` **not** granted directly to external users; surfaced only via filtered Apex |
| Guest | Login-only portal; no unauthenticated customer data |
| Negative tests | Cross-customer `System.runAs` tests per exposed object must pass (read isolation + write isolation) |

**Permissions still to design (P8-02, after licence verification):** external profile,
`PS_Portal_Customer` permission set, external-user licence assignment within the measured count,
and the per-object sharing grants above. None of this exists yet.

---

## Known gaps / pending

- `ngpersona` created and `scripts/persona.sh` verified for manager and finance.
- 