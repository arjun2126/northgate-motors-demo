/**
 * Northgate Motors — Phase 5 release-gate DQ verifier (P5-08).
 *
 * Implements all 14 §9a release gates from DEMO_ORG_SYNTHETIC_DATA_PLAN.md.
 * Pure core (evaluateGates) takes a query function for testability; the
 * CLI wrapper runs the gates against ng-demo via `sf data query`.
 */
import { execFileSync } from 'node:child_process';
import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { resolve } from 'node:path';

// ---------- Canonical manifest (authoritative source from data/csv/) ----------

interface ObjectCsvSpec { csv: string; }

const CANONICAL_OBJECT_TO_CSV: Record<string, ObjectCsvSpec> = {
    'Rooftop__c': { csv: '01-rooftops.csv' },
    'Vehicle_Model__c': { csv: '02-models.csv' },
    'Product2': { csv: '03-products.csv' },
    'PricebookEntry': { csv: '04-pricebookentries.csv' },
    'Staff__c': { csv: '05-staff.csv' },
    'Vehicle__c': { csv: '06-vehicles.csv' },
    'Account': { csv: '07-accounts.csv' },
    'Contact': { csv: '08-contacts.csv' },
    'Lead': { csv: '09-leads.csv' },
    'Opportunity': { csv: '10-opportunities.csv' },
    'OpportunityLineItem': { csv: '11-opptylineitems.csv' },
    'Quote': { csv: '12-quotes.csv' },
    'QuoteLineItem': { csv: '13-quotelineitems.csv' },
    'Trade_In__c': { csv: '14-tradeins.csv' },
    'Financing__c': { csv: '15-financing.csv' },
    'Delivery__c': { csv: '16-deliveries.csv' },
    'Test_Drive__c': { csv: '17-testdrives.csv' },
    'Case': { csv: '18-cases.csv' },
    'Service_Visit__c': { csv: '19-servicevisits.csv' },
    'Campaign': { csv: '20-campaigns.csv' },
    'CampaignMember': { csv: '21-campaignmembers.csv' },
    'Loyalty_Member__c': { csv: '22-loyaltymembers.csv' },
    'Loyalty_Transaction__c': { csv: '23-loyaltytxns.csv' },
    'Consent__c': { csv: '24-consents.csv' },
    'Task': { csv: '25-tasks.csv' },
    'Event': { csv: '26-events.csv' },
    'Data_Load_Batch__c': { csv: '27-dataloadbatches.csv' },
};

export interface CanonicalManifest {
    tagsByObject: Record<string, string[]>;
    total: number;
}

export function buildCanonicalManifest(csvDir: string): CanonicalManifest {
    const tagsByObject: Record<string, string[]> = {};
    let total = 0;
    for (const [obj, spec] of Object.entries(CANONICAL_OBJECT_TO_CSV)) {
        const path = resolve(csvDir, spec.csv);
        if (!existsSync(path)) {
            tagsByObject[obj] = [];
            continue;
        }
        const text = readFileSync(path, 'utf8');
        const lines = text.split(/\r?\n/).filter((l) => l.length > 0);
        if (lines.length <= 1) {
            tagsByObject[obj] = [];
            continue;
        }
        const header = parseCsvLineLocal(lines[0]!);
        const tagIdx = header.indexOf('Seed_Tag__c');
        if (tagIdx < 0) {
            // OLI uses OLI_Row_Id__c for traceability, not Seed_Tag__c.
            tagsByObject[obj] = [];
            continue;
        }
        const tags: string[] = [];
        for (let i = 1; i < lines.length; i++) {
            const cells = parseCsvLineLocal(lines[i]!);
            const tag = cells[tagIdx];
            if (tag && tag.length > 0) tags.push(tag);
        }
        tagsByObject[obj] = tags;
        total += tags.length;
    }
    return { tagsByObject, total };
}

// Local CSV line parser (mirrors resolve.ts parseCsvLine).
function parseCsvLineLocal(line: string): string[] {
    const out: string[] = [];
    let cur = '';
    let inQuotes = false;
    for (let i = 0; i < line.length; i++) {
        const ch = line[i]!;
        if (inQuotes) {
            if (ch === '"' && line[i + 1] === '"') { cur += '"'; i++; }
            else if (ch === '"') { inQuotes = false; }
            else { cur += ch; }
        } else {
            if (ch === ',') { out.push(cur); cur = ''; }
            else if (ch === '"') { inQuotes = true; }
            else { cur += ch; }
        }
    }
    out.push(cur);
    return out;
}

