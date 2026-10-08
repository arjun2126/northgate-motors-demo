# Data Model — Northgate Motors

**Status:** PLANNING ONLY. No metadata exists yet. This document is the field-level contract
for the executing agent; any deviation should be recorded here first, then built.

Companions: `DEMO_ORG_MASTER_PLAN.md` (conventions §5, ledger §4), `DEMO_ORG_BACKLOG.md`,
`DEMO_ORG_SYNTHETIC_DATA_PLAN.md` (volumes and distributions).

---

## 1. Modelling principles

1. **Standard objects first.** Use Lead, Account, Contact, Opportunity, Case, Quote,
   QuoteLineItem, Product2, Pricebook2, Task, Event wherever they fit. Custom objects only where
   no standard object models the concept. This keeps the demo legible to reviewers and reduces
   maintenance in a permanent org.
2. **Custom objects are singular and `__c`.** No abbreviations that a reader must decode.
3. **Controlled picklists everywhere.** Free-text picklists break report grouping and reset.
4. **Every picklist API value is stable** (`Title_Case_With_Underscores`) — labels may change,
   API values must not, because seeded data depends on them.
5. **Formulas over derived Apex.** If a value can be a formula or roll-up, it is, so reports
   work without code.
6. **`Seed_Tag__c` on everything seeded** — one field name, External ID, Unique, not mapped
   during Lead conversion. This is the reset key and the upsert key.
7. **Finance fields are always permission-set-gated (FLS), never profile-gated.**

---

## 2. Object inventory

### 2.1 Standard objects in scope

| Object | Role in the demo | Notes |
|---|---|---|
| Lead | Inbound interest, qualification | Sources: Web, Walk-in, Referral, Event, Social, Phone |
| Account | Household, business/fleet, dealer partner | `Type` = `Household`, `Business`, `Dealer_Partner`. **Person Accounts intentionally NOT enabled** (see MASTER_PLAN §4.3) |
| Contact | Individual people within accounts | Buyer, co-signer, fleet manager, service contact |
| Opportunity | Retail/fleet deal in progress | Stage model below |
| Case | Support/service complaints | Record types `Service`, `Complaint`, `Warranty` |
| Quote | Simulated CPQ header | Standard object, enabled in Setup |
| QuoteLineItem | Quote detail lines | Master-detail to Quote (native) |
| Product2 | Trims, service packages, add-ons | Standard Price Book = CAD |
| Pricebook2 / PricebookEntry | Pricing basis | One active CAD price book |
| Campaign | Marketing/nurture simulation | Also used for consent-gated nurture |
| Task, Event | Follow-ups, appointments (light) | Auto-created by Flow |
| User, Role, PermissionSet | Security model | See §6 |
| Report / Dashboard | Analyst surface | Folders per MASTER_PLAN §6.2 |

### 2.2 Custom objects

| # | Object | Label | Purpose | Cardinality |
|---|---|---|---|---|
| 1 | `Rooftop__c` | Rooftop | Dealership location; supports territory, sharing, dashboards | Parent |
| 2 | `Vehicle_Model__c` | Vehicle Model | Make / model / trim reference | Reference for Vehicle (required lookup) |
| 3 | `Vehicle__c` | Vehicle | A single inventory unit (a VIN) | Core |
| 4 | `Test_Drive__c` | Test Drive | Booking, outcome, feedback | Detail to Vehicle/Opp |
| 5 | `Trade_In__c` | Trade-In | Appraisal, payoff, equity | Detail to Opportunity |
| 6 | `Financing__c` | Financing | Finance application, lender, terms | Detail to Opportunity |
| 7 | `Delivery__c` | Delivery | Handoff checklist and completion | Detail to Opportunity |
| 8 | `Service_Visit__c` | Service Visit | Scheduled service work (Field Service substitute) | Detail to Vehicle |
| 9 | `Loyalty_Member__c` | Loyalty Member | Membership, tier, balance | Parent |
| 10 | `Loyalty_Transaction__c` | Loyalty Transaction | Accrual / redemption / expiry | Child of Loyalty Member (MD) |
| 11 | `Consent__c` | Consent | Marketing/service consent record (privacy surface) | Detail to Contact |
| 12 | `Data_Load_Batch__c` | Data Load Batch | Seed-run ledger for reset/versioning | Independent |
| 13 | `Staff__c` | Staff | The 14 fictional staff members (rep/advisor/technician) — the reporting dimension that replaces 14 logins | Independent |

**13 custom objects.** Comfortably within any org's limits; deliberately kept under 15 so the
build stays maintainable.

> **Why `Staff__c`:** interactive logins are licence-bound (Stop B: 4 Salesforce +
> 6 Platform per org — see §6.1), but dashboards and reports must group by
> rep, advisor and technician. `Staff__c` holds the 14 people; only a handful of them
> correspond to real users. Lookups
> like `Opportunity.Sales_Staff__c` and `Service_Visit__c.Advisor_Staff__c` feed every
> staff-level report.

### 2.3 Custom metadata types and custom settings

| Type | Purpose | Example record |
|---|---|---|
| `Price_Rule__mdt` | CPQ simulation — discount/premium rules | `Loyalty_Gold_3pct` |
| `Rate_Table__mdt` | Credit tier + term → base rate mapping | `Tier_B_60` |
| `Loyalty_Tier__mdt` | Tier thresholds, accrual multipliers, expiry window | `Gold_50k` |
| `Lead_Routing__mdt` | Postal FSA prefix → rooftop routing table | `L4H_North` |

**4 custom metadata types.** Custom metadata deploys with the project (no data load, no
reset risk) and is reserved for *business* rules only.

| Custom setting | Purpose |
|---|---|
| `Automation_Settings__c` (hierarchy) | Automation bypass: `Bypass_Validation__c`, `Bypass_Flows__c`, `Bypass_Triggers__c` — paired with the `Bypass_Automation` custom permission (§9) |

Build flags live in the custom setting because a loader must flip them **per user, instantly,
without a deploy** — custom metadata would require a release for the same effect.

---

## 3. Field-level design

Legend: **Req** = required on create · **FLS** = permission-set gated · **MD** = master-detail ·
**L** = lookup.

### 3.1 `Rooftop__c`

| Field | API | Type | Notes |
|---|---|---|---|
| Name | `Name` | Auto Number or Text | e.g. `NG-DT Downtown` |
| Address | `Address__c` | Text(255) | |
| City | `City__c` | Text(80) | |
| Province | `Province__c` | Picklist | ON, QC, BC, AB, MB |
| Postal code | `Postal_Code__c` | Text(10) | Used for lead routing |
| Type | `Type__c` | Picklist | `New_Sales`, `Used_Sales`, `Service_Center`, `Full_Service` |
| General manager | `General_Manager__c` | Lookup(User) | |
| Service capacity/day | `Service_Capacity__c` | Number(4,0) | Drives appointment capacity |
| Is active | `Is_Active__c` | Checkbox | |
| Vehicles on hand | `Vehicles_On_Hand__c` | Number(6,0) | **Flow-maintained count** (Vehicle → Rooftop is a lookup, so no native roll-up) — see §5.3 |

### 3.2 `Vehicle_Model__c`

