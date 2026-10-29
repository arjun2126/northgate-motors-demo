/**
 * Determinism test: two generator runs with the same ANCHOR_DATE + SEED must
 * produce byte-identical CSV output. Generator writes to data/csv/ in place,
 * so we capture checksums before/after a second invocation and compare.
 */
import { strict as assert } from 'node:assert';
import { createHash } from 'node:crypto';
import { readFileSync, readdirSync, writeFileSync, mkdirSync, rmSync, existsSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { resolve, join, dirname } from 'node:path';
import { tmpdir } from 'node:os';

const REPO_ROOT = process.cwd();
const CSV_DIR = resolve(REPO_ROOT, 'data/csv');

function hashDir(dir: string): Record<string, string> {
    const out: Record<string, string> = {};
    for (const f of readdirSync(dir).filter((x) => x.endsWith('.csv')).sort()) {
        const h = createHash('sha256').update(readFileSync(join(dir, f))).digest('hex');
        out[f] = h;
    }
    return out;
}

const seedVersionPath = resolve(REPO_ROOT, 'data/SEED_VERSION.txt');
const originalSeed = readFileSync(seedVersionPath, 'utf8');

const stashDir = join(tmpdir(), `p5-determinism-${Date.now()}`);
mkdirSync(stashDir, { recursive: true });
// Snapshot current CSVs aside so the test is non-destructive.
for (const f of readdirSync(CSV_DIR)) {
    if (f.endsWith('.csv')) {
        const src = join(CSV_DIR, f);
        const dst = join(stashDir, f);
        if (existsSync(src)) {
            const data = readFileSync(src);
            mkdirSync(dirname(dst), { recursive: true });
            writeFileSync(dst, data);
        }
    }
}

try {
    const before = hashDir(CSV_DIR);
    execFileSync('npx', ['tsx', 'data/scripts/generate.ts'], { cwd: REPO_ROOT, stdio: 'pipe' });
    const after = hashDir(CSV_DIR);

    const beforeKeys = Object.keys(before);
    const afterKeys = Object.keys(after);
    assert.deepEqual(afterKeys.sort(), beforeKeys.sort(), `CSV file list changed across runs`);

    for (const f of beforeKeys) {
        assert.equal(after[f], before[f], `CSV ${f} differs across two identical runs (not deterministic)`);
    }
    console.log(`[determinism.test] PASS — ${beforeKeys.length} CSVs byte-identical across two runs`);
} finally {
    // Restore stashed CSVs and SEED_VERSION so other tests / human work are not disturbed.
    for (const f of readdirSync(stashDir)) {
        const src = join(stashDir, f);
        const dst = join(CSV_DIR, f);
        writeFileSync(dst, readFileSync(src));
    }
    writeFileSync(seedVersionPath, originalSeed);
    rmSync(stashDir, { recursive: true, force: true });
}