// ---------- §2.1 envelope (from data plan) ----------

interface Envelope {
    clean: number;
    activities: number;
    legacy: number;
    total: number;
    activityTolerance: number;
}

const ENVELOPE_2_1: Envelope = {
    clean: 1835,
    activities: 250,
    legacy: 30,
    total: 2115,
    activityTolerance: 2,
};

// Per-object expected counts (from plan §2.1, table rows 1-25).
// Activities (Task 200 + Event 50) are tracked separately to apply ±2 tolerance.
const EXPECTED_COUNTS: Record<string, number> = {
    'Rooftop__c': 4,
    'Vehicle_Model__c': 30,
    'Vehicle__c': 120,
    'Product2': 60,
    'PricebookEntry': 60,
    'Account': 150,
    'Contact': 185,
    'Lead': 130,
    'Opportunity': 100,
    'OpportunityLineItem': 100,
    'Quote': 60,
    'QuoteLineItem': 80,
    'Trade_In__c': 45,
    'Financing__c': 60,
    'Delivery__c': 12,
    'Test_Drive__c': 70,
    'Service_Visit__c': 140,
    'Case': 60,
    'Loyalty_Member__c': 70,
    'Loyalty_Transaction__c': 110,
    'Consent__c': 90,
    'Staff__c': 14,
    'Campaign': 5,
    'CampaignMember': 60,
    'Data_Load_Batch__c': 20,
};

// Objects that have a Seed_Tag__c field and are part of the seed (gate 8).
// OpportunityLineItem is excluded because it's a standard object without
// Seed_Tag__c (it uses OLI_Row_Id__c for traceability, not Seed_Tag__c).
const SEEDED_OBJECTS = Object.keys(EXPECTED_COUNTS).filter((o) => o !== 'OpportunityLineItem');

// ---------- Types ----------

export interface GateResult {
    id: number;
    name: string;
    description: string;
    expected: string;
    actual: string;
    passed: boolean;
    detail: string;
}

export interface GateInputs {
    /** Query function: returns an array of records (or throws on error). */
    query: (soql: string) => Promise<any[]>;
    /** Storage used in MB (gate 13). */
    storageUsedMb: number;
    /** Activity counts (gate 10 split). */
    taskCount: number;
    eventCount: number;
}

// ---------- Gate implementations ----------

async function gate1(input: GateInputs): Promise<GateResult> {
    const r = await input.query(`SELECT COUNT(Id) c FROM Vehicle__c WHERE Seed_Tag__c LIKE 'SEED-%' AND Is_VIN_Valid__c = false`);
    const n = Number(r[0]?.c ?? r[0]?.expr0 ?? 0);
    return { id: 1, name: 'invalid-vin', description: '0 vehicles where Is_VIN_Valid__c = false', expected: '0', actual: String(n), passed: n === 0, detail: '' };
}

async function gate2(input: GateInputs): Promise<GateResult> {
    const r = await input.query(`SELECT VIN__c v, COUNT(Id) c FROM Vehicle__c WHERE Seed_Tag__c LIKE 'SEED-%' AND VIN__c != null GROUP BY VIN__c HAVING COUNT(Id) > 1`);
    const n = r.length;
    return { id: 2, name: 'duplicate-vin', description: '0 duplicate VIN__c (Unique field is the primary guard)', expected: '0', actual: String(n), passed: n === 0, detail: n > 0 ? `${n} duplicate VIN groups` : '' };
}

async function gate3(input: GateInputs): Promise<GateResult> {
    const r = await input.query(`SELECT COUNT(Id) c FROM Opportunity WHERE Seed_Tag__c LIKE 'SEED-%' AND Amount <= 0 AND StageName != 'Prospecting'`);
    const n = Number(r[0]?.c ?? 0);
    return { id: 3, name: 'opp-nonpositive-amount', description: '0 opportunities with Amount <= 0 past Prospecting', expected: '0', actual: String(n), passed: n === 0, detail: '' };
}

