import { LightningElement, api, track } from 'lwc';
import getCatalog from '@salesforce/apex/QuoteBuilderController.getCatalog';
import getBuyerContacts from '@salesforce/apex/QuoteBuilderController.getBuyerContacts';
import createQuote from '@salesforce/apex/QuoteBuilderController.createQuote';
import submitForApproval from '@salesforce/apex/QuoteBuilderController.submitForApproval';

export default class QuoteBuilder extends LightningElement {
    @api recordId;
    @track categories = [
        { label: 'Vehicle Trims', value: 'Vehicle_Trim', active: true, variant: 'brand' },
        { label: 'Accessories', value: 'Accessory', active: false, variant: 'neutral' },
        { label: 'Service Packages', value: 'Service_Package', active: false, variant: 'neutral' },
        { label: 'Protection Plans', value: 'Protection_Plan', active: false, variant: 'neutral' }
    ];
    @track catalog = [];
    @track selected = {};
    @track buyers = [];
    @track buyerContactId;
    @track busy = false;
    @track error;
    @track result;
    @track submitted = false;
    @track submitMessage;

    listSubtotal = 0;

    get contextNote() {
        return true;
    }

    get selectedLines() {
        const lines = Object.values(this.selected);
        return lines.map((line) => ({
            ...line,
            subtotal: this.round2(line.unitPrice * line.quantity)
        }));
    }

    get hasSelected() {
        return this.selectedLines.length > 0;
    }

    get hasResult() {
        return this.result != null;
    }

    get needsApproval() {
        return (
            this.result != null &&
            !this.result.blockerMessage &&
            Number(this.result.netDiscountPercent) > 5 &&
            !this.submitted
        );
    }

    connectedCallback() {
        this.loadCatalog('Vehicle_Trim');
        this.loadBuyers();
    }

    loadBuyers() {
        if (!this.recordId) {
            return;
        }
        getBuyerContacts({ opportunityId: this.recordId })
            .then((data) => {
                this.buyers = data;
            })
            .catch((err) => {
                this.error = this.messageFrom(err);
            });
    }

    handleCategory(event) {
        const value = event.currentTarget.dataset.value;
        this.categories = this.categories.map((category) => ({
            ...category,
            active: category.value === value,
            variant: category.value === value ? 'brand' : 'neutral'
        }));
        this.loadCatalog(value);
    }

    loadCatalog(category) {
        this.busy = true;
        getCatalog({ category })
            .then((data) => {
                this.catalog = data.map((item) => ({
                    ...item,
                    quantity: (this.selected[item.productId] || {}).quantity || 0
                }));
                this.busy = false;
            })
            .catch((err) => {
                this.busy = false;
                this.error = this.messageFrom(err);
            });
    }

    handleQty(event) {
        const productId = event.currentTarget.dataset.id;
        const raw = Number(event.currentTarget.value);
        const qty = Number.isFinite(raw) && raw > 0 ? raw : 1;
        const item = this.catalog.find((entry) => entry.productId === productId);
        if (!item) {
            return;
        }
        this.selected = {
            ...this.selected,
            [productId]: {
                productId: item.productId,
                name: item.name,
                unitPrice: item.unitPrice,
                quantity: qty
            }
        };
        this.catalog = this.catalog.map((entry) =>
            entry.productId === productId ? { ...entry, quantity: qty } : entry
        );
        this.recomputeSubtotal();
    }

    handleBuyer(event) {
        this.buyerContactId = event.detail.value;
    }

    handleSave() {
        const lines = this.selectedLines.map((line) => ({
            productId: line.productId,
            quantity: line.quantity
        }));
        this.busy = true;
        this.error = null;
        this.result = null;
        createQuote({ opportunityId: this.recordId, buyerContactId: this.buyerContactId, lines })
            .then((data) => {
                this.busy = false;
                this.result = data;
            })
            .catch((err) => {
                this.busy = false;
                this.error = this.messageFrom(err);
            });
    }

    handleSubmit() {
        if (!this.result || !this.result.quoteId || this.submitted) {
            return;
        }
        this.busy = true;
        this.error = null;
        submitForApproval({ quoteId: this.result.quoteId })
            .then(() => {
                this.busy = false;
                this.submitted = true;
                this.submitMessage = 'Submitted for approval.';
            })
            .catch((err) => {
                this.busy = false;
                this.error = this.messageFrom(err);
            });
    }

    recomputeSubtotal() {
        let total = 0;
        for (const line of Object.values(this.selected)) {
            total += line.unitPrice * line.quantity;
        }
        this.listSubtotal = this.round2(total);
    }

    round2(value) {
        const value2 = Number(value);
        if (!Number.isFinite(value2)) {
            return 0;
        }
        return Math.round(value2 * 100) / 100;
    }

    messageFrom(err) {
        return err && err.body && err.body.message ? err.body.message : 'Unexpected error.';
    }
}