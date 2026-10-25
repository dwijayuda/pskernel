// Diagnostic only: inspect actual parser/elaborator hints. No accepted index,
// independent admission, candidate capability or publication is produced.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import { readOwnedCompilerSources } from '../host-tools/compiler-source-inputs.mjs';
import { compilerSourceClosureDigest } from '../host-tools/compiler-host-protocol.mjs';
import { createLosslessSourceTool } from '../host-tools/source-refactoring.mjs';
import { boundedRun } from '../host-tools/generated-target-tools.mjs';
const hash = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const rows = readOwnedCompilerSources('Ps.CompilerUnified.Service');
const sourceClosureDigest = compilerSourceClosureDigest(rows.map(row => ({ ...row, kind: 'lean' })));
const directory = path.resolve('dist/source-binding-diagnostic');
fs.mkdirSync(directory, { recursive: true });
const input = path.join(directory, 'request.json'), output = path.join(directory, 'wire.json');
fs.writeFileSync(input, JSON.stringify(['psc1-compiler-service/1', 'binding-origin-audit',
  sourceClosureDigest, 'lean', 'ordinary-checked', 'Ps.CompilerUnified.Service',
  rows.map(row => [row.module, row.text])]));
const executable = path.resolve('.lake/build/bin/psc1_source_ownership');
const native = boundedRun('prlimit', ['--as=4294967296', '--stack=8388608', '--',
  executable, 'bindings', input, output, path.join(directory, 'admissions.json'),
  path.join(directory, 'ir.json')], { timeoutMs: 240000, timeoutPolicy: 'standard-240s',
  env: { ...process.env, LEAN_MAIN_USE_THREAD: '0', LEAN_NUM_THREADS: '0', LEAN_STACK_SIZE_KB: '8192' } });
assert.equal(native.status, 0, native.stderr);
const bytes = fs.readFileSync(output);
assert.ok(bytes.length <= 33554432);
const wire = JSON.parse(bytes);
assert.equal(wire.status, 'prepared');
assert.equal(wire.sourceClosureDigest, sourceClosureDigest);
const lexer = path.resolve('.lake/build/bin/psc1_lossless_source');
const lexical = createLosslessSourceTool({ executable: lexer, sha256: hash(fs.readFileSync(lexer)) });
const snapshots = new Map(), mismatches = [], counts = { references: 0, generated: 0, source: 0 };
for (const [i, module] of wire.modules.entries()) {
  assert.equal(module.module, rows[i].module);
  const source = Buffer.from(rows[i].text);
  for (const batch of module.bindings) for (const trace of batch.traces) {
    assert.equal(trace.encoding, 'psc1-source-bindings-compact/2');
    for (const row of trace.references) {
      counts.references++;
      const span = row[5];
      if (span === null) { counts.generated++; continue; }
      counts.source++;
      const name = row[1].map(part => part[1]).join('.');
      const raw = source.subarray(span[0], span[3]).toString('utf8');
      if (raw === name) continue;
      if (!snapshots.has(module.module)) snapshots.set(module.module,
        lexical.capture({ module: module.module, grammar: 'lean', bytes: source }));
      const snapshot = snapshots.get(module.module);
      const tokens = snapshot.pieces.filter(piece => piece.kind === 'token' &&
        piece.span.start.byteOffset >= span[0] && piece.span.stop.byteOffset <= span[3]);
      const spelling = tokens.map(piece => piece.token.text).join('');
      const aligned = tokens.length && tokens[0].span.start.byteOffset === span[0] &&
        tokens.at(-1).span.stop.byteOffset === span[3] &&
        tokens.every(piece => ['identifier', 'natural'].includes(piece.token.kind) ||
          (piece.token.kind === 'symbol' && piece.token.text === '.'));
      if (!aligned || spelling !== name) mismatches.push({
        module: module.module, file: rows[i].path, owner: trace.name,
        event: row[0], name, span, raw: raw.slice(0,1024),
        tokenSpelling: spelling.slice(0,1024), target: row[4],
      });
    }
  }
}
const report = {
  schema: 'psc1-source-binding-diagnostic/1', sourceClosureDigest,
  testedCommit: process.env.GITHUB_SHA, nativeSha256: hash(fs.readFileSync(executable)),
  responseBytes: bytes.length, responseSha256: hash(bytes),
  elapsedMs: native.elapsedMs, maxRssKiB: native.maxRssKiB,
  counts, mismatchCount: mismatches.length, mismatches,
  admission: 'not-run', acceptedIndex: false, candidate: false, publication: false,
};
fs.writeFileSync(path.join(directory, 'diagnostic.json'), JSON.stringify(report,null,2)+'\n');
console.log('PSC1_BINDING_HINT_DIAGNOSTIC:', JSON.stringify(report));
