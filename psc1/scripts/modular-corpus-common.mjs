// Development qualification helpers; never imported by production host code.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import { boundedRun, sha } from '../host-tools/generated-target-tools.mjs';
export { sha };
export const suites = [
  ['compiler-m','PSC1_COMPILERM','PSC1_COMPILERM_CASE_CONTRACT.json'],
  ['stdlib-collections','PSC1_COLLECTION','PSC1_STDLIB_COLLECTION_CASE_CONTRACT.json'],
  ['json-application','PSC1_JSON','PSC1_JSON_APPLICATION_CASE_CONTRACT.json'],
  ['inference-control','PSC1_INFERENCE','PSC1_INFERENCE_CONTROL_CASE_CONTRACT.json'],
  ['typed-io-protocol','PSC1_IO_PROTOCOL','PSC1_TYPED_IO_PROTOCOL_CASE_CONTRACT.json'],
  ['typed-io-sequencing','PSC1_IO_SEQUENCING','PSC1_TYPED_IO_SEQUENCING_CASE_CONTRACT.json'],
  ['checked-order','PSC1_ORDER','PSC1_ORDER_CASE_CONTRACT.json'],
  ['library-application','PSC1_LIBRARY','PSC1_LIBRARY_APPLICATION_CASE_CONTRACT.json'],
];
export const root = path.resolve('dist/modular-corpus');
export const read = file => JSON.parse(fs.readFileSync(file));
export function write(file, value) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, JSON.stringify(value, null, 2) + '\n');
}
export function run(executable, args, options = {}) {
  const result = boundedRun(executable, args, options);
  assert.equal(result.error, null, result.stderr);
  assert.equal(result.status, 0, result.stderr || result.stdout);
  return result;
}
export function capturedSources(rows) {
  const names = new Set();
  return rows.map(row => {
    assert.equal(sha(row.text), row.sha256);
    assert.equal(Buffer.byteLength(row.text), row.bytes);
    // Only the sealed retained corpus is accepted. No path is opened here.
    const marker = row.path.lastIndexOf('ProofScript/');
    const relative = marker >= 0 ? row.path.slice(marker) : row.path;
    assert.match(relative, /^(?:[A-Za-z_][A-Za-z_0-9]*\/)*[A-Za-z_][A-Za-z_0-9]*\.(lean|ps)$/);
    const kind = path.extname(relative).slice(1);
    const module = relative.slice(0, -(kind.length + 1)).split('/').join('.');
    assert.ok(!names.has(module)); names.add(module);
    return { module, kind, text: row.text };
  });
}
