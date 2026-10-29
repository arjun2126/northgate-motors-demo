/**
 * Verifier tests — exercise the pure core (evaluateGates, formatResults,
 * buildCanonicalManifest) with a fake query function. No Salesforce calls.
 */
import { strict as assert } from 'node:assert';
import { evaluateGates, formatResults, GateInputs, buildCanonicalManifest, CanonicalManifest } from '../verify.js';
import { mkdtempSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

// Build a CanonicalManifest by writing CSVs to a temp dir that match the
// CANONICAL_OBJECT_TO_CSV filenames, then calling buildCanonicalManifest.
// Returns both the manifest and the temp dir path (caller must clean up).
function makeManifestEnv(tagsByObject: Record<string, string[]>): { manifest: CanonicalManifest; dir: string } {
    const dir = mkdtempSync(join(tmpdir(), 'p5m-'));
    // CANONICAL_OBJECT_TO_CSV maps object name to CSV filename (e.g. '01-rooftops.csv').
    // We need to write files with those exact names.
    const fileMap: Record<string, string> = {
        'Rooftop__c': '01-rooftops.csv', 'Vehicle_Model__c': '02-models.csv',
        'Product2': '03-products.csv', 'PricebookEntry': '04-pricebookentries.csv',
        'Staff__c': '05-staff.csv', 'Vehicle__c': '06-vehicles.csv',
        'Account': '07-accounts.csv', 'Contact': '08-contacts.csv',
        'Lead': '09-leads.csv', 'Opportunity': '10-opportunities.csv',
        'OpportunityLineItem': '11-opptylineitems.csv', 'Quote': '12-quotes.csv',
        'QuoteLineItem': '13-quotelineitems.csv', 'Trade_In__c': '14-tradeins.csv',
        'Financing__c': '15-financing.csv', 'Delivery__c': '16-deliveries.csv',
        'Test_Drive__c': '17-testdrives.csv', 'Case': '18-cases.csv',
        'Service_Visit__c': '19-servicevisits.csv', 'Campaign': '20-campaigns.csv',
        'CampaignMember': '21-campaignmembers.csv', 'Loyalty_Member__c': '22-loyaltymembers.csv',
        'Loyalty_Transaction__c': '23-loyaltytxns.csv', 'Consent__c': '24-consents.csv',
        'Task': '25-tasks.csv', 'Event': '26-events.csv', 'Data_Load_Batch__c': '27-dataloadbatches.csv',
    };
    for (const [obj, tags] of Object.entries(tagsByObject)) {
        const csvName = fileMap[obj];
        if (!csvName) continue;
        // OLI uses OLI_Row_Id__c, not Seed_Tag__c. Skip if no tags.
        if (obj === 'OpportunityLineItem' || tags.length === 0) {
            writeFileSync(join(dir, csvName), 'Seed_Tag__c\n', 'utf8');
            continue;
        }
        const csv = 'Seed_Tag__c\n' + tags.join('\n') + '\n';
        writeFileSync(join(dir, csvName), csv, 'utf8');
    }
    const manifest = buildCanonicalManifest(dir);
    return { manifest, dir };
}

function cleanup(dir: string) { rmSync(dir, { recursive: true, force: true }); }

// Empty manifest: no objects have tags.
const emptyManifest: CanonicalManifest = { tagsByObject: {}, total: 0 };

function fakeQuery(map: Record<string, number>): (soql: string) => Promise<any[]> {
    return async (soql: string) => {
        if (soql.includes('GROUP BY Status__c')) {
            const n = map['GROUP BY Status__c'] ?? 0;
            if (n === 0) return [];
            return [{ Status__c: 'Loaded', c: n }];
        }
        if (soql.includes('GROUP BY VIN__c')) {
            const n = map['GROUP BY VIN__c'] ?? 0;
            if (n === 0) return [];
            return [{ v: 'DUP', c: n }];
        }
        for (const [key, val] of Object.entries(map)) {
            if (soql.includes(key)) return [{ c: val }];
        }
        return [{ c: 0 }];
    };
}

const baselineInput: GateInputs = {
    query: fakeQuery({ 'GROUP BY Status__c': 20 }),
    storageUsedMb: 3.0,
    taskCount: 200,
    eventCount: 50,
};

// Build a clean manifest with expected counts matching the plan.
function cleanManifest(): { manifest: CanonicalManifest; dir: string } {
    const expected: Record<string, number> = {
        'Rooftop__c': 4, 'Vehicle_Model__c': 30, 'Vehicle__c': 120, 'Product2': 60,
        'PricebookEntry': 60, 'Account': 150, 'Contact': 185, 'Lead': 130,
        'Opportunity': 100, 'OpportunityLineItem': 100, 'Quote': 60, 'QuoteLineItem': 80,
        'Trade_In__c': 45, 'Financing__c': 60, 'Delivery__c': 12, 'Test_Drive__c': 70,
        'Service_Visit__c': 140, 'Case': 60, 'Loyalty_Member__c': 70,
        'Loyalty_Transaction__c': 110, 'Consent__c': 90, 'Staff__c': 14,
        'Campaign': 5, 'CampaignMember': 60, 'Data_Load_Batch__c': 20,
    };
    const tagsByObject: Record<string, string[]> = {};
    let n = 1;
    for (const [obj, count] of Object.entries(expected)) {
        const tags: string[] = [];
        for (let i = 0; i < count; i++) {
            tags.push(`SEED-${obj.replace(/__c$/, '').slice(0, 2)}-${String(++n).padStart(3, '0')}`);
        }
        tagsByObject[obj] = tags;
    }
    return makeManifestEnv(tagsByObject);
}

async function t1() {
    // All gates PASS when no defects are present.
    const { manifest, dir } = cleanManifest();
    try {
        const expected: Record<string, number> = {
            'Rooftop__c': 4, 'Vehicle_Model__c': 30, 'Vehicle__c': 120, 'Product2': 60,
            'PricebookEntry': 60, 'Account': 150, 'Contact': 185, 'Lead': 130,
            'Opportunity': 100, 'OpportunityLineItem': 100, 'Quote': 60, 'QuoteLineItem': 80,
            'Trade_In__c': 45, 'Financing__c': 60, 'Delivery__c': 12, 'Test_Drive__c': 70,
            'Service_Visit__c': 140, 'Case': 60, 'Loyalty_Member__c': 70,
            'Loyalty_Transaction__c': 110, 'Consent__c': 90, 'Staff__c': 14,
            'Campaign': 5, 'CampaignMember': 60, 'Data_Load_Batch__c': 20,
        };
        const allTags: string[] = [];
        for (const tags of Object.values(manifest.tagsByObject)) allTags.push(...tags);
        const tagSet = new Set(allTags);

        const isDefectFilter = (s: string) =>
            /Is_VIN_Valid__c\s*=\s*false|GROUP BY|HAVING|Seed_Tag__c\s*=\s*null|Seed_Tag__c\s*=\s*''|NOT\s+Seed_Tag__c|Amount\s*<=\s*0|StageName\s*!=|IsWon\s*=\s*true|Annual_Rate__c\s*<\s*0|Annual_Rate__c\s*>\s*25|Term_Months__c\s*!=\s*\d|Points_Balance__c\s*<\s*0|Total_Cost__c\s*=\s*0|Email\s+LIKE|Status__c\s*=\s*'Revoked'|Revoked_On__c\s*=\s*null|SEED-98-%/i.test(s);

        const q = async (soql: string) => {
            if (soql.includes('GROUP BY Status__c')) return [{ Status__c: 'Loaded', c: 20 }];
            if (soql.includes('GROUP BY VIN__c')) return [];
            if (soql.includes('SELECT COUNT(Id) c FROM Task')) return [{ c: 200 }];
            if (soql.includes('SELECT COUNT(Id) c FROM Event')) return [{ c: 50 }];
            if (soql.includes('SELECT COUNT(Id) c FROM OpportunityLineItem')) {
                if (soql.includes('SEED-%')) return [{ c: 0 }];
                return [{ c: 100 }];
            }
            if (soql.includes('SELECT Email FROM Contact')) return [{ Email: 'a@example.test' }];
            if (soql.includes('SELECT Email FROM Lead')) return [{ Email: 'b@example.test' }];
            // Gate 8: return all canonical tags as found
            if (/SELECT Seed_Tag__c FROM \S+ WHERE Seed_Tag__c IN/.test(soql)) {
                const objMatch = soql.match(/FROM (\S+)/);
                if (objMatch) {
                    const tags = manifest.tagsByObject[objMatch[1]] ?? [];
                    return tags.map((t) => ({ Seed_Tag__c: t }));
                }
            }
            if (/SELECT Seed_Tag__c FROM \S+ WHERE Seed_Tag__c LIKE 'SEED-%'/.test(soql)) {
                const objMatch = soql.match(/FROM (\S+)/);
                if (objMatch) {
                    const tags = manifest.tagsByObject[objMatch[1]] ?? [];
                    return tags.map((t) => ({ Seed_Tag__c: t }));
                }
            }
            if (isDefectFilter(soql)) return [{ c: 0 }];
            for (const [obj, n] of Object.entries(expected)) {
                if (soql.includes(`FROM ${obj} `) || soql.includes(`FROM ${obj}\n`) || soql.endsWith(`FROM ${obj}`)) return [{ c: n }];
            }
            return [{ c: 0 }];
        };
        const r = await evaluateGates({ ...baselineInput, query: q }, manifest);
        assert.equal(r.length, 14);
        const failures = r.filter((g) => !g.passed);
        assert.equal(failures.length, 0, `unexpected failures: ${failures.map((g) => g.id + ':' + g.name + '=' + g.actual + ' (' + g.detail + ')').join(', ')}`);
        console.log('  PASS verify: all 14 gates clean → all PASS');
    } finally { cleanup(dir); }
}

async function t2() {
    const { manifest, dir } = cleanManifest();
    try {
        const input: GateInputs = { ...baselineInput, query: fakeQuery({ 'Is_VIN_Valid__c = false': 3, 'GROUP BY VIN__c': 0 }) };
        const r = await evaluateGates(input, manifest);
        const g1 = r.find((x) => x.id === 1)!;
        assert.equal(g1.passed, false);
        assert.equal(g1.actual, '3');
        console.log('  PASS verify: gate 1 catches invalid VINs');
    } finally { cleanup(dir); }
}

async function t3() {
    const { manifest, dir } = cleanManifest();
    try {
        const input: GateInputs = { ...baselineInput, query: fakeQuery({ 'Is_VIN_Valid__c = false': 0, 'GROUP BY VIN__c': 2 }) };
        const r = await evaluateGates(input, manifest);
        const g2 = r.find((x) => x.id === 2)!;
        assert.equal(g2.passed, false);
        assert.equal(g2.actual, '1');
        console.log('  PASS verify: gate 2 catches duplicate VINs');
    } finally { cleanup(dir); }
}

async function t4() {
    const { manifest, dir } = cleanManifest();
    try {
        const input: GateInputs = { ...baselineInput, query: fakeQuery({ 'Amount <= 0 AND StageName': 5, 'GROUP BY VIN__c': 0, 'Is_VIN_Valid__c = false': 0 }) };
        const r = await evaluateGates(input, manifest);
        const g3 = r.find((x) => x.id === 3)!;
        assert.equal(g3.passed, false);
        console.log('  PASS verify: gate 3 catches non-positive Amount');
    } finally { cleanup(dir); }
}

async function t5() {
    const { manifest, dir } = cleanManifest();
    try {
        const input: GateInputs = { ...baselineInput, query: fakeQuery({ 'IsWon = true AND Delivery_Completed__c = false': 1 }) };
        const r = await evaluateGates(input, manifest);
        const g4 = r.find((x) => x.id === 4)!;
        assert.equal(g4.passed, false);
        console.log('  PASS verify: gate 4 catches Won without Delivery');
    } finally { cleanup(dir); }
}

async function t6() {
    const { manifest, dir } = cleanManifest();
    try {
        const input: GateInputs = { ...baselineInput, query: fakeQuery({ 'Annual_Rate__c < 0 OR Annual_Rate__c > 25': 2 }) };
        const r = await evaluateGates(input, manifest);
        const g5 = r.find((x) => x.id === 5)!;
        assert.equal(g5.passed, false);
        console.log('  PASS verify: gate 5 catches bad Financing rate/term');
    } finally { cleanup(dir); }
}

// --- Gate 8 regression tests (strong canonical-tag reconciliation) ---

async function t8a() {
    // Missing canonical tag: org does not have one of the expected tags.
    const { manifest, dir } = cleanManifest();
    try {
        // Fake returns all tags EXCEPT the first Account tag.
        const accountTags = manifest.tagsByObject['Account'] ?? [];
        const omitted = accountTags[0]!;
        const q = async (soql: string) => {
            if (/SELECT Seed_Tag__c FROM Account WHERE Seed_Tag__c IN/.test(soql)) {
                return accountTags.filter((t) => t !== omitted).map((t) => ({ Seed_Tag__c: t }));
            }
            if (/SELECT Seed_Tag__c FROM Account WHERE Seed_Tag__c LIKE 'SEED-%'/.test(soql)) {
                return accountTags.filter((t) => t !== omitted).map((t) => ({ Seed_Tag__c: t }));
            }
            if (/SELECT COUNT\(Id\) c FROM Account WHERE Seed_Tag__c LIKE 'SEED-%'/.test(soql)) {
                return [{ c: accountTags.length - 1 }];
            }
            return defaultFake(soql, manifest);
        };
        const r = await evaluateGates({ ...baselineInput, query: q }, manifest);
        const g8 = r.find((x) => x.id === 8)!;
        assert.equal(g8.passed, false);
        assert.ok(g8.detail.includes('missing'), `expected missing in detail, got: ${g8.detail}`);
        console.log('  PASS verify: gate 8 detects MISSING canonical tag');
    } finally { cleanup(dir); }
}

async function t8b() {
    // Duplicate canonical tag: org has the same tag twice for the same object.
    const { manifest, dir } = cleanManifest();
    try {
        const accountTags = manifest.tagsByObject['Account'] ?? [];
        const q = async (soql: string) => {
            if (/SELECT Seed_Tag__c FROM Account WHERE Seed_Tag__c IN/.test(soql)) {
                // Return each tag once, but the first tag twice (duplicate Id not detectable here,
                // but duplicate tag IS: we return the same tag twice in the result set).
                const out: any[] = [];
                for (const t of accountTags) out.push({ Seed_Tag__c: t });
                out.push({ Seed_Tag__c: accountTags[0] }); // duplicate
                return out;
            }
            if (/SELECT Seed_Tag__c FROM Account WHERE Seed_Tag__c LIKE 'SEED-%'/.test(soql)) {
                return accountTags.map((t) => ({ Seed_Tag__c: t }));
            }
            if (/SELECT COUNT\(Id\) c FROM Account WHERE Seed_Tag__c LIKE 'SEED-%'/.test(soql)) {
                return [{ c: accountTags.length + 1 }];
            }
            return defaultFake(soql, manifest);
        };
        const r = await evaluateGates({ ...baselineInput, query: q }, manifest);
        const g8 = r.find((x) => x.id === 8)!;
        assert.equal(g8.passed, false);
        assert.ok(g8.detail.includes('dupes'), `expected dupes in detail, got: ${g8.detail}`);
        console.log('  PASS verify: gate 8 detects DUPLICATE canonical tag');
    } finally { cleanup(dir); }
}

async function t8c() {
    // Malformed canonical tag: org has a SEED-* tag that is NOT in the manifest.
    const { manifest, dir } = cleanManifest();
    try {
        const accountTags = manifest.tagsByObject['Account'] ?? [];
        const rogue = 'SEED-99-XXX';
        const q = async (soql: string) => {
            if (/SELECT Seed_Tag__c FROM Account WHERE Seed_Tag__c IN/.test(soql)) {
                return accountTags.map((t) => ({ Seed_Tag__c: t }));
            }
            if (/SELECT Seed_Tag__c FROM Account WHERE Seed_Tag__c LIKE 'SEED-%'/.test(soql)) {
                return [...accountTags.map((t) => ({ Seed_Tag__c: t })), { Seed_Tag__c: rogue }];
            }
            if (/SELECT COUNT\(Id\) c FROM Account WHERE Seed_Tag__c LIKE 'SEED-%'/.test(soql)) {
                return [{ c: accountTags.length + 1 }];
            }
            return defaultFake(soql, manifest);
        };
        const r = await evaluateGates({ ...baselineInput, query: q }, manifest);
        const g8 = r.find((x) => x.id === 8)!;
        assert.equal(g8.passed, false);
        assert.ok(g8.detail.includes('extras') || g8.detail.includes('malformed'), `expected extras/malformed, got: ${g8.detail}`);
        console.log('  PASS verify: gate 8 detects MALFORMED/EXTRA canonical tag');
    } finally { cleanup(dir); }
}

async function t8d() {
    // Pre-existing untagged records are NOT flagged (they have no SEED-* tag).
    const { manifest, dir } = cleanManifest();
    try {
        const q = async (soql: string) => {
            if (/SELECT Seed_Tag__c FROM \S+ WHERE Seed_Tag__c IN/.test(soql)) {
                const m = soql.match(/FROM (\S+)/);
                if (m) return (manifest.tagsByObject[m[1]] ?? []).map((t) => ({ Seed_Tag__c: t }));
            }
            // Pre-existing untagged records: the LIKE 'SEED-%' query returns only
            // the canonical tags (no extras with null Seed_Tag__c).
            if (/SELECT Seed_Tag__c FROM \S+ WHERE Seed_Tag__c LIKE 'SEED-%'/.test(soql)) {
                const m = soql.match(/FROM (\S+)/);
                if (m) return (manifest.tagsByObject[m[1]] ?? []).map((t) => ({ Seed_Tag__c: t }));
            }
            return defaultFake(soql, manifest);
        };
        const r = await evaluateGates({ ...baselineInput, query: q }, manifest);
        const g8 = r.find((x) => x.id === 8)!;
        assert.equal(g8.passed, true, `pre-existing untagged should not fail gate 8, got: ${g8.detail}`);
        console.log('  PASS verify: gate 8 ignores pre-existing untagged records');
    } finally { cleanup(dir); }
}

// --- Gate 10 regression tests (canonical vs envelope) ---

async function t10a() {
    // Correct canonical counts + SEED-98 deferred → gate 10 PASS with envelope NOT SATISFIED.
    const { manifest, dir } = cleanManifest();
    try {
        const q = async (soql: string) => {
            if (/SELECT COUNT\(Id\) c FROM \S+ WHERE Seed_Tag__c LIKE 'SEED-98-%'/.test(soql)) return [{ c: 0 }];
            if (/SELECT COUNT\(Id\) c FROM OpportunityLineItem/.test(soql)) {
                if (soql.includes('SEED-%')) return [{ c: 0 }];
                return [{ c: 100 }];
            }
            return defaultFake(soql, manifest);
        };
        const r = await evaluateGates({ ...baselineInput, query: q }, manifest);
        const g10 = r.find((x) => x.id === 10)!;
        assert.equal(g10.passed, true);
        assert.ok(g10.detail.includes('envelope: NOT SATISFIED'), `expected envelope NOT SATISFIED, got: ${g10.detail}`);
        assert.ok(g10.detail.includes('30 SEED-98 records deferred'));
        console.log('  PASS verify: gate 10 canonical PASS + envelope NOT SATISFIED (SEED-98 deferred)');
    } finally { cleanup(dir); }
}

async function t10b() {
    // Missing canonical record: Account count is 1 less than expected.
    const { manifest, dir } = cleanManifest();
    try {
        const expected: Record<string, number> = {
            'Rooftop__c': 4, 'Vehicle_Model__c': 30, 'Vehicle__c': 120, 'Product2': 60,
            'PricebookEntry': 60, 'Account': 150, 'Contact': 185, 'Lead': 130,
            'Opportunity': 100, 'OpportunityLineItem': 100, 'Quote': 60, 'QuoteLineItem': 80,
            'Trade_In__c': 45, 'Financing__c': 60, 'Delivery__c': 12, 'Test_Drive__c': 70,
            'Service_Visit__c': 140, 'Case': 60, 'Loyalty_Member__c': 70,
            'Loyalty_Transaction__c': 110, 'Consent__c': 90, 'Staff__c': 14,
            'Campaign': 5, 'CampaignMember': 60, 'Data_Load_Batch__c': 20,
        };
        const q = async (soql: string) => {
            if (/SELECT COUNT\(Id\) c FROM \S+ WHERE Seed_Tag__c LIKE 'SEED-98-%'/.test(soql)) return [{ c: 0 }];
            if (/SELECT COUNT\(Id\) c FROM OpportunityLineItem/.test(soql)) {
                if (soql.includes('SEED-%')) return [{ c: 0 }];
                return [{ c: 100 }];
            }
            for (const [obj, n] of Object.entries(expected)) {
                if (soql.includes(`FROM ${obj} `) || soql.includes(`FROM ${obj}\n`) || soql.endsWith(`FROM ${obj}`)) {
                    return [{ c: n + (obj === 'Account' ? -1 : 0) }];
                }
            }
            return defaultFake(soql, manifest);
        };
        const r = await evaluateGates({ ...baselineInput, query: q }, manifest);
        const g10 = r.find((x) => x.id === 10)!;
        assert.equal(g10.passed, false);
        assert.ok(g10.detail.includes('Account'));
        console.log('  PASS verify: gate 10 detects MISSING canonical record (count off by 1)');
    } finally { cleanup(dir); }
}

async function t10c() {
    // Unexpected extra record: Account count is 1 more than expected.
    const { manifest, dir } = cleanManifest();
    try {
        const expected: Record<string, number> = {
            'Rooftop__c': 4, 'Vehicle_Model__c': 30, 'Vehicle__c': 120, 'Product2': 60,
            'PricebookEntry': 60, 'Account': 150, 'Contact': 185, 'Lead': 130,
            'Opportunity': 100, 'OpportunityLineItem': 100, 'Quote': 60, 'QuoteLineItem': 80,
            'Trade_In__c': 45, 'Financing__c': 60, 'Delivery__c': 12, 'Test_Drive__c': 70,
            'Service_Visit__c': 140, 'Case': 60, 'Loyalty_Member__c': 70,
            'Loyalty_Transaction__c': 110, 'Consent__c': 90, 'Staff__c': 14,
            'Campaign': 5, 'CampaignMember': 60, 'Data_Load_Batch__c': 20,
        };
        const q = async (soql: string) => {
            if (/SELECT COUNT\(Id\) c FROM \S+ WHERE Seed_Tag__c LIKE 'SEED-98-%'/.test(soql)) return [{ c: 0 }];
            if (/SELECT COUNT\(Id\) c FROM OpportunityLineItem/.test(soql)) {
                if (soql.includes('SEED-%')) return [{ c: 0 }];
                return [{ c: 100 }];
            }
            for (const [obj, n] of Object.entries(expected)) {
                if (soql.includes(`FROM ${obj} `) || soql.includes(`FROM ${obj}\n`) || soql.endsWith(`FROM ${obj}`)) {
                    return [{ c: n + (obj === 'Account' ? 1 : 0) }];
                }
            }
            return defaultFake(soql, manifest);
        };
        const r = await evaluateGates({ ...baselineInput, query: q }, manifest);
        const g10 = r.find((x) => x.id === 10)!;
        assert.equal(g10.passed, false);
        assert.ok(g10.detail.includes('Account'));
        console.log('  PASS verify: gate 10 detects UNEXPECTED EXTRA canonical record');
    } finally { cleanup(dir); }
}

async function t10d() {
    // SEED-98 boundary: 30 records (fully loaded) → envelope SATISFIED.
    const { manifest, dir } = cleanManifest();
    try {
        const q = async (soql: string) => {
            if (/SELECT COUNT\(Id\) c FROM Account WHERE Seed_Tag__c LIKE 'SEED-98-%'/.test(soql)) return [{ c: 30 }];
            if (/SELECT COUNT\(Id\) c FROM Contact WHERE Seed_Tag__c LIKE 'SEED-98-%'/.test(soql)) return [{ c: 0 }];
            if (/SELECT COUNT\(Id\) c FROM Lead WHERE Seed_Tag__c LIKE 'SEED-98-%'/.test(soql)) return [{ c: 0 }];
            if (/SELECT COUNT\(Id\) c FROM Vehicle__c WHERE Seed_Tag__c LIKE 'SEED-98-%'/.test(soql)) return [{ c: 0 }];
            if (/SELECT COUNT\(Id\) c FROM OpportunityLineItem/.test(soql)) {
                if (soql.includes('SEED-%')) return [{ c: 0 }];
                return [{ c: 100 }];
            }
            return defaultFake(soql, manifest);
        };
        const r = await evaluateGates({ ...baselineInput, query: q }, manifest);
        const g10 = r.find((x) => x.id === 10)!;
        assert.equal(g10.passed, true);
        assert.ok(g10.detail.includes('envelope: PASS'), `expected envelope PASS, got: ${g10.detail}`);
        console.log('  PASS verify: gate 10 envelope SATISFIED when 30 SEED-98 loaded');
    } finally { cleanup(dir); }
}

async function t10e() {
    // Incorrect actual count: per-object count wrong → gate 10 FAIL.
    const { manifest, dir } = cleanManifest();
    try {
        const expected: Record<string, number> = {
            'Rooftop__c': 4, 'Vehicle_Model__c': 30, 'Vehicle__c': 120, 'Product2': 60,
            'PricebookEntry': 60, 'Account': 150, 'Contact': 185, 'Lead': 130,
            'Opportunity': 100, 'OpportunityLineItem': 100, 'Quote': 60, 'QuoteLineItem': 80,
            'Trade_In__c': 45, 'Financing__c': 60, 'Delivery__c': 12, 'Test_Drive__c': 70,
            'Service_Visit__c': 140, 'Case': 60, 'Loyalty_Member__c': 70,
            'Loyalty_Transaction__c': 110, 'Consent__c': 90, 'Staff__c': 14,
            'Campaign': 5, 'CampaignMember': 60, 'Data_Load_Batch__c': 20,
        };
        const q = async (soql: string) => {
            if (/SELECT COUNT\(Id\) c FROM \S+ WHERE Seed_Tag__c LIKE 'SEED-98-%'/.test(soql)) return [{ c: 0 }];
            if (/SELECT COUNT\(Id\) c FROM OpportunityLineItem/.test(soql)) {
                if (soql.includes('SEED-%')) return [{ c: 0 }];
                return [{ c: 100 }];
            }
            for (const [obj, n] of Object.entries(expected)) {
                if (soql.includes(`FROM ${obj} `) || soql.includes(`FROM ${obj}\n`) || soql.endsWith(`FROM ${obj}`)) {
                    return [{ c: n + (obj === 'Financing__c' ? -1 : 0) }];
                }
            }
            return defaultFake(soql, manifest);
        };
        const r = await evaluateGates({ ...baselineInput, query: q }, manifest);
        const g10 = r.find((x) => x.id === 10)!;
        assert.equal(g10.passed, false);
        assert.ok(g10.detail.includes('Financing__c'));
        console.log('  PASS verify: gate 10 detects INCORRECT ACTUAL COUNT');
    } finally { cleanup(dir); }
}

// Default fake for tests that don't need custom behavior: return expected counts.
function defaultFake(soql: string, manifest: CanonicalManifest): any[] {
    const expected: Record<string, number> = {
        'Rooftop__c': 4, 'Vehicle_Model__c': 30, 'Vehicle__c': 120, 'Product2': 60,
        'PricebookEntry': 60, 'Account': 150, 'Contact': 185, 'Lead': 130,
        'Opportunity': 100, 'OpportunityLineItem': 100, 'Quote': 60, 'QuoteLineItem': 80,
        'Trade_In__c': 45, 'Financing__c': 60, 'Delivery__c': 12, 'Test_Drive__c': 70,
        'Service_Visit__c': 140, 'Case': 60, 'Loyalty_Member__c': 70,
        'Loyalty_Transaction__c': 110, 'Consent__c': 90, 'Staff__c': 14,
        'Campaign': 5, 'CampaignMember': 60, 'Data_Load_Batch__c': 20,
    };
    if (soql.includes('GROUP BY Status__c')) return [{ Status__c: 'Loaded', c: 20 }];
    if (soql.includes('GROUP BY VIN__c')) return [];
    if (soql.includes('SELECT COUNT(Id) c FROM Task')) return [{ c: 200 }];
    if (soql.includes('SELECT COUNT(Id) c FROM Event')) return [{ c: 50 }];
    if (soql.includes('SELECT COUNT(Id) c FROM OpportunityLineItem')) {
        if (soql.includes('SEED-%')) return [{ c: 0 }];
        return [{ c: 100 }];
    }
    if (soql.includes('SELECT Email FROM Contact')) return [{ Email: 'a@example.test' }];
    if (soql.includes('SELECT Email FROM Lead')) return [{ Email: 'b@example.test' }];
    if (/SELECT Seed_Tag__c FROM \S+ WHERE Seed_Tag__c IN/.test(soql)) {
        const m = soql.match(/FROM (\S+)/);
        if (m) return (manifest.tagsByObject[m[1]] ?? []).map((t) => ({ Seed_Tag__c: t }));
    }
    if (/SELECT Seed_Tag__c FROM \S+ WHERE Seed_Tag__c LIKE 'SEED-%'/.test(soql)) {
        const m = soql.match(/FROM (\S+)/);
        if (m) return (manifest.tagsByObject[m[1]] ?? []).map((t) => ({ Seed_Tag__c: t }));
    }
    for (const [obj, n] of Object.entries(expected)) {
        if (soql.includes(`FROM ${obj} `) || soql.includes(`FROM ${obj}\n`) || soql.endsWith(`FROM ${obj}`)) return [{ c: n }];
    }
    return [{ c: 0 }];
}

async function t9() {
    // Gate 9 fails when batch status is not Loaded/Partial.
    const { manifest, dir } = cleanManifest();
    try {
        const q = async (soql: string) => {
            if (soql.includes('GROUP BY Status__c')) return [{ Status__c: 'Failed', c: 2 }];
            return defaultFake(soql, manifest);
        };
        const r = await evaluateGates({ ...baselineInput, query: q }, manifest);
        const g9 = r.find((x) => x.id === 9)!;
        assert.equal(g9.passed, false);
        assert.ok(g9.detail.includes('Failed'));
        console.log('  PASS verify: gate 9 catches non-Loaded/Partial batch status');
    } finally { cleanup(dir); }
}

async function t11() {
    // Gate 11 catches non-.test emails.
    const { manifest, dir } = cleanManifest();
    try {
        const q = async (soql: string) => {
            if (soql.includes('FROM Contact')) return [{ Email: 'bad@example.com' }, { Email: 'ok@example.test' }];
            if (soql.includes('FROM Lead')) return [{ Email: 'alsobad@gmail.com' }];
            return defaultFake(soql, manifest);
        };
        const r = await evaluateGates({ ...baselineInput, query: q }, manifest);
        const g11 = r.find((x) => x.id === 11)!;
        assert.equal(g11.passed, false);
        assert.equal(g11.actual, '2');
        console.log('  PASS verify: gate 11 catches non-.test emails');
    } finally { cleanup(dir); }
}

async function t12() {
    // Gate 12 catches Revoked consent without Revoked_On__c.
    const { manifest, dir } = cleanManifest();
    try {
        const input: GateInputs = { ...baselineInput, query: fakeQuery({ "Status__c = 'Revoked' AND Revoked_On__c = null": 2 }) };
        const r = await evaluateGates(input, manifest);
        const g12 = r.find((x) => x.id === 12)!;
        assert.equal(g12.passed, false);
        console.log('  PASS verify: gate 12 catches Revoked without date');
    } finally { cleanup(dir); }
}

async function t13() {
    // Gate 13 fails when storage exceeds 4.0 MB.
    const { manifest, dir } = cleanManifest();
    try {
        const r = await evaluateGates({ ...baselineInput, storageUsedMb: 4.5 }, manifest);
        const g13 = r.find((x) => x.id === 13)!;
        assert.equal(g13.passed, false);
        assert.equal(g13.actual, '4.50 MB');
        console.log('  PASS verify: gate 13 catches over-budget storage');
    } finally { cleanup(dir); }
}

async function t14() {
    // Gate 14: 0 SEED-98 → PASS; 30 → PASS; 15 → FAIL.
    const { manifest, dir } = cleanManifest();
    try {
        const q30 = async (soql: string) => {
            if (soql.includes('FROM Account')) return [{ c: 10 }];
            if (soql.includes('FROM Contact')) return [{ c: 10 }];
            if (soql.includes('FROM Lead')) return [{ c: 5 }];
            if (soql.includes('FROM Vehicle__c')) return [{ c: 5 }];
            return defaultFake(soql, manifest);
        };
        const r30 = await evaluateGates({ ...baselineInput, query: q30 }, manifest);
        const g14_30 = r30.find((x) => x.id === 14)!;
        assert.equal(g14_30.passed, true, `30 should pass: ${g14_30.detail}`);

        const q0 = async (soql: string) => {
            if (soql.includes('FROM Account')) return [{ c: 0 }];
            if (soql.includes('FROM Contact')) return [{ c: 0 }];
            if (soql.includes('FROM Lead')) return [{ c: 0 }];
            if (soql.includes('FROM Vehicle__c')) return [{ c: 0 }];
            return defaultFake(soql, manifest);
        };
        const r0 = await evaluateGates({ ...baselineInput, query: q0 }, manifest);
        const g14_0 = r0.find((x) => x.id === 14)!;
        assert.equal(g14_0.passed, true, `0 should pass: ${g14_0.detail}`);

        const q15 = async (soql: string) => {
            if (soql.includes('FROM Account')) return [{ c: 15 }];
            if (soql.includes('FROM Contact')) return [{ c: 0 }];
            if (soql.includes('FROM Lead')) return [{ c: 0 }];
            if (soql.includes('FROM Vehicle__c')) return [{ c: 0 }];
            return defaultFake(soql, manifest);
        };
        const r15 = await evaluateGates({ ...baselineInput, query: q15 }, manifest);
        const g14_15 = r15.find((x) => x.id === 14)!;
        assert.equal(g14_15.passed, false);
        console.log('  PASS verify: gate 14 boundary (0 and 30 pass, 15 fails)');
    } finally { cleanup(dir); }
}

async function t15() {
    // A query that throws must NOT be a pass.
    const { manifest, dir } = cleanManifest();
    try {
        const throwingQuery = async (soql: string): Promise<any[]> => {
            throw new Error('connection refused');
        };
        const r = await evaluateGates({ ...baselineInput, query: throwingQuery }, manifest);
        const errorGates = r.filter((g) => g.actual.startsWith('ERROR'));
        assert.ok(errorGates.length > 0, 'expected at least one ERROR gate');
        assert.ok(errorGates.every((g) => !g.passed), 'all ERROR gates must be failed');
        console.log(`  PASS verify: query failures do NOT silently pass (${errorGates.length} gates caught error)`);
    } finally { cleanup(dir); }
}

async function t16() {
    // formatResults produces a readable summary.
    const { manifest, dir } = cleanManifest();
    try {
        const r = await evaluateGates(baselineInput, manifest);
        const text = formatResults(r);
        assert.ok(text.includes('Phase 5 §9a Release Gates'));
        assert.ok(text.includes('PASS'));
        assert.ok(/Result: \d+ PASS, \d+ FAIL/.test(text));
        console.log('  PASS verify: formatResults produces readable output');
    } finally { cleanup(dir); }
}

async function t17() {
    // buildCanonicalManifest reads CSV files correctly.
    const { manifest, dir } = makeManifestEnv({
        'Rooftop__c': ['SEED-01-001', 'SEED-01-002'],
        'Account': ['SEED-06-001', 'SEED-06-002', 'SEED-06-003'],
    });
    try {
        assert.equal(manifest.tagsByObject['Rooftop__c']?.length, 2);
        assert.equal(manifest.tagsByObject['Account']?.length, 3);
        assert.equal(manifest.total, 5);
        assert.ok(manifest.tagsByObject['Rooftop__c']?.includes('SEED-01-001'));
        console.log('  PASS verify: buildCanonicalManifest reads data/csv/ correctly');
    } finally { cleanup(dir); }
}

await t1(); await t2(); await t3(); await t4(); await t5(); await t6();
await t8a(); await t8b(); await t8c(); await t8d();
await t10a(); await t10b(); await t10c(); await t10d(); await t10e();
await t9(); await t11(); await t12(); await t13(); await t14();
await t15(); await t16(); await t17();
console.log('[verify.test] PASS — all 14 §9a gates + strong Gate 8/10 regression tests verified');
