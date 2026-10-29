// Run: node --test scripts/tests/finance_launch_context.test.mjs
// Exercises the real component handlers; Salesforce enforces access in Apex tests.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';
import vm from 'node:vm';

const source = readFileSync(new URL('../../force-app/main/default/lwc/financeApplication/financeApplication.js', import.meta.url), 'utf8');
const javascript = source
    .replace(/^import .*;\n/gm, '')
    .replace(/@(?:api|track)\s*/g, '')
    .replace('export default class FinanceApplication', 'class FinanceApplication')
    + '\nglobalThis.Finance = FinanceApplication;';
const opportunityId = '006000000000001AAA';
const financingId = 'a04000000000001AAA';
const quoteId = '0Q0000000000001AAA';
const settle = () => new Promise(resolve => setImmediate(resolve));

function component(data, error, saveResult = { errors: [], financingId }) {
    const calls = { load: [], preview: [], save: [] };
    const context = vm.createContext({
        LightningElement: class {},
        loadFinanceWizard: input => {
            calls.load.push(input);
            return error ? Promise.reject(error) : Promise.resolve(data);
        },
        previewApplication: input => {
            calls.preview.push(input);
            return Promise.resolve({ errors: [], monthlyPayment: 500 });
        },
        saveApplication: input => {
            calls.save.push(input);
            return Promise.resolve(saveResult);
        }
    });
    vm.runInContext(javascript, context);
    return { app: new context.Finance(), calls };
}

for (const [name, launchId] of [['Opportunity', opportunityId], ['Financing', financingId]]) {
    test(`${name} launch uses resolved Opportunity for preview and save, preserving draft ID`, async () => {
        const { app, calls } = component({
            opportunityId, quoteId, recordId: financingId, mode: 'edit', status: 'Draft',
            downPayment: 2000, termMonths: 60, rateSource: 'Rate_Table'
        });
        app.recordId = launchId;
        await settle();
        assert.equal(calls.load.length, 1);
        assert.equal(calls.load[0].recordId, launchId);
        assert.equal(calls.preview[0].opportunityId, opportunityId);
        assert.equal(calls.preview[0].quoteId, quoteId);
        assert.equal(app.showExistingDraftNotice, true);
        app.handleSave();
        await settle();
        assert.equal(calls.save[0].opportunityId, opportunityId);
        assert.equal(calls.save[0].recordId, financingId);
        assert.equal(calls.save[0].downPayment, 2000);
        assert.equal(app.savedFinancingId, financingId);
    });
}

test('new Opportunity draft keeps a null Financing ID after selecting a quote', async () => {
    const { app, calls } = component({ opportunityId, recordId: null, quoteId: null, mode: 'new' });
    app.recordId = opportunityId;
    await settle();
    assert.equal(calls.preview.length, 0);
    app.handleQuoteChange({ detail: { value: quoteId } });
    await settle();
    assert.equal(calls.preview[0].opportunityId, opportunityId);
    app.handleSave();
    await settle();
    assert.equal(calls.save[0].recordId, null);
    assert.equal(calls.save[0].opportunityId, opportunityId);
});

test('denied context leaves no loaded data or downstream request', async () => {
    const { app, calls } = component(undefined, { body: { message: 'Financing record or linked Opportunity not found or inaccessible.' } });
    app.recordId = financingId;
    await settle();
    assert.equal(app.data, undefined);
    assert.equal(app.loading, false);
    assert.equal(app.error, 'Financing record or linked Opportunity not found or inaccessible.');
    assert.equal(calls.preview.length, 0);
    app.handleSave();
    assert.equal(calls.save.length, 0);
});

test('existing Draft has one editing notice, never a new-draft notice', async () => {
    const { app } = component({ opportunityId, recordId: financingId, mode: 'edit', status: 'Draft' });
    app.recordId = financingId;
    assert.equal(app.draftNotice, null, 'loading must not flash a new-draft banner');
    await settle();
    assert.match(app.draftNotice, /^Editing existing Draft/);
    assert.doesNotMatch(app.draftNotice, /New Draft/);
});

test('new Draft notice becomes saved notice without changing save inputs or CP2 preview', async () => {
    const { app, calls } = component({ opportunityId, quoteId, recordId: null, mode: 'new' });
    app.recordId = opportunityId;
    await settle();
    assert.equal(app.draftNotice, 'New Draft application.');
    app.handleSave();
    await settle();
    assert.equal(app.draftNotice, 'Draft application saved for this Opportunity.');
    assert.equal(calls.save.length, 1);
    assert.equal(calls.save[0].recordId, null);
    assert.equal(calls.save[0].quoteId, quoteId);
});

test('existing-draft save rejection suppresses stale new-draft notice and never retries', async () => {
    const message = 'A Draft already exists for this Opportunity; opening it instead.';
    const { app, calls } = component({ opportunityId, quoteId, mode: 'new' }, null, { errors: [message] });
    app.recordId = opportunityId;
    await settle();
    app.handleSave();
    await settle();
    assert.equal(app.error, message);
    assert.equal(app.draftNotice, null);
    assert.equal(calls.save.length, 1);
    assert.equal(calls.load.length, 1, 'no hidden retry or automatic draft opening introduced');
    assert.equal(app.savedFinancingId, null);
});

test('ambiguous context is not labeled new or editing', async () => {
    const { app } = component({ opportunityId, recordId: financingId, mode: 'ambiguous', status: 'Draft' });
    app.recordId = opportunityId;
    await settle();
    assert.equal(app.draftNotice, 'Multiple Draft applications exist for this Opportunity.');
    assert.doesNotMatch(app.draftNotice, /New Draft|Editing/);
});

test('unknown context has neutral copy and denied loading has no draft notice', async () => {
    const { app } = component({ opportunityId, mode: 'unexpected' });
    app.recordId = opportunityId;
    await settle();
    assert.equal(app.draftNotice, 'Finance application details.');
    const denied = component(null, { body: { message: 'Access denied' } }).app;
    denied.recordId = financingId;
    await settle();
    assert.equal(denied.draftNotice, null);
});

test('template renders only one draft notice region', () => {
    const html = readFileSync(new URL('../../force-app/main/default/lwc/financeApplication/financeApplication.html', import.meta.url), 'utf8');
    assert.equal((html.match(/\{draftNotice\}/g) || []).length, 2, 'one conditional and one text binding');
    assert.doesNotMatch(html, /if:false=\{showExistingDraftNotice\}|New Draft application\./);
    assert.match(html, /<template lwc:if=\{draftNotice\}>/);
});
