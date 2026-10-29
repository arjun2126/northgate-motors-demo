/**
 * Deterministic PRNG helpers for the Northgate Motors generator.
 * - mulberry32: small fast 32-bit PRNG, deterministic given a seed.
 * - stringHash: maps a string to a 32-bit unsigned int (FNV-1a).
 * - uuidFromSeed: builds a deterministic pseudo-UUID for fields like Member_Number__c.
 * - dateRange: helper to advance a Date by N days.
 */

export function stringHash(s: string): number {
    let h = 0x811c9dc5;
    for (let i = 0; i < s.length; i++) {
        h ^= s.charCodeAt(i);
        h = Math.imul(h, 0x01000193);
    }
    return h >>> 0;
}

export function mulberry32(seed: number): () => number {
    let a = seed >>> 0;
    return function () {
        a = (a + 0x6D2B79F5) | 0;
        let t = a;
        t = Math.imul(t ^ (t >>> 15), t | 1);
        t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
        return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
}

export function uuidFromSeed(rand: () => number, namespace: string): string {
    // Deterministic 12-char id built from 6 hex bytes derived from the RNG.
    let s = '';
    for (let i = 0; i < 12; i++) {
        s += Math.floor(rand() * 16).toString(16).toUpperCase();
    }
    return `${namespace}-${s}`;
}

export function dateRange(start: Date, end: Date): Date[] {
    const out: Date[] = [];
    const cur = new Date(start);
    while (cur <= end) {
        out.push(new Date(cur));
        cur.setUTCDate(cur.getUTCDate() + 1);
    }
    return out;
}
