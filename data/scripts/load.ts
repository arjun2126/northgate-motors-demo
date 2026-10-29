/**
 * Northgate Motors — Phase 5 synthetic-data loader (P5-02).
 *
 * Reads data/csv/*.csv in the dependency order from DEMO_ORG_SYNTHETIC_DATA_PLAN.md §4
 * and shells out to `sf data upsert bulk` per object with `--external-id Seed_Tag__c`.
 *
 * Modes (mutually exclusive):
 *   --dry-run     Print the exact shell commands that would be run, the per-object
 *                 row counts, and the projected storage budget check. NO Salesforce
 *                 changes. This is the default in this session (no owner authorization
 *                 for a real load).
 *   --execute     Run the full `sf data upsert bulk` sequence. Requires explicit
 *                 owner authorization and a bypass grant/revoke cycle.
 *   --object <name>  Restrict the run to a single object (e.g. Financing__c).
 *   --validate    Run dry-run + a CSV sanity check (header rows, unique Seed_Tag__c
 *                 values, mandatory column presence) without invoking sf.
 *   --resolve     Print the SOQL queries that would resolve Seed_Tag__c → Salesforce
 *                 Id mappings at load time (read-only). Used to preview the external-ID
 *                 relationship resolution plan before --execute.
 *
 * The loader is idempotent by design (per §1.3 of the data plan): a re-run after a
 * partial failure repairs, never duplicates. The dependency order is encoded below.
 *
 * External-ID relationship strategy (per plan §4):
 *   - Custom lookups: CSV column `Parent__r.Seed_Tag__c` with the parent's Seed_Tag__c
 *     value. Salesforce Bulk API resolves the external ID to the actual Id at upsert time.
 *   - Standard lookups (AccountId, ContactId, OpportunityId, etc.): the CSV column keeps
 *     the field name; the value is the parent's Seed_Tag__c. Salesforce auto-resolves.
 *   - Polymorphic lookups (WhoId, WhatId on Task/Event): resolved to actual Salesforce
 *     Ids at load time via SOQL queries against Contact/Opportunity/Case.
 *   - Pricebook2 on Quote/PBE: resolved at load time by querying the standard pricebook
 *     (never hardcoded).
 *   - OwnerId (User lookup): resolved at load time from a username → Id map queried once.
 *
 * OpportunityLineItem does not have Seed_Tag__c on the standard object. The loader
 * creates OLI via `sf data create bulk` (insert-only). OLI records are deleted and
 * re-inserted by the reset script (§8), preserving idempotency at the reset level.
 *
 * The loader never edits a validation rule. Bypass of triggers/flows/VRs is handled
 * separately by the owner via `PS_Bypass_Load` and `Automation_Settings__c` per §4.
 */