| Field | API | Type | Notes |
|---|---|---|---|
| Name | `Name` | Text(80) | Display: `Aurelia Solara EX` |
| Make | `Make__c` | Picklist | `Aurelia`, `Cascadia`, `Meridian`, `Vantage`, `Halcyon`, `Kestrel` |
| Model | `Model__c` | Text(40) | e.g. `Solara` |
| Trim | `Trim__c` | Picklist | `LX`, `EX`, `Sport`, `Limited`, `Premium` |
| Body style | `Body_Style__c` | Picklist | `Sedan`, `SUV`, `Hatchback`, `Truck`, `Coupe`, `Wagon` |
| Base MSRP | `Base_MSRP__c` | Currency(CAD) | |
| Fuel type | `Fuel_Type__c` | Picklist | `Gasoline`, `Hybrid`, `EV`, `Diesel` |
| Drivetrain | `Drivetrain__c` | Picklist | `FWD`, `RWD`, `AWD` |
| Transmission | `Transmission__c` | Picklist | `Automatic`, `Manual`, `CVT` |
| Segments | `Segment__c` | Picklist | `Entry`, `Mainstream`, `Premium` |
| Active | `Is_Active__c` | Checkbox | |
| Image path | `Image_Path__c` | Text(255) | Static-resource URL of the model photo, e.g. `/resource/NG_VehicleImages/aurelia_solara_ex.webp` — one AI-generated fictional webp (~50 KB) per model (~30), no logos (backlog P7-22) |

### 3.3 `Vehicle__c` (core)

| Field | API | Type | Notes |
|---|---|---|---|
| Name | `Name` | Auto Number | `VEH-0001` (VIN is a separate field) |
| VIN | `VIN__c` | Text(17) | **Unique field setting** + length/charset check via `VR_Vehicle_VIN17` |
| Is VIN valid | `Is_VIN_Valid__c` | Checkbox | Computed by Apex `VinValidator` (ISO 3779 mod-11 check digit + charset). Not a formula — the check digit exceeds formula size limits. |
| Model | `Vehicle_Model__c` | **Required Lookup → Vehicle_Model__c** | *Not* master-detail: MD would cascade-delete vehicles with a model, force OWD "Controlled by Parent", and take vehicle ownership away from the rooftop sharing model |
| Year | `Year__c` | Number(4,0) | Range 2015–2027 |
| Colour | `Colour__c` | Picklist | 10 values (`Black`, `White`, `Silver`, `Grey`, `Blue`, `Red`, `Green`, `Brown`, `Beige`, `Orange`) — the single colour field (a free-text twin was removed in v2) |
| Odometer | `Odometer__c` | Number(7,0) | km (Canada) |
| Condition | `Condition__c` | Picklist | `New`, `Certified_Pre-Owned`, `Used` |
| Status | `Status__c` | Picklist | `Available`, `Reserved`, `In_Appraisal`, `Sold`, `Delivered`, `In_Transit`, `On_Hold` |
| List price | `List_Price__c` | Currency(CAD) | |
| MSRP | `MSRP__c` | Currency(CAD) | From model |
| Invoice cost | `Invoice_Cost__c` | Currency(CAD) | **FLS: finance/manager only** |
| Acquisition date | `Acquisition_Date__c` | Date | New/used sourcing date |
| Inventory age | `Inventory_Age_Days__c` | Formula(Number) | `TODAY() - Acquisition_Date__c` |
| Is aged | `Is_Aged_60__c` | FormulaCheckbox | `Inventory_Age_Days__c > 60` |
| Rooftop | `Rooftop__c` | L → Rooftop__c | Where it physically sits |
| Lot stall | `Lot_Stall__c` | Text(10) | e.g. `D-14` |
| Mileage at intake | `Intake_Mileage__c` | Number(7,0) | |
| Is demo unit | `Is_Demo_Unit__c` | Checkbox | |
| Reserved by | `Reserved_By__c` | L → Contact | |
| Reserved on | `Reserved_On__c` | DateTime | |
| Seed tag | `Seed_Tag__c` | Text(80) | `SEED-03-VEH-0472`; **External ID, Unique** |
| Photo | `Photo__c` | Formula(Text) | `IMAGE(Vehicle_Model__r.Image_Path__c, "Vehicle photo")` — renders the model's image with no code on layouts and LWC (needs `Image_Path__c` populated, P7-22) |

**Indexes:** `VIN__c` (Unique), `Seed_Tag__c` (External ID, Unique).
**Enforcement:** `VR_Vehicle_VIN17` (length/charset), `VR_Vehicle_PriceFloor`;
duplicate VINs are impossible via the field's Unique setting — no cross-record validation
rule exists (VRs cannot query).

### 3.4 `Test_Drive__c`

| Field | API | Type | Notes |
|---|---|---|---|
| Name | `Name` | Auto Number | `TD-0001` |
| Vehicle | `Vehicle__c` | L → Vehicle__c | Required |
| Contact (driver) | `Contact__c` | L → Contact | Required |
| Opportunity | `Opportunity__c` | L → Opportunity | Optional (pre-opp bookings exist) |
| Rooftop | `Rooftop__c` | L → Rooftop__c | |
| Scheduled start | `Scheduled_Start__c` | DateTime | Required |
| Duration (min) | `Duration_Minutes__c` | Number(3,0) | Default 30 |
| Scheduled end | `Scheduled_End__c` | Formula(DateTime) | `Scheduled_Start__c + Duration` |
| Status | `Status__c` | Picklist | `Requested`, `Scheduled`, `Completed`, `No_Show`, `Cancelled`, `Declined` |
| Assigned to | `Assigned_To__c` | L → User | |
| Odometer start | `Odometer_Start__c` | Number(7,0) | Captured at handoff |
| Odometer end | `Odometer_End__c` | Number(7,0) | |
| Route | `Route__c` | Picklist | `Urban`, `Highway`, `Mixed` |
| Feedback | `Feedback__c` | LongTextArea(1000) | |
| Customer score | `Customer_Score__c` | Number(2,0) | 1–5 |
| Purchase intent | `Purchase_Intent__c` | Picklist | `High`, `Medium`, `Low`, `None` |
| Outcome | `Outcome__c` | Picklist | `No_Followup`, `Follow_Up_Scheduled`, `Converted`, `Lost` |
| Seed tag | `Seed_Tag__c` | Text(80) | **External ID, Unique** |

**Enforcement:** `VR_TestDrive_EndAfterStart` (single-record). Slot conflicts are **not** a
VR (they would need a cross-record query) — handled by the flow/Apex path in §5.5.

### 3.5 `Trade_In__c`

| Field | API | Type | Notes |
|---|---|---|---|
| Name | `Name` | Auto Number | `TI-0001` |
| Opportunity | `Opportunity__c` | L → Opportunity | Required |
| Contact (owner) | `Contact__c` | L → Contact | |
| Trade VIN | `Trade_VIN__c` | Text(17) | Can be blank for older vehicles |
| Year / Make / Model | `Trade_Year__c`, `Trade_Make__c`, `Trade_Model__c` | Number/Picklist/Text | |
| Odometer | `Trade_Odometer__c` | Number(7,0) | |
| Condition | `Trade_Condition__c` | Picklist | `Excellent`, `Good`, `Fair`, `Poor` |
| Structural issues | `Has_Structural_Damage__c` | Checkbox | |
| Status | `Status__c` | Picklist | `Requested`, `Pending_Appraisal`, `Appraised`, `Accepted`, `Rejected`, `Withdrawn` |
| Appraisal amount | `Appraisal_Amount__c` | Currency(CAD) | **FLS: manager/finance** |
| Payoff amount | `Payoff_Amount__c` | Currency(CAD) | Outstanding finance on trade |
| Trade equity | `Trade_Equity__c` | Formula(Currency) | `Appraisal_Amount__c - Payoff_Amount__c` — may be **negative** (designed edge case) |
| Appraised by | `Appraised_By__c` | L → User | |
| Appraisal date | `Appraisal_Date__c` | Date | |
| Reconditioning cost | `Reconditioning_Cost__c` | Currency(CAD) | |
| Wholesale value | `Wholesale_Value__c` | Currency(CAD) | |
| Seed tag | `Seed_Tag__c` | Text(80) | **External ID, Unique** |

