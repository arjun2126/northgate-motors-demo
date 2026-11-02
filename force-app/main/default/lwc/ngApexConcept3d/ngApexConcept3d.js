/**
 * Northgate Apex Concept — Experience Cloud 3D viewer (integration candidate).
 *
 * Desktop-first progressive enhancement:
 *  - the poster and concept details render immediately (no JavaScript required);
 *  - interactive 3D starts automatically only on a capable, non-touch desktop;
 *  - touch and low-core devices keep the static preview and can opt in explicitly;
 *  - any failure falls back to the static preview instead of a blank stage.
 *
 * Boundaries: no Apex, no DML, no customer data, no price/availability claim, no external URL.
 * LWS/CSP: three.js is a static-resource bundle loaded with lightning/platformResourceLoader; no eval,
 * no import maps, no inline script, no third-party host.
 */
import { LightningElement, api } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import VIEWER_RESOURCE from '@salesforce/resourceUrl/apexConceptViewer';
import MODEL_RESOURCE from '@salesforce/resourceUrl/apexConceptModel';

// Zipped static resource: the glTF references its .bin and textures relatively, so every request
// stays same-origin. Embedding textures in a GLB forces blob: URLs, which a strict CSP blocks.
const MODEL_URL = `${MODEL_RESOURCE}/model.gltf`;
import POSTER_RESOURCE from '@salesforce/resourceUrl/apexConceptPoster';

const FINISHES = {
    carmine: {
        label: 'Carmine',
        description: 'Carmine — deep metallic red with a warm highlight. Illustrative and unpriced.'
    },
    pearl: {
        label: 'Pearl',
        description: 'Pearl — warm off-white with a soft metallic sheen. Illustrative and unpriced.'
    },
    graphite: {
        label: 'Graphite',
        description: 'Graphite — dark satin grey with restrained reflections. Illustrative and unpriced.'
    }
};

const CAMERA = {
    left: [0.32, 0],
    right: [-0.32, 0],
    up: [0, -0.1],
    down: [0, 0.1]
};

export default class NgApexConcept3d extends LightningElement {
    /** Optional override for the inquiry destination; defaults to the Buyer contact section. */
    @api inquiryUrl;
    /** Host pages that own the priority action themselves hide the built-in concept CTA. */
    @api hideInquiry = false;

    /**
     * Admins can force the static preview. Boolean @api properties must default to false in LWC
     * (LWC1099), so the opt-out is expressed positively instead of defaulting auto-load to true.
     */
    @api forceStaticPreview = false;

    mode = 'static';
    statusText = 'Static preview.';
    announcement = '';
    finish = 'carmine';
    posterUrl = POSTER_RESOURCE;

    _viewer;
    _starting = false;
    _disconnected = false;
    _can3d = false;
    _coarse = false;
    _autoEligible = false;
    _reduced = false;
    _resolvedInquiryUrl = '';
    _viewerMetrics;

    /* ------------------------------------------------------------------ lifecycle */

    connectedCallback() {
        this.notifyFinish();
        this._detectCapability();
        this._resolvedInquiryUrl = this._resolveInquiryUrl();

        if (!this._can3d) {
            this.mode = 'static';
            this.statusText = '3D preview is not available in this browser. Showing a still preview.';
            return;
        }
        if (this._autoEligible) {
            this.startViewer();
        } else {
            this.mode = 'static';
            this.statusText = 'Tap “Load interactive 3D” to explore this concept.';
        }
    }

    disconnectedCallback() {
        this._disconnected = true;
        this._disposeViewer();
    }

    /* -------------------------------------------------------------------- getters */

    get showPoster() { return this.mode !== 'interactive'; }

    get showScrim() { return this.mode === 'loading'; }

    get startLabel() { return this.mode === 'error' ? 'Try 3D again' : 'Load interactive 3D'; }

    get showError() { return this.mode === 'error'; }

    get isInteractive() { return this.mode === 'interactive'; }

    get notInteractive() { return !this.isInteractive; }

    get showStartButton() {
        // Opt-in for non-auto devices, and retry after a failure. forceStaticPreview disables both.
        return this._can3d
            && !this.forceStaticPreview
            && !this._starting
            && (this.mode === 'static' || this.mode === 'error');
    }

    get captionText() {
        return this.isInteractive
            ? 'Interactive concept preview · not a vehicle in inventory'
            : 'Concept preview · not a vehicle in inventory';
    }

    get finishLabel() { return FINISHES[this.finish].label; }

    get finishDescription() { return FINISHES[this.finish].description; }

    get carminePressed() { return String(this.finish === 'carmine'); }
    get pearlPressed() { return String(this.finish === 'pearl'); }
    get graphitePressed() { return String(this.finish === 'graphite'); }
    get carmineClass() { return this.finish === 'carmine' ? 'apex-finish is-selected' : 'apex-finish'; }
    get pearlClass() { return this.finish === 'pearl' ? 'apex-finish is-selected' : 'apex-finish'; }
    get graphiteClass() { return this.finish === 'graphite' ? 'apex-finish is-selected' : 'apex-finish'; }

    get hasInquiryUrl() { return !this.hideInquiry && Boolean(this.effectiveInquiryUrl); }

    get effectiveInquiryUrl() {
        const configured = (this.inquiryUrl || '').trim();
        // '#inquiry' is the designer placeholder, not a real destination on another page.
        if (configured && configured !== '#inquiry') return configured;
        return this._resolvedInquiryUrl;
    }

    /* ---------------------------------------------------------------- capability */

