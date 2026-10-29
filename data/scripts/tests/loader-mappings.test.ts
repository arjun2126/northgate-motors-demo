/**
 * Loader mappings test — verifies the Mappings shape has both PBE maps the
 * QLI preflight and resolver depend on, and that a real-world population
 * (matching the live org's 77 standard active PBEs) succeeds.
 * Pure function, no Salesforce calls.
 */
import { strict as assert } from 'node:assert';
import { validateQliRows, Mappings } from '../resolve.js';
import { mkdtempSync, writeFileSync, rmSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';

function t1() {
    // The Mappings type must include the new PBE→Product2 and quoteIdSet fields.
    // Type-only assertion; if this compiles, the field is present.
    const m: Mappings = {
        seedTagToId: new Map(),
        usernameToId: new Map(),
        standardPricebookId: '',
        productCodeToId: new Map(),
        productCodeToPbeId: new Map(),
        pbeIdToProduct2Id: new Map(),
        quoteIdSet: new Set(),
    };
    assert.equal(m.pbeIdToProduct2Id.size, 0);
    assert.equal(m.quoteIdSet.size, 0);
    assert.equal(m.productCodeToPbeId.size, 0);
    console.log('  PASS mappings: includes pbeIdToProduct2Id, quoteIdSet, productCodeToPbeId');
}

function t2() {
    // Realistic mapping: 77 standard active PBEs (matches live ng-demo).
    // QuoteLineItem preflight using a derived quoteIdSet from a seedTagToId map
    // must succeed for all rows.
    const dir = mkdtempSync(join(tmpdir(), 'p5-mappings-'));
    try {
        const pbeIdToProduct2Id = new Map<string, string>();
        const productCodeToPbeId = new Map<string, string>();
        const seedTagToId = new Map<string, Map<string, string>>();
        const quoteMap = new Map<string, string>();
        const productMap = new Map<string, string>();
        for (let i = 1; i <= 77; i++) {
            const code = `TRIM-${i.toString().padStart(3, '0')}`;
            const pbeId = `01tPBE${i.toString().padStart(3, '0')}`;
            const p2Id = `01tP2${i.toString().padStart(3, '0')}`;
            pbeIdToProduct2Id.set(pbeId, p2Id);
            productCodeToPbeId.set(code, pbeId);
            productMap.set(code, p2Id);
        }
        for (let i = 1; i <= 60; i++) {
            const tag = `SEED-12-${i.toString().padStart(3, '0')}`;
            const id = `0Q0Q${i.toString().padStart(3, '0')}`;
            quoteMap.set(tag, id);
        }
        const quoteIdByIdx = (i: number) => `0Q0Q${i.toString().padStart(3, '0')}`;
        seedTagToId.set('Quote', quoteMap);
        seedTagToId.set('Product2', productMap);

        // Build quoteIdSet the same way load.ts does after the seed-tag query.
        const quoteIdSet = new Set<string>();
        for (const id of quoteMap.values()) quoteIdSet.add(id);

        // Build a 80-row QLI that references codes 1..30 (within the 77 PBE set).
        const rows: string[] = [];
        for (let i = 1; i <= 80; i++) {
            const codeIdx = (i % 30) + 1;
            const code = `TRIM-${codeIdx.toString().padStart(3, '0')}`;
            const pbeId = productCodeToPbeId.get(code)!;
            const q = quoteIdByIdx(((i - 1) % 60) + 1);
            rows.push(`SEED-13-${i.toString().padStart(3, '0')}-01,${q},${pbeId},1,${i * 1000}`);
        }
        const csv = join(dir, 'qli.csv');
        writeFileSync(csv, ['Seed_Tag__c,QuoteId,PricebookEntryId,Quantity,UnitPrice', ...rows].join('\n') + '\n', 'utf8');

        const r = validateQliRows(csv, { pbeIdToProduct2Id, quoteIdSet });
        assert.equal(r.ok, true, `unexpected problems: ${JSON.stringify(r)}`);
        assert.equal(r.rows, 80);
        assert.equal(pbeIdToProduct2Id.size, 77);
        assert.equal(quoteIdSet.size, 60);
        console.log('  PASS mappings: 80-row QLI resolves against 77 PBE + 60 Quote map');
    } finally { rmSync(dir, { recursive: true, force: true }); }
}

t1();
t2();
console.log('[loader-mappings.test] PASS — Mappings shape + realistic PBE/Quote population');
