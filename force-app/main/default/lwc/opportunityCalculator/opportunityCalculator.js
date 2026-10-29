import { LightningElement, api } from 'lwc';
import amount from '@salesforce/apex/OpportunityCalculatorController.amount';
import preview from '@salesforce/apex/OpportunityCalculatorController.preview';

export default class OpportunityCalculator extends LightningElement {
    @api recordId;
    sellingPrice;
    downPayment = 0;
    appraisal = 0;
    payoff = 0;
    creditTier = 'A';
    termMonths = 60;
    manualRate = '';
    manualReason = '';
    result;
    error;
    busy = false;
    generation = 0;
    connectedCallback() {
        if (this.recordId) amount({ opportunityId: this.recordId }).then(value => { if (this.sellingPrice == null) this.sellingPrice = value; })
            .catch(error => { this.error = this.message(error); });
    }
    handleInput(event) {
        this[event.target.name] = event.detail.value;
        this.generation += 1;
        this.result = null;
        this.busy = false;
    }
    calculate() {
        const generation = ++this.generation;
        this.busy = true; this.error = null; this.result = null;
        return preview({ opportunityId: this.recordId, sellingPrice: this.number(this.sellingPrice), downPayment: this.number(this.downPayment),
            appraisal: this.number(this.appraisal), payoff: this.number(this.payoff), creditTier: this.creditTier,
            termMonths: this.number(this.termMonths), manualRate: this.number(this.manualRate), manualReason: this.manualReason })
            .then(result => { if (generation === this.generation) this.result = result; })
            .catch(error => { if (generation === this.generation) this.error = this.message(error); })
            .finally(() => { if (generation === this.generation) this.busy = false; });
    }
    number(value) { return value === '' || value == null ? null : Number(value); }
    message(error) { return error?.body?.message || error?.message || 'Estimate failed.'; }
}