**Enforcement:** no VR on `Trade_In__c` for the appraisal gate — an Opportunity-side VR cannot
query its child trade-ins. The gate is `Quote_Before_Create_Flow` (§5.6), which queries the
trade-in status and raises a screen error.

### 3.6 `Financing__c`

| Field | API | Type | Notes |
|---|---|---|---|
| Name | `Name` | Auto Number | `FIN-0001` |
| Opportunity | `Opportunity__c` | L → Opportunity | Required, one primary |
| Contact (applicant) | `Applicant__c` | L → Contact | Required |
| Co-signer | `Co_Signer__c` | L → Contact | Optional |
| Vehicle | `Vehicle__c` | L → Vehicle__c | |
| Status | `Status__c` | Picklist | `Draft`, `Submitted`, `Conditional`, `Approved`, `Declined`, `Funded`, `Cancelled` |
| Previous status | `Previous_Status__c` | Picklist (same values) | Maintained by `Financing_Status_Flow` so transition rules can be enforced by single-record VRs |
| Amount financed | `Amount_Financed__c` | Currency(CAD) | |
| Down payment | `Down_Payment__c` | Currency(CAD) | |
| Term (months) | `Term_Months__c` | Number(3,0) | Allowed values {36, 48, 60, 72, 84, 96} enforced by `VR_Financing_TermAllowed`. A Number (not a picklist) so the amortisation formula and payment calculator can use it arithmetically. |
| Annual rate | `Annual_Rate__c` | Number(5,3) | Percent, e.g. `6.490` |
| Credit tier | `Credit_Tier__c` | Picklist | `A`, `B`, `C`, `D`, `Sub_Prime` |
| Payment (monthly) | `Monthly_Payment__c` | Currency(CAD) | **Calculated** by `PaymentCalculatorService`, stored for reporting |
| Total interest | `Total_Interest__c` | Currency(CAD) | Stored calculation |
| Lender | `Lender__c` | Picklist | Invented: `Northgate Financial`, `Maple Trust`, `Cascade Credit Union`, `Self_Funded` |
| Application date | `Application_Date__c` | Date | |
| Decision date | `Decision_Date__c` | Date | |
| APR source | `Rate_Source__c` | Picklist | Business values `Rate_Table`, `Manual_Exception` |
| Exception reason | `Exception_Reason__c` | Text(255) | **FLS finance/manager** |
| Funded date | `Funded_Date__c` | Date | |
| Payment calc help | `Payment_Calc_Help__c` | Formula(Text) | Localized help text via Custom Label |
| Seed tag | `Seed_Tag__c` | Text(80) | **External ID, Unique** |

**FLS:** `Annual_Rate__c`, `Exception_Reason__c` and `Invoice_Cost__c`-adjacent finance
fields are invisible to `PS_Sales_Rep`.
**Enforcement:** `VR_Financing_RateRange` (0 ≤ rate ≤ 25), `VR_Financing_TermAllowed`,
`VR_Financing_TermRequired`, `VR_Financing_FundedRequiresApproved` (status history held in a
`Previous_Status__c` field maintained by the status-flow so the VR stays single-record).

### 3.7 `Delivery__c`

| Field | API | Type | Notes |
|---|---|---|---|
| Name | `Name` | Auto Number | `DLV-0001` |
| Opportunity | `Opportunity__c` | L → Opportunity | Required, unique-ish |
| Vehicle | `Vehicle__c` | L → Vehicle__c | Required |
| Contact (buyer) | `Buyer__c` | L → Contact | |
| Status | `Status__c` | Picklist | `Scheduled`, `In_Progress`, `Completed`, `Postponed` |
| Scheduled date | `Scheduled_Date__c` | Date | |
| Completed date | `Completed_Date__c` | Date | |
| Delivered by | `Delivered_By__c` | L → User | |
| Checklist — docs provided | `Checklist_Documents__c` | Checkbox | Registration, warranty booklet |
| Checklist — inspection done | `Checklist_Inspection__c` | Checkbox | |
| Checklist — features walkthrough | `Checklist_Walkthrough__c` | Checkbox | |
| Checklist — signature captured | `Checklist_Signature__c` | Checkbox | |
| Checklist complete | `Checklist_Complete__c` | FormulaCheckbox | All four true |
| Accessories included | `Accessories__c` | Multi-select Picklist | `Floor_Mats`, `Roof_Rack`, `Winter_Tires`, `Extended_Warranty` |
| Customer notes | `Customer_Notes__c` | LongTextArea(1000) | |
| Seed tag | `Seed_Tag__c` | Text(80) | **External ID, Unique** |

**Validation:** `VR_Delivery_ChecklistBeforeCompleted` (blocks `Completed` unless
`Checklist_Complete__c` is true).

### 3.8 `Service_Visit__c`

| Field | API | Type | Notes |
|---|---|---|---|
| Name | `Name` | Auto Number | `SV-0001` |
| Vehicle | `Vehicle__c` | L → Vehicle__c | Required |
| Contact (customer) | `Contact__c` | L → Contact | Required |
| Case | `Case__c` | L → Case | Optional linkage (entitlement milestones hang off the Case) |
| Rooftop | `Rooftop__c` | L → Rooftop__c | |
| Service type | `Service_Type__c` | Picklist | `Oil_Change`, `Brakes`, `Tire_Change`, `Recall`, `Warranty_Repair`, `Diagnostics`, `Detailing`, `Inspection` |
| Status | `Status__c` | Picklist | `Requested`, `Scheduled`, `Checked_In`, `In_Progress`, `Completed`, `No_Show`, `Cancelled` |
| Scheduled date/time | `Scheduled_Start__c` | DateTime | Required |
| Duration (min) | `Duration_Minutes__c` | Number(3,0) | |
| Advisor | `Advisor_Staff__c` | L → Staff__c | Staff, not User — only ~5 logins exist |
| Technician | `Technician_Staff__c` | L → Staff__c | |
| Repair order # | `RO_Number__c` | Text(20) | e.g. `RO-2026-0041` |
| Mileage at check-in | `Mileage_At_Checkin__c` | Number(7,0) | |
| Work performed | `Work_Performed__c` | LongTextArea(2000) | |
| Labour hours | `Labour_Hours__c` | Number(4,1) | |
| Parts cost | `Parts_Cost__c` | Currency(CAD) | |
| Labour cost | `Labour_Cost__c` | Currency(CAD) | |
| Total cost | `Total_Cost__c` | Formula(Currency) | `Parts + Labour` |
| Is overdue | `Is_Overdue__c` | FormulaCheckbox | `Status ≠ Completed/Cancelled/No_Show` AND `Scheduled_Start__c < NOW()` |
| Days overdue | `Days_Overdue__c` | Formula(Number) | For SLA reporting |
| CSI score | `CSI_Score__c` | Number(2,0) | 1–10 satisfaction |
| Follow-up required | `Follow_Up_Required__c` | Checkbox | |
| Seed tag | `Seed_Tag__c` | Text(80) | **External ID, Unique** |

**Enforcement:** `VR_ServiceVisit_FutureForNew` (single-record). Advisor/day capacity is
**not** a VR — it needs a count query — so it is enforced by the before-save flow
`ServiceVisit_EnforceCapacity` (§5.6), which compares the day's count against
`Rooftop__c.Service_Capacity__c`.

### 3.9 `Loyalty_Member__c`

