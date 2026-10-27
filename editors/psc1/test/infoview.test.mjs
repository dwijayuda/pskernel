import test from 'node:test';
import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
const {renderInfoview, canReplaceStatus, snapshotMatches, includesSource, infoAtPosition} = createRequire(import.meta.url)('../vscode/src/infoview.cjs');

test('compiler and filename text cannot become executable Infoview markup', () => {
  const hostile = '</pre><script>alert(1)</script><img src="x" onerror="alert(1)">';
  const html = renderInfoview({
    state: 'rejected', summary: hostile, version: 3, projectGeneration: 7,
    declaration: {name: hostile, type: hostile, verified: true},
    goalsAvailable: false,
    diagnostics: [{message: hostile, severity: 1, range: {start: {line: 0, character: 0}, end: {line: 0, character: 1}}}],
  }, {name: hostile, line: 0, character: 0}, 'test-nonce');
  assert.ok(!html.includes('<script'));
  assert.ok(!html.includes('<img'));
  assert.ok(html.includes('&lt;script&gt;'));
  assert.match(html, /default-src 'none'/);
  assert.ok(!html.includes('Goals accomplished!'));
  assert.ok(!html.includes('Checked by the PSC1 compiler.'));
});

test('successful declaration checking alone never invents a goal snapshot', () => {
  const html = renderInfoview({state: 'checked', declaration: {name: 'answer', type: 'Nat', verified: true},
    goalsAvailable: false, diagnostics: []}, {name: 'Main.ps', line: 0, character: 0}, 'test-nonce');
  assert.ok(!html.includes('Goals accomplished!'));
  assert.match(html, /not available yet/);
});

// UI state-machine fixtures are not evidence that a compiler accepts/rejects code.
// Real compiler and installed-extension qualification live in the integration suites.
test('an observed platform refusal remains an actionable terminal error', () => {
  const message = 'PSC1_SERVICE_PUBLICATION_PLATFORM_UNQUALIFIED';
  const html = renderInfoview({state: 'error', summary: 'Compiler checking could not finish.',
    version: 1, projectGeneration: 1, messages: [],
    diagnostics: [{message, severity: 1, range: {start: {line: 0, character: 0}, end: {line: 0, character: 0}}}],
    declarations: [], goalsAvailable: false}, {name: 'Main.ps', line: 0, character: 7}, 'test-nonce');
  assert.match(html, /Check unavailable/);
  assert.match(html, /PSC1_SERVICE_PUBLICATION_PLATFORM_UNQUALIFIED/);
  assert.match(html, /Install the updated PSC1 extension build/);
  assert.match(html, /All messages \(1\)/);
  assert.ok(!html.includes('Waiting for check'));
  assert.ok(!html.includes('Goals accomplished!'));
});

test('a delayed pending Infoview response cannot replace terminal feedback in the same generation', () => {
  const terminal = {version: 3, projectGeneration: 9, state: 'error'};
  assert.equal(canReplaceStatus(terminal, {...terminal, state: 'pending'}), false);
  assert.equal(canReplaceStatus(terminal, {...terminal, state: 'checking'}), false);
  assert.equal(canReplaceStatus(terminal, {...terminal, projectGeneration: 8}), false);
  assert.equal(canReplaceStatus(terminal, {...terminal, projectGeneration: 10, state: 'pending'}), true);
  assert.equal(canReplaceStatus(terminal, {...terminal, version: 4, state: 'pending'}), true);
  assert.equal(canReplaceStatus({version: 3, state: 'pending'}, {version: 3, projectGeneration: 0, state: 'checked'}), true,
    'restart clears server-generation provenance; the fresh generation zero is admissible');
});

test('source-version validation isolates projects and invalidates changed or closed imports', () => {
  const main = 'file:///project/Main.ps', imported = 'file:///project/Lib.ps', other = 'file:///elsewhere/Other.ps';
  const status = {state: 'checked', snapshotVersions: {[main]: 4, [imported]: 2}};
  const open = new Map([[main, 4], [imported, 2], [other, 17]]);
  assert.equal(snapshotMatches(status, open), true);
  open.set(other, 18);
  assert.equal(snapshotMatches(status, open), true);
  assert.equal(includesSource(status, other), false);
  assert.equal(includesSource(status, imported), true);
  open.set(imported, 3);
  assert.equal(snapshotMatches(status, open), false);
  open.delete(imported);
  assert.equal(snapshotMatches(status, open), false);
  assert.equal(snapshotMatches({...status, snapshotVersions: {[main]: 4, [imported]: null}}, open), true);
  open.set(imported, 1);
  assert.equal(snapshotMatches({...status, snapshotVersions: {[main]: 4, [imported]: null}}, open), false);
});

test('source-version validation uses the editor-provided URI normalization', () => {
  const nodeUri = 'file:///C:/work/Main.ps', editorUri = 'file:///c%3A/work/Main.ps';
  const normalize = uri => uri === nodeUri ? editorUri : uri;
  const status = {snapshotVersions: {[nodeUri]: 5}};
  assert.equal(snapshotMatches(status, new Map([[editorUri, 5]]), normalize), true);
  assert.equal(includesSource(status, editorUri, normalize), true);
  assert.equal(snapshotMatches({snapshotVersions: {}}, new Map()), false);
});

test('cursor following selects only ranges and types provided in the compiler snapshot', () => {
  const declaration = {name: 'answer', type: 'Nat', verified: true,
    range: {start: {line: 1, character: 0}, end: {line: 1, character: 24}},
    selectionRange: {start: {line: 1, character: 4}, end: {line: 1, character: 10}}};
  const snapshot = {state: 'checked', declarations: [declaration], diagnostics: []};
  assert.equal(infoAtPosition(snapshot, {line: 1, character: 7}).declaration, declaration);
  assert.equal(infoAtPosition(snapshot, {line: 1, character: 23}).declaration, declaration);
  assert.equal(infoAtPosition(snapshot, {line: 2, character: 0}).declaration, null);
  assert.equal(infoAtPosition(snapshot, {line: 1, character: 7}).goalsAvailable, false);
});
