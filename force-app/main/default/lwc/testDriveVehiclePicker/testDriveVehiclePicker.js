import { LightningElement, api, wire } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import VEHICLE from '@salesforce/schema/Vehicle__c';
import MODEL from '@salesforce/schema/Vehicle_Model__c';

const VEHICLE_FIELDS = ['Booking_Display__c', 'Year__c', 'VIN__c', 'Status__c'];
const MODEL_FIELDS = ['Make__c', 'Model__c', 'Trim__c'];
const SELECTED_FIELDS = ['Vehicle__c.Booking_Display__c', 'Vehicle__c.VIN__c', 'Vehicle__c.Status__c'];

export default class TestDriveVehiclePicker extends LightningElement {
    @api objectApiName = 'Test_Drive__c';
    @api fieldApiName = 'Vehicle__c';
    @api label = 'Vehicle';
    @api required;
    _recordId;
    _vehicleInfo;
    _modelInfo;
    _vehicleError = false;
    _modelError = false;
    _searchError = '';
    _selectionError = '';
    _externalError = '';
    _showValidation = false;
    selection;
    availableOnly = true;

    matchingInfo = {
        primaryField: { fieldPath: 'Booking_Display__c', mode: 'contains' },
        additionalFields: [{ fieldPath: 'VIN__c', mode: 'contains' }]
    };
    displayInfo = { primaryField: 'Booking_Display__c', additionalFields: ['Status__c'] };

    @api
    get recordId() { return this._recordId || null; }
    set recordId(value) {
        const next = value || undefined;
        if (next !== this._recordId) {
            this._recordId = next;
            this.selection = undefined;
        }
    }

    @wire(getObjectInfo, { objectApiName: VEHICLE })
    vehicleInfo({ data, error }) {
        this._vehicleInfo = data;
        this._vehicleError = Boolean(error);
        if (this.accessError) this.clearSelection();
    }

    @wire(getObjectInfo, { objectApiName: MODEL })
    modelInfo({ data, error }) {
        this._modelInfo = data;
        this._modelError = Boolean(error);
        if (this.accessError) this.clearSelection();
    }

    @wire(getRecord, { recordId: '$_recordId', fields: SELECTED_FIELDS })
    selectedVehicle({ data, error }) {
        if (error) {
            this._selectionError = 'The selected vehicle is unavailable or you do not have the required field access.';
            this.clearSelection();
        } else if (data && data.id === this._recordId) {
            this.selection = {
                description: getFieldValue(data, 'Vehicle__c.Booking_Display__c'),
                status: getFieldValue(data, 'Vehicle__c.Status__c'),
                vin: getFieldValue(data, 'Vehicle__c.VIN__c')
            };
            this._searchError = '';
            this._selectionError = '';
        }
    }

    get displayLabel() { return this.label || 'Vehicle'; }
    get isRequired() { return this.required !== false; }
    get mappingError() {
        return this.objectApiName !== 'Test_Drive__c' || this.fieldApiName !== 'Vehicle__c'
            ? 'This selector must use the Test Drive Vehicle lookup mapping.' : '';
    }
    get accessError() {
        const missingVehicle = this._vehicleInfo && VEHICLE_FIELDS.some(field => !this._vehicleInfo.fields[field]);
        const missingModel = this._modelInfo && MODEL_FIELDS.some(field => !this._modelInfo.fields[field]);
        return this._vehicleError || this._modelError || missingVehicle || missingModel
            ? 'Vehicle search access is unavailable. Ask your administrator to check the required field permissions.' : '';
    }
    get disabled() { return Boolean(this.mappingError || this.accessError || !this._vehicleInfo || !this._modelInfo); }
    get vehicleFilter() {
        return this.availableOnly ? { criteria: [{ fieldPath: 'Status__c', operator: 'eq', value: 'Available' }] } : undefined;
    }
    get hasSelection() { return Boolean(this._recordId && this.selection); }
    get validationMessage() {
        return this._externalError || this.mappingError || this.accessError || this._searchError || this._selectionError
            || (this.disabled ? 'Wait for vehicle search to load.' : '')
            || (this.isRequired && !this._recordId ? 'Select a vehicle from the search results.' : '')
            || (this._recordId && !this.selection ? 'Wait for the selected vehicle details to load.' : '');
    }
    get errorMessage() {
        return this._externalError || this.mappingError || this.accessError || this._searchError || this._selectionError
            || (this._showValidation ? this.validationMessage : '');
    }

    handleChange(event) {
        this._recordId = event.detail.recordId || undefined;
        this.selection = undefined;
        this._searchError = '';
        this._selectionError = '';
        this.dispatchEvent(new FlowAttributeChangeEvent('recordId', this.recordId));
    }
    clearSelection() {
        const hadSelection = Boolean(this._recordId);
        this._recordId = undefined;
        this.selection = undefined;
        if (hadSelection) this.dispatchEvent(new FlowAttributeChangeEvent('recordId', null));
    }
    handleError() {
        this._searchError = 'Vehicle search failed. Check your access and try again; no vehicle has been selected.';
        this.clearSelection();
    }
    handleAvailabilityChange(event) {
        this.availableOnly = event.target.checked;
        this._searchError = '';
        this._selectionError = '';
        this.clearSelection();
    }

    @api
    validate() { return { isValid: !this.validationMessage, errorMessage: this.validationMessage }; }
    @api
    setCustomValidity(message) { this._externalError = message || ''; }
    @api
    reportValidity() {
        this._showValidation = true;
        this.template.querySelector('lightning-record-picker')?.reportValidity();
    }
}
