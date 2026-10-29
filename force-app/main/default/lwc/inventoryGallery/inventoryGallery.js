import { LightningElement } from 'lwc';
import browse from '@salesforce/apex/InventoryGalleryController.browse';
import reserve from '@salesforce/apex/InventoryGalleryController.reserve';
import decode from '@salesforce/apex/VinDecoderService.decode';
import { subscribe, unsubscribe, onError, isEmpEnabled } from 'lightning/empApi';

export default class InventoryGallery extends LightningElement {
    cards = [];
    make = '';
    bodyStyle = '';
    status = '';
    minPrice = '';
    maxPrice = '';
    contactId;
    nextId;
    hasMore = false;
    busy = false;
    error;
    notice;
    eventNotice;
    generation = 0;
    subscription;
    get empty() { return !this.busy && this.cards.length === 0; }
    get statusOptions() {
        return ['', 'Available', 'Reserved', 'In_Appraisal', 'Sold', 'Delivered', 'In_Transit', 'On_Hold']
            .map(value => ({ label: value || 'All statuses', value }));
    }
    connectedCallback() {
        this.load(false);
        onError(() => { if (this.isConnected) this.eventNotice = 'Live refresh unavailable. Use Refresh.'; });
        isEmpEnabled().then(enabled => {
            if (!enabled || !this.isConnected) { this.eventNotice = 'Live refresh unavailable. Use Refresh.'; return null; }
            return subscribe('/event/Vehicle_Reserved__e', -1, () => { if (this.isConnected) this.load(false); });
        }).then(subscription => {
            if (!subscription) return;
            if (this.isConnected) this.subscription = subscription;
            else unsubscribe(subscription, () => {});
        }).catch(() => { this.eventNotice = 'Live refresh unavailable. Use Refresh.'; });
    }
    disconnectedCallback() {
        this.generation += 1;
        if (this.subscription) { unsubscribe(this.subscription, () => {}); this.subscription = null; }
    }
    handleFilter(event) { this[event.target.name] = event.detail.value; }
    handleContact(event) { this.contactId = event.detail.recordId; }
    refresh() { this.load(false); }
    more() { this.load(true); }
    load(append) {
        const generation = ++this.generation;
        this.busy = true;
        this.error = null;
        return browse({ make: this.make || null, bodyStyle: this.bodyStyle || null, status: this.status || null,
            minPrice: this.minPrice === '' ? null : Number(this.minPrice),
            maxPrice: this.maxPrice === '' ? null : Number(this.maxPrice), afterId: append ? this.nextId : null })
            .then(page => {
                if (generation !== this.generation) return;
                const rows = page.cards.map(card => ({ ...card, reserveDisabled: !card.reservable }));
                this.cards = append ? [...this.cards, ...rows] : rows;
                this.nextId = page.nextId;
                this.hasMore = page.hasMore;
            }).catch(error => { if (generation === this.generation) this.error = this.message(error); })
            .finally(() => { if (generation === this.generation) this.busy = false; });
    }
    handleImageError(event) {
        const id = event.target.dataset.id;
        this.cards = this.cards.map(card => card.id === id ? { ...card, imagePath: null } : card);
    }
    async handleReserve(event) {
        if (this.busy) return;
        if (!this.contactId) { this.error = 'Select a Contact before reserving.'; return; }
        this.busy = true; this.error = null; this.notice = null;
        try {
            await reserve({ vehicleId: event.target.dataset.id, contactId: this.contactId });
            this.notice = 'Reservation saved.';
            await this.load(false);
        } catch (error) { this.error = this.message(error); }
        finally { this.busy = false; }
    }
    async handleDecode(event) {
        if (this.busy) return;
        this.busy = true; this.error = null; this.notice = null;
        try {
            const result = await decode({ vin: event.target.dataset.vin });
            this.notice = `SIMULATION: ${result.make} ${result.model} ${result.year} (${result.bodyStyle}). Inventory unchanged.`;
        } catch (error) { this.error = this.message(error); }
        finally { this.busy = false; }
    }
    message(error) { return error?.body?.message || error?.message || 'Inventory request failed.'; }
}
