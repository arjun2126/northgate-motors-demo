// Component state/static presentation contracts only; not a Salesforce DOM or PDF renderer.
import { readFileSync } from 'node:fs';
import { runInNewContext } from 'node:vm';
import assert from 'node:assert/strict';
import test from 'node:test';

const base = new URL('../../force-app/main/default/lwc/quoteSummary/', import.meta.url);
const html = readFileSync(new URL('quoteSummary.html', base), 'utf8');
const css = readFileSync(new URL('quoteSummary.css', base), 'utf8');

test('quote names and line descriptions wrap instead of truncating', () => {
    assert.match(html, /class="summary-name[^\"]*" title=\{summary.quoteName\}/);
    assert.match(html, /class="line-name" title=\{line.name\}/);
    assert.doesNotMatch(html, /slds-truncate[^\"]*" title=\{(?:summary|line)\./);
    assert.match(css, /overflow-wrap: anywhere/);
    assert.equal((html.match(/summary-grid slds-grid slds-wrap/g) || []).length, 4);
});

test('print rules expose horizontal overflow, allow table pagination and hide controls', () => {
    assert.match(css, /@media print/);
    assert.match(css, /\.line-items\s*\{\s*overflow: visible;\s*max-height: none;/);
    assert.match(css, /table-layout: fixed/);
    assert.match(css, /display: table-header-group/);
    assert.match(css, /\.quote-lines tr\s*\{\s*break-inside: avoid;/);
    assert.match(css, /\.print-actions,\s*lightning-helptext\s*\{\s*display: none;/);
    assert.doesNotMatch(css, /(?:^|\n)\s*(?:body|html)\s*[{,]|position:\s*(?:fixed|absolute)|height:\s*100vh/);
});

test('displayed financial bindings, signed adjustment and official totals remain present', () => {
    for (const field of ['listSubtotal', 'adjustedSubtotal', 'discountPercent', 'rulesApplied', 'grandTotal']) {
        assert.match(html, new RegExp(`value=\\{summary\\.${field}\\}`));
    }
    assert.match(html, /Positive = net discount\. Negative = net premium uplift/);
    assert.match(html, /Tax and shipping are not included/);
});

test('printing stays read-only and does not price, save or submit the historical Quote', async () => {
    let prints = 0;
    const requests = [];
    const source = readFileSync(new URL('quoteSummary.js', base), 'utf8')
        .replace(/^import .*;\r?\n/gm, '')
        .replace(/^\s*@wire\(.*\)\r?\n/gm, '')
        .replace(/@(?:api|track)\s*/g, '')
        .replace('export default class', 'globalThis.Component = class');
    const data = { listSubtotal: 50615, adjustedSubtotal: 43022.75, rulesApplied: 1, discountPercent: 15, approvalStatus: 'Pending' };
    const context = { LightningElement: class {}, NavigationMixin: baseClass => baseClass,
        window: { print: () => { prints += 1; } },
        getFieldValue: () => '006aj00000fbDI1AAM', getSummary: args => { requests.push(args); return Promise.resolve(data); } };
    runInNewContext(source, context);
    const summary = new context.Component();
    summary.recordId = '0Q0aj000003kVS5CAM';
    summary.connectedCallback();
    await new Promise(resolve => setImmediate(resolve));
    summary.handlePrint();
    assert.equal(prints, 1);
    assert.equal(requests.length, 1);
    assert.equal(requests[0].quoteId, summary.recordId);
    assert.equal(summary.summary, data);
    assert.equal(summary.approvalStatusLabel, 'Pending review');
});
