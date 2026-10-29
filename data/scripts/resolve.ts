/**
 * Northgate Motors — Phase 5 resolve module.
 *
 * Pure functions for resolving Seed_Tag__c values to Salesforce Ids in CSVs.
 * No Salesforce CLI calls here — this module operates on in-memory data so it
 * can be unit-tested without a live org.
 *
 * The executable pipeline in load.ts:
 *   1. Queries Salesforce for Seed_Tag__c → Id mappings (one query per object)
 *   2. Queries standard Pricebook2 Id (one query)
 *   3. Queries User by username (one query)
 *   4. Queries Product2 by ProductCode (one query, for OLI/QLI)
 *   5. Calls resolveCsv() for each CSV to replace external-ID values with Ids
 *   6. Calls dedupOli() to filter out already-existing OpportunityLineItems
 *   7. Executes `sf data upsert bulk` / `sf data create bulk` in dependency order
 */
import { readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';

// ---------- Public types ----------

export interface Mappings {
    /** objectName → Seed_Tag__c → Salesforce Id */
    seedTagToId: Map<string, Map<string, string>>;
    /** username (e.g. ngrep+opp001@northgate.demo) → User Id */
    usernameToId: Map<string, string>;
    /** Standard pricebook Id (queried once) */
    standardPricebookId: string;
    /** ProductCode → Product2 Id (for OLI Product2Id resolution) */
    productCodeToId: Map<string, string>;
    /** ProductCode → PricebookEntry Id (for QLI PricebookEntryId resolution) */
    productCodeToPbeId: Map<string, string>;
    /** PricebookEntry Id → Product2 Id (live org PBEs, standard pricebook only).
     *  Populated at startup so the QuoteLineItem preflight can verify every PBE
     *  has a Product2Id before any Salesforce write. */
    pbeIdToProduct2Id: Map<string, string>;
    /** Set of Quote Ids known to exist in the org (SEED-12-*). Used by the QLI
     *  preflight to confirm every resolved QuoteId is real, not a stale or
     *  missing lookup. */
    quoteIdSet: Set<string>;
}

// ---------- Custom lookup field → target object ----------
//
// The CSV relationship form `<Field>__r.Seed_Tag__c` renames to the lookup FIELD
// (`<Field>__c`), but the seed-tag value must be resolved against the target OBJECT.
// Those are only the same string for a few fields; for the rest the field name differs
// from its object (Sales_Staff__c → Staff__c, Preferred_Rooftop__c → Rooftop__c,
// Buyer_Contact__c → Contact). Resolving by field name silently produced blank values
// for exactly those three relationships.

export const CUSTOM_LOOKUP_TARGETS: Record<string, string> = {
    Sales_Staff__c: 'Staff__c',
    Preferred_Rooftop__c: 'Rooftop__c',
    Buyer_Contact__c: 'Contact',
    Advisor_Staff__c: 'Staff__c',
    Technician_Staff__c: 'Staff__c',
    Assigned_To__c: 'Staff__c',
    Vehicle__c: 'Vehicle__c',
    Vehicle_Model__c: 'Vehicle_Model__c',
    Rooftop__c: 'Rooftop__c',
    Opportunity__c: 'Opportunity',
    Contact__c: 'Contact',
    Account__c: 'Account',
    Case__c: 'Case',
};

// ---------- Standard lookup field → target object ----------

export const STANDARD_LOOKUP_FIELDS: Record<string, string> = {
    AccountId: 'Account',
    ContactId: 'Contact',
    OpportunityId: 'Opportunity',
    CampaignId: 'Campaign',
    QuoteId: 'Quote',
    VehicleId: 'Vehicle__c',
    ApplicantId: 'Contact',
    LeadId: 'Lead',
    // Custom-object lookup fields use the custom field name directly (not the __r.Seed_Tag__c syntax)
    Contact__c: 'Contact',
    Vehicle__c: 'Vehicle__c',
    Opportunity__c: 'Opportunity',
    Applicant__c: 'Contact',
    Loyalty_Member__c: 'Loyalty_Member__c',
    Assigned_To__c: 'Staff__c',
    Advisor_Staff__c: 'Staff__c',
    Technician_Staff__c: 'Staff__c',
};

// Objects that need Seed_Tag__c → Id resolution before loading their dependents.
export const RESOLVABLE_OBJECTS = [
    'Rooftop__c', 'Vehicle_Model__c', 'Product2', 'Staff__c', 'Vehicle__c',
    'Account', 'Contact', 'Opportunity', 'Quote', 'Case', 'Campaign',
    'Loyalty_Member__c',
] as const;

export type ColumnType =
    | 'passthrough'
    | 'standard-lookup'
    | 'custom-lookup'
    | 'polymorphic-what'
    | 'polymorphic-who'
    | 'owner'
    | 'pricebook'
    | 'product-code'
    | 'drop';

export interface ColumnMeta {
    oldIdx: number;
    newName: string;
    type: ColumnType;
    target?: string;
}

// ---------- Column classification ----------

// Map polymorphic relationship name → actual SObject name (e.g. "Opportunity__" → "Opportunity")
const POLYMORPHIC_TARGETS: Record<string, string> = {
    'WhatId_Opportunity__': 'Opportunity',
    'WhatId_Case__': 'Case',
    'WhoId_Contact__': 'Contact',
    'WhoId_Lead__': 'Lead',
};

export function classifyColumns(header: readonly string[], contextObjectName?: string): ColumnMeta[] {
    return header.map((col, idx) => {
        if (col.endsWith('__r.Seed_Tag__c')) {
            if (col.startsWith('WhatId_')) {
                const target = POLYMORPHIC_TARGETS[col] ?? col.replace('WhatId_', '').replace('__r.Seed_Tag__c', '').replace(/_+$/, '');
                return { oldIdx: idx, newName: '__WhatId__' + target, type: 'polymorphic-what' as ColumnType, target };
            }
            if (col.startsWith('WhoId_')) {
                const target = POLYMORPHIC_TARGETS[col] ?? col.replace('WhoId_', '').replace('__r.Seed_Tag__c', '').replace(/_+$/, '');
                return { oldIdx: idx, newName: '__WhoId__' + target, type: 'polymorphic-who' as ColumnType, target };
            }
            // Custom lookup: rename Parent__r → Parent__c (the field API name).
            // The seed tag resolves against the target OBJECT, which is not always the
            // field name (Sales_Staff__c lives on Staff__c, Buyer_Contact__c on Contact).
            const relName = col.replace('__r.Seed_Tag__c', '');
            const fieldName = relName + '__c';
            const target = CUSTOM_LOOKUP_TARGETS[fieldName] ?? fieldName;
            return { oldIdx: idx, newName: fieldName, type: 'custom-lookup' as ColumnType, target };
        }
        if (col === 'OwnerId') {
            return { oldIdx: idx, newName: 'OwnerId', type: 'owner' as ColumnType };
        }
        if (col === 'Pricebook2Id') {
            return { oldIdx: idx, newName: 'Pricebook2Id', type: 'pricebook' as ColumnType };
        }
        if (col === 'ProductCode') {
            // ProductCode resolution depends on the target object:
            //   - Product2: self-field (passthrough)
            //   - QuoteLineItem: → PricebookEntryId (PBE lookup)
            //   - everything else: → Product2Id
            if (contextObjectName === 'Product2') {
                return { oldIdx: idx, newName: 'ProductCode', type: 'passthrough' as ColumnType };
            }
            if (contextObjectName === 'QuoteLineItem') {
                return { oldIdx: idx, newName: 'PricebookEntryId', type: 'pbe-code' as ColumnType };
            }
            return { oldIdx: idx, newName: 'Product2Id', type: 'product-code' as ColumnType };
        }
        const standardTarget = STANDARD_LOOKUP_FIELDS[col];
        if (standardTarget) {
            return { oldIdx: idx, newName: col, type: 'standard-lookup' as ColumnType, target: standardTarget };
        }
        // Loader-only traceability columns (used by validator + dedup; not a Salesforce field).
        // Drop them from the resolved CSV so `sf data create bulk` does not try to insert
        // a non-existent field on the target standard object (e.g. OpportunityLineItem).
        if (col === 'OLI_Row_Id__c') {
            return { oldIdx: idx, newName: col, type: 'drop' as ColumnType };
        }
        return { oldIdx: idx, newName: col, type: 'passthrough' as ColumnType };
    });
}

// ---------- CSV reader/writer (handles quoted fields with commas) ----------

function parseCsvLine(line: string): string[] {
    const out: string[] = [];
    let cur = '';
    let inQuotes = false;
    for (let i = 0; i < line.length; i++) {
        const ch = line[i]!;
        if (inQuotes) {
            if (ch === '"' && line[i + 1] === '"') {
                cur += '"';
                i++;
            } else if (ch === '"') {
                inQuotes = false;
            } else {
                cur += ch;
            }
        } else {
            if (ch === ',') {
                out.push(cur);
                cur = '';
            } else if (ch === '"') {
                inQuotes = true;
            } else {
                cur += ch;
            }
        }
    }
    out.push(cur);
    return out;
}

export { parseCsvLine };

function readCsv(csvPath: string): { header: string[]; rows: string[][] } {
    const text = readFileSync(csvPath, 'utf8');
    const lines = text.split(/\r?\n/).filter((l) => l.length > 0);
    return { header: parseCsvLine(lines[0]!), rows: lines.slice(1).map(parseCsvLine) };
}

function writeCsv(csvPath: string, header: readonly string[], rows: ReadonlyArray<readonly string[]>): void {
    const esc = (v: string): string => {
        if (v.includes(',') || v.includes('"') || v.includes('\n') || v.includes('\r')) {
            return `"${v.replace(/"/g, '""')}"`;
        }
        return v;
    };
    const lines = [header.map(esc).join(','), ...rows.map((r) => r.map(esc).join(','))];
    writeFileSync(csvPath, lines.join('\n') + '\n', 'utf8');
}

// ---------- Core: resolve a single CSV ----------

export function resolveCsv(
    csvPath: string,
    resolvedPath: string,
    mappings: Mappings,
    contextObjectName?: string,
): {
    rowsIn: number;
    rowsOut: number;
    columnsRenamed: number;
    polymorphicResolved: number;
} {
    const { header, rows } = readCsv(csvPath);
    const colMetas = classifyColumns(header, contextObjectName);

    const passthroughMetas = colMetas.filter((cm) => cm.type !== 'polymorphic-what' && cm.type !== 'polymorphic-who' && cm.type !== 'drop');
    const whatMetas = colMetas.filter((cm) => cm.type === 'polymorphic-what');
    const whoMetas = colMetas.filter((cm) => cm.type === 'polymorphic-who');

    const newHeader: string[] = passthroughMetas.map((cm) => cm.newName);
    if (whatMetas.length > 0) newHeader.push('WhatId');
    if (whoMetas.length > 0) newHeader.push('WhoId');

    let polymorphicResolved = 0;
    let columnsRenamed = 0;
    for (const cm of colMetas) {
        if (cm.type === 'custom-lookup') columnsRenamed++;
    }

    const newRows: string[][] = rows.map((row) => {
        const newRow: string[] = [];
        let whatId = '';
        let whoId = '';

        for (const cm of colMetas) {
            const val = row[cm.oldIdx] ?? '';
            if (val === undefined || val === 'null') {
                // skip
            }
            switch (cm.type) {
                case 'passthrough':
                    newRow.push(val ?? '');
                    break;
                case 'standard-lookup':
                case 'custom-lookup':
                    if (val && val !== 'null') {
                        const objMap = mappings.seedTagToId.get(cm.target!);
                        const id = objMap?.get(val) ?? '';
                        newRow.push(id);
                    } else {
                        newRow.push('');
                    }
                    break;
                case 'polymorphic-what':
                    if (val && val !== 'null') {
                        const objMap = mappings.seedTagToId.get(cm.target!);
                        const id = objMap?.get(val) ?? '';
                        if (id) { whatId = id; polymorphicResolved++; }
                    }
                    break;
                case 'polymorphic-who':
                    if (val && val !== 'null') {
                        const objMap = mappings.seedTagToId.get(cm.target!);
                        const id = objMap?.get(val) ?? '';
                        if (id) { whoId = id; polymorphicResolved++; }
                    }
                    break;
                case 'owner':
                    if (val && val.includes('@')) {
                        const id = mappings.usernameToId.get(val) ?? '';
                        newRow.push(id);
                    } else {
                        newRow.push(val ?? '');
                    }
                    break;
                case 'pricebook':
                    if (val === '__STANDARD_PRICEBOOK__') {
                        newRow.push(mappings.standardPricebookId);
                    } else {
                        newRow.push(val ?? '');
                    }
                    break;
                case 'product-code':
                    if (val) {
                        const id = mappings.productCodeToId.get(val) ?? '';
                        newRow.push(id);
                    } else {
                        newRow.push('');
                    }
                    break;
                case 'pbe-code':
                    if (val) {
                        const id = mappings.productCodeToPbeId.get(val) ?? '';
                        newRow.push(id);
                    } else {
                        newRow.push('');
                    }
                    break;
                case 'drop':
                    // Column removed from resolved CSV (loader-only traceability).
                    break;
            }
        }

        if (whatMetas.length > 0) newRow.push(whatId);
        if (whoMetas.length > 0) newRow.push(whoId);

        return newRow;
    });

    writeCsv(resolvedPath, newHeader, newRows);
    return { rowsIn: rows.length, rowsOut: newRows.length, columnsRenamed, polymorphicResolved };
}

// ---------- OLI dedup: filter against existing (OpportunityId, Product2Id) pairs ----------

export function dedupOli(
    resolvedOliPath: string,
    dedupedOliPath: string,
    existingPairs: ReadonlySet<string>,
): { rowsIn: number; rowsOut: number; skipped: number } {
    const { header, rows } = readCsv(resolvedOliPath);
    const oppIdx = header.indexOf('OpportunityId');
    const prodIdx = header.indexOf('Product2Id');
    if (oppIdx < 0 || prodIdx < 0) {
        throw new Error(`OLI CSV missing OpportunityId or Product2Id column: ${resolvedOliPath}`);
    }
    const kept: string[][] = [];
    let skipped = 0;
    for (const row of rows) {
        const key = `${row[oppIdx]}|${row[prodIdx]}`;
        if (existingPairs.has(key)) {
            skipped++;
        } else {
            kept.push(row);
        }
    }
    writeCsv(dedupedOliPath, header, kept);
    return { rowsIn: rows.length, rowsOut: kept.length, skipped };
}

export function buildExistingOliPairs(records: ReadonlyArray<{ OpportunityId: string; Product2Id: string }>): Set<string> {
    const s = new Set<string>();
    for (const r of records) s.add(`${r.OpportunityId}|${r.Product2Id}`);
    return s;
}

// ---------- QLI preflight: validate resolved QuoteLineItem rows ----------

export interface QliCheckResult {
    ok: boolean;
    rows: number;
    emptyPBE: number;
    pbeNotInMap: number;
    pbeNoProduct2: number;
    emptyQuote: number;
    quoteNotInOrg: number;
    emptyQty: number;
    zeroQty: number;
    emptyUnitPrice: number;
    nonNumericUnitPrice: number;
    nonPositiveUnitPrice: number;
}

/**
 * Validates a resolved QuoteLineItem CSV against the live org's PBE and Quote
 * maps. Every required field is checked: PricebookEntryId (non-empty, exists in
 * the PBE map, has a Product2Id), QuoteId (non-empty, exists in the org), Quantity
 * (non-empty, > 0), and UnitPrice (non-empty, numeric, > 0). Pure function — no
 * Salesforce calls. The loader calls this before submitting the bulk job so a
 * mapping bug fails fast (exit 7) instead of producing a 80/80 partial-failure
 * bulk job. */
export function validateQliRows(
    csvPath: string,
    options: { pbeIdToProduct2Id: ReadonlyMap<string, string>; quoteIdSet: ReadonlySet<string> },
): QliCheckResult {
    const empty = (): QliCheckResult => ({
        ok: true, rows: 0, emptyPBE: 0, pbeNotInMap: 0, pbeNoProduct2: 0,
        emptyQuote: 0, quoteNotInOrg: 0, emptyQty: 0, zeroQty: 0,
        emptyUnitPrice: 0, nonNumericUnitPrice: 0, nonPositiveUnitPrice: 0,
    });
    const text = readFileSync(csvPath, 'utf8');
    const lines = text.split(/\r?\n/).filter((l) => l.length > 0);
    if (lines.length <= 1) return empty();
    const header = parseCsvLine(lines[0]!);
    const pIdx = header.indexOf('PricebookEntryId');
    const qIdx = header.indexOf('QuoteId');
    const qtyIdx = header.indexOf('Quantity');
    const upIdx = header.indexOf('UnitPrice');
    if (pIdx < 0) throw new Error('QLI CSV missing PricebookEntryId column');
    if (qIdx < 0) throw new Error('QLI CSV missing QuoteId column');
    if (qtyIdx < 0) throw new Error('QLI CSV missing Quantity column');
    if (upIdx < 0) throw new Error('QLI CSV missing UnitPrice column');
    let emptyPBE = 0, pbeNotInMap = 0, pbeNoProduct2 = 0;
    let emptyQuote = 0, quoteNotInOrg = 0;
    let emptyQty = 0, zeroQty = 0;
    let emptyUnitPrice = 0, nonNumericUnitPrice = 0, nonPositiveUnitPrice = 0;
    for (let i = 1; i < lines.length; i++) {
        const c = parseCsvLine(lines[i]!);
        const pbe = c[pIdx] ?? '';
        if (!pbe) emptyPBE++;
        else if (!options.pbeIdToProduct2Id.has(pbe)) pbeNotInMap++;
        else if (!options.pbeIdToProduct2Id.get(pbe)) pbeNoProduct2++;
        const q = c[qIdx] ?? '';
        if (!q) emptyQuote++;
        else if (!options.quoteIdSet.has(q)) quoteNotInOrg++;
        const qty = c[qtyIdx] ?? '';
        if (!qty) emptyQty++;
        else if (qty === '0' || /^0+\.0*$/.test(qty)) zeroQty++;
        const up = c[upIdx] ?? '';
        if (!up) emptyUnitPrice++;
        else {
            const n = Number(up);
            if (!Number.isFinite(n)) nonNumericUnitPrice++;
            else if (n <= 0) nonPositiveUnitPrice++;
        }
    }
    const problems = emptyPBE + pbeNotInMap + pbeNoProduct2
        + emptyQuote + quoteNotInOrg
        + emptyQty + zeroQty
        + emptyUnitPrice + nonNumericUnitPrice + nonPositiveUnitPrice;
    return {
        ok: problems === 0,
        rows: lines.length - 1,
        emptyPBE, pbeNotInMap, pbeNoProduct2,
        emptyQuote, quoteNotInOrg,
        emptyQty, zeroQty,
        emptyUnitPrice, nonNumericUnitPrice, nonPositiveUnitPrice,
    };
}

// ---------- Plan filter (pure) ----------

export interface PlanStepLike {
    object: string;
    csv: string;
    rows: number;
    externalIdCol: string;
    mode: 'upsert' | 'create';
}

/** Return the plan filtered to a single object. Empty result if not found. */
export function filterPlanByObject(plan: ReadonlyArray<PlanStepLike>, onlyObject: string): PlanStepLike[] {
    return plan.filter((s) => s.object === onlyObject);
}

// ---------- Bulk API result accounting (pure) ----------

/** Count the data rows in a CSV string (excludes header). Returns 0 for empty
 *  string or header-only. The caller distinguishes missing vs. header-only via
 *  the matching `*FileExists` boolean on the evidence object. */
export function countCsvDataRows(csvContent: string): number {
    if (csvContent === '') return 0;
    const lines = csvContent.split(/\r?\n/).filter((l) => l.length > 0);
    return Math.max(0, lines.length - 1);
}

export interface BulkResultEvidence {
    /** Contents of the resolved CSV that was passed to `sf data upsert bulk`.
     *  Empty string = file unreadable. Header-only = 0 rows. */
    loadFileContent: string;
    /** Whether the success-records.csv file exists in the working directory. */
    successFileExists: boolean;
    /** Contents of the success-records.csv file. Empty if missing. */
    successFileContent: string;
    /** Whether the failed-records.csv file exists. (CLI omits it when zero
     *  failures, so missing + 0 CLI-reported failures = 0 failed rows.) */
    failedFileExists: boolean;
    /** Contents of the failed-records.csv file. Empty if missing. */
    failedFileContent: string;
    /** Job Id parsed from the CLI stdout. Empty if not found. */
    jobId: string;
    /** Process exit code of the `sf` invocation. */
    cliStatus: number;
    /** Combined CLI stdout + stderr (used for Processed/Failed counts). */
    cliStdout: string;
    cliStderr: string;
}

export interface BulkResultEvaluation {
    ok: boolean;
    reason: string;
    submitted: number;
    succeeded: number;
    failed: number;
    processed: number | null;
    unprocessed: number;
}

/**
 * Verifies a Bulk API 2.0 job result with complete success accounting.
 * Returns ok=true ONLY if ALL of the following hold:
 *   1. cliStatus === 0
 *   2. jobId is non-empty
 *   3. loadFileContent has > 0 data rows (i.e. something was actually submitted)
 *   4. success-records.csv exists and has > 0 data rows
 *   5. failed-records.csv reports 0 failed rows (file content or CLI output)
 *   6. succeeded === submitted (every submitted row is accounted for as success)
 *   7. unprocessed === 0 (succeeded + failed == submitted)
 *   8. if Processed records is parseable from CLI, it equals submitted
 * Any other combination, including missing files, header-only results, or
 * silent partial-success, returns ok=false with a reason string. */
export function evaluateBulkResult(ev: BulkResultEvidence): BulkResultEvaluation {
    const reasonParts: string[] = [];
    const submitted = countCsvDataRows(ev.loadFileContent);
    const succeeded = countCsvDataRows(ev.successFileContent);
    const failedFromFile = countCsvDataRows(ev.failedFileContent);
    const outText = (ev.cliStdout || '') + (ev.cliStderr || '');
    const cliFailedMatch = outText.match(/Failed\s+records\s*:\s*(\d+)/i);
    const cliFailedCount = cliFailedMatch ? parseInt(cliFailedMatch[1]!, 10) : 0;
    const processedMatch = outText.match(/Processed\s+records\s*:\s*(\d+)/i);
    const processedCount = processedMatch ? parseInt(processedMatch[1]!, 10) : null;

    if (ev.cliStatus !== 0) reasonParts.push(`exit=${ev.cliStatus}`);
    if (!ev.jobId) reasonParts.push('no_job_id');
    if (submitted <= 0) reasonParts.push('no_submitted_rows');
    if (!ev.successFileExists) reasonParts.push('no_success_file');
    if (succeeded <= 0) reasonParts.push('empty_success_file');
    if (failedFromFile > 0) reasonParts.push(`failed_file_rows=${failedFromFile}`);
    if (cliFailedCount > 0) reasonParts.push(`cli_failed=${cliFailedCount}`);
    if (submitted > 0 && succeeded !== submitted) reasonParts.push(`succeeded_mismatch=${succeeded}/${submitted}`);
    if (processedCount !== null && submitted > 0 && processedCount !== submitted) {
        reasonParts.push(`processed_mismatch=${processedCount}/${submitted}`);
    }
    const unprocessed = Math.max(0, submitted - succeeded - failedFromFile);
    if (submitted > 0 && unprocessed > 0) reasonParts.push(`unprocessed=${unprocessed}`);

    const ok = reasonParts.length === 0;
    return {
        ok,
        reason: ok ? 'ok' : reasonParts.join(';'),
        submitted,
        succeeded,
        failed: Math.max(failedFromFile, cliFailedCount),
        processed: processedCount,
        unprocessed,
    };
}
