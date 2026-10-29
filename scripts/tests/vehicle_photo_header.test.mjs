import { readFileSync } from 'node:fs';
import { runInNewContext } from 'node:vm';
import assert from 'node:assert/strict';
import test from 'node:test';

// Real component state with UI API bindings stubbed. No DOM, browser or actual-persona claim.
const fields = {
    NAME_FIELD: 'Vehicle__c.Name', PHOTO_FIELD: 'Vehicle__c.Photo__c',
    MODEL_NAME_FIELD: 'Vehicle__c.Vehicle_Model__r.Name', IMAGE_PATH_FIELD: 'Vehicle__c.Vehicle_Model__r.Image_Path__c'
};
const first = 'a00100000000001AAA';
const second = 'a00100000000002AAA';
const path = '/resource/NG_VehicleImages/aurelia_ex.webp';
function component() {
    const source = readFileSync(new URL('../../force-app/main/default/lwc/vehiclePhotoHeader/vehiclePhotoHeader.js', import.meta.url), 'utf8')
        .replace(/^import .*;\r?\n/gm, '').replace(/@api\s+/g, '')
        .replace(/^\s*@wire\(.*\)\r?\n/gm, '')
        .replace('export default class', 'globalThis.Component = class');
    const context = {
        LightningElement: class {}, ...fields,
        getFieldValue(record, field) {
            let current = record;
            for (const part of field.split('.').slice(1)) current = current?.fields?.[part]?.value;
            return current;
        }
    };
    runInNewContext(source, context);
    return new context.Component();
}
function record(id = first, imagePath = path, photo = '<img src="existing-formula" />') {
    return { id, fields: {
        Name: { value: 'V-TEST' }, Photo__c: { value: photo },
        Vehicle_Model__r: { value: { fields: { Name: { value: 'Aurelia EX 2026' }, Image_Path__c: { value: imagePath } } } }
    } };
}
const imageError = (id = first, imagePath = path) => ({ currentTarget: { dataset: { recordId: id, path: imagePath } } });

test('loads existing Photo formula/model contract without rendering formula HTML', () => {
    const header = component();
    assert.equal(header.noRecord, true);
    header.recordId = first;
    assert.equal(header.loading, true);
    header.wiredVehicle({ data: record() });
    assert.equal(header.imagePath, path);
    assert.equal(header.vehicleName, 'V-TEST');
    assert.equal(header.modelLine, 'Aurelia EX 2026');
    assert.equal(header.imageAlt, 'Aurelia EX 2026 vehicle photo');
    assert.equal(header.loading, false);
});

test('missing or omitted optional fields fail closed to a photo fallback', () => {
    const header = component(); header.recordId = first;
    for (const data of [record(first, null), record(first, path, null), record(first, path, '   '),
        { id: first, fields: { Name: { value: 'V-TEST' } } }]) {
        header.wiredVehicle({ data });
        assert.equal(header.imagePath, null);
        assert.equal(header.error, undefined);
    }
    assert.equal(header.modelLine, 'Vehicle model unavailable');
});

test('allows only exact local WebP paths, never remote or injected URLs', () => {
    const header = component(); header.recordId = first;
    for (const value of ['https://example.test/car.webp', '//example.test/car.webp', 'javascript:alert(1)',
        '/resource/NG_VehicleImages/../car.webp', '/resource/NG_VehicleImages/car.svg',
        '/resource/NG_VehicleImages/car.webp?x=1', '/resource/NG_VehicleImages/CAR.webp', '<img onerror="bad">']) {
        header.wiredVehicle({ data: record(first, value) });
        assert.equal(header.imagePath, null, value);
    }
});

test('broken image falls back; record navigation clears old data and failed path', () => {
    const header = component(); header.recordId = first; header.wiredVehicle({ data: record() });
    header.handleImageError(imageError()); assert.equal(header.imagePath, null);
    header.recordId = second;
    assert.equal(header.record, undefined); assert.equal(header.loading, true);
    header.wiredVehicle({ data: record(second) });
    assert.equal(header.imagePath, path);
});

test('stale record responses and image errors cannot overwrite a new record', () => {
    const header = component(); header.recordId = second;
    header.wiredVehicle({ data: record(first) }); assert.equal(header.record, undefined);
    header.wiredVehicle({ data: record(second) });
    header.handleImageError(imageError(first)); assert.equal(header.imagePath, path);
    header.recordId = undefined;
    header.wiredVehicle({ data: record(first) }); assert.equal(header.record, undefined);
    assert.equal(header.noRecord, true); assert.equal(header.loading, false);
});

test('read errors remove prior content and expose only a generic access error', () => {
    const header = component(); header.recordId = first; header.wiredVehicle({ data: record() });
    header.wiredVehicle({ error: { body: { message: 'private details' } } });
    assert.equal(header.imagePath, null); assert.equal(header.record, undefined);
    assert.match(header.error, /Check record access/); assert.doesNotMatch(header.error, /private details/);
    assert.equal(header.loading, false);
});
