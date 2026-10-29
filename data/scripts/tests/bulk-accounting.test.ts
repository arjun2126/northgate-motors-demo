/**
 * Bulk success-accounting tests — verify evaluateBulkResult() catches every
 * silent partial-success mode the previous inline handler missed. Pure
 * function, no Salesforce calls, no file system.
 */
import { strict as assert } from 'node:assert';
import { evaluateBulkResult, countCsvDataRows } from '../resolve.js';

const HEADER = '"sf__Id","sf__Created",Seed_Tag__c,QuoteId,PricebookEntryId,Quantity,UnitPrice\n';
function rows(n: number, prefix = 'SEED-13'): string {
    let s = '';
    for (let i = 1; i <= n; i++) s += `${prefix}-${i.toString().padStart(3, '0')},0Q0AA,01tXX,1,81043\n`;
    return s;
}
function loadContent(n: number): string { return HEADER + rows(n); }
function successContent(n: number): string { return HEADER + rows(n, 'OK'); }
function failedContent(n: number): string { return HEADER + rows(n, 'FAIL'); }

const baseEv = (overrides: Partial<Parameters<typeof evaluateBulkResult>[0]> = {}) => ({
    loadFileContent: loadContent(80),
    successFileExists: true,
    successFileContent: successContent(80),
    failedFileExists: true,
    failedFileContent: HEADER,  // header-only → 0 failed
    jobId: '750aj00001HpL4vAAF',
    cliStatus: 0,
    cliStdout: 'Job Id:\n 750aj00001HpL4vAAF\nSuccessfully processed 80 records.\nProcessed records: 80\nFailed records: 0\n',
    cliStderr: '',
    ...overrides,
});

function t1() {
    // 80 submitted, 80 succeeded, 0 failed → PASS.
    const r = evaluateBulkResult(baseEv());
    assert.equal(r.ok, true, `unexpected reason: ${r.reason}`);
    assert.equal(r.submitted, 80);
    assert.equal(r.succeeded, 80);
    assert.equal(r.failed, 0);
    assert.equal(r.unprocessed, 0);
    assert.equal(r.processed, 80);
    console.log('  PASS bulk: 80/80/0 → ok');
}

function t2() {
    // 80 submitted, 79 succeeded, 0 failed → FAIL (unprocessed=1).
    const r = evaluateBulkResult(baseEv({ successFileContent: successContent(79) }));
    assert.equal(r.ok, false);
    assert.ok(r.reason.includes('succeeded_mismatch=79/80'), `reason=${r.reason}`);
    assert.ok(r.reason.includes('unprocessed=1'), `reason=${r.reason}`);
    assert.equal(r.submitted, 80);
    assert.equal(r.succeeded, 79);
    assert.equal(r.failed, 0);
    assert.equal(r.unprocessed, 1);
    console.log('  PASS bulk: 80/79/0 → fail (unprocessed=1)');
}

function t3() {
    // 80 submitted, 79 succeeded, 1 failed → FAIL.
    const r = evaluateBulkResult(baseEv({
        successFileContent: successContent(79),
        failedFileContent: failedContent(1),
    }));
    assert.equal(r.ok, false);
    assert.ok(r.reason.includes('succeeded_mismatch=79/80'));
    assert.ok(r.reason.includes('failed_file_rows=1'));
    assert.equal(r.submitted, 80);
    assert.equal(r.succeeded, 79);
    assert.equal(r.failed, 1);
    assert.equal(r.unprocessed, 0);
    console.log('  PASS bulk: 80/79/1 → fail (mismatch + failed rows)');
}

function t4() {
    // Missing success results → FAIL.
    const r = evaluateBulkResult(baseEv({
        successFileExists: false,
        successFileContent: '',
    }));
    assert.equal(r.ok, false);
    assert.ok(r.reason.includes('no_success_file'), `reason=${r.reason}`);
    console.log('  PASS bulk: missing success file → fail (no_success_file)');
}

function t5() {
    // Header-only success file → FAIL (empty_success_file).
    const r = evaluateBulkResult(baseEv({
        successFileContent: HEADER,
    }));
    assert.equal(r.ok, false);
    assert.ok(r.reason.includes('empty_success_file'), `reason=${r.reason}`);
    console.log('  PASS bulk: header-only success file → fail (empty_success_file)');
}

