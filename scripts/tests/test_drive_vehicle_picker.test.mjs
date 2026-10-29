// Run: node --test scripts/tests/test_drive_vehicle_picker.test.mjs
// Exercises the real component's handlers with platform interfaces mocked.
// Rendering, LDS/GraphQL enforcement, and browser search still require Salesforce acceptance.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';
import vm from 'node:vm';

const base = new URL('../../force-app/main/default/', import.meta.url);
const read = path => readFileSync(new URL(path, base), 'utf8');
const source = read('lwc/testDriveVehiclePicker/testDriveVehiclePicker.js');
const javascript = source
    .replace(/^import .*;\n/gm, '')
    .replace(/^\s*@wire\([^\n]*\)\n/gm, '\n')
    .replace(/@api\s*/g, '')
    .replace('export default class TestDriveVehiclePicker', 'class TestDriveVehiclePicker')
    + '\nglobalThis.Picker = TestDriveVehiclePicker;';

class Element {
    events = [];
    reports = 0;
    template = { querySelector: () => ({ reportValidity: () => { this.reports += 1; } }) };
    dispatchEvent(event) { this.events.push(event); }
}
const context = vm.createContext({
    LightningElement: Element,
    FlowAttributeChangeEvent: class {
        constructor(name, value) { this.name = name; this.value = value; }
    },
    getFieldValue: (record, field) => record.fields[field.split('.').at(-1)]?.value,
    VEHICLE: 'Vehicle__c', MODEL: 'Vehicle_Model__c'
});
vm.runInContext(javascript, context);
const fields = names => Object.fromEntries(names.map(name => [name, {}]));
const vehicleFields = ['Booking_Display__c', 'Year__c', 'VIN__c', 'Status__c'];
const modelFields = ['Make__c', 'Model__c', 'Trim__c'];
const id = 'a0D000000000001AAA';
const data = {
    id,
    fields: {
        Booking_Display__c: { value: '2024 Example Touring | Stock 10' },
        Status__c: { value: 'Available' },
        VIN__c: { value: 'TESTVIN0000000001' }
    }
};
function ready() {
    const picker = new context.Picker();
    picker.vehicleInfo({ data: { fields: fields(vehicleFields) } });
    picker.modelInfo({ data: { fields: fields(modelFields) } });
    return picker;
}
function select(picker) {
    picker.handleChange({ detail: { recordId: id } });
    picker.selectedVehicle({ data });
}

test('required selection uses the existing recordId output, not typed text', () => {
    const picker = ready();
    assert.equal(picker.validate().isValid, false);
    picker.handleChange({ detail: { recordId: id } });
    assert.equal(picker.recordId, id);
    assert.equal(picker.events.at(-1).name, 'recordId');
    assert.equal(picker.events.at(-1).value, id);
    assert.equal(picker.validate().isValid, false, 'selected details must finish loading');
    picker.selectedVehicle({ data });
    assert.equal(picker.validate().isValid, true);
    assert.equal(picker.selection.description, data.fields.Booking_Display__c.value);
    picker.handleChange({ detail: { recordId: null } });
    assert.equal(picker.events.at(-1).value, null);
    assert.equal(picker.validate().isValid, false);
});

test('Flow restores selection without an event loop and null required defaults safely', () => {
    const picker = ready();
    picker.required = null;
    picker.label = null;
    assert.equal(picker.isRequired, true);
    assert.equal(picker.displayLabel, 'Vehicle');
    picker.recordId = id;
    assert.equal(picker.events.length, 0);
    assert.equal(picker.validate().isValid, false);
    picker.selectedVehicle({ data });
    assert.equal(picker.validate().isValid, true);
    picker.recordId = id;
    assert.equal(picker.validate().isValid, true, 'Flow echoing the selected ID must not discard loaded details');
    assert.equal(picker.events.length, 0, 'Flow input updates must not emit another output event');
});

test('missing vehicle field permissions clear output and fail closed', () => {
    for (const denied of vehicleFields) {
        const picker = ready();
        select(picker);
        picker.vehicleInfo({ data: { fields: fields(vehicleFields.filter(name => name !== denied)) } });
        assert.equal(picker.disabled, true);
        assert.equal(picker.recordId, null);
        assert.equal(picker.events.at(-1).value, null);
        assert.equal(picker.validate().isValid, false);
    }
});

