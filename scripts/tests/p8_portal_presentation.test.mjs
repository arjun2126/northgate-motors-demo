import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import assert from 'node:assert/strict';
import test from 'node:test';

// Offline source checks, not an LWC compiler, DOM renderer or actual-persona security test.
// Child hashes are the captured dirty-working-tree JavaScript before the presentation work,
// not HEAD or a claim of live-source parity. The shell JavaScript was intentionally changed for
// view navigation in the approved structural redesign; its contracts are checked structurally.
const children = {
    ownerPortalVehicles: '0ba2e0bc05258270608cc9d7481f04c9b00ab53a116b998ed69bbeca20b250e7',
    ownerPortalAppointment: '0b998f96c68898d335151710ac4181a62d5c212968144de9033c31f118fcef8f',
    ownerPortalHistory: 'b7a2e54ddaee7fcb458cafedf51ba352b6ed019522e873f59955751331ae81dc',
    ownerPortalCases: '587fcb5f2b98c79bc5f0a04849211de08c38a4203fd3d05595c7d8c3f79ae34d',
    ownerPortalLoyalty: 'c60c3b17d5559cc8b5336a7c93946ebf6695c705fb26f52de68d5ca1dd6a337c'
};
const source = (name, extension) => readFileSync(`force-app/main/default/lwc/${name}/${name}.${extension}`, 'utf8');
const aura = (name, extension) => readFileSync(`force-app/main/default/aura/${name}/${name}.${extension}`, 'utf8');
const events = {
    ownerPortalVehicles: ['onclick:refresh', 'onclick:select', 'onclick:load', 'onerror:imageError'],
    ownerPortalAppointment: [...Array(4).fill('onchange:input'), 'onclick:load', 'onclick:review', 'onclick:back', 'onclick:submit'],
    ownerPortalHistory: ['onclick:load'],
    ownerPortalCases: [...Array(3).fill('onchange:input'), 'onclick:refresh', 'onclick:choose', 'onclick:load', 'onclick:create', 'onclick:comment'],
    ownerPortalLoyalty: ['onclick:load']
};

test('five child JS implementations and thus child Apex imports/parameters/handlers are byte-preserved', () => {
    for (const [name, hash] of Object.entries(children)) {
        assert.equal(createHash('sha256').update(source(name, 'js')).digest('hex'), hash, name);
        const bindings = [...source(name, 'html').matchAll(/\b(on\w+)=\{(\w+)\}/g)].map(m => `${m[1]}:${m[2]}`).sort();
        assert.deepEqual(bindings, [...events[name]].sort(), `${name} handler wiring`);
    }
});

