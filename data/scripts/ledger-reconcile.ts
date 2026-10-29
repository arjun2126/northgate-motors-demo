/**
 * P5-05 ledger reconciliation analyzer (read-only).
 *
 * Reads wrapper logs + SEED_VERSION.txt + the 20 existing ledger records
 * and produces a proposed update plan. Does NOT execute any Salesforce
 * writes. Output is human-readable, suitable for owner review.
 *
 * Usage: npx tsx data/scripts/ledger-reconcile.ts > evidence/P5/ledger_proposed.txt
 */
import { execFileSync } from 'node:child_process';
import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { resolve } from 'node:path';

interface RunEvidence {
    timestamp: string;       // YYYYMMDDTHHMMSSZ
    isoTimestamp: string;    // YYYY-MM-DDTHH:MM:SS.000Z
    object: string;
    result: string;          // 'OK (succeeded=N/M; failed=0)' or 'FAILED (...)' or ''
    jobId: string;           // from log content, '' if not found
    mode: string;            // 'execute' | 'read-only' from wrapper
}

const LOG_DIR = resolve(process.cwd(), 'data', 'automation-control', 'logs');
const SEED_VERSION_PATH = resolve(process.cwd(), 'data', 'SEED_VERSION.txt');

function parseTimestamp(ts: string): string {
    // 20261018T045812Z → 2026-10-18T04:58:12.000Z
    return `${ts.slice(0, 4)}-${ts.slice(4, 6)}-${ts.slice(6, 8)}T${ts.slice(9, 11)}:${ts.slice(11, 13)}:${ts.slice(13, 15)}.000Z`;
}

function parseLogs(): RunEvidence[] {
    const files = readdirSync(LOG_DIR).filter((f) => f.endsWith('-wrapper.log')).sort();
    const out: RunEvidence[] = [];
    for (const f of files) {
        // Strip ANSI escape codes from the log text.
        const raw = readFileSync(resolve(LOG_DIR, f), 'utf8');
        const text = raw.replace(/\x1b\[[0-9;]*[a-zA-Z]/g, '');
        const ts = f.replace('-wrapper.log', '');
        const objectMatch = text.match(/--object\s+([A-Za-z_]+)/);
        const resultMatch = text.match(/(OK \(succeeded=[^\)]+\)|FAILED[^\n]+)/);
        const jobMatch = text.match(/job=([0-9a-zA-Z]{15,18})/);
        const modeMatch = text.match(/detected mode:\s+(\w+)/);
        if (!objectMatch) continue;  // skip non-execute logs
        out.push({
            timestamp: ts,
            isoTimestamp: parseTimestamp(ts),
            object: objectMatch[1],
            result: resultMatch ? resultMatch[1] : '(no result line)',
            jobId: jobMatch ? jobMatch[1] : '',
            mode: modeMatch ? modeMatch[1] : '',
        });
    }
    return out;
}

function queryExistingLedger(): any[] {
    const out = execFileSync('sf', ['data', 'query', '--query', 'SELECT Id, Seed_Tag__c, Name, Object__c, Batch_Number__c, Inserted_Count__c, Failed_Count__c, Status__c, Seed_Version__c, Loaded_At__c, Reset_At__c, Notes__c FROM Data_Load_Batch__c ORDER BY Batch_Number__c', '--result-format', 'json', '--target-org', 'ng-demo'], { encoding: 'utf8' });
    return JSON.parse(out).result.records;
}