import { execSync, spawnSync } from 'node:child_process';
import { readFileSync, existsSync, statSync, readdirSync, writeFileSync, mkdirSync } from 'node:fs';
import { resolve, join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { Mappings, resolveCsv, dedupOli, buildExistingOliPairs, parseCsvLine, validateQliRows, filterPlanByObject, evaluateBulkResult, RESOLVABLE_OBJECTS as RES_OBJECTS } from './resolve.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const REPO_ROOT = resolve(__dirname, '../..');
const DATA_DIR = resolve(REPO_ROOT, 'data');
const CSV_DIR = resolve(DATA_DIR, 'csv');
const SEED_VERSION_PATH = resolve(DATA_DIR, 'SEED_VERSION.txt');
const RESOLVED_DIR = resolve(DATA_DIR, 'csv-resolved');

const ARGS = process.argv.slice(2);

const FLAGS = {
    dryRun: ARGS.includes('--dry-run') || (!ARGS.includes('--execute') && !ARGS.includes('--resolve-only')),
    execute: ARGS.includes('--execute'),
    validate: ARGS.includes('--validate'),
    resolve: ARGS.includes('--resolve'),
    resolveOnly: ARGS.includes('--resolve-only'),
    continueOnError: ARGS.includes('--continue-on-error'),
    onlyObject: ARGS.includes('--object') ? ARGS[ARGS.indexOf('--object') + 1] : null,
    targetOrg: process.env.SF_TARGET_ORG ?? 'ng-dev',
};

if (FLAGS.dryRun && FLAGS.execute) {
    throw new Error('--dry-run and --execute are mutually exclusive');
}

// §4 dependency order (load order = dependency order).
const LOAD_ORDER = [
    '01-rooftops',
    '02-models',
    '03-products',
    '04-pricebookentries',
    '05-staff',
    '06-vehicles',
    '07-accounts',
    '08-contacts',
    '09-leads',
    '10-opportunities',
    '11-opptylineitems',
    '12-quotes',
    '13-quotelineitems',
    '14-tradeins',
    '15-financing',
    '16-deliveries',
    '17-testdrives',
    '18-cases',
    '19-servicevisits',
    '20-campaigns',
    '21-campaignmembers',
    '22-loyaltymembers',
    '23-loyaltytxns',
    '24-consents',
    '25-tasks',
    '26-events',
    '27-dataloadbatches',
    '77-burst',
    '98-legacy',
    '99-bad-data',
];

// §2.1 envelope: hard limits from the data plan.
const ENVELOPE_LIMITS_KB: Record<number, number> = {
    4026: 4026, // total max KB (non-burst)
};

// [derived from §2.1] Plan-mandated record counts per object.
const TARGET_VOLUMES: Record<string, number> = {
    'Rooftop__c': 4,
    'Vehicle_Model__c': 30,
    'Product2': 60,
    'PricebookEntry': 60,
    'Staff__c': 14,
    'Vehicle__c': 120,
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
    'Case': 60,
    'Service_Visit__c': 140,
    'Campaign': 5,
    'CampaignMember': 60,
    'Loyalty_Member__c': 70,
    'Loyalty_Transaction__c': 110,
    'Consent__c': 90,
    'Task': 200,
    'Event': 50,
    'Data_Load_Batch__c': 20,
};

const KB_PER_RECORD: Record<string, number> = {
    'Campaign': 8,
    'Task': 1,
    'Event': 1,
};
const KB_PER_RECORD_DEFAULT = 2;

const STORAGE_BUDGET_MB = 4.0;
const STORAGE_HEADROOM_MB = 1.0;

// `sf data upsert bulk` mapping. OpportunityLineItem uses create-bulk (no Seed_Tag__c).
interface ObjectLoadSpec {
    csv: string;
    externalIdCol: string;
    mode: 'upsert' | 'create';
}
const OBJECT_TO_CSV: Record<string, ObjectLoadSpec> = {
    'Rooftop__c': { csv: '01-rooftops.csv', externalIdCol: 'Seed_Tag__c', mode: 'upsert' },
    'Vehicle_Model__c': { csv: '02-models.csv', externalIdCol: 'Seed_Tag__c', mode: 'upsert' },
    'Product2': { csv: '03-products.csv', externalIdCol: 'Seed_Tag__c', mode: 'upsert' },
    'PricebookEntry': { csv: '04-pricebookentries.csv', externalIdCol: 'Seed_Tag__c', mode: 'upsert' },
    'Staff__c': { csv: '05-staff.csv', externalIdCol: 'Seed_Tag__c', mode: 'upsert' },
    'Vehicle__c': { csv: '06-vehicles.csv', externalIdCol: 'Seed_Tag__c', mode: 'upsert' },
    'Account': { csv: '07-accounts.csv', externalIdCol: 'Seed_Tag__c', mode: 'upsert' },
    'Contact': { csv: '08-contacts.csv', externalIdCol: 'Seed_Tag__c', mode: 'upsert' },
    'Lead': { csv: '09-leads.csv', externalIdCol: 'Seed_Tag__c', mode: 'upsert' },
    'Opportunity': { csv: '10-opportunities.csv', externalIdCol: 'Seed_Tag__c', mode: 'upsert' },
    'OpportunityLineItem': { csv: '11-opptylineitems.csv', externalIdCol: '', mode: 'create' },
    'Quote': { csv: '12-quotes.csv', externalIdCol: 'Seed_Tag__c', mode: 'upsert' },
    'QuoteLineItem': { csv: '13-quotelineitems.csv', externalIdCol: 'Seed_Tag__c', mode: 'upsert' },
    'Trade_In__c': { csv: '14-tradeins.csv', externalIdCol: 'Seed_Tag__c', mode: 'upsert' },
    'Financing__c': { csv: '15-financing.csv', externalIdCol: 'Seed_Tag__c', mode: 'upsert' },
    'Delivery__c': { csv: '16-deliveries.csv', externalIdCol: 'Seed_Tag__c', mode: 'upsert' },
    'Test_Drive__c': { csv: '17-testdrives.csv', externalIdCol: 'Seed_Tag__c', mode: 'upsert' },
    'Case': { csv: '18-cases.csv', externalIdCol: 'Seed_Tag__c', mode: 'upsert' },
    'Service_Visit__c': { csv: '19-servicevisits.csv', externalIdCol: 'Seed_Tag__c', mode: 'upsert' },
    'Campaign': { csv: '20-campaigns.csv', externalIdCol: 'Seed_Tag__c', mode: 'upsert' },
    'CampaignMember': { csv: '21-campaignmembers.csv', externalIdCol: 'Seed_Tag__c', mode: 'upsert' },
    'Loyalty_Member__c': { csv: '22-loyaltymembers.csv', externalIdCol: 'Seed_Tag__c', mode: 'upsert' },
    'Loyalty_Transaction__c': { csv: '23-loyaltytxns.csv', externalIdCol: 'Seed_Tag__c', mode: 'upsert' },
    'Consent__c': { csv: '24-consents.csv', externalIdCol: 'Seed_Tag__c', mode: 'upsert' },
    'Task': { csv: '25-tasks.csv', externalIdCol: 'Seed_Tag__c', mode: 'upsert' },
    'Event': { csv: '26-events.csv', externalIdCol: 'Seed_Tag__c', mode: 'upsert' },
    'Data_Load_Batch__c': { csv: '27-dataloadbatches.csv', externalIdCol: 'Seed_Tag__c', mode: 'upsert' },
    'BurstLeads': { csv: '77-burst.csv', externalIdCol: 'Seed_Tag__c', mode: 'upsert' },
    'Legacy': { csv: '98-legacy.csv', externalIdCol: 'Seed_Tag__c', mode: 'upsert' },
    'BadData': { csv: '99-bad-data.csv', externalIdCol: 'Seed_Tag__c', mode: 'upsert' },
};

// Objects that need Seed_Tag__c → Id resolution before loading their dependents.
const RESOLVABLE_OBJECTS = [
    'Rooftop__c', 'Vehicle_Model__c', 'Product2', 'Staff__c', 'Vehicle__c',
    'Account', 'Contact', 'Opportunity', 'Quote', 'Case', 'Campaign',
    'Loyalty_Member__c',
] as const;

// ---------- Salesforce CLI wrapper ----------

interface SfResult {
    status: number;
    stdout: string;
    stderr: string;
}

function runSf(args: string[]): SfResult {
    try {
        const r = spawnSync('sf', args, {
            stdio: ['pipe', 'pipe', 'pipe'],
            encoding: 'utf8',
            maxBuffer: 64 * 1024 * 1024,
        });
        if (r.error) {
            return { status: 1, stdout: '', stderr: r.error.message };
        }
        return {
            status: r.status ?? 0,
            stdout: r.stdout ?? '',
            stderr: r.stderr ?? '',
        };
    } catch (e: any) {
        return {
            status: 1,
            stdout: '',
            stderr: e.message ?? '',
        };
    }
}

function runSfQuery(soql: string): { records: any[]; result: SfResult } {
    const r = runSf(['data', 'query', '--query', soql, '--result-format', 'json', '--target-org', FLAGS.targetOrg]);
    if (r.status !== 0) {
        return { records: [], result: r };
    }
    try {
        const parsed = JSON.parse(r.stdout);
        return { records: parsed.result?.records ?? [], result: r };
    } catch {
        return { records: [], result: r };
    }
}

function runSfUpsertBulk(csvPath: string, objectName: string, externalIdCol: string): SfResult {
    return runSf(['data', 'upsert', 'bulk', '--sobject', objectName, '--file', csvPath, '--external-id', externalIdCol, '--target-org', FLAGS.targetOrg, '--wait', '10']);
}

// Split a CSV into N-row chunks and upsert each chunk separately. Used for objects
// whose triggers exceed the 201 SOQL-query-per-batch limit (e.g. LeadRoutingTrigger).
function runSfUpsertBulkChunked(csvPath: string, objectName: string, externalIdCol: string, chunkSize: number): SfResult {
    const text = readFileSync(csvPath, 'utf8');
    const lines = text.split(/\r?\n/).filter((l) => l.length > 0);
    if (lines.length <= 1) return { status: 0, stdout: 'no data', stderr: '' };
    const header = lines[0]!;
    const dataLines = lines.slice(1);
    const dir = resolve(RESOLVED_DIR, 'chunks');
    mkdirSync(dir, { recursive: true });
    let lastResult: SfResult = { status: 0, stdout: '', stderr: '' };
    for (let i = 0; i < dataLines.length; i += chunkSize) {
        const chunk = dataLines.slice(i, i + chunkSize);
        const chunkPath = resolve(dir, `${objectName}-chunk-${Math.floor(i / chunkSize) + 1}.csv`);
        writeFileSync(chunkPath, [header, ...chunk].join('\n') + '\n', 'utf8');
        const relChunk = chunkPath.startsWith(REPO_ROOT) ? chunkPath.slice(REPO_ROOT.length + 1) : chunkPath;
        process.stdout.write(`[load]     ${objectName} chunk ${Math.floor(i / chunkSize) + 1} (${chunk.length} rows)... `);
        const r = runSf(['data', 'upsert', 'bulk', '--sobject', objectName, '--file', relChunk, '--external-id', externalIdCol, '--target-org', FLAGS.targetOrg, '--wait', '10']);
        if (r.status !== 0) {
            console.error(`FAILED (exit ${r.status})`);
            console.error(r.stderr || r.stdout);
            return r;
        }
        console.log('OK');
        lastResult = r;
    }
    return lastResult;
}

function runSfCreateBulk(csvPath: string, objectName: string): SfResult {
    return runSf(['data', 'import', 'bulk', '--sobject', objectName, '--file', csvPath, '--target-org', FLAGS.targetOrg, '--wait', '10']);
}

// ---------- Build mappings (real Salesforce queries) ----------

function buildMappingsFromOrg(): { mappings: Mappings; result: SfResult } {
    const seedTagToId = new Map<string, Map<string, string>>();

    // 1. Standard Pricebook2 (one-time)
    const pb = runSfQuery(`SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1`);
    if (pb.result.status !== 0 || pb.records.length === 0) {
        return { mappings: emptyMappings(), result: { ...pb.result, stderr: pb.result.stderr || 'standard Pricebook2 not found' } };
    }
    const standardPricebookId = pb.records[0].Id as string;

    // 2. Each resolvable object's Seed_Tag__c → Id
    for (const obj of RESOLVABLE_OBJECTS) {
        const q = runSfQuery(`SELECT Id, Seed_Tag__c FROM ${obj} WHERE Seed_Tag__c LIKE 'SEED-%'`);
        if (q.result.status !== 0) {
            return { mappings: emptyMappings(), result: q.result };
        }
        const m = new Map<string, string>();
        for (const r of q.records) m.set(r.Seed_Tag__c, r.Id);
        seedTagToId.set(obj, m);
    }

    // 3. User by username (OwnerId resolution).
    // Includes both the actual username (ngpersona.ngdemo@northgate.demo, created as
    // a duplicate-handling variant when ngpersona@northgate.demo was rejected) and the
    // canonical-looking alias (ngpersona@northgate.demo, which CSVs reference as
    // OwnerId literal). The alias map below binds both to the same User Id so all 350
    // OwnerId references in canonical CSVs resolve correctly without modifying seed data.
    const userResult = runSfQuery(`SELECT Id, Username FROM User WHERE Username IN ('ngrep@northgate.demo','ngpersona.ngdemo@northgate.demo','ngadmin@northgate.demo','ngsvc@northgate.demo')`);
    if (userResult.result.status !== 0) {
        return { mappings: emptyMappings(), result: userResult.result };
    }
    const usernameToId = new Map<string, string>();
    for (const r of userResult.records) usernameToId.set(r.Username, r.Id);
    // Alias: ngpersona@northgate.demo (CSV literal) → ngpersona.ngdemo@northgate.demo (actual user)
    if (usernameToId.has('ngpersona.ngdemo@northgate.demo')) {
        const newUserId = usernameToId.get('ngpersona.ngdemo@northgate.demo')!;
        usernameToId.set('ngpersona@northgate.demo', newUserId);
    }

    // 4. Product2 by ProductCode (for OLI/QLI Product2Id resolution)
    const productResult = runSfQuery(`SELECT Id, ProductCode FROM Product2 WHERE ProductCode LIKE 'TRIM-%' OR ProductCode LIKE 'PKG-%' OR ProductCode LIKE 'ACC-%'`);
    if (productResult.result.status !== 0) {
        return { mappings: emptyMappings(), result: productResult.result };
    }
    const productCodeToId = new Map<string, string>();
    for (const r of productResult.records) productCodeToId.set(r.ProductCode, r.Id);

    // 5. PBE → Product2Id and ProductCode → PBE Id, for QLI resolution & preflight.
    // Both queries filter to the standard pricebook so non-canonical PBEs don't
    // shadow the canonical ones in the resolver map.
    const pbeProduct = runSfQuery(`SELECT Id, Product2Id FROM PricebookEntry WHERE IsActive = true AND Pricebook2.IsStandard = true`);
    if (pbeProduct.result.status !== 0) {
        return { mappings: emptyMappings(), result: pbeProduct.result };
    }
    const pbeIdToProduct2Id = new Map<string, string>();
    const productCodeToPbeId = new Map<string, string>();
    for (const r of pbeProduct.records) {
        pbeIdToProduct2Id.set(r.Id, r.Product2Id ?? '');
        if ((r as any).ProductCode) productCodeToPbeId.set((r as any).ProductCode, r.Id);
    }
    // Some PricebookEntry queries don't surface ProductCode on the record (older
    // API versions). Fall back to a separate query so productCodeToPbeId is
    // always populated. The previous bug in this function was to return a
    // mappings object missing productCodeToPbeId entirely; the resolver then
    // wrote blank PricebookEntryId for every QLI row.
    if (productCodeToPbeId.size === 0) {
        const fallback = runSfQuery(`SELECT Id, ProductCode FROM PricebookEntry WHERE IsActive = true AND Pricebook2.IsStandard = true`);
        if (fallback.result.status === 0) {
            for (const r of fallback.records) {
                if (r.ProductCode) productCodeToPbeId.set(r.ProductCode, r.Id);
            }
        }
    }

    // 6. Set of live Quote Ids (used by the QLI preflight to catch stale lookups).
    const quoteIdSet = new Set<string>();
    const quoteMap = seedTagToId.get('Quote');
    if (quoteMap) for (const id of quoteMap.values()) quoteIdSet.add(id);

    return {
        mappings: { seedTagToId, usernameToId, standardPricebookId, productCodeToId, productCodeToPbeId, pbeIdToProduct2Id, quoteIdSet },
        result: { status: 0, stdout: '', stderr: '' },
    };
}

function emptyMappings(): Mappings {
    return {
        seedTagToId: new Map(),
        usernameToId: new Map(),
        standardPricebookId: '',
        productCodeToId: new Map(),
        productCodeToPbeId: new Map(),
        pbeIdToProduct2Id: new Map(),
        quoteIdSet: new Set(),
    };
}

// ---------- OLI dedup query ----------

function queryExistingOliPairs(oppIds: readonly string[]): { pairs: Set<string>; result: SfResult } {
    if (oppIds.length === 0) return { pairs: new Set(), result: { status: 0, stdout: '', stderr: '' } };
    // SOQL IN clause limit is ~200; chunk if needed
    const chunks: string[][] = [];
    for (let i = 0; i < oppIds.length; i += 200) chunks.push(oppIds.slice(i, i + 200));
    const allRecords: Array<{ OpportunityId: string; Product2Id: string }> = [];
    for (const chunk of chunks) {
        const inList = chunk.map((id) => `'${id.replace(/'/g, "\\'")}'`).join(',');
        const q = runSfQuery(`SELECT Id, OpportunityId, Product2Id FROM OpportunityLineItem WHERE OpportunityId IN (${inList})`);
        if (q.result.status !== 0) return { pairs: new Set(), result: q.result };
        for (const r of q.records) allRecords.push({ OpportunityId: r.OpportunityId, Product2Id: r.Product2Id });
    }
    return { pairs: buildExistingOliPairs(allRecords), result: { status: 0, stdout: '', stderr: '' } };
}

// ---------- Execute pipeline (incremental resolve) ----------

function queryObjectMappings(objectName: string): Map<string, string> {
    const m = new Map<string, string>();
    const q = runSfQuery(`SELECT Id, Seed_Tag__c FROM ${objectName} WHERE Seed_Tag__c LIKE 'SEED-%'`);
    if (q.result.status === 0) {
        for (const r of q.records) m.set(r.Seed_Tag__c, r.Id);
    }
    return m;
}

function queryProductCodeMappings(): Map<string, string> {
    const m = new Map<string, string>();
    const q = runSfQuery(`SELECT Id, ProductCode FROM Product2 WHERE ProductCode LIKE 'TRIM-%' OR ProductCode LIKE 'PKG-%' OR ProductCode LIKE 'ACC-%'`);
    if (q.result.status === 0) {
        for (const r of q.records) m.set(r.ProductCode, r.Id);
    }
    return m;
}

function queryProductCodeToPbeMappings(): Map<string, string> {
    const m = new Map<string, string>();
    const q = runSfQuery(`SELECT Id, ProductCode, Pricebook2Id FROM PricebookEntry WHERE IsActive = true AND Pricebook2.IsStandard = true`);
    if (q.result.status === 0) {
        for (const r of q.records) m.set(r.ProductCode, r.Id);
    }
    return m;
}

function queryPbeIdToProduct2Mappings(): Map<string, string> {
    const m = new Map<string, string>();
    const q = runSfQuery(`SELECT Id, Product2Id FROM PricebookEntry WHERE IsActive = true AND Pricebook2.IsStandard = true`);
    if (q.result.status === 0) {
        for (const r of q.records) m.set(r.Id, r.Product2Id ?? '');
    }
    return m;
}

function runExecute(planIn: PlanStep[]): void {
    let plan = planIn;
    // Safety guard: require explicit authorization env var.
    if (process.env.NG_LOAD_AUTHORIZED !== '1') {
        console.error('[load] --execute refused: set NG_LOAD_AUTHORIZED=1 to enable real Salesforce writes.');
        process.exit(2);
    }

    console.log(`[load] EXECUTE mode → org=${FLAGS.targetOrg}`);
    console.log('[load] Step 1: Initial mapping build (standard Pricebook2, User, existing SEED records)...');

    // Initialize mappings with org-wide singletons
    const mappings: Mappings = emptyMappings();

    const pb = runSfQuery(`SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1`);
    if (pb.result.status !== 0 || pb.records.length === 0) {
        console.error('[load] FAILED: standard Pricebook2 not found');
        process.exit(1);
    }
    mappings.standardPricebookId = pb.records[0].Id as string;
    console.log(`[load]   standard Pricebook2 = ${mappings.standardPricebookId}`);

    // Run the same user query during --execute so the usernameToId map is populated.
    // Mirrors the buildMappingsFromOrg behavior above, including the ngpersona alias.
    const userResult = runSfQuery(`SELECT Id, Username FROM User WHERE Username IN ('ngrep@northgate.demo','ngpersona.ngdemo@northgate.demo','ngadmin@northgate.demo','ngsvc@northgate.demo')`);
    if (userResult.result.status === 0) {
        for (const r of userResult.records) mappings.usernameToId.set(r.Username, r.Id);
        if (mappings.usernameToId.has('ngpersona.ngdemo@northgate.demo')) {
            const newUserId = mappings.usernameToId.get('ngpersona.ngdemo@northgate.demo')!;
            mappings.usernameToId.set('ngpersona@northgate.demo', newUserId);
        }
    }
    console.log(`[load]   ${mappings.usernameToId.size} users resolved`);

    // Query existing SEED records (for rerun scenario; mostly empty for initial load)
    for (const obj of RESOLVABLE_OBJECTS) {
        const m = queryObjectMappings(obj);
        if (m.size > 0) {
            mappings.seedTagToId.set(obj, m);
            console.log(`[load]   ${obj}: ${m.size} existing records`);
        }
    }
    mappings.productCodeToId = queryProductCodeMappings();
    // Initialize the PricebookEntry lookup map and the live PBE→Product2Id map
    // BEFORE any step runs, so a selected-object execute (e.g. --object
    // QuoteLineItem) can resolve PricebookEntryId and the preflight can verify
    // Product2Id without depending on the PricebookEntry step having run first.
    mappings.productCodeToPbeId = queryProductCodeToPbeMappings();
    mappings.pbeIdToProduct2Id = queryPbeIdToProduct2Mappings();
    // Build the set of live Quote Ids for the QLI preflight. Quotes are queried
    // above as part of RESOLVABLE_OBJECTS; this collects the resulting Ids.
    const quoteMap = mappings.seedTagToId.get('Quote');
    if (quoteMap) for (const id of quoteMap.values()) mappings.quoteIdSet.add(id);
    console.log(`[load]   productCodeToPbeId: ${mappings.productCodeToPbeId.size} entries; pbeIdToProduct2Id: ${mappings.pbeIdToProduct2Id.size} entries; live Quotes: ${mappings.quoteIdSet.size}`);

    mkdirSync(RESOLVED_DIR, { recursive: true });

    // Filter plan by --object if provided. This is what enables a selected-object
    // resume (e.g. --object QuoteLineItem) to skip the 1,013 records already
    // loaded. Unknown object names are reported and the run aborts before any
    // Salesforce write. Default (no --object): full plan, preserves existing
    // behavior.
    if (FLAGS.onlyObject) {
        const filtered = filterPlanByObject(plan, FLAGS.onlyObject);
        if (filtered.length === 0) {
            console.error(`[load] --object ${FLAGS.onlyObject}: not in plan. Available: ${plan.map((p) => p.object).join(', ')}`);
            process.exit(1);
        }
        console.log(`[load]   --object filter: ${FLAGS.onlyObject} → ${filtered.length} step(s) of ${plan.length}`);
        plan = filtered;
    }

    // Step 2: Load objects in dependency order, resolving each CSV just before its load.
    // After each successful load, re-query that object's Seed_Tag__c→Id and add to mappings
    // so subsequent CSVs can resolve their parent references. This supports both initial
    // load (parents don't exist yet) and rerun (parents already exist).
    console.log('[load] Step 2: Incremental resolve + load...');
    for (const step of plan) {
        if (step.rows === 0) continue;
        const csvPath = resolve(CSV_DIR, step.csv);
        const resolvedPath = resolve(RESOLVED_DIR, step.csv);

        // Resolve this object's CSV with current mappings
        const r = resolveCsv(csvPath, resolvedPath, mappings, step.object);
        let loadPath = resolvedPath;

        // OLI: dedup against existing records before loading
        if (step.object === 'OpportunityLineItem') {
            const dedupedPath = resolve(RESOLVED_DIR, '11-opptylineitems-deduped.csv');
            const oliText = readFileSync(resolvedPath, 'utf8');
            const oliLines = oliText.split(/\r?\n/).filter((l) => l.length > 0);
            const oliHeader = oliLines[0]!.split(',');
            const oppIdx = oliHeader.indexOf('OpportunityId');
            const oppIds = new Set<string>();
            for (let i = 1; i < oliLines.length; i++) {
                const id = oliLines[i]!.split(',')[oppIdx];
                if (id) oppIds.add(id);
            }
            const { pairs, result: qResult } = queryExistingOliPairs(Array.from(oppIds));
            if (qResult.status !== 0) { console.error(qResult.stderr || qResult.stdout); process.exit(1); }
            const d = dedupOli(resolvedPath, dedupedPath, pairs);
            if (d.rowsOut === 0) {
                console.log(`[load]   OLI: ${d.rowsIn} total, ${d.skipped} duplicates, 0 to insert — all already exist (idempotent)`);
                loadPath = dedupedPath;
            } else {
                console.log(`[load]   OLI: ${d.rowsIn} total, ${d.skipped} duplicates, ${d.rowsOut} to insert`);
                loadPath = dedupedPath;
            }
        } else {
            console.log(`[load]   ${step.object}: ${r.rowsIn} rows resolved (${r.columnsRenamed} custom-lookups renamed, ${r.polymorphicResolved} polymorphic resolved)`);
        }

        // Execute the load
        const relCsv = loadPath.startsWith(REPO_ROOT) ? loadPath.slice(REPO_ROOT.length + 1) : loadPath;
        process.stdout.write(`[load]     upserting ${step.object}... `);
        if (step.object === 'Lead') {
            // LeadRoutingHandler references Q_Inbound_Leads/Q_Service_Intake queues
            // that are now configured (verified). Proceed with chunked load.
            console.log('(chunked)');
        }
        if (step.object === 'OpportunityLineItem') {
            const dedupedContent = readFileSync(loadPath, 'utf8');
            const dedupedLines = dedupedContent.split(/\r?\n/).filter((l) => l.length > 0);
            if (dedupedLines.length <= 1) {
                console.log('SKIPPED (all OLI already exist, dedup CSV is header-only)');
                continue;
            }
        }
        if (step.object === 'Campaign' || step.object === 'CampaignMember') {
            // No hardcoded skip. The loader attempts the upsert; if Campaign
            // create access is not granted to the running user, the Bulk API
            // job will fail and the strict accounting will report it. This
            // surfaces the real blocker instead of hiding it.
        }
        if (step.object === 'BurstLeads' || step.object === 'Legacy' || step.object === 'BadData') {
            console.log('SKIPPED (special batch — loaded separately per data plan §2.7/§7)');
            (runExecute as any).__skipped = ((runExecute as any).__skipped ?? []).concat([`${step.object}: special batch, not part of P5-03 main load`]);
            continue;
        }
        let loadResult: SfResult;
        if (step.object === 'Lead') {
            // LeadRoutingTrigger exceeds 201 SOQL queries per batch — split into chunks
            console.log('(chunked)');
            loadResult = runSfUpsertBulkChunked(loadPath, step.object, step.externalIdCol, 50);
        } else {
            // Fail-fast validation for QuoteLineItem: every row must have non-empty
            // PricebookEntryId (with a real Product2Id), QuoteId (with a real Quote),
            // positive Quantity, and positive UnitPrice. If any row is empty, the bulk
            // job would fail with REQUIRED_FIELD_MISSING — stop BEFORE submitting so
            // the operator can fix the mapping bug instead of partial-success noise.
            if (step.object === 'QuoteLineItem') {
                const result = validateQliRows(loadPath, {
                    pbeIdToProduct2Id: mappings.pbeIdToProduct2Id,
                    quoteIdSet: mappings.quoteIdSet,
                });
                if (result.rows === 0) {
                    console.log('[load]   QLI pre-flight: no rows');
                } else if (result.ok) {
                    console.log(`[load]   QLI pre-flight: ${result.rows} rows pass (PBE+Product2, Quote, Quantity>0, UnitPrice>0)`);
                } else {
                    console.error(`[load] QLI fail-fast (${result.rows} rows): ${result.emptyPBE} empty PBE, ${result.pbeNotInMap} PBE not in org, ${result.pbeNoProduct2} PBE missing Product2, ${result.emptyQuote} empty Quote, ${result.quoteNotInOrg} Quote not in org, ${result.emptyQty} empty Qty, ${result.zeroQty} zero Qty, ${result.emptyUnitPrice} empty UnitPrice, ${result.nonNumericUnitPrice} non-numeric UnitPrice, ${result.nonPositiveUnitPrice} non-positive UnitPrice`);
                    process.exit(7);
                }
            }
            loadResult = step.mode === 'create'
                ? runSfCreateBulk(relCsv, step.object)
                : runSfUpsertBulk(relCsv, step.object, step.externalIdCol);
        }
        // Consolidated bulk-result handler:
        //   - Primary source of truth: `sf data bulk results --job-id <id>`
        //     returns the job summary synchronously (Status, Processed records,
        //     Successful records, Failed records). This avoids the 30-60s
        //     async delay in writing the local per-record CSV files.
        //   - Secondary: the per-record CSV files sf CLI writes locally
        //     (`<jobId>-success-records.csv`, `<jobId>-failed-records.csv`).
        //     We read them if present to verify succeeded === submitted.
        //   - Positive evidence required: jobId resolved, Status=JobComplete,
        //     Processed=Submitted, Successful=Submitted, Failed=0, AND
        //     succeeded file rows = submitted. Any mismatch is treated as failure.
        const outText = (loadResult.stdout || '') + (loadResult.stderr || '');
        // Salesforce Bulk API 2.0 job Ids are 15- or 18-char alphanumeric
        // (e.g. "750aj00001HpoenAAB"). The CLI may format the output with
        // "Job Id:\n <id>" on multiple lines, so capture the full Id.
        const jobIdMatch = outText.match(/Job\s*ID\s*:\s*([0-9a-zA-Z]{15,18})/i);
        const jobId = jobIdMatch ? jobIdMatch[1]! : '';
        let successFileExists = false;
        let successFileContent = '';
        let failedFileExists = false;
        let failedFileContent = '';
        let bulkResultsSummary = '';
        if (jobId) {
            // Fetch the authoritative job summary synchronously. This is
            // reliable and does not depend on the async file-write timing.
            const br = runSf(['data', 'bulk', 'results', '--job-id', jobId, '--target-org', FLAGS.targetOrg]);
            bulkResultsSummary = (br.stdout || '') + (br.stderr || '');
            const succeededPath = resolve(process.cwd(), `${jobId}-success-records.csv`);
            const failedPath = resolve(process.cwd(), `${jobId}-failed-records.csv`);
            if (existsSync(succeededPath)) {
                successFileExists = true;
                successFileContent = readFileSync(succeededPath, 'utf8');
            }
            if (existsSync(failedPath)) {
                failedFileExists = true;
                failedFileContent = readFileSync(failedPath, 'utf8');
            }
        }
        let loadFileContent = '';
        try { loadFileContent = readFileSync(loadPath, 'utf8'); } catch { /* unreadable → evaluateBulkResult flags it */ }
        const evaluation = evaluateBulkResult({
            loadFileContent,
            successFileExists,
            successFileContent,
            failedFileExists,
            failedFileContent,
            jobId,
            cliStatus: loadResult.status,
            cliStdout: bulkResultsSummary || (loadResult.stdout ?? ''),
            cliStderr: loadResult.stderr ?? '',
        });
        if (!evaluation.ok) {
            console.error(`FAILED (exit ${loadResult.status}; processed=${evaluation.processed ?? '?'}; succeeded=${evaluation.succeeded}/${evaluation.submitted}; failed=${evaluation.failed}; unprocessed=${evaluation.unprocessed}; job=${jobId || 'none'}; reason=${evaluation.reason})`);
            console.error(loadResult.stderr || loadResult.stdout);
            if (!FLAGS.continueOnError) {
                process.exit(1);
            }
            (runExecute as any).__failures = ((runExecute as any).__failures ?? []).concat([step.object]);
        } else {
            console.log(`OK (succeeded=${evaluation.succeeded}/${evaluation.submitted}; failed=${evaluation.failed})`);
        }

        // After successful load, re-query this object's mappings for subsequent dependents.
        if (step.mode === 'upsert') {
            if (RESOLVABLE_OBJECTS.includes(step.object as typeof RESOLVABLE_OBJECTS[number])) {
                const updated = queryObjectMappings(step.object);
                mappings.seedTagToId.set(step.object, updated);
            }
            // Refresh Product2→Id and Product2→PBE mappings so subsequent CSVs (especially
            // QuoteLineItem, which needs Product2→PricebookEntryId) see freshly-inserted rows.
            // Critical fix: also refresh after PricebookEntry creation — the QLI lookup must
            // include the PBEs that the canonical step just inserted (TRIM-011..TRIM-029 etc.),
            // not just the PBEs that existed at resolve-only time.
            if (step.object === 'Product2') {
                mappings.productCodeToId = queryProductCodeMappings();
            } else if (step.object === 'PricebookEntry') {
                // Refresh PBE maps so newly-inserted rows are visible to the QLI
                // preflight and resolver. The previous code wrongly assigned the
                // Product2Id map to productCodeToPbeId, which left the QLI
                // resolver with no real PBE entries and produced blank
                // PricebookEntryId on every row.
                mappings.productCodeToPbeId = queryProductCodeToPbeMappings();
                mappings.pbeIdToProduct2Id = queryPbeIdToProduct2Mappings();
            }
        }
    }
    console.log('[load] All loads complete.');
}

function loadSeedVersion(): { seed: string; anchor: string; budget: number } {
    if (!existsSync(SEED_VERSION_PATH)) throw new Error(`Missing ${SEED_VERSION_PATH}`);
    const map: Record<string, string> = {};
    for (const line of readFileSync(SEED_VERSION_PATH, 'utf8').split(/\r?\n/)) {
        const m = line.match(/^([A-Z_][A-Z0-9_]*)=(.*)$/);
        if (m) map[m[1]!] = m[2]!;
    }
    return { seed: map.SEED_VERSION ?? 'SEED-2026.10.01', anchor: map.ANCHOR_DATE ?? '2026-10-01', budget: parseFloat(map.STORAGE_BUDGET_MB ?? '4.0') };
}

function countCsvRows(csvPath: string): number {
    if (!existsSync(csvPath)) return 0;
    return Math.max(0, statSync(csvPath).size > 0 ? readFileSync(csvPath, 'utf8').split(/\r?\n/).filter((l) => l.length > 0).length - 1 : 0);
}

interface PlanStep { object: string; csv: string; rows: number; externalIdCol: string; mode: 'upsert' | 'create'; }

function buildPlan(): PlanStep[] {
    const plan: PlanStep[] = [];
    for (const key of LOAD_ORDER) {
        const objectName = keyToObjectName(key);
        const meta = OBJECT_TO_CSV[objectName];
        if (!meta) continue;
        const csv = resolve(CSV_DIR, meta.csv);
        const rows = countCsvRows(csv);
        plan.push({ object: objectName, csv: meta.csv, rows, externalIdCol: meta.externalIdCol, mode: meta.mode });
    }
    return plan;
}

function keyToObjectName(key: string): string {
    if (key === '77-burst') return 'BurstLeads';
    if (key === '98-legacy') return 'Legacy';
    if (key === '99-bad-data') return 'BadData';
    const m: Record<string, string> = {
        '01-rooftops': 'Rooftop__c',
        '02-models': 'Vehicle_Model__c',
        '03-products': 'Product2',
        '04-pricebookentries': 'PricebookEntry',
        '05-staff': 'Staff__c',
        '06-vehicles': 'Vehicle__c',
        '07-accounts': 'Account',
        '08-contacts': 'Contact',
        '09-leads': 'Lead',
        '10-opportunities': 'Opportunity',
        '11-opptylineitems': 'OpportunityLineItem',
        '12-quotes': 'Quote',
        '13-quotelineitems': 'QuoteLineItem',
        '14-tradeins': 'Trade_In__c',
        '15-financing': 'Financing__c',
        '16-deliveries': 'Delivery__c',
        '17-testdrives': 'Test_Drive__c',
        '18-cases': 'Case',
        '19-servicevisits': 'Service_Visit__c',
        '20-campaigns': 'Campaign',
        '21-campaignmembers': 'CampaignMember',
        '22-loyaltymembers': 'Loyalty_Member__c',
        '23-loyaltytxns': 'Loyalty_Transaction__c',
        '24-consents': 'Consent__c',
        '25-tasks': 'Task',
        '26-events': 'Event',
        '27-dataloadbatches': 'Data_Load_Batch__c',
    };
    return m[key] ?? key;
}

function estimateKb(object: string, rows: number): number {
    const kbr = KB_PER_RECORD[object] ?? KB_PER_RECORD_DEFAULT;
    return rows * kbr;
}

// ---------- Resolve plan (read-only SOQL preview) ----------

function printResolvePlan(plan: PlanStep[]): void {
    console.log('[load] resolve plan: SOQL queries that would be issued to build Seed_Tag__c → Id maps');
    console.log('[load] (read-only — no data changes; standard Pricebook2 queried once, then cached)');
    console.log('');
    console.log('  Step 1: Query standard Pricebook2 (one-time, cached for the session):');
    console.log('    sf data query --query "SELECT Id FROM Pricebook2 WHERE IsStandard = true" --target-org ' + FLAGS.targetOrg);
    console.log('');
    console.log('  Step 2: After each parent object loads, query Seed_Tag__c → Id mapping:');
    for (const obj of RESOLVABLE_OBJECTS) {
        if (obj === 'User') {
            console.log(`    [User]      sf data query --query "SELECT Id, Username FROM User WHERE Username IN ('ngpersona.ngdemo@northgate.demo','ngrep+...','ngadmin@northgate.demo')" --target-org ${FLAGS.targetOrg}`);
        } else {
            console.log(`    [${obj.padEnd(15)}] sf data query --query "SELECT Id, Seed_Tag__c FROM ${obj} WHERE Seed_Tag__c LIKE 'SEED-%'" --target-org ${FLAGS.targetOrg}`);
        }
    }
    console.log('');
    console.log('  Step 3: Resolve CSVs in memory and write to data/csv-resolved/ for --execute:');
    console.log('    - Replace Seed_Tag__c values in parent-reference columns with resolved Ids');
    console.log('    - Replace __STANDARD_PRICEBOOK__ in Pricebook2Id with standard pricebook Id');
    console.log('    - Resolve WhoId/WhatId on Task/Event from polymorphic relationship columns');
    console.log('    - Replace OwnerId usernames with User Ids');
    console.log('');
    console.log('[load] resolve plan complete. Re-run with --execute to perform the real load.');
}

function printPlan(plan: PlanStep[]): void {
    const { seed, anchor, budget } = loadSeedVersion();
    console.log(`[load] seed=${seed} anchor=${anchor} target-org=${FLAGS.targetOrg} mode=${FLAGS.dryRun ? 'DRY-RUN' : FLAGS.execute ? 'EXECUTE' : 'DRY-RUN (default)'}`);
    console.log('[load] dependency order (per §4):');
    for (const s of plan) {
        const target = TARGET_VOLUMES[s.object] ?? null;
        const note = target !== null && s.rows !== target ? `  (target ${target})` : '';
        const modeNote = s.mode === 'create' ? '  [create-only]' : '';
        console.log(`  ${s.csv.padEnd(35)} rows=${String(s.rows).padStart(4)}${note}${modeNote}`);
    }
    // Plan §2.1 budget total (4,026 KB = 3.93 MB) covers clean subtotal + SEED-98 legacy
    // + Task/Event activities. SEED-99 business-bad rows are loaded with bypass and are
    // not counted in the storage budget (they sit "inside the envelope object counts"
    // per the plan's §2.1 note). SEED-77 burst is excluded by the burst filter.
    const budgetRows = plan.filter((p) => !p.csv.startsWith('77-') && !p.csv.startsWith('99-'));
    const budgetKb = budgetRows.reduce((a, p) => a + estimateKb(p.object, p.rows), 0);
    const nonBurst = plan.filter((p) => !p.csv.startsWith('77-'));
    const nonBurstKb = nonBurst.reduce((a, p) => a + estimateKb(p.object, p.rows), 0);
    console.log('');
    console.log(`[load] non-burst rows: ${nonBurst.reduce((a, p) => a + p.rows, 0)}; burst rows: ${plan.find((p) => p.csv.startsWith('77-'))?.rows ?? 0}`);
    console.log(`[load] estimated budget KB (per §2.1: clean + SEED-98 + Task/Event): ${budgetKb} KB = ${(budgetKb / 1024).toFixed(2)} MB`);
    console.log(`[load] total non-burst KB (incl. SEED-99 business-bad, excl. burst): ${nonBurstKb} KB = ${(nonBurstKb / 1024).toFixed(2)} MB`);
    console.log(`[load] storage budget (data plan §2.1): ${STORAGE_BUDGET_MB} MB; headroom ${STORAGE_HEADROOM_MB} MB; plan-mandated total = 3.93 MB (4026 KB)`);
    const withinBudget = (budgetKb / 1024) <= STORAGE_BUDGET_MB;
    console.log(`[load] budget check: ${withinBudget ? 'PASS' : 'WARN — projected exceeds budget; review envelope'}`);
    console.log('');
    if (FLAGS.dryRun || !FLAGS.execute) {
        console.log('[load] dry-run: the following sf commands would be executed in order (no Salesforce changes are made by this run):');
        console.log('');
        for (const s of plan) {
            if (FLAGS.onlyObject && s.object !== FLAGS.onlyObject) continue;
            const cmd = s.mode === 'create'
                ? `sf data create bulk --sobject ${s.object} --file data/csv-resolved/${s.csv} --target-org ${FLAGS.targetOrg}`
                : `sf data upsert bulk --sobject ${s.object} --file data/csv-resolved/${s.csv} --external-id ${s.externalIdCol} --target-org ${FLAGS.targetOrg}`;
            console.log(`  ${cmd}    # ${s.object} (rows=${s.rows})`);
        }
        console.log('');
        console.log('[load] dry-run complete. Re-run with --resolve to preview the SOQL plan, or --execute to perform the real load. Add --continue-on-error to skip failed objects and proceed to remaining ones.');
    } else {
        throw new Error('--execute is not enabled in this session. Re-run with --dry-run to preview.');
    }
}

function validate(): void {
    const plan = buildPlan();
    let problems = 0;
    for (const s of plan) {
        const csv = resolve(CSV_DIR, s.csv);
        if (!existsSync(csv)) {
            console.error(`  [validate] missing CSV: ${s.csv}`);
            problems++;
            continue;
        }
        const text = readFileSync(csv, 'utf8');
        const lines = text.split(/\r?\n/).filter((l) => l.length > 0);
        if (lines.length === 0) {
            console.error(`  [validate] empty CSV: ${s.csv}`);
            problems++;
            continue;
        }
        const header = lines[0]!.split(',');
        // OLI uses OLI_Row_Id__c as traceability, not an external ID.
        const expectedIdCol = s.mode === 'create' ? 'OLI_Row_Id__c' : s.externalIdCol;
        if (!header.includes(expectedIdCol)) {
            console.error(`  [validate] ${s.csv}: missing id column ${expectedIdCol}`);
            problems++;
        }
        const tagCol = header.indexOf(expectedIdCol);
        if (tagCol < 0) continue;
        const seen = new Set<string>();
        for (let i = 1; i < lines.length; i++) {
            const cells = lines[i]!.split(',');
            const tag = cells[tagCol];
            if (tag === undefined || tag === '') {
                console.error(`  [validate] ${s.csv}: row ${i + 1} missing ${expectedIdCol}`);
                problems++;
                continue;
            }
            if (seen.has(tag)) {
                console.error(`  [validate] ${s.csv}: duplicate ${expectedIdCol} ${tag} at row ${i + 1}`);
                problems++;
            }
            seen.add(tag);
        }
    }
    if (problems === 0) console.log('[validate] all CSVs pass: id column present, unique and non-empty.');
    else console.error(`[validate] ${problems} problem(s) found.`);
    // Propagate validation result to the wrapper via process exit code.
    process.exit(problems > 0 ? 1 : 0);
}

const { seed, anchor, budget } = loadSeedVersion();
console.log(`[load] seed_version=${seed} anchor=${anchor} budget=${budget}MB target-org=${FLAGS.targetOrg}`);

if (FLAGS.validate) {
    validate();
} else if (FLAGS.execute) {
    runExecute(buildPlan());
} else if (FLAGS.resolveOnly) {
    // Resolve mappings from org, write resolved CSVs, stop before loading.
    if (process.env.NG_LOAD_AUTHORIZED !== '1') {
        console.error('[load] --resolve-only refused: set NG_LOAD_AUTHORIZED=1 to enable Salesforce queries.');
        process.exit(2);
    }
    const plan = buildPlan();
    console.log('[load] --resolve-only: querying Salesforce and writing data/csv-resolved/');
    const { mappings, result: br } = buildMappingsFromOrg();
    if (br.status !== 0) { console.error(br.stderr || br.stdout); process.exit(1); }
    mkdirSync(RESOLVED_DIR, { recursive: true });
    for (const step of plan) {
        if (step.rows === 0) continue;
        const csvPath = resolve(CSV_DIR, step.csv);
        const resolvedPath = resolve(RESOLVED_DIR, step.csv);
        const r = resolveCsv(csvPath, resolvedPath, mappings, step.object);
        console.log(`[load]   ${step.csv}: ${r.rowsIn}→${r.rowsOut} rows`);
    }
    console.log('[load] Resolve complete. Resolved CSVs in data/csv-resolved/');
} else if (FLAGS.resolve) {
    printResolvePlan(buildPlan());
} else {
    printPlan(buildPlan());
}
