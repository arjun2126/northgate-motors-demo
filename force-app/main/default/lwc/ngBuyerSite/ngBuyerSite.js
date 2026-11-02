import { LightningElement, api } from 'lwc';
import getShowcase from '@salesforce/apex/BuyerShowcaseController.getShowcase';
import submitBuyerInquiry from '@salesforce/apex/BuyerInquiryController.submit';
import LOCALE from '@salesforce/i18n/locale';
import CURRENCY_CODE from '@salesforce/i18n/currency';
import NG_VEHICLE_IMAGES from '@salesforce/resourceUrl/NG_VehicleImages';

const CURRENCY = new Intl.NumberFormat(LOCALE, { style: 'currency', currency: CURRENCY_CODE, maximumFractionDigits: 0 });
const NUMBER = new Intl.NumberFormat(LOCALE);
const VEHICLE_HASH_PREFIX = '#vehicle-';
const PAGE_SLUGS = {
    home: 'buyer',
    inventory: 'buyer-inventory',
    vehicle: 'buyer-vehicle',
    studio: 'buyer-studio',
    about: 'buyer-about',
    contact: 'buyer-contact'
};
const PAGE_COPY = {
    home: {
        eyebrow: 'NORTHGATE MOTORS',
        heading: 'Drive something worth arriving in.',
        lede: 'Explore the Northgate range, browse listings and find your next vehicle.'
    },
    inventory: {
        eyebrow: 'INVENTORY',
        heading: 'Find your next vehicle.',
        lede: 'Browse listed vehicles with their recorded colour, condition and list price.'
    },
    vehicle: {
        eyebrow: 'VEHICLE',
        heading: 'Vehicle details',
        lede: 'Specifications, availability and inquiry options for this listing.'
    },
    studio: {
        eyebrow: '3D STUDIO',
        heading: 'Explore the Apex Concept.',
        lede: 'A concept preview with illustrative finishes, alongside the listed Northgate inventory.'
    },
    about: {
        eyebrow: 'ABOUT',
        heading: 'About Northgate.',
        lede: 'A fictional dealership used to demonstrate a modern retail experience.'
    },
    contact: {
        eyebrow: 'CONTACT',
        heading: 'Contact Northgate.',
        lede: 'Send an inquiry about a listing, a test drive or the Apex Concept.'
    }
};
const COLOUR_SWATCH = {
    black: '#1d1f22', white: '#f4f1ea', silver: '#c9ccd0', grey: '#80868c', gray: '#80868c',
    red: '#9e2b2b', blue: '#2f4f7a', green: '#3f6b4f', brown: '#6b5140', beige: '#d8c9ad',
    orange: '#b5652a', yellow: '#d4b13a'
};

export default class NgBuyerSite extends LightningElement {
    /** Which Buyer page hosts this instance: home | inventory | vehicle | studio | about | contact. */
    @api page = 'all';

    data;
    loadError;
    loading = true;
    filterModel = '';
    filterFamily = '';
    filterBody = '';
    filterColour = '';
    filterCondition = '';
    maxPrice = '';
    selectedVehicleId;
    inquiryConfigSummary = '';
    lastAutoMessage = '';
    failedFamilyImages = [];
    topGapApplied = false;
    inquiryOpen = false;
    inquiryType = 'Purchase Inquiry';
    inquiryName = '';
    inquiryEmail = '';
    inquiryPhone = '';
    inquiryMessage = '';
    inquiryVehicleId;
    consent = false;
    submitting = false;
    submitTimeoutMs = 20000;
    submitTimer;
    inquiryUnconfirmed = false;
    inquiryError;
    inquiryReference;
    failedImages = [];
    heroFailed = false;
    focusTarget;
    menuOpen = false;
    filtersOpen = false;
    inventoryPage = 1;
    apexFinish = '';
    skeletonCards = [{ id: 's1' }, { id: 's2' }, { id: 's3' }];

    // Defined as a field so the guard exists (and is testable) before any connection.
    boundBeforeUnload = event => {
        if (!this.hasUnsavedInquiry) return undefined;
        if (event) { event.preventDefault(); event.returnValue = 'Your inquiry has not been sent.'; }
        return 'Your inquiry has not been sent.';
    };

