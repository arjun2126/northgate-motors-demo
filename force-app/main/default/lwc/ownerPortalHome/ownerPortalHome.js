import { LightningElement, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import isGuest from '@salesforce/user/isGuest';
import getDashboard from '@salesforce/apex/OwnerPortalBatchBController.getDashboard';

const VIEWS = [
    { value: 'dashboard', label: 'Dashboard' },
    { value: 'garage', label: 'My Garage' },
    { value: 'service', label: 'Service' },
    { value: 'support', label: 'Support' },
    { value: 'rewards', label: 'Rewards' }
];
const SERVICE_VIEWS = [
    { value: 'appointments', label: 'Appointments' },
    { value: 'booking', label: 'Request service' },
    { value: 'history', label: 'History & mileage' }
];

export default class OwnerPortalHome extends NavigationMixin(LightningElement) {
    summary;
    error;
    loading = false;
    pageReference;
    view = 'dashboard';
    serviceView = 'appointments';
    menuOpen = false;
    navigationError;
    navigationNotice = '';
    focusPending = false;
    garageVisited = false;
    bookingVisited = false;
    historyVisited = false;
    supportVisited = false;
    rewardsVisited = false;
    get guest() { return isGuest; }

    @wire(CurrentPageReference)
    setPageReference(reference) {
        if (!reference) return;
        const state = reference.state || {};
        const requestedView = state.c__view || 'dashboard';
        const requestedService = state.c__service || 'appointments';
        const validView = VIEWS.some(item => item.value === requestedView);
        const validService = SERVICE_VIEWS.some(item => item.value === requestedService);
        const view = validView ? requestedView : 'dashboard';
        const service = validService ? requestedService : 'appointments';
        const changed = this.view !== view || (view === 'service' && this.serviceView !== service);
        const initial = !this.pageReference;
        this.pageReference = reference;
        this.navigationError = !validView || (view === 'service' && !validService)
            ? 'That view is unavailable. A supported portal view is shown instead.' : undefined;
        this.view = view;
        this.serviceView = service;
        this.menuOpen = false;
        // Monotonic mount flags: visiting another view must not destroy a draft, request
        // token, in-flight request, selected Case, or receipt in an existing child instance.
        if (!isGuest) {
            if (view === 'garage') this.garageVisited = true;
            if (view === 'support') this.supportVisited = true;
            if (view === 'rewards') this.rewardsVisited = true;
            if (view === 'service' && service === 'booking') this.bookingVisited = true;
            if (view === 'service' && service === 'history') this.historyVisited = true;
        }
        if (changed) {
            this.navigationNotice = view === 'service' ? `Service — ${this.serviceTitle}` : this.viewTitle;
            // Do not steal focus during the initial page load or a deep link arrival.
            if (!initial) this.focusPending = true;
        }
    }

    // Namespaced query state stays on the current authenticated Experience page. The
    // Salesforce navigation service owns history; no custom history/router is installed.
    navigate(event) {
        if (event.button > 0 || event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return;
        event.preventDefault();
        const { view, service = 'appointments' } = event.currentTarget.dataset;
        if (isGuest || !VIEWS.some(item => item.value === view) || !SERVICE_VIEWS.some(item => item.value === service)) return;
        const target = this.navigationTarget(view, service);
        if (!target) {
            this.navigationError = 'Navigation is still loading. Please try again.';
            return;
        }
        this.menuOpen = false;
        this[NavigationMixin.Navigate](target);
    }

    // Named Experience pages accept a state object that the router serialises into the URL.
    // A web-page reference does not, so it carries the same namespaced parameters in its URL.
    // Both forms keep the URL authoritative for refresh, deep links and browser history.
    navigationTarget(view, service = 'appointments') {
        const reference = this.pageReference;
        if (!reference) return undefined;
        if (/^(?:comm|standard)__namedPage$/.test(reference.type)) {
            const state = { ...(reference.state || {}), c__view: view };
            if (view === 'service') state.c__service = service;
            else delete state.c__service;
            return { type: reference.type, attributes: { ...reference.attributes }, state };
        }
        return { type: 'standard__webPage', attributes: { url: this.hrefFor(view, service) } };
    }

    hrefFor(view, service = 'appointments') {
        const url = new URL(window.location.href);
        url.searchParams.set('c__view', view);
        if (view === 'service') url.searchParams.set('c__service', service);
        else url.searchParams.delete('c__service');
        return url.pathname + url.search + url.hash;
    }
    get navigationItems() {
        return VIEWS.map(item => ({ ...item, href: this.hrefFor(item.value),
            current: this.view === item.value ? 'page' : null,
            className: this.view === item.value ? 'nav-link is-current' : 'nav-link' }));
    }
    get serviceItems() {
        return SERVICE_VIEWS.map(item => ({ ...item, href: this.hrefFor('service', item.value),
            current: this.serviceView === item.value ? 'page' : null,
            className: this.serviceView === item.value ? 'service-link is-current' : 'service-link' }));
    }
    toggleMenu() { this.menuOpen = !this.menuOpen; }
    closeMenu(event) {
        if (event.key !== 'Escape' || !this.menuOpen) return;
        this.menuOpen = false;
        this.template?.querySelector('[data-menu-toggle]')?.focus();
    }
    skipToContent(event) {
        event.preventDefault();
        this.template?.querySelector('[data-view-heading]')?.focus();
    }
    renderedCallback() {
        if (!this.focusPending) return;
        this.focusPending = false;
        this.template?.querySelector('[data-view-heading]')?.focus();
    }
    get navigationClass() { return this.menuOpen ? 'portal-nav is-open' : 'portal-nav'; }
    get menuExpanded() { return this.menuOpen ? 'true' : 'false'; }
    get viewTitle() { return VIEWS.find(item => item.value === this.view)?.label || 'Dashboard'; }
    get serviceTitle() { return SERVICE_VIEWS.find(item => item.value === this.serviceView)?.label || 'Appointments'; }
    get dashboardHidden() { return this.view !== 'dashboard'; }
    get garageHidden() { return this.view !== 'garage'; }
    get serviceHidden() { return this.view !== 'service'; }
    get supportHidden() { return this.view !== 'support'; }
    get rewardsHidden() { return this.view !== 'rewards'; }
    get bookingHidden() { return this.view !== 'service' || this.serviceView !== 'booking'; }
    get historyHidden() { return this.view !== 'service' || this.serviceView !== 'history'; }
    get appointmentsHidden() { return this.view !== 'service' || this.serviceView !== 'appointments'; }
    get garageHref() { return this.hrefFor('garage'); }
    get bookingHref() { return this.hrefFor('service', 'booking'); }
    get appointmentsHref() { return this.hrefFor('service'); }
    get historyHref() { return this.hrefFor('service', 'history'); }
    get supportHref() { return this.hrefFor('support'); }
    get rewardsHref() { return this.hrefFor('rewards'); }
    connectedCallback() { this.load(); }
    async load() {
        if (isGuest || this.loading) return;
        this.loading = true; this.error = undefined; this.summary = undefined;
        try { this.summary = await getDashboard(); }
        catch (error) { this.error = 'Customer dashboard is unavailable. Check access and try again.'; }
        finally { this.loading = false; }
    }
    get nextAppointments() { return this.summary?.nextAppointment || []; }
    get memberships() { return this.summary?.membership || []; }
    get noAppointment() { return this.summary && !this.summary.appointmentError && !this.nextAppointments.length; }
    get noMembership() { return this.summary && !this.summary.loyaltyError && !this.memberships.length; }
}
