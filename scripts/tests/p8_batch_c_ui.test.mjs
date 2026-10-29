import { readFileSync } from 'node:fs';
import { runInNewContext } from 'node:vm';
import assert from 'node:assert/strict';
import test from 'node:test';

// Actual component methods with platform bindings stubbed; not a DOM/screen-reader test.
// The shell's CurrentPageReference decorator is stripped so the setter can be invoked directly;
// the navigation mixin is stubbed and exposes a symbol-keyed Navigate method.
function component(name, bindings = {}) {
    const mixin = Base => class extends Base { [mixin.Navigate](reference) { this.navigatedTo = reference; } };
    mixin.Navigate = Symbol('Navigate');
    const source = readFileSync(`force-app/main/default/lwc/${name}/${name}.js`, 'utf8')
        .replace(/^import .*;\r?\n/gm, '')
        .replace(/^[ \t]*@wire\(CurrentPageReference\)[ \t]*\r?\n/gm, '')
        .replace('export default class', 'globalThis.Component = class');
    const context = { LightningElement: class {}, isGuest: false, NavigationMixin: mixin, ...bindings };
    runInNewContext(source, context);
    return new context.Component();
}
function luminance(hex) {
    const channels = hex.match(/[a-f\d]{2}/gi).map(x => parseInt(x, 16) / 255)
        .map(v => v <= .04045 ? v / 12.92 : ((v + .055) / 1.055) ** 2.4);
    return channels[0] * .2126 + channels[1] * .7152 + channels[2] * .0722;
}
function contrast(a, b) { const x = [luminance(a), luminance(b)].sort((a, b) => b - a); return (x[0] + .05) / (x[1] + .05); }