    connectedCallback() {
        // Hash navigation gives every vehicle a stable, shareable link. The record id is already
        // part of the public DTO and grants nothing; ids never depend on list order.
        this.boundHashChange = () => this.applyDeepLink();
        this.boundResize = () => this.syncViewport();
        if (typeof window !== 'undefined' && typeof window.addEventListener === 'function') {
            window.addEventListener('hashchange', this.boundHashChange);
            if (typeof window.addEventListener === 'function') window.addEventListener('beforeunload', this.boundBeforeUnload);
            window.addEventListener('resize', this.boundResize);
        }
        this.syncViewport();
        this.applyPriorityIntent();
        this.loadShowcase().then(() => {
            this.applyFamilyIntent();
            this.applyVehicleIntent();
            this.applyInquiryIntent();
            this.applyDeepLink();
        });
    }
    disconnectedCallback() {
        if (this.submitTimer) { clearTimeout(this.submitTimer); this.submitTimer = null; }
        if (typeof window !== 'undefined' && typeof window.removeEventListener === 'function') {
            window.removeEventListener('hashchange', this.boundHashChange);
            if (typeof window.removeEventListener === 'function') window.removeEventListener('beforeunload', this.boundBeforeUnload);
            window.removeEventListener('resize', this.boundResize);
        }
    }
    // Full-bleed width uses the layout viewport, not 100vw, so a classic scrollbar cannot push the
    // component past the right page boundary. The CSS keeps a 100vw fallback.
    // The Experience page content column can add a small top pad (12px in ng-demo). Because the
    // header is sticky, that pad becomes a visible white/canvas strip above the dark header at the
    // top of the page. Measure it once and pull the component up by exactly that amount.
    syncTopGap() {
        if (this.topGapApplied) return;
        try {
            const host = this.template && this.template.host;
            if (!host || !host.getBoundingClientRect || !host.style) return;
            const top = Math.round(host.getBoundingClientRect().top + (window.scrollY || 0));
            if (top > 0 && top < 64) {
                host.style.setProperty('--ng-top-gap', top + 'px');
                this.topGapApplied = true;
            }
        } catch (error) {
            // Leave the standard layout gap if measurement is unavailable.
        }
    }
    syncViewport() {
        try {
            const width = document.documentElement.clientWidth || window.innerWidth;
            const host = this.template && this.template.host;
            if (host && host.style && width) host.style.setProperty('--ng-viewport', width + 'px');
            // The collapse breakpoint is 47.9375rem; a resize to the desktop header must not leave
            // the mobile panel in an expanded state.
            if (this.menuOpen && typeof window.matchMedia === 'function' && window.matchMedia('(min-width: 48rem)').matches) {
                this.menuOpen = false;
            }
        } catch (error) {
            // Rendering continues with the CSS fallback width.
        }
    }
    currentHash() {
        try { return (window.location && window.location.hash) || ''; } catch (error) { return ''; }
    }
    applyDeepLink() {
        const hash = this.currentHash();
        // In-page anchors (skip link, back to top) must never clear the vehicle detail.
        if (hash === '#buyer-main' || hash === '#top' || hash === '') {
            if (hash === '' && this.selectedVehicleId) {
                const id = new URLSearchParams(window.location.search || '').get('c__vehicle');
                if (!this.isVehicle || id !== this.selectedVehicleId) this.selectedVehicleId = undefined;
            }
            return;
        }
        if (hash.startsWith('#studio')) {
            if (!this.isAll && !this.isStudio) {
                this.goToLegacyTarget(hash);
                return;
            }
            this.selectedVehicleId = undefined;
            this.focusTarget = 'studio';
            return;
        }
        if (!hash.startsWith(VEHICLE_HASH_PREFIX)) {
            // Any other anchor (for example #inventory) leaves the detail view.
            if (this.selectedVehicleId) this.selectedVehicleId = undefined;
            return;
        }
        if (!this.data) return;
        let id;
        try { id = decodeURIComponent(hash.slice(VEHICLE_HASH_PREFIX.length)); }
        catch (error) { this.selectedVehicleId = undefined; return; }
        if (!this.allVehicles.some(vehicle => vehicle.id === id)) {
            this.selectedVehicleId = undefined;
            return;
        }
        if (!this.isAll && !this.isVehicle) {
            this.goToLegacyTarget(hash);
            return;
        }
        if (this.selectedVehicleId !== id) {
            this.selectedVehicleId = id;
            this.focusTarget = 'detail';
        }
    }
    openVehicleHash(id) {
        if (!id) return;
        const hash = VEHICLE_HASH_PREFIX + encodeURIComponent(id);
        try {
            if (this.currentHash() !== hash) window.location.hash = hash;
        } catch (error) {
            // The detail view still opens; only the shareable URL is unavailable.
        }
    }
    // "Join the Priority List" links here with the chosen finish. The request stays an ordinary
    // inquiry; it is never a reservation, allocation, price or purchase commitment.
    // The dedicated vehicle page is reached as buyer-vehicle?c__vehicle=<id>. The id is validated
    // against the public DTO exactly like a hash link; unknown ids resolve to nothing.
    applyVehicleIntent() {
        try {
            const params = new URLSearchParams((window.location && window.location.search) || '');
            const id = params.get('c__vehicle');
            if (!id || !this.data) return;
            if (!this.allVehicles.some(vehicle => vehicle.id === id)) return;
            this.selectedVehicleId = id;
            this.focusTarget = 'detail';
        } catch (error) {
            // A malformed query string simply leaves the vehicle page empty.
        }
    }

    applyInquiryIntent() {
        if (this.hasUnsavedInquiry) return;
        try {
            const params = new URLSearchParams((window.location && window.location.search) || '');
            if (params.get('c__priority') === 'apex') return;
            const type = params.get('c__type');
            const vehicleId = params.get('c__vehicle');
            const config = params.get('c__config');
            if (!type && !config) return;
            if (type === 'Test Drive' || type === 'Purchase Inquiry') this.inquiryType = type;
            if (vehicleId && this.allVehicles.some(vehicle => vehicle.id === vehicleId)) {
                this.inquiryVehicleId = vehicleId;
            }
            if (config) {
                const safeConfig = String(config).replace(/[\r\n]+/g, ' ').replace(/[^A-Za-z0-9 ·\/,\.-]/g, '').slice(0, 120);
                if (!safeConfig) return;
                this.inquiryConfigSummary = safeConfig;
                this.inquiryMessage = 'Preferences: ' + safeConfig + '. Please contact me about this configuration.';
                this.lastAutoMessage = this.inquiryMessage;
            }
            this.inquiryOpen = true;
            this.focusTarget = 'inquiry';
        } catch (error) {
            // Fall back to the empty contact form.
        }
    }