| Field | API | Type | Notes |
|---|---|---|---|
| Name | `Name` | Auto Number | `LM-0001` |
| Contact | `Contact__c` | L → Contact | Required, one member per contact |
| Member number | `Member_Number__c` | Text(12) | External ID, e.g. `NG-8842-1039` |
| Status | `Status__c` | Picklist | `Active`, `Suspended`, `Closed` |
| Tier | `Tier__c` | Picklist | `Bronze`, `Silver`, `Gold`, `Platinum` |
| Points balance | `Points_Balance__c` | Number(9,0) | Maintained by engine |
| Lifetime points earned | `Lifetime_Points_Earned__c` | Number(9,0) | |
| Lifetime points redeemed | `Lifetime_Points_Redeemed__c` | Number(9,0) | |
| Lifetime spend | `Lifetime_Spend__c` | Currency(CAD) | |
| Join date | `Join_Date__c` | Date | |
| Last activity | `Last_Activity_Date__c` | Date | |
| Tier evaluated on | `Tier_Evaluated_On__c` | Date | Set by `LoyaltyTierEvalBatch` |
| Next tier threshold | `Next_Tier_Threshold__c` | Number(9,0) | Formula based on tier |
| Is expiring points | `Has_Expiring_Points__c` | Checkbox | |
| Seed tag | `Seed_Tag__c` | Text(80) | **External ID, Unique** |

**Validation:** `VR_Loyalty_NonNegativeBalance`.
**Roll-ups (from MD child):** `Points_Accrued__c`, `Points_Redeemed__c`, `Transaction_Count__c`.

### 3.10 `Loyalty_Transaction__c` (MD → Loyalty_Member__c)

| Field | API | Type | Notes |
|---|---|---|---|
| Name | `Name` | Auto Number | `LT-0001` |
| Member | `Loyalty_Member__c` | **MD → Loyalty_Member__c** | Required, cascade delete |
| Type | `Type__c` | Picklist | `Accrual`, `Redemption`, `Expiry`, `Adjustment`, `Bonus` |
| Points | `Points__c` | Number(8,0) | Positive for accrual, negative for redemption/expiry |
| Reason | `Reason__c` | Picklist | `Vehicle_Purchase`, `Service_Spend`, `Referral`, `Birthday`, `Promotion`, `Annual_Expiry`, `Manual_Adjustment` |
| Source record | `Source_Reference__c` | Text(80) | Stores the originating record's external ID (no polymorphic lookup — see §5.4) |
| Transaction date | `Transaction_Date__c` | Date | Required |
| Expiry date | `Expiry_Date__c` | Date | For accruals |
| Is expired | `Is_Expired__c` | FormulaCheckbox | |
| Related opportunity | `Opportunity__c` | L → Opportunity | When applicable |
| Related service | `Service_Visit__c` | L → Service_Visit__c | When applicable |
| Seed tag | `Seed_Tag__c` | Text(80) | **External ID, Unique** |

### 3.11 `Consent__c`

| Field | API | Type | Notes |
|---|---|---|---|
| Name | `Name` | Auto Number | `CONSENT-0001` |
| Contact | `Contact__c` | L → Contact | Required |
| Channel | `Channel__c` | Picklist | `Email`, `SMS`, `Phone`, `Mail` |
| Purpose | `Purpose__c` | Picklist | `Marketing`, `Service_Notices`, `Recall_Alerts`, `Loyalty` |
| Status | `Status__c` | Picklist | `Granted`, `Revoked`, `Expired` |
| Granted on | `Granted_On__c` | Date | |
| Revoked on | `Revoked_On__c` | Date | |
| Source | `Capture_Source__c` | Picklist | `Web_Form`, `In_Store`, `Service_Visit`, `Import` |
| Evidence text | `Evidence__c` | Text(255) | What the customer was shown |
| Seed tag | `Seed_Tag__c` | Text(80) | **External ID, Unique** |

**Validation:** `VR_Consent_RevokedRequiresDate`.

### 3.12 `Data_Load_Batch__c`

| Field | API | Type | Notes |
|---|---|---|---|
| Name | `Name` | Auto Number | `BATCH-001` |
| Batch number | `Batch_Number__c` | Number(3,0) | External ID |
| Seed version | `Seed_Version__c` | Text(20) | Mirrors `data/SEED_VERSION.txt` |
| Object | `Object__c` | Picklist | Object name |
| Inserted count | `Inserted_Count__c` | Number(6,0) | |
| Failed count | `Failed_Count__c` | Number(6,0) | |
| Loaded at | `Loaded_At__c` | DateTime | |
| Reset at | `Reset_At__c` | DateTime | When the batch was deleted |
| Status | `Status__c` | Picklist | `Loaded`, `Partial`, `Reset`, `Archived` |
| Notes | `Notes__c` | LongTextArea(1000) | |

This object is how the org self-reports which seed version it currently holds — critical for a
permanent environment where "which data am I looking at?" becomes ambiguous over time.

### 3.13 Custom metadata: `Price_Rule__mdt`

| Field | API | Type | Notes |
|---|---|---|---|
| Label | `Label` | Text | e.g. `Loyalty Gold discount` |
| Developer name | `DeveloperName` | Text | `Loyalty_Gold_3pct` |
| Rule type | `Rule_Type__c` | Picklist | `Discount`, `Premium`, `Rebate` |
| Target object | `Target__c` | Picklist | `Quote_Line`, `Vehicle` |
| Attribute | `Attribute__c` | Picklist | `Trim`, `Condition`, `Age_Days`, `Segment`, `Loyalty_Tier`, `Volume` |
| Operator | `Operator__c` | Picklist | `Equals`, `Greater_Than`, `Less_Than`, `In` |
| Value | `Value__c` | Text(40) | |
| Percent adjustment | `Percent_Adjustment__c` | Number(5,2) | Negative = discount |
| Fixed adjustment | `Fixed_Adjustment__c` | Currency(CAD) | |
| Priority | `Priority__c` | Number(3,0) | Lower runs first |
| Max applies per line | `Max_Applies__c` | Number(2,0) | Guards runaway stacking |
| Is active | `Is_Active__c` | Checkbox | |
| Description | `Description__c` | LongTextArea(1000) | |

**≥10 seeded metadata records.** Metadata deploys with the project — no data-load dependency.

### 3.14 Custom metadata: `Rate_Table__mdt`

| Field | API | Type | Notes |
|---|---|---|---|
| Credit tier | `Credit_Tier__c` | Picklist | `A` … `Sub_Prime` |
| Term | `Term_Months__c` | Number(3,0) | Same allowed values as `Financing__c.Term_Months__c` |
| Base rate | `Base_Rate__c` | Number(5,3) | Percent |
| Max LTV | `Max_LTV__c` | Number(5,2) | |
| Is active | `Is_Active__c` | Checkbox | |

### 3.15 `Staff__c`

The 14 fictional staff members. This object is what lets dashboards say "Dana sold 9 vehicles
this month" when only 5 logins exist.

| Field | API | Type | Notes |
|---|---|---|---|
| Name | `Name` | Text(80) | e.g. `Dana Whitfield` |
| Role | `Role__c` | Picklist | `Sales_Rep`, `Sales_Manager`, `Finance`, `Service_Advisor`, `Technician`, `Inventory` |
| Rooftop | `Rooftop__c` | L → Rooftop__c | |
| Active | `Is_Active__c` | Checkbox | |
| Hire date | `Hire_Date__c` | Date | |
| Linked user | `User__c` | L → User | **Optional** — populated only for the ≤5 staff who have real logins |
| User username | `Username__c` | Text(80) | Display convenience for the persona matrix |
| Is persona login | `Is_Persona_Login__c` | Checkbox | True for the 5 staff that correspond to real users |
| Seed tag | `Seed_Tag__c` | Text(80) | **External ID, Unique** |

Reports and dashboards group by `Staff__c` (via `Opportunity.Sales_Staff__c`,
`Service_Visit__c.Advisor_Staff__c`, `Service_Visit__c.Technician_Staff__c`), never by User.
The persona matrix in `docs/security/PERMISSION_MATRIX.md` maps each `Staff__c` row to either
a real login or "demonstrated via Login As with the persona's permission set group".