test('portal shell changes presentation only: one dashboard read, no Apex writes, no new imports', () => {
    const js = source('ownerPortalHome', 'js');
    assert.equal((js.match(/@salesforce\/apex/g) || []).length, 1, 'exactly one Apex import');
    assert.match(js, /import getDashboard from '@salesforce\/apex\/OwnerPortalBatchBController\.getDashboard';/);
    assert.match(js, /import \{ CurrentPageReference, NavigationMixin \} from 'lightning\/navigation';/);
    assert.match(js, /@wire\(CurrentPageReference\)/);
    assert.match(js, /NavigationMixin\.Navigate/);
    assert.match(js, /if \(isGuest \|\| this\.loading\) return;/);
    assert.doesNotMatch(js, /@salesforce\/apex\/[^']*(?:create|update|book|comment|submit|delete)/i);
    assert.doesNotMatch(js, /lightning\/uiRecordApi|getRecord|updateRecord|createRecord|deleteRecord/);
    // The allowlist is the sole navigation source; every advertised view is declared once.
    for (const view of ['dashboard', 'garage', 'service', 'support', 'rewards']) assert.ok(js.includes(`{ value: '${view}',`), view);
    for (const service of ['appointments', 'booking', 'history']) assert.ok(js.includes(`{ value: '${service}',`), service);
    const bindings = [...source('ownerPortalHome', 'html').matchAll(/\b(on\w+)=\{(\w+)\}/g)].map(m => `${m[1]}:${m[2]}`).sort();
    assert.deepEqual(bindings, [
        'onclick:load', 'onclick:load',
        ...Array(10).fill('onclick:navigate'),
        'onclick:skipToContent', 'onclick:toggleMenu', 'onkeydown:closeMenu'
    ].sort());
});

test('templates have balanced tags, unique local IDs and resolvable static ARIA references', () => {
    const voids = new Set(['br', 'img', 'hr', 'input', 'meta', 'link']);
    for (const name of ['ownerPortalHome', ...Object.keys(children)]) {
        const html = source(name, 'html');
        const stack = [];
        for (const match of html.matchAll(/<(\/?)([a-z][\w-]*)(\s[^<>]*?)?\s*(\/?)>/gi)) {
            const [, closing, tag, , selfClosing] = match;
            if (closing) assert.equal(stack.pop(), tag, `${name}: ${tag}`);
            else if (!selfClosing && !voids.has(tag)) stack.push(tag);
        }
        assert.deepEqual(stack, [], name);
        const ids = [...html.matchAll(/\bid="([^"]+)"/g)].map(m => m[1]);
        assert.equal(new Set(ids).size, ids.length, `${name} duplicate IDs`);
        for (const [, references] of html.matchAll(/\baria-(?:controls|labelledby|describedby)="([^"]+)"/g)) {
            for (const id of references.split(' ')) assert.ok(ids.includes(id), `${name}: ${id}`);
        }
    }
});

test('five-view shell mounts each child once, hides inactive panels and keeps future features non-interactive', () => {
    const html = source('ownerPortalHome', 'html');
    for (const view of ['dashboard', 'garage', 'service', 'support', 'rewards']) {
        assert.match(html, new RegExp(`data-view-panel="${view}"`));
    }
    for (const child of ['vehicles', 'appointment', 'history', 'cases', 'loyalty']) {
        assert.equal((html.match(new RegExp(`<c-owner-portal-${child}>`, 'g')) || []).length, 1);
    }
    for (const flag of ['dashboardHidden', 'garageHidden', 'serviceHidden', 'supportHidden', 'rewardsHidden', 'bookingHidden', 'historyHidden', 'appointmentsHidden']) {
        assert.ok(html.includes(`hidden={${flag}}`), flag);
    }
    // Monotonic mount flags keep a child instance (and its draft, request token or receipt) alive.
    for (const flag of ['garageVisited', 'bookingVisited', 'historyVisited', 'supportVisited', 'rewardsVisited']) {
        assert.ok(html.includes(`lwc:if={${flag}}`), flag);
    }
    const future = html.match(/<aside class="future-experiences"[\s\S]*?<\/aside>/);
    assert.ok(future, 'planned experiences block');
    for (const label of ['Explore Vehicles', 'Vehicle Studio', 'Test Drives', 'Trade-In']) {
        assert.ok(future[0].includes(`<li>${label}</li>`), label);
    }
    assert.doesNotMatch(future[0], /href=|onclick=/, 'planned experiences must not be links');
    assert.match(html, /lwc:if=\{guest\}/);
    assert.match(html, /Skip to portal content/);
});

test('appointment controls retain names, data hooks, values, catalogs and disabled predicates', () => {
    const html = source('ownerPortalAppointment', 'html');
    for (const [name, disabled, options] of [
        ['vehicleId', 'loading', 'vehicleOptions'], ['rooftopId', 'detailsDisabled', 'rooftops'],
        ['serviceType', 'detailsDisabled', 'services'], ['startsAt', 'detailsDisabled', null]
    ]) {
        const tag = [...html.matchAll(/<lightning-(?:input|combobox)\b[^>]+>/g)].map(m => m[0]).find(t => t.includes(`name="${name}"`));
        assert.ok(tag, name);
        for (const attribute of ['data-input', `value={${name}}`, 'onchange={input}', `disabled={${disabled}}`, 'required']) assert.ok(tag.includes(attribute), `${name}: ${attribute}`);
        if (options) assert.ok(tag.includes(`options={${options}}`));
    }
    assert.match(html, /label="Submit service request" onclick=\{submit\} disabled=\{submitDisabled\}/);
    assert.match(html, /lwc:if=\{reviewing\}/);
    assert.match(html, /lwc:if=\{receipt\}/);
    assert.match(html, /Reference: \{receipt\}/);
    assert.match(html, /Requested does not mean Scheduled/);
});

test('Case form hooks, validation limits, focus targets and public-comment warnings survive', () => {
    const html = source('ownerPortalCases', 'html');
    for (const [name, hook, max] of [['subject', 'data-case-input', 255], ['description', 'data-case-input', 4000], ['commentBody', 'data-comment-input', 4000]]) {
        const tag = [...html.matchAll(/<lightning-(?:input|textarea)\b[^>]+>/g)].map(m => m[0]).find(t => t.includes(`name="${name}"`));
        for (const attr of [hook, `value={${name}}`, 'onchange={input}', `maxlength="${max}"`]) assert.ok(tag?.includes(attr), `${name}: ${attr}`);
        if (name !== 'description') assert.ok(tag.includes('required'));
    }
    assert.match(html, /data-comment-heading tabindex="-1"/);
    assert.match(html, /data-case-error tabindex="-1"/);
    assert.match(html, /aria-expanded=\{row.expanded\} disabled=\{loading\}/);
    assert.match(html, /Do not include payment details or passwords/);
});

test('vehicle artwork is neutral; existing selected-image failure handler/disclosure remain', () => {
    const html = source('ownerPortalVehicles', 'html');
    assert.equal((html.match(/<img\b/g) || []).length, 1);
    assert.match(html, /lwc:if=\{selected.photoUrl\} src=\{selected.photoUrl\} alt=\{selected.photoAlt\}/);
    assert.match(html, /data-vehicle-id=\{selected.vehicleId\} onerror=\{imageError\}/);
    assert.match(html, /Vehicle photo unavailable/);
    assert.match(html, /not proof of this vehicle's exact colour or specification/);
    assert.match(html, /lwc:if=\{selected.canRequestService\}/);
    assert.match(html, /separate servicing authorization is required/);
});

test('unavailable states remain errors; data is never replaced by fabricated balances or receipts', () => {
    for (const name of ['ownerPortalHome', ...Object.keys(children)]) {
        const html = source(name, 'html');
        assert.match(html, /lwc:if=\{error\}[^>]*role="alert"/);
        assert.match(html, /aria-busy=\{loading\}/);
        assert.doesNotMatch(html, /innerHTML|lwc:dom|lightning-record|lightning-datatable|https?:\/\//);
    }
    const home = source('ownerPortalHome', 'html');
    for (const state of ['summary.caseError', 'summary.appointmentError', 'summary.loyaltyError']) assert.ok(home.includes(`lwc:if={${state}}`));
    assert.match(home, /Unavailable is not a zero balance/);
    assert.match(home, /summary\.vehicleMessage/);
    assert.match(source('ownerPortalLoyalty', 'html'), /without recalculation, accrual or redemption/);
    assert.match(source('ownerPortalHistory', 'html'), /Individual dated odometer readings, not proof of ownership or a combined vehicle mileage total/);
});

test('full-width theme and single-region content layouts are supported metadata, not CSS breakouts', () => {
    const theme = aura('ngOwnerThemeLayout', 'cmp');
    assert.match(theme, /implements="forceCommunity:themeLayout"/);
    assert.match(theme, /<aura:attribute name="profileMenu" type="Aura.Component\[\]"/);
    assert.match(theme, /\{!v\.body\}/);
    const content = aura('ngOwnerContentLayout', 'cmp');
    assert.match(content, /implements="forceCommunity:layout"/);
    assert.match(content, /\{!v\.content\}/);
    for (const [name, css] of [['ngOwnerThemeLayout', aura('ngOwnerThemeLayout', 'css')], ['ngOwnerContentLayout', aura('ngOwnerContentLayout', 'css')]]) {
        assert.match(css, /width: 100%/, name);
        assert.match(css, /max-width: none/, name);
        assert.doesNotMatch(css, /1140px|1200px|90rem|margin:\s*0 auto/, name);
    }
    // The shell itself must not reimpose a centred maximum width or hide overflow.
    const home = source('ownerPortalHome', 'css');
    assert.match(home, /\.portal \{ width: 100%; max-width: none;/);
    assert.doesNotMatch(home, /max-width:\s*(?:90rem|\d{3,}px)/);
    assert.doesNotMatch(home, /overflow-x:\s*hidden|100vw/);
});

function luminance(hex) {
    const rgb = hex.match(/../g).map(x => parseInt(x, 16) / 255).map(x => x <= .04045 ? x / 12.92 : ((x + .055) / 1.055) ** 2.4);
    return rgb[0] * .2126 + rgb[1] * .7152 + rgb[2] * .0722;
}
test('new palette text pairs meet WCAG AA contrast arithmetic (not rendered contrast)', () => {
    for (const [a, b] of [['20242a','ffffff'], ['242a32','ffffff'], ['52606d','f5f7fa'], ['135de6','ffffff'], ['ffffff','135de6'], ['ffffff','171a1f'], ['cad3df','171a1f'], ['104cbf','edf3ff'], ['a9caff','20242a'], ['8c2525','fff3f0'], ['e1e6ed','20242a']]) {
        const [hi, lo] = [luminance(a), luminance(b)].sort((x, y) => y - x);
        assert.ok((hi + .05) / (lo + .05) >= 4.5, `${a}/${b}`);
    }
});

test('320/768/1440 breakpoint source contracts: single-column feature stack and 1/2/4 summaries', () => {
    // Declarations begin after a block/semicolon (or at the start of a fragment),
    // unlike media feature conditions, which begin after an opening parenthesis.
    const restrictiveMinimumWidth = /(?:^|[;{])\s*min-width\s*:\s*(?:[1-9]\d*(?:\.\d+)?|0?\.\d*[1-9]\d*)(?:px|rem)\b/i;
    for (const allowed of [
        '@media (min-width: 40rem) { .panel { min-width: 0; } }',
        '@media screen and (min-width: 64rem) { .panel { min-width: 0px; } }',
        '.panel { min-width: 0.0rem; }'
    ]) assert.doesNotMatch(allowed, restrictiveMinimumWidth);
    for (const prohibited of [
        '.panel { min-width: 320px; }',
        '.panel { display: grid; min-width: 40rem; }',
        '@media (min-width: 64rem) { .panel { min-width: 320px; } }',
        'min-width: .5rem;',
        '.panel {\n MIN-WIDTH : 0.75rem; }'
    ]) assert.match(prohibited, restrictiveMinimumWidth);
    const css = source('ownerPortalHome', 'css');
    assert.match(css, /\.summary-grid \{ display: grid; grid-template-columns: minmax\(0, 1fr\)/);
    assert.match(css, /@media \(min-width: 40rem\) \{ \.summary-grid \{ grid-template-columns: repeat\(2, minmax\(0, 1fr\)\)/);
    assert.match(css, /@media \(min-width: 64rem\) \{ \.summary-grid \{ grid-template-columns: repeat\(4, minmax\(0, 1fr\)\)/);
    assert.match(css, /@media \(min-width: 48rem\)/);
    for (const name of ['ownerPortalHome', ...Object.keys(children)]) {
        const styles = source(name, 'css');
        assert.match(styles, /overflow-wrap: anywhere/);
        assert.match(styles, /box-sizing: border-box/);
        assert.doesNotMatch(styles, restrictiveMinimumWidth);
        assert.doesNotMatch(styles, /height:\s*100vh|overflow-x:\s*hidden|outline:\s*(?:none|0)/);
    }
    assert.match(css, /prefers-reduced-motion/);
    for (const name of ['ownerPortalVehicles', 'ownerPortalCases']) assert.match(source(name, 'css'), /min-height: 44px/);
});
