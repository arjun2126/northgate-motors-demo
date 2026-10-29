import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import NAME_FIELD from '@salesforce/schema/Vehicle__c.Name';
import PHOTO_FIELD from '@salesforce/schema/Vehicle__c.Photo__c';
import MODEL_NAME_FIELD from '@salesforce/schema/Vehicle__c.Vehicle_Model__r.Name';
import IMAGE_PATH_FIELD from '@salesforce/schema/Vehicle__c.Vehicle_Model__r.Image_Path__c';

export default class VehiclePhotoHeader extends LightningElement {
    _recordId;
    record;
    loading = false;
    error;
    failedPath;

    @api get recordId() { return this._recordId; }
    set recordId(value) {
        if (value !== this._recordId) {
            this._recordId = value;
            this.record = undefined;
            this.error = undefined;
            this.failedPath = undefined;
            this.loading = Boolean(value);
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: [NAME_FIELD], optionalFields: [PHOTO_FIELD, MODEL_NAME_FIELD, IMAGE_PATH_FIELD] })
    wiredVehicle({ data, error }) {
        if (data) {
            if (!this.recordId || data.id.slice(0, 15) !== this.recordId.slice(0, 15)) return;
            this.record = data;
            this.error = undefined;
            this.loading = false;
        } else if (error) {
            this.record = undefined;
            this.error = 'Vehicle details could not be loaded. Check record access and try again.';
            this.loading = false;
        }
    }

    get noRecord() { return !this.recordId; }
    get vehicleName() { return getFieldValue(this.record, NAME_FIELD) || 'Vehicle'; }
    get modelLine() { return getFieldValue(this.record, MODEL_NAME_FIELD) || 'Vehicle model unavailable'; }
    get imagePath() {
        const photo = getFieldValue(this.record, PHOTO_FIELD);
        const path = getFieldValue(this.record, IMAGE_PATH_FIELD);
        // Photo__c is IMAGE markup. Reuse the gallery's exact local-resource contract, never raw HTML.
        return typeof photo === 'string' && photo.trim() && typeof path === 'string'
            && /^\/resource\/NG_VehicleImages\/[a-z0-9_]+\.webp$/.test(path) && path !== this.failedPath ? path : null;
    }
    get imageAlt() { return `${this.modelLine} vehicle photo`; }
    handleImageError(event) {
        if (event.currentTarget.dataset.recordId?.slice(0, 15) === this.recordId?.slice(0, 15)) {
            this.failedPath = event.currentTarget.dataset.path;
        }
    }
}
