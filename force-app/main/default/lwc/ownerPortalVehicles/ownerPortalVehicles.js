import { LightningElement } from 'lwc';
import isGuest from '@salesforce/user/isGuest';
import getVehicles from '@salesforce/apex/OwnerPortalBatchBController.getVehicles';
import getVehiclePage from '@salesforce/apex/OwnerPortalBatchBController.getVehiclePage';

export default class OwnerPortalVehicles extends LightningElement {
    message;
    error;
    rows = [];
    loading = false;
    hasMore = false;
    cursor;
    selectedId;
    failedPhotos = [];
    focusDetail = false;
    connectedCallback() { this.load(); }
    async load() {
        if (isGuest || this.loading) return;
        this.loading = true; this.error = undefined;
        try {
            const page = this.cursor ? await getVehiclePage({ beforeId: this.cursor }) : await getVehicles();
            this.rows = [...this.rows, ...page.rows]; this.hasMore = page.hasMore;
            this.cursor = page.beforeId;
            this.message = page.unavailableReason;
        } catch (error) {
            this.rows = []; this.selectedId = undefined; this.hasMore = false; this.cursor = undefined;
            this.error = 'Owned vehicles are unavailable. Check access and try again.';
        } finally { this.loading = false; }
    }
    async refresh() {
        if (this.loading) return;
        this.rows = []; this.cursor = undefined; this.selectedId = undefined; this.failedPhotos = [];
        await this.load();
    }
    select(event) {
        const id = event.currentTarget.dataset.vehicleId;
        if (!this.rows.some(row => row.vehicleId === id)) return;
        this.selectedId = id; this.focusDetail = true;
    }
    renderedCallback() {
        if (this.focusDetail) { this.template.querySelector('[data-detail-heading]')?.focus(); this.focusDetail = false; }
    }
    imageError(event) {
        const id = event.currentTarget.dataset.vehicleId;
        if (this.rows.some(row => row.vehicleId === id)) this.failedPhotos = [...new Set([...this.failedPhotos, id])];
    }
    get selected() {
        const row = this.rows.find(item => item.vehicleId === this.selectedId);
        if (!row) return undefined;
        return { ...row, photoUrl: this.failedPhotos.includes(row.vehicleId) ? null : row.photoUrl,
            photoAlt: `${row.year || ''} ${row.model || 'Vehicle'} photo` };
    }
    get empty() { return !isGuest && !this.loading && !this.error && !this.rows.length; }
}