    applyFamilyIntent() {
        try {
            const family = new URLSearchParams((window.location && window.location.search) || '').get('c__family');
            if (family && this.families.some(row => row.value === family)) {
                this.filterFamily = family;
                this.inventoryPage = 1;
            }
        } catch (error) {
            // Ignore malformed query strings.
        }
    }
    applyPriorityIntent(force) {
        if (this.hasUnsavedInquiry) {
            this.inquiryOpen = true;
            this.focusTarget = 'inquiry';
            return;
        }
        try {
            const params = new URLSearchParams((window.location && window.location.search) || '');
            if (!force && params.get('c__priority') !== 'apex') return;
            const finish = force ? this.apexFinish : params.get('c__finish');
            const label = this.finishLabelFor(finish);
            this.inquiryType = 'Purchase Inquiry';
            this.inquiryVehicleId = null;
            this.inquiryConfigSummary = 'Apex Concept · Priority List' + (label ? ' · ' + label : '');
            this.inquiryMessage = 'Priority list — Apex Concept.' + (label ? '\nPreview finish: ' + label + ' (illustrative and unpriced).' : '') + '\n\nThis is interest only: not a reservation, confirmed allocation, price or purchase commitment.';
            this.lastAutoMessage = this.inquiryMessage;
            this.inquiryReference = undefined;
            this.inquiryOpen = true;
            // Never override the page configured in Builder from query parameters.
            this.focusTarget = 'inquiry';
        } catch (error) {
            // A malformed query string simply leaves the standard contact form.
        }
    }
    // A legacy fragment belongs to a different page: navigate there rather than swapping the host
    // page's content, which would leave the configured page in a state it can never return from.
    goToLegacyTarget(hash) {
        if (hash.startsWith('#vehicle-')) {
            const id = hash.slice('#vehicle-'.length);
            if (id) this.navigateTo(this.vehicleUrlFor(decodeURIComponent(id)));
            return true;
        }
        if (hash.startsWith('#studio')) {
            this.navigateTo(this.pageUrl(PAGE_SLUGS.studio));
            return true;
        }
        return false;
    }

    clearVehicleHash() {
        try {
            if (!this.currentHash().startsWith(VEHICLE_HASH_PREFIX)) return;
            const url = window.location.pathname + window.location.search;
            if (window.history && window.history.replaceState) window.history.replaceState(null, '', url);
            else window.location.hash = '';
        } catch (error) {
            // Leaving the stale fragment is harmless.
        }
    }
    /* ---------------------------------------------------------------- page shell */

    // 'all' is the pre-3.0 single-page layout. It is the default so deploying this bundle cannot
    // blank the currently published Buyer page before the six Experience pages exist.
    get isAll() { return this.page === 'all' || !PAGE_SLUGS[this.page]; }
    get isHome() { return this.page === 'home'; }
    get isInventory() { return this.page === 'inventory'; }
    get isVehicle() { return this.page === 'vehicle'; }
    get isStudio() { return this.page === 'studio'; }
    get isAbout() { return this.page === 'about'; }
    get isContact() { return this.page === 'contact'; }
    get showHome() { return this.isAll || this.isHome; }
    get showInventory() { return this.isAll || this.isInventory; }
    get showVehicle() { return this.isAll || this.isVehicle; }
    get showStudio() { return this.isAll || this.isStudio; }
    get showAbout() { return this.isAll || this.isAbout; }
    // The inquiry form stays in place on every page that can start one, so a typed draft is never
    // destroyed by navigating away. It opens on demand outside the contact page.
    get inquiryPanelVisible() {
        if (this.isAll || this.isContact) return true;
        return (this.isVehicle || this.isStudio) && this.inquiryOpen;
    }
    get heroClass() { return this.showHome ? 'hero' : 'hero is-page'; }
    // A dedicated vehicle page already shows the title in its banner; keep the heading for
    // focus/AT but do not repeat it visually.
    get detailHeadingClass() { return this.isVehicle ? 'sr-only' : ''; }
    get pageEyebrow() { return (PAGE_COPY[this.page] || PAGE_COPY.home).eyebrow; }
    get pageLede() { return (PAGE_COPY[this.page] || PAGE_COPY.home).lede; }
    get pageHeading() {
        if (this.isVehicle && this.selectedVehicle) return this.selectedVehicle.title;
        return (PAGE_COPY[this.page] || PAGE_COPY.home).heading;
    }
    get pageLedeSafe() { return this.pageLede; }
    get noVehicleSelected() { return this.isVehicle && !this.selectedVehicle; }
    get homeCurrent() { return this.isHome ? 'page' : null; }
    get inventoryCurrent() { return this.isInventory ? 'page' : null; }
    get studioCurrent() { return this.isStudio ? 'page' : null; }
    get aboutCurrent() { return this.isAbout ? 'page' : null; }
    get contactCurrent() { return this.isContact ? 'page' : null; }

