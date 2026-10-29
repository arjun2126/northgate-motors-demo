/**
 * Northgate Motors — Phase 5 deterministic synthetic-data generator (P5-01).
 *
 * Reads ANCHOR_DATE and SEED_VERSION from data/SEED_VERSION.txt and writes the full
 * envelope of CSVs (per DEMO_ORG_SYNTHETIC_DATA_PLAN.md §2.1 and §4) to data/csv/.
 * Two runs with the same ANCHOR_DATE + SEED produce byte-identical output.
 *
 * Implementation notes:
 *  - Seeded PRNG (mulberry32) keyed by a stable string hash of the seed for determinism.
 *  - Fictional first/last name pools (~120 each) + reserved .test email domains.
 *  - ISO 3779 VIN generation (WMI NGD, deterministic VDS, mod-11 check digit).
 *  - Ontario-only postal codes (FSA prefixes M\*, L4H\*, L5V\*, L1G\*).
 *  - Phone numbers in the fictional 416/905/289 + 555-01xx block.
 *  - All dates spread over an 18-month rolling window ending at ANCHOR_DATE.
 *  - No real names, no real VINs, no deliverable emails, no external datasets.
 *
 * Usage:
 *   npm run data:generate            # writes data/csv/NN-*.csv
 *   ANCHOR_DATE=2026-10-01 npm run data:generate   # override (for tests)
 */

