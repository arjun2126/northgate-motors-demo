import { LightningElement } from 'lwc';
import isGuest from '@salesforce/user/isGuest';
import getHistory from '@salesforce/apex/OwnerPortalBatchBController.getHistory';

export default class OwnerPortalHistory extends LightningElement {
    visits = [];
    cases = [];
    error;
    loading = false;
    hasMore = false;
    connectedCallback() { this.load(); }
    async load() {
        if (isGuest || this.loading) return;
        this.loading = true;
        this.error = undefined;
        try {
            const page = await getHistory({ beforeId: this.visits.at(-1)?.Id || null });
            this.visits = [...this.visits, ...page.visits];
            this.cases = [...new Map([...this.cases, ...page.cases].map(row => [row.Id, row])).values()];
            this.hasMore = page.hasMore;
        } catch (error) {
            this.visits = []; this.cases = []; this.hasMore = false;
            this.error = 'Service history is unavailable. Check access and try again.';
        } finally { this.loading = false; }
    }
    get empty() { return !isGuest && !this.loading && !this.error && !this.visits.length; }
    get chronologicalVisits() {
        return [...this.visits].sort((a, b) => Date.parse(a.Scheduled_Start__c) - Date.parse(b.Scheduled_Start__c) || a.Id.localeCompare(b.Id));
    }
    get mileageReadings() {
        // Individual visit readings, not a joined odometer curve across possibly different cars.
        return this.chronologicalVisits.filter(row => row.Mileage_At_Checkin__c !== null && row.Mileage_At_Checkin__c !== undefined);
    }
}
