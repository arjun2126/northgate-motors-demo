import { LightningElement } from 'lwc';
import isGuest from '@salesforce/user/isGuest';
import getVehicles from '@salesforce/apex/OwnerPortalBatchBController.getVehicles';
import getVehiclePage from '@salesforce/apex/OwnerPortalBatchBController.getVehiclePage';
import getAppointmentOptions from '@salesforce/apex/OwnerPortalBatchBController.getAppointmentOptions';
import bookAppointment from '@salesforce/apex/OwnerPortalBatchBController.bookAppointment';

export default class OwnerPortalAppointment extends LightningElement {
    message = 'Checking eligible vehicles…';
    rows = [];
    rooftops = [];
    services = [];
    hasMore = false;
    cursor;
    loading = false;
    vehicleId = '';
    rooftopId = '';
    startsAt = '';
    serviceType = '';
    requestKey;
    reviewing = false;
    receipt;
    error;
    connectedCallback() { this.load(); }
    async load() {
        if (isGuest) { this.message = 'Sign in to request service.'; return; }
        if (this.loading) return;
        this.loading = true; this.error = undefined;
        try {
            const page = this.cursor ? await getVehiclePage({ beforeId: this.cursor }) : await getVehicles();
            this.rows = [...this.rows, ...page.rows]; this.cursor = page.beforeId; this.hasMore = page.hasMore;
            this.message = page.unavailableReason || (this.vehicleOptions.length ? 'Select a verified vehicle with separate servicing authorization.' : 'No eligible owned vehicle is available. Contact Northgate for assistance.');
        } catch (error) {
            this.rows = []; this.vehicleId = ''; this.rooftops = []; this.services = []; this.hasMore = false; this.cursor = undefined;
            this.error = 'Appointment requests are unavailable. Check access and try again.';
        } finally { this.loading = false; }
    }
    async input(event) {
        if (this.loading || this.receipt || !['vehicleId','rooftopId','startsAt','serviceType'].includes(event.target.name)) return;
        this[event.target.name] = event.target.value; this.reviewing = false; this.requestKey = undefined; this.error = undefined;
        if (event.target.name !== 'vehicleId') return;
        this.rooftopId = ''; this.serviceType = ''; this.rooftops = []; this.services = [];
        if (!this.rows.some(row => row.vehicleId === this.vehicleId && row.canRequestService)) return;
        this.loading = true;
        try {
            const options = await getAppointmentOptions({ vehicleId: this.vehicleId });
            this.rooftops = options.rooftops; this.services = options.services;
        } catch (error) { this.error = 'Servicing eligibility or locations are unavailable. Refresh before trying again.'; this.vehicleId = ''; }
        finally { this.loading = false; }
    }
    valid() {
        const controls = [...(this.template?.querySelectorAll('[data-input]') || [])];
        const displayedValid = controls.map(field => field.reportValidity()).every(Boolean);
        return displayedValid && this.rows.some(row => row.vehicleId === this.vehicleId && row.canRequestService) &&
            this.rooftops.some(row => row.value === this.rooftopId) && this.services.some(row => row.value === this.serviceType) &&
            Number.isFinite(Date.parse(this.startsAt)) && Date.parse(this.startsAt) > Date.now();
    }
    review() {
        if (isGuest || this.loading || this.receipt) return;
        if (!this.valid()) {
            this.error = 'Choose an eligible vehicle, location, service and future date.';
            this.template?.querySelector('[data-input]')?.focus(); return;
        }
        this.error = undefined; this.reviewing = true;
    }
    back() { if (!this.loading) this.reviewing = false; }
    async submit() {
        if (isGuest || this.loading || this.receipt || !this.reviewing || !this.valid()) return;
        this.requestKey = this.requestKey || globalThis.crypto?.randomUUID?.();
        if (!this.requestKey) { this.error = 'A secure request token is unavailable. Refresh in a supported browser.'; return; }
        this.loading = true; this.error = undefined;
        try {
            this.receipt = await bookAppointment({ vehicleId: this.vehicleId, rooftopId: this.rooftopId,
                startsAt: new Date(this.startsAt).toISOString(), serviceType: this.serviceType, requestKey: this.requestKey });
        } catch (error) { this.error = 'The request could not be completed. Check eligibility, date and capacity, then retry. No success is assumed.'; }
        finally { this.loading = false; }
    }
    get vehicleOptions() { return this.rows.filter(row => row.canRequestService).map(row => ({ label: `${row.label} — ${row.model}`, value: row.vehicleId })); }
    get noEligibleVehicle() { return !this.vehicleOptions.length; }
    get detailsDisabled() { return this.loading || !this.vehicleId || Boolean(this.receipt); }
    get submitDisabled() { return this.loading || Boolean(this.receipt); }
    get vehicleLabel() { return this.vehicleOptions.find(row => row.value === this.vehicleId)?.label; }
    get rooftopLabel() { return this.rooftops.find(row => row.value === this.rooftopId)?.label; }
    get serviceLabel() { return this.services.find(row => row.value === this.serviceType)?.label; }
}