    // Experience pages are separate URLs; the /s/ prefix is preserved so links work in-site.
    pageUrl(slug) {
        try {
            const match = (window.location.pathname || '').match(/^(.*\/s\/)/);
            const base = match ? match[1] : '/';
            return base + (slug || '');
        } catch (error) {
            return '/' + (slug || '');
        }
    }
    // Legacy single-page mode keeps the accepted in-page anchors; dedicated pages use real URLs.
    navHref(name, anchor) {
        return this.isAll ? anchor : this.pageUrl(PAGE_SLUGS[name]);
    }
    get homeUrl() { return this.isAll ? '#top' : this.pageUrl(PAGE_SLUGS.home); }
    get inventoryUrl() { return this.navHref('inventory', '#inventory'); }
    get studioUrl() { return this.navHref('studio', '#studio'); }
    get aboutUrl() { return this.navHref('about', '#why'); }
    get contactUrl() { return this.navHref('contact', '#inquiry'); }
    get portalUrl() { return this.pageUrl(''); }
    vehicleUrlFor(id) {
        return this.pageUrl(PAGE_SLUGS.vehicle) + '?c__vehicle=' + encodeURIComponent(id);
    }
    finishLabelFor(value) {
        if (!['carmine', 'pearl', 'graphite'].includes(value)) return '';
        return ({ carmine: 'Carmine', pearl: 'Pearl', graphite: 'Graphite' })[value];
    }
    handleApexFinish(event) {
        const finish = event.detail && event.detail.finish;
        if (['carmine', 'pearl', 'graphite'].includes(finish)) this.apexFinish = finish;
    }
    get priorityUrl() {
        const finish = this.finishLabelFor(this.apexFinish) ? '&c__finish=' + this.apexFinish : '';
        return this.isAll ? '#inquiry' : this.contactUrl + '?c__priority=apex' + finish;
    }
    isModifiedActivation(event) {
        // Ctrl/Cmd/Shift/Alt-click and middle-click must keep native new-tab behaviour.
        if (!event) return false;
        return Boolean(event.metaKey || event.ctrlKey || event.shiftKey || event.altKey
            || (typeof event.button === 'number' && event.button !== 0));
    }
    startPriorityInterest(event) {
        // Open in place, including dedicated Studio, so drafts and terminal warnings survive.
        if (this.isModifiedActivation(event)) return;
        if (event && typeof event.preventDefault === 'function') event.preventDefault();
        this.applyPriorityIntent(true);
        this.focusTarget = 'inquiry';
    }
    navigateTo(url) {
        try {
            if (url && typeof window !== 'undefined' && window.location && typeof window.location.assign === 'function') {
                window.location.assign(url);
            }
        } catch (error) {
            // Navigation failure leaves the current page usable.
        }
    }

    get menuExpanded() { return this.menuOpen ? 'true' : 'false'; }
    get menuLabel() { return this.menuOpen ? 'Close menu' : 'Menu'; }
    get navigationClass() { return this.menuOpen ? 'buyer-nav is-open' : 'buyer-nav'; }
    toggleMenu() { this.menuOpen = !this.menuOpen; }
    closeMenu() { this.menuOpen = false; }
    handleKeydown(event) {
        if (event.key !== 'Escape' || !this.menuOpen) return;
        this.menuOpen = false;
        const toggle = this.template && this.template.querySelector('[data-menu-toggle]');
        if (toggle) toggle.focus();
    }
    async loadShowcase() {
        this.loading = true; this.loadError = undefined;
        try {
            const data = await getShowcase();
            this.data = data;
        } catch (error) {
            this.loadError = (error.body && error.body.message) || 'Inventory is unavailable right now. Please try again.';
        } finally { this.loading = false; }
    }

