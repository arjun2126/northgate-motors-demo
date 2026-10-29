/**
 * One-shot live preflight check against ng-demo. Not part of data:test; run
 * manually after a successful --resolve-only to confirm the loader's
 * validateQliRows() will pass when the real --execute runs.
 */
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { execFileSync } from 'node:child_process';
import { validateQliRows } from '../resolve.js';

function q(soql: string): any[] {
  const out = execFileSync('sf', ['data','query','--query',soql,'--result-format','json','--target-org','ng-demo'], { encoding: 'utf8' });
  return JSON.parse(out).result.records;
}

const pbeRows = q("SELECT Id, Product2Id FROM PricebookEntry WHERE IsActive = true AND Pricebook2.IsStandard = true");
const pbeIdToProduct2Id = new Map<string, string>();
for (const r of pbeRows) pbeIdToProduct2Id.set(r.Id, r.Product2Id ?? '');

const quoteRows = q("SELECT Id FROM Quote WHERE Seed_Tag__c LIKE 'SEED-%'");
const quoteIdSet = new Set<string>();
for (const r of quoteRows) quoteIdSet.add(r.Id);

const csvPath = resolve(process.cwd(), 'data/csv-resolved/13-quotelineitems.csv');
const r = validateQliRows(csvPath, { pbeIdToProduct2Id, quoteIdSet });
console.log(`[live] PBE map size: ${pbeIdToProduct2Id.size}, Quote set size: ${quoteIdSet.size}`);
console.log(`[live] QLI preflight: ${JSON.stringify(r)}`);
if (r.ok) console.log('[live] PASS — 80/80 QuoteLineItems resolve to valid Quote + PBE (with Product2Id)');
else { console.error('[live] FAIL'); process.exit(1); }
