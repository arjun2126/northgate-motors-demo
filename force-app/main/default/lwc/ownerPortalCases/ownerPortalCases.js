import { LightningElement } from 'lwc';
import isGuest from '@salesforce/user/isGuest';
import getCases from '@salesforce/apex/OwnerPortalBatchBController.getCases';
import createCase from '@salesforce/apex/OwnerPortalBatchBController.createCase';
import addComment from '@salesforce/apex/OwnerPortalBatchBController.addComment';
import getComments from '@salesforce/apex/OwnerPortalBatchBController.getComments';

export default class OwnerPortalCases extends LightningElement {
    rows = [];
    comments = [];
    subject = '';
    description = '';
    commentBody = '';
    selectedCase;
    error;
    notice;
    loading = false;
    commentsLoading = false;
    hasMore = false;
    connectedCallback() { this.load(); }
    async refresh() {
        if (this.loading) return;
        this.rows = []; this.comments = []; this.selectedCase = undefined; this.hasMore = false; this.commentsLoading = false;
        await this.load();
    }
    async load() {
        if (isGuest || this.loading) return;
        this.loading = true; this.error = undefined;
        try {
            const page = await getCases({ beforeId: this.rows.at(-1)?.Id || null });
            this.rows = [...this.rows, ...page.rows]; this.hasMore = page.hasMore;
        } catch (error) {
            this.rows = []; this.comments = []; this.selectedCase = undefined; this.hasMore = false; this.commentsLoading = false;
            this.error = 'Cases are unavailable. Check access and try again.';
        } finally { this.loading = false; }
    }
    input(event) {
        if (['subject', 'description', 'commentBody'].includes(event.target.name)) {
            this[event.target.name] = event.target.value;
            event.target.setCustomValidity?.('');
        }
    }
    async create() {
        if (isGuest || this.loading) return;
        const inputs = [...(this.template?.querySelectorAll('[data-case-input]') || [])];
        const subjectInput = inputs.find(field => field.name === 'subject');
        subjectInput?.setCustomValidity(this.subject.trim() ? '' : 'Enter a Case subject, not only spaces.');
        if (!inputs.map(field => field.reportValidity()).every(Boolean) || !this.subject.trim()) {
            this.error = 'Check the Case subject and description before submitting.';
            (inputs.find(field => !field.checkValidity()) || subjectInput)?.focus();
            return;
        }
        this.loading = true; this.error = undefined; this.notice = undefined;
        try {
            await createCase({ subject: this.subject, description: this.description });
            this.subject = ''; this.description = ''; this.rows = []; this.comments = []; this.selectedCase = undefined; this.commentsLoading = false;
            this.notice = 'Your Case was submitted to Northgate Service. Tracking is subject to your record access.';
        } catch (error) { this.error = 'Your Case could not be submitted. Check access and try again.'; }
        finally { this.loading = false; }
        if (!this.error) await this.load();
    }
    async select(event) {
        const caseId = event.detail.selectedRows[0]?.Id;
        this.selectedCase = caseId; this.comments = []; this.commentBody = ''; this.error = undefined;
        this.commentsLoading = Boolean(caseId && !isGuest);
        if (!caseId || isGuest) return;
        try {
            const rows = await getComments({ caseId });
            if (this.selectedCase === caseId) this.comments = rows;
        } catch (error) { if (this.selectedCase === caseId) this.error = 'Published comments are unavailable.'; }
        finally { if (this.selectedCase === caseId) this.commentsLoading = false; }
    }
    async choose(event) {
        const caseId = event.currentTarget.dataset.caseId;
        if (!this.rows.some(row => row.Id === caseId) || this.loading || isGuest) return;
        await this.select({ detail: { selectedRows: [{ Id: caseId }] } });
        if (this.selectedCase === caseId) this.template?.querySelector(this.error ? '[data-case-error]' : '[data-comment-heading]')?.focus();
    }
    async comment() {
        if (isGuest || this.loading || !this.selectedCase) return;
        const input = this.template?.querySelector('[data-comment-input]');
        input?.setCustomValidity(this.commentBody.trim() ? '' : 'Enter a comment, not only spaces.');
        if ((input && !input.reportValidity()) || !this.commentBody.trim()) {
            this.error = 'Enter a comment before submitting.'; input?.focus(); return;
        }
        const caseId = this.selectedCase;
        this.loading = true; this.error = undefined;
        try {
            await addComment({ caseId, body: this.commentBody });
            if (this.selectedCase === caseId) {
                this.commentBody = '';
                const rows = await getComments({ caseId });
                if (this.selectedCase === caseId) this.comments = rows;
            }
        } catch (error) { if (this.selectedCase === caseId) this.error = 'Your comment could not be submitted. Check access and try again.'; }
        finally { this.loading = false; }
    }
    get empty() { return !isGuest && !this.loading && !this.error && !this.rows.length; }
    get selectedCaseNumber() { return this.rows.find(row => row.Id === this.selectedCase)?.CaseNumber || 'choose a Case'; }
    get caseCards() {
        return this.rows.map(row => ({ ...row,
            className: row.Id === this.selectedCase ? 'case-row is-selected' : 'case-row',
            expanded: row.Id === this.selectedCase ? 'true' : 'false',
            buttonLabel: `Read comments for Case ${row.CaseNumber || row.Id}`
        }));
    }
}