async function gate4(input: GateInputs): Promise<GateResult> {
    const r = await input.query(`SELECT COUNT(Id) c FROM Opportunity WHERE Seed_Tag__c LIKE 'SEED-%' AND IsWon = true AND Delivery_Completed__c = false`);
    const n = Number(r[0]?.c ?? 0);
    return { id: 4, name: 'won-no-delivery', description: '0 Closed Won opportunities where Delivery_Completed__c = false', expected: '0', actual: String(n), passed: n === 0, detail: '' };
}

async function gate5(input: GateInputs): Promise<GateResult> {
    const r = await input.query(`SELECT COUNT(Id) c FROM Financing__c WHERE Seed_Tag__c LIKE 'SEED-%' AND (Annual_Rate__c < 0 OR Annual_Rate__c > 25 OR (Term_Months__c != 36 AND Term_Months__c != 48 AND Term_Months__c != 60 AND Term_Months__c != 72 AND Term_Months__c != 84 AND Term_Months__c != 96))`);
    const n = Number(r[0]?.c ?? 0);
    return { id: 5, name: 'financing-rate-term', description: '0 Financing__c with Annual_Rate__c outside 0-25 or term outside {36,48,60,72,84,96}', expected: '0', actual: String(n), passed: n === 0, detail: '' };
}

async function gate6(input: GateInputs): Promise<GateResult> {
    const r = await input.query(`SELECT COUNT(Id) c FROM Loyalty_Member__c WHERE Seed_Tag__c LIKE 'SEED-%' AND Points_Balance__c < 0`);
    const n = Number(r[0]?.c ?? 0);
    return { id: 6, name: 'loyalty-negative', description: '0 loyalty members with Points_Balance__c < 0', expected: '0', actual: String(n), passed: n === 0, detail: '' };
}

async function gate7(input: GateInputs): Promise<GateResult> {
    const r = await input.query(`SELECT COUNT(Id) c FROM Service_Visit__c WHERE Seed_Tag__c LIKE 'SEED-%' AND Status__c = 'Completed' AND Total_Cost__c = 0`);
    const n = Number(r[0]?.c ?? 0);
    return { id: 7, name: 'sv-completed-zero-cost', description: '0 Completed service visits with Total_Cost__c = 0', expected: '0', actual: String(n), passed: n === 0, detail: '' };
}

async function gate8(input: GateInputs, canonical: CanonicalManifest): Promise<GateResult> {
    // Strong Gate 8: cross-reference the authoritative canonical manifest
    // (built from data/csv/*.csv) against live Salesforce records. Detects:
    //   - Missing canonical record (expected Seed_Tag__c not found in org)
    //   - Extra record (Seed_Tag__c in org but not in manifest — could be
    //     a duplicate or an unexpected insert; pre-existing non-SEED records
    //     are excluded because their Seed_Tag__c is null and they don't match
    //     the SEED-* pattern)
    //   - Malformed canonical tag (org Seed_Tag__c doesn't match manifest)
    //   - Duplicate canonical tag (same Seed_Tag__c maps to multiple Ids)
    // The manifest is the source of truth; pre-existing non-SEED records
    // are excluded by the SOQL filter (Seed_Tag__c LIKE 'SEED-%').
    const missing: string[] = [];
    const malformed: string[] = [];
    const extras: string[] = [];
    const dupes: string[] = [];
    for (const [obj, expectedTags] of Object.entries(canonical.tagsByObject)) {
        if (expectedTags.length === 0) continue;
        // Use a single IN clause query for efficiency. SOQL IN limit is ~200,
        // but our largest set is 200 (Tasks), so chunking is needed.
        const seen = new Set<string>();
        const orgTags = new Set<string>();
        for (let i = 0; i < expectedTags.length; i += 200) {
            const chunk = expectedTags.slice(i, i + 200);
            const inList = chunk.map((t) => `'${t.replace(/'/g, "\\'")}'`).join(',');
            const r = await input.query(`SELECT Seed_Tag__c FROM ${obj} WHERE Seed_Tag__c IN (${inList})`);
            for (const row of r) {
                const tag = (row as any).Seed_Tag__c as string;
                if (!tag) continue;
                orgTags.add(tag);
                if (seen.has(tag)) dupes.push(`${obj}/${tag}`);
                seen.add(tag);
                if (!expectedTags.includes(tag)) malformed.push(`${obj}/${tag}`);
            }
        }
        for (const tag of expectedTags) {
            if (!orgTags.has(tag)) missing.push(`${obj}/${tag}`);
        }
        // Extras: org has a SEED-* tag for this object that isn't in the manifest.
        // This catches unexpected inserts. We don't query for all org SEED-* tags
        // here (that would be expensive); the per-object count check in Gate 10
        // catches unexpected extras via the per-object count comparison.
    }
    // For extras detection: query each object for any SEED-* tag NOT in the
    // manifest. This is O(objects * SOQL) but the SEED-* filter keeps it
    // bounded to the canonical count per object.
    for (const [obj, expectedTags] of Object.entries(canonical.tagsByObject)) {
        if (expectedTags.length === 0) continue;
        const r = await input.query(`SELECT Seed_Tag__c FROM ${obj} WHERE Seed_Tag__c LIKE 'SEED-%'`);
        const expectedSet = new Set(expectedTags);
        for (const row of r) {
            const tag = (row as any).Seed_Tag__c as string;
            if (tag && !expectedSet.has(tag)) extras.push(`${obj}/${tag}`);
        }
    }
    const total = missing.length + malformed.length + extras.length + dupes.length;
    const summary: string[] = [];
    if (missing.length) summary.push(`missing=${missing.length}`);
    if (malformed.length) summary.push(`malformed=${malformed.length}`);
    if (extras.length) summary.push(`extras=${extras.length}`);
    if (dupes.length) summary.push(`dupes=${dupes.length}`);
    const detail = total > 0
        ? `${summary.join(' ')} (${[...missing, ...malformed, ...extras, ...dupes].slice(0, 5).join(', ')}${total > 5 ? '...' : ''})`
        : `verified ${Object.values(canonical.tagsByObject).reduce((a, b) => a + b.length, 0)} canonical tags across ${Object.keys(canonical.tagsByObject).length} objects`;
    return {
        id: 8, name: 'canonical-seed-tag-reconciliation',
        description: 'Every canonical Seed_Tag__c from data/csv/ exists exactly once in org with correct value; no missing/malformed/extra/duplicate tags',
        expected: 'all canonical tags present, no extras',
        actual: total === 0 ? '0 discrepancies' : `${total} discrepancies`,
        passed: total === 0,
        detail,
    };
}

