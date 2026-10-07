# Phase 1 Step 1 — Org Clicks (ng-dev only)
Since the source deployment is not compatible with CLI 2.140.6, follow these Setup clicks in `ng-dev`:

## 1. Create 13 Custom Objects
In Setup → Objects → New Custom Object, create each object with the fields below. API Name must match exactly.

### Rooftop__c
- Fields: Name (Text 80, Name field), Address__c (Text 255), City__c (Text 80), Province__c (Picklist: ON, QC, BC, AB, MB), Postal_Code__c (Text 10), Type__c (Picklist: New_Sales, Used_Sales, Service_Center, Full_Service), General_Manager__c (Lookup User), Service_Capacity__c (Number 4,0), Is_Active__c (Checkbox), Vehicles_On_Hand__c (Number 6,0)
- Settings: Deactivate "Allow Reports" / "Allow Dashboards" if prompted

### Vehicle_Model__c
- Fields: Name (Text 80, Name field), Make__c (Picklist: Aurelia, Cascadia, Meridian, Vantage, Halcyon, Kestrel), Model__c (Text 40), Trim__c (Picklist: LX, EX, Sport, Limited, Premium), Body_Style__c (Picklist: Sedan, SUV, Hatchback, Truck, Coupe, Wagon), Base_MSRP__c (Currency), Fuel_Type__c (Picklist: Gasoline, Hybrid, EV, Diesel), Drivetrain__c (Picklist: FWD, RWD, AWD), Transmission__c (Picklist: Automatic, Manual, CVT), Segment__c (Picklist: Entry, Mainstream, Premium), Is_Active__c (Checkbox)

### Vehicle__c
- Fields: Name (Text 80, Name field), VIN__c (Text 17, Unique), Is_VIN_Valid__c (Checkbox), Model__c (Required Lookup → Vehicle_Model__c, NOT master-detail), Year__c (Number 4,0), Colour__c (Picklist: 10 values — single colour field), Status__c (Picklist: Available, Reserved, In_Appraisal, Sold, Delivered, In_Transit, On_Hold), List_Price__c (Currency), MSRP__c (Currency), Invoice_Cost__c (Currency), Acquisition_Date__c (Date), Inventory_Age_Days__c (Formula: TODAY() - Acquisition_Date__c), Is_Aged_60__c (FormulaCheckbox: Inventory_Age_Days__c > 60), Rooftop__c (Lookup → Rooftop__c), Lot_Stall__c (Text 10), Mileage_at_Intake__c (Number 7,0), Is_Demo_Unit__c (Checkbox), Reserved_By__c (Lookup → Contact), Reserved_On__c (DateTime), Seed_Tag__c (Text 80, External ID, Unique)
- Important: Do NOT select "Master-Detail" for Model__c — choose "Required Lookup" only. MD would cascade-delete vehicles and break rooftop sharing.

### Test_Drive__c
- Fields: Name (Text 80, Name field), Vehicle__c (Required Lookup → Vehicle__c), Contact__c (Required Lookup → Contact), Opportunity__c (Lookup → Opportunity), Rooftop__c (Lookup → Rooftop__c), Scheduled_Start__c (DateTime), Duration_Minutes__c (Number 3,0), Scheduled_End__c (Formula: Scheduled_Start__c + Duration), Status__c (Picklist: Requested, Scheduled, Completed, No_Show, Cancelled, Declined), Assigned_To__c (Lookup → User), Odometer_Start__c (Number 7,0), Odometer_End__c (Number 7,0), Route__c (Picklist: Urban, Highway, Mixed), Feedback__c (LongTextArea 1000), Customer_Score__c (Number 2,0), Purchase_Intent__c (Picklist: High, Medium, Low, None), Outcome__c (Picklist: No_Followup, Follow_Up_Scheduled, Converted, Lost), Seed_Tag__c (Text 80, External ID, Unique)

### Trade_In__c
- Fields: Name (Text 80, Name field), Opportunity__c (Required Lookup → Opportunity), Contact__c (Lookup → Contact), Trade_VIN__c (Text 17), Trade_Year__c (Number), Trade_Make__c (Picklist), Trade_Model__c (Text), Trade_Odometer__c (Number 7,0), Trade_Condition__c (Picklist: Excellent, Good, Fair, Poor), Has_Structural_Damage__c (Checkbox), Status__c (Picklist: Requested, Pending_Appraisal, Appraised, Accepted, Rejected, Withdrawn), Appraisal_Amount__c (Currency), Payoff_Amount__c (Currency), Trade_Equity__c (Formula: Appraisal_Amount__c - Payoff_Amount__c), Appraised_By__c (Lookup → User), Appraisal_Date__c (Date), Reconditioning_Cost__c (Currency), Wholesale_Value__c (Currency), Seed_Tag__c (Text 80, External ID, Unique)

