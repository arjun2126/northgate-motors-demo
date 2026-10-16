import { LightningElement, api, track } from 'lwc';
import loadFinanceWizard from '@salesforce/apex/FinanceApplicationController.load';
import previewApplication from '@salesforce/apex/FinanceApplicationController.preview';
import saveApplication from '@salesforce/apex/FinanceApplicationController.saveApplication';

const MAX_AMOUNT = 10000000;

export default class FinanceApplication extends LightningElement {
    _recordId;
    _loaded = false;

    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
        if (value && !this._loaded) {
            this._loaded = true;
            this.refresh();
        }
    }

    @track loading = true;
    @track saving = false;
    @track error;
    @track notice;
    @track data;
    @track quoteId;
    @track downPayment = 0;
    @track termMonths = 60;
    @track creditTier = 'A';
    @track rateSource = 'Rate_Table';
    @track manualRate;
    @track exceptionReason;
    @track applicantContactId;
    @track previewResult;
    @track previewError;
    @track previewRequestId = 0;
    @track savedFinancingId;
    @track showTaxNotice = true;

    tierOptions = [
        { label: 'A', value: 'A' },
        { label: 'B', value: 'B' },
        { label: 'C', value: 'C' },
        { label: 'D', value: 'D' },
        { label: 'Sub Prime', value: 'Sub_Prime' }
    ];
    termOptions = [
        { label: '36', value: 36 },
        { label: '48', value: 48 },
        { label: '60', value: 60 },
        { label: '72', value: 72 },
        { label: '84', value: 84 },
        { label: '96', value: 96 }
    ];
    rateSourceOptions = [
        { label: 'Rate Table (illustrative demo rates)', value: 'Rate_Table' },
        { label: 'Manual Exception', value: 'Manual_Exception' }
    ];

    refresh() {
        if (!this.recordId) {
            return;
        }
        this.loading = true;
        this.error = null;
        loadFinanceWizard({ opportunityId: this.recordId })
            .then((data) => {
                this.data = data;
                this.quoteId = data.quoteId || null;
                this.downPayment = data.downPayment == null ? 0 : data.downPayment;
                if (data.termMonths != null) this.termMonths = data.termMonths;
                if (data.annualRate != null && data.rateSource == null) {
                    this.manualRate = data.annualRate;
                    this.rateSource = 'Manual_Exception';
                } else if (data.rateSource != null) {
                    this.rateSource = data.rateSource;
                }
                this.exceptionReason = data.exceptionReason;
                this.applicantContactId = data.applicantContactId;
                this.previewRequestId += 1;
                this.runPreview();
            })
            .catch((err) => { this.error = this.messageFrom(err); })
            .finally(() => { this.loading = false; });
    }

    handleQuoteChange(event) {
        this.quoteId = event.detail.value;
        this.previewRequestId += 1;
        this.runPreview();
    }
    handleDownPayment(event) {
        this.downPayment = Number(event.detail.value) || 0;
        this.previewRequestId += 1;
        this.runPreview();
    }
    handleTermChange(event) {
        this.termMonths = Number(event.detail.value);
        this.previewRequestId += 1;
        this.runPreview();
    }
    handleTierChange(event) {
        this.creditTier = event.detail.value;
        this.previewRequestId += 1;
        this.runPreview();
    }
    handleRateSourceChange(event) {
        this.rateSource = event.detail.value;
        if (this.rateSource === 'Rate_Table') {
            this.manualRate = null;
            this.exceptionReason = null;
        }
        this.previewRequestId += 1;
        this.runPreview();
    }
    handleManualRate(event) {
        this.manualRate = Number(event.detail.value);
        this.previewRequestId += 1;
        this.runPreview();
    }
    handleReason(event) {
        this.exceptionReason = event.detail.value;
    }
    handleApplicant(event) {
        this.applicantContactId = event.detail.recordId || null;
    }

    runPreview() {
        if (!this.quoteId) {
            this.previewResult = null;
            this.previewError = null;
            return;
        }
        const myRequest = this.previewRequestId;
        previewApplication({
            opportunityId: this.recordId,
            quoteId: this.quoteId,
            downPayment: this.downPayment,
            creditTier: this.creditTier,
            termMonths: this.termMonths,
            rateSource: this.rateSource,
            manualRate: this.manualRate,
            exceptionReason: this.exceptionReason
        })
            .then((result) => {
                if (myRequest !== this.previewRequestId) {
                    return;
                }
                if (result.errors && result.errors.length > 0) {
                    this.previewError = result.errors.join(', ');
                    this.previewResult = null;
                } else {
                    this.previewError = null;
                    this.previewResult = result;
                }
            })
            .catch((err) => {
                if (myRequest !== this.previewRequestId) {
                    return;
                }
                this.previewError = this.messageFrom(err);
                this.previewResult = null;
            });
    }

    handleSave() {
        if (!this.quoteId) {
            this.error = 'Select a Quote first.';
            return;
        }
        this.saving = true;
        this.error = null;
        saveApplication({
            recordId: this.data && this.data.recordId ? this.data.recordId : null,
            opportunityId: this.recordId,
            quoteId: this.quoteId,
            applicantContactId: this.applicantContactId,
            downPayment: this.downPayment,
            creditTier: this.creditTier,
            termMonths: this.termMonths,
            rateSource: this.rateSource,
            manualRate: this.manualRate,
            exceptionReason: this.exceptionReason
        })
            .then((result) => {
                if (result.errors && result.errors.length > 0) {
                    this.error = result.errors.join(', ');
                    this.savedFinancingId = null;
                } else {
                    this.savedFinancingId = result.financingId;
                    this.error = null;
                }
            })
            .catch((err) => { this.error = this.messageFrom(err); })
            .finally(() => { this.saving = false; });
    }

    get eligibleQuoteOptions() {
        if (!this.data || !this.data.eligibleQuotes) return [];
        return this.data.eligibleQuotes.map((q) => ({
            label: q.name + ' — $' + Number(q.adjustedSubtotal).toLocaleString(),
            value: q.quoteId
        }));
    }

    get canPickManualRate() { return this.rateSource === 'Manual_Exception'; }
    get showExistingDraftNotice() { return this.data && this.data.mode === 'edit' && this.data.status === 'Draft'; }
    get blockReason() {
        if (this.data && this.data.tradeInCount > 1) {
            return 'Multiple Accepted trade-ins exist; cannot pick one deterministically.';
        }
        return null;
    }

    messageFrom(err) {
        return err && err.body && err.body.message ? err.body.message : 'Unexpected error.';
    }
}
