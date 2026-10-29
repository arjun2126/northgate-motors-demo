/**
 * QLI preflight test — verifies validateQliRows() catches every failure mode
 * that previously caused 80/80 partial-failure bulk jobs against QuoteLineItem.
 * Pure function, no Salesforce calls.
 */
import { strict as assert } from 'node:assert';
import { mkdtempSync, writeFileSync, rmSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { validateQliRows } from '../resolve.js';

function writeQli(dir: string, name: string, header: string, rows: string[]): string {
    const p = join(dir, name);
    writeFileSync(p, [header, ...rows].join('\n') + '\n', 'utf8');
    return p;
}

function t1() {
    // All rows valid: PBE in map with Product2, Quote in set, Qty>0, UnitPrice>0.
    const dir = mkdtempSync(join(tmpdir(), 'p5-qli-'));
    try {
        const pbeMap = new Map([['01tXX', '01tYY']]);
        const quoteSet = new Set(['0Q0AA']);
        const csv = writeQli(dir, 'qli.csv',
            'Seed_Tag__c,QuoteId,PricebookEntryId,Quantity,UnitPrice',
            ['SEED-1,0Q0AA,01tXX,1,81043']);
        const r = validateQliRows(csv, { pbeIdToProduct2Id: pbeMap, quoteIdSet: quoteSet });
        assert.equal(r.ok, true);
        assert.equal(r.rows, 1);
        assert.equal(r.emptyPBE + r.pbeNotInMap + r.pbeNoProduct2 + r.emptyQuote + r.quoteNotInOrg + r.emptyQty + r.zeroQty + r.emptyUnitPrice + r.nonNumericUnitPrice + r.nonPositiveUnitPrice, 0);
        console.log('  PASS QLI: all valid rows → ok');
    } finally { rmSync(dir, { recursive: true, force: true }); }
}

function t2() {
    // Empty PBE column (the original 80-row failure). Must report and fail.
    const dir = mkdtempSync(join(tmpdir(), 'p5-qli-'));
    try {
        const csv = writeQli(dir, 'qli.csv',
            'Seed_Tag__c,QuoteId,PricebookEntryId,Quantity,UnitPrice',
            ['SEED-1,0Q0AA,,1,81043']);
        const r = validateQliRows(csv, { pbeIdToProduct2Id: new Map(), quoteIdSet: new Set(['0Q0AA']) });
        assert.equal(r.ok, false);
        assert.equal(r.emptyPBE, 1);
        console.log('  PASS QLI: empty PBE → fail (emptyPBE=1)');
    } finally { rmSync(dir, { recursive: true, force: true }); }
}

function t3() {
    // PBE present in row but not in org map (PBE was deleted or never created).
    const dir = mkdtempSync(join(tmpdir(), 'p5-qli-'));
    try {
        const csv = writeQli(dir, 'qli.csv',
            'Seed_Tag__c,QuoteId,PricebookEntryId,Quantity,UnitPrice',
            ['SEED-1,0Q0AA,01tNOPE,1,81043']);
        const r = validateQliRows(csv, {
            pbeIdToProduct2Id: new Map([['01tOK', '01tP2']]),
            quoteIdSet: new Set(['0Q0AA']),
        });
        assert.equal(r.ok, false);
        assert.equal(r.pbeNotInMap, 1);
        console.log('  PASS QLI: PBE not in org map → fail (pbeNotInMap=1)');
    } finally { rmSync(dir, { recursive: true, force: true }); }
}

function t4() {
    // PBE exists but its Product2Id is empty (would fail at insert time).
    const dir = mkdtempSync(join(tmpdir(), 'p5-qli-'));
    try {
        const csv = writeQli(dir, 'qli.csv',
            'Seed_Tag__c,QuoteId,PricebookEntryId,Quantity,UnitPrice',
            ['SEED-1,0Q0AA,01tXX,1,81043']);
        const r = validateQliRows(csv, {
            pbeIdToProduct2Id: new Map([['01tXX', '']]),
            quoteIdSet: new Set(['0Q0AA']),
        });
        assert.equal(r.ok, false);
        assert.equal(r.pbeNoProduct2, 1);
        console.log('  PASS QLI: PBE has empty Product2Id → fail (pbeNoProduct2=1)');
    } finally { rmSync(dir, { recursive: true, force: true }); }
}

function t5() {
    // QuoteId not in the live set. Stale or fictional reference.
    const dir = mkdtempSync(join(tmpdir(), 'p5-qli-'));
    try {
        const csv = writeQli(dir, 'qli.csv',
            'Seed_Tag__c,QuoteId,PricebookEntryId,Quantity,UnitPrice',
            ['SEED-1,0Q0FAKE,01tXX,1,81043']);
        const r = validateQliRows(csv, {
            pbeIdToProduct2Id: new Map([['01tXX', '01tP2']]),
            quoteIdSet: new Set(['0Q0REAL']),
        });
        assert.equal(r.ok, false);
        assert.equal(r.quoteNotInOrg, 1);
        console.log('  PASS QLI: Quote not in org set → fail (quoteNotInOrg=1)');
    } finally { rmSync(dir, { recursive: true, force: true }); }
}

function t6() {
    // Quantity 0 and missing UnitPrice must both be flagged.
    const dir = mkdtempSync(join(tmpdir(), 'p5-qli-'));
    try {
        const csv = writeQli(dir, 'qli.csv',
            'Seed_Tag__c,QuoteId,PricebookEntryId,Quantity,UnitPrice',
            [
                'SEED-1,0Q0AA,01tXX,0,81043',
                'SEED-2,0Q0AA,01tXX,1,',
            ]);
        const r = validateQliRows(csv, {
            pbeIdToProduct2Id: new Map([['01tXX', '01tP2']]),
            quoteIdSet: new Set(['0Q0AA']),
        });
        assert.equal(r.ok, false);
        assert.equal(r.zeroQty, 1);
        assert.equal(r.emptyUnitPrice, 1);
        console.log('  PASS QLI: zero Qty + empty UnitPrice → fail (both flagged)');
    } finally { rmSync(dir, { recursive: true, force: true }); }
}

function t7() {
    // Non-numeric and non-positive UnitPrice must be flagged.
    const dir = mkdtempSync(join(tmpdir(), 'p5-qli-'));
    try {
        const csv = writeQli(dir, 'qli.csv',
            'Seed_Tag__c,QuoteId,PricebookEntryId,Quantity,UnitPrice',
            [
                'SEED-1,0Q0AA,01tXX,1,abc',
                'SEED-2,0Q0AA,01tXX,1,-5',
                'SEED-3,0Q0AA,01tXX,1,0',
            ]);
        const r = validateQliRows(csv, {
            pbeIdToProduct2Id: new Map([['01tXX', '01tP2']]),
            quoteIdSet: new Set(['0Q0AA']),
        });
        assert.equal(r.ok, false);
        assert.equal(r.nonNumericUnitPrice, 1);
        assert.equal(r.nonPositiveUnitPrice, 2);
        console.log('  PASS QLI: bad UnitPrice (non-numeric + negative + zero) → fail');
    } finally { rmSync(dir, { recursive: true, force: true }); }
}

function t8() {
    // 80-row sweep: all valid → ok, with realistic PBE/Quote maps.
    const dir = mkdtempSync(join(tmpdir(), 'p5-qli-'));
    try {
        const pbeMap = new Map<string, string>();
        const quoteSet = new Set<string>();
        const rows: string[] = [];
        for (let i = 0; i < 80; i++) {
            const pbe = `01tPBE${i.toString().padStart(3, '0')}`;
            const p2 = `01tP2${i.toString().padStart(3, '0')}`;
            const q = `0Q0Q${i.toString().padStart(3, '0')}`;
            pbeMap.set(pbe, p2);
            quoteSet.add(q);
            rows.push(`SEED-13-${i.toString().padStart(3, '0')}-01,${q},${pbe},1,${(i + 1) * 1000}`);
        }
        const csv = writeQli(dir, 'qli.csv',
            'Seed_Tag__c,QuoteId,PricebookEntryId,Quantity,UnitPrice',
            rows);
        const r = validateQliRows(csv, { pbeIdToProduct2Id: pbeMap, quoteIdSet: quoteSet });
        assert.equal(r.ok, true);
        assert.equal(r.rows, 80);
        console.log('  PASS QLI: 80-row sweep → ok');
    } finally { rmSync(dir, { recursive: true, force: true }); }
}

t1();
t2();
t3();
t4();
t5();
t6();
t7();
t8();
console.log('[qli-preflight.test] PASS — validateQliRows catches every failure mode');
