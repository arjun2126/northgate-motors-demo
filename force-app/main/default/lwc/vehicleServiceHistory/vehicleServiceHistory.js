import { LightningElement, api } from 'lwc';
import getVisits from '@salesforce/apex/VehicleServiceHistoryController.getVisits';
import getCases from '@salesforce/apex/VehicleServiceHistoryController.getCases';

export default class VehicleServiceHistory extends LightningElement {
    _recordId;
    visits = [];
    cases = [];
    moreVisits = false;
    moreCases = false;
    visitError;
    caseError;
    loading = false;
    visitColumns = [
        { label: 'Visit', fieldName: 'url', type: 'url', typeAttributes: { label: { fieldName: 'name' } } },
        { label: 'Scheduled Start', fieldName: 'scheduledStart', type: 'date', typeAttributes: { year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit', timeZone: 'America/Toronto' } },
        { label: 'Status', fieldName: 'status' }, { label: 'Service', fieldName: 'serviceType' },
        { label: 'Recorded Mileage', fieldName: 'mileage', type: 'number' }
    ];
    caseColumns = [
        { label: 'Case', fieldName: 'url', type: 'url', typeAttributes: { label: { fieldName: 'name' } } },
        { label: 'Created', fieldName: 'createdAt', type: 'date' }, { label: 'Status', fieldName: 'status' }
    ];
    @api get recordId() { return this._recordId; }
    set recordId(value) {
        if (value !== this._recordId) {
            this._recordId = value;
            this.visits = []; this.cases = [];
            this.moreVisits = false; this.moreCases = false;
            this.visitError = undefined; this.caseError = undefined;
            if (this.isConnected) this.loadInitial();
        }
    }
    connectedCallback() { this.loadInitial(); }
    async loadInitial() {
        if (!this.recordId) return;
        this.loading = true;
        await Promise.all([this.loadVisits(), this.loadCases()]);
        this.loading = false;
    }
    async loadVisits() {
        const vehicleId = this.recordId;
        const last = this.visits[this.visits.length - 1];
        try {
            const page = await getVisits({ vehicleId, beforeTime: last?.scheduledStart || null, beforeId: last?.id || null });
            if (vehicleId !== this.recordId) return;
            this.visits = [...this.visits, ...page.rows.map(row => ({ ...row, url: `/lightning/r/Service_Visit__c/${row.id}/view` }))];
            this.moreVisits = page.hasMore;
        } catch (error) {
            if (vehicleId === this.recordId) { this.visitError = 'Service visits could not be loaded. Check access and try again.'; this.moreVisits = false; }
        }
    }
    async loadCases() {
        const vehicleId = this.recordId;
        const last = this.cases[this.cases.length - 1];
        try {
            const page = await getCases({ vehicleId, beforeTime: last?.createdAt || null, beforeId: last?.id || null });
            if (vehicleId !== this.recordId) return;
            this.cases = [...this.cases, ...page.rows.map(row => ({ ...row, url: `/lightning/r/Case/${row.id}/view` }))];
            this.moreCases = page.hasMore;
        } catch (error) {
            if (vehicleId === this.recordId) { this.caseError = 'Cases could not be loaded. Check access and try again.'; this.moreCases = false; }
        }
    }
    async nextVisits() { this.loading = true; await this.loadVisits(); this.loading = false; }
    async nextCases() { this.loading = true; await this.loadCases(); this.loading = false; }
    get noVisits() { return !this.loading && !this.visitError && this.visits.length === 0; }
    get noCases() { return !this.loading && !this.caseError && this.cases.length === 0; }
}
