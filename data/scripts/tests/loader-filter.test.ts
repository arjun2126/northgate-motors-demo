/**
 * Loader filter test — verifies filterPlanByObject() narrows the plan to a
 * single object without mutating the input. Pure function, no Salesforce calls.
 */
import { strict as assert } from 'node:assert';
import { filterPlanByObject, PlanStepLike } from '../resolve.js';

const SAMPLE: PlanStepLike[] = [
    { object: 'Rooftop__c',          csv: '01-rooftops.csv',         rows: 4,   externalIdCol: 'Seed_Tag__c', mode: 'upsert' },
    { object: 'Product2',            csv: '03-products.csv',         rows: 60,  externalIdCol: 'Seed_Tag__c', mode: 'upsert' },
    { object: 'OpportunityLineItem', csv: '11-opptylineitems.csv',   rows: 100, externalIdCol: '',           mode: 'create' },
    { object: 'Quote',               csv: '12-quotes.csv',           rows: 60,  externalIdCol: 'Seed_Tag__c', mode: 'upsert' },
    { object: 'QuoteLineItem',       csv: '13-quotelineitems.csv',   rows: 80,  externalIdCol: 'Seed_Tag__c', mode: 'upsert' },
];

function t1() {
    // Filter to QuoteLineItem → exactly one step, the right one.
    const out = filterPlanByObject(SAMPLE, 'QuoteLineItem');
    assert.equal(out.length, 1);
    assert.equal(out[0]?.csv, '13-quotelineitems.csv');
    assert.equal(out[0]?.mode, 'upsert');
    console.log('  PASS filter: --object QuoteLineItem → 1 step');
}

function t2() {
    // Filter to a create-mode object (OpportunityLineItem) preserves mode.
    const out = filterPlanByObject(SAMPLE, 'OpportunityLineItem');
    assert.equal(out.length, 1);
    assert.equal(out[0]?.mode, 'create');
    assert.equal(out[0]?.externalIdCol, '');
    console.log('  PASS filter: --object OpportunityLineItem → create-mode preserved');
}

function t3() {
    // Unknown object → empty result (loader aborts with exit 1 on this case).
    const out = filterPlanByObject(SAMPLE, 'Financing__c');
    assert.equal(out.length, 0);
    console.log('  PASS filter: unknown object → empty result');
}

function t4() {
    // Original plan not mutated (filter must not be destructive).
    const before = SAMPLE.map((s) => s.object).join(',');
    filterPlanByObject(SAMPLE, 'QuoteLineItem');
    const after = SAMPLE.map((s) => s.object).join(',');
    assert.equal(before, after);
    console.log('  PASS filter: input plan not mutated');
}

t1();
t2();
t3();
t4();
console.log('[loader-filter.test] PASS — filterPlanByObject selects one step, preserves mode, non-destructive');
