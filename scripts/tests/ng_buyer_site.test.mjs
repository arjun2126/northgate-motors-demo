// Offline static contracts for the buyer website. Not an LWC compiler, DOM render or browser test.
import { readFileSync } from 'node:fs';
import { runInNewContext } from 'node:vm';
import assert from 'node:assert/strict';
import test from 'node:test';

const root = new URL('../../force-app/main/default/', import.meta.url);
const read = (path) => readFileSync(new URL(path, root), 'utf8');
const html = read('lwc/ngBuyerSite/ngBuyerSite.html');
const js = read('lwc/ngBuyerSite/ngBuyerSite.js');
const css = read('lwc/ngBuyerSite/ngBuyerSite.css');
const showcase = read('classes/BuyerShowcaseController.cls');
const inquiry = read('classes/BuyerInquiryController.cls');

test('page shell is accessible and single-purpose', () => {
    assert.equal((html.match(/<h1\b/g) || []).length, 1);
    assert.match(html, /class="skip-link" href="#buyer-main"/);
    assert.match(html, /<main id="buyer-main"/);
    assert.match(html, /aria-live="polite"/);
    assert.match(html, /role="alert"/);
    for (const label of ['Model', 'Body style', 'Colour', 'Condition', 'Maximum listed price']) {
        assert.ok(html.includes(label), label);
    }
    assert.doesNotMatch(html, /innerHTML|lwc:dom|lightning-record|https?:\/\//);
});

test('inventory, detail and studio use real DTO fields only', () => {
    assert.match(js, /import getShowcase from '@salesforce\/apex\/BuyerShowcaseController\.getShowcase'/);
    assert.match(js, /import submitBuyerInquiry from '@salesforce\/apex\/BuyerInquiryController\.submit'/);
    assert.match(js, /vehicle\.price === null \? 'Price on request'/);
    assert.match(js, /imagePath: failed \? null : this\.imageUrl\(vehicle\.imageName\)/);
    assert.match(js, /import NG_VEHICLE_IMAGES from '@salesforce\/resourceUrl\/NG_VehicleImages'/);
    assert.match(js, /imageUrl\(name\) \{ return name \? `\$\{NG_VEHICLE_IMAGES\}\/\$\{name\}` : null; \}/);
    assert.match(js, /COLOUR_SWATCH/);
    assert.match(html, /No vehicles are listed right now/);
    assert.match(html, /concept preview, not a vehicle in inventory/);
    assert.match(html, /not a reservation, confirmed allocation, price or purchase commitment/);
    assert.doesNotMatch(js, /optionPrice|option_price|factoryOption/i, 'no invented option fields or pricing');
    assert.doesNotMatch(js, /\$[0-9]{2,}|[0-9]{2},[0-9]{3}/, 'no hardcoded prices');
});

test('inquiry intake targets standard Lead and never claims a reservation', () => {
    assert.match(html, /This demo records your inquiry/);
    assert.match(html, /does not reserve a vehicle, confirm a price or book an appointment/);
    assert.match(html, /Demo only\. Use a \.test or \.example email address/);
    assert.match(inquiry, /new Lead\(LastName = cleanedName, Company = 'Northgate Motors Website'/);
    assert.match(inquiry, /LeadSource = 'Web'/);
    assert.match(inquiry, /Database\.insert\(lead, AccessLevel\.SYSTEM_MODE\)/);
    assert.doesNotMatch(inquiry, /USER_MODE/, 'guest endpoint must not depend on guest object permissions');
    assert.match(inquiry, /Label\.Buyer_Lead_Queue_Id/);
    assert.doesNotMatch(inquiry, /FROM Group/);
    assert.doesNotMatch(inquiry, /insert new (Opportunity|Quote|Vehicle__c)/);
});

test('server read path is server-mediated, read-only and rejects unsafe images', () => {
    assert.match(showcase, /public without sharing class BuyerShowcaseController/);
    assert.match(showcase, /@AuraEnabled\n    public static Showcase getShowcase/);
    assert.doesNotMatch(showcase, /cacheable=true/);
    assert.match(showcase, /WITH SYSTEM_MODE/);
    assert.match(showcase, /NG_VehicleImages/);
    assert.match(showcase, /Status__c IN :PUBLIC_STATUSES/);
    assert.doesNotMatch(showcase, /\b(insert|update|delete|upsert)\b/i);
});

test('permission set grants Apex access only, with no native object or field access', () => {
    const ps = read('permissionsets/PS_Buyer_Website.permissionset-meta.xml');
    assert.match(ps, /<apexClass>BuyerShowcaseController<\/apexClass>/);
    assert.match(ps, /<apexClass>BuyerInquiryController<\/apexClass>/);
    assert.doesNotMatch(ps, /<objectPermissions>/);
    assert.doesNotMatch(ps, /<fieldPermissions>/);
    assert.doesNotMatch(ps, /<tabSettings>|<customPermissions>|<userPermissions>/);
});

test('responsive, focus and reduced-motion states exist', () => {
    assert.match(css, /@media \(max-width: 40rem\)/);
    assert.match(css, /@media \(max-width: 64rem\)/);
    assert.match(css, /@media \(max-width: 47\.9375rem\)/);
    assert.match(css, /prefers-reduced-motion/);
    assert.match(css, /:focus-visible/);
    assert.match(css, /--ng-control: 44px/);
    assert.match(css, /min-height: var\(--ng-control\)/);
    assert.match(html, /loading="eager"/);
    // Full bleed uses the measured layout viewport so a classic scrollbar cannot create overflow.
    assert.match(css, /--ng-viewport: 100vw/);
    assert.match(css, /width: var\(--ng-viewport\)/);
    assert.match(css, /margin-left: calc\(50% - \(var\(--ng-viewport\) \/ 2\)\)/);
    assert.match(js, /setProperty\('--ng-viewport', width \+ 'px'\)/);
    assert.doesNotMatch(css, /overflow-x:\s*hidden/);
    assert.doesNotMatch(css, /--ng-viewport\) \/ 2\)[^;]*100vw/, 'no unmeasured 100vw in the bleed offsets');
    assert.match(html, /disabled=\{submitDisabled\}/);
    assert.match(css, /scroll-margin-top/, 'anchors clear the sticky header');
});

