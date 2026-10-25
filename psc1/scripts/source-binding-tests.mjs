import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import os from 'node:os';
import { boundedRun } from '../host-tools/generated-target-tools.mjs';
import { createLosslessSourceTool, createSourceOwnershipTool,
  createSourceBindingTool, createCheckedSourceConverter } from '../host-tools/source-refactoring.mjs';

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
const converter = createCheckedSourceConverter({ ownershipTool: ownership });
const records = [];
let negatives = 0;
const refuse = (fn, pattern = /PSC1_LOSSLESS_/) => {
  assert.throws(fn, pattern); negatives++;
};
const captureRaw = (text, grammar, module = 'Test.Main') =>
  lexical.capture({ module, grammar, bytes: Buffer.from(text) });
const capture = (text, grammar, module = 'Test.Main') => {
  if (grammar === 'lean') return captureRaw(text, grammar, module);
  // Use the existing qualified printer; the candidate is subsequently parsed,
  // elaborated and admitted through the actual PS production path.
  const source = captureRaw(text, 'lean', module);
  // Imports are already authored in both grammars; standalone conversion needs
  // the actual complete closure, so imported fixtures below supply authored PS.
  if (/^import /m.test(text)) return captureRaw(text, grammar, module);
  const index = ownership.analyze({ snapshots: [source], entry: module });
  const report = converter.convert({ index, snapshots: [source], targetGrammar: 'ps' });
  return converter.candidateSnapshots(report)[0];
};
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
    assert.equal(lexical.reconstruct(source).toString('utf8').includes('renamedValue'), false);
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
    (grammar === 'ps' ? 'let x : Nat := _root_.Base.seed\n Nat.add(x, 1)\nend App\n' :
      'let x : Nat := _root_.Base.seed; Nat.add x 1\nend App\n'), grammar);
  const index = analyze([base, main], 'ordinary-checked');
  const report = bindings.rename({ index, snapshots: [base, main], binder: selected(index, 'x'),
    newName: 'seedValue' });
  assert.deepEqual(bindings.readCandidate(report, 'Test.Base'), lexical.reconstruct(base));
  records.push({ grammar, name: 'import-namespace-root-ordinary', ...report });
}
refuse(() => createSourceBindingTool({ ownershipTool: { ...ownership } }), /BINDING_OWNERSHIP_TOOL/);