---

## 4. Seed tagging (reset key)

**One field, everywhere: `Seed_Tag__c`.** Standard and custom objects alike.

| Object family | Field properties | Constraint |
|---|---|---|
| All 13 custom objects | `Seed_Tag__c` Text(80) | **External ID + Unique**; value `SEED-<BATCH>-<CODE>-<NNNN>` |
| Standard objects (Lead, Account, Contact, Opportunity, Case) | `Seed_Tag__c` Text(80) | **External ID + Unique**; "Map during conversion" = **off** on every custom field |
| Quote / QuoteLineItem / OpportunityLineItem / Product2 / PricebookEntry | `Seed_Tag__c` Text(80) | External ID + Unique |
| Campaign, CampaignMember, Task, Event | `Seed_Tag__c` Text(80) | External ID + Unique |
| **Never tagged** | User, Role, PermissionSet, Queue, PublicGroup, Report, Dashboard, EmailTemplate, CustomMetadata, CustomSetting | Never deleted on reset |

Why one unified field: the loader issues a single command shape per object
(`sf data upsert bulk --external-id Seed_Tag__c`), the reset script filters on a single
predicate (`Seed_Tag__c LIKE 'SEED-%'`), and no future agent has to wonder which of two
external-ID fields is the real key. Uniqueness makes duplicate loads impossible even if the
upsert key were mis-set.

---

## 5. Relationship and integrity design

### 5.1 Relationship map

```
Rooftop__c ──< Vehicle__c ──┬──< Test_Drive__c
   │                         ├──< Service_Visit__c
   │                         ├──< Delivery__c
   │                         └──< Opportunity.Vehicle__c (lookup)
   ├──< Staff__c (staff assigned to rooftop)
   └──< Lead / Account.Preferred_Rooftop__c / Service_Visit__c

Vehicle_Model__c ──(required Lookup)──< Vehicle__c        ← NOT master-detail

Account ──< Contact ──┬──< Consent__c
   │                  ├──< Loyalty_Member__c ──< Loyalty_Transaction__c (MD)   ← only MD
   │                  └──< Service_Visit__c / Test_Drive__c (driver/customer)
   └──< Opportunity ──┬──< Trade_In__c
                      ├──< Financing__c
                      ├──< Delivery__c
                      ├──< Quote (standard) ──< QuoteLineItem (MD, native)
                      └──< Case ──< Entitlement/Milestone (standard)

Staff__c ──< Opportunity.Sales_Staff__c
        ──< Service_Visit__c.Advisor_Staff__c / Technician_Staff__c
```

`Staff__c` is the reporting dimension for staff-level analytics; `User` is only the login
mechanism for ≤6 interactive users (§6.1).

### 5.2 Cardinality decisions

| Relationship | Type | Rationale |
|---|---|---|
| `Loyalty_Transaction__c → Loyalty_Member__c` | **Master-Detail** | The **only** custom MD. Enables native roll-ups of points; cascade delete simplifies reset |
| `Vehicle__c → Vehicle_Model__c` | **Required Lookup** | v2 change: MD would cascade-delete vehicles when a model is retired, force OWD "Controlled by Parent" (contradicting §6.3), and strip vehicle ownership from the rooftop model. Model-level counts are Flow-maintained (§5.3) |
| `Vehicle__c → Rooftop__c` | Lookup | Physical location; vehicles are Public Read/Write across rooftops |
| `QuoteLineItem → Quote` | Master-Detail (native) | Standard Salesforce behaviour |
| `Trade_In__c → Opportunity__c` | Lookup, required | Allows historical re-parenting if needed |
| `Financing__c → Opportunity__c` | Lookup, required | One primary financing per deal |
| `Delivery__c → Opportunity__c` | Lookup, required | |
| `Loyalty_Member__c → Contact__c` | Lookup, required, one member per contact | Enforced by duplicate rule |
| `Staff__c → User__c` | Lookup, optional | Most staff have no login |

### 5.3 Counts and roll-ups — native vs maintained

Native roll-up summaries require **master-detail**, and Contact cannot hold roll-ups at all.
Every lookup-parent count below is therefore a **Flow- or Apex-maintained Number field**,
listed explicitly so nobody attempts an impossible roll-up.

**Native (MD only):**

| Roll-up | On | Over |
|---|---|---|
| `Points_Accrued__c` | `Loyalty_Member__c` | sum of `Points__c` where `Type__c = Accrual` |
| `Points_Redeemed__c` | `Loyalty_Member__c` | sum of \|`Points__c`\| where `Type__c = Redemption` |
| `Transaction_Count__c` | `Loyalty_Member__c` | count of Loyalty_Transaction__c |

**Flow-maintained (lookup parents):**

| Maintained field | On | Maintained by | Recomputes when |
|---|---|---|---|
| `Vehicles_On_Hand__c` | `Rooftop__c` | `Vehicle_Counter_Flow` | Vehicle insert/update/delete or status change |
| `Vehicles_Aged_60__c` | `Rooftop__c` | `Vehicle_Counter_Flow` + `Vehicle_Age_Scheduled` | Status/age change; nightly recompute |
| `Completed_Test_Drives__c` | `Vehicle_Model__c` | `TestDrive_Counter_Flow` | Test drive status change |
| `Open_Visits__c` | `Vehicle__c` | `ServiceVisit_Counter_Flow` | Service visit status change |
| `Service_Spend__c` | `Contact__c` | `ServiceVisit_Counter_Flow` | Visit completion |
| `Lifetime_Vehicles_Owned__c` | `Contact__c` | `Delivery_Close_Flow` | Delivery completion |
| `Completed_Test_Drives__c` (contact-level optional) | `Contact__c` | `TestDrive_Counter_Flow` | Status change |

Maintenance pattern: the counting flow runs on child change, re-queries the parent's count
with an efficient SOQL aggregate, and updates only the parent row. Every maintained field is
documented in the automation map (§5.6) and asserted in a test. Scheduled recompute
(`Vehicle_Age_Scheduled`) is the safety net if a bulk path misses an event.

### 5.4 Polymorphic lookup avoidance

Salesforce cannot create a polymorphic custom lookup (e.g. one field pointing at either an
Opportunity or a Case). Rather than build a junction object for loyalty sources, the design uses:

- `Source_Reference__c` (Text) storing the source record's external ID, **plus**
- two optional concrete lookups (`Opportunity__c`, `Service_Visit__c`).

This keeps reporting straightforward (real lookups group natively) and avoids the extra object.
A future agent may replace this with a junction object if the demo needs true polymorphic
reporting — noted as a deliberate simplification.

### 5.5 Conflict checking for slots

True double-booking prevention for test drives and service appointments is hard with Flow alone
because there is no native "overlap query across a time range with exclusive lock" without code.
The plan is:

1. Flow screen validates via SOQL overlap query (fast path, catches 95%).
2. Apex `@future`/before-save guard re-checks and raises an error on race (defence in depth).
3. If the race is not worth code, ship path 1 and document the limitation in
   `docs/TECH_DEBT.md` — an honest limitation is better than a false claim.

This is flagged so the executing agent does not over-build.

### 5.6 Automation map (what enforces what)

Global rule: **every** validation-rule formula begins with the bypass check
`AND(NOT($Permission.Bypass_Automation), …)`; every record-triggered flow's entry condition
checks `Automation_Settings__c.Bypass_Flows__c`; every trigger handler returns early when
`Bypass_Triggers__c` is set. Validation rules are never deployed disabled — the bypass is the
only escape hatch, and the loader flips it on and off around a load.