async function gate9(input: GateInputs): Promise<GateResult> {
    const r = await input.query(`SELECT Status__c, COUNT(Id) c FROM Data_Load_Batch__c GROUP BY Status__c`);
    const bad = r.filter((x: any) => x.Status__c && !['Loaded', 'Partial'].includes(x.Status__c));
    const total = r.reduce((a: number, x: any) => a + Number(x.c), 0);
    const badCount = bad.reduce((a: number, x: any) => a + Number(x.c), 0);
    return {
        id: 9, name: 'batch-status', description: 'Every Data_Load_Batch__c row Status__c in {Loaded, Partial}',
        expected: 'all Loaded/Partial', actual: `${total} rows, ${badCount} bad`,
        passed: badCount === 0,  // vacuously true when total=0
        detail: bad.length > 0 ? `bad: ${bad.map((x: any) => `${x.Status__c}=${x.c}`).join(',')}` : '',
    };
}

async function gate10(input: GateInputs, canonical: CanonicalManifest): Promise<GateResult> {
    // Strong Gate 10: verify three distinct categories:
    //   A) Canonical loaded records (2,085 = 1,835 clean + 250 activities):
    //      per-object counts match EXPECTED_COUNTS; activities within ±2.
    //   B) Deferred SEED-98 legacy batch (0 actual vs 30 expected): verify
    //      that 0 SEED-98 records exist (deferred per owner).
    //   C) Full §2.1 envelope (2,115): requires A + 30 SEED-98 records.
    //      Currently NOT SATISFIED because SEED-98 is deferred.
    const canonicalErrors: string[] = [];
    let cleanTotal = 0;
    for (const [obj, expected] of Object.entries(EXPECTED_COUNTS)) {
        // OpportunityLineItem is a standard object without Seed_Tag__c; count all rows.
        const soql = obj === 'OpportunityLineItem'
            ? `SELECT COUNT(Id) c FROM ${obj}`
            : `SELECT COUNT(Id) c FROM ${obj} WHERE Seed_Tag__c LIKE 'SEED-%'`;
        const r = await input.query(soql);
        const actual = Number(r[0]?.c ?? 0);
        cleanTotal += actual;
        if (actual !== expected) canonicalErrors.push(`${obj}: exp=${expected} act=${actual}`);
    }
    const activityActual = input.taskCount + input.eventCount;
    const activityDelta = Math.abs(activityActual - ENVELOPE_2_1.activities);
    const activitiesOk = activityDelta <= ENVELOPE_2_1.activityTolerance;
    if (!activitiesOk) canonicalErrors.push(`activities: exp=${ENVELOPE_2_1.activities}±${ENVELOPE_2_1.activityTolerance} act=${activityActual}`);

    // SEED-98 deferred check: count records across objects with SEED-98- prefix.
    let seed98Count = 0;
    for (const obj of ['Account', 'Contact', 'Lead', 'Vehicle__c']) {
        const r = await input.query(`SELECT COUNT(Id) c FROM ${obj} WHERE Seed_Tag__c LIKE 'SEED-98-%'`);
        seed98Count += Number(r[0]?.c ?? 0);
    }
    const canonicalTotal = cleanTotal + activityActual;
    const canonicalOk = canonicalErrors.length === 0;
    const seed98DeferredOk = seed98Count === 0;  // 0 means deferred (not loaded)
    const envelopeOk = canonicalOk && seed98Count === ENVELOPE_2_1.legacy;  // full envelope requires all 30

    // Gate passes if canonical counts match (the actual scope of what was loaded).
    // The full envelope is reported as NOT SATISFIED because SEED-98 is deferred.
    const passed = canonicalOk;
    const detail = [
        `A) canonical: ${canonicalOk ? 'PASS' : 'FAIL'} (${canonicalTotal} actual = ${cleanTotal} clean + ${activityActual} activities vs ${ENVELOPE_2_1.clean + ENVELOPE_2_1.activities} expected)`,
        `B) SEED-98 deferred: ${seed98DeferredOk ? 'PASS' : 'FAIL'} (${seed98Count} actual vs 0 expected for deferred)`,
        `C) full §2.1 envelope: ${envelopeOk ? 'PASS' : 'NOT SATISFIED'} (${canonicalTotal} + ${seed98Count} = ${canonicalTotal + seed98Count} vs ${ENVELOPE_2_1.total} expected; 30 SEED-98 records deferred)`,
        canonicalErrors.length > 0 ? `errors: ${canonicalErrors.join('; ')}` : '',
    ].filter(Boolean).join(' | ');
    return {
        id: 10, name: 'counts-canonical-vs-envelope',
        description: `Canonical loaded records match (${ENVELOPE_2_1.clean + ENVELOPE_2_1.activities}); full §2.1 envelope (${ENVELOPE_2_1.total}) requires SEED-98 which is deferred`,
        expected: `canonical: ${ENVELOPE_2_1.clean + ENVELOPE_2_1.activities}; envelope: ${ENVELOPE_2_1.total}`,
        actual: `canonical: ${canonicalTotal} (${canonicalOk ? 'match' : 'mismatch'}); SEED-98: ${seed98Count} (deferred); envelope: ${canonicalTotal + seed98Count}/${ENVELOPE_2_1.total}`,
        passed, detail,
    };
}

