// Diagnostic only: current component state with mocked endpoints, no Salesforce calls or LWC edits.
import { readFileSync } from 'node:fs';
import { runInNewContext } from 'node:vm';
import assert from 'node:assert/strict';
import test from 'node:test';

function scenario({ submitFails = false, readFails = false } = {}) {
    const calls = { submit: 0, read: 0 };
    const source = readFileSync(new URL('../../force-app/main/default/lwc/ownerPortalCases/ownerPortalCases.js', import.meta.url), 'utf8')
        .replace(/^import .*;\r?\n/gm, '')
        .replace('export default class', 'globalThis.Component = class');
    const context = { LightningElement: class {}, isGuest: false,
        addComment: async () => {
            calls.submit += 1;
            if (submitFails) throw new Error('simulated insert rejection');
            return 'comment-id';
        },
        getComments: async () => {
            calls.read += 1;
            if (readFails) throw new Error('simulated refresh rejection');
            return [{ Id: 'comment-id', CommentBody: 'diagnostic text' }];
        } };
    runInNewContext(source, context);
    const component = new context.Component();
    component.selectedCase = 'own-case';
    component.commentBody = 'diagnostic text';
    return { component, calls };
}

test('failed submit retains text and does not fetch or retry', async () => {
    const { component, calls } = scenario({ submitFails: true });
    await component.comment();
    assert.equal(calls.submit, 1);
    assert.equal(calls.read, 0);
    assert.equal(component.commentBody, 'diagnostic text');
    assert.equal(component.loading, false);
    assert.match(component.error, /could not be submitted/);
});

test('successful submit followed by failed refresh currently gives the same failure message', async () => {
    const { component, calls } = scenario({ readFails: true });
    await component.comment();
    assert.equal(calls.submit, 1);
    assert.equal(calls.read, 1);
    assert.equal(component.commentBody, '');
    assert.equal(component.loading, false);
    assert.match(component.error, /could not be submitted/);
    // Confirms an ambiguous UI diagnostic, not the cause/outcome of the owner's failed request.
});

test('mocked successful submit and refresh displays the returned row once', async () => {
    const { component, calls } = scenario();
    await component.comment();
    assert.equal(calls.submit, 1);
    assert.equal(calls.read, 1);
    assert.equal(component.comments.length, 1);
    assert.equal(component.comments[0].Id, 'comment-id');
    assert.equal(component.error, undefined);
});
