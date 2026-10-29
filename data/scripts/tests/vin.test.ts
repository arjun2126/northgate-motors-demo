/**
 * VIN check-digit validation tests (data/scripts/generate.ts makes 120 VINs;
 * vinValid must accept every generated VIN).
 */
import { strict as assert } from 'node:assert';
import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { makeVin, vinValid } from '../vin.js';

const REPO_ROOT = process.cwd();
const VEH_CSV = resolve(REPO_ROOT, 'data/csv/06-vehicles.csv');

const lines = readFileSync(VEH_CSV, 'utf8').trim().split(/\r?\n/);
assert.ok(lines.length > 1, `vehicles CSV missing or empty: ${VEH_CSV}`);
const header = lines[0]!.split(',');
const vinIdx = header.indexOf('VIN__c');
assert.ok(vinIdx >= 0, 'VIN__c column missing in 06-vehicles.csv');

const vins: string[] = [];
for (let i = 1; i < lines.length; i++) {
    const cells = lines[i]!.split(',');
    const vin = cells[vinIdx];
    assert.ok(vin, `row ${i + 1} missing VIN`);
    vins.push(vin);
}

assert.equal(vins.length, 120, `expected 120 vehicles, got ${vins.length}`);

const seen = new Set<string>();
for (const vin of vins) {
    assert.equal(vin.length, 17, `VIN ${vin} not 17 chars`);
    assert.ok(vinValid(vin), `VIN ${vin} fails check digit`);
    assert.ok(!seen.has(vin), `duplicate VIN ${vin}`);
    seen.add(vin);
}

// Synthetic round-trip: a freshly minted VIN must also pass.
let rngCalls = 0;
const rand = () => {
    rngCalls++;
    // Deterministic xorshift for reproducibility
    const x = Math.imul(rngCalls ^ 0x9E3779B9, 0x85EBCA6B) >>> 0;
    return (x >>> 0) / 4294967296;
};
const fresh = makeVin(rand, '2024');
assert.equal(fresh.length, 17, 'fresh VIN wrong length');
assert.ok(vinValid(fresh), `fresh VIN ${fresh} fails check digit`);

console.log(`[vin.test] ${vins.length} VINs validated (all unique, all check-digit valid)`);
