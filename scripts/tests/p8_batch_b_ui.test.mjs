import { readFileSync } from 'node:fs';
import { runInNewContext } from 'node:vm';
import assert from 'node:assert/strict';
import test from 'node:test';

// Component-state tests with Apex/user bindings stubbed; no DOM or live-site proof.
// The shell's CurrentPageReference decorator is stripped so the setter can be invoked directly.
function component(name, bindings = {}, guest = false) {
    const source = readFileSync(`force-app/main/default/lwc/${name}/${name}.js`, 'utf8')
        .replace(/^import .*;\r?\n/gm, '')
        .replace(/^[ \t]*@wire\(CurrentPageReference\)[ \t]*\r?\n/gm, '')
        .replace('export default class', 'globalThis.Component = class');
    const context = { LightningElement: class {}, isGuest: guest, NavigationMixin: Base => class extends Base {}, ...bindings };
    runInNewContext(source, context);
    return new context.Component();
}
test('guests perform no customer Apex reads or writes', async () => {
    const fail = () => { throw new Error('Guest Apex call'); };
    for (const [name, bindings] of [
        ['ownerPortalHistory', { getHistory: fail }], ['ownerPortalCases', { getCases: fail, createCase: fail, addComment: fail }],
        ['ownerPortalLoyalty', { getLoyalty: fail }], ['ownerPortalVehicles', { getVehicles: fail }],
        ['ownerPortalAppointment', { getVehicles: fail }]
    ]) {
        const widget = component(name, bindings, true);
        await widget.load();
        if (name === 'ownerPortalCases') { widget.subject = 'Test'; await widget.create(); await widget.comment(); }
    }
    assert.equal(component('ownerPortalHome', {}, true).guest, true);
});
test('service history uses only cursor and clears data on access failure', async () => {
    let calls = 0;
    const widget = component('ownerPortalHistory', { getHistory: async args => {
        assert.equal(Object.keys(args).join(), 'beforeId');
        if (++calls > 1) throw { body: { message: 'private customer detail' } };
        return { visits: [{ Id: 'own' }], cases: [], hasMore: true };
    } });
    await widget.load(); assert.equal(widget.visits[0].Id, 'own');
    await widget.load(); assert.equal(widget.visits.length, 0); assert.equal(widget.hasMore, false);
    assert.match(widget.error, /unavailable/); assert.doesNotMatch(widget.error, /private customer/);
});
test('loyalty errors never become a zero-point balance', async () => {
    const widget = component('ownerPortalLoyalty', { getLoyalty: async () => { throw new Error('private'); } });
    await widget.load();
    assert.equal(widget.members.length, 0); assert.equal(widget.empty, false);
    assert.match(widget.error, /unavailable/);
});
test('empty membership is distinct from an unavailable response', async () => {
    const widget = component('ownerPortalLoyalty', { getLoyalty: async () => ({ members: [], transactions: [], hasMore: false }) });
    await widget.load(); assert.equal(widget.empty, true); assert.equal(widget.error, undefined);
});
test('missing ownership still prevents the now-implemented appointment write', async () => {
    let writes = 0;
    const widget = component('ownerPortalAppointment', { getVehicles: async () => ({ rows: [], unavailableReason: 'Ownership not configured' }),
        bookAppointment: async () => { writes++; } });
    await widget.load(); assert.equal(widget.message, 'Ownership not configured');
    widget.review(); await widget.submit(); assert.equal(writes, 0);
    const html = readFileSync('force-app/main/default/lwc/ownerPortalAppointment/ownerPortalAppointment.html', 'utf8');
    assert.match(html, /disabled/);
});
test('Case submission sends only subject/description, not identity or routing', async () => {
    let sent;
    const widget = component('ownerPortalCases', {
        createCase: async args => { sent = args; return 'own-case'; },
        getCases: async () => ({ rows: [], hasMore: false })
    });
    widget.subject = 'Service question'; widget.description = 'Customer message';
    await widget.create();
    assert.equal(JSON.stringify(sent), JSON.stringify({ subject: 'Service question', description: 'Customer message' }));
    assert.match(widget.notice, /submitted/); assert.equal(widget.subject, '');
});
test('stale Case comment responses cannot replace a newer selection', async () => {
    let resolve;
    const widget = component('ownerPortalCases', { getComments: () => new Promise(r => { resolve = r; }) });
    const pending = widget.select({ detail: { selectedRows: [{ Id: 'first' }] } });
    await widget.select({ detail: { selectedRows: [] } });
    resolve([{ Id: 'old-comment' }]); await pending;
    assert.equal(widget.comments.length, 0);
});
test('dashboard loads independent widget states without turning a denial into zero', async () => {
    const widget = component('ownerPortalHome', { getDashboard: async () => ({
        openCaseCount: null, caseError: 'unavailable', nextAppointment: [], membership: [],
        vehicleMessage: 'Ownership not configured'
    }) });
    await widget.load();
    assert.equal(widget.summary.openCaseCount, null); assert.equal(widget.noAppointment, true);
    assert.equal(widget.noMembership, true); assert.equal(widget.summary.caseError, 'unavailable');
    const guest = component('ownerPortalHome', { getDashboard: () => { throw new Error('Guest Apex'); } }, true);
    await guest.load(); assert.equal(guest.summary, undefined);
});
test('dashboard errors clear prior customer state and do not expose server details', async () => {
    const widget = component('ownerPortalHome', { getDashboard: async () => { throw new Error('private query detail'); } });
    widget.summary = { openCaseCount: 9 };
    await widget.load(); assert.equal(widget.summary, undefined);
    assert.match(widget.error, /unavailable/); assert.doesNotMatch(widget.error, /private/);
});
test('history displays dated mileage chronologically without changing the pagination cursor', () => {
    const widget = component('ownerPortalHistory');
    widget.visits = [{ Id: 'new-id', Scheduled_Start__c: '2026-10-20T12:00:00Z', Mileage_At_Checkin__c: null },
        { Id: 'old-id', Scheduled_Start__c: '2026-10-10T12:00:00Z', Mileage_At_Checkin__c: 0 }];
    assert.equal(widget.chronologicalVisits[0].Id, 'old-id');
    assert.equal(widget.visits[1].Id, 'old-id');
    assert.equal(widget.mileageReadings.length, 1); assert.equal(widget.mileageReadings[0].Mileage_At_Checkin__c, 0);
});
test('Case refresh clears selected comments and begins at the first page', async () => {
    let cursor;
    const widget = component('ownerPortalCases', { getCases: async args => { cursor = args.beforeId; return { rows: [], hasMore: false }; } });
    widget.rows = [{ Id: 'old' }]; widget.selectedCase = 'old'; widget.comments = [{ Id: 'old-comment' }];
    await widget.refresh(); assert.equal(cursor, null); assert.equal(widget.selectedCase, undefined);
    assert.equal(widget.comments.length, 0); assert.equal(widget.empty, true);
});
test('Case inputs cannot overwrite identity-independent control state', () => {
    const widget = component('ownerPortalCases');
    widget.input({ target: { name: 'selectedCase', value: 'forged' } });
    assert.equal(widget.selectedCase, undefined);
    widget.input({ target: { name: 'subject', value: 'A question' } });
    assert.equal(widget.subject, 'A question');
});
