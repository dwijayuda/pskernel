import test from 'node:test';
import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
const {renderInfoview} = createRequire(import.meta.url)('../vscode/src/infoview.cjs');

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