### Financing__c
- Fields: Name (Text 80, Name field), Opportunity__c (Required Lookup → Opportunity), Applicant__c (Required Lookup → Contact), Co_Signer__c (Lookup → Contact), Vehicle__c (Lookup → Vehicle__c), Status__c (Picklist: Draft, Submitted, Conditional, Approved, Declined, Funded, Cancelled), Previous_Status__c (Picklist same values), Amount_Financed__c (Currency), Down_Payment__c (Currency), Term_Months__c (Number 3,0, Allowed values: 36, 48, 60, 72, 84, 96), Annual_Rate__c (Number 5,3, Percent e.g. 6.490), Credit_Tier__c (Picklist: A, B, C, D, Sub_Prime), Monthly_Payment__c (Currency), Total_Interest__c (Currency), Lender__c (Picklist: Northgate_Financial, Maple_Trust, Cascade_Credit_Union, Self_Funded), Application_Date__c (Date), Decision_Date__c (Date), Rate_Source__c (Picklist: Rate_Table, Manual_Exception), Exception_Reason__c (Text 255, FLS finance/manager), Funded_Date__c (Date), Payment_Calc_Help__c (Formula Text), Seed_Tag__c (Text 80, External ID, Unique)

### Delivery__c
- Fields: Name (Text 80, Name field), Opportunity__c (Required Lookup → Opportunity), Vehicle__c (Required Lookup → Vehicle__c), Buyer__c (Lookup → Contact), Status__c (Picklist: Scheduled, In_Progress, Completed, Postponed), Scheduled_Date__c (Date), Completed_Date__c (Date), Delivered_By__c (Lookup → User), Checklist_Documents__c (Checkbox), Checklist_Inspection__c (Checkbox), Checklist_Walkthrough__c (Checkbox), Checklist_Signature__c (Checkbox), Checklist_Complete__c (FormulaCheckbox: All four true), Accessories__c (Multi-select Picklist: Floor_Mats, Roof_Rack, Winter_Tires, Extended_Warranty), Customer_Notes__c (LongTextArea 1000), Seed_Tag__c (Text 80, External ID, Unique)

### Service_Visit__c
- Fields: Name (Text 80, Name field), Vehicle__c (Required Lookup → Vehicle__c), Contact__c (Required Lookup → Contact), Case__c (Lookup → Case), Rooftop__c (Lookup → Rooftop__c), Service_Type__c (Picklist: Oil_Change, Brakes, Tire_Change, Recall, Warranty_Repair, Diagnostics, Detailing, Inspection), Status__c (Picklist: Requested, Scheduled, Checked_In, In_Progress, Completed, No_Show, Cancelled), Scheduled_Start__c (DateTime), Duration_Minutes__c (Number 3,0), Advisor_Staff__c (Lookup → Staff__c), Technician_Staff__c (Lookup → Staff__c), RO_Number__c (Text 20), Mileage_At_Checkin__c (Number 7,0), Work_Performed__c (LongTextArea 2000), Labour_Hours__c (Number 4,1), Parts_Cost__c (Currency), Labour_Cost__c (Currency), Total_Cost__c (Formula: Parts_Cost__c + Labour_Cost__c), Is_Overdue__c (FormulaCheckbox: Status ≠ Completed/Cancelled/No_Show AND Scheduled_Start__c < NOW()), Days_Overdue__c (Formula: TODAY() - Scheduled_Start__c), CSI_Score__c (Number 2,0), Follow_Up_Required__c (Checkbox), Seed_Tag__c (Text 80, External ID, Unique)

### Loyalty_Member__c
- Fields: Name (Text 80, Name field), Contact__c (Required Lookup → Contact, one member per contact), Member_Number__c (Text 12, e.g. NG-8842-1039), Status__c (Picklist: Active, Suspended, Closed), Tier__c (Picklist: Bronze, Silver, Gold, Platinum), Points_Balance__c (Number 9,0), Lifetime_Points_Earned__c (Number 9,0), Lifetime_Points_Redeemed__c (Number 9,0), Lifetime_Spend__c (Currency), Join_Date__c (Date), Last_Activity_Date__c (Date), Tier_Evaluated_On__c (Date), Next_Tier_Threshold__c (Number 9,0), Has_Expiring_Points__c (FormulaCheckbox: Points_Balance__c < 0), Seed_Tag__c (Text 80, External ID, Unique)