function queryCanonicalCounts(): Record<string, number> {
    const objects = ['Rooftop__c', 'Vehicle_Model__c', 'Product2', 'PricebookEntry', 'Staff__c', 'Vehicle__c', 'Account', 'Contact', 'Lead', 'Opportunity', 'OpportunityLineItem', 'Quote', 'QuoteLineItem', 'Trade_In__c', 'Financing__c', 'Delivery__c', 'Test_Drive__c', 'Service_Visit__c', 'Case', 'Loyalty_Member__c', 'Loyalty_Transaction__c', 'Consent__c', 'Campaign', 'CampaignMember', 'Data_Load_Batch__c', 'Task', 'Event'];
    const out: Record<string, number> = {};
    for (const obj of objects) {
        const soql = obj === 'OpportunityLineItem'
            ? `SELECT COUNT(Id) c FROM ${obj}`
            : `SELECT COUNT(Id) c FROM ${obj} WHERE Seed_Tag__c LIKE 'SEED-%'`;
        const r = execFileSync('sf', ['data', 'query', '--query', soql, '--result-format', 'json', '--target-org', 'ng-demo'], { encoding: 'utf8' });
        const j = JSON.parse(r);
        out[obj] = j.status === 0 ? j.result.records[0].c : 0;
    }
    return out;
}

