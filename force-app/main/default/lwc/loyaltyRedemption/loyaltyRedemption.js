import { LightningElement, api } from 'lwc';
import redeem from '@salesforce/apex/RedemptionService.redeem';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';

export default class LoyaltyRedemption extends LightningElement {
    @api recordId;
    points;
    busy = false;
    message;
    requestToken;
    changePoints(event) {
        this.points = Number(event.target.value);
        this.requestToken = undefined;
        this.message = undefined;
    }
    async submit() {
        const input = this.template.querySelector('lightning-input');
        if (!input.reportValidity() || this.busy) return;
        this.busy = true;
        // Keep the token on error: a lost response must not turn Retry into a second redemption.
        if (!this.requestToken) {
            this.requestToken = Array.from(globalThis.crypto.getRandomValues(new Uint8Array(16)), value => value.toString(16).padStart(2, '0')).join('');
        }
        try {
            const result = await redeem({ memberId: this.recordId, points: this.points, requestToken: this.requestToken });
            this.message = `Request posted. Balance: ${result.balance} points. Demonstration value: CAD ${result.valueCad}.`;
            await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
        } catch (error) {
            this.message = error.body?.message || 'Redemption failed. Retry this request or contact the loyalty operator.';
        } finally { this.busy = false; }
    }
}