test('mobile navigation is a labelled disclosure with keyboard and focus handling', () => {
    assert.match(html, /<button type="button" class="menu-toggle" data-menu-toggle aria-controls="buyer-navigation" aria-expanded=\{menuExpanded\} onclick=\{toggleMenu\}>/);
    assert.match(html, /<nav id="buyer-navigation" class=\{navigationClass\} aria-label="Primary">/);
    assert.match(html, /<a href=\{inventoryUrl\} onclick=\{closeMenu\} aria-current=\{inventoryCurrent\}>Inventory<\/a>/);
    assert.match(html, /class="head-cta" href=\{contactUrl\}>Contact Northgate<\/a>/, 'the primary action stays reachable in the header');
    assert.match(js, /get menuExpanded\(\) \{ return this\.menuOpen \? 'true' : 'false'; \}/);
    assert.match(js, /get menuLabel\(\) \{ return this\.menuOpen \? 'Close menu' : 'Menu'; \}/);
    assert.match(js, /toggleMenu\(\) \{ this\.menuOpen = !this\.menuOpen; \}/);
    assert.match(js, /if \(event\.key !== 'Escape' \|\| !this\.menuOpen\) return;/);
    assert.match(js, /\[data-menu-toggle\][\s\S]{0,40}\.focus\(\)/, 'Escape returns focus to the toggle');
    assert.match(js, /startGeneralInquiry\(\) \{[\s\S]{0,220}this\.menuOpen = false;/, 'opening an inquiry closes the menu');
    assert.match(css, /\.menu-toggle \{ display: none;/);
    assert.match(css, /@media \(max-width: 47\.9375rem\) \{\s*\.menu-toggle \{ display: inline-flex; \}/);
    assert.match(css, /\.menu-toggle\[aria-expanded="true"\]/, 'the toggle reflects the expanded state visually');
    assert.match(css, /\.buyer-nav\.is-open \{[^}]*flex-direction: column;/, 'the panel stacks links instead of wrapping them');
    assert.doesNotMatch(css, /\.site-head nav \{ display: none; \}/, 'mobile navigation is no longer simply removed');
});

test('vehicle deep links use a stable record id and survive reload, back and forward', () => {
    assert.match(js, /const VEHICLE_HASH_PREFIX = '#vehicle-';/);
    assert.match(js, /window\.addEventListener\('hashchange', this\.boundHashChange\)/);
    assert.match(js, /try \{ id = decodeURIComponent\(hash\.slice\(VEHICLE_HASH_PREFIX\.length\)\); \}/);
    assert.match(js, /this\.allVehicles\.some\(vehicle => vehicle\.id === id\)/, 'unknown ids never open a detail panel');
    assert.match(js, /openVehicleHash\(this\.selectedVehicleId\)/);
    assert.match(js, /history\.replaceState/, 'closing details clears the fragment without adding history');
    assert.doesNotMatch(js, /#inventory-|vehicleIndex|selectedIndex|index \+ 1/, 'no order-dependent identifiers');
    assert.doesNotMatch(js, /location\.hash = '#inventory-'/, 'legacy index links are not reused');
});

test('colour is presented as recorded data, not as an image-adjacent claim', () => {
    assert.match(html, /<p class="vehicle-meta">\{vehicle\.conditionLabel\}<\/p>/, 'the card caption no longer mixes colour with the photo');
    assert.match(html, /<p lwc:if=\{vehicle\.colour\} class="vehicle-colour"><span>Colour<\/span>\{vehicle\.colour\}<\/p>/);
    assert.match(html, /<p class="vehicle-meta">\{vehicle\.conditionLabel\}<\/p>[\s\S]{0,80}<h3>\{vehicle\.title\}<\/h3>/, 'studio matches drop the colour caption');
    assert.match(html, /Illustrative model images\. Recorded colour is listed on each vehicle/);
    assert.match(html, /Illustrative model images\. Recorded colour is listed on each vehicle/);
    // The Salesforce colour field, filter and detail spec are preserved.
    assert.match(html, /<label>Colour<select data-filter="filterColour"/);
    assert.match(js, /filterColour/);
    assert.match(js, /\{ label: 'Colour', value: vehicle\.colour \}/);
    assert.match(html, /role="group" aria-label="Filter inventory"/);
});

test('clear filters is enabled only when a filter is active', () => {
    const { component } = inquiryScenario(async () => 'NG-CLEAR');
    assert.equal(component.clearDisabled, true, 'nothing to clear on first load');
    assert.match(html, /disabled=\{clearDisabled\}/);
    assert.doesNotMatch(html, /disabled=\{hasActiveFilters\}/, 'the pre-existing inverted predicate is gone');
    component.filterModel = 'a0Caj0000000001';
    assert.equal(component.clearDisabled, false);
    component.clearFilters();
    assert.equal(component.hasActiveFilters, false);
    assert.equal(component.clearDisabled, true);
});

test('cinematic hero is a single image stage, not a split screen', () => {
    assert.match(css, /\.hero \{ display: flex; flex-direction: column; align-items: center; padding: clamp\(2\.75rem, 5vw, 4\.25rem\)/);
    assert.doesNotMatch(css, /\.hero \{[^}]*display:\s*grid/, 'no split-screen hero');
    assert.match(css, /\.hero-media \{ position: relative; width: 100%; max-width: 1000px; aspect-ratio: 16 \/ 10;/);
    assert.match(css, /@media \(max-width: 64rem\) \{[\s\S]*?\.hero-media \{ aspect-ratio: 16 \/ 9; \}/);
    assert.match(css, /@media \(max-width: 40rem\) \{[\s\S]*?\.hero-media \{ aspect-ratio: 4 \/ 3; \}/);
    assert.match(css, /\.hero-media::after/);
    assert.match(css, /\.hero-band \{/, 'stats sit in their own cinematic band');
    assert.match(html, /class="hero-band"/);
    assert.match(html, /Representative imagery/);
    assert.match(html, /class="family-card"/);
});

test('mobile filters are a labelled disclosure, collapsed by default and always available on desktop', () => {
    assert.match(html, /<button type="button" class="filters-toggle" aria-controls="inventory-filters" aria-expanded=\{filtersExpanded\} onclick=\{toggleFilters\}>/);
    assert.match(html, /<div id="inventory-filters" class=\{filtersPanelClass\} role="group" aria-label="Filter inventory">/);
    assert.match(js, /filtersOpen = false;/);
    assert.match(js, /toggleFilters\(\) \{ this\.filtersOpen = !this\.filtersOpen; \}/);
    assert.match(js, /get filtersExpanded\(\)/);
    assert.match(js, /get activeFilterCount\(\)/);
    assert.match(css, /\.filter-bar \{ display: none; \}/);
    // The collapse must live inside the mobile media block, not globally.
    const mobileStart = css.indexOf('@media (max-width: 47.9375rem)');
    assert.ok(mobileStart >= 0, 'mobile media block exists');
    const mobileBlock = css.slice(mobileStart, css.indexOf('@media (max-width: 40rem)'));
    assert.match(mobileBlock, /\.filter-bar \{ display: flex;/);
    assert.match(mobileBlock, /\.filters \{ display: none; \}/);
    assert.match(mobileBlock, /\.filters\.is-open \{ display: grid; \}/);
    assert.doesNotMatch(css.slice(0, mobileStart), /\.filters \{ display: none; \}/, 'desktop filters are never hidden');
    assert.equal((css.match(/\.filters \{ display: none; \}/g) || []).length, 1, 'the collapse rule exists exactly once');
    assert.match(css, /\.filters-toggle \{[^}]*min-height: var\(--ng-control\)/);
});

test('loading uses a skeleton while the status message stays available to assistive tech', () => {
    assert.match(html, /<p lwc:if=\{loading\} class="sr-only" role="status">Loading inventory…<\/p>/);
    assert.match(html, /<div lwc:if=\{loading\} class="skeleton-grid" aria-hidden="true">/);
    assert.match(js, /skeletonCards = \[\{ id: 's1' \}, \{ id: 's2' \}, \{ id: 's3' \}\]/);
    assert.match(css, /\.skeleton-grid \{ display: grid; grid-template-columns: repeat\(3/);
    assert.match(css, /@keyframes ng-shimmer/);
    assert.match(css, /\.skeleton-media, \.skeleton-line \{ animation: none !important; \}/);
});

test('availability messaging is derived from recorded status only', () => {
    assert.match(js, /availabilityNote\(status\) \{/);
    assert.match(js, /status === 'Available'.*Available now/);
    assert.match(js, /status === 'Reserved'.*ask about similar/);
    assert.match(js, /status === 'In_Transit'.*ask for timing/);
    assert.match(html, /<p class=\{vehicle\.availabilityClass\}>\{vehicle\.availabilityNote\}<\/p>/);
    assert.match(css, /\.vehicle-availability\.is-available::before/);
    assert.match(js, /\{ label: 'Body style', value: vehicle\.bodyStyle \}/);
});

test('footer carries the site shell navigation and stacks on phones', () => {
    assert.match(html, /<nav class="foot-nav" aria-label="Footer">/);
    assert.match(html, /<a href=\{inventoryUrl\}>Inventory<\/a>/);
    assert.match(html, /<a href="#top">Back to top<\/a>/);
    assert.match(css, /\.site-foot \{ display: grid; grid-template-columns: minmax\(0, 1fr\) auto;/);
    assert.match(css, /\.foot-nav a \{[^}]*min-height: var\(--ng-control\)/);
    assert.match(css, /\.site-foot \{ grid-template-columns: minmax\(0, 1fr\); \}/);
});

test('polish candidate deploys only the six changed LWC bundles', () => {
    const manifest = readFileSync(new URL('../../manifest/web-polish-2026-10-30.xml', import.meta.url), 'utf8');
    for (const bundle of ['ngBuyerSite', 'ownerPortalCases', 'ownerPortalHistory', 'ownerPortalLoyalty', 'ownerPortalVehicles', 'ownerPortalAppointment']) {
        assert.match(manifest, new RegExp(`<members>${bundle}</members>`), bundle);
    }
    assert.doesNotMatch(manifest, /<name>ApexClass<\/name>|<name>PermissionSet<\/name>|<name>CustomLabels<\/name>|<name>AuraDefinitionBundle<\/name>/);
    assert.doesNotMatch(manifest, /<members>ownerPortalHome<\/members>/, 'unchanged shell is not repackaged');
});

test('component CSS uses only LWC-supported selector forms', () => {
    // LWC rejects id selectors in component CSS (LWC1009). Hex colours are not selectors.
    const selectors = css.replace(/#[0-9a-fA-F]{3,8}\b/g, '').replace(/url\([^)]*\)/g, '');
    assert.doesNotMatch(selectors, /(?:^|[\s,>+~])#[A-Za-z][\w-]*/m, 'no id selectors');
    assert.match(css, /\.hero, \.section \{ scroll-margin-top/);
    assert.doesNotMatch(css, /#top|#inventory|#studio/, 'anchor offsets use classes, not ids');
});

test('studio specification and caption text keeps AA contrast in its real contexts', () => {
    // The Apex console is a light panel inside the dark Studio, so the spec rows use dark ink;
    // the Studio-level caption copy uses light ink on the dark section.
    const apex = read('lwc/ngApexConcept3d/ngApexConcept3d.css');
    assert.match(apex, /--apex-ink-soft: #3c434d;/);
    assert.match(apex, /\.apex-facts dt \{[^}]*color: var\(--apex-ink-soft\);/s);
    assert.match(css, /\.apex-panel \{[^}]*background: #f7f4ee;/);
    assert.match(css, /\.apex-3d \.section-note, \.apex-3d \.studio-sub, \.apex-3d \.micro \{ color: #b9c2cc; \}/);
    const lum = hex => {
        const rgb = hex.match(/../g).map(x => parseInt(x, 16) / 255)
            .map(v => v <= .04045 ? v / 12.92 : ((v + .055) / 1.055) ** 2.4);
        return rgb[0] * .2126 + rgb[1] * .7152 + rgb[2] * .0722;
    };
    const ratio = (a, b) => {
        const [hi, lo] = [lum(a), lum(b)].sort((x, y) => y - x);
        return (hi + .05) / (lo + .05);
    };
    assert.ok(ratio('3c434d', 'f7f4ee') >= 4.5, 'spec labels on the light console');
    assert.ok(ratio('12151a', 'f7f4ee') >= 4.5, 'spec values on the light console');
    assert.ok(ratio('b9c2cc', '0a0d12') >= 4.5, 'studio caption copy on the dark section');
    assert.ok(ratio('12161c', '0a0d12') < 4.5, 'dark ink would be unreadable on the dark section');
});
test('buyer theme layout is full-width, body-only and leaves shared headers out', () => {
    const cmp = read('aura/ngBuyerThemeLayout/ngBuyerThemeLayout.cmp');
    const css = read('aura/ngBuyerThemeLayout/ngBuyerThemeLayout.css');
    assert.match(cmp, /implements="forceCommunity:themeLayout"/);
    assert.match(cmp, /\{!v\.body\}/);
    assert.doesNotMatch(cmp, /\{!v\.profileMenu\}|globalHeader|navigationMenu/);
    assert.match(css, /max-width: none/);
});

test('custom label and manifest carry the queue-only routing configuration', () => {
    const labels = read('labels/CustomLabels.labels-meta.xml');
    const manifest = readFileSync(new URL('../../manifest/buyer-site-mvp.xml', import.meta.url), 'utf8');
    assert.match(labels, /<fullName>Buyer_Lead_Queue_Id<\/fullName>/);
    assert.match(labels, /<value>00G[a-zA-Z0-9]+<\/value>/);
    assert.match(manifest, /<name>CustomLabels<\/name>/);
});

// Behavioural contract for the inquiry completion path. Mocked Apex only; no browser or Lead.
function inquiryScenario(submit) {
    const calls = { submit: 0 };
    const source = read('lwc/ngBuyerSite/ngBuyerSite.js')
        .replace(/^import .*;\r?\n/gm, '')
        .replace(/^\s*@api\s+/gm, '')
        .replace('export default class', 'globalThis.Component = class');
    const context = {
        LightningElement: class {}, Intl,
        window: { location: { pathname: '/owners/s/buyer' } },
        LOCALE: 'en-CA', CURRENCY_CODE: 'CAD', NG_VEHICLE_IMAGES: '/resource/NG_VehicleImages',
        setTimeout, clearTimeout,
        getShowcase: async () => ({ models: [], vehicles: [], availableCount: 0 }),
        submitBuyerInquiry: (...args) => { calls.submit += 1; return submit(...args); }
    };
    runInNewContext(source, context);
    const component = new context.Component();
    component.consent = true;
    component.inquiryName = 'Buyer';
    component.inquiryEmail = 'buyer@northgate.test';
    component.inquiryMessage = 'Please call me.';
    component.submitTimeoutMs = 5;
    return { component, calls };
}

test('a pending Aura action completes to an explicit unconfirmed state, never "Sending…"', async () => {
    const { component, calls } = inquiryScenario(() => new Promise(() => {}));
    await component.submitInquiry();
    assert.equal(calls.submit, 1);
    assert.equal(component.submitting, false);
    assert.equal(component.inquiryUnconfirmed, true);
    assert.equal(component.inquiryError, undefined);
    assert.equal(component.inquiryReference, undefined);
    assert.equal(component.inquiryName, 'Buyer');
    assert.match(html, /Confirmation delayed/);
    assert.match(html, /Please do not send it again/);
});

test('a late success after the timeout cannot claim confirmation or retry', async () => {
    const { component, calls } = inquiryScenario(() => new Promise(resolve => setTimeout(() => resolve('NG-LATE01'), 30)));
    await component.submitInquiry();
    assert.equal(component.inquiryUnconfirmed, true);
    await new Promise(resolve => setTimeout(resolve, 50));
    assert.equal(component.inquiryReference, undefined);
    assert.equal(calls.submit, 1);
});

test('a normal success shows the reference and clears the form', async () => {
    const { component } = inquiryScenario(async () => 'NG-ABC123');
    await component.submitInquiry();
    assert.equal(component.inquiryReference, 'NG-ABC123');
    assert.equal(component.inquiryUnconfirmed, false);
    assert.equal(component.submitting, false);
    assert.equal(component.inquiryName, '');
    assert.equal(component.consent, false);
});

test('a rejection shows the server message without retrying', async () => {
    const { component, calls } = inquiryScenario(async () => { throw { body: { message: 'Enter a valid email address.' } }; });
    await component.submitInquiry();
    assert.equal(calls.submit, 1);
    assert.equal(component.inquiryError, 'Enter a valid email address.');
    assert.equal(component.inquiryUnconfirmed, false);
    assert.equal(component.submitting, false);
});

test('in-flight and unconfirmed states cannot start a second submission', async () => {
    const pending = inquiryScenario(() => new Promise(() => {}));
    pending.component.submitting = true;
    await pending.component.submitInquiry();
    assert.equal(pending.calls.submit, 0);
    const unconfirmed = inquiryScenario(async () => 'NG-ONE');
    unconfirmed.component.inquiryUnconfirmed = true;
    await unconfirmed.component.submitInquiry();
    assert.equal(unconfirmed.calls.submit, 0);
});

test('navigation CTAs keep the unconfirmed warning; only explicit acknowledgement clears it', () => {
    const { component } = inquiryScenario(async () => 'NG-ONE');
    component.inquiryUnconfirmed = true;
    component.consent = true;
    component.startGeneralInquiry();
    assert.equal(component.inquiryUnconfirmed, true, 'a new inquiry must not erase the duplicate warning');
    assert.equal(component.submitDisabled, true, 'the button stays disabled while unconfirmed');
    component.acknowledgeUnconfirmed();
    assert.equal(component.inquiryUnconfirmed, false);
    assert.equal(component.submitDisabled, false);
});

test('the default inquiry type matches the default select option', () => {
    assert.match(js, /inquiryType = 'Purchase Inquiry'/);
    assert.doesNotMatch(js, /inquiryType = 'Test Drive'/, 'no vehicle is selected by default, so Test Drive must not be the initial state');
});

test('Test Drive is labelled as a request, not a scheduled Test_Drive__c record', () => {
    assert.match(html, />Request a test drive</);
    assert.doesNotMatch(html, /Book a test drive/, 'a Lead inquiry must not promise a booked appointment');
    assert.match(js, /label: 'Test Drive request', value: 'Test Drive'/);
    assert.match(js, /This is a request, not a confirmed appointment/);
    assert.match(html, /\{inquirySuccessNote\}/);
    assert.doesNotMatch(inquiry, /new Test_Drive__c\(|insert new Test_Drive__c/);
});

test('the detail Test Drive action targets the selected vehicle and request type', async () => {
    const { component, calls } = inquiryScenario(async (args) => {
        assert.equal(args.requestType, 'Test Drive');
        assert.equal(args.vehicleId, 'a0Aaj0000000001');
        return 'NG-TD0001';
    });
    component.data = {
        models: [
            { id: 'm1', make: 'Cascadia', model: 'Cascadia', trim: 'LX', title: 'Cascadia LX', bodyStyle: 'Truck', drivetrain: '4WD', transmission: 'Automatic', fuelType: 'Diesel', imageName: 'cascadia_lx.webp' },
            { id: 'm2', make: 'Aurelia', model: 'Aurelia', trim: 'Sport', title: 'Aurelia Sport', bodyStyle: 'Coupe', drivetrain: 'AWD', transmission: 'Automatic', fuelType: 'EV', imageName: 'aurelia_sport.webp' }
        ],
        availableCount: 1,
        vehicles: [{ id: 'a0Aaj0000000001', available: true, title: '2024 Aurelia', stockNumber: 'S-1', price: null, odometer: null }]
    };
    component.startInquiry({ currentTarget: { dataset: { type: 'Test Drive', vehicleId: 'a0Aaj0000000001' } } });
    assert.equal(component.inquiryType, 'Test Drive');
    assert.equal(component.inquiryVehicleId, 'a0Aaj0000000001');
    assert.equal(component.submitLabel, 'Request a test drive');
    assert.equal(component.submitDisabled, false);
    await component.submitInquiry();
    assert.equal(calls.submit, 1);
    assert.equal(component.inquiryReference, 'NG-TD0001');
    assert.match(component.inquirySuccessNote, /not a confirmed appointment/);
    assert.doesNotMatch(component.inquirySuccessNote, /reserved for you/);
});

test('request type options derive selection from the single inquiryType field', () => {
    const { component } = inquiryScenario(async () => 'NG-OPT');
    component.data = {
        models: [
            { id: 'm1', make: 'Cascadia', model: 'Cascadia', trim: 'LX', title: 'Cascadia LX', bodyStyle: 'Truck', drivetrain: '4WD', transmission: 'Automatic', fuelType: 'Diesel', imageName: 'cascadia_lx.webp' },
            { id: 'm2', make: 'Aurelia', model: 'Aurelia', trim: 'Sport', title: 'Aurelia Sport', bodyStyle: 'Coupe', drivetrain: 'AWD', transmission: 'Automatic', fuelType: 'EV', imageName: 'aurelia_sport.webp' }
        ],
        availableCount: 1,
        vehicles: [{ id: 'a0Aaj0000000001', available: true, title: '2024 Aurelia', stockNumber: 'S-1', price: null, odometer: null }]
    };
    component.inquiryVehicleId = 'a0Aaj0000000001';
    component.inquiryType = 'Test Drive';
    let options = component.inquiryTypeOptions;
    assert.equal(options.find(option => option.value === 'Test Drive').selected, true);
    assert.equal(options.find(option => option.value === 'Purchase Inquiry').selected, false);
    component.inquiryType = 'Purchase Inquiry';
    options = component.inquiryTypeOptions;
    assert.equal(options.find(option => option.value === 'Test Drive').selected, false);
    assert.equal(options.find(option => option.value === 'Purchase Inquiry').selected, true);
});

test('the select binds selection from inquiryType rather than a competing value attribute', () => {
    assert.match(html, /<select data-field="inquiryType" onchange=\{handleInquiryInput\}>/);
    assert.match(html, /selected=\{option\.selected\}/);
    assert.doesNotMatch(html, /<select[^>]*value=\{inquiryType\}/, 'the select must not hold a second source of truth');
});

test('renderedCallback re-syncs the visible dropdown to inquiryType', () => {
    const { component } = inquiryScenario(async () => 'NG-SYNC');
    const select = { value: 'Purchase Inquiry' };
    component.template = { querySelector: (selector) => selector === '[data-field="inquiryType"]' ? select : null };
    component.inquiryType = 'Test Drive';
    component.renderedCallback();
    assert.equal(select.value, 'Test Drive');
    component.inquiryType = 'Purchase Inquiry';
    component.renderedCallback();
    assert.equal(select.value, 'Purchase Inquiry');
});

test('CTA, manual change and navigation keep type, dropdown and payload synchronized', async () => {
    const payloads = [];
    const { component } = inquiryScenario(async (args) => { payloads.push(args); return 'NG-SYNC2'; });
    component.data = {
        models: [
            { id: 'm1', make: 'Cascadia', model: 'Cascadia', trim: 'LX', title: 'Cascadia LX', bodyStyle: 'Truck', drivetrain: '4WD', transmission: 'Automatic', fuelType: 'Diesel', imageName: 'cascadia_lx.webp' },
            { id: 'm2', make: 'Aurelia', model: 'Aurelia', trim: 'Sport', title: 'Aurelia Sport', bodyStyle: 'Coupe', drivetrain: 'AWD', transmission: 'Automatic', fuelType: 'EV', imageName: 'aurelia_sport.webp' }
        ],
        availableCount: 1,
        vehicles: [{ id: 'a0Aaj0000000001', available: true, title: '2024 Aurelia', stockNumber: 'S-1', price: null, odometer: null }]
    };
    component.startInquiry({ currentTarget: { dataset: { type: 'Test Drive', vehicleId: 'a0Aaj0000000001' } } });
    assert.equal(component.inquiryType, 'Test Drive');
    assert.equal(component.inquiryTypeOptions.find(option => option.value === 'Test Drive').selected, true);
    assert.equal(component.submitLabel, 'Request a test drive');

    component.handleInquiryInput({ target: { dataset: { field: 'inquiryType' }, value: 'Purchase Inquiry' } });
    assert.equal(component.inquiryType, 'Purchase Inquiry');
    assert.equal(component.inquiryTypeOptions.find(option => option.value === 'Purchase Inquiry').selected, true);
    assert.equal(component.submitLabel, 'Send inquiry');

    component.startInquiry({ currentTarget: { dataset: { type: 'Test Drive', vehicleId: 'a0Aaj0000000001' } } });
    assert.equal(component.inquiryType, 'Test Drive');
    assert.equal(component.inquiryTypeOptions.find(option => option.value === 'Test Drive').selected, true);
    await component.submitInquiry();
    assert.equal(payloads.length, 1);
    assert.equal(payloads[0].requestType, 'Test Drive');
    assert.equal(payloads[0].vehicleId, 'a0Aaj0000000001');
});

test('a Test Drive CTA without a vehicle stays visible, selected and blocked', () => {
    const { component } = inquiryScenario(async () => 'NG-FALLBACK');
    component.startInquiry({ currentTarget: { dataset: { type: 'Test Drive' } } });
    assert.equal(component.inquiryVehicleId, null);
    assert.equal(component.inquiryType, 'Test Drive');
    assert.equal(component.inquiryTypeOptions.find(option => option.value === 'Test Drive').selected, true);
    assert.equal(component.submitLabel, 'Request a test drive');
    assert.equal(component.testDriveNeedsVehicle, true);
    assert.equal(component.submitDisabled, true);
});

test('a Test Drive request cannot submit without a resolved selected vehicle', async () => {
    const { component, calls } = inquiryScenario(async () => 'NG-NONE');
    component.data = {
        models: [
            { id: 'm1', make: 'Cascadia', model: 'Cascadia', trim: 'LX', title: 'Cascadia LX', bodyStyle: 'Truck', drivetrain: '4WD', transmission: 'Automatic', fuelType: 'Diesel', imageName: 'cascadia_lx.webp' },
            { id: 'm2', make: 'Aurelia', model: 'Aurelia', trim: 'Sport', title: 'Aurelia Sport', bodyStyle: 'Coupe', drivetrain: 'AWD', transmission: 'Automatic', fuelType: 'EV', imageName: 'aurelia_sport.webp' }
        ],
        availableCount: 1,
        vehicles: [{ id: 'a0Aaj0000000002', available: true, title: 'Other', stockNumber: 'S-2', price: null, odometer: null }]
    };
    component.inquiryType = 'Test Drive';
    component.inquiryVehicleId = undefined;
    assert.equal(component.testDriveNeedsVehicle, true);
    assert.equal(component.submitDisabled, true);
    await component.submitInquiry();
    assert.equal(calls.submit, 0);
    component.inquiryVehicleId = 'a0Aaj00000000XX';
    assert.equal(component.testDriveNeedsVehicle, true, 'a stale/delisted id must not pass client validation');
    assert.match(html, /Choose a listed vehicle, then select/);
});

test('success and delayed states use valid LWC conditional directives', () => {
    assert.match(html, /<template lwc:if=\{inquiryUnconfirmed\}>/);
    assert.match(html, /<template lwc:elseif=\{inquiryReference\}>/);
    assert.doesNotMatch(html, /lwc:elif/, 'LWC uses lwc:elseif, not lwc:elif');
});

// Behavioural contract for stable vehicle links. Mocked Apex/window only; no browser or org call.
function linkScenario(initialHash = '') {
    const source = read('lwc/ngBuyerSite/ngBuyerSite.js')
        .replace(/^import .*;\r?\n/gm, '')
        .replace(/^\s*@api\s+/gm, '')
        .replace('export default class', 'globalThis.Component = class');
    const replaced = [];
    const listeners = {};
    const assigned = [];
    const location = {
        pathname: '/owners/s/buyer', search: '', hash: initialHash,
        assign: url => assigned.push(url)
    };
    const context = {
        LightningElement: class {}, Intl,
        document: { documentElement: { clientWidth: 1024 } },
        window: {
            location,
            addEventListener: (name, handler) => { listeners[name] = handler; },
            removeEventListener: (name) => { delete listeners[name]; },
            history: { replaceState: (...args) => replaced.push(args) }
        },
        LOCALE: 'en-CA', CURRENCY_CODE: 'CAD', NG_VEHICLE_IMAGES: '/resource/NG_VehicleImages',
        URLSearchParams,
        setTimeout, clearTimeout,
        getShowcase: async () => ({ models: [], vehicles: [], availableCount: 0 }),
        submitBuyerInquiry: async () => 'NG-LINK'
    };
    runInNewContext(source, context);
    const component = new context.Component();
    component.boundHashChange = () => component.applyDeepLink();
    component.data = {
        models: [
            { id: 'm1', make: 'Cascadia', model: 'Cascadia', trim: 'LX', title: 'Cascadia LX', bodyStyle: 'Truck', drivetrain: '4WD', transmission: 'Automatic', fuelType: 'Diesel', imageName: 'cascadia_lx.webp' },
            { id: 'm2', make: 'Aurelia', model: 'Aurelia', trim: 'Sport', title: 'Aurelia Sport', bodyStyle: 'Coupe', drivetrain: 'AWD', transmission: 'Automatic', fuelType: 'EV', imageName: 'aurelia_sport.webp' }
        ],
        availableCount: 1,
        vehicles: [
            { id: 'a0Aaj0000000001', available: true, title: '2024 Aurelia', stockNumber: 'S-1', price: null, odometer: null },
            { id: 'a0Aaj0000000002', available: true, title: '2025 Cascadia', stockNumber: 'S-2', price: null, odometer: null }
        ]
    };
    return { component, location, replaced, listeners, assigned };
}

test('a shared vehicle link reopens the same record, not a list position', () => {
    const { component, location, listeners } = linkScenario('#vehicle-a0Aaj0000000002');
    component.page = 'vehicle';
    assert.equal(typeof component.boundHashChange, 'function');
    assert.deepEqual(Object.keys(listeners), [], 'no listener is installed without a connected component');
    component.applyDeepLink();
    assert.equal(component.selectedVehicleId, 'a0Aaj0000000002');
    assert.equal(component.focusTarget, 'detail');

    // A different order in the DTO must not change the resolved vehicle.
    component.data.vehicles.reverse();
    component.selectedVehicleId = undefined;
    component.applyDeepLink();
    assert.equal(component.selectedVehicleId, 'a0Aaj0000000002');

    component.viewVehicle({ currentTarget: { dataset: { vehicleId: 'a0Aaj0000000001' } } });
    assert.equal(location.hash, '#vehicle-a0Aaj0000000001');
    assert.equal(component.selectedVehicleId, 'a0Aaj0000000001');
});

test('unknown links, other anchors and close keep the hash and selection consistent', () => {
    const { component, location, replaced } = linkScenario('');
    component.page = 'vehicle';
    component.applyDeepLink();
    assert.equal(component.selectedVehicleId, undefined, 'no hash means no detail');

    location.hash = '#vehicle-a0Aaj00000000XX';
    component.applyDeepLink();
    assert.equal(component.selectedVehicleId, undefined, 'a stale or foreign id is ignored');

    location.hash = '#vehicle-a0Aaj0000000001';
    component.applyDeepLink();
    assert.equal(component.selectedVehicleId, 'a0Aaj0000000001');

    location.hash = '#vehicle-a0Aaj00000%';
    assert.doesNotThrow(() => component.applyDeepLink());
    assert.equal(component.selectedVehicleId, undefined, 'a malformed fragment cannot throw or open a detail');

    location.hash = '#inventory';
    component.applyDeepLink();
    assert.equal(component.selectedVehicleId, undefined, 'section anchors leave the detail view');

    location.hash = '#vehicle-a0Aaj0000000002';
    component.applyDeepLink();
    component.closeDetail();
    assert.equal(component.selectedVehicleId, undefined);
    assert.equal(replaced.length, 1);
    assert.equal(replaced[0][2], '/owners/s/buyer', 'closing details removes the fragment without adding history');
});

test('the viewport measurement never blocks rendering when the DOM is unavailable', () => {
    const source = read('lwc/ngBuyerSite/ngBuyerSite.js')
        .replace(/^import .*;\r?\n/gm, '')
        .replace(/^\s*@api\s+/gm, '')
        .replace('export default class', 'globalThis.Component = class');
    const context = { LightningElement: class {}, Intl, LOCALE: 'en-CA', CURRENCY_CODE: 'CAD',
        NG_VEHICLE_IMAGES: '/resource', window: {}, setTimeout, clearTimeout,
        getShowcase: async () => ({}), submitBuyerInquiry: async () => 'NG' };
    runInNewContext(source, context);
    const component = new context.Component();
    assert.doesNotThrow(() => component.syncViewport());
    assert.doesNotThrow(() => component.applyDeepLink());
});


// Behavioural contracts for Vehicle Studio 2.0. Mocked Apex only; no browser or org call.

test('a studio fragment opens the Studio without opening a vehicle', () => {
    const { component, location } = linkScenario('');
    component.page = 'studio';
    location.hash = '#studio-cascadia';
    component.applyDeepLink();
    assert.equal(component.selectedVehicleId, undefined);
    assert.equal(component.focusTarget, 'studio');
    component.selectedVehicleId = 'a0Aaj0000000001';
    location.hash = '#studio-unknown';
    component.applyDeepLink();
    assert.equal(component.selectedVehicleId, undefined, 'any studio fragment closes the vehicle detail');
});


test('the component closes the small Experience Cloud top gap that sits above the sticky header', () => {
    assert.match(css, /margin-top: calc\(-1 \* var\(--ng-top-gap, 0px\)\)/);
    const { component } = linkScenario('');
    const sets = {};
    const host = { style: { setProperty: (name, value) => { sets[name] = value; } }, getBoundingClientRect: () => ({ top: 12 }) };
    component.template = { host };
    const previousWindow = globalThis.window;
    globalThis.window = { scrollY: 0 };
    try {
        component.syncTopGap();
        assert.equal(sets['--ng-top-gap'], '12px');
        assert.equal(component.topGapApplied, true);
    } finally { globalThis.window = previousWindow; }
});


/* ------------------------------------------------------------ Buyer 3.0 pages */

const PAGES = ['home', 'inventory', 'vehicle', 'studio', 'about', 'contact'];

test('the component renders six distinct Buyer pages from one shared shell', () => {
    for (const page of PAGES) {
        const { component } = linkScenario('');
        component.page = page;
        const states = PAGES.map(name => component['is' + name[0].toUpperCase() + name.slice(1)]);
        assert.equal(states.filter(Boolean).length, 1, `${page} selects exactly one page`);
        assert.equal(component['is' + page[0].toUpperCase() + page.slice(1)], true, page);
        assert.ok(component.pageHeading.length > 3, `${page} has a heading`);
        assert.ok(component.pageLede.length > 10, `${page} has a lede`);
    }
    // The template gates every section on a page mode, so nothing renders twice.
    for (const gate of ['showHome', 'showInventory', 'showVehicle', 'showStudio', 'showAbout', 'inquiryPanelVisible']) {
        assert.match(html, new RegExp(`lwc:if=\\{${gate}\\}`), gate);
    }
    assert.equal((html.match(/<h1\b/g) || []).length, 1, 'one h1 per rendered page');
});

test('each page has a distinct URL under the site prefix', () => {
    const { component } = linkScenario('');
    component.page = 'home';
    const urls = ['homeUrl', 'inventoryUrl', 'studioUrl', 'aboutUrl', 'contactUrl'].map(key => component[key]);
    assert.equal(new Set(urls).size, urls.length, 'no page shares a URL');
    for (const url of urls) assert.match(url, /^\/owners\/s\/buyer/);
    assert.match(component.vehicleUrlFor('a0Aaj0000000001'), /^\/owners\/s\/buyer-vehicle\?c__vehicle=a0Aaj0000000001$/);
    assert.equal(component.portalUrl, '/owners/s/', 'the Owner Portal keeps the site root');
});

test('navigation marks the current page for assistive tech', () => {
    const { component } = linkScenario('');
    component.page = 'studio';
    assert.equal(component.studioCurrent, 'page');
    for (const key of ['homeCurrent', 'inventoryCurrent', 'aboutCurrent', 'contactCurrent']) {
        assert.equal(component[key], null, key);
    }
    assert.match(html, /aria-current=\{studioCurrent\}>3D Studio<\/a>/);
});

test('legacy fragments resolve to the page that owns them', () => {
    // On the vehicle page the fragment selects the record in place.
    const vehicle = linkScenario('#vehicle-a0Aaj0000000002');
    vehicle.component.page = 'vehicle';
    vehicle.component.applyDeepLink();
    assert.equal(vehicle.component.selectedVehicleId, 'a0Aaj0000000002');

    // From another page the fragment must navigate, not overwrite the hosted page.
    const other = linkScenario('#vehicle-a0Aaj0000000002');
    other.component.page = 'inventory';
    other.component.applyDeepLink();
    assert.equal(other.component.page, 'inventory', 'the configured page is not hijacked');
    assert.equal(other.assigned.length, 1);
    assert.match(other.assigned[0], /buyer-vehicle\?c__vehicle=a0Aaj0000000002$/);

    const studio = linkScenario('#studio-cascadia');
    studio.component.page = 'studio';
    studio.component.selectedVehicleId = 'a0Aaj0000000002';
    studio.component.applyDeepLink();
    assert.equal(studio.component.selectedVehicleId, undefined, 'studio link closes the detail');
    assert.equal(studio.component.focusTarget, 'studio');
});

test('the vehicle page reads c__vehicle and rejects unknown ids', () => {
    const { component, location } = linkScenario('');
    component.page = 'vehicle';
    component.data = {
        models: [], availableCount: 1,
        vehicles: [{ id: 'a0Aaj0000000002', available: true, title: '2025 Cascadia', stockNumber: 'S-2', price: null, odometer: null }]
    };
    location.search = '?c__vehicle=a0Aaj0000000002';
    component.applyVehicleIntent();
    assert.equal(component.selectedVehicleId, 'a0Aaj0000000002');

    location.search = '?c__vehicle=does-not-exist';
    component.selectedVehicleId = undefined;
    component.applyVehicleIntent();
    assert.equal(component.selectedVehicleId, undefined, 'unknown ids never select a record');
});

test('in-page anchors never clear the vehicle detail', () => {
    const { component, location } = linkScenario('#vehicle-a0Aaj0000000002');
    component.page = 'vehicle';
    component.applyDeepLink();
    assert.equal(component.selectedVehicleId, 'a0Aaj0000000002');
    for (const anchor of ['#buyer-main', '#top']) {
        location.hash = anchor;
        component.applyDeepLink();
        assert.equal(component.selectedVehicleId, 'a0Aaj0000000002', anchor);
    }
});

test('inquiry actions open the form in place so a draft is never lost', () => {
    const vehicle = linkScenario('');
    vehicle.component.page = 'vehicle';
    vehicle.component.selectedVehicleId = 'a0Aaj0000000002';
    assert.equal(vehicle.component.inquiryPanelVisible, false, 'closed until requested');
    vehicle.component.startInquiry({ currentTarget: { dataset: { type: 'Test Drive', vehicleId: 'a0Aaj0000000002' } } });
    assert.equal(vehicle.component.inquiryPanelVisible, true);
    assert.equal(vehicle.component.inquiryOpen, true);
    assert.equal(vehicle.component.inquiryType, 'Test Drive');
    assert.equal(vehicle.assigned.length, 0, 'no navigation, so typed text survives');

    // The Studio no longer starts an inquiry from a catalogue; its CTA is the Priority List.
    const studio = linkScenario('');
    studio.component.page = 'studio';
    assert.match(html, /src|href=\{priorityUrl\}|onclick=\{startPriorityInterest\}/);
});

test('the priority list reuses the existing inquiry and never claims a reservation', () => {
    const { component, location } = linkScenario('');
    location.search = '?c__priority=apex';
    component.applyPriorityIntent();
    assert.equal(component.page, 'all', 'the legacy layout keeps every section');
    assert.equal(component.inquiryType, 'Purchase Inquiry', 'no Test Drive request is created');
    assert.equal(component.inquiryVehicleId, null, 'no vehicle is attached');
    assert.match(component.inquiryConfigSummary, /Apex Concept · Priority List/);
    assert.match(component.inquiryMessage, /Priority list — Apex Concept/);
    assert.match(component.inquiryMessage, /not a reservation, confirmed allocation, price or purchase commitment/);
    assert.doesNotMatch(component.inquiryMessage, /reserve my|guarantee|deposit/i);

    // A normal visit must never inherit the priority prefill.
    const plain = linkScenario('');
    plain.component.applyPriorityIntent();
    assert.equal(plain.component.inquiryMessage, '', 'no intent, no prefill');
    assert.equal(plain.component.page, 'all');
});

test('the priority CTA never invents a paint finish', () => {
    const { component } = linkScenario('');
    component.page = 'studio';
    component.studioColour = 'Green';
    assert.match(component.priorityUrl, /c__priority=apex/);
    assert.doesNotMatch(component.priorityUrl, /c__finish/, 'the paint finish lives in the 3D component');
    assert.equal(component.inquiryType, 'Purchase Inquiry');
    assert.match(html, /Join the Priority List/);
    assert.match(html, /not a reservation, confirmed allocation, price or purchase commitment/);
});

test('about and contact pages expose the portal and inquiry paths', () => {
    assert.match(html, /href=\{portalUrl\}>Open the Owner Portal<\/a>/);
    assert.match(html, /href=\{contactUrl\}>Contact Northgate<\/a>/);
    assert.match(html, /href=\{inventoryUrl\}>Back to inventory<\/a>/);
});

test('customer copy uses Canadian English and avoids internal jargon', () => {
    const customer = html + js;
    assert.match(customer, /Colour/);
    assert.match(customer, /Centre|centre|Colour/);
    assert.doesNotMatch(html, /\brooftop\b|\bDTO\b|Lead routing|CP2/i, 'no internal terminology in page copy');
    assert.doesNotMatch(html, /color\b/, 'CSS properties only live in the stylesheet');
});

test('the page property is exposed to Experience Builder with all six modes', () => {
    const meta = read('lwc/ngBuyerSite/ngBuyerSite.js-meta.xml');
    assert.match(meta, /<property name="page" type="String" label="Buyer page" default="all"/);
    for (const page of ['all', ...PAGES]) assert.ok(meta.includes(page), page);
    assert.match(meta, /lightningCommunity__Default/);
});


test('the deployed default preserves the published single-page Buyer', () => {
    const { component } = linkScenario('');
    assert.equal(component.page, 'all', 'default is the pre-3.0 layout');
    for (const gate of ['showHome', 'showInventory', 'showVehicle', 'showStudio', 'showAbout']) {
        assert.equal(component[gate], true, gate);
    }
    assert.equal(component.inquiryPanelVisible, true);
    // In-page anchors keep the accepted navigation until dedicated pages exist.
    assert.equal(component.inventoryUrl, '#inventory');
    assert.equal(component.studioUrl, '#studio');
    assert.equal(component.aboutUrl, '#why');
    assert.equal(component.contactUrl, '#inquiry');
    assert.equal(component.homeUrl, '#top');
    // Unknown page values fall back to the safe legacy layout rather than an empty shell.
    component.page = 'not-a-page';
    assert.equal(component.isAll, true);
    assert.equal(component.showInventory, true);
});


test('a draft, pending submission or unconfirmed outcome blocks silent navigation', () => {
    const { component } = linkScenario('');
    const event = { preventDefault() { this.prevented = true; }, returnValue: '' };
    assert.equal(component.hasUnsavedInquiry, false, 'an empty form does not nag');
    component.inquiryMessage = 'Please call me.';
    assert.equal(component.hasUnsavedInquiry, true);
    component.boundBeforeUnload(event);
    assert.equal(event.prevented, true);
    assert.match(String(event.returnValue), /not been sent/);

    component.inquiryMessage = '';
    component.submitting = true;
    assert.equal(component.hasUnsavedInquiry, true, 'in-flight submission is protected');

    component.submitting = false;
    component.inquiryUnconfirmed = true;
    assert.equal(component.hasUnsavedInquiry, true, 'unconfirmed outcome is protected');

    component.inquiryUnconfirmed = false;
    component.inquiryReference = 'NG-123';
    assert.equal(component.hasUnsavedInquiry, false, 'a completed request does not block leaving');
});


test('legacy mode keeps every CTA working without leaving the page', () => {
    const { component, assigned } = linkScenario('#vehicle-a0Aaj0000000002');
    component.applyDeepLink();
    assert.equal(component.selectedVehicleId, 'a0Aaj0000000002', 'detail opens in place');
    assert.equal(assigned.length, 0, 'no navigation to a page that does not exist yet');

    // Priority CTA applies in place in legacy mode and does not collapse the layout.
    component.page = 'all';
    const event = { preventDefault() { this.prevented = true; } };
    component.startPriorityInterest(event);
    assert.equal(event.prevented, true);
    assert.equal(component.page, 'all');
    assert.equal(component.inquiryOpen, true);
    assert.match(component.inquiryConfigSummary, /Apex Concept/);
    assert.equal(component.priorityUrl, '#inquiry');
});

test('a crafted configuration string cannot smuggle long or newline text', () => {
    const { component, location } = linkScenario('');
    component.page = 'contact';
    const payload = 'X'.repeat(500) + '\n<script>alert(1)</script>';
    location.search = '?c__config=' + encodeURIComponent(payload);
    component.applyInquiryIntent();
    assert.ok(component.inquiryConfigSummary.length <= 120, 'clamped');
    assert.doesNotMatch(component.inquiryConfigSummary, /[\r\n<>]/, 'stripped');
    assert.doesNotMatch(component.inquiryMessage, /<script>/);
});

test('the beforeunload guard is registered while connected', () => {
    const { component, listeners } = linkScenario('');
    component.syncViewport = () => {};
    component.applyPriorityIntent = () => {};
    component.loadShowcase = async () => {};
    component.connectedCallback();
    assert.equal(typeof listeners.beforeunload, 'function', 'guard registered');
    component.disconnectedCallback();
    assert.equal(listeners.beforeunload, undefined, 'guard removed on teardown');
});


/* -------------------------------------------------- configurator removal (3.0) */

test('the Studio hosts only the Apex Concept configurator', () => {
    assert.doesNotMatch(html, /trim-card|swatch|family-tab|studio-stage|match-grid|config-grid|studio-specs/,
        'the obsolete catalogue UI is gone');
    // One prioritisation action only: the Buyer CTA owns it, so the child renders no duplicate CTA.
    assert.match(html, /<c-ng-apex-concept-3d onfinishchange=\{handleApexFinish\} hide-inquiry><\/c-ng-apex-concept-3d>/);
    assert.equal((html.match(/Join the Priority List/g) || []).length, 1);
    assert.match(html, /id="studio"/);
    assert.match(html, /explore the car in 3D/);
    assert.match(js, /openStudio\(event\)/);
    assert.doesNotMatch(js, /selectStudio(Trim|Colour|Family)|studioRequest\(|startStudioConfiguration|startStudioTestDrive/);
});

test('the Studio keeps the Priority List and a route to listed inventory', () => {
    assert.match(html, /Join the Priority List/);
    assert.match(html, /href=\{priorityUrl\} onclick=\{startPriorityInterest\}/);
    assert.match(html, /Browse listed inventory/);
    assert.match(html, /not a reservation, confirmed allocation, price or purchase commitment/);
});

test('inventory, details, filters and inquiry survive the removal', () => {
    for (const keep of ['vehicle-card', 'vehicles match', 'vehicle-detail', 'card-cta',
                        'inventory-filters', 'inquiry-form', 'inquiryReference', 'testDriveDisabled']) {
        assert.ok(html.includes(keep), keep);
    }
    assert.match(js, /get filteredVehicles\(\)/);
    assert.match(js, /get detailSpecs\(\)/);
    assert.match(js, /async submitInquiry\(\)/);
});

test('home family cards group by model family and browse that family inventory', () => {
    assert.match(html, /class="family-card" data-family=\{family\.key\} onclick=\{openFamily\}/);
    assert.doesNotMatch(html, /Explore Apex Concept/);

    const { component, assigned } = linkScenario('');
    component.data = {
        models: [
            { id: 'm1', make: 'Northgate', model: 'Aurelia', title: 'Aurelia Sport', imageName: 'a.webp' },
            { id: 'm2', make: 'Northgate', model: 'Aurelia', title: 'Aurelia LX', imageName: 'a.webp' },
            { id: 'm3', make: 'Northgate', model: 'Cascadia', title: 'Cascadia LX', imageName: 'c.webp' }
        ],
        availableCount: 2,
        vehicles: [
            { id: 'v1', modelId: 'm1', price: 100, odometer: null, available: true },
            { id: 'v2', modelId: 'm3', price: 200, odometer: null, available: true }
        ]
    };
    const cards = component.familyCards;
    assert.equal(cards.length, 2, 'one card per family, not one per make');
    assert.deepEqual([...cards.map(c => c.title)].sort(), ['Aurelia', 'Cascadia']);
    assert.equal(cards.find(c => c.key === 'aurelia').count, 1);

    // Legacy single-page mode filters in place.
    const scrolls = [];
    component.template = { querySelector: selector => {
        if (selector === '[data-inventory]') return { scrollIntoView: options => scrolls.push(options) };
        if (selector === '[data-inventory-heading]') return { focus() {} };
        return null;
    } };
    component.openFamily({ currentTarget: { dataset: { family: 'aurelia' } } });
    assert.equal(component.filterFamily, 'aurelia');
    assert.equal(component.filteredVehicles.length, 1);
    assert.equal(component.filteredVehicles[0].id, 'v1');
    assert.equal(scrolls.length, 1);
    assert.equal(assigned.length, 0);

    // Dedicated Home navigates to Inventory with the family intent.
    component.page = 'home';
    component.openFamily({ currentTarget: { dataset: { family: 'cascadia' } } });
    assert.equal(assigned[0], component.inventoryUrl + '?c__family=cascadia');
});

test('a family query applies only to a known family and an unknown one is ignored', () => {
    const { component, location } = linkScenario('');
    component.data = {
        models: [{ id: 'm1', make: 'Northgate', model: 'Aurelia', title: 'Aurelia LX', imageName: 'a.webp' }],
        vehicles: [], availableCount: 0
    };
    location.search = '?c__family=aurelia';
    component.applyFamilyIntent();
    assert.equal(component.filterFamily, 'aurelia');
    assert.equal(component.inventoryPage, 1);

    component.filterFamily = '';
    location.search = '?c__family=<script>';
    component.applyFamilyIntent();
    assert.equal(component.filterFamily, '', 'unknown family is ignored');
});
test('dedicated Home Studio links navigate to studioUrl rather than an absent local Studio', () => {
    const { component, assigned } = linkScenario('');
    component.page = 'home';
    assert.equal(component.showStudio, false);
    component.template = { querySelector() { assert.fail('dedicated mode must not query a local Studio'); } };
    const event = { preventDefault() { this.prevented = true; } };
    component.openStudio(event);
    assert.equal(event.prevented, true);
    assert.deepEqual(assigned, ['/owners/s/buyer-studio']);
    assert.equal(assigned[0], component.studioUrl);
    assert.equal(component.page, 'home');
    assert.equal(component.focusTarget, undefined);
});

test('all-mode Studio actions scroll and focus the local Studio without navigation', () => {
    const { component, assigned } = linkScenario('');
    const scrolls = [];
    let focused = 0;
    component.template = { querySelector: selector => {
        if (selector === '[data-studio]') return { scrollIntoView: options => scrolls.push(options) };
        if (selector === '[data-studio-heading]') return { focus: () => focused++ };
        return null;
    } };
    component.selectedVehicleId = 'a0Aaj0000000002';
    assert.equal(component.showStudio, true);
    component.openStudio();
    assert.equal(assigned.length, 0);
    assert.equal(scrolls.length, 1);
    assert.equal(scrolls[0].block, 'start');
    assert.equal(scrolls[0].behavior, 'smooth');
    assert.equal(focused, 1);
    assert.equal(component.selectedVehicleId, undefined);
    assert.equal(component.focusTarget, 'studio');
});

test('opening Studio preserves inquiry drafts and pending/unconfirmed navigation guards in both modes', () => {
    for (const page of ['home', 'all']) {
        for (const state of ['draft', 'submitting', 'inquiryUnconfirmed']) {
            const { component } = linkScenario('');
            component.page = page;
            component.inquiryOpen = true;
            component.inquiryVehicleId = 'a0Aaj0000000002';
            if (state === 'draft') component.inquiryMessage = 'Keep my question.';
            else component[state] = true;
            const before = JSON.stringify(component);
            component.openStudio();
            const after = JSON.stringify(component, (key, value) => key === 'focusTarget' ? undefined : value);
            assert.equal(after, before, `${page}/${state}: only local focus may change`);
            assert.equal(component.hasUnsavedInquiry, true);
            const event = { preventDefault() { this.prevented = true; } };
            component.boundBeforeUnload(event);
            assert.equal(event.prevented, true);
            assert.match(event.returnValue, /not been sent/);
            if (state !== 'draft') assert.equal(component.submitDisabled, true);
        }
    }
});

test('family and Studio copy do not promise a selected model or matching concept inventory', () => {
    assert.match(html, /Browse by model family\. The Apex Concept lives in the 3D Studio\./);
    assert.match(html, /class="family-cta">View inventory/);
    assert.doesNotMatch(html, /Choose a model to explore|Explore model|Browse matching inventory|Explore Apex Concept/);
});

test('query vehicle selection survives the initial empty-hash deep link pass', () => {
    const { component, location } = linkScenario('');
    component.page = 'vehicle';
    location.search = '?c__vehicle=a0Aaj0000000002';
    component.applyVehicleIntent();
    component.applyDeepLink();
    assert.equal(component.selectedVehicleId, 'a0Aaj0000000002');
});

test('malformed and unknown vehicle fragments never navigate from another page', () => {
    for (const hash of ['#vehicle-%', '#vehicle-unknown']) {
        const { component, assigned } = linkScenario(hash);
        component.page = 'home';
        assert.doesNotThrow(() => component.applyDeepLink());
        assert.equal(assigned.length, 0);
    }
});

test('priority handoff carries only a reported allowlisted finish and preserves Builder mode', () => {
    for (const finish of ['carmine', 'pearl', 'graphite']) {
        const { component, location, assigned } = linkScenario('');
        component.page = 'studio';
        component.handleApexFinish({ detail: { finish } });
        assert.ok(component.priorityUrl.endsWith('&c__finish=' + finish));
        component.startPriorityInterest({ preventDefault() {} });
        assert.equal(component.page, 'studio');
        assert.equal(component.inquiryPanelVisible, true);
        assert.equal(component.inquiryVehicleId, null);
        assert.match(component.inquiryMessage, /Preview finish: .*illustrative and unpriced/);
        assert.equal(assigned.length, 0);
        const contact = linkScenario('');
        contact.component.page = 'contact';
        contact.location.search = '?c__priority=apex&c__finish=' + finish + '&c__type=Test+Drive&c__vehicle=a0Aaj0000000002';
        contact.component.applyPriorityIntent();
        contact.component.applyInquiryIntent();
        assert.equal(contact.component.inquiryMessage, component.inquiryMessage);
        assert.equal(contact.component.inquiryType, 'Purchase Inquiry');
        assert.equal(contact.component.inquiryVehicleId, null);
        location.search = '?c__priority=apex';
        component.page = 'about';
        component.applyPriorityIntent();
        assert.equal(component.page, 'about', 'query cannot hijack Builder configuration');
    }
    for (const finish of ['Green', 'toString', '__proto__', '<script>']) {
        const { component, location } = linkScenario('');
        component.handleApexFinish({ detail: { finish } });
        assert.equal(component.apexFinish, '');
        location.search = '?c__priority=apex&c__finish=' + encodeURIComponent(finish);
        component.applyPriorityIntent();
        assert.doesNotMatch(component.inquiryMessage, /Preview finish:/);
    }
});

test('priority CTA preserves typed drafts, pending payloads and unconfirmed outcomes', () => {
    for (const state of ['draft', 'submitting', 'inquiryUnconfirmed']) {
        const { component } = linkScenario('');
        component.page = 'studio';
        component.inquiryType = 'Test Drive';
        component.inquiryVehicleId = 'a0Aaj0000000002';
        component.inquiryMessage = 'Keep my question';
        if (state !== 'draft') component[state] = true;
        component.startPriorityInterest({ preventDefault() {} });
        assert.equal(component.inquiryMessage, 'Keep my question');
        assert.equal(component.inquiryVehicleId, 'a0Aaj0000000002');
        assert.equal(component.inquiryType, 'Test Drive');
        assert.equal(component.hasUnsavedInquiry, true);
        if (state !== 'draft') assert.equal(component[state], true);
    }
});

test('inventory pagination is bounded and filters reset to the first page', () => {
    const { component } = linkScenario('');
    component.data.vehicles = Array.from({ length: 25 }, (_, n) => ({ id: String(n), price: n, odometer: null }));
    assert.equal(component.visibleVehicles.length, 12);
    assert.equal(component.inventoryPageCount, 3);
    assert.equal(component.firstInventoryPage, true);
    component.nextInventoryPage();
    assert.equal(component.visibleVehicles[0].id, '12');
    component.nextInventoryPage();
    component.nextInventoryPage();
    assert.equal(component.inventoryPage, 3);
    assert.equal(component.visibleVehicles.length, 1);
    component.handleFilter({ target: { dataset: { filter: 'maxPrice' }, value: '5' } });
    assert.equal(component.inventoryPage, 1);
    assert.equal(component.visibleVehicles.length, 6);
    component.clearFilters();
    assert.equal(component.filteredVehicles.length, 25);
    component.previousInventoryPage();
    assert.equal(component.inventoryPage, 1);
});

test('inquiry focus reaches terminal states and modified clicks keep native navigation', () => {
    // The received/unconfirmed regions must be focusable, otherwise keyboard focus stays
    // on the Studio call to action after an in-place priority action.
    assert.match(html, /class="state" role="alert" tabindex="-1" data-inquiry-focus/);
    assert.match(html, /class="success" role="status" tabindex="-1" data-inquiry-focus/);
    assert.match(js, /querySelector\('\[data-inquiry-name\]'\) \|\| this\.template\.querySelector\('\[data-inquiry-focus\]'\)/);

    const { component } = linkScenario('');
    component.page = 'studio';
    component.inquiryOpen = true;
    component.inquiryUnconfirmed = true;
    let terminalFocused = false;
    component.template = {
        activeElement: null,
        querySelector: selector => selector === '[data-inquiry-focus]'
            ? { focus: () => { terminalFocused = true; } }
            : null
    };
    component.focusTarget = 'inquiry';
    component.renderedCallback();
    assert.equal(terminalFocused, true, 'the terminal region receives focus');
    assert.equal(component.focusTarget, undefined);

    // Modified or middle clicks keep the browser's own new-tab behaviour.
    const modified = { metaKey: true, preventDefault() { this.prevented = true; } };
    component.startPriorityInterest(modified);
    assert.equal(modified.prevented, undefined);
    const middle = { button: 1, preventDefault() { this.prevented = true; } };
    component.startPriorityInterest(middle);
    assert.equal(middle.prevented, undefined);
    const plain = { button: 0, preventDefault() { this.prevented = true; } };
    component.startPriorityInterest(plain);
    assert.equal(plain.prevented, true);

    const apex = read('lwc/ngApexConcept3d/ngApexConcept3d.js');
    assert.match(apex, /event\.metaKey \|\| event\.ctrlKey \|\| event\.shiftKey \|\| event\.altKey/);
});

test('actual Apex component emits finish changes and retains standalone inquiry configuration', () => {
    const source = read('lwc/ngApexConcept3d/ngApexConcept3d.js')
        .replace(/^import .*;\r?\n/gm, '').replace(/^\s*@api\s+/gm, '')
        .replace('export default class', 'globalThis.Component = class');
    const events = [];
    const context = {
        LightningElement: class { dispatchEvent(event) { events.push(event); return true; } },
        CustomEvent: class { constructor(type, options) { this.type = type; Object.assign(this, options); } },
        VIEWER_RESOURCE: '/viewer', MODEL_RESOURCE: '/model', POSTER_RESOURCE: '/poster',
        window: { location: { pathname: '/owners/s/buyer-studio' } }
    };
    runInNewContext(source, context);
    const component = new context.Component();
    component.connectedCallback();
    assert.equal(events[0].detail.finish, 'carmine');
    component.handleFinish({ currentTarget: { dataset: { finish: 'pearl' } } });
    assert.equal(events[1].detail.finish, 'pearl');
    component.inquiryUrl = '/explicit-builder-destination';
    assert.equal(component.effectiveInquiryUrl, '/explicit-builder-destination');
    const click = { preventDefault() { this.prevented = true; } };
    component.handleInquiry(click);
    assert.equal(click.prevented, undefined, 'standalone follows its configured link');
    component.dispatchEvent = () => false;
    component.handleInquiry(click);
    assert.equal(click.prevented, true, 'host can open in place');
});

test('native filter controls follow programmatic state changes', () => {
    // A family card or Clear filters changes state without interacting with the <select>; a native
    // select keeps its old selection unless the component re-asserts it after render.
    const { component } = linkScenario('');
    component.filterFamily = 'aurelia';
    component.filterCondition = 'New';
    const values = {};
    component.template = {
        querySelector: selector => {
            const match = /data-(?:filter|field)="([A-Za-z]+)"/.exec(selector);
            if (!match) return null;
            const key = match[1];
            return { get value() { return values[key] === undefined ? '' : values[key]; }, set value(value) { values[key] = value; } };
        }
    };
    component.renderedCallback();
    assert.equal(values.filterFamily, 'aurelia');
    assert.equal(values.filterCondition, 'New');
    component.clearFilters();
    component.renderedCallback();
    assert.equal(values.filterFamily, '');
    assert.equal(values.filterCondition, '');
});

test('model options are scoped to the selected family', () => {
    // D1: the model dropdown used to offer every model regardless of family, so family+model
    // could combine into a guaranteed-empty result (family Aurelia + model Cascadia = 0).
    const { component } = linkScenario('');
    component.data = {
        models: [
            { id: 'm1', model: 'Aurelia', title: 'Aurelia Sport', imageName: 'a.webp' },
            { id: 'm2', model: 'Aurelia', title: 'Aurelia EX', imageName: 'a.webp' },
            { id: 'm3', model: 'Cascadia', title: 'Cascadia LX', imageName: 'c.webp' }
        ],
        vehicles: [], availableCount: 0
    };
    assert.deepEqual([...component.modelOptions.map(o => o.label)], ['All models', 'Aurelia Sport', 'Aurelia EX', 'Cascadia LX']);
    component.setFamily('aurelia');
    assert.deepEqual([...component.modelOptions.map(o => o.label)], ['All models', 'Aurelia Sport', 'Aurelia EX']);
    assert.ok(!component.modelOptions.some(o => o.value === 'm3'), 'another family model is not offered');
    component.setFamily('');
    assert.equal(component.modelOptions.length, 4, 'clearing the family restores every model');
});

test('a family change drops an incompatible model selection', () => {
    const { component } = linkScenario('');
    component.data = {
        models: [
            { id: 'm1', model: 'Aurelia', title: 'Aurelia Sport', imageName: 'a.webp' },
            { id: 'm3', model: 'Cascadia', title: 'Cascadia LX', imageName: 'c.webp' }
        ],
        vehicles: [
            { id: 'v1', modelId: 'm1', available: true, price: 100, odometer: null },
            { id: 'v2', modelId: 'm3', available: true, price: 200, odometer: null }
        ],
        availableCount: 2
    };
    component.filterModel = 'm3';
    component.inventoryPage = 3;
    component.setFamily('aurelia');
    assert.equal(component.filterModel, '', 'the incompatible trim is cleared');
    assert.equal(component.filterFamily, 'aurelia');
    assert.equal(component.inventoryPage, 1, 'pagination returns to the first page');
    assert.deepEqual(component.filteredVehicles.map(v => v.id), ['v1'], 'no dead-end empty result');
});

test('a compatible model and independent filters survive a family change', () => {
    const { component } = linkScenario('');
    component.data = {
        models: [
            { id: 'm1', model: 'Aurelia', title: 'Aurelia Sport', imageName: 'a.webp' },
            { id: 'm2', model: 'Aurelia', title: 'Aurelia EX', imageName: 'a.webp' }
        ],
        vehicles: [
            { id: 'v1', modelId: 'm1', available: true, price: 100, odometer: null, colour: 'Grey' },
            { id: 'v2', modelId: 'm2', available: true, price: 200, odometer: null, colour: 'Blue' }
        ],
        availableCount: 2
    };
    component.filterModel = 'm1';
    component.filterColour = 'Grey';
    component.maxPrice = '150';
    component.setFamily('aurelia');
    assert.equal(component.filterModel, 'm1', 'a model inside the family stays selected');
    assert.equal(component.filterColour, 'Grey', 'independent filters are untouched');
    assert.equal(component.maxPrice, '150', 'price filter is untouched');
    assert.deepEqual(component.filteredVehicles.map(v => v.id), ['v1']);
});

test('the family control and family cards both apply the same dependent-filter rule', () => {
    const { component } = linkScenario('');
    component.data = {
        models: [
            { id: 'm1', model: 'Aurelia', title: 'Aurelia Sport', imageName: 'a.webp' },
            { id: 'm3', model: 'Cascadia', title: 'Cascadia LX', imageName: 'c.webp' }
        ],
        vehicles: [], availableCount: 0
    };
    component.filterModel = 'm3';

    // Native select path.
    component.handleFilter({ target: { dataset: { filter: 'filterFamily' }, value: 'aurelia' } });
    assert.equal(component.filterFamily, 'aurelia');
    assert.equal(component.filterModel, '', 'selecting the family clears the foreign trim');
    assert.equal(component.inventoryPage, 1);

    // Family card path, legacy single-page mode (no navigation).
    component.filterModel = 'm3';
    component.template = { querySelector: () => null };
    component.openFamily({ currentTarget: { dataset: { family: 'aurelia' } }, preventDefault() {} });
    assert.equal(component.filterFamily, 'aurelia');
    assert.equal(component.filterModel, '', 'the family card applies the same rule');
});

test('clearing the family keeps a valid model selection', () => {
    const { component } = linkScenario('');
    component.data = {
        models: [{ id: 'm1', model: 'Aurelia', title: 'Aurelia Sport', imageName: 'a.webp' }],
        vehicles: [{ id: 'v1', modelId: 'm1', available: true, price: 100, odometer: null }],
        availableCount: 1
    };
    component.filterModel = 'm1';
    component.setFamily('aurelia');
    component.handleFilter({ target: { dataset: { filter: 'filterFamily' }, value: '' } });
    assert.equal(component.filterFamily, '');
    assert.equal(component.filterModel, 'm1', 'a model is valid with no family filter');
    assert.deepEqual(component.filteredVehicles.map(v => v.id), ['v1']);
});
