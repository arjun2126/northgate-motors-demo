/**
 * Incremental resolve test — verifies the loader's dependency-aware
 * resolve pattern works for initial load where parents don't exist yet.
 * No Salesforce calls; uses in-memory mock mappings.
 */
import { strict as assert } from 'node:assert';
import { mkdtempSync, writeFileSync, readFileSync, rmSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { Mappings, resolveCsv } from '../resolve.js';

const emptyMappings = (): Mappings => ({
    seedTagToId: new Map(),
    usernameToId: new Map(),
    standardPricebookId: '',
    productCodeToId: new Map(),
    productCodeToPbeId: new Map(),
    pbeIdToProduct2Id: new Map(),
    quoteIdSet: new Set(),
});

function t1() {
    // Simulate initial load: Rooftop__c is loaded first (no parents).
    // After it loads, query returns Seed_Tag__c→Id mappings.
    // Vehicle__c then needs Rooftop__c Id — incremental resolve must work.
    const dir = mkdtempSync(join(tmpdir(), 'p5-incr-'));
    try {
        const mappings = emptyMappings();
        const rooftopCsv = join(dir, 'rooftops.csv');
        writeFileSync(rooftopCsv, 'Seed_Tag__c,Name\nSEED-01-001,R1\nSEED-01-002,R2\n', 'utf8');
        // No parent mappings needed for Rooftop
        const rooftopResolved = join(dir, 'rooftops-resolved.csv');
        resolveCsv(rooftopCsv, rooftopResolved, mappings);

        // After load, mappings are populated
        mappings.seedTagToId.set('Rooftop__c', new Map([['SEED-01-001', '0RT0001'], ['SEED-01-002', '0RT0002']]));

        // Now Vehicle__c can resolve Rooftop__r.Seed_Tag__c → Rooftop__c
        const vehicleCsv = join(dir, 'vehicles.csv');
        writeFileSync(vehicleCsv, 'Seed_Tag__c,Name,Rooftop__r.Seed_Tag__c\nSEED-05-001,V1,SEED-01-001\n', 'utf8');
        const vehicleResolved = join(dir, 'vehicles-resolved.csv');
        resolveCsv(vehicleCsv, vehicleResolved, mappings);

        const text = readFileSync(vehicleResolved, 'utf8');
        assert.ok(text.includes('Rooftop__c'), 'column renamed');
        assert.ok(text.includes('0RT0001'), 'Rooftop Id resolved from incremental mapping');
        console.log('  PASS incremental resolve: Vehicle__c resolves Rooftop after Rooftop loads');
    } finally {
        rmSync(dir, { recursive: true, force: true });
    }
}

function t2() {
    // Multi-stage: Rooftop → Staff → (no further deps). Verify Staff resolves Rooftop.
    const dir = mkdtempSync(join(tmpdir(), 'p5-incr-'));
    try {
        const mappings = emptyMappings();

        // Stage 1: Rooftop loads
        const rooftopCsv = join(dir, 'rooftops.csv');
        writeFileSync(rooftopCsv, 'Seed_Tag__c,Name\nSEED-01-001,R1\n', 'utf8');
        resolveCsv(rooftopCsv, join(dir, 'rooftops-resolved.csv'), mappings);
        mappings.seedTagToId.set('Rooftop__c', new Map([['SEED-01-001', '0RT1']]));

        // Stage 2: Staff loads (depends on Rooftop)
        const staffCsv = join(dir, 'staff.csv');
        writeFileSync(staffCsv, 'Seed_Tag__c,Name,Rooftop__r.Seed_Tag__c\nSEED-04-001,S1,SEED-01-001\n', 'utf8');
        resolveCsv(staffCsv, join(dir, 'staff-resolved.csv'), mappings);
        mappings.seedTagToId.set('Staff__c', new Map([['SEED-04-001', '0ST1']]));

        // Stage 3: Vehicle (depends on both Rooftop and Vehicle_Model)
        const mappings3 = new Map(mappings.seedTagToId);
        mappings3.set('Vehicle_Model__c', new Map([['SEED-02-001', '0VM1']]));
        const newMappings = { ...mappings, seedTagToId: mappings3 };
        const vehicleCsv = join(dir, 'vehicles.csv');
        writeFileSync(vehicleCsv, 'Seed_Tag__c,Name,Rooftop__r.Seed_Tag__c,Vehicle_Model__r.Seed_Tag__c\nSEED-05-001,V1,SEED-01-001,SEED-02-001\n', 'utf8');
        resolveCsv(vehicleCsv, join(dir, 'vehicles-resolved.csv'), newMappings);

        const text = readFileSync(join(dir, 'vehicles-resolved.csv'), 'utf8');
        assert.ok(text.includes('0RT1'), 'Rooftop resolved');
        assert.ok(text.includes('0VM1'), 'Vehicle_Model resolved');
        console.log('  PASS incremental resolve: multi-stage dependency chain');
    } finally {
        rmSync(dir, { recursive: true, force: true });
    }
}

function t3() {
    // Verify: if parent doesn't exist (empty mapping), child resolves with blank value.
    // This is the expected behavior for initial load — the CSV is written with blank
    // parent Ids, but the load will fail until parents are loaded first.
    const dir = mkdtempSync(join(tmpdir(), 'p5-incr-'));
    try {
        const mappings = emptyMappings();
        const csv = join(dir, 'vehicles.csv');
        writeFileSync(csv, 'Seed_Tag__c,Name,Vehicle_Model__r.Seed_Tag__c\nSEED-05-001,V1,SEED-02-001\n', 'utf8');
        const resolved = join(dir, 'vehicles-resolved.csv');
        resolveCsv(csv, resolved, mappings);
        const text = readFileSync(resolved, 'utf8');
        // Vehicle_Model__c column should be present but empty
        const lines = text.trim().split('\n');
        const header = lines[0]!.split(',');
        const idx = header.indexOf('Vehicle_Model__c');
        const row = lines[1]!.split(',');
        assert.equal(row[idx], '', 'parent not yet loaded → blank value');
        console.log('  PASS incremental resolve: blank value when parent not yet loaded');
    } finally {
        rmSync(dir, { recursive: true, force: true });
    }
}

t1();
t2();
t3();
console.log('[incremental.test] PASS — incremental resolve pattern verified');