test('formula dependencies require readable model fields', () => {
    for (const denied of modelFields) {
        const picker = ready();
        picker.modelInfo({ data: { fields: fields(modelFields.filter(name => name !== denied)) } });
        assert.equal(picker.disabled, true);
        assert.equal(picker.validate().isValid, false);
    }
});

test('schema, search and selected-record errors never retain a booking ID', () => {
    for (const fail of [
        p => p.vehicleInfo({ error: { message: 'denied' } }),
        p => p.modelInfo({ error: { message: 'denied' } }),
        p => p.handleError(),
        p => p.selectedVehicle({ error: { message: 'denied' } })
    ]) {
        const picker = ready();
        select(picker);
        fail(picker);
        assert.equal(picker.recordId, null);
        assert.equal(picker.hasSelection, false);
        assert.equal(picker.events.at(-1).value, null);
        assert.equal(picker.validate().isValid, false);
    }
});

test('availability is only a UI filter and changing it clears the old selection', () => {
    const picker = ready();
    assert.equal(picker.vehicleFilter.criteria[0].fieldPath, 'Status__c');
    assert.equal(picker.vehicleFilter.criteria[0].value, 'Available');
    select(picker);
    picker.handleAvailabilityChange({ target: { checked: false } });
    assert.equal(picker.vehicleFilter, undefined);
    assert.equal(picker.recordId, null);
    assert.equal(picker.events.at(-1).value, null);
});

test('invalid source mappings and Flow external errors block navigation', () => {
    const picker = ready();
    select(picker);
    picker.objectApiName = 'Contact';
    assert.equal(picker.disabled, true);
    assert.equal(picker.validate().isValid, false);
    picker.objectApiName = 'Test_Drive__c';
    picker.setCustomValidity('External validation failure');
    assert.equal(picker.validate().isValid, false);
    picker.reportValidity();
    assert.equal(picker.errorMessage, 'External validation failure');
    assert.equal(picker.reports, 1);
    picker.setCustomValidity('');
    assert.equal(picker.validate().isValid, true);
});

test('picker uses supported two-field matching and a readable selected description', () => {
    const picker = ready();
    assert.equal(picker.matchingInfo.primaryField.fieldPath, 'Booking_Display__c');
    assert.equal(picker.matchingInfo.additionalFields.length, 1);
    assert.equal(picker.matchingInfo.additionalFields[0].fieldPath, 'VIN__c');
    assert.equal(picker.displayInfo.primaryField, 'Booking_Display__c');
    assert.equal(picker.displayInfo.additionalFields[0], 'Status__c');
    assert.doesNotMatch(source, /@salesforce\/apex|SYSTEM_MODE|Invoice_Cost__c|Contact\.Email/);
});

test('metadata retains native Contact lookup, recordId bindings and Everything list scope', () => {
    const flow = read('flows/TestDrive_Book_Screen.flow-meta.xml');
    const metadata = read('lwc/testDriveVehiclePicker/testDriveVehiclePicker.js-meta.xml');
    assert.equal((flow.match(/Vehicle_Lookup\.recordId/g) || []).length, 2);
    assert.match(flow, /<name>Contact_Lookup<\/name><extensionName>flowruntime:lookup<\/extensionName>/);
    assert.match(flow, /<extensionName>c:testDriveVehiclePicker<\/extensionName>/);
    const output = metadata.match(/<property name="recordId"[^>]*\/>/)[0];
    assert.doesNotMatch(output, /role=/, 'recordId supports both restoring and exporting selection');
    assert.match(read('objects/Vehicle__c/listViews/All_Vehicles.listView-meta.xml'), /<filterScope>Everything<\/filterScope>/);
    const permission = read('permissionsets/PS_Test_Drive_Booking.permissionset-meta.xml');
    const grants = [...permission.matchAll(/<fieldPermissions>([\s\S]*?)<\/fieldPermissions>/g)].map(match => ({
        name: match[1].match(/<field>(.*?)<\/field>/)[1],
        editable: match[1].match(/<editable>(.*?)<\/editable>/)[1]
    }));
    const added = grants.filter(grant => !grant.name.startsWith('Test_Drive__c.'));
    assert.equal(added.length, 6);
    assert.equal(new Set(grants.map(grant => grant.name)).size, grants.length);
    assert(added.every(grant => grant.editable === 'false'));
    assert(!grants.some(grant => /Invoice_Cost|Contact\.Email/.test(grant.name)));
});
