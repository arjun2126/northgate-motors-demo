/**
 * Count reconciliation: per data plan §2.1 the generator must emit exactly the
 * documented volumes. Also asserts a small set of business invariants
 * (unique Seed_Tag__c across each CSV; every Quote references an existing
 * Opportunity; every QuoteLineItem references an existing Quote).
 */
import { strict as assert } from 'node:assert';
import { readFileSync, readdirSync } from 'node:fs';
import { resolve, join } from 'node:path';

const REPO_ROOT = process.cwd();
const CSV_DIR = resolve(REPO_ROOT, 'data/csv');

function readCsv(name: string): { header: string[]; rows: string[][] } {
    const text = readFileSync(join(CSV_DIR, name), 'utf8');
    const lines = text.trim().split(/\r?\n/);
    const header = lines[0]!.split(',');
    const rows = lines.slice(1).map((l) => l.split(','));
    return { header, rows };
}

function countRows(name: string): number {
    return readCsv(name).rows.length;
}

// Plan §2.1 envelope targets (non-burst). Generator renumbered to slot in
// PricebookEntry, CampaignMember, QuoteLineItem, and split Task/Event.
const TARGETS: Record<string, number> = {
    '01-rooftops.csv': 4,
    '02-models.csv': 30,
    '03-products.csv': 60,
    '04-pricebookentries.csv': 60,
    '05-staff.csv': 14,
    '06-vehicles.csv': 120,
    '07-accounts.csv': 150,
    '08-contacts.csv': 185,
    '09-leads.csv': 130,
    '10-opportunities.csv': 100,
    '11-opptylineitems.csv': 100,
    '12-quotes.csv': 60,
    '13-quotelineitems.csv': 80,
    '14-tradeins.csv': 45,
    '15-financing.csv': 60,
    '16-deliveries.csv': 12,
    '17-testdrives.csv': 70,
    '18-cases.csv': 60,
    '19-servicevisits.csv': 140,
    '20-campaigns.csv': 5,
    '21-campaignmembers.csv': 60,
    '22-loyaltymembers.csv': 70,
    '23-loyaltytxns.csv': 110,
    '24-consents.csv': 90,
    '25-tasks.csv': 200,
    '26-events.csv': 50,
    '27-dataloadbatches.csv': 20,
    '77-burst.csv': 300,
    '98-legacy.csv': 30,
    '99-bad-data.csv': 16,
};

const failures: string[] = [];
for (const [file, target] of Object.entries(TARGETS)) {
    const got = countRows(file);
    if (got !== target) failures.push(`${file}: got ${got}, want ${target}`);
}

// Per-CSV id uniqueness. OLI has no Seed_Tag__c — just verify row count.
for (const file of Object.keys(TARGETS)) {
    const { header, rows } = readCsv(file);
    if (file === '11-opptylineitems.csv') {
        // OLI: no external ID field; just verify it has rows
        if (rows.length === 0) failures.push(`${file}: expected rows, got 0`);
        continue;
    }
    const idx = header.indexOf('Seed_Tag__c');
    if (idx < 0) {
        failures.push(`${file}: Seed_Tag__c column missing`);
        continue;
    }
    const seen = new Set<string>();
    for (let i = 0; i < rows.length; i++) {
        const tag = rows[i]![idx];
        if (!tag) {
            failures.push(`${file}: row ${i + 1} has empty Seed_Tag__c`);
            continue;
        }
        if (seen.has(tag)) failures.push(`${file}: duplicate Seed_Tag__c ${tag}`);
        seen.add(tag);
    }
}

// Quote → Opportunity referential integrity (parent references now use Seed_Tag__c).
const oppsBySeedTag = new Set<string>();
for (const r of readCsv('10-opportunities.csv').rows) oppsBySeedTag.add(r[0]!);
const quotes = readCsv('12-quotes.csv').rows;
for (let i = 0; i < quotes.length; i++) {
    const oppSeed = quotes[i]![2];
    if (!oppsBySeedTag.has(oppSeed)) failures.push(`12-quotes.csv: row ${i + 1} references unknown Opportunity Seed_Tag__c "${oppSeed}"`);
}

// QuoteLineItem → Quote referential integrity (QuoteId column in the QLI CSV
// holds the parent Quote's Seed_Tag__c, not its Name).
const quoteSeeds = new Set<string>();
for (const r of readCsv('12-quotes.csv').rows) quoteSeeds.add(r[0]!);
const qliCount = readCsv('13-quotelineitems.csv').rows.length;
let qliOrphan = 0;
for (const r of readCsv('13-quotelineitems.csv').rows) {
    if (!quoteSeeds.has(r[1]!)) qliOrphan++;
}
if (qliOrphan > 0) failures.push(`13-quotelineitems.csv: ${qliOrphan} rows reference unknown Quote Seed_Tag`);

// QuoteLineItem must equal exactly the count of QLI rows (no Quote+QLI mix-up).
if (qliCount !== TARGETS['13-quotelineitems.csv']) {
    failures.push(`13-quotelineitems.csv: row count ${qliCount} != target ${TARGETS['13-quotelineitems.csv']}`);
}

// Tasks + Events must sum to 250 (plan §2.1 row 27).
const taskCount = countRows('25-tasks.csv');
const eventCount = countRows('26-events.csv');
if (taskCount + eventCount !== 250) failures.push(`activities: ${taskCount}+${eventCount} != 250`);

if (failures.length > 0) {
    for (const f of failures) console.error(`  ${f}`);
    throw new Error(`[counts.test] FAIL — ${failures.length} issue(s)`);
}
console.log(`[counts.test] PASS — ${Object.keys(TARGETS).length} CSVs match plan §2.1 envelope; uniqueness + referential integrity OK`);