async function gate11(input: GateInputs): Promise<GateResult> {
    // SOQL does not support `NOT LIKE`. Fetch all seeded Contact + Lead emails
    // and filter in-process for those not ending in .test or .example.
    const r = await input.query(`SELECT Email FROM Contact WHERE Seed_Tag__c LIKE 'SEED-%' AND Email != null`);
    const r2 = await input.query(`SELECT Email FROM Lead WHERE Seed_Tag__c LIKE 'SEED-%' AND Email != null`);
    const all = [...r, ...r2].map((x: any) => (x.Email as string) ?? '').filter((e) => e.length > 0);
    const offenders = all.filter((e) => !e.endsWith('.test') && !e.endsWith('.example'));
    return { id: 11, name: 'email-test-domain', description: '0 leads/contacts with email outside *.test domains', expected: '0', actual: String(offenders.length), passed: offenders.length === 0, detail: offenders.length > 0 ? `examples: ${offenders.slice(0, 3).join(', ')}` : '' };
}

async function gate12(input: GateInputs): Promise<GateResult> {
    const r = await input.query(`SELECT COUNT(Id) c FROM Consent__c WHERE Seed_Tag__c LIKE 'SEED-%' AND Status__c = 'Revoked' AND Revoked_On__c = null`);
    const n = Number(r[0]?.c ?? 0);
    return { id: 12, name: 'consent-revoked-date', description: '0 consent rows Revoked without Revoked_On__c', expected: '0', actual: String(n), passed: n === 0, detail: '' };
}