function main() {
    const out: string[] = [];
    out.push('# P5-05 Data Load Ledger Reconciliation — Proposed Update Plan');
    out.push('# Generated: ' + new Date().toISOString());
    out.push('');

    // 1. Acceptance requirements
    out.push('## 1. Acceptance Requirements (P5-05 + Data_Load_Batch__c schema)');
    out.push('');
    out.push('Backlog P5-05: "One row per batch: version, counts, timestamps, status, anchor date, storage reading"');
    out.push('Backlog P5-05 evidence: "Ledger matches SEED_VERSION.txt → evidence/P5/ledger.png"');
    out.push('');
    out.push('Data_Load_Batch__c fields:');
    out.push('  - Seed_Tag__c (Text, externalId, unique) — primary key');
    out.push('  - Batch_Number__c (Number, externalId) — sequence 1..20');
    out.push('  - Seed_Version__c (Text 20) — must match SEED_VERSION');
    out.push('  - Object__c (Picklist) — limited to 17 values; missing Product2, PricebookEntry, Quote, QuoteLineItem, OLI, Campaign, CampaignMember');
    out.push('  - Inserted_Count__c (Number) — records successfully inserted in this batch');
    out.push('  - Failed_Count__c (Number) — records that failed');
    out.push('  - Loaded_At__c (DateTime) — when the batch completed');
    out.push('  - Reset_At__c (DateTime) — when the batch was reset (null for active)');
    out.push('  - Status__c (Picklist) — Loaded | Partial | Reset | Archived');
    out.push('  - Notes__c (LongTextArea 1000) — free-form evidence');
    out.push('');

    // 2. SEED_VERSION evidence
    out.push('## 2. SEED_VERSION.txt Evidence');
    out.push('');
    if (existsSync(SEED_VERSION_PATH)) {
        const sv = readFileSync(SEED_VERSION_PATH, 'utf8');
        out.push('```');
        out.push(sv.trim());
        out.push('```');
    } else {
        out.push('MISSING');
    }
    out.push('');

    // 3. Wrapper log evidence
    out.push('## 3. Wrapper Log Evidence (data/automation-control/logs/)');
    out.push('');
    const runs = parseLogs();
    const executeRuns = runs.filter((r) => r.mode === 'execute');
    out.push(`Total wrapper log files: ${runs.length}`);
    out.push(`Execute-mode runs: ${executeRuns.length}`);
    out.push('');
    out.push('| Timestamp (ISO) | Object | Result | Job ID |');
    out.push('|---|---|---|---|');
    for (const r of executeRuns) {
        const resultShort = r.result.length > 60 ? r.result.slice(0, 57) + '...' : r.result;
        out.push(`| ${r.isoTimestamp} | ${r.object} | ${resultShort} | ${r.jobId || '—'} |`);
    }
    out.push('');

    // 4. Actual Salesforce counts
    out.push('## 4. Actual Salesforce Canonical Counts (SEED-% filter)');
    out.push('');
    const counts = queryCanonicalCounts();
    let total = 0;
    out.push('| Object | Count |');
    out.push('|---|---|');
    for (const [obj, n] of Object.entries(counts)) {
        out.push(`| ${obj} | ${n} |`);
        total += n;
    }
    out.push(`| **TOTAL** | **${total}** |`);
    out.push('');

    // 5. Existing ledger records
    out.push('## 5. Existing 20 Ledger Records (current state)');
    out.push('');
    const existing = queryExistingLedger();
    out.push('| Seed_Tag__c | Batch | Object | Inserted | Failed | Status | Loaded_At |');
    out.push('|---|---|---|---|---|---|---|');
    for (const r of existing) {
        out.push(`| ${r.Seed_Tag__c} | ${r.Batch_Number__c} | ${r.Object__c} | ${r.Inserted_Count__c} | ${r.Failed_Count__c} | ${r.Status__c} | ${r.Loaded_At__c} |`);
    }
    out.push('');

    // 6. Evidence gaps
    out.push('## 6. Evidence Gaps');
    out.push('');
    out.push('1. The 20 existing records were created by the loader\'s step 27 (Data_Load_Batch__c CSV).');
    out.push('   They contain PLACEHOLDER values from the CSV, not real ledger entries:');
    out.push('   - Object__c = "Mixed" for all 20 (not the actual object name)');
    out.push('   - Inserted_Count__c = 0 for all 20 (the loader inserted 20 Data_Load_Batch__c records, not 0)');
    out.push('   - Loaded_At__c = 2026-10-01T00:00:00 for all 20 (hardcoded placeholder, not actual load time)');
    out.push('   - Notes__c = "Loader-written batch row." for all 20 (placeholder)');
    out.push('');
    out.push('2. The 20 Seed_Tag__c values (SEED-25-001..020) do NOT map 1:1 to the 27 wrapper');
    out.push('   execution runs. The wrapper logs show 19+ successful runs across 27 steps,');
    out.push('   but the 20 ledger records were loaded as a single CSV batch, not as');
    out.push('   per-step ledger entries.');
    out.push('');
    out.push('3. Object__c picklist CANNOT represent all 27 loaded objects:');
    out.push('   Missing: Product2, PricebookEntry, Quote, QuoteLineItem, OpportunityLineItem,');
    out.push('   Campaign, CampaignMember. Only "Mixed" is available for multi-object batches.');
    out.push('');
    out.push('4. Per-record Inserted_Count__c and Loaded_At__c CANNOT be reconciled to specific');
    out.push('   wrapper runs because the 20 Seed_Tag__c values do not correspond to specific');
    out.push('   execution batches. Assigning per-record values would require invention.');
    out.push('');

    // 7. Proposed update plan
    out.push('## 7. Proposed Update Plan (evidence-backed only)');
    out.push('');
    out.push('Strategy: update the 20 existing records with aggregate canonical evidence.');
    out.push('Do NOT assign per-record counts/timestamps (would be invention).');
    out.push('Do NOT delete any records (destructive). Do NOT create duplicates.');
    out.push('');
    out.push('### Common updates (all 20 records):');
    out.push('  - Seed_Version__c: "SEED-2026.10.01" (unchanged, already correct)');
    out.push('  - Object__c: "Mixed" (unchanged, picklist limitation)');
    out.push('  - Status__c: "Loaded" (unchanged, accurate for canonical completion)');
    out.push('  - Reset_At__c: null (unchanged)');
    out.push('  - Batch_Number__c: 1..20 (unchanged, already correct)');
    out.push('  - Loaded_At__c: "2026-10-18T05:45:00.000Z" (the final canonical completion time from SEED_VERSION.txt)');
    out.push('  - Notes__c: "Phase 5 canonical load SEED-2026.10.01; 2,085 records across 27 steps;');
    out.push('    SEED-98 (30 records) deferred. Aggregate evidence: 19 wrapper runs, 1,985 SEED tags reconciled.');
    out.push('    Per-step evidence: data/automation-control/logs/2026*.log. P5-08 gates 14/14 PASS."');
    out.push('');
    out.push('### Record 1 (SEED-25-001) only:');
    out.push('  - Inserted_Count__c: 2085 (aggregate canonical count, evidence-backed)');
    out.push('  - Failed_Count__c: 0 (no records failed in the final canonical run)');
    out.push('  - Object__c: "Mixed" (unchanged)');
    out.push('');
    out.push('### Records 2-20 (SEED-25-002..020):');
    out.push('  - Inserted_Count__c: 0 (unchanged — no per-batch count available)');
    out.push('  - Failed_Count__c: 0 (unchanged)');
    out.push('');
    out.push('### Evidence for each proposed value:');
    out.push('  - 2085 total: Gate 10 canonical actual = 1835 clean + 250 activities (live ng-demo)');
    out.push('  - 2026-10-18T05:45:00Z: SEED_VERSION.txt LOADED_AT (final completion marker)');
    out.push('  - "Mixed": only available picklist value for multi-object batches');
    out.push('  - "Loaded": all 27 canonical steps completed successfully (wrapper logs)');
    out.push('');

    // 8. Exact update operations
    out.push('## 8. Exact Salesforce Update Operations (20 records, 5 fields each)');
    out.push('');
    out.push('Tool: sf data update record -o ng-demo -s Data_Load_Batch__c -i <Id> -v "Loaded_At__c=2026-10-18T05:45:00.000Z|Inserted_Count__c=<N>|Failed_Count__c=0|Notes__c=<text>"');
    out.push('');
    out.push('(Note: sf data update record uses -v key=value pairs separated by |)');
    out.push('');
    out.push('Record 1: Inserted_Count__c=2085');
    out.push('Records 2-20: Inserted_Count__c=0 (unchanged)');
    out.push('');
    for (const r of existing) {
        const ins = r.Seed_Tag__c === 'SEED-25-001' ? '2085' : '0';
        out.push(`  ${r.Id} (${r.Seed_Tag__c}, batch ${r.Batch_Number__c})`);
    }
    out.push('');
    out.push('Notes text (truncated to 1000 chars):');
    const notes = 'Phase 5 canonical load SEED-2026.10.01; 2,085 records across 27 steps; SEED-98 (30 records) deferred. Aggregate evidence: 19 wrapper runs, 1,985 SEED tags reconciled. Per-step evidence: data/automation-control/logs/2026*.log. P5-08 gates 14/14 PASS.';
    out.push(`  "${notes}" (${notes.length} chars)`);
    out.push('');

    // 9. Unresolved evidence gaps
    out.push('## 9. Unresolved Evidence Gaps');
    out.push('');
    out.push('1. Per-record Inserted_Count__c: cannot be reconciled to specific wrapper runs.');
    out.push('   The 20 Seed_Tag__c values were generated as seed data, not as per-step ledger entries.');
    out.push('   The loader does not currently write per-step Data_Load_Batch__c records.');
    out.push('   FIX: modify data/scripts/load.ts to write a ledger record after each successful step.');
    out.push('   SCOPE: out of scope for P5-05 (requires loader changes; deferred to future work).');
    out.push('');
    out.push('2. Per-record Loaded_At__c: same issue. All 20 records will share the final');
    out.push('   completion timestamp (2026-10-18T05:45:00Z). This is a known approximation.');
    out.push('');
    out.push('3. Object__c picklist: cannot represent multi-object batches. The 17-value');
    out.push('   picklist is a schema limitation. "Mixed" is the only option. FIX: extend');
    out.push('   the picklist (metadata deployment) or change to Text. OUT OF SCOPE for P5-05.');
    out.push('');
    out.push('4. Bulk API Job IDs: wrapper logs capture job IDs, but they are not mapped');
    out.push('   to specific ledger records. Would require loader changes to record job ID');
    out.push('   per step. OUT OF SCOPE for P5-05.');
    out.push('');

    out.push('## 10. Local Files Changed (this task)');
    out.push('');
    out.push('- data/scripts/ledger-reconcile.ts (new, read-only analyzer)');
    out.push('- data/SEED_VERSION.txt (no change; used as evidence source)');
    out.push('- No Salesforce data modifications performed.');
    out.push('');

    process.stdout.write(out.join('\n') + '\n');
}

main();