test('owned palette meets text and focus contrast arithmetic', () => {
    for (const [text, background] of [['20242a', 'ffffff'], ['242a32', 'ffffff'], ['52606d', 'f5f7fa'], ['135de6', 'ffffff']]) {
        assert.ok(contrast(text, background) >= 4.5, `${text}/${background}`);
    }
    assert.ok(contrast('ffffff', '171a1f') >= 3);
});
test('native layouts reflow and do not depend on mobile-unsupported datatables', () => {
    for (const name of ['ownerPortalHome', 'ownerPortalCases', 'ownerPortalHistory', 'ownerPortalLoyalty', 'ownerPortalVehicles', 'ownerPortalAppointment']) {
        const root = `force-app/main/default/lwc/${name}/${name}`;
        const html = readFileSync(root + '.html', 'utf8'); const css = readFileSync(root + '.css', 'utf8');
        assert.doesNotMatch(html, /lightning-datatable|lwc:dom|innerHTML/);
        assert.match(css, /overflow-wrap: anywhere/);
        assert.doesNotMatch(css, /outline:\s*(none|0)|min-width:\s*\d{3,}px/);
    }
    const css = readFileSync('force-app/main/default/lwc/ownerPortalHome/ownerPortalHome.css', 'utf8');
    assert.match(css, /min-width: 40rem/); assert.match(css, /min-width: 64rem/);
    assert.match(css, /min-height: 44px/); assert.match(css, /prefers-reduced-motion/);
});
test('view navigation accepts only allowlisted views and preserves mounted workflows', () => {
    const navigations = [];
    const mixin = Base => class extends Base { [mixin.Navigate](reference) { navigations.push(reference); } };
    mixin.Navigate = Symbol('Navigate');
    const widget = component('ownerPortalHome', {
        NavigationMixin: mixin, URL,
        window: { location: { href: 'https://example.test/owners/s/' } }
    });
    const page = { type: 'standard__webPage', attributes: { url: '/owners/s/' }, state: {} };

    widget.setPageReference(page);
    assert.equal(widget.view, 'dashboard');

    widget.setPageReference({ ...page, state: { c__view: 'service', c__service: 'booking' } });
    assert.equal(widget.view, 'service'); assert.equal(widget.serviceView, 'booking');
    assert.equal(widget.bookingHidden, false); assert.equal(widget.bookingVisited, true);

    widget.setPageReference({ ...page, state: { c__view: 'support' } });
    assert.equal(widget.supportVisited, true); assert.equal(widget.bookingHidden, true);

    // Returning reuses the already-mounted booking child instead of creating a new one.
    widget.setPageReference({ ...page, state: { c__view: 'service', c__service: 'booking' } });
    assert.equal(widget.bookingVisited, true); assert.equal(widget.bookingHidden, false);

    // An unknown or malformed target falls back to Dashboard with a customer-safe announcement.
    widget.setPageReference({ ...page, state: { c__view: 'admin', c__service: 'launch' } });
    assert.equal(widget.view, 'dashboard');
    assert.equal(widget.serviceView, 'appointments');
    assert.match(widget.navigationError, /unavailable/);

    // Links cannot navigate to an arbitrary view or before the page reference is known.
    const prevent = { preventDefault() { throw new Error('prevented'); } };
    widget.navigate({ currentTarget: { dataset: { view: 'admin' } }, button: 0, preventDefault() {} });
    assert.equal(navigations.length, 0);

    // A web-page reference has no state channel, so the URL carries the same parameters.
    widget.pageReference = page;
    widget.navigate({ currentTarget: { dataset: { view: 'support' } }, button: 0, preventDefault() {} });
    assert.equal(navigations.length, 1);
    assert.equal(navigations[0].type, 'standard__webPage');
    assert.match(navigations[0].attributes.url, /\?c__view=support$/);
    assert.doesNotMatch(navigations[0].attributes.url, /c__service/);

    // A named Experience page uses the router's state object and keeps unrelated state.
    widget.pageReference = { type: 'comm__namedPage', attributes: { name: 'home' }, state: { existing: 'kept' } };
    widget.navigate({ currentTarget: { dataset: { view: 'service', service: 'history' } }, button: 0, preventDefault() {} });
    assert.equal(navigations.length, 2);
    assert.equal(navigations[1].state.c__view, 'service');
    assert.equal(navigations[1].state.c__service, 'history');
    assert.equal(navigations[1].state.existing, 'kept');
    assert.equal(JSON.stringify(navigations[1].attributes), JSON.stringify({ name: 'home' }));

    // Modified clicks retain native link behaviour, such as opening a new tab.
    widget.navigate({ currentTarget: { dataset: { view: 'garage' } }, button: 0, metaKey: true, ...prevent });
    assert.equal(navigations.length, 2);
});
test('deep-link arrival does not steal focus; in-session view changes focus the heading', () => {
    const mixin = Base => class extends Base {};
    let focused = 0;
    const widget = component('ownerPortalHome', { NavigationMixin: mixin });
    widget.template = { querySelector: selector => {
        assert.equal(selector, '[data-view-heading]');
        return { focus() { focused++; } };
    } };
    // Initial deep link: view is applied, but focus stays where the customer expects.
    widget.setPageReference({ type: 'comm__namedPage', attributes: { name: 'home' }, state: { c__view: 'garage' } });
    widget.renderedCallback();
    assert.equal(widget.view, 'garage'); assert.equal(focused, 0);
    // A subsequent Back/Forward or link change moves focus to the announced heading.
    widget.setPageReference({ type: 'comm__namedPage', attributes: { name: 'home' }, state: { c__view: 'support' } });
    widget.renderedCallback();
    widget.renderedCallback();
    assert.equal(focused, 1);
});
test('invalid Case form reports and focuses input without an Apex write', async () => {
    let writes = 0; let focused = 0; let reported = 0;
    const widget = component('ownerPortalCases', { createCase: async () => { writes++; } });
    const input = { name: 'subject', setCustomValidity(message) { assert.match(message, /subject/); },
        reportValidity() { reported++; return false; }, checkValidity() { return false; }, focus() { focused++; } };
    widget.template = { querySelectorAll: () => [input] };
    widget.subject = '   ';
    await widget.create(); assert.equal(writes, 0); assert.equal(focused, 1); assert.equal(reported, 1);
    assert.match(widget.error, /subject/);
});
test('Case selection uses native action and focuses the published-comments heading', async () => {
    let focused = 0;
    const widget = component('ownerPortalCases', { getComments: async () => [] });
    widget.rows = [{ Id: 'own-case', CaseNumber: '000123' }];
    widget.template = { querySelector: selector => { assert.equal(selector, '[data-comment-heading]'); return { focus() { focused++; } }; } };
    await widget.choose({ currentTarget: { dataset: { caseId: 'foreign-not-in-list' } } });
    await widget.choose({ currentTarget: { dataset: { caseId: 'own-case' } } });
    assert.equal(focused, 1); assert.equal(widget.commentsLoading, false);
    assert.equal(widget.caseCards[0].expanded, 'true'); assert.equal(widget.selectedCaseNumber, '000123');
});
test('blank comment reports validation, focuses field and does not write', async () => {
    let writes = 0; let focused = 0;
    const widget = component('ownerPortalCases', { addComment: async () => { writes++; } });
    widget.selectedCase = 'own-case'; widget.commentBody = '  ';
    widget.template = { querySelector: () => ({ setCustomValidity() {}, reportValidity() { return false; }, focus() { focused++; } }) };
    await widget.comment(); assert.equal(writes, 0); assert.equal(focused, 1); assert.match(widget.error, /Enter a comment/);
});
test('templates preserve labels, keyboard semantics and announced states', () => {
    const home = readFileSync('force-app/main/default/lwc/ownerPortalHome/ownerPortalHome.html', 'utf8');
    assert.match(home, /Skip to portal content/); assert.match(home, /<main/); assert.match(home, /<nav aria-label/);
    const cases = readFileSync('force-app/main/default/lwc/ownerPortalCases/ownerPortalCases.html', 'utf8');
    assert.match(cases, /<button type="button"/); assert.match(cases, /aria-expanded=/);
    assert.match(cases, /data-case-input label="New Case subject"/); assert.match(cases, /data-comment-input label=/);
    assert.match(cases, /aria-describedby="comment-help"/); assert.match(cases, /role="alert"/); assert.match(cases, /aria-busy=/);
    const history = readFileSync('force-app/main/default/lwc/ownerPortalHistory/ownerPortalHistory.html', 'utf8');
    assert.match(history, /<caption>/); assert.match(history, /scope="col"/); assert.match(history, /role="region".*tabindex="0"/);
});