async function gate13(input: GateInputs): Promise<GateResult> {
    const budget = 4.0;
    const used = input.storageUsedMb;
    return {
        id: 13, name: 'storage-budget', description: `Storage Usage <= ${budget} MB after full reset`,
        expected: `<= ${budget} MB`, actual: `${used.toFixed(2)} MB`, passed: used <= budget, detail: '',
    };
}

async function gate14(input: GateInputs): Promise<GateResult> {
    // 0 records in SEED-98-* outside the 30-record legacy batch. Since SEED-98
    // is skipped by the canonical loader, count of SEED-98 records should be
    // either 0 (not loaded) or 30 (loaded as a single batch). Any other count
    // is a failure.
    const r = await input.query(`SELECT COUNT(Id) c FROM Account WHERE Seed_Tag__c LIKE 'SEED-98-%'`);
    const c1 = Number(r[0]?.c ?? 0);
    const r2 = await input.query(`SELECT COUNT(Id) c FROM Contact WHERE Seed_Tag__c LIKE 'SEED-98-%'`);
    const c2 = Number(r2[0]?.c ?? 0);
    const r3 = await input.query(`SELECT COUNT(Id) c FROM Lead WHERE Seed_Tag__c LIKE 'SEED-98-%'`);
    const c3 = Number(r3[0]?.c ?? 0);
    const r4 = await input.query(`SELECT COUNT(Id) c FROM Vehicle__c WHERE Seed_Tag__c LIKE 'SEED-98-%'`);
    const c4 = Number(r4[0]?.c ?? 0);
    const total = c1 + c2 + c3 + c4;
    const ok = total === 0 || total === 30;
    return {
        id: 14, name: 'seed98-boundary', description: '0 records in SEED-98-* outside the 30-record legacy batch (or 0 if not loaded)',
        expected: '0 or 30', actual: String(total), passed: ok,
        detail: !ok ? `Account=${c1} Contact=${c2} Lead=${c3} Vehicle=${c4}` : '',
    };
}

// ---------- Orchestrator ----------

type GateFn = (i: GateInputs, c: CanonicalManifest) => Promise<GateResult>;
const GATES: GateFn[] = [
    gate1, gate2, gate3, gate4, gate5, gate6, gate7, gate8, gate9, gate10, gate11, gate12, gate13, gate14,
];

export async function evaluateGates(input: GateInputs, canonical: CanonicalManifest): Promise<GateResult[]> {
    const results: GateResult[] = [];
    for (const g of GATES) {
        try {
            results.push(await g(input, canonical));
        } catch (e: any) {
            // A query that fails is NOT a pass. Report as failure with the error.
            results.push({
                id: -1, name: 'query-error', description: 'gate query failed',
                expected: '0', actual: `ERROR: ${e?.message ?? String(e)}`,
                passed: false, detail: '',
            });
        }
    }
    return results;
}

export function formatResults(results: GateResult[]): string {
    const lines: string[] = [];
    lines.push('Phase 5 §9a Release Gates');
    lines.push('='.repeat(70));
    for (const r of results) {
        const st = r.passed ? 'PASS' : 'FAIL';
        lines.push(`Gate ${String(r.id).padStart(2)} [${st}] ${r.name}`);
        lines.push(`        ${r.description}`);
        lines.push(`        expected: ${r.expected}    actual: ${r.actual}`);
        if (r.detail) lines.push(`        detail:   ${r.detail}`);
    }
    const pass = results.filter((r) => r.passed).length;
    const fail = results.length - pass;
    lines.push('='.repeat(70));
    lines.push(`Result: ${pass} PASS, ${fail} FAIL (of ${results.length})`);
    return lines.join('\n');
}

// ---------- CLI ----------

function sfQuery(soql: string, targetOrg: string): any[] {
    const out = execFileSync('sf', ['data', 'query', '--query', soql, '--result-format', 'json', '--target-org', targetOrg], { encoding: 'utf8' });
    const j = JSON.parse(out);
    if (j.status !== 0) throw new Error(`sf query failed: ${j.message ?? JSON.stringify(j).slice(0, 200)}`);
    return j.result?.records ?? [];
}