| Object | Before-save flow | After-save flow | Trigger / Apex | Validation rules (single-record) | Approval | Scheduled / batch |
|---|---|---|---|---|---|---|
| Lead | `Lead_Enrich_Rooftop` (FSA → rooftop via `Lead_Routing__mdt`) | `Lead_Create_Task` | — | `VR_Lead_EmailFormat` | — | — |
| Account | — | `Account_Counter_Flow` (optional) | — | — | — | — |
| Contact | — | `Contact_Counter_Flow`; duplicate rules `DR_Contact_Email` | — | — | — | — |
| Opportunity | `Opportunity_Check_TradeIn` (appraisal gate when quoting) | `Opportunity_Stage_Stamp` (`Stage_Last_Changed__c`, `Previous_Status__c`-style history), `Opportunity_Delivery_Flag` (sets `Delivery_Completed__c` from child deliveries) | — | `VR_Opportunity_AmountPositive`, `VR_Opportunity_LossReasonOnLost`, `VR_Opportunity_ClosedWonNeedsDelivery` (checks the maintained `Delivery_Completed__c` flag, not a child query) | `Opportunity_DiscountApproval` (>5% manager, >10% director) | — |
| Quote | `Quote_Before_Create_Flow` (queries trade-in status → blocks quote; sets `Delivery_Completed__c` untouched) | `Quote_Apply_PriceRules` (calls `QuotePricingService`) | — | `VR_Quote_NoQuoteWithoutOpp` | discount approval via parent | — |
| Case | — | `Case_Assign_Queue`, `Case_Stamp_Escalated_On__c` | — | — | — | `ER_Case_HighPriority_4h` (escalation rule) |
| `Vehicle__c` | `Vehicle_Validate_Vin` (calls `VinValidator`) | `Vehicle_Counter_Flow` (updates rooftop + model counters), `Vehicle_Reserve_Flow` | `VehicleTrigger → VehicleTriggerHandler` (bypass-guarded) | `VR_Vehicle_VIN17`, `VR_Vehicle_PriceFloor` | — | `Vehicle_Age_Scheduled` (recompute age counters) |
| `Test_Drive__c` | `TestDrive_Enforce_Slot` (overlap query — see §5.5) | `TestDrive_Counter_Flow` | — | `VR_TestDrive_EndAfterStart` | — | — |
| `Trade_In__c` | `TradeIn_Calc_Equity` | `TradeIn_Counter_Flow` | — | `VR_TradeIn_EquityInputs` | — | — |
| `Financing__c` | `Financing_Status_Flow` (writes `Previous_Status__c`, blocks invalid transitions) | `Financing_Calc_Flow` (calls `PaymentCalculatorService`) | — | `VR_Financing_RateRange`, `VR_Financing_TermAllowed`, `VR_Financing_TermRequired`, `VR_Financing_FundedRequiresApproved` | `Financing_ExceptionApproval` (sub-prime exceptions) | `Financing_RateRefresh_Scheduled` (optional) |
| `Delivery__c` | `Delivery_Block_Incomplete` | `Delivery_Close_Flow` (sets `Opportunity.StageName = Closed Won`, stamps `Delivery_Date__c`, updates `Contact.Lifetime_Vehicles_Owned__c`, enrolls loyalty) | — | `VR_Delivery_ChecklistBeforeCompleted` | — | — |
| `Service_Visit__c` | `ServiceVisit_EnforceCapacity` (advisor/day count vs `Rooftop__c.Service_Capacity__c`) | `ServiceVisit_Counter_Flow` (vehicle open-visit count, contact service spend) | — | `VR_ServiceVisit_FutureForNew` | — | `ServiceVisit_OverdueScan_Scheduled` (flags SLA breaches) |
| `Loyalty_Member__c` | — | `Loyalty_Tier_Flow` (thresholds from `Loyalty_Tier__mdt`) | — | `VR_Loyalty_NonNegativeBalance` | — | `LoyaltyTierEvalBatch`, `Loyalty_ExpiryBatch` |
| `Loyalty_Transaction__c` | `Loyalty_Txn_Balance_Flow` | roll-up recalculates natively (MD) | — | — | — | — |
| `Consent__c` | — | `Consent_Gate_Flow` (campaign membership) | — | `VR_Consent_RevokedRequiresDate` | — | — |
| `Staff__c` | — | — | — | — | — | — |

Rules of engagement:

1. A check that needs **only the record being saved** → validation rule.
2. A check that needs **other records** → before-save flow or before-trigger Apex
   (VRs cannot query).
3. A **derived value on another record** → after-save flow maintaining a field
   (§5.3), never a roll-up over a lookup.
4. Anything cross-record gets a test asserting both the pass and the block path.

---

## 6. Security model

### 6.1 Personas, licences and role hierarchy

**Stop B measured (per org): 4 Salesforce licences (2 used, 2 free), 6 Platform licences,
1 Integration licence** — recorded from the `UserLicense` query in `docs/VERIFY_RESULTS.md`;
re-confirmed at backlog P0-08. External Identity licences **[VERIFY P0-08]** (expect ≈5).

**Licence rule: Login As does not lift licence limits.** A Platform user cannot use
Opportunity, Lead, Case, Quote or Campaign — regardless of any permission set or sharing
granted. The design therefore puts **every standard-object persona demo on a Salesforce
licence**, and Platform users only on objects their licence allows.

| # | Persona | Username | Licence | Role | What it can demonstrate |
|---|---|---|---|---|---|
| 1 | Admin / presenter | `ngadmin@northgate.demo` | Salesforce | CEO | Everything; also the Login As origin for admin/Setup demos |
| 2 | Sales Rep | `ngrep@northgate.demo` | Salesforce | Sales Rep | **Real login:** lead → opportunity → quote, normal rep limits (`PSG_Rep`) |
| 3 | Service Advisor | `ngsvc@northgate.demo` | Salesforce | Service Advisor | **Real login:** Case, `Service_Visit__c`, Contact, service reports (`PSG_Service`) |
| 4 | **Persona Switcher** | `ngpersona@northgate.demo` | Salesforce | *swapped by script* | Role + permission-set-group swapped by `scripts/persona.sh <manager\|finance>` to demonstrate **Sales Manager** and **Finance Manager** security on one licence |
| 5 | Inventory Coordinator | `nginv@northgate.demo` | Platform | Inventory Coordinator | `Vehicle__c`, `Vehicle_Model__c`, `Rooftop__c`, `Staff__c` |
| 6 | Service Technician | `ngtech@northgate.demo` | Platform | Service Technician | `Service_Visit__c`, `Vehicle__c`, Account/Contact **read** |
| 7 | CI / DMS integration | `dms.integration@northgate.demo` | Integration | (outside tree) | JWT auth for pipelines only; no interactive login |

Seven accounts, six interactive logins — must all fit inside the measured ceilings
(4 Salesforce, 6 Platform). **P0-08 records the exact used/free split**; any shortfall hits
the shrink gate (fold a real login into Persona Switcher coverage) — never a licence
overrun.

`scripts/persona.sh` (backlog P1-21) swaps the Persona Switcher's role **and** assigns
exactly one of `PSG_Manager` / `PSG_Finance` at a time; it records the active persona in a
comment in the script log so demos are reproducible. It never touches users, licences or
profiles — only the switcher's role and permission set group assignments.

All interactive emails are real plus-addressed inboxes (activation requires deliverable
email); `dms.integration` uses a plus address for the same reason. Every dashboard that
groups by person uses `Staff__c`, not User (§3.15).

```
CEO                                     [ngadmin — Salesforce] ✓
├── VP Sales                            [empty — presentational]
│   ├── Sales Manager — Downtown        [~ persona switcher when manager]
│   │   └── Sales Rep                   [ngrep — Salesforce] ✓
│   ├── Sales Manager — North           [empty]
│   ├── Sales Manager — Airport         [empty]
│   └── Inventory Coordinator           [nginv — Platform] ✓
├── Finance Manager                     [~ persona switcher when finance]
└── Service Manager                     [empty]
    ├── Service Advisor                 [ngsvc — Salesforce] ✓
    └── Service Technician              [ngtech — Platform] ✓
```

