import { LightningElement, api, track } from 'lwc';
import { RefreshEvent } from 'lightning/refresh';
import submitForExceptionApproval from '@salesforce/apex/FinanceApplicationController.submitForExceptionApproval';

export default class SubmitFinancingApproval extends LightningElement {
    _recordId;
    busy = false;
    message;
    messageIsError = false;

    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
    }

    get canInvoke() {
        return !!this._recordId && !this.busy;
    }

    invoke() {
        if (!this._recordId) {
            this.showError('No Financing record context.');
            return;
        }
        this.busy = true;
        this.message = null;
        submitForExceptionApproval({ recordId: this._recordId })
            .then((outcome) => {
                if (outcome.errors && outcome.errors.length > 0) {
                    this.showError(outcome.errors.join(' '));
                    return;
                }
                if (outcome.alreadySubmitted) {
                    this.message = 'Exception approval was already submitted for this record.';
                    this.messageIsError = false;
                } else if (outcome.processInstanceId) {
                    this.message = 'Submitted for Finance Manager exception approval. Reload the record to see the work item.';
                    this.messageIsError = false;
                } else {
                    this.message = 'No submission required.';
                    this.messageIsError = false;
                }
                this.dispatchEvent(new RefreshEvent());
            })
            .catch((err) => {
                this.showError(err && err.body && err.body.message ? err.body.message : 'Unexpected error.');
            })
            .finally(() => {
                this.busy = false;
            });
    }

    showError(text) {
        this.message = text;
        this.messageIsError = true;
    }
}