function getStorageMb(targetOrg: string): number {
    const out = execFileSync('sf', ['org', 'list', 'limits', '--target-org', targetOrg, '--json'], { encoding: 'utf8' });
    const j = JSON.parse(out);
    const arr = j.result ?? [];
    const dkm = arr.find((x: any) => x.name === 'DataStorageMB' || x.name === 'DataStorage');
    if (!dkm) throw new Error('DataStorage limit not found');
    // used = max - remaining (some orgs report used directly)
    const used = dkm.used ?? (dkm.max - dkm.remaining);
    return Number(used);
}

async function main(): Promise<void> {
    const targetOrg = process.env.SF_TARGET_ORG ?? 'ng-demo';
    process.stderr.write(`[verify] target org: ${targetOrg}\n`);

    process.stderr.write('[verify] querying Task count...\n');
    const taskCount = Number((await new Promise<any[]>((resolve, reject) => {
        try { resolve(sfQuery(`SELECT COUNT(Id) c FROM Task WHERE Seed_Tag__c LIKE 'SEED-%'`, targetOrg)); } catch (e) { reject(e); }
    }))[0]?.c ?? 0);
    process.stderr.write(`[verify] Task count: ${taskCount}\n`);

    process.stderr.write('[verify] querying Event count...\n');
    const eventCount = Number((await new Promise<any[]>((resolve, reject) => {
        try { resolve(sfQuery(`SELECT COUNT(Id) c FROM Event WHERE Seed_Tag__c LIKE 'SEED-%'`, targetOrg)); } catch (e) { reject(e); }
    }))[0]?.c ?? 0);
    process.stderr.write(`[verify] Event count: ${eventCount}\n`);

    process.stderr.write('[verify] querying storage...\n');
    const storageUsedMb = getStorageMb(targetOrg);
    process.stderr.write(`[verify] Storage used: ${storageUsedMb.toFixed(2)} MB\n`);

    const input: GateInputs = {
        query: async (soql: string) => sfQuery(soql, targetOrg),
        storageUsedMb,
        taskCount,
        eventCount,
    };

    process.stderr.write('[verify] building canonical manifest from data/csv/...\n');
    const csvDir = resolve(process.cwd(), 'data', 'csv');
    const canonical = buildCanonicalManifest(csvDir);
    process.stderr.write(`[verify] manifest: ${canonical.total} tags across ${Object.keys(canonical.tagsByObject).length} objects\n`);

    process.stderr.write('[verify] evaluating 14 gates...\n');
    const results = await evaluateGates(input, canonical);
    process.stderr.write('[verify] evaluation complete\n');

    const text = formatResults(results);
    process.stdout.write(text + '\n');

    // Persist evidence.
    const evidenceDir = resolve(process.cwd(), 'evidence', 'P5');
    mkdirSync(evidenceDir, { recursive: true });
    const evidencePath = resolve(evidenceDir, 'verify_gates.txt');
    const header = `# Phase 5 §9a Release Gate Verification\n# Target org: ${targetOrg}\n# Generated: ${new Date().toISOString()}\n# Storage used (MB): ${input.storageUsedMb.toFixed(2)}\n# Task count: ${input.taskCount}\n# Event count: ${input.eventCount}\n# Canonical manifest: ${canonical.total} Seed_Tag__c values across ${Object.keys(canonical.tagsByObject).length} objects (from data/csv/)\n\n`;
    writeFileSync(evidencePath, header + text + '\n', 'utf8');
    process.stderr.write(`[verify] evidence written: ${evidencePath}\n`);

    const failed = results.filter((r) => !r.passed).length;
    process.stderr.write(`[verify] done: ${results.length - failed} PASS, ${failed} FAIL\n`);
    process.exit(failed === 0 ? 0 : 1);
}

// Run when invoked as CLI. When imported as a module, main is not called.
const isMain = (() => {
    const arg = process.argv[1] ?? '';
    const url = import.meta.url ?? '';
    if (!arg || !url) return true;  // npx tsx: treat as CLI when context is ambiguous
    // Decode the URL to handle percent-encoded paths (e.g. spaces in paths).
    let decoded = url;
    try { decoded = decodeURIComponent(url); } catch { /* keep original */ }
    return decoded === `file://${arg}` || decoded.endsWith(arg);
})();
if (isMain) {
    main().catch((e) => {
        process.stderr.write(`[verify] FATAL: ${e?.message ?? e}\n`);
        process.exit(2);
    });
}
