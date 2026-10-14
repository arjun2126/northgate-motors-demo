import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import getSummary from '@salesforce/apex/QuoteSummaryController.getSummary';

const QUOTE_OPPORTUNITY_FIELD = 'Quote.OpportunityId';

const APPROVAL_LABELS = {
    'Not_Required': 'Not required',
    'Pending': 'Pending review',
    'Approved': 'Approved',
    'Rejected': 'Rejected'
};

export default class QuoteSummary extends NavigationMixin(LightningElement) {
    @api recordId;
    @track summary;
    @track error;

    @wire(getRecord, { recordId: '$recordId', fields: [QUOTE_OPPORTUNITY_FIELD] })
    quoteRecord;

    get hasSummary() {
        return this.summary != null;
    }

    get opportunityId() {
        return getFieldValue(this.quoteRecord.data, QUOTE_OPPORTUNITY_FIELD);
    }

    get isOpportunityLinkDisabled() {
        return !this.opportunityId;
    }

    get approvalStatusLabel() {
        const raw = this.summary && this.summary.approvalStatus;
        return (raw && APPROVAL_LABELS[raw]) || raw || '—';
    }

    connectedCallback() {
        if (!this.recordId) {
            return;
        }
        getSummary({ quoteId: this.recordId })
            .then((data) => {
                this.summary = data;
            })
            .catch((err) => {
                this.error = err && err.body && err.body.message ? err.body.message : 'Unexpected error.';
            });
    }

    handlePrint() {
        window.print();
    }

    handleOpenOpportunity() {
        if (!this.opportunityId) {
            return;
        }
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.opportunityId,
                objectApiName: 'Opportunity',
                actionName: 'view'
            }
        });
    }
}
