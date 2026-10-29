import { LightningElement, api, wire } from 'lwc';
import getHistory from '@salesforce/apex/CaseServiceHistoryController.getHistory';

const PAGE_SIZE = 20;
const COLUMNS = [
    { label: 'Service Visit', fieldName: 'url', type: 'url', typeAttributes: { label: { fieldName: 'name' } } },
    { label: 'Scheduled Start', fieldName: 'scheduledStart', type: 'date', typeAttributes: { year: 'numeric', month: 'short', day: '2-digit' } },
    { label: 'Status', fieldName: 'status' },
    { label: 'Service Type', fieldName: 'serviceType' }
];

export default class CaseServiceHistory extends LightningElement {
    @api recordId;
    columns = COLUMNS;
    visits = [];
    offset = 0;
    hasNext = false;

    @wire(getHistory, { caseId: '$recordId', pageSize: 21, pageOffset: '$offset' })
    wiredHistory({ data }) {
        if (data) {
            this.hasNext = data.length > PAGE_SIZE;
            this.visits = data.slice(0, PAGE_SIZE).map((visit) => ({
                ...visit,
                url: `/lightning/r/Service_Visit__c/${visit.id}/view`
            }));
        }
    }

    get hasVisits() {
        return this.visits.length > 0;
    }

    get firstPage() {
        return this.offset === 0;
    }

    get lastPage() {
        return !this.hasNext;
    }

    previousPage() {
        this.offset = Math.max(0, this.offset - PAGE_SIZE);
    }

    nextPage() {
        if (this.hasNext) {
            this.offset += PAGE_SIZE;
        }
    }
}
