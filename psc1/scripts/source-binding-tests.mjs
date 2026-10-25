import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { createLosslessSourceTool, createSourceOwnershipTool,
  createSourceBindingTool } from '../host-tools/source-refactoring.mjs';

const hash = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const pin = name => {
  const executable = path.resolve('.lake/build/bin/' + name);
  return { executable, sha256: hash(fs.readFileSync(executable)) };
};
const lexical = createLosslessSourceTool(pin('psc1_lossless_source'));
const checker = pin('psc1_independent_checker');
const ownership = createSourceOwnershipTool({
  lexicalTool: lexical, ...pin('psc1_source_ownership'),
  checkerExecutable: checker.executable, checkerSha256: checker.sha256,
});
const bindings = createSourceBindingTool({ ownershipTool: ownership });
const records = [];
let negatives = 0;
const refuse = (fn, pattern = /PSC1_LOSSLESS_/) => {
  assert.throws(fn, pattern); negatives++;
};
const capture = (text, grammar, module = 'Test.Main') =>
  lexical.capture({ module, grammar, bytes: Buffer.from(text) });
function selected(index, name, occurrence = 0, region = 'body') {
  const all = index.modules.flatMap(module => module.bindings.flatMap(batch =>
    batch.traces.flatMap(trace => trace.binders)));
  const found = all.filter(binder => binder.sourceBacked && binder.region === region &&
    JSON.stringify(binder.name) === JSON.stringify([['s', name]]))[occurrence];
  assert.ok(found, 'source binder ' + name + ': ' + JSON.stringify(all));
  return found;
}
function analyze(snapshots, assurance = 'checked') {
  try {
    const index = bindings.analyze({ snapshots, entry: snapshots.at(-1).module, assurance });
    assert.equal(index.checker.accepted, true);
    assert.equal(index.metrics.timeoutMs, 240000);
    assert.equal(index.authority.publication, false);
    assert.ok(Object.isFrozen(index.modules));
    return index;
  } catch (error) { console.error('PSC1_BINDINGS_CASE', error.cause); throw error; }
}
for (const grammar of ['lean', 'ps']) {
  const cases = [
    ['let', 'def choose (x : Nat) : Nat := let value : Nat := Nat.add x 1; value\n', 'value', 0],
    ['shadow', 'def choose (x : Nat) : Nat := let x : Nat := Nat.add x 1; x\n', 'x', 0],
    ['reuse', 'def choose : Nat := Nat.add (let x : Nat := 1; x) (let x : Nat := 2; x)\n', 'x', 1],
    ['lambda', 'def choose : Nat := (fun (x : Nat) => Nat.add x 1) 2\n', 'x', 0],
    ['branch', 'def choose : Nat := if true then (let x : Nat := 1; x) else (let x : Nat := 2; x)\n', 'x', 1],
    ['unicode', '/- 😀 value stays -/\r\ndef choose : Nat := let α : Nat := 7; α\n' +
      'def text : String := "α -- untouched"\n', 'α', 0],
  ];
  for (const [name, text, binderName, occurrence] of cases) {
    console.log('PSC1_BINDINGS_STARTED', { grammar, name });
    const source = capture(text, grammar), snapshots = [source], index = analyze(snapshots);
    const binder = selected(index, binderName, occurrence);
    const report = bindings.rename({ index, snapshots, binder, newName: 'renamedValue' });
    const bytes = bindings.readCandidate(report, 'Test.Main');
    assert.equal(report.authority.publication, false);
    assert.equal(report.authority.sourceFilesWritten, false);
    assert.equal(report.admissions.beforeChecker.accepted, true);
    assert.equal(report.admissions.afterChecker.accepted, true);
    assert.notEqual(report.sourceClosureDigest, report.candidateClosureDigest);
    assert.ok(Object.isFrozen(report.binderMap));
    const original = Buffer.from(bytes); bytes.fill(0);
    assert.deepEqual(bindings.readCandidate(report, 'Test.Main'), original);
    assert.deepEqual(lexical.reconstruct(source), Buffer.from(text));
    assert.equal(bindings.assertCandidateCurrent(report, snapshots), true);
    assert.ok(bindings.candidateIndex(report).checker.accepted);
    records.push({ grammar, name, ...report });
    if (name === 'let') {
      refuse(() => bindings.rename({ index: { ...index }, snapshots, binder, newName: 'other' }), /BINDING_INDEX/);
      refuse(() => bindings.rename({ index, snapshots, binder: { ...binder }, newName: 'other' }), /BINDING_HANDLE/);
      const repeat = analyze(snapshots);
      refuse(() => bindings.rename({ index: repeat, snapshots, binder, newName: 'other' }), /BINDING_HANDLE/);
      refuse(() => bindings.rename({ index, snapshots: [capture(text + '-- stale', grammar)],
        binder, newName: 'other' }), /OWNERSHIP_STALE/);
      for (const newName of ['_', '_root_', 'value', 'a.b', 'x y', '']) {
        refuse(() => bindings.rename({ index, snapshots, binder, newName }), /BINDING_RENAME_NAME/);
      }
      refuse(() => bindings.readCandidate({ ...report }, 'Test.Main'), /BINDING_REPORT/);
      refuse(() => bindings.readCandidate(report, 'Absent'), /BINDING_MODULE/);
      refuse(() => bindings.rename({ index, snapshots, binder: selected(index, 'x', 0, 'public-header'),
        newName: 'header' }), /BINDING_RENAME_UNSUPPORTED/);
    }
  }
  for (const text of [
    'def choose : Nat := let x : Nat := 1; let y : Nat := 2; Nat.add x y\n',
    'def y : Nat := 2\ndef choose : Nat := let x : Nat := 1; Nat.add x y\n',
  ]) {
    const source = capture(text, grammar), snapshots = [source], index = analyze(snapshots);
    refuse(() => bindings.rename({ index, snapshots, binder: selected(index, 'x'), newName: 'y' }),
      /BINDING_REFERENCE_CORRESPONDENCE|BINDING_BINDER_CORRESPONDENCE/);
  }
  const base = capture('namespace Base\ndef seed : Nat := 3\nend Base\n', grammar, 'Test.Base');
  const main = capture('import Test.Base\nnamespace App\ndef choose : Nat := ' +
    'let x : Nat := _root_.Base.seed; Nat.add x 1\nend App\n', grammar);
  const index = analyze([base, main], 'ordinary-checked');
  const report = bindings.rename({ index, snapshots: [base, main], binder: selected(index, 'x'),
    newName: 'seedValue' });
  assert.deepEqual(bindings.readCandidate(report, 'Test.Base'), lexical.reconstruct(base));
  records.push({ grammar, name: 'import-namespace-root-ordinary', ...report });
}
refuse(() => createSourceBindingTool({ ownershipTool: { ...ownership } }), /BINDING_OWNERSHIP_TOOL/);
fs.mkdirSync('dist/source-bindings', { recursive: true });
fs.writeFileSync('dist/source-bindings/focused.json', JSON.stringify({
  schema: 'psc1-source-bindings-focused/1', records, negatives,
  sourceFilesWritten: false, publication: false,
}, null, 2) + '\n');
console.log('PSC1_SOURCE_BINDINGS: PASS', JSON.stringify({ renames: records.length, negatives }));