    get models() { return this.data ? this.data.models : []; }
    get allVehicles() { return this.data ? this.data.vehicles : []; }
    get hasInventory() { return this.allVehicles.length > 0; }
    get availableCount() { return this.data ? this.data.availableCount : 0; }
    get modelCount() { return this.models.length; }
    get heroImage() {
        if (this.heroFailed) return null;
        const model = this.models.find(item => item.imageName);
        return model ? this.imageUrl(model.imageName) : null;
    }
    get heroImageName() {
        const model = this.models.find(item => item.imageName);
        return model ? model.imageName : null;
    }
    imageUrl(name) { return name ? `${NG_VEHICLE_IMAGES}/${name}` : null; }
    siteImageUrl(name) {
        const match = window.location.pathname.match(/^(.*\/s\/)/);
        const base = match ? match[1] : '/owners/s/';
        return name ? `${base}sfsites/c/resource/NG_VehicleImages/${name}` : null;
    }
    get heroStats() {
        return [
            { value: this.availableCount, label: 'vehicles available' },
            { value: this.modelCount, label: 'models in the showroom' },
            { value: this.priceFromLabel, label: 'starting from' }
        ];
    }
    get priceFromLabel() {
        const prices = this.allVehicles.filter(vehicle => vehicle.available && vehicle.price !== null).map(vehicle => vehicle.price);
        return prices.length ? CURRENCY.format(Math.min(...prices)) : 'Price on request';
    }
    // Model is a trim of one family, so the dropdown follows the selected family. Offering every
    // model regardless of family lets the two dependent filters combine into a guaranteed-empty
    // result (family Aurelia + model Cascadia = 0) with no signal to the buyer.
    get modelOptions() {
        const models = this.filterFamily
            ? this.models.filter(model => this.familyKey(model) === this.filterFamily)
            : this.models;
        return this.options(models.map(model => ({ label: model.title, value: model.id })), 'All models');
    }
    get bodyOptions() { return this.options(this.data ? this.data.bodyStyles : [], 'All body styles'); }
    get colourOptions() { return this.options(this.data ? this.data.colours : [], 'All colours'); }
    get conditionOptions() { return this.options(this.data ? this.data.conditions : [], 'All conditions'); }
    options(rows, allLabel) {
        return [{ label: allLabel, value: '' }].concat(rows.map(row => ({ label: row.label, value: row.value })));
    }
    get filteredVehicles() {
        const max = this.maxPrice === '' ? null : Number(this.maxPrice);
        return this.allVehicles
            .filter(vehicle => !this.filterFamily || this.familyOf(vehicle) === this.filterFamily)
            .filter(vehicle => !this.filterModel || vehicle.modelId === this.filterModel)
            .filter(vehicle => !this.filterBody || vehicle.bodyStyle === this.filterBody)
            .filter(vehicle => !this.filterColour || vehicle.colour === this.filterColour)
            .filter(vehicle => !this.filterCondition || vehicle.conditionLabel === this.filterCondition)
            .filter(vehicle => max === null || vehicle.price === null || vehicle.price <= max)
            .map(vehicle => this.card(vehicle));
    }
    get inventoryPageCount() { return Math.max(1, Math.ceil(this.filteredVehicles.length / 12)); }
    get visibleVehicles() { return this.filteredVehicles.slice((this.inventoryPage - 1) * 12, this.inventoryPage * 12); }
    get showPagination() { return this.inventoryPageCount > 1; }
    get firstInventoryPage() { return this.inventoryPage <= 1; }
    get lastInventoryPage() { return this.inventoryPage >= this.inventoryPageCount; }
    get inventoryPageLabel() { return 'Page ' + this.inventoryPage + ' of ' + this.inventoryPageCount; }
    previousInventoryPage() {
        if (!this.firstInventoryPage) this.inventoryPage -= 1;
        this.focusTarget = 'inventory';
    }
    nextInventoryPage() {
        if (!this.lastInventoryPage) this.inventoryPage += 1;
        this.focusTarget = 'inventory';
    }
    get noVehicles() { return Boolean(this.data) && this.filteredVehicles.length === 0; }
    get noInventory() { return Boolean(this.data) && !this.loading && !this.loadError && this.allVehicles.length === 0; }
    get resultLabel() {
        const count = this.filteredVehicles.length;
        return count === 1 ? '1 vehicle' : count + ' vehicles';
    }
    get hasActiveFilters() {
        return Boolean(this.filterFamily || this.filterModel || this.filterBody || this.filterColour || this.filterCondition || this.maxPrice !== '');
    }
    // Clear is available only when there is something to clear.
    get clearDisabled() { return !this.hasActiveFilters; }
    get activeFilterCount() {
        const selected = [this.filterFamily, this.filterModel, this.filterBody, this.filterColour, this.filterCondition].filter(Boolean).length;
        return selected + (this.maxPrice !== '' ? 1 : 0);
    }
    get filtersExpanded() { return this.filtersOpen ? 'true' : 'false'; }
    get filtersPanelClass() { return this.filtersOpen ? 'filters is-open' : 'filters'; }
    get filterSummary() {
        const count = this.activeFilterCount;
        if (count) return count + (count === 1 ? ' filter active' : ' filters active');
        return 'Model, body, colour or price';
    }
    toggleFilters() { this.filtersOpen = !this.filtersOpen; }
    card(vehicle) {
        const failed = this.failedImages.includes(vehicle.id);
        return { ...vehicle,
            imagePath: failed ? null : this.imageUrl(vehicle.imageName),
            priceLabel: vehicle.price === null ? 'Price on request' : CURRENCY.format(vehicle.price),
            mileageLabel: vehicle.odometer === null ? null : NUMBER.format(vehicle.odometer) + ' km',
            photoAlt: 'Representative ' + vehicle.modelTitle + ' photo',
            detailLabel: 'View details for ' + vehicle.title,
            statusClass: 'status status-' + (vehicle.status || '').toLowerCase(),
            availabilityNote: this.availabilityNote(vehicle.status),
            availabilityClass: 'vehicle-availability is-' + (vehicle.status || 'unknown').toLowerCase(),
            canTestDrive: vehicle.available
        };
    }
    // Availability wording is derived only from the recorded status; it promises nothing beyond it.
    availabilityNote(status) {
        if (status === 'Available') return 'Available now';
        if (status === 'Reserved') return 'Reserved · ask about similar';
        if (status === 'In_Transit') return 'In transit · ask for timing';
        return 'Contact us for availability';
    }
    get selectedVehicle() {
        const vehicle = this.allVehicles.find(item => item.id === this.selectedVehicleId);
        return vehicle ? this.card(vehicle) : null;
    }
    get detailSpecs() {
        const vehicle = this.selectedVehicle;
        if (!vehicle) return [];
        const specs = [
            { label: 'Year', value: vehicle.year },
            { label: 'Model', value: vehicle.modelTitle },
            { label: 'Body style', value: vehicle.bodyStyle },
            { label: 'Colour', value: vehicle.colour },
            { label: 'Condition', value: vehicle.conditionLabel },
            { label: 'Odometer', value: vehicle.mileageLabel },
            { label: 'Stock number', value: vehicle.stockNumber }
        ];
        return specs.filter(item => item.value !== null && item.value !== undefined && item.value !== '');
    }
    familyKey(model) {
        // A family is the model line (Aurelia, Cascadia, …), never the make: every model shares
        // the Northgate make, so keying by make collapsed the entire range into one card.
        const raw = (model && (model.model || model.make || model.title)) || 'northgate';
        return String(raw).toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '') || 'northgate';
    }
    get families() {
        const seen = new Map();
        this.models.forEach(model => {
            const key = this.familyKey(model);
            if (!seen.has(key)) seen.set(key, { value: key, label: model.model || model.make || model.title });
        });
        return [...seen.values()];
    }
    get familyOptions() { return this.options(this.families, 'All families'); }
    familyOf(vehicle) {
        const model = this.models.find(item => item.id === vehicle.modelId);
        return model ? this.familyKey(model) : '';
    }
    // Home discovery grid: one card per model family. It opens the 3D Studio; it is not a configurator.
    get familyCards() {
        const groups = new Map();
        this.models.forEach(model => {
            const key = this.familyKey(model);
            if (!groups.has(key)) groups.set(key, { key, title: model.model || model.make || model.title, models: [], imageName: null });
            const group = groups.get(key);
            group.models.push(model);
            if (!group.imageName && model.imageName) group.imageName = model.imageName;
        });
        return [...groups.values()].map(group => {
            const ids = new Set(group.models.map(model => model.id));
            const vehicles = this.allVehicles.filter(vehicle => ids.has(vehicle.modelId));
            // Match the inventory "from" basis: only purchasable listings set the family price.
            const prices = vehicles.filter(vehicle => vehicle.available && vehicle.price !== null).map(vehicle => vehicle.price);
            const fromPrice = prices.length ? Math.min(...prices) : null;
            return {
                ...group,
                count: vehicles.length,
                fromPrice,
                imagePath: group.imageName && !this.failedFamilyImages.includes(group.key) ? this.imageUrl(group.imageName) : null,
                priceLabel: fromPrice === null ? 'Price on request' : 'From ' + CURRENCY.format(fromPrice),
                meta: vehicles.length === 1 ? '1 listed' : vehicles.length + ' listed',
                ariaLabel: 'View ' + group.title + ' inventory',
                photoAlt: 'Representative ' + group.title + ' photo'
            };
        });
    }

    get inquiryVehicle() {
        const vehicle = this.allVehicles.find(item => item.id === this.inquiryVehicleId);
        return vehicle ? this.card(vehicle) : null;
    }
    get isTestDrive() { return this.inquiryType === 'Test Drive'; }
    get submitLabel() { return this.isTestDrive ? 'Request a test drive' : 'Send inquiry'; }
    get submitButtonLabel() { return this.submitting ? 'Sending…' : this.submitLabel; }

    // A draft, an in-flight submission or an unconfirmed outcome must not disappear silently when
    // the visitor follows a link. The browser prompt is the only reliable guard across pages.
    get hasUnsavedInquiry() {
        if (this.inquiryReference) return false;
        if (this.submitting || this.inquiryUnconfirmed) return true;
        const typed = (this.inquiryMessage || '').trim();
        const autoOnly = typed && this.lastAutoMessage && typed === this.lastAutoMessage.trim();
        return Boolean((this.inquiryName || '').trim() || (this.inquiryEmail || '').trim()
            || (this.inquiryPhone || '').trim() || (typed && !autoOnly));
    }
    get inquirySuccessNote() {
        return this.isTestDrive
            ? 'Your test drive request is with Northgate sales. This is a request, not a confirmed appointment — a specialist will contact you to arrange a time. No vehicle is reserved.'
            : 'A Northgate specialist will be in touch. This is an inquiry, not a reservation.';
    }
    get inquiryVehicleLabel() { return this.inquiryVehicle ? this.inquiryVehicle.title + ' · ' + this.inquiryVehicle.stockNumber : 'No specific vehicle'; }
    // Defensive: normal UI only offers Test Drive after resolving a listed vehicle, and the
    // server revalidates. A stale/delisted id is still blocked here before any Apex call.
    get testDriveNeedsVehicle() { return this.isTestDrive && !this.inquiryVehicle; }
    get canSubmit() { return Boolean(this.consent) && !this.submitting && !this.inquiryUnconfirmed && !this.testDriveNeedsVehicle; }
    get selectedUnavailable() { return Boolean(this.selectedVehicle) && !this.selectedVehicle.available; }
    get testDriveDisabled() { return Boolean(this.selectedVehicle) && !this.selectedVehicle.canTestDrive; }
    get inquiryTypeOptions() {
        const options = [{ label: 'Purchase inquiry', value: 'Purchase Inquiry' }];
        // Keep the current Test Drive choice visible even if its vehicle is no longer resolved, so
        // the guard explains the requirement instead of silently reverting the selection.
        if (this.inquiryVehicleId || this.inquiryType === 'Test Drive') {
            options.unshift({ label: 'Test Drive request', value: 'Test Drive' });
        }
        // Selection is derived from the single inquiryType field, so a CTA, navigation or manual
        // change cannot leave the visible option disagreeing with the submitted requestType.
        return options.map(option => ({ ...option, selected: option.value === this.inquiryType }));
    }
    get submitDisabled() { return !this.canSubmit; }

    modelBelongsToFamily(modelId, family) {
        if (!modelId || !family) return false;
        return this.models.some(model => model.id === modelId && this.familyKey(model) === family);
    }
    setFamily(family) {
        this.filterFamily = family || '';
        this.inventoryPage = 1;
        // A model selection from a different family can never match, so drop it rather than
        // letting the dependent filters dead-end at 0 vehicles.
        if (this.filterFamily && this.filterModel && !this.modelBelongsToFamily(this.filterModel, this.filterFamily)) {
            this.filterModel = '';
        }
    }
    handleFilter(event) {
        const filter = event.target.dataset.filter;
        if (!filter) return;
        if (filter === 'filterFamily') {
            this.setFamily(event.target.value);
            return;
        }
        this.inventoryPage = 1;
        this[filter] = event.target.value;
    }
    clearFilters() {
        this.inventoryPage = 1;
        this.filterModel = ''; this.filterFamily = ''; this.filterBody = ''; this.filterColour = '';
        this.filterCondition = ''; this.maxPrice = '';
    }
    viewVehicle(event) {
        this.selectedVehicleId = event.currentTarget.dataset.vehicleId;
        this.openVehicleHash(this.selectedVehicleId);
        this.focusTarget = 'detail';
        if (!this.isAll && !this.isVehicle && !this.isHome && this.selectedVehicleId) {
            this.navigateTo(this.vehicleUrlFor(this.selectedVehicleId));
        }
    }
    closeDetail() {
        this.selectedVehicleId = undefined;
        this.clearVehicleHash();
        this.focusTarget = 'inventory';
    }
    openFamily(event) {
        const family = event && event.currentTarget && event.currentTarget.dataset ? event.currentTarget.dataset.family : '';
        if (!family) return;
        if (event && typeof event.preventDefault === 'function') event.preventDefault();
        this.setFamily(family);
        this.selectedVehicleId = undefined;
        if (!this.isAll) {
            this.navigateTo(this.inventoryUrl + '?c__family=' + encodeURIComponent(family));
            return;
        }
        this.focusTarget = 'inventory';
        this.scrollToInventory();
    }
    scrollToInventory() {
        const target = this.template && this.template.querySelector('[data-inventory]');
        const reduce = typeof window.matchMedia === 'function' && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
        if (target) target.scrollIntoView({ behavior: reduce ? 'auto' : 'smooth', block: 'start' });
        const heading = this.template && this.template.querySelector('[data-inventory-heading]');
        if (heading) heading.focus();
    }
    openStudio(event) {
        if (event && typeof event.preventDefault === 'function') event.preventDefault();
        if (!this.isAll) {
            this.navigateTo(this.studioUrl);
            return;
        }
        this.selectedVehicleId = undefined;
        this.focusTarget = 'studio';
        this.scrollToStudio();
    }
    scrollToStudio() {
        const target = this.template && this.template.querySelector('[data-studio]');
        const reduce = typeof window.matchMedia === 'function' && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
        if (target) target.scrollIntoView({ behavior: reduce ? 'auto' : 'smooth', block: 'start' });
        const heading = this.template && this.template.querySelector('[data-studio-heading]');
        if (heading) heading.focus();
    }
    startInquiry(event) {
        this.inquiryType = event.currentTarget.dataset.type || 'Purchase Inquiry';
        const vehicleId = event.currentTarget.dataset.vehicleId || this.selectedVehicleId || this.inquiryVehicleId;
        this.inquiryVehicleId = vehicleId || null;
        this.inquiryConfigSummary = '';
        this.inquiryOpen = true; this.menuOpen = false; this.inquiryError = undefined; this.inquiryReference = undefined;
        this.focusTarget = 'inquiry';
    }
    startGeneralInquiry() {
        this.inquiryType = 'Purchase Inquiry'; this.inquiryVehicleId = null;
        this.inquiryConfigSummary = '';
        this.inquiryOpen = true; this.menuOpen = false; this.inquiryError = undefined; this.inquiryReference = undefined;
        this.focusTarget = 'inquiry';
    }
    // An unconfirmed submission must survive every navigation CTA; only this explicit
    // acknowledgement clears the "do not send it again" warning.
    acknowledgeUnconfirmed() {
        this.inquiryUnconfirmed = false; this.inquiryError = undefined; this.inquiryReference = undefined;
        this.focusTarget = 'inquiry';
    }
    closeInquiry() { this.inquiryOpen = false; this.inquiryError = undefined; }
    handleInquiryInput(event) {
        const field = event.target.dataset.field;
        if (field) this[field] = event.target.value;
    }
    handleConsent(event) { this.consent = event.target.checked; }
    async submitInquiry() {
        if (!this.canSubmit) return;
        this.submitting = true; this.inquiryError = undefined; this.inquiryReference = undefined;
        try {
            // The Aura action can stay pending after the Lead has already been inserted. Never leave
            // the form on “Sending…” indefinitely, and never retry automatically (that would create a
            // duplicate Lead). A timeout produces an explicit, terminal “may already be received”
            // state; a late server response is ignored because the race has already settled.
            const call = submitBuyerInquiry({
                name: this.inquiryName.trim(),
                email: this.inquiryEmail.trim(),
                phone: this.inquiryPhone.trim(),
                message: this.inquiryMessage.trim(),
                vehicleId: this.inquiryVehicleId || null,
                requestType: this.inquiryType
            });
            const timeout = new Promise((resolve, reject) => {
                this.submitTimer = setTimeout(() => reject(Object.assign(new Error('submit-timeout'), { name: 'SubmitTimeout' })), this.submitTimeoutMs);
            });
            const reference = await Promise.race([call, timeout]);
            this.inquiryReference = reference;
            this.inquiryName = ''; this.inquiryEmail = ''; this.inquiryPhone = '';
            this.inquiryMessage = ''; this.consent = false;
        } catch (error) {
            if (error && error.name === 'SubmitTimeout') {
                this.inquiryUnconfirmed = true;
            } else {
                this.inquiryError = (error.body && error.body.message) || 'Your request could not be submitted. Please try again.';
            }
        } finally {
            if (this.submitTimer) { clearTimeout(this.submitTimer); this.submitTimer = null; }
            this.submitting = false;
        }
    }
    imageError(event) {
        const img = event.target;
        // One cross-browser retry on the site-scoped static-resource path. Safari can reject the
        // shorter /owners/resource form in some cached sessions; both resolve to the same asset.
        if (!img.dataset.retried && img.dataset.imageName) {
            img.dataset.retried = '1';
            img.src = this.siteImageUrl(img.dataset.imageName);
            return;
        }
        const kind = img.dataset.kind;
        if (kind === 'family') {
            const key = img.dataset.id;
            if (key) this.failedFamilyImages = [...new Set([...this.failedFamilyImages, key])];
            return;
        }
        if (kind === 'preview') { this.previewFailed = true; return; }
        const id = img.dataset.id;
        if (id === 'hero') { this.heroFailed = true; return; }
        if (id) this.failedImages = [...new Set([...this.failedImages, id])];
    }
    renderedCallback() {
        this.syncViewport();
        this.syncTopGap();
        // Native select options can keep a stale selection when the option set changes. Re-assert
        // the one reactive source after render so the control always matches inquiryType.
        const typeSelect = this.template.querySelector('[data-field="inquiryType"]');
        if (typeSelect && typeSelect.value !== this.inquiryType) typeSelect.value = this.inquiryType;
        // Filter controls are state-driven too: a family card or Clear filters changes the state
        // without a user interaction on the <select>, and a native select keeps its old selection
        // when only the value attribute changes.
        [['filterFamily', this.filterFamily], ['filterModel', this.filterModel], ['filterBody', this.filterBody],
            ['filterColour', this.filterColour], ['filterCondition', this.filterCondition], ['maxPrice', this.maxPrice]]
            .forEach(([field, value]) => {
                const control = this.template.querySelector(`[data-filter="${field}"]`);
                if (control && control.value !== value) control.value = value;
            });
        // A prefilled <textarea> needs its DOM property set; changing the value attribute alone does
        // not update what the buyer sees. Never fight the field while it is focused.
        const message = this.template.querySelector('[data-field="inquiryMessage"]');
        if (message && this.template.activeElement !== message && message.value !== this.inquiryMessage) {
            message.value = this.inquiryMessage;
        }
        if (this.focusTarget === 'detail') {
            const heading = this.template.querySelector('[data-detail-heading]');
            if (heading) { heading.focus(); this.focusTarget = undefined; }
        } else if (this.focusTarget === 'inquiry') {
            // Terminal states (received / unconfirmed) replace the form, so fall back to the
            // alert or status region instead of leaving focus on the Studio call to action.
            const field = this.template.querySelector('[data-inquiry-name]') || this.template.querySelector('[data-inquiry-focus]');
            if (field) { field.focus(); this.focusTarget = undefined; }
        } else if (this.focusTarget === 'inventory') {
            const heading = this.template.querySelector('[data-inventory-heading]');
            if (heading) { heading.focus(); this.focusTarget = undefined; }
        } else if (this.focusTarget === 'studio') {
            const heading = this.template.querySelector('[data-studio-heading]');
            if (heading) { heading.focus(); this.focusTarget = undefined; }
        }
    }
}
