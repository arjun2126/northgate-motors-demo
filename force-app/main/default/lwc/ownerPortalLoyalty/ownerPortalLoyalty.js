import { LightningElement } from 'lwc';
import isGuest from '@salesforce/user/isGuest';
import getLoyalty from '@salesforce/apex/OwnerPortalBatchBController.getLoyalty';

export default class OwnerPortalLoyalty extends LightningElement {
    members = [];
    transactions = [];
    error;
    loading = false;
    hasMore = false;
    connectedCallback() { this.load(); }
    async load() {
        if (isGuest || this.loading) return;
        this.loading = true; this.error = undefined;
        try {
            const page = await getLoyalty({ beforeId: this.transactions.at(-1)?.Id || null });
            this.members = page.members;
            this.transactions = [...this.transactions, ...page.transactions];
            this.hasMore = page.hasMore;
        } catch (error) {
            this.members = []; this.transactions = []; this.hasMore = false;
            this.error = 'Loyalty information is unavailable. Check access and try again.';
        } finally { this.loading = false; }
    }
    get empty() { return !isGuest && !this.loading && !this.error && !this.members.length; }
}