### Loyalty_Transaction__c
- Fields: Name (Text 80, Name field), Member__c (Required MD → Loyalty_Member__c, cascade delete), Type__c (Picklist: Accrual, Redemption, Expiry, Adjustment, Bonus), Points__c (Number 8,0, Positive for accrual, negative for redemption/expiry), Reason__c (Picklist: Vehicle_Purchase, Service_Spend, Referral, Birthday, Promotion, Annual_Expiry, Manual_Adjustment), Source_Reference__c (Text 80), Transaction_Date__c (Date), Expiry_Date__c (Date), Is_Expired__c (FormulaCheckbox), Opportunity__c (Lookup → Opportunity), Service_Visit__c (Lookup → Service_Visit__c), Seed_Tag__c (Text 80, External ID, Unique)

### Consent__c
- Fields: Name (Text 80, Name field), Contact__c (Required Lookup → Contact), Channel__c (Picklist: Email, SMS, Phone, Mail), Purpose__c (Picklist: Marketing, Service_Notices, Recall_Alerts, Loyalty), Status__c (Picklist: Granted, Revoked, Expired), Granted_On__c (Date), Revoked_On__c (Date), Capture_Source__c (Picklist: Web_Form, In_Store, Service_Visit, Import), Evidence__c (Text 255), Seed_Tag__c (Text 80, External ID, Unique)

### Data_Load_Batch__c
- Fields: Name (Text 80, Name field), Batch_Number__c (Number 3,0, External ID), Seed_Version__c (Text 20), Object__c (Picklist), Inserted_Count__c (Number 6,0), Failed_Count__c (Number 6,0), Loaded_At__c (DateTime), Reset_At__c (DateTime), Status__c (Picklist: Loaded, Partial, Reset, Archived), Notes__c (LongTextArea 1000)

## 2. Create Automation_Settings__c Custom Setting
In Setup → Custom Settings → New, create "Automation Settings" (Hierarchy custom setting) with 3 custom fields:
- Bypass_Validation__c (Checkbox)
- Bypass_Flows__c (Checkbox)
- Bypass_Triggers__c (Checkbox)
- This is a Hierarchy custom setting used by all validation rules, flows, and triggers as the bypass guard.

## 3. Create Seed_Tag__c on Standard Objects
In Setup → Object Manager, for each standard object, create a Text(80) field named Seed_Tag__c:
- Check "External ID" and "Unique"
- UNcheck "Map during conversion" (on Lead/Contact/Opportunity)
- Add to relevant page layouts later

Standard objects needing Seed_Tag__c: Lead, Account, Contact, Opportunity, Case, Quote, QuoteLineItem, Product2, Campaign, CampaignMember, Task, Event

## 4. Create PS_Demo_Admin Permission Set
In Setup → Permission Sets → New, create "PS_Demo_Admin" (Custom Permissions Set):
- Object permissions for all 13 custom objects: Read + Edit on each
- Field-level security: Grant read/edit access to every new field including Seed_Tag__c on standard objects (on the FLS section of the permission set)
- Critical: Finance fields (Annual_Rate__c, Invoice_Cost__c, Exception_Reason__c, Appraisal_Amount__c) must be FLS-gated — visible only to PS_Finance_Officer and above, NOT PS_Sales_Rep

## 4. Assign PS_Demo_Admin to arjun.ngdev@northgate.demo
In Setup → Manage Users → Users, edit arjun.ngdev@northgate.demo → Add permission sets → Check PS_Demo_Admin → Save.

## 5. Verify Field Counts with Describe
In Setup → Object Manager, for each object, view the field list and confirm the count matches the data model:
- Vehicle__c: 22 custom fields + 1 standard (Name) = 23 total
- Financing__c: 23 custom fields + 1 standard (Name) = 24 total
- Service_Visit__c: 22 custom fields + 1 standard (Name) = 23 total

Or run in Anonymous Apex:
```java
System.describeSObject(Vehicle__c).getDescribe().getFields().size()
System.describeSObject(Financing__c).getDescribe().getFields().size()
System.describeSObject(Service_Visit__c).getDescribe().getFields().size()
```

## 6. Verify in the org
After clicking all above, run:
```bash
sf org list sobject --target-org ng-dev | grep -E "Vehicle__c|Financing__c|Service_Visit__c"
```

---
After completing all clicks, the build agent can proceed with verification. Tag the user when done.