import { readFileSync } from 'node:fs';
import { runInNewContext } from 'node:vm';
import assert from 'node:assert/strict';
import test from 'node:test';

// Execute real controller state logic with platform bindings stubbed; this is not a DOM/browser test.
function component(bundle, bindings) {
    const source = readFileSync(new URL(`../../force-app/main/default/lwc/${bundle}/${bundle}.js`, import.meta.url), 'utf8')
        .replace(/^import .*;\r?\n/gm, '').replace(/@api\s+/g, '').replace('export default class', 'globalThis.Component = class');
    const context = { LightningElement: class { isConnected = true; }, console, ...bindings };
    runInNewContext(source, context);
    return new context.Component();
}
const page = id => ({ cards: [{ id, reservable: false, imagePath: '/resource/NG_VehicleImages/aurelia_ex.webp' }], nextId: id, hasMore: false });
const platform = { onError() {}, isEmpEnabled: async () => false, subscribe: async () => ({}), unsubscribe() {} };

test('gallery discards stale filter replies and supports missing-image fallback', async () => {
    const pending = [];
    const gallery = component('inventoryGallery', { ...platform, browse: () => new Promise(resolve => pending.push(resolve)) });
    const older = gallery.load(false);
    gallery.make = 'Cascadia';
    const newer = gallery.load(false);
    pending[1](page('new')); await newer;
    pending[0](page('old')); await older;
    assert.equal(gallery.cards[0].id, 'new');
    assert.equal(gallery.busy, false);
    gallery.handleImageError({ target: { dataset: { id: 'new' } } });
    assert.equal(gallery.cards[0].imagePath, null);
});

test('reservation requires contact and refreshes actual inventory without a reload', async () => {
    let calls = 0;
    const gallery = component('inventoryGallery', { ...platform, browse: async () => page('reserved'), reserve: async args => {
        calls++; assert.equal(args.vehicleId, 'vehicle'); assert.equal(args.contactId, 'contact');
    } });
    const event = { target: { dataset: { id: 'vehicle' } } };
    await gallery.handleReserve(event); assert.equal(calls, 0); assert.match(gallery.error, /Select a Contact/);
    gallery.contactId = 'contact'; await gallery.handleReserve(event);
    assert.equal(calls, 1); assert.equal(gallery.notice, 'Reservation saved.'); assert.equal(gallery.cards[0].reserveDisabled, true);
});

test('late event subscription is released after disconnect', async () => {
    let resolveSubscription; let released = 0;
    const gallery = component('inventoryGallery', { ...platform, browse: async () => page('v'), isEmpEnabled: async () => true,
        subscribe: () => new Promise(resolve => { resolveSubscription = resolve; }), unsubscribe: () => { released++; } });
    gallery.connectedCallback();
    await new Promise(resolve => setImmediate(resolve));
    gallery.isConnected = false; gallery.disconnectedCallback(); resolveSubscription({ id: 'subscription' });
    await new Promise(resolve => setImmediate(resolve));
    assert.equal(released, 1); assert.ok(!gallery.subscription);
});

test('calculator discards stale estimate after an input edit and preserves explicit zero rate', async () => {
    let resolvePreview; let supplied;
    const calculator = component('opportunityCalculator', { amount: async () => 30000, preview: args => {
        supplied = args; return new Promise(resolve => { resolvePreview = resolve; });
    } });
    calculator.recordId = 'opportunity'; calculator.sellingPrice = 30000; calculator.manualRate = '0';
    const pending = calculator.calculate();
    calculator.handleInput({ target: { name: 'sellingPrice' }, detail: { value: '20000' } });
    resolvePreview({ monthlyPayment: 500 }); await pending;
    assert.equal(calculator.result, null); assert.equal(calculator.busy, false);
    assert.equal(supplied.manualRate, 0); assert.equal(calculator.number(''), null);
});