✓ = fixed interactive user. ~ = the Persona Switcher occupying that role whenever
`scripts/persona.sh` selects it. Roles are kept as a full tree so sharing demos are
realistic; empty roles are deliberate (structure without wasting licences).

Persona demo matrix (which persona needs which PSG, and what each can see) lives in
`docs/security/PERMISSION_MATRIX.md`; every demo script opens with its "Activate persona"
step (master plan §10).

### 6.2 Permission sets and FLS

`PS_Sales_Rep` → `ngrep` and `PS_Service_Advisor` → `ngsvc` are assigned permanently as
`PSG_Rep` / `PSG_Service`; `PSG_Manager` / `PSG_Finance` are assigned to the **Persona
Switcher**, one active group at a time via `scripts/persona.sh`; the Admin holds
`PS_Demo_Admin` permanently.

| Permission set | Object grants | Critical FLS |
|---|---|---|
| `PS_Sales_Rep` | CRUD on Lead, Account, Contact, Opportunity, Quote, `Test_Drive__c`, `Trade_In__c`, `Vehicle__c` (read) | **No** access to `Financing__c.Annual_Rate__c`, `Vehicle__c.Invoice_Cost__c`, `Trade_In__c.Appraisal_Amount__c` (read-only on appraisal) |
| `PS_Sales_Manager` | Above + edit on appraisal, approve discounts | Read on financing, no edit |
| `PS_Finance_Officer` | Full on `Financing__c`, read on deals | Read on all pricing; edit rate/exception fields |
| `PS_Service_Advisor` | CRUD on Case, `Service_Visit__c`, `Vehicle__c` (read), Contact (read) | No opportunity/finance access |
| `PS_Demo_Admin` | Full + **`Bypass_Automation` custom permission** | Used for presenting, loading and resetting |
| `PS_Bypass_Load` | Custom permission `Bypass_Automation` only | Assigned to the loader admin for the duration of a load, then removed |

### 6.3 OWD recommendation

| Object | OWD | Reason |
|---|---|---|
| Account, Contact, Opportunity, Case, Lead | Private | Makes role hierarchy and sharing rules visible and demonstrable |
| Quote | Controlled by parent | Follows opportunity |
| `Vehicle__c` | Public Read/Write | Inventory is shared across rooftops by design |
| `Rooftop__c`, `Vehicle_Model__c` | Public Read/Write | Reference data |
| `Financing__c` | Private | Highest-sensitivity object |
| `Loyalty_*` | Public Read/Write | Low sensitivity, cross-team visibility |
| `Service_Visit__c` | Private | Service team scope |

### 6.4 Sharing rules (minimum set)

1. Sales Manager — Downtown can see Downtown reps' opportunities (role hierarchy already grants this).
2. Service Advisor can see Vehicle + Contact for any rooftop where a service visit exists (criteria-based sharing).
3. Finance can see all opportunities (role hierarchy above sales managers, or a direct sharing rule).
4. Cross-rooftop vehicle visibility (already via Public Read/Write) — keep, do not over-engineer.

### 6.5 Profiles (seamless-UX exception, default app + tabs only)

**Seamless UX rule (master plan §3.2-6):** each demo user lands directly in their own app
on login, with only the tabs that persona needs; every app has its own tab list and home
page.

**Narrow exception to the no-profile-edits rule:** small custom profiles hold **only two
settings** — the login **default app** and **tab visibility**. All object access, FLS and
record types stay in permission sets and permission set groups (§6.2). A profile never
grants access.

| Profile | Default app | Tab visibility (examples) | Assigned to |
|---|---|---|---|
| `NG_Admin` | `Northgate Admin` | full Admin tab set | `ngadmin` |
| `NG_Sales` | `Northgate Sales` | Leads, Opportunities, Quotes, Test Drives, Vehicles (read) | `ngrep`, `ngpersona` |
| `NG_Service` | `Northgate Service` | Cases, Service Visits, Contacts, Vehicles | `ngsvc`, `ngtech` |
| `NG_Inventory` | `Northgate Inventory` | Vehicles, Vehicle Models, Rooftops, Staff | `nginv` |

Apps: `Northgate Admin`, `Northgate Sales`, `Northgate Service`, `Northgate Inventory` —
each with its own tab list and its own home page (backlog P1-07). Profiles are deployed or
retrieved with care (never hand-edited beyond these two settings) and any profile change is
logged in `metadata-log/README.md`.

---

## 7. Opportunity stage model

Standard `StageName` picklist values, configured in Setup to exactly this set:

| API value | Label | Exit criteria |
|---|---|---|
| `Prospecting` | New | Lead converted |
| `Qualification` | Working | Needs, budget, timeline captured |
| `Test_Drive` | Test Drive | Test drive scheduled or completed |
| `Appraisal` | Appraisal | Trade-in appraised (if applicable) |
| `Quoting` | Quoting | Quote issued |
| `Financing` | Financing | Finance application submitted |
| `Closed Won` | Closed Won | Delivery completed |
| `Closed Lost` | Closed Lost | Loss reason recorded |

**Required on stage change:** Loss reason (`Loss_Reason__c`) when `Closed Lost`.
`Closed Won` requires a completed delivery — enforced by
`VR_Opportunity_ClosedWonNeedsDelivery`, which checks the **maintained** flag
`Delivery_Completed__c` (set by `Opportunity_Delivery_Flag` / `Delivery_Close_Flow` in §5.6),
because a validation rule cannot query child `Delivery__c` records.

Additional Opportunity fields:

| Field | API | Type |
|---|---|---|
| Seed tag | `Seed_Tag__c` | Text(80), External ID, Unique |
| Lead source | `LeadSource` | Standard picklist |
| Channel | `Channel__c` | Picklist: `Web`, `Walk_In`, `Referral`, `Event`, `Social`, `Phone` |
| Rooftop | `Rooftop__c` | L → Rooftop__c |
| Sales staff | `Sales_Staff__c` | L → Staff__c (staff-level reporting — §3.15) |
| Vehicle of interest | `Vehicle__c` | L → Vehicle__c |
| Has trade-in | `Has_Trade_In__c` | Checkbox |
| Discount percent | `Discount_Percent__c` | Number(5,2) |
| Approval status | `Approval_Status__c` | Picklist: `Not_Required`, `Pending`, `Approved`, `Rejected` |
| Loss reason | `Loss_Reason__c` | Picklist: `Price`, `Financing_Fell_Through`, `Competitor`, `No_Response`, `Timing`, `Trade_In_Value`, `No_Stock` |
| Stage last changed | `Stage_Last_Changed__c` | DateTime |
| Previous stage | `Previous_Stage__c` | Text(40) — maintained by `Opportunity_Stage_Stamp` |
| Days in stage | `Days_In_Stage__c` | Formula |
| Delivery completed flag | `Delivery_Completed__c` | Checkbox — **maintained**, checked by the Closed-Won VR |
| Probability | `Probability` | Standard |

---

## 8. Standard-object field additions

Every `Seed_Tag__c` below is **Text(80), External ID, Unique, "Map during conversion" off** —
one field shape across all standard objects (§4).