import { createHash } from 'node:crypto';
import { mkdirSync, writeFileSync, readFileSync, existsSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

import { NAMES, pickFirst, pickLast, makeEmail, makePhone, makePostal, makeStreet, makeCity, makeProvince } from '../fixtures/names.js';
import { mulberry32, stringHash, uuidFromSeed, dateRange } from './prng.js';
import { makeVin, vinValid } from './vin.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const REPO_ROOT = resolve(__dirname, '../..');
const DATA_DIR = resolve(REPO_ROOT, 'data');
// Isolated output supports determinism checks without replacing preserved CSVs.
const CSV_DIR = resolve(process.env.NG_GENERATOR_OUTPUT_DIR ?? resolve(DATA_DIR, 'csv'));
const SEED_VERSION_PATH = resolve(DATA_DIR, 'SEED_VERSION.txt');

// ---------- Configuration ----------

interface SeedConfig {
    seed: string;
    anchor: Date; // ANCHOR_DATE at midnight
}

function readSeedVersion(): SeedConfig {
    if (!existsSync(SEED_VERSION_PATH)) {
        throw new Error(`Missing ${SEED_VERSION_PATH}. Create SEED_VERSION.txt with ANCHOR_DATE=YYYY-MM-DD.`);
    }
    const raw = readFileSync(SEED_VERSION_PATH, 'utf8');
    const map: Record<string, string> = {};
    for (const line of raw.split(/\r?\n/)) {
        const m = line.match(/^([A-Z_][A-Z0-9_]*)=(.*)$/);
        if (m) map[m[1]] = m[2];
    }
    const anchorStr = process.env.ANCHOR_DATE ?? map.ANCHOR_DATE;
    if (!anchorStr) throw new Error('ANCHOR_DATE not set in SEED_VERSION.txt and not in env.');
    const seed = map.GENERATOR_SEED ?? `${anchorStr}-northgate-v1`;
    const anchor = new Date(`${anchorStr}T00:00:00Z`);
    if (isNaN(anchor.getTime())) throw new Error(`Invalid ANCHOR_DATE: ${anchorStr}`);
    return { seed, anchor };
}

// ---------- PRNG wrappers (namespace-scoped per call site) ----------

function rngFactory(seed: string, namespace: string) {
    return mulberry32(stringHash(`${seed}::${namespace}`));
}

function rngInt(rand: () => number, lo: number, hi: number): number {
    return lo + Math.floor(rand() * (hi - lo + 1));
}

function rngPick<T>(rand: () => number, arr: readonly T[]): T {
    return arr[Math.floor(rand() * arr.length)]!;
}

function rngBool(rand: () => number, pTrue = 0.5): boolean {
    return rand() < pTrue;
}

// ---------- Fictional company constants ----------

const MAKES = ['Aurelia', 'Cascadia', 'Meridian', 'Vantage', 'Halcyon', 'Kestrel'] as const;
const TRIMS = ['LX', 'EX', 'Sport', 'Limited', 'Premium'] as const;
const SEGMENTS = ['Entry', 'Mainstream', 'Premium'] as const;
const TRANSMISSIONS = ['Automatic', 'Manual', 'CVT'] as const;
const FUEL_TYPES = ['Gasoline', 'Hybrid', 'EV', 'Diesel'] as const;
const BODIES = ['Sedan', 'SUV', 'Hatchback', 'Truck', 'Coupe', 'Wagon'] as const;
const DRIVETRAINS = ['FWD', 'RWD', 'AWD'] as const;

const FSA_PREFIXES = [
    { fsa: 'M5V', city: 'Downtown' },
    { fsa: 'L4H', city: 'North' },
    { fsa: 'L5V', city: 'Airport' },
    { fsa: 'L1G', city: 'Service Centre' },
] as const;
const ROOFTOP_NAMES = ['Northgate Downtown', 'Northgate North', 'Northgate Airport', 'Northgate Service Centre'] as const;
const PROVINCES = ['ON', 'ON', 'ON', 'ON', 'ON', 'ON'] as const; // all Ontario per plan

const LENDERS = ['Northgate Financial', 'Maple Trust', 'Cascade Credit Union', 'Self_Funded'] as const;
const CREDIT_TIERS = ['A', 'B', 'C', 'D', 'Sub_Prime'] as const;
const RATE_SOURCES = ['Rate_Table', 'Manual_Exception'] as const;
const OPPORTUNITY_STAGES = ['Prospecting', 'Qualification', 'Test_Drive', 'Appraisal', 'Quoting', 'Financing', 'Closed Won', 'Closed Lost'] as const;
const OPPORTUNITY_STAGE_COUNTS: Record<string, number> = {
    Prospecting: 10, Qualification: 12, Test_Drive: 12, Appraisal: 9, Quoting: 11, Financing: 11, 'Closed Won': 12, 'Closed Lost': 23,
};
const LEAD_STATUSES = ['Open', 'Working', 'Qualified', 'Unqualified'] as const;
const LEAD_STATUS_COUNTS = { Open: 45, Working: 32, Qualified: 28, Unqualified: 25 } as const;
const LEAD_SOURCES = ['Web', 'Walk_In', 'Referral', 'Social', 'Event', 'Phone'] as const;
const LEAD_SOURCE_WEIGHTS: Record<string, number> = { Web: 35, Walk_In: 20, Referral: 15, Social: 15, Event: 10, Phone: 5 };

const VEHICLE_STATUSES = ['Available', 'Reserved', 'Sold', 'Delivered', 'In_Appraisal', 'In_Transit', 'On_Hold'] as const;
const VEHICLE_STATUS_COUNTS: Record<string, number> = {
    Available: 70, Reserved: 14, Sold: 18, Delivered: 8, In_Appraisal: 5, In_Transit: 3, On_Hold: 2,
};
const VEHICLE_CONDITIONS = ['New', 'Certified_Pre-Owned', 'Used'] as const;
const VEHICLE_CONDITION_WEIGHTS: Record<string, number> = { New: 45, 'Certified_Pre-Owned': 25, Used: 30 };

const DELIVERY_STATUSES = ['Scheduled', 'In_Progress', 'Completed', 'Postponed'] as const;
const FINANCING_STATUSES = ['Draft', 'Submitted', 'Conditional', 'Approved', 'Declined', 'Funded', 'Cancelled'] as const;

const TESTDRIVE_STATUSES = ['Requested', 'Scheduled', 'Completed', 'No_Show', 'Cancelled', 'Declined'] as const;
const TESTDRIVE_STATUS_COUNTS = { Requested: 0, Scheduled: 20, Completed: 30, No_Show: 12, Declined: 5, Cancelled: 3 } as const;
const TESTDRIVE_OUTCOMES = ['No_Followup', 'Follow_Up_Scheduled', 'Converted', 'Lost'] as const;

const SERVICE_STATUSES = ['Requested', 'Scheduled', 'Checked_In', 'In_Progress', 'Completed', 'No_Show', 'Cancelled'] as const;
const SERVICE_STATUS_COUNTS = { Requested: 8, Scheduled: 35, Checked_In: 10, In_Progress: 8, Completed: 70, No_Show: 5, Cancelled: 4 } as const;

const CASE_STATUSES = ['New', 'Working', 'Escalated', 'Closed'] as const;
const CASE_PRIORITIES = ['Low', 'Normal', 'High'] as const;

// Fixture counts required by the data plan §9b demo findings. Each is applied
// per status, never with a global row counter, so the count is reproducible.
const SERVICE_OVERDUE_COUNT = 12;        // BAD-04: past, still Scheduled
const VEHICLE_AGED_120_COUNT = 12;        // BAD-06: aged over 120 days
const VEHICLE_AGED_60_EXTRA_COUNT = 3;    // §2.2: ~15 aged over 60 days

const LOYALTY_TIERS = ['Bronze', 'Silver', 'Gold', 'Platinum'] as const;
const LOYALTY_TIER_COUNTS = { Bronze: 39, Silver: 18, Gold: 9, Platinum: 4 } as const;

const CONSENT_PURPOSES = ['Marketing', 'Service_Notices', 'Recall_Alerts', 'Loyalty'] as const;
const CONSENT_CHANNELS = ['Email', 'SMS', 'Phone', 'Mail'] as const;
const CONSENT_STATUSES = ['Granted', 'Revoked', 'Expired'] as const;

const QUOTE_STATUSES = ['Draft', 'Presented', 'Accepted', 'Denied', 'Rejected'] as const;

// ---------- Count helpers (override these for tests) ----------

function n(rand: () => number, k: number) { return rngInt(rand, 0, k - 1); }

function takeN<T>(rand: () => number, pool: T[], k: number, max = pool.length): T[] {
    const arr = pool.slice();
    const out: T[] = [];
    for (let i = 0; i < k && arr.length > 0 && i < max; i++) {
        const idx = Math.floor(rand() * arr.length);
        out.push(arr.splice(idx, 1)[0]!);
    }
    return out;
}

// ---------- CSV writer (quote, escape) ----------

function csvEscape(v: unknown): string {
    if (v == null) return '';
    const s = String(v);
    if (s.includes(',') || s.includes('"') || s.includes('\n') || s.includes('\r')) {
        return `"${s.replace(/"/g, '""')}"`;
    }
    return s;
}

function writeCsv(path: string, header: readonly string[], rows: ReadonlyArray<Record<string, unknown>>): void {
    mkdirSync(dirname(path), { recursive: true });
    const lines: string[] = [header.map(csvEscape).join(',')];
    for (const r of rows) {
        lines.push(header.map((h) => csvEscape(r[h])).join(','));
    }
    const content = lines.join('\n') + '\n';
    writeFileSync(path, content, 'utf8');
}

// ---------- Helpers ----------

function isoDate(d: Date): string { return d.toISOString().slice(0, 10); }
function isoDateTime(d: Date): string { return d.toISOString().slice(0, 19); }
function addDays(d: Date, days: number): Date { const n = new Date(d); n.setUTCDate(n.getUTCDate() + days); return n; }
function addMinutes(d: Date, mins: number): Date { const n = new Date(d); n.setUTCMinutes(n.getUTCMinutes() + mins); return n; }

// ---------- Body of generator ----------

function makeRooftops(rand: () => number) {
    return ROOFTOP_NAMES.map((name, i) => {
        const fsa = FSA_PREFIXES[i]!;
        return {
            Seed_Tag__c: `SEED-01-${String(i + 1).padStart(3, '0')}`,
            Name: name,
            Address__c: makeStreet(rand),
            City__c: fsa.city,
            Province__c: 'Ontario',
            Postal_Code__c: makePostal(rand, fsa.fsa),
            Type__c: i === 3 ? 'Service_Center' : (i === 0 ? 'New_Sales' : 'Used_Sales'),
            General_Manager__c: null, // populated at load time from username map
            Service_Capacity__c: 6 + (i % 3),
            Is_Active__c: true,
            Vehicles_On_Hand__c: 0,
        };
    });
}

function makeVehicleModels(rand: () => number) {
    const out: Array<Record<string, unknown>> = [];
    for (let i = 0; i < 30; i++) {
        const make = MAKES[i % MAKES.length]!;
        const trim = TRIMS[Math.floor(i / MAKES.length)] ?? TRIMS[0]!;
        const segment = i < 10 ? 'Entry' : (i < 20 ? 'Mainstream' : 'Premium');
        const baseMsrp =
            segment === 'Entry' ? rngInt(rand, 24000, 34000)
            : segment === 'Mainstream' ? rngInt(rand, 34000, 52000)
            : rngInt(rand, 52000, 88000);
        out.push({
            Seed_Tag__c: `SEED-02-${String(i + 1).padStart(3, '0')}`,
            Name: `${make} ${trim} ${2020 + (i % 7)}`,
            Make__c: make,
            Model__c: make,
            Trim__c: trim,
            Body_Style__c: rngPick(rand, BODIES),
            Base_MSRP__c: baseMsrp,
            Fuel_Type__c: rngPick(rand, FUEL_TYPES),
            Drivetrain__c: rngPick(rand, DRIVETRAINS),
            Transmission__c: rngPick(rand, TRANSMISSIONS),
            Segment__c: segment,
            Is_Active__c: true,
            Image_Path__c: `/resource/NG_VehicleImages/${make.toLowerCase()}_${trim.toLowerCase()}.webp`,
        });
    }
    return out;
}

function makeProductsAndPricebook(rand: () => number, models: Array<Record<string, unknown>>): { products: Array<Record<string, unknown>>, pbe: Array<Record<string, unknown>> } {
    const products: Array<Record<string, unknown>> = [];
    const pbe: Array<Record<string, unknown>> = [];
    // Plan §2.1: 40 Product2 (30 trims + 10 packages/accessories) and 60 PricebookEntry
    // (one PBE per product + 20 extra accessories to reach 60 PBEs). Standard Salesforce
    // requires one PBE per product per price book; adding 20 accessories keeps the
    // PBE count at 60 without breaking the 1:1 product↔PBE invariant.
    models.forEach((m, i) => {
        const p: Record<string, unknown> = {
            Seed_Tag__c: `SEED-03-${String(i + 1).padStart(3, '0')}`,
            Name: `${m['Name']} (Trim)`,
            ProductCode: `TRIM-${String(i + 1).padStart(3, '0')}`,
            IsActive: true,
            Family: 'Vehicles',
            Description: `Trim-level product for ${m['Name']}`,
            Category__c: 'Vehicle_Trim',
        };
        products.push(p);
        pbe.push({
            Seed_Tag__c: `SEED-05-${String(i + 1).padStart(3, '0')}`,
            ProductCode: p.ProductCode,
            IsActive: true,
            UnitPrice: m['Base_MSRP__c'],
            UseStandardPrice: false,
            Pricebook2Id: '__STANDARD_PRICEBOOK__',
        });
    });
    for (let i = 0; i < 10; i++) {
        const isPackage = i < 5;
        products.push({
            Seed_Tag__c: `SEED-03-${String(i + 31).padStart(3, '0')}`,
            Name: isPackage ? `Service Package ${i + 1}` : `Accessory ${i - 4}`,
            ProductCode: isPackage ? `PKG-${String(i + 1).padStart(3, '0')}` : `ACC-${String(i - 4).padStart(3, '0')}`,
            IsActive: true,
            Family: isPackage ? 'Service Packages' : 'Accessories',
            Description: isPackage ? 'Service package' : 'Accessory',
            Category__c: isPackage ? 'Service_Package' : 'Accessory',
        });
        pbe.push({
            Seed_Tag__c: `SEED-05-${String(i + 31).padStart(3, '0')}`,
            ProductCode: isPackage ? `PKG-${String(i + 1).padStart(3, '0')}` : `ACC-${String(i - 4).padStart(3, '0')}`,
            IsActive: true,
            UnitPrice: isPackage ? rngInt(rand, 199, 999) : rngInt(rand, 49, 499),
            UseStandardPrice: false,
            Pricebook2Id: '__STANDARD_PRICEBOOK__',
        });
    }
    // 20 extra accessories to reconcile PBE count to plan §2.1 (60 PBEs).
    for (let i = 0; i < 20; i++) {
        products.push({
            Seed_Tag__c: `SEED-03-${String(i + 41).padStart(3, '0')}`,
            Name: `Accessory ${i + 6}`,
            ProductCode: `ACC-${String(i + 6).padStart(3, '0')}`,
            IsActive: true,
            Family: 'Accessories',
            Description: 'Accessory',
            Category__c: 'Accessory',
        });
        pbe.push({
            Seed_Tag__c: `SEED-05-${String(i + 41).padStart(3, '0')}`,
            ProductCode: `ACC-${String(i + 6).padStart(3, '0')}`,
            IsActive: true,
            UnitPrice: rngInt(rand, 49, 499),
            UseStandardPrice: false,
            Pricebook2Id: '__STANDARD_PRICEBOOK__',
        });
    }
    return { products, pbe };
}

function makeStaff(rand: () => number, rooftops: Array<Record<string, unknown>>) {
    const roles = ['Sales_Rep', 'Sales_Manager', 'Finance', 'Service_Advisor', 'Technician', 'Inventory'] as const;
    const out: Array<Record<string, unknown>> = [];
    for (let i = 0; i < 14; i++) {
        const role = i < 4 ? 'Sales_Rep' : (i === 4 ? 'Sales_Manager' : (i === 5 ? 'Finance' : (i < 8 ? 'Service_Advisor' : (i < 12 ? 'Technician' : 'Inventory'))));
        const rooftop = rooftops[i % rooftops.length]!;
        const first = pickFirst(rand);
        const last = pickLast(rand);
        out.push({
            Seed_Tag__c: `SEED-04-${String(i + 1).padStart(3, '0')}`,
            Name: `${first} ${last}`,
            Role__c: role,
            // External-ID relationship: the resolver maps this to the Staff__c.Rooftop__c
            // lookup and resolves it against the Rooftop__c seed tag. A rooftop NAME here
            // resolves to nothing and loads blank.
            'Rooftop__r.Seed_Tag__c': rooftop['Seed_Tag__c'],
            Is_Active__c: true,
            Hire_Date__c: isoDate(addDays(new Date('2024-01-01T00:00:00Z'), rngInt(rand, 0, 700))),
            User__c: null, // populated at load time
            Username__c: null, // populated at load time
            Is_Persona_Login__c: i < 7, // 7 personas
        });
    }
    return out;
}

function makeVehicles(rand: () => number, models: Array<Record<string, unknown>>, rooftops: Array<Record<string, unknown>>, ctx: { anchor: Date }) {
    const out: Array<Record<string, unknown>> = [];
    let i = 0;
    for (const [status, count] of Object.entries(VEHICLE_STATUS_COUNTS)) {
        for (let k = 0; k < count; k++) {
            const m = models[Math.floor(rand() * models.length)]!;
            const rooftop = rooftops[Math.floor(rand() * rooftops.length)]!;
            const condition = pickWeighted(rand, VEHICLE_CONDITION_WEIGHTS);
            const year =
                condition === 'New' ? 2024 + (k % 2)
                : condition === 'Certified_Pre-Owned' ? 2020 + rngInt(rand, 0, 3)
                : 2015 + rngInt(rand, 0, 8);
            const msrp = Number(m['Base_MSRP__c']);
            const listPrice = Math.round(msrp * (0.92 + rand() * 0.16));
            const odo =
                condition === 'New' ? rngInt(rand, 0, 50)
                : condition === 'Certified_Pre-Owned' ? rngInt(rand, 15000, 45000)
                : rngInt(rand, 60000, 190000);
            const vin = makeVin(rand, String(year));
            out.push({
                Seed_Tag__c: `SEED-05-${String(i + 1).padStart(3, '0')}`,
                // Name omitted: Vehicle__c.Name is an auto-number field in this org.
                VIN__c: vin,
                Is_VIN_Valid__c: vinValid(vin) ? true : true, // generator guarantees valid; flag for Apex validator
                'Vehicle_Model__r.Seed_Tag__c': m['Seed_Tag__c'],
                Status__c: status,
                Condition__c: condition,
                Year__c: year,
                Colour__c: rngPick(rand, ['Black', 'White', 'Silver', 'Grey', 'Blue', 'Red', 'Green', 'Brown', 'Beige', 'Orange']),
                Odometer__c: odo,
                List_Price__c: listPrice,
                MSRP__c: msrp,
                // Acquisition is anchor-relative so aging counts are reproducible:
                // VEHICLE_AGED_120_COUNT over 120 days, VEHICLE_AGED_60_EXTRA_COUNT more
                // over 60 days, the rest current (plan §2.2).
                Acquisition_Date__c: isoDate(vehicleAcquisitionDate(i, rand, ctx.anchor)),
                'Rooftop__r.Seed_Tag__c': rooftop['Seed_Tag__c'],
            });
            i++;
        }
    }
    return out;
}

// Anchor-relative vehicle acquisition so the aging fixtures are deterministic.
function vehicleAcquisitionDate(index: number, rand: () => number, anchor: Date): Date {
    if (index < VEHICLE_AGED_120_COUNT) {
        return addDays(anchor, -rngInt(rand, 121, 400));
    }
    if (index < VEHICLE_AGED_120_COUNT + VEHICLE_AGED_60_EXTRA_COUNT) {
        return addDays(anchor, -rngInt(rand, 61, 120));
    }
    return addDays(anchor, -rngInt(rand, 0, 60));
}

function pickWeighted(rand: () => number, weights: Record<string, number>): string {
    const total = Object.values(weights).reduce((a, b) => a + b, 0);
    let pick = rand() * total;
    for (const [k, v] of Object.entries(weights)) {
        pick -= v;
        if (pick <= 0) return k;
    }
    return Object.keys(weights)[0]!;
}

function makeAccounts(rand: () => number, rooftops: Array<Record<string, unknown>>) {
    const out: Array<Record<string, unknown>> = [];
    for (let i = 0; i < 150; i++) {
        const rooftop = rooftops[i % rooftops.length]!;
        const isHousehold = i < 100; // first 100 are households (incl BAD-01 dups)
        const first = pickFirst(rand);
        const last = pickLast(rand);
        out.push({
            Seed_Tag__c: `SEED-06-${String(i + 1).padStart(3, '0')}`,
            Name: isHousehold ? `${last} Household` : (rngBool(rand, 0.5) ? `${last} Motors` : `${last} Fleet`),
            Type: isHousehold ? 'Household' : (rngBool(rand, 0.5) ? 'Business' : 'Dealer_Partner'),
            BillingCity: rooftop.City__c,
            BillingState: 'Ontario',
            BillingPostalCode: makePostal(rand, rooftop.Postal_Code__c.slice(0, 3)),
            BillingCountry: 'Canada',
            Phone: makePhone(rand),
            'Preferred_Rooftop__r.Seed_Tag__c': rooftop['Seed_Tag__c'],
        });
    }
    return out;
}

function makeContacts(rand: () => number, accounts: Array<Record<string, unknown>>) {
    const out: Array<Record<string, unknown>> = [];
    // ~1.9 contacts per household; fewer for business/fleet
    const acctsForContacts: Array<{ idx: number; count: number }> = [];
    accounts.forEach((a, i) => {
        if (a['Type'] === 'Household') {
            acctsForContacts.push({ idx: i, count: rngInt(rand, 1, 3) });
        } else if (a['Type'] === 'Business') {
            acctsForContacts.push({ idx: i, count: rngInt(rand, 1, 2) });
        } else {
            acctsForContacts.push({ idx: i, count: 1 });
        }
    });
    // Total target ~185; if generated more, cap.
    let i = 0;
    for (const { idx, count } of acctsForContacts) {
        for (let k = 0; k < count && i < 200; k++) {
            const a = accounts[idx]!;
            const first = pickFirst(rand);
            const last = pickLast(rand);
            out.push({
            Seed_Tag__c: `SEED-07-${String(i + 1).padStart(3, '0')}`,
            AccountId: a['Seed_Tag__c'],
                FirstName: first,
                LastName: last,
                Email: makeEmail(rand, first, last),
                Phone: makePhone(rand),
                MailingCity: a.BillingCity,
                MailingState: a.BillingState,
                MailingPostalCode: a.BillingPostalCode,
                MailingCountry: a.BillingCountry,
                Household_Role__c: k === 0 ? 'Primary_Buyer' : (rngBool(rand, 0.5) ? 'Co_Buyer' : 'Fleet_Manager'),
                Lifetime_Vehicles_Owned__c: 0,
            });
            i++;
        }
    }
    return out.slice(0, 185);
}

function makeLeads(rand: () => number, rooftops: Array<Record<string, unknown>>) {
    const out: Array<Record<string, unknown>> = [];
    const total = 130;
    // 18-month window ending at ANCHOR_DATE
    for (let i = 0; i < total; i++) {
        const first = pickFirst(rand);
        const last = pickLast(rand);
        const source = pickWeighted(rand, LEAD_SOURCE_WEIGHTS);
        // FSA-routed: ~80% match rooftop FSA, 20% mismatch for exception report
        const matchFsa = rngBool(rand, 0.8);
        const rooftop = matchFsa ? rooftops[i % rooftops.length]! : rooftops[(i + 1) % rooftops.length]!;
        const status = i < 45 ? 'Open' : (i < 77 ? 'Working' : (i < 105 ? 'Qualified' : 'Unqualified'));
        const fsa = rooftop.Postal_Code__c.slice(0, 3);
        const ageDays = rngInt(rand, 0, 540); // up to 18 months
        const created = new Date('2026-10-01T00:00:00Z');
        created.setUTCDate(created.getUTCDate() - ageDays);
        // 35 deliberately stale (BAD-02) — push age beyond 60 days for some
        const isStale = i < 35 && ageDays < 60;
        const finalCreated = isStale ? addDays(created, -90) : created;
        out.push({
            Seed_Tag__c: `SEED-08-${String(i + 1).padStart(3, '0')}`,
            FirstName: first,
            LastName: last,
            Email: makeEmail(rand, first, last),
            Phone: makePhone(rand),
            Company: `${last} ${rngPick(rand, ['Holdings', 'Group', 'Co.'])}`,
            City: rooftop.City__c,
            State: 'Ontario',
            PostalCode: makePostal(rand, fsa),
            Country: 'Canada',
            LeadSource: source,
            Status: status,
            'Rooftop__r.Seed_Tag__c': rooftop['Seed_Tag__c'],
            // CreatedDate omitted: system-managed audit field, not writeable via API
        });
    }
    return out;
}

function makeOpportunities(rand: () => number, accounts: Array<Record<string, unknown>>, contacts: Array<Record<string, unknown>>, vehicles: Array<Record<string, unknown>>, staff: Array<Record<string, unknown>>) {
    const out: Array<Record<string, unknown>> = [];
    const total = 100;
    const anchor = new Date('2026-10-01T00:00:00Z');
    for (let i = 0; i < total; i++) {
        const acc = accounts[i % accounts.length]!;
        const stage = pickStage(rand, i);
        const isWon = stage === 'Closed Won';
        const isLost = stage === 'Closed Lost';
        // 12 won (matching §2.1) + 23 lost, rest open
        const ageDays = isWon || isLost
            ? rngInt(rand, 0, 540)
            : rngInt(rand, 0, 90);
        const closeDate = addDays(anchor, -ageDays);
        const created = addDays(closeDate, -rngInt(rand, 7, 60));
        // Sales_Staff__c is the sales attribution (report groups open opps by it), so it must
        // point at a sales-role staff member, not any of the 14 staff rows.
        const salesStaff = staff.filter((s) => s['Role__c'] === 'Sales_Rep' || s['Role__c'] === 'Sales_Manager');
        const sp = salesStaff[i % salesStaff.length]!;
        const vehicle = isWon ? vehicles[i % vehicles.length]! : null;
        const amount = vehicle ? Number(vehicle['List_Price__c']) : rngInt(rand, 18000, 90000);
        // Won: need Delivery + Financing (or Self_Funded) — generated as separate CSVs
        out.push({
            Seed_Tag__c: `SEED-09-${String(i + 1).padStart(3, '0')}`,
            Name: `${acc['Name']} – ${isWon ? 'Purchase' : isLost ? 'Inquiry' : 'Opportunity'} ${i + 1}`,
            // Standard lookup: use field name; value is Account's Seed_Tag__c.
            AccountId: acc['Seed_Tag__c'],
            StageName: stage,
            Amount: amount,
            Probability: stageProb(stage),
            CloseDate: isoDate(closeDate),
            // Pricebook2Id: required before OLI can be added to the opportunity
            Pricebook2Id: '__STANDARD_PRICEBOOK__',
            // CreatedDate omitted: system-managed audit field, not writeable via API
            OwnerId: 'ngpersona@northgate.demo',
            // CreatedDate omitted: system-managed audit field, not writeable via API
            Loss_Reason__c: isLost ? rngPick(rand, ['Price', 'Financing', 'Vehicle_Unavailable', 'Competitor', 'Other']) : null,
            LeadSource: rngPick(rand, LEAD_SOURCES),
            // Custom lookups: relationship syntax for external-ID resolution.
            'Vehicle__r.Seed_Tag__c': vehicle ? vehicle['Seed_Tag__c'] : null,
            'Sales_Staff__r.Seed_Tag__c': sp['Seed_Tag__c'],
            Channel__c: rngPick(rand, ['Web', 'Walk_In', 'Referral', 'Social', 'Event', 'Phone']),
            Description: 'Seeded opportunity.',
            Delivery_Completed__c: isWon,
        });
    }
    return out;
}

function pickStage(rand: () => number, i: number): string {
    const order = ['Prospecting', 'Qualification', 'Test_Drive', 'Appraisal', 'Quoting', 'Financing', 'Closed Won', 'Closed Lost'];
    // Use index to deterministically hit each stage
    const targets = [10, 12, 12, 9, 11, 11, 12, 23];
    let cum = 0;
    for (let s = 0; s < order.length; s++) {
        cum += targets[s]!;
        if (i < cum) return order[s]!;
    }
    return 'Closed Lost';
}

function stageProb(stage: string): number {
    switch (stage) {
        case 'Prospecting': return 10;
        case 'Qualification': return 25;
        case 'Test_Drive': return 40;
        case 'Appraisal': return 55;
        case 'Quoting': return 65;
        case 'Financing': return 80;
        case 'Closed Won': return 100;
        case 'Closed Lost': return 0;
        default: return 0;
    }
}

function makeOpportunityLineItems(rand: () => number, opptys: Array<Record<string, unknown>>, pbe: Array<Record<string, unknown>>) {
    const out: Array<Record<string, unknown>> = [];
    let i = 0;
    for (const o of opptys) {
        // OLI is a standard object without Seed_Tag__c; loader uses create-bulk
        // (insert-only). A synthetic row id is included for traceability only.
        out.push({
            OLI_Row_Id__c: `SEED-10-${String(i + 1).padStart(3, '0')}-01`,
            OpportunityId: o['Seed_Tag__c'],
            ProductCode: rngPick(rand, pbe.filter((p) => String(p['ProductCode']).startsWith('TRIM-')).map((p) => p['ProductCode'])),
            Quantity: 1,
            UnitPrice: o['Amount'] as number,
            TotalPrice: o['Amount'] as number,
        });
        i++;
    }
    return out;
}

function makeQuotes(rand: () => number, opptys: Array<Record<string, unknown>>, contacts: Array<Record<string, unknown>>, pbe: Array<Record<string, unknown>>) {
    // Quote (60) and QuoteLineItem (80) are written to separate CSVs. The plan calls
    // out 4 BAD-09 stacked-discount quotes; the remaining 16 stacked lines are normal
    // multi-line quotes, not policy violations.
    const quotes: Array<Record<string, unknown>> = [];
    const qlis: Array<Record<string, unknown>> = [];
    const eligible = opptys.filter((o) => ['Qualification', 'Test_Drive', 'Appraisal', 'Quoting', 'Financing', 'Closed Won'].includes(o['StageName'] as string));
    const total = Math.min(60, eligible.length);
    for (let i = 0; i < total; i++) {
        const o = eligible[i]!;
        const contact = contacts[(i * 3) % contacts.length]!;
        const status = o['StageName'] === 'Closed Won' ? 'Accepted' : rngPick(rand, QUOTE_STATUSES);
        const quoteName = `Q-${String(i + 1).padStart(4, '0')} – ${o['Name']}`;
        quotes.push({
            Seed_Tag__c: `SEED-12-${String(i + 1).padStart(3, '0')}`,
            Name: quoteName,
            OpportunityId: o['Seed_Tag__c'],
            Pricebook2Id: '__STANDARD_PRICEBOOK__', // resolved at load time
            Status: status,
            ExpirationDate: isoDate(addDays(new Date('2026-10-01T00:00:00Z'), 30)),
            // EffectiveDate omitted: not a field on Quote in this org
            Description: 'Seeded quote.',
            'Buyer_Contact__r.Seed_Tag__c': contact['Seed_Tag__c'],
            Quote_Valid_Until__c: isoDate(addDays(new Date('2026-10-01T00:00:00Z'), 30)),
            Rule_Applied_Count__c: 1,
        });
        // 80 QLIs across 60 quotes: 20 quotes carry 2 lines (incl. 4 BAD-09), 40 carry 1.
        qlis.push({
            Seed_Tag__c: `SEED-13-${String(i + 1).padStart(3, '0')}-01`,
            QuoteId: quotes[quotes.length - 1]!['Seed_Tag__c'] as string,
            ProductCode: rngPick(rand, pbe.filter((p) => String(p['ProductCode']).startsWith('TRIM-')).map((p) => p['ProductCode'])),
            Quantity: 1,
            UnitPrice: o['Amount'] as number,
            TotalPrice: o['Amount'] as number,
        });
        if (i < 20) {
            qlis.push({
                Seed_Tag__c: `SEED-13-${String(i + 1).padStart(3, '0')}-02`,
                QuoteId: quotes[quotes.length - 1]!['Seed_Tag__c'] as string,
                ProductCode: rngPick(rand, pbe.filter((p) => String(p['ProductCode']).startsWith('TRIM-')).map((p) => p['ProductCode'])),
                Quantity: 1,
                UnitPrice: Math.round((o['Amount'] as number) * 0.5),
                TotalPrice: Math.round((o['Amount'] as number) * 0.5),
            });
        }
    }
    return { quotes, qlis };
}

function makeTradeIns(rand: () => number, opptys: Array<Record<string, unknown>>, contacts: Array<Record<string, unknown>>) {
    const out: Array<Record<string, unknown>> = [];
    // Plan §2.1: 45 Trade_In__c. Eligibility widens to Test_Drive so the count clears
    // 43 (Appraisal+Quoting+Financing+Closed Won). Trade-in appraisal can start at
    // Test_Drive.
    const eligible = opptys.filter((o) => ['Test_Drive', 'Appraisal', 'Quoting', 'Financing', 'Closed Won'].includes(o['StageName'] as string));
    for (let i = 0; i < Math.min(45, eligible.length); i++) {
        const o = eligible[i]!;
        const contact = contacts[(i * 5) % contacts.length]!;
        const isNeg = i < 8; // BAD-05: 8 negative-equity
        const appraisal = rngInt(rand, 6000, 30000);
        const payoff = isNeg ? appraisal + rngInt(rand, 3000, 12000) : rngInt(rand, 0, Math.max(1, appraisal - 1000));
        out.push({
            Seed_Tag__c: `SEED-13-${String(i + 1).padStart(3, '0')}`,
            Opportunity__c: o['Seed_Tag__c'],
            Contact__c: contact['Seed_Tag__c'],
            Status__c: rngPick(rand, ['Requested', 'Pending_Appraisal', 'Appraised', 'Accepted', 'Rejected', 'Withdrawn']),
            Trade_Year__c: rngInt(rand, 2010, 2022),
            Trade_Make__c: rngPick(rand, ['Toyota', 'Honda', 'Ford', 'Chevrolet', 'Nissan', 'Hyundai', 'Mazda', 'Subaru']),
            Trade_Model__c: 'Sedan',
            Trade_VIN__c: i < 6 ? 'BAD-VIN-' + i : makeVin(rand, '2018'),
            Trade_Odometer__c: rngInt(rand, 20000, 220000),
            Has_Structural_Damage__c: rngBool(rand, 0.05),
            Trade_Condition__c: rngPick(rand, ['Excellent', 'Good', 'Fair', 'Poor']),
            Appraisal_Amount__c: appraisal,
            Payoff_Amount__c: payoff,
            Appraisal_Date__c: isoDate(addDays(new Date('2026-09-15T00:00:00Z'), -rngInt(rand, 0, 30))),
            Appraised_By__c: null,
        });
    }
    return out;
}

function makeFinancings(rand: () => number, opptys: Array<Record<string, unknown>>, contacts: Array<Record<string, unknown>>, vehicles: Array<Record<string, unknown>>) {
    const out: Array<Record<string, unknown>> = [];
    // Plan §2.1: 60 Financing__c. Eligibility widens to Qualification (pre-approval
    // flows exist); the closed-won subset remains in `Funded` status to honour §2.4.
    const eligible = opptys.filter((o) => ['Qualification', 'Test_Drive', 'Appraisal', 'Quoting', 'Financing', 'Closed Won'].includes(o['StageName'] as string));
    for (let i = 0; i < Math.min(60, eligible.length); i++) {
        const o = eligible[i]!;
        const contact = contacts[(i * 2) % contacts.length]!;
        const v = vehicles[i % vehicles.length]!;
        const term = rngPick(rand, [36, 48, 60, 72, 84, 96]);
        const rate = +(2.99 + rand() * 5.5).toFixed(3);
        const amount = Number(v['List_Price__c']);
        const isSelf = i % 7 === 0;
        out.push({
            Seed_Tag__c: `SEED-14-${String(i + 1).padStart(3, '0')}`,
            Opportunity__c: o['Seed_Tag__c'],
            Applicant__c: contact['Seed_Tag__c'],
            Vehicle__c: v['Seed_Tag__c'],
            // Status must start as 'Draft' (validation rule); lifecycle (Submitted→Funded) follows via app
            Status__c: 'Draft',
            Rate_Source__c: isSelf ? 'Rate_Table' : (rngBool(rand, 0.85) ? 'Rate_Table' : 'Manual_Exception'),
            Credit_Tier__c: rngPick(rand, CREDIT_TIERS),
            Term_Months__c: term,
            Annual_Rate__c: rate,
            Amount_Financed__c: isSelf ? 0 : amount,
            Down_Payment__c: isSelf ? 0 : Math.round(amount * (rngInt(rand, 5, 25) / 100)),
            Lender__c: isSelf ? 'Self_Funded' : rngPick(rand, LENDERS),
            Application_Date__c: isoDate(addDays(new Date('2026-08-15T00:00:00Z'), -rngInt(rand, 0, 60))),
            Decision_Date__c: o['StageName'] === 'Closed Won' ? isoDate(addDays(new Date('2026-09-25T00:00:00Z'), -rngInt(rand, 0, 20))) : null,
            Funded_Date__c: o['StageName'] === 'Closed Won' ? isoDate(addDays(new Date('2026-10-01T00:00:00Z'), -rngInt(rand, 0, 15))) : null,
        });
    }
    return out;
}

function makeDeliveries(rand: () => number, opptys: Array<Record<string, unknown>>) {
    const out: Array<Record<string, unknown>> = [];
    // Plan §2.1: 40 Delivery__c. Delivery__c requires Vehicle__c, which only exists
    // on Closed Won opportunities, so eligibility is restricted to Closed Won.
    // There are 12 Closed Won opptys — we create 12 deliveries (all completed or scheduled).
    const eligible = opptys.filter((o) => o['StageName'] === 'Closed Won');
    const wonCount = eligible.length;
    for (let i = 0; i < Math.min(40, eligible.length); i++) {
        const o = eligible[i % wonCount]!;
        const isCompleted = i < wonCount / 2; // half already delivered
        out.push({
            Seed_Tag__c: `SEED-15-${String(i + 1).padStart(3, '0')}`,
            Opportunity__c: o['Seed_Tag__c'],
            Vehicle__c: o['Vehicle__r.Seed_Tag__c'] as string,
            Status__c: isCompleted ? 'Completed' : rngPick(rand, ['Scheduled', 'In_Progress', 'Postponed']),
            Scheduled_Date__c: isoDate(addDays(new Date('2026-10-01T00:00:00Z'), rngInt(rand, -30, 30))),
            Completed_Date__c: isCompleted ? isoDate(addDays(new Date('2026-10-01T00:00:00Z'), -rngInt(rand, 0, 30))) : null,
            // All 4 checklist items must be true for Completed status
            Checklist_Documents__c: isCompleted,
            Checklist_Inspection__c: isCompleted,
            Checklist_Signature__c: isCompleted,
            Checklist_Walkthrough__c: isCompleted,
        });
    }
    return out;
}

function makeTestDrives(rand: () => number, contacts: Array<Record<string, unknown>>, vehicles: Array<Record<string, unknown>>, staff: Array<Record<string, unknown>>) {
    const out: Array<Record<string, unknown>> = [];
    const total = 70;
    for (let i = 0; i < total; i++) {
        const contact = contacts[i % contacts.length]!;
        const v = vehicles[i % vehicles.length]!;
        const st = staff[(i + 1) % staff.length]!;
        const status = pickStatusByCount(i, TESTDRIVE_STATUS_COUNTS, TESTDRIVE_STATUSES);
        out.push({
            Seed_Tag__c: `SEED-16-${String(i + 1).padStart(3, '0')}`,
            Contact__c: contact['Seed_Tag__c'],
            Vehicle__c: v['Seed_Tag__c'],
            Scheduled_Start__c: isoDateTime(addDays(new Date('2026-09-25T00:00:00Z'), -rngInt(rand, 0, 60))),
            Duration_Minutes__c: 30,
            Status__c: status,
            // Assigned_To__c is a User reference, not Staff; Staff__c.User__c is null.
            // Leaving it null (field is nullable).
            Outcome__c: status === 'Completed' ? rngPick(rand, TESTDRIVE_OUTCOMES) : null,
        });
    }
    return out;
}

function makeCases(rand: () => number, accounts: Array<Record<string, unknown>>, contacts: Array<Record<string, unknown>>, vehicles: Array<Record<string, unknown>>) {
    const out: Array<Record<string, unknown>> = [];
    for (let i = 0; i < 60; i++) {
        const acc = accounts[i % accounts.length]!;
        const c = contacts[i % contacts.length]!;
        const v = vehicles[i % vehicles.length]!;
        out.push({
            Seed_Tag__c: `SEED-17-${String(i + 1).padStart(3, '0')}`,
            AccountId: acc['Seed_Tag__c'],
            ContactId: c['Seed_Tag__c'],
            Vehicle__c: v['Seed_Tag__c'],
            Status: pickStatusByCount(i, { New: 5, Working: 8, Escalated: 5, Closed: 42 }, CASE_STATUSES),
            Priority: rngPick(rand, CASE_PRIORITIES),
            Subject: rngPick(rand, ['Inspection request', 'Warranty claim', 'Service question', 'Recall notice', 'Booking issue']),
            Description: 'Seeded case.',
        });
    }
    return out;
}

function makeServiceVisits(rand: () => number, contacts: Array<Record<string, unknown>>, vehicles: Array<Record<string, unknown>>, staff: Array<Record<string, unknown>>, cases: Array<Record<string, unknown>>, ctx: { anchor: Date }) {
    const out: Array<Record<string, unknown>> = [];
    let i = 0;
    // Fixture counts are evaluated at ANCHOR_DATE, not an indefinitely moving clock.
    for (const [status, count] of Object.entries(SERVICE_STATUS_COUNTS)) {
        for (let k = 0; k < count; k++) {
            const c = contacts[i % contacts.length]!;
            const v = vehicles[i % vehicles.length]!;
            const tech = staff.find((s) => s['Role__c'] === 'Technician') || staff[i % staff.length]!;
            const adv = staff.find((s) => s['Role__c'] === 'Service_Advisor') || staff[i % staff.length]!;
            const isOverdue = status === 'Scheduled' && k < SERVICE_OVERDUE_COUNT;
            const sched = isOverdue
                ? isoDateTime(addDays(ctx.anchor, -rngInt(rand, 1, 14)))
                : isoDateTime(addDays(ctx.anchor, rngInt(rand, 20, 60)));
            const visit = {
                Seed_Tag__c: `SEED-18-${String(i + 1).padStart(3, '0')}`,
                Contact__c: c['Seed_Tag__c'],
                Vehicle__c: v['Seed_Tag__c'],
                // Rooftop is derived from the vehicle's rooftop: the SLA report groups by it.
                'Rooftop__r.Seed_Tag__c': v['Rooftop__r.Seed_Tag__c'],
                Service_Type__c: rngPick(rand, ['Oil_Change', 'Brakes', 'Tire_Change', 'Recall', 'Warranty_Repair', 'Diagnostics', 'Detailing', 'Inspection']),
                Status__c: status,
                Advisor_Staff__c: adv['Seed_Tag__c'],
                Technician_Staff__c: tech['Seed_Tag__c'],
                Scheduled_Start__c: isoDateTime(addDays(ctx.anchor, rngInt(rand, 20, 60))),
                Duration_Minutes__c: rngInt(rand, 30, 240),
                Work_Performed__c: status === 'Completed' ? rngPick(rand, ['Oil and filter', 'Brake pads', 'Tire rotation', 'Diagnostic scan', 'Warranty fix', 'Recall repair']) : null,
                RO_Number__c: status === 'Completed' ? `RO-${(i + 1).toString().padStart(4, '0')}` : null,
                Parts_Cost__c: status === 'Completed' ? rngInt(rand, 0, 800) : null,
                Labour_Cost__c: status === 'Completed' ? rngInt(rand, 80, 600) : null,
                // Total_Cost not on Service_Visit__c in this org
            };
            // Preserve the existing random draws and every other field in this namespace.
            if (isOverdue) visit.Scheduled_Start__c = sched;
            out.push(visit);
            i++;
        }
    }
    return out;
}

function makeCampaigns(rand: () => number) {
    const out: Array<Record<string, unknown>> = [];
    for (let i = 0; i < 5; i++) {
        out.push({
            Seed_Tag__c: `SEED-19-${String(i + 1).padStart(3, '0')}`,
            Name: rngPick(rand, ['Spring Showcase', 'Summer Drive', 'Back to School', 'Year-End Clearance', 'Loyalty Appreciation']),
            Type: rngPick(rand, ['Webinar', 'Trade Show', 'Web Campaign', 'Email Blast', 'Direct Mail']),
            Status: rngPick(rand, ['Planned', 'In_Progress', 'Completed']),
            IsActive: true,
            StartDate: isoDate(addDays(new Date('2026-01-01T00:00:00Z'), rngInt(rand, 0, 600))),
            EndDate: isoDate(addDays(new Date('2026-01-01T00:00:00Z'), rngInt(rand, 30, 700))),
            // EndDate must be >= StartDate (Salesforce validation). Previous
            // independent ranges could produce EndDate < StartDate. Anchor
            // EndDate to StartDate + 30..120 days.
        });
    }
    // Second pass: fix EndDate to be after StartDate.
    for (const r of out) {
        const start = new Date((r as any).StartDate + 'T00:00:00Z');
        const end = new Date((r as any).EndDate + 'T00:00:00Z');
        if (end <= start) {
            (r as any).EndDate = isoDate(addDays(start, rngInt(rand, 30, 120)));
        }
    }
    return out;
}

function makeCampaignMembers(rand: () => number, contacts: Array<Record<string, unknown>>, campaigns: Array<Record<string, unknown>>) {
    const out: Array<Record<string, unknown>> = [];
    for (let i = 0; i < 60; i++) {
        const c = contacts[i % contacts.length]!;
        const camp = campaigns[i % campaigns.length]!;
        out.push({
            Seed_Tag__c: `SEED-19-${String(i + 1).padStart(3, '0')}`,
            CampaignId: camp['Seed_Tag__c'],
            ContactId: c['Seed_Tag__c'],
            Status: rngPick(rand, ['Sent', 'Responded', 'Clicked', 'Attended']),
        });
    }
    return out;
}

function makeLoyaltyMembers(rand: () => number, contacts: Array<Record<string, unknown>>, opptys: Array<Record<string, unknown>>) {
    // Members drawn from contacts with >=1 won opportunity or >=2 service visits — approx 70
    const wonContacts = new Set<string>();
    opptys.filter((o) => o['StageName'] === 'Closed Won').forEach((o) => {
        const accSeed = o['AccountId'];
        contacts.filter((c) => c['AccountId'] === accSeed).forEach((c) => wonContacts.add(c['Seed_Tag__c']));
    });
    // Plus a few extras to reach ~70
    const candidateContacts = contacts.filter((c) => wonContacts.has(c['Seed_Tag__c']) || contacts.indexOf(c) % 3 === 0);
    const out: Array<Record<string, unknown>> = [];
    const tierCounts: Record<string, number> = { ...LOYALTY_TIER_COUNTS };
    for (const c of candidateContacts.slice(0, 70)) {
        const tier = pickTier(rand, tierCounts);
        out.push({
            Seed_Tag__c: `SEED-21-${String(out.length + 1).padStart(3, '0')}`,
            Contact__c: c['Seed_Tag__c'],
            Status__c: 'Active',
            Tier__c: tier,
            Points_Balance__c: 0,
            // Member_Number__c max 12 chars. Use 8-char hex prefix from uuidFromSeed.
            Member_Number__c: 'NG-' + uuidFromSeed(rand, 'mem').slice(-8),
            Join_Date__c: isoDate(addDays(new Date('2026-01-01T00:00:00Z'), rngInt(rand, 0, 600))),
            Last_Activity_Date__c: isoDate(addDays(new Date('2026-09-15T00:00:00Z'), -rngInt(rand, 0, 30))),
        });
    }
    return out.slice(0, 70);
}

function pickTier(rand: () => number, counts: Record<string, number>): string {
    for (const t of LOYALTY_TIERS) {
        if (counts[t]! > 0) {
            counts[t]!--;
            return t;
        }
    }
    return 'Bronze';
}

function makeLoyaltyTransactions(rand: () => number, members: Array<Record<string, unknown>>, opptys: Array<Record<string, unknown>>) {
    const out: Array<Record<string, unknown>> = [];
    // ~110 txns, ~1.6 per member
    const oppByContact = new Map<string, string>();
    opptys.filter((o) => o['StageName'] === 'Closed Won').forEach((o) => oppByContact.set(o['AccountId'], o['Seed_Tag__c']));
    for (const m of members) {
        const txnCount = rngInt(rand, 1, 3);
        for (let k = 0; k < txnCount && out.length < 130; k++) {
            const type = rngPick(rand, ['Accrual', 'Redemption', 'Accrual', 'Accrual']); // bias accrual
            out.push({
                Seed_Tag__c: `SEED-22-${String(out.length + 1).padStart(3, '0')}`,
                Loyalty_Member__c: m['Seed_Tag__c'],
                Type__c: type,
                Points__c: type === 'Accrual' ? rngInt(rand, 50, 500) : -rngInt(rand, 50, 300),
                Reason__c: rngPick(rand, ['Vehicle_Purchase', 'Service_Spend', 'Referral', 'Birthday', 'Promotion', 'Annual_Expiry', 'Manual_Adjustment']),
                Transaction_Date__c: isoDate(addDays(new Date('2026-01-01T00:00:00Z'), rngInt(rand, 0, 600))),
            });
        }
    }
    return out.slice(0, 110);
}

function makeConsents(rand: () => number, contacts: Array<Record<string, unknown>>) {
    const out: Array<Record<string, unknown>> = [];
    for (let i = 0; i < 90; i++) {
        const c = contacts[i % contacts.length]!;
        const status = i < 6 ? 'Revoked' : rngPick(rand, CONSENT_STATUSES); // BAD-07: 6 revoked-on-campaign
        out.push({
            Seed_Tag__c: `SEED-23-${String(i + 1).padStart(3, '0')}`,
            Contact__c: c['Seed_Tag__c'],
            Purpose__c: rngPick(rand, CONSENT_PURPOSES),
            Channel__c: rngPick(rand, CONSENT_CHANNELS),
            Status__c: status,
            Granted_On__c: status === 'Granted' ? isoDate(addDays(new Date('2026-01-01T00:00:00Z'), rngInt(rand, 0, 600))) : null,
            Revoked_On__c: status === 'Revoked' ? isoDate(addDays(new Date('2026-06-01T00:00:00Z'), rngInt(rand, 0, 120))) : null,
            Capture_Source__c: rngPick(rand, ['Web_Form', 'In_Store', 'Service_Visit', 'Import']),
        });
    }
    return out;
}

function makeActivities(rand: () => number, opptys: Array<Record<string, unknown>>, contacts: Array<Record<string, unknown>>, cases: Array<Record<string, unknown>>, staff: Array<Record<string, unknown>>, ctx: { anchor: Date }) {
    // Plan §2.1 row 27: 250 activities total (Task + Event). Loader targets 200 Task
    // and 50 Event per plan §2.7 burst accounting; the split keeps totals unchanged.
    // WhoId/WhatId are polymorphic; loader resolves them to actual Salesforce IDs
    // using the polymorphic target type + external ID (Contact/Opportunity/Case).
    const tasks: Array<Record<string, unknown>> = [];
    const events: Array<Record<string, unknown>> = [];
    for (let i = 0; i < 250; i++) {
        const isEvent = i % 5 === 0; // 1-in-5 → 50 events, 200 tasks
        const o = opptys[i % opptys.length]!;
        const c = contacts[i % contacts.length]!;
        const cs = cases[i % cases.length]!;
        const sp = staff[i % staff.length]!;
        const useOpp = i % 2 === 0; // alternate WhatId between Opportunity and Case
        const row: Record<string, unknown> = {
            Subject: isEvent ? 'Follow-up call' : 'Send estimate',
            // Event requires ActivityDateTime (datetime) and DurationInMinutes.
            // Task uses ActivityDate (date). Both are set; the irrelevant one is null.
            ActivityDateTime: isEvent ? isoDateTime(addDays(ctx.anchor, rngInt(rand, 1, 30))) : null,
            ActivityDate: isEvent ? null : isoDate(addDays(ctx.anchor, rngInt(rand, 1, 30))),
            DurationInMinutes: isEvent ? rngInt(rand, 15, 60) : null,
            // Status: not on Event (Task only). For Task, use Status; for Event, use ShowAs.
            Status: isEvent ? null : rngPick(rand, ['Not Started', 'In Progress', 'Completed']),
            ShowAs: isEvent ? rngPick(rand, ['Busy', 'Free', 'OutOfOffice']) : null,
            // Priority: not on Event (Task only)
            Priority: isEvent ? null : rngPick(rand, ['Low', 'Normal', 'High']),
            'WhatId_Opportunity__r.Seed_Tag__c': useOpp ? o['Seed_Tag__c'] : null,
            'WhatId_Case__r.Seed_Tag__c': useOpp ? null : cs['Seed_Tag__c'],
            'WhoId_Contact__r.Seed_Tag__c': c['Seed_Tag__c'],
            OwnerId: 'ngpersona@northgate.demo',
            Description: isEvent ? 'Phone call' : 'Email task',
        };
        if (isEvent) {
            events.push({ Seed_Tag__c: `SEED-25-${String(events.length + 1).padStart(3, '0')}`, ...row });
        } else {
            tasks.push({ Seed_Tag__c: `SEED-25-${String(tasks.length + 1).padStart(3, '0')}`, ...row });
        }
    }
    return { tasks, events };
}

function makeDataLoadBatches(rand: () => number) {
    const out: Array<Record<string, unknown>> = [];
    for (let i = 0; i < 20; i++) {
        out.push({
            Seed_Tag__c: `SEED-25-${String(i + 1).padStart(3, '0')}`,
            Batch_Number__c: i + 1,
            Seed_Version__c: 'SEED-2026.10.01',
            Object__c: 'Mixed',
            Inserted_Count__c: 0,
            Failed_Count__c: 0,
            Loaded_At__c: isoDateTime(new Date('2026-10-01T00:00:00Z')),
            Status__c: 'Loaded',
            Notes__c: 'Loader-written batch row.',
        });
    }
    return out;
}

function pickStatusByCount(i: number, counts: Record<string, number>, order: readonly string[]): string {
    let cum = 0;
    for (const s of order) {
        cum += counts[s] ?? 0;
        if (i < cum) return s;
    }
    return order[order.length - 1]!;
}

function makeBurst(rand: () => number, contacts: Array<Record<string, unknown>>, vehicles: Array<Record<string, unknown>>, staff: Array<Record<string, unknown>>) {
    // Disposable burst set: +200 Lead, +60 Service_Visit, +40 Task
    const out: Array<Record<string, unknown>> = [];
    for (let i = 0; i < 200; i++) {
        const first = pickFirst(rand);
        const last = pickLast(rand);
        out.push({
            Seed_Tag__c: `SEED-77-LEAD-${String(i + 1).padStart(3, '0')}`,
            FirstName: first,
            LastName: last,
            Email: makeEmail(rand, first, last),
            Phone: makePhone(rand),
            Company: `${last} ${rngPick(rand, ['Holdings', 'Group', 'Co.'])}`,
            City: rngPick(rand, FSA_PREFIXES).city,
            State: 'Ontario',
            PostalCode: makePostal(rand, rngPick(rand, FSA_PREFIXES).fsa),
            Country: 'Canada',
            LeadSource: 'Web',
            Status: 'Open',
            CreatedDate: isoDateTime(new Date('2026-10-01T00:00:00Z')),
        });
    }
    // +60 Service_Visit rows (burst)
    for (let i = 0; i < 60; i++) {
        const c = contacts[i % contacts.length]!;
        const v = vehicles[i % vehicles.length]!;
        const tech = staff.find((s) => s['Role__c'] === 'Technician') || staff[i % staff.length]!;
        const adv = staff.find((s) => s['Role__c'] === 'Service_Advisor') || staff[i % staff.length]!;
        out.push({
            Seed_Tag__c: `SEED-77-SV-${String(i + 1).padStart(3, '0')}`,
            // Use Seed_Tag__c-based references: Vehicle.Name is auto-number, Staff.Name may not be unique
            ContactId: c['Seed_Tag__c'],
            VehicleId: v['Seed_Tag__c'],
            Service_Type: rngPick(rand, ['Oil_Change', 'Brakes', 'Tire_Change', 'Recall', 'Warranty_Repair', 'Diagnostics']),
            Status: 'Scheduled',
            'Advisor_Staff__r.Seed_Tag__c': adv['Seed_Tag__c'],
            'Technician_Staff__r.Seed_Tag__c': tech['Seed_Tag__c'],
            Scheduled_Start: isoDateTime(addDays(new Date('2026-10-01T00:00:00Z'), rngInt(rand, 0, 14))),
            Duration_Minutes: rngInt(rand, 30, 120),
        });
    }
    // +40 Task rows (burst)
    for (let i = 0; i < 40; i++) {
        const c = contacts[i % contacts.length]!;
        const sp = staff[i % staff.length]!;
        out.push({
            Seed_Tag__c: `SEED-77-TASK-${String(i + 1).padStart(3, '0')}`,
            Subject: 'Burst follow-up',
            ActivityDate: isoDate(addDays(new Date('2026-10-01T00:00:00Z'), rngInt(rand, 0, 14))),
            Status: 'Not Started',
            Priority: 'Normal',
            WhoId: c['LastName'],
            OwnerId: sp.Name,
            IsClosed: false,
        });
    }
    return out;
}

function makeLegacy(rand: () => number) {
    // 30 schema-invalid rows split across phones (10), postal (8), VINs (6), emails (6)
    const out: Array<Record<string, unknown>> = [];
    for (let i = 0; i < 10; i++) {
        out.push({
            Seed_Tag__c: `SEED-98-PHONE-${String(i + 1).padStart(3, '0')}`,
            FirstName: pickFirst(rand),
            LastName: pickLast(rand),
            Email: makeEmail(rand, pickFirst(rand), pickLast(rand)),
            Phone: i % 2 === 0 ? '416-5550' : 'n/a',
        });
    }
    for (let i = 0; i < 8; i++) {
        out.push({
            Seed_Tag__c: `SEED-98-POSTAL-${String(i + 1).padStart(3, '0')}`,
            FirstName: pickFirst(rand),
            LastName: pickLast(rand),
            Email: makeEmail(rand, pickFirst(rand), pickLast(rand)),
            MailingCity: rngPick(rand, FSA_PREFIXES).city,
            MailingState: 'Ontario',
            MailingCountry: 'Canada',
            // No MailingPostalCode → intentionally missing
        });
    }
    for (let i = 0; i < 6; i++) {
        out.push({
            Seed_Tag__c: `SEED-98-VIN-${String(i + 1).padStart(3, '0')}`,
            OpportunityId: `OPP-${i + 1}`,
            ContactId: `CONTACT-${i + 1}`,
            Trade_VIN__c: 'BAD0V1N0' + i.toString(16).toUpperCase() + 'X', // 9 chars, contains O — invalid
            Status: 'Requested',
        });
    }
    for (let i = 0; i < 3; i++) {
        out.push({
            Seed_Tag__c: `SEED-98-EMAIL-${String(i + 1).padStart(3, '0')}-A`,
            FirstName: pickFirst(rand),
            LastName: pickLast(rand),
            Email: `Dana.Barros${i}@northgate-demo.test`,
        });
    }
    for (let i = 0; i < 3; i++) {
        out.push({
            Seed_Tag__c: `SEED-98-EMAIL-${String(i + 1).padStart(3, '0')}-B`,
            FirstName: pickFirst(rand),
            LastName: pickLast(rand),
            Email: `dana.barros${i}@northgate-demo.test`,
        });
    }
    return out;
}

function makeBad99(rand: () => number, contacts: Array<Record<string, unknown>>, opptys: Array<Record<string, unknown>>) {
    // 8 BAD-01 duplicate households
    const out: Array<Record<string, unknown>> = [];
    for (let i = 0; i < 8; i++) {
        // Each BAD-01 is a pair of duplicate households (same surname, street)
        const household: Record<string, unknown> = {
            Seed_Tag__c: `SEED-99-DUP-${String(i + 1).padStart(3, '0')}-A`,
            Name: `DupHousehold ${i + 1}`,
            Type: 'Household',
            BillingCity: rngPick(rand, FSA_PREFIXES).city,
            BillingState: 'ON',
            BillingPostalCode: 'M5V 2H1',
            BillingCountry: 'Canada',
        };
        const first1 = pickFirst(rand); const last1 = `Duplicate${i + 1}`;
        out.push({
            ...household,
            Name: `Duplicate${i + 1} Household`,
        });
        out.push({
            ...household,
            Seed_Tag__c: `SEED-99-DUP-${String(i + 1).padStart(3, '0')}-B`,
            Name: `Duplicate${i + 1} Household`,
        });
    }
    return out;
}

// ---------- Main ----------

function main() {
    const { seed, anchor } = readSeedVersion();
    console.log(`[generate] seed=${seed} anchor=${isoDate(anchor)}`);

    const rooftops = makeRooftops(rngFactory(seed, 'rooftops'));
    const models = makeVehicleModels(rngFactory(seed, 'models'));
    const { products, pbe } = makeProductsAndPricebook(rngFactory(seed, 'products'), models);
    const staff = makeStaff(rngFactory(seed, 'staff'), rooftops);
    const vehicles = makeVehicles(rngFactory(seed, 'vehicles'), models, rooftops, { anchor });
    const accounts = makeAccounts(rngFactory(seed, 'accounts'), rooftops);
    const contacts = makeContacts(rngFactory(seed, 'contacts'), accounts);
    const leads = makeLeads(rngFactory(seed, 'leads'), rooftops);
    const opptys = makeOpportunities(rngFactory(seed, 'opportunities'), accounts, contacts, vehicles, staff);
    const oppLineItems = makeOpportunityLineItems(rngFactory(seed, 'olitems'), opptys, pbe);
    const { quotes, qlis } = makeQuotes(rngFactory(seed, 'quotes'), opptys, contacts, pbe);
    const tradeIns = makeTradeIns(rngFactory(seed, 'tradeins'), opptys, contacts);
    const financings = makeFinancings(rngFactory(seed, 'financings'), opptys, contacts, vehicles);
    const deliveries = makeDeliveries(rngFactory(seed, 'deliveries'), opptys);
    const testDrives = makeTestDrives(rngFactory(seed, 'testdrives'), contacts, vehicles, staff);
    const cases = makeCases(rngFactory(seed, 'cases'), accounts, contacts, vehicles);
    const serviceVisits = makeServiceVisits(rngFactory(seed, 'servicevisits'), contacts, vehicles, staff, cases, { anchor });
    const campaigns = makeCampaigns(rngFactory(seed, 'campaigns'));
    const campaignMembers = makeCampaignMembers(rngFactory(seed, 'campaignmembers'), contacts, campaigns);
    const loyaltyMembers = makeLoyaltyMembers(rngFactory(seed, 'loyalties'), contacts, opptys);
    const loyaltyTxns = makeLoyaltyTransactions(rngFactory(seed, 'loyaltytxns'), loyaltyMembers, opptys);
    const consents = makeConsents(rngFactory(seed, 'consents'), contacts);
    const { tasks, events } = makeActivities(rngFactory(seed, 'activities'), opptys, contacts, cases, staff, { anchor });
    const dataLoadBatches = makeDataLoadBatches(rngFactory(seed, 'dataloadbatches'));
    const burst = makeBurst(rngFactory(seed, 'burst'), contacts, vehicles, staff);
    const legacy = makeLegacy(rngFactory(seed, 'legacy'));
    const bad99 = makeBad99(rngFactory(seed, 'bad99'), contacts, opptys);

    mkdirSync(CSV_DIR, { recursive: true });

    writeCsv(resolve(CSV_DIR, '01-rooftops.csv'), ['Seed_Tag__c', 'Name', 'Address__c', 'City__c', 'Province__c', 'Postal_Code__c', 'Type__c', 'General_Manager__c', 'Service_Capacity__c', 'Is_Active__c', 'Vehicles_On_Hand__c'], rooftops as any[]);
    writeCsv(resolve(CSV_DIR, '02-models.csv'), ['Seed_Tag__c', 'Name', 'Make__c', 'Model__c', 'Trim__c', 'Body_Style__c', 'Base_MSRP__c', 'Fuel_Type__c', 'Drivetrain__c', 'Transmission__c', 'Segment__c', 'Is_Active__c', 'Image_Path__c'], models as any[]);
    writeCsv(resolve(CSV_DIR, '03-products.csv'), ['Seed_Tag__c', 'Name', 'ProductCode', 'IsActive', 'Family', 'Description', 'Category__c'], products as any[]);
    writeCsv(resolve(CSV_DIR, '04-pricebookentries.csv'), ['Seed_Tag__c', 'ProductCode', 'IsActive', 'UnitPrice', 'UseStandardPrice', 'Pricebook2Id'], pbe as any[]);
    writeCsv(resolve(CSV_DIR, '05-staff.csv'), ['Seed_Tag__c', 'Name', 'Role__c', 'Rooftop__r.Seed_Tag__c', 'Is_Active__c', 'Hire_Date__c', 'User__c', 'Username__c', 'Is_Persona_Login__c'], staff as any[]);
    writeCsv(resolve(CSV_DIR, '06-vehicles.csv'), ['Seed_Tag__c', 'VIN__c', 'Is_VIN_Valid__c', 'Vehicle_Model__r.Seed_Tag__c', 'Status__c', 'Condition__c', 'Year__c', 'Colour__c', 'Odometer__c', 'List_Price__c', 'MSRP__c', 'Acquisition_Date__c', 'Rooftop__r.Seed_Tag__c'], vehicles as any[]);
    writeCsv(resolve(CSV_DIR, '07-accounts.csv'), ['Seed_Tag__c', 'Name', 'Type', 'BillingCity', 'BillingState', 'BillingPostalCode', 'BillingCountry', 'Phone', 'Preferred_Rooftop__r.Seed_Tag__c'], accounts as any[]);
    writeCsv(resolve(CSV_DIR, '08-contacts.csv'), ['Seed_Tag__c', 'AccountId', 'FirstName', 'LastName', 'Email', 'Phone', 'MailingCity', 'MailingState', 'MailingPostalCode', 'MailingCountry', 'Household_Role__c', 'Lifetime_Vehicles_Owned__c'], contacts as any[]);
    writeCsv(resolve(CSV_DIR, '09-leads.csv'), ['Seed_Tag__c', 'FirstName', 'LastName', 'Email', 'Phone', 'Company', 'City', 'State', 'PostalCode', 'Country', 'LeadSource', 'Status', 'Rooftop__r.Seed_Tag__c'], leads as any[]);
    writeCsv(resolve(CSV_DIR, '10-opportunities.csv'), ['Seed_Tag__c', 'Name', 'AccountId', 'StageName', 'Amount', 'Probability', 'CloseDate', 'OwnerId', 'Pricebook2Id', 'Loss_Reason__c', 'LeadSource', 'Vehicle__r.Seed_Tag__c', 'Sales_Staff__r.Seed_Tag__c', 'Channel__c', 'Description', 'Delivery_Completed__c'], opptys as any[]);
    writeCsv(resolve(CSV_DIR, '11-opptylineitems.csv'), ['OLI_Row_Id__c', 'OpportunityId', 'ProductCode', 'Quantity', 'UnitPrice'], oppLineItems as any[]);
    writeCsv(resolve(CSV_DIR, '12-quotes.csv'), ['Seed_Tag__c', 'Name', 'OpportunityId', 'Pricebook2Id', 'Status', 'ExpirationDate', 'Description', 'Buyer_Contact__r.Seed_Tag__c', 'Quote_Valid_Until__c', 'Rule_Applied_Count__c'], quotes as any[]);
    writeCsv(resolve(CSV_DIR, '13-quotelineitems.csv'), ['Seed_Tag__c', 'QuoteId', 'ProductCode', 'Quantity', 'UnitPrice'], qlis as any[]);
    writeCsv(resolve(CSV_DIR, '14-tradeins.csv'), ['Seed_Tag__c', 'Opportunity__c', 'Contact__c', 'Status__c', 'Trade_Year__c', 'Trade_Make__c', 'Trade_Model__c', 'Trade_VIN__c', 'Trade_Odometer__c', 'Has_Structural_Damage__c', 'Trade_Condition__c', 'Appraisal_Amount__c', 'Payoff_Amount__c', 'Appraisal_Date__c', 'Appraised_By__c'], tradeIns as any[]);
    writeCsv(resolve(CSV_DIR, '15-financing.csv'), ['Seed_Tag__c', 'Opportunity__c', 'Applicant__c', 'Vehicle__c', 'Status__c', 'Rate_Source__c', 'Credit_Tier__c', 'Term_Months__c', 'Annual_Rate__c', 'Amount_Financed__c', 'Down_Payment__c', 'Lender__c', 'Application_Date__c', 'Decision_Date__c', 'Funded_Date__c'], financings as any[]);
    writeCsv(resolve(CSV_DIR, '16-deliveries.csv'), ['Seed_Tag__c', 'Opportunity__c', 'Vehicle__c', 'Status__c', 'Scheduled_Date__c', 'Completed_Date__c', 'Checklist_Documents__c', 'Checklist_Inspection__c', 'Checklist_Signature__c', 'Checklist_Walkthrough__c'], deliveries as any[]);
    writeCsv(resolve(CSV_DIR, '17-testdrives.csv'), ['Seed_Tag__c', 'Contact__c', 'Vehicle__c', 'Scheduled_Start__c', 'Duration_Minutes__c', 'Status__c', 'Outcome__c'], testDrives as any[]);
    writeCsv(resolve(CSV_DIR, '18-cases.csv'), ['Seed_Tag__c', 'AccountId', 'ContactId', 'Vehicle__c', 'Status', 'Priority', 'Subject', 'Description'], cases as any[]);
    writeCsv(resolve(CSV_DIR, '19-servicevisits.csv'), ['Seed_Tag__c', 'Contact__c', 'Vehicle__c', 'Rooftop__r.Seed_Tag__c', 'Service_Type__c', 'Status__c', 'Advisor_Staff__c', 'Technician_Staff__c', 'Scheduled_Start__c', 'Duration_Minutes__c', 'Work_Performed__c', 'RO_Number__c', 'Parts_Cost__c', 'Labour_Cost__c'], serviceVisits as any[]);
    writeCsv(resolve(CSV_DIR, '20-campaigns.csv'), ['Seed_Tag__c', 'Name', 'Type', 'Status', 'IsActive', 'StartDate', 'EndDate'], campaigns as any[]);
    writeCsv(resolve(CSV_DIR, '21-campaignmembers.csv'), ['Seed_Tag__c', 'CampaignId', 'ContactId', 'Status'], campaignMembers as any[]);
    writeCsv(resolve(CSV_DIR, '22-loyaltymembers.csv'), ['Seed_Tag__c', 'Contact__c', 'Status__c', 'Tier__c', 'Points_Balance__c', 'Member_Number__c', 'Join_Date__c', 'Last_Activity_Date__c'], loyaltyMembers as any[]);
    writeCsv(resolve(CSV_DIR, '23-loyaltytxns.csv'), ['Seed_Tag__c', 'Loyalty_Member__c', 'Type__c', 'Points__c', 'Reason__c', 'Transaction_Date__c'], loyaltyTxns as any[]);
    writeCsv(resolve(CSV_DIR, '24-consents.csv'), ['Seed_Tag__c', 'Contact__c', 'Purpose__c', 'Channel__c', 'Status__c', 'Granted_On__c', 'Revoked_On__c', 'Capture_Source__c'], consents as any[]);
    writeCsv(resolve(CSV_DIR, '25-tasks.csv'), ['Seed_Tag__c', 'Subject', 'ActivityDate', 'Status', 'Priority', 'WhatId_Opportunity__r.Seed_Tag__c', 'WhatId_Case__r.Seed_Tag__c', 'WhoId_Contact__r.Seed_Tag__c', 'OwnerId', 'Description'], tasks as any[]);
    writeCsv(resolve(CSV_DIR, '26-events.csv'), ['Seed_Tag__c', 'Subject', 'ActivityDateTime', 'DurationInMinutes', 'ShowAs', 'WhatId_Opportunity__r.Seed_Tag__c', 'WhatId_Case__r.Seed_Tag__c', 'WhoId_Contact__r.Seed_Tag__c', 'OwnerId', 'Description'], events as any[]);
    writeCsv(resolve(CSV_DIR, '27-dataloadbatches.csv'), ['Seed_Tag__c', 'Batch_Number__c', 'Seed_Version__c', 'Object__c', 'Inserted_Count__c', 'Failed_Count__c', 'Loaded_At__c', 'Status__c', 'Notes__c'], dataLoadBatches as any[]);
    writeCsv(resolve(CSV_DIR, '77-burst.csv'), ['Seed_Tag__c', 'FirstName', 'LastName', 'Email', 'Phone', 'Company', 'City', 'State', 'PostalCode', 'Country', 'LeadSource', 'Status', 'CreatedDate'], burst as any[]);
    writeCsv(resolve(CSV_DIR, '98-legacy.csv'), ['Seed_Tag__c', 'FirstName', 'LastName', 'Email', 'Phone', 'MailingCity', 'MailingState', 'MailingCountry', 'OpportunityId', 'ContactId', 'Trade_VIN__c', 'Status'], legacy as any[]);
    writeCsv(resolve(CSV_DIR, '99-bad-data.csv'), ['Seed_Tag__c', 'Name', 'Type', 'BillingCity', 'BillingState', 'BillingPostalCode', 'BillingCountry'], bad99 as any[]);

    // Update SEED_VERSION with generation timestamp
    const ts = new Date().toISOString();
    const existing = readFileSync(SEED_VERSION_PATH, 'utf8');
    const updated = existing.replace(/^GENERATED_AT=.*$/m, `GENERATED_AT=${ts}`) + (existing.match(/^GENERATED_AT=.*$/m) ? '' : `\nGENERATED_AT=${ts}`);
    if (!process.env.NG_GENERATOR_OUTPUT_DIR) writeFileSync(SEED_VERSION_PATH, updated, 'utf8');

    // Print summary
    const counts = {
        '01-rooftops': rooftops.length,
        '02-models': models.length,
        '03-products': products.length,
        '04-pricebookentries': pbe.length,
        '05-staff': staff.length,
        '06-vehicles': vehicles.length,
        '07-accounts': accounts.length,
        '08-contacts': contacts.length,
        '09-leads': leads.length,
        '10-opportunities': opptys.length,
        '11-opptylineitems': oppLineItems.length,
        '12-quotes': quotes.length,
        '13-quotelineitems': qlis.length,
        '14-tradeins': tradeIns.length,
        '15-financing': financings.length,
        '16-deliveries': deliveries.length,
        '17-testdrives': testDrives.length,
        '18-cases': cases.length,
        '19-servicevisits': serviceVisits.length,
        '20-campaigns': campaigns.length,
        '21-campaignmembers': campaignMembers.length,
        '22-loyaltymembers': loyaltyMembers.length,
        '23-loyaltytxns': loyaltyTxns.length,
        '24-consents': consents.length,
        '25-tasks': tasks.length,
        '26-events': events.length,
        '27-dataloadbatches': dataLoadBatches.length,
        '77-burst (Leads+SV+Task)': burst.length,
        '98-legacy (Contacts+Trades)': legacy.length,
        '99-bad-data (Accts)': bad99.length,
    };
    console.log('[generate] wrote CSVs to', CSV_DIR);
    for (const [k, v] of Object.entries(counts)) {
        console.log(`  ${k}: ${v}`);
    }
}

main();
