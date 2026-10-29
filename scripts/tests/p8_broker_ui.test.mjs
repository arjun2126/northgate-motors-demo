import { readFileSync } from 'node:fs';
import { runInNewContext } from 'node:vm';
import assert from 'node:assert/strict';
import test from 'node:test';

function component(name, bindings = {}, guest = false) {
    const source = readFileSync(`force-app/main/default/lwc/${name}/${name}.js`, 'utf8')
        .replace(/^import .*;\r?\n/gm, '').replace('export default class', 'globalThis.Component = class');
    const context = { LightningElement: class {}, isGuest: guest,
        crypto: { randomUUID: () => 'broker-request-00000001' }, ...bindings };
    runInNewContext(source, context); return new context.Component();
}
const own = { vehicleId: 'own', label: 'Vehicle A', model: 'Aurelia EX', year: 2026,
    photoUrl: '/resource/NG_VehicleImages/aurelia_ex.webp', canRequestService: true };

test('vehicle list/detail selects only delivered rows, handles photo failure and clears on denial', async () => {
    let calls = 0;
    const widget = component('ownerPortalVehicles', { getVehicles: async () => {
        if (calls++) throw new Error('private owner data'); return { rows: [own], hasMore: false };
    } });
    await widget.load(); widget.select({ currentTarget: { dataset: { vehicleId: 'foreign' } } });
    assert.equal(widget.selected, undefined);
    widget.select({ currentTarget: { dataset: { vehicleId: 'own' } } }); assert.equal(widget.selected.model, 'Aurelia EX');
    widget.imageError({ currentTarget: { dataset: { vehicleId: 'own' } } }); assert.equal(widget.selected.photoUrl, null);
    await widget.refresh(); assert.equal(widget.rows.length, 0); assert.equal(widget.selected, undefined);
    assert.doesNotMatch(widget.error, /private owner/);
});
test('owned vehicle pagination sends only the cursor and appends bounded DTOs', async () => {
    const widget = component('ownerPortalVehicles', { getVehicles: async () => ({ rows: [own], beforeId: 'cursor', hasMore: true }),
        getVehiclePage: async args => { assert.equal(JSON.stringify(args), '{"beforeId":"cursor"}'); return { rows: [{ ...own, vehicleId: 'older' }], hasMore: false }; } });
    await widget.load(); await widget.load(); assert.equal(widget.rows.length, 2); assert.equal(widget.hasMore, false);
});
test('appointment exposes only separately authorized vehicles and server catalog', async () => {
    const widget = component('ownerPortalAppointment', {
        getVehicles: async () => ({ rows: [own, { ...own, vehicleId: 'ownership-only', canRequestService: false }] }),
        getAppointmentOptions: async args => { assert.equal(args.vehicleId, 'own'); return { rooftops: [{ label: 'Service', value: 'roof' }], services: [{ label: 'Inspection', value: 'Inspection' }] }; }
    });
    await widget.load(); assert.equal(widget.vehicleOptions.length, 1);
    await widget.input({ target: { name: 'vehicleId', value: 'own' } }); assert.equal(widget.rooftops[0].value, 'roof');
    await widget.input({ target: { name: 'receipt', value: 'forged' } }); assert.equal(widget.receipt, undefined);
});
test('review validates, retries retain the idempotency key, and success prevents another write', async () => {
    const sent = []; let fail = true;
    const widget = component('ownerPortalAppointment', { bookAppointment: async args => {
        sent.push(args); if (fail) { fail = false; throw new Error('network'); } return 'own-visit';
    } });
    widget.review(); assert.equal(widget.reviewing, false);
    widget.rows = [own]; widget.vehicleId = 'own'; widget.rooftopId = 'roof'; widget.serviceType = 'Inspection';
    widget.startsAt = '2099-01-01T12:00:00.000Z'; widget.rooftops = [{ value: 'roof' }]; widget.services = [{ value: 'Inspection' }];
    widget.review(); assert.equal(widget.reviewing, true);
    await widget.submit(); assert.equal(widget.receipt, undefined); await widget.submit(); await widget.submit();
    assert.equal(sent.length, 2); assert.equal(sent[0].requestKey, sent[1].requestKey); assert.equal(widget.receipt, 'own-visit');
    assert.deepEqual(Object.keys(sent[0]).sort(), ['requestKey','rooftopId','serviceType','startsAt','vehicleId']);
});
test('changed inputs reset request identity; guest and loading states never submit', async () => {
    const widget = component('ownerPortalAppointment'); widget.requestKey = 'previous'; widget.reviewing = true;
    await widget.input({ target: { name: 'startsAt', value: '2099-02-01T12:00:00Z' } });
    assert.equal(widget.requestKey, undefined); assert.equal(widget.reviewing, false);
    const guest = component('ownerPortalAppointment', { bookAppointment: () => { throw new Error('guest write'); } }, true);
    guest.reviewing = true; await guest.submit();
    widget.loading = true; await widget.submit(); assert.equal(widget.receipt, undefined);
});
test('no raw formula HTML or native record components; forms retain accessible labels and states', () => {
    for (const name of ['ownerPortalVehicles','ownerPortalAppointment']) {
        const html = readFileSync(`force-app/main/default/lwc/${name}/${name}.html`, 'utf8');
        assert.doesNotMatch(html, /lwc:dom|innerHTML|lightning-record/); assert.match(html, /aria-busy/); assert.match(html, /role="alert"/);
    }
    const vehicles = readFileSync('force-app/main/default/lwc/ownerPortalVehicles/ownerPortalVehicles.html', 'utf8');
    assert.match(vehicles, /alt=\{selected.photoAlt\}/); assert.match(vehicles, /onerror=\{imageError\}/);
    const booking = readFileSync('force-app/main/default/lwc/ownerPortalAppointment/ownerPortalAppointment.html', 'utf8');
    assert.match(booking, /Step 3/); assert.match(booking, /required/); assert.match(booking, /Requested does not mean Scheduled/);
});