    _detectCapability() {
        try {
            const probe = document.createElement('canvas');
            this._can3d = Boolean(probe.getContext('webgl2'));
        } catch (error) {
            this._can3d = false;
        }

        try {
            const view = window;
            this._coarse = typeof view.matchMedia === 'function'
                ? view.matchMedia('(pointer: coarse)').matches
                : false;
            this._reduced = typeof view.matchMedia === 'function'
                ? view.matchMedia('(prefers-reduced-motion: reduce)').matches
                : false;
            const connection = view.navigator && view.navigator.connection;
            const saveData = Boolean(connection && connection.saveData);
            const cores = (view.navigator && view.navigator.hardwareConcurrency) || 4;
            const memory = (view.navigator && view.navigator.deviceMemory) || 4;
            this._autoEligible = Boolean(
                !this.forceStaticPreview
                && this._can3d
                && !this._coarse
                && !saveData
                && cores >= 4
                && memory >= 4
            );
        } catch (error) {
            this._autoEligible = false;
        }
    }

    _resolveInquiryUrl() {
        try {
            const path = window.location.pathname;
            const match = path.match(/^(.*\/s\/)/);
            const base = match ? match[1] : '/';
            return `${base}buyer#inquiry`;
        } catch (error) {
            return '#inquiry';
        }
    }

    /* -------------------------------------------------------------------- actions */

    async startViewer() {
        if (this._starting || this._viewer || !this._can3d) return;
        this._starting = true;
        this.mode = 'loading';
        this.statusText = 'Loading interactive 3D…';

        try {
            await loadScript(this, VIEWER_RESOURCE);
            // The component can be removed while the script loads; never build on a detached host.
            if (this._disconnected) return;
            const bundle = this._resolveBundle();
            if (!bundle || typeof bundle.createViewer !== 'function') {
                throw new Error('3D bundle did not initialise');
            }
            const host = this.template.querySelector('[data-canvas-host]');
            if (!host) throw new Error('3D stage is unavailable');

            let failedDuringCreate = false;
            const viewer = bundle.createViewer(host, {
                modelUrl: MODEL_URL,
                canvasLabel: 'Interactive 3D concept car. Use the arrow keys to rotate, plus and minus to zoom, or the camera buttons.',
                initialFinish: this.finish,
                touchEnabled: true,
                onStatus: (name, text) => this._onViewerStatus(name, text),
                onReady: metrics => {
                    this._viewerMetrics = metrics;
                    this._starting = false;
                },
                onError: () => {
                    // Construction can fail synchronously; record it so the caller can clean up.
                    failedDuringCreate = true;
                    this._starting = false;
                },
                onAnnounce: text => { this.announcement = text; }
            });

            if (this._disconnected || failedDuringCreate) {
                if (viewer && typeof viewer.dispose === 'function') viewer.dispose();
                return;
            }
            this._viewer = viewer;
        } catch (error) {
            this._starting = false;
            this._fail('The interactive preview could not start. Showing the still preview.');
            // eslint-disable-next-line no-console
            console.error('[apex-concept] viewer start failed', error);
        }
    }

    _resolveBundle() {
        // LWS may sandbox globals; check both the virtual window and globalThis without assuming either.
        try {
            if (typeof window !== 'undefined' && window.ApexConceptViewer) return window.ApexConceptViewer;
            if (typeof globalThis !== 'undefined' && globalThis.ApexConceptViewer) return globalThis.ApexConceptViewer;
        } catch (error) {
            return null;
        }
        return null;
    }

    _onViewerStatus(name, text) {
        if (name === 'ready') {
            this.mode = 'interactive';
            this.statusText = text || 'Interactive 3D ready.';
            this.announcement = 'Interactive 3D concept preview ready.';
        } else if (name === 'error') {
            this._fail(text || 'The 3D preview stopped.');
        }
    }

    _fail(message) {
        this.mode = 'error';
        this.statusText = message;
        this.announcement = message;
        this._disposeViewer();
        Promise.resolve().then(() => {
            const target = this.template && this.template.querySelector('.apex-error');
            if (target && typeof target.focus === 'function') target.focus();
        });
    }

    _disposeViewer() {
        if (this._viewer && typeof this._viewer.dispose === 'function') {
            try {
                this._viewer.dispose();
            } catch (error) {
                // Disposal is best effort; never block teardown on it.
            }
        }
        this._viewer = undefined;
    }

    handleStart() {
        this.startViewer();
    }

    handleCamera(event) {
        if (!this._viewer) return;
        const action = event.currentTarget.dataset.cam;
        if (action === 'reset') this._viewer.reset();
        else if (action === 'zoom-in') this._viewer.zoomBy(0.85);
        else if (action === 'zoom-out') this._viewer.zoomBy(1.18);
        else if (CAMERA[action]) this._viewer.rotateBy(CAMERA[action][0], CAMERA[action][1]);
    }

    handleView(event) {
        if (!this._viewer) return;
        this._viewer.setView(event.currentTarget.dataset.view);
    }

    handleFinish(event) {
        const next = event.currentTarget.dataset.finish;
        if (!FINISHES[next]) return;
        this.finish = next;
        this.notifyFinish();
        const applied = this._viewer ? this._viewer.setFinish(next) : false;
        this.announcement = applied
            ? `${FINISHES[next].label} finish applied. Illustrative and unpriced.`
            : `${FINISHES[next].label} selected; it will apply when the 3D preview loads.`;
    }
    notifyFinish() {
        this.dispatchEvent(new CustomEvent('finishchange', { detail: { finish: this.finish } }));
    }
    handleInquiry(event) {
        // A hosting Buyer page can preserve its draft by opening the inquiry in place.
        // Standalone Builder placements retain their explicitly configured link destination.
        // Modified/new-tab clicks always keep native link behaviour.
        if (event && (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey
            || (typeof event.button === 'number' && event.button !== 0))) return;
        if (!this.dispatchEvent(new CustomEvent('conceptinterest', { cancelable: true }))) event.preventDefault();
    }
}