| Object | Added field | Type | Purpose |
|---|---|---|---|
| Lead | `Seed_Tag__c` | Text(80), ExtID, Unique | Reset / upsert |
| Lead | `Rooftop__c` | L → Rooftop__c | Routing result visibility |
| Lead | `Assigned_Batch__c` | Text(40) | Round-robin audit |
| Contact | `Seed_Tag__c` | Text(80), ExtID, Unique | Reset / upsert |
| Contact | `Household_Role__c` | Picklist: `Primary_Buyer`, `Co_Buyer`, `Fleet_Manager`, `Service_Contact` | Household modelling without Person Accounts |
| Contact | `Lifetime_Vehicles_Owned__c` | Number(3,0) — **flow-maintained** by `Delivery_Close_Flow` | Loyalty context |
| Account | `Seed_Tag__c` | Text(80), ExtID, Unique | Reset / upsert |
| Account | `Household_Size__c` | Number(2,0) | Household realism |
| Account | `Preferred_Rooftop__c` | L → Rooftop__c | |
| Opportunity | see §7 | includes `Seed_Tag__c`, `Sales_Staff__c`, `Delivery_Completed__c` | |
| Case | `Seed_Tag__c` | Text(80), ExtID, Unique | Reset / upsert |
| Case | `Service_Type__c` | Picklist | Aligns case with service |
| Case | `Escalated_On__c` | DateTime | Set by escalation rule |
| Case | `Vehicle__c` | L → Vehicle__c | Case-to-vehicle linkage |
| Quote | `Seed_Tag__c` | Text(80), ExtID, Unique | Reset / upsert |
| Quote | `Rule_Applied_Count__c` | Number(3,0) | CPQ simulation trace |
| Quote | `Prepared_By__c` | L → Staff__c | Staff, not User (§3.15) |
| Product2 | `Seed_Tag__c` | Text(80), ExtID, Unique | Reset / upsert |
| Product2 | `Category__c` | Picklist: `Vehicle_Trim`, `Service_Package`, `Accessory`, `Protection_Plan` | |

---

## 9. Data-quality validation rules (complete list)

| API name | Object | Rule |
|---|---|---|
| `VR_Vehicle_VIN17` | Vehicle__c | 17 chars, charset excludes I/O/Q, no spaces |
| `VR_Vehicle_PriceFloor` | Vehicle__c | `List_Price__c >= Invoice_Cost__c` (finance/manager can override via a flag field) |
| `VR_Lead_EmailFormat` | Lead | `Email` well-formed, always `.test`/`.example` domain |
| `VR_TestDrive_EndAfterStart` | Test_Drive__c | End > Start |
| `VR_TradeIn_EquityInputs` | Trade_In__c | `Payoff__c` and `Appraisal_Amount__c` required before `Status__c = Accepted` |
| `VR_Financing_RateRange` | Financing__c | 0 ≤ `Annual_Rate__c` ≤ 25 |
| `VR_Financing_TermAllowed` | Financing__c | `Term_Months__c` ∈ {36, 48, 60, 72, 84, 96} |
| `VR_Financing_TermRequired` | Financing__c | Term required when status ≠ Draft |
| `VR_Financing_FundedRequiresApproved` | Financing__c | Cannot set `Funded` unless `Previous_Status__c = Approved` (single-record via maintained field) |
| `VR_Delivery_ChecklistBeforeCompleted` | Delivery__c | All four checklist boxes required |
| `VR_ServiceVisit_FutureForNew` | Service_Visit__c | New visits: `Scheduled_Start__c` must be in the future |
| `VR_Loyalty_NonNegativeBalance` | Loyalty_Member__c | Balance ≥ 0 |
| `VR_Consent_RevokedRequiresDate` | Consent__c | Revoked → date required |
| `VR_Opportunity_AmountPositive` | Opportunity | Amount > 0 when stage not `Prospecting` |
| `VR_Opportunity_LossReasonOnLost` | Opportunity | Loss reason required when `Closed Lost` |
| `VR_Opportunity_ClosedWonNeedsDelivery` | Opportunity | `Closed Won` requires maintained flag `Delivery_Completed__c = TRUE` |
| `VR_Quote_NoQuoteWithoutOpp` | Quote | Opportunity required |

**17 rules — the complete set.** Deliberately absent, with the replacement:

| Absent because it needs a query | Replaced by |
|---|---|
| Unique VIN duplicate check | `VIN__c` **Unique field setting** (zero-query, load-safe) |
| Service visit advisor/day capacity | Before-save flow `ServiceVisit_EnforceCapacity` (§5.6) |
| Test-drive slot overlap | Flow/Apex path §5.5 |
| Trade-in appraisal gate on Opportunity | `Quote_Before_Create_Flow` (queries child trade-ins) |
| Household role defaults | Flow default, not a rule |

**Bypass policy (v2 — replaces the old `Demo_Config__mdt` guard):** VRs are **never deployed
disabled**. Every rule's formula begins with `AND(NOT($Permission.Bypass_Automation), …)`.
The loader admin is temporarily assigned the `Bypass_Automation` custom permission (via
`PS_Bypass_Load`) for the duration of a load, then it is removed. Flows and triggers honour
the same permission through `Automation_Settings__c` (§5.6). State changes are recorded in
`metadata-log/README.md` — but the preferred state is "bypass granted, then revoked", never
"rule edited".

---

## 10. Scale and limits check

| Metric | Planned | Comment |
|---|---|---|
| Custom objects | 13 (12 business + `Staff__c`) | Well within any org limit |
| Custom metadata types | 4 (`Price_Rule`, `Rate_Table`, `Loyalty_Tier`, `Lead_Routing`) | Deploys with metadata, no data-load risk |
| Custom settings | 1 (`Automation_Settings__c`, hierarchy) | Bypass switches for flows/triggers |
| Custom fields (total, est.) | ~200 | ~14 per custom object + standard-object additions |
| Apex classes (est.) | ~20 | See backlog P2/P4/P6/P7 |
| Flows (est.) | ~30 | Per §5.6 automation map |
| Validation rules | 17 | Complete list §9 |
| Permission sets | 6 (+4 groups) | §6.2 |
| Profiles | 4 (default app + tab visibility only) | §6.5 |
| Report folders | 6 | |
| Dashboard folders | 3 | 3 dynamic (limit: 3 of 10) + fixed dashboards |

If custom field counts approach org limits during the build, prefer reusing a field with a
record type over adding a near-duplicate.

---

## 11. Decisions log

| # | Decision | Outcome | Status |
|---|---|---|---|
| 7 | Loader: SF Data Miner (SFDMU) vs native `sf data upsert bulk` + `resolve.ts` | **Native `sf data upsert bulk` with external-ID relationship columns** (`Seed_Tag__c` on parents, parent `Seed_Tag__c` values in child CSVs — no `resolve.ts` ID pass needed); SFDMU remains an optional later upgrade, not a plan dependency | **CLOSED (v2.1)** |
| 8 | Dynamic dashboard limit | **3 dynamic dashboards** — confirmed in Salesforce Help; all others fixed-user | **CLOSED (v2.1)** |
| 9 | GitHub repository | **Private `arjun2126/northgate-motors-demo`, created by the owner with `gh`** — never by an agent, never with agent-handled tokens | **CLOSED (v2.1)** |

| # | Decision | Recommendation | Impact |
|---|---|---|---|
| 1 | Person Accounts vs `Account.Type = Household` | **Household via Type** (avoids one-way config) | Affects Contact/Account modelling everywhere |
| 2 | Multi-currency vs single CAD | **Single CAD** | Affects currency fields; must be set in Phase 0 |
| 3 | Visualforce vs LWC for quote PDF | **LWC + standard Quote PDF** | Affects P3-07 effort |
| 4 | Keep `Source_Reference__c` text field vs junction object | **Text field now**, junction later if needed | Affects P6-06 reporting |
| 5 | Experience Cloud site | **Yes, plan to build** — ~5 External Identity licences expected **[VERIFY P0-09]**; small real site | Affects P7-18 |
| 6 | Use standard `ServiceAppointment` if Field Service appears available | **Do not** unless verified free; keep custom `Service_Visit__c` for stability | Affects P6-01 |