const work = fs.mkdtempSync(path.join(os.tmpdir(), 'psc1-bindings-negative-'));
try {
  const sourceText = 'def target (input : Nat) : Nat := let local : Nat := input; local\n';
  const source = capture(sourceText, 'lean');
  const index = analyze([source]), binder = selected(index, 'local');
  const native = pin('psc1_source_ownership');
  function fixture(label, change) {
    const executable = path.join(work, label);
    fs.writeFileSync(executable, '#!/usr/bin/python3\nimport sys,subprocess,json\n' +
      'status=subprocess.run([' + JSON.stringify(native.executable) + ']+sys.argv[1:]).returncode\n' +
      'if status: sys.exit(status)\n' +
      'value=json.load(open(sys.argv[3]))\n' + change + '\n' +
      'json.dump(value,open(sys.argv[3],"w"),ensure_ascii=False)\n', { mode: 0o700 });
    const owner = createSourceOwnershipTool({
      lexicalTool: lexical, executable, sha256: hash(fs.readFileSync(executable)),
      checkerExecutable: checker.executable, checkerSha256: checker.sha256,
    });
    return createSourceBindingTool({ ownershipTool: owner });
  }
  const prefix = 'if sys.argv[1]=="bindings":\n  trace=value["modules"][0]["bindings"][0]["traces"][0]\n';
  const changes = [
    'trace["events"]+=1',
    'trace["bodyStart"]=trace["events"]+1',
    'trace["name"]=[["s","absent"]]',
    'trace["phase"]="after-erasure"',
    'trace["binders"][0][3]=trace["binders"][0][0]',
    'trace["binders"][0][0]=trace["events"]',
    'trace["binders"][0][4][2]+=1',
    'trace["references"][-1][4][2]=trace["events"]',
    'trace["references"][-1][3]=0',
    'trace["references"][-1][1]=[["s","other"]]',
    'trace["references"][-1][2][2]+=1',
    'trace["encoding"]="unknown"',
    'trace["binders"][0].append("extra")',
    'trace["references"][-1][4].append("extra")',
    'trace["references"][-1][2].append(0)',
    'trace["enabled"]=False',
    'trace["authority"]="publish"',
    'value["modules"][0]["bindings"]=[]',
    'value["sourceClosureDigest"]="0"*64',
  ];
  for (const [i, change] of changes.entries()) {
    const bad = fixture('trace-' + i, prefix + '  ' + change);
    refuse(() => bad.analyze({ snapshots: [source], entry: 'Test.Main' }));
  }
  for (const [i, change] of [
    'value["beforeDigest"]="0"*64',
    'value["target"]["name"]=[["s","other"]]',
    'value["relation"]="unrestricted"',
    'value["sourceFilesWritten"]=True',
    'value["publication"]=True',
  ].entries()) {
    const bad = fixture('comparison-' + i,
      'if sys.argv[1]=="compare-bindings":\n  ' + change);
    const before = bad.analyze({ snapshots: [source], entry: 'Test.Main' });
    refuse(() => bad.rename({ index: before, snapshots: [source],
      binder: selected(before, 'local'), newName: 'renamed' }), /BINDING_COMPARISON_IDENTITY/);
  }
  const badGraph = fixture('bad-admission',
    'if sys.argv[1]=="bindings":\n  open(sys.argv[4],"w").write("{}")');
  refuse(() => badGraph.analyze({ snapshots: [source], entry: 'Test.Main' }), /PSC1_CHECKER_/);
  const changingPath = path.join(work, 'changed-tool');
  fs.copyFileSync(native.executable, changingPath);
  const changingOwner = createSourceOwnershipTool({
    lexicalTool: lexical, executable: changingPath, sha256: native.sha256,
    checkerExecutable: checker.executable, checkerSha256: checker.sha256,
  });
  const changing = createSourceBindingTool({ ownershipTool: changingOwner });
  fs.appendFileSync(changingPath, '\nchanged');
  refuse(() => changing.analyze({ snapshots: [source], entry: 'Test.Main' }), /TOOL_IDENTITY/);

  const manifest = {
    schema: 'psc1-source-tools/1',
    lexical: { path: pin('psc1_lossless_source').executable, sha256: pin('psc1_lossless_source').sha256 },
    ownership: { path: native.executable, sha256: native.sha256 },
    checker: { path: checker.executable, sha256: checker.sha256 },
  };
  const manifestPath = path.join(work, 'tools.json'), sourcePath = path.join(work, 'Main.lean');
  fs.writeFileSync(manifestPath, JSON.stringify(manifest));
  fs.writeFileSync(sourcePath, sourceText);
  const original = hash(fs.readFileSync(sourcePath));
  const cli = path.resolve('scripts/refactor-source.mjs');
  const args = ['--manifest', manifestPath, '--entry', 'Test.Main',
    '--grammar', 'lean', '--source', 'Test.Main=' + sourcePath];
  function runCli(extra) {
    return boundedRun(process.execPath, [cli, ...args, ...extra], {
      cwd: work, timeoutMs: 240000, timeoutPolicy: 'standard-240s',
    });
  }
  const view = runCli(['--operation', 'bindings']);
  assert.equal(view.status, 0, view.stderr);
  assert.equal(JSON.parse(view.stdout).schema, 'psc1-source-bindings-view/1');
  const rename = runCli(['--operation', 'rename', '--module', 'Test.Main',
    '--offset', String(binder.span.start.byteOffset), '--new-name', 'renamed']);
  assert.equal(rename.status, 0, rename.stderr);
  const candidate = JSON.parse(rename.stdout);
  assert.equal(candidate.schema, 'psc1-source-rename-candidate/1');
  assert.match(candidate.modules[0].text, /let renamed/);
  assert.equal(candidate.report.authority.publication, false);
  const missing = runCli(['--operation', 'rename', '--module', 'Test.Main',
    '--offset', '0', '--new-name', 'renamed']);
  assert.notEqual(missing.status, 0); negatives++;
  assert.equal(missing.stdout, '');
  assert.equal(hash(fs.readFileSync(sourcePath)), original);
} finally { fs.rmSync(work, { recursive: true, force: true }); }

fs.mkdirSync('dist/source-bindings', { recursive: true });
fs.writeFileSync('dist/source-bindings/focused.json', JSON.stringify({
  schema: 'psc1-source-bindings-focused/1', records, negatives,
  sourceFilesWritten: false, publication: false,
}, null, 2) + '\n');
console.log('PSC1_SOURCE_BINDINGS: PASS', JSON.stringify({ renames: records.length, negatives }));