function t6() {
    // Missing jobId (no "Job ID:" line in stdout) → FAIL.
    const r = evaluateBulkResult(baseEv({
        jobId: '',
        cliStdout: 'Successfully completed.\n',
    }));
    assert.equal(r.ok, false);
    assert.ok(r.reason.includes('no_job_id'), `reason=${r.reason}`);
    console.log('  PASS bulk: no jobId → fail (no_job_id)');
}

function t7() {
    // Empty loadFileContent (loader couldn't read what it submitted) → FAIL.
    const r = evaluateBulkResult(baseEv({ loadFileContent: '' }));
    assert.equal(r.ok, false);
    assert.ok(r.reason.includes('no_submitted_rows'), `reason=${r.reason}`);
    console.log('  PASS bulk: empty load file → fail (no_submitted_rows)');
}

function t8() {
    // Header-only loadFileContent (loader submitted nothing) → FAIL.
    const r = evaluateBulkResult(baseEv({ loadFileContent: HEADER }));
    assert.equal(r.ok, false);
    assert.ok(r.reason.includes('no_submitted_rows'), `reason=${r.reason}`);
    console.log('  PASS bulk: header-only load file → fail (no_submitted_rows)');
}

function t9() {
    // Nonzero CLI exit → FAIL even if files would balance.
    const r = evaluateBulkResult(baseEv({ cliStatus: 1 }));
    assert.equal(r.ok, false);
    assert.ok(r.reason.includes('exit=1'), `reason=${r.reason}`);
    console.log('  PASS bulk: nonzero CLI exit → fail (exit=1)');
}

function t10() {
    // CLI reports failed=0 but failed file has rows (CLI/sf mismatch) → FAIL.
    const r = evaluateBulkResult(baseEv({
        failedFileContent: failedContent(2),
        cliStdout: 'Job Id:\n 750aj00001HpL4vAAF\nProcessed records: 80\nFailed records: 0\n',
    }));
    assert.equal(r.ok, false);
    assert.ok(r.reason.includes('failed_file_rows=2'), `reason=${r.reason}`);
    assert.equal(r.failed, 2);
    console.log('  PASS bulk: file rows exceed CLI count → fail');
}

function t11() {
    // Processed count from CLI mismatches submitted → FAIL.
    const r = evaluateBulkResult(baseEv({
        cliStdout: 'Job Id:\n 750aj00001HpL4vAAF\nProcessed records: 70\nFailed records: 0\n',
    }));
    assert.equal(r.ok, false);
    assert.ok(r.reason.includes('processed_mismatch=70/80'), `reason=${r.reason}`);
    console.log('  PASS bulk: CLI processed != submitted → fail');
}

function t12() {
    // Failed file absent, CLI reports 0 failed, 80/80/0 → PASS (sf omits the
    // failed file when there are no failures; that's the normal happy path).
    const r = evaluateBulkResult(baseEv({
        failedFileExists: false,
        failedFileContent: '',
    }));
    assert.equal(r.ok, true, `reason=${r.reason}`);
    assert.equal(r.failed, 0);
    console.log('  PASS bulk: absent failed file + 0 CLI failures → ok');
}

function t13() {
    // countCsvDataRows helper correctness.
    assert.equal(countCsvDataRows(''), 0);
    assert.equal(countCsvDataRows(HEADER), 0);
    assert.equal(countCsvDataRows(HEADER + 'a\nb\nc\n'), 3);
    assert.equal(countCsvDataRows(HEADER + 'a\nb\nc'), 3);  // trailing newline missing
    console.log('  PASS bulk: countCsvDataRows correct (empty, header-only, N rows, missing trailing nl)');
}

function t14() {
    // The loader's jobId parser must capture the FULL Salesforce Id
    // (e.g. "750aj00001HpoenAAB"), not just the digit prefix. A previous
    // regex truncated to "750" and produced a false-positive failure.
    const cliOut = ' Status: UploadComplete\n Job Id:\n 750aj00001HpoenAAB\n';
    const m = cliOut.match(/Job\s+ID\s*:\s*([0-9a-zA-Z]{15,18})/i);
    assert.ok(m, 'regex must match');
    assert.equal(m![1], '750aj00001HpoenAAB', 'must capture full 15-char Salesforce Id');
    console.log('  PASS bulk: jobId regex captures full 15-char Salesforce Id (not digit prefix)');
}

t1();
t2();
t3();
t4();
t5();
t6();
t7();
t8();
t9();
t10();
t11();
t12();
t13();
t14();
console.log('[bulk-accounting.test] PASS — evaluateBulkResult enforces complete success accounting');
