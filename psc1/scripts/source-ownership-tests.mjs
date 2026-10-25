import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { createLosslessSourceTool, createSourceOwnershipTool } from '../host-tools/source-refactoring.mjs';
import { compilerSourceClosureDigest } from '../host-tools/compiler-host-protocol.mjs';
import { readOwnedCompilerSources } from '../host-tools/compiler-source-inputs.mjs';
import { boundedRun } from '../host-tools/generated-target-tools.mjs';

const hash = b => crypto.createHash('sha256').update(b).digest('hex');
const executable = path.resolve('.lake/build/bin/psc1_source_ownership');
const checkerExecutable = path.resolve('.lake/build/bin/psc1_independent_checker');
const lexicalExecutable = path.resolve('.lake/build/bin/psc1_lossless_source');
const sha256 = hash(fs.readFileSync(executable)), checkerSha256 = hash(fs.readFileSync(checkerExecutable));
const lexical = createLosslessSourceTool({
  executable: lexicalExecutable, sha256: hash(fs.readFileSync(lexicalExecutable)),
});
const configuration = { lexicalTool: lexical, executable, sha256, checkerExecutable, checkerSha256 };
const tool = createSourceOwnershipTool(configuration);
const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'psc1-ownership-tests-'));
const records = [];
let negatives = 0, references = 0, captures = 0;
function capture(text, grammar = 'lean', module = 'Test.Main') {
  const snapshot = lexical.capture({ module, grammar, bytes: Buffer.from(text) });
  captures++;
  if (captures % 50 === 0) console.log('PSC1_OWNERSHIP_CAPTURE:', { captures, grammar, module });
  return snapshot;
}
function rejects(work, expression = /PSC1_LOSSLESS_/) {
  assert.throws(work, expression); negatives++;
}
function native(mode, rows, entry, assurance = 'checked', executableOverride = executable) {
  const kind = rows[0].snapshot?.grammar ?? rows[0].kind;
  const sources = rows.map(row => ({ module: row.module, kind, text: row.text }));
  const digest = compilerSourceClosureDigest(sources);
  const input = path.join(directory, 'request.json'), output = path.join(directory, 'index.json');
  const admissions = path.join(directory, 'admissions.json'), ir = path.join(directory, 'ir.json');
  for (const p of [output, admissions, ir]) fs.rmSync(p, { force: true });
  fs.writeFileSync(input, JSON.stringify(['psc1-compiler-service/1', 'test-reference', digest,
    kind, assurance, entry, sources.map(row => [row.module, row.text])]));
  const run = boundedRun('prlimit', ['--as=4294967296', '--stack=8388608', '--',
    executableOverride, mode, input, output, admissions, ir], {
    timeoutMs: 240000, timeoutPolicy: 'standard-240s',
    env: { ...process.env, LEAN_MAIN_USE_THREAD: '0', LEAN_NUM_THREADS: '0', LEAN_STACK_SIZE_KB: '8192' },
  });
  assert.equal(run.error, null, run.stderr);
  assert.equal(run.status, 0, run.stderr);
  return { wire: JSON.parse(fs.readFileSync(output, 'utf8')),
    admissions: fs.existsSync(admissions) ? fs.readFileSync(admissions) : null,
    ir: fs.existsSync(ir) ? fs.readFileSync(ir) : null, run };
}
function analyze(snapshots, entry = snapshots.at(-1).module, assurance = 'checked', compare = true) {
  let index;
  console.log('PSC1_OWNERSHIP_STARTED:', { entry, modules: snapshots.length, assurance });
  try { index = tool.analyze({ snapshots, entry, assurance }); }
  catch (error) { console.error('PSC1_OWNERSHIP_CASE:', { entry, assurance, cause: error.cause }); throw error; }
  assert.equal(index.checker.accepted, true);
  assert.equal(index.authority.publication, false);
  assert.equal(index.authority.referenceResolution, false);
  assert.equal(index.metrics.timeoutMs, 240000);
  assert.ok(Object.isFrozen(index) && Object.isFrozen(index.modules));
  assert.equal(tool.assertCurrent(index, snapshots), true);
  if (compare) {
    const rows = snapshots.map(snapshot => ({
      snapshot, module: snapshot.module, text: lexical.reconstruct(snapshot).toString('utf8'),
    }));
    const reference = native('reference', rows, entry, assurance);
    assert.equal(reference.wire.status, 'prepared', JSON.stringify(reference.wire));
    assert.equal(index.admissionsSha256, hash(reference.admissions));
    assert.equal(index.originalIrSha256, hash(reference.ir));
    references++;
  }
  records.push({ id: index.id, closure: index.sourceClosureDigest, modules: index.modules.length,
    grammar: index.grammar, assurance, members: index.sourceCoreDeclarations,
    admissionsSha256: index.admissionsSha256, originalIrSha256: index.originalIrSha256,
    ...index.metrics });
  return index;
}
try {
  const sources = {
    lean: 'import Test.Base\n/- 😀 keep -/\r\nnamespace App\n' +
      'def α : Nat := seed\nnamespace Inner\ndef selected : Nat := α\nend Inner\nend App\n',
    ps: 'import Test.Base\n/- 😀 keep -/\nnamespace App\n' +
      'def α : Nat := seed\nnamespace Inner\ndef selected : Nat := α\nend Inner\nend App\n',
  };
  const prepared = {};
  for (const grammar of ['lean', 'ps']) {
    const base = capture('def seed : Nat := 7\n', grammar, 'Test.Base');
    const entry = capture(sources[grammar], grammar);
    const index = analyze([base, entry]);
    prepared[grammar] = { base, entry, index };
    const origins = index.modules[1].origins;
    assert.deepEqual(origins.map(o => o.sourceName.join('.')), ['App.α', 'App.Inner.selected']);
    assert.equal(origins[0].namePieceIds.length, 1);
    assert.equal(origins[0].namePieceIds[0], entry.pieces.find(p => p.raw === 'α').id);
    assert.equal(origins[0].members[0].role, 'sourceDeclaration');
    assert.notEqual(origins[0].id, origins[1].id);
    assert.notEqual(index.modules[0].origins[0].id, origins[0].id);
    assert.ok(Object.isFrozen(origins[0].members[0].name[0]));
    rejects(() => { origins[0].members[0].role = 'recursor'; }, /TypeError/);
    const repeat = analyze([base, entry], 'Test.Main', 'checked', false);
    assert.equal(repeat.id, index.id);
    rejects(() => tool.assertCurrent(index, [entry, base]), /OWNERSHIP_STALE/);
    rejects(() => tool.assertCurrent(index, [base, capture(sources[grammar] + '-- new\n', grammar)]),
      /OWNERSHIP_STALE/);
    rejects(() => tool.assertCurrent({ ...index }, [base, entry]), /OWNERSHIP_INDEX/);
    rejects(() => tool.analyze({ snapshots: [base, { ...entry }], entry: 'Test.Main' }), /SNAPSHOT/);
    rejects(() => tool.analyze({ snapshots: [entry, base], entry: 'Test.Main' }), /OWNERSHIP_REFUSED/);
    rejects(() => tool.analyze({ snapshots: [base, entry, capture('def extra : Nat := 0\n', grammar, 'Extra')],
      entry: 'Test.Main' }), /OWNERSHIP_REFUSED/);
    const bad = capture('import Test.Base\ndef good : Nat := seed\ndef bad : Nat := true\n', grammar);
    let error;
    try { tool.analyze({ snapshots: [base, bad], entry: 'Test.Main' }); }
    catch (value) { error = value; }
    assert.match(error.message, /OWNERSHIP_REFUSED/); negatives++;
    assert.equal(error.cause.module, 'Test.Main');
    assert.equal(error.cause.phase, 'elaboration');
    assert.equal(error.cause.origin.sourceIndex, 1);
    assert.deepEqual(error.cause.origin.sourceName, ['bad']);
    assert.equal(error.cause.origin.phase, 'stableDeclaration');
    assert.match(error.cause.detail, /typeMismatch/);
  }
  assert.notEqual(prepared.lean.index.id, prepared.ps.index.id);
  assert.equal(prepared.lean.index.admissionsSha256, prepared.ps.index.admissionsSha256);
  rejects(() => tool.analyze({ snapshots: [], entry: 'Test.Main' }), /OWNERSHIP_CLOSURE/);
  rejects(() => tool.analyze({ snapshots: [prepared.lean.base, prepared.lean.base], entry: 'Test.Base' }),
    /OWNERSHIP_SOURCE/);
  rejects(() => tool.analyze({ snapshots: [prepared.lean.base, prepared.ps.entry], entry: 'Test.Main' }),
    /OWNERSHIP_REQUEST/);
  rejects(() => tool.analyze({ snapshots: [capture('def x := "bad')], entry: 'Test.Main' }),
    /OWNERSHIP_SOURCE/);
  rejects(() => createSourceOwnershipTool({ ...configuration, lexicalTool: { ...lexical } }),
    /OWNERSHIP_LEXICAL_TOOL/);
  rejects(() => createSourceOwnershipTool({ ...configuration, sha256: '0'.repeat(64) }), /TOOL_IDENTITY/);
  rejects(() => createSourceOwnershipTool({ ...configuration, checkerSha256: '0'.repeat(64) }), /TOOL_IDENTITY/);
  rejects(() => tool.analyze({ snapshots: [prepared.lean.base], entry: 'Absent' }), /OWNERSHIP_REQUEST/);
  rejects(() => tool.analyze({ snapshots: [prepared.lean.base], entry: 'Test.Base', assurance: 'verified' }),
    /OWNERSHIP_REQUEST/);

  const declarations = {
    lean: 'namespace Model\ninductive Flag where\n  | off\n  | on\n' +
      'structure Box where\n  value : Nat\nend Model\n',
    ps: 'namespace Model\ninductive Flag where {\n  | off\n  | on\n}\n' +
      'structure Box where {\n  value : Nat\n}\nend Model\n',
  };
  const normalized = {
    lean: 'namespace Math\ndef accumulate (n : Nat) (acc : Nat) : Nat := match n with\n' +
      '  | Nat.zero => acc\n  | Nat.succ k => accumulate k (Nat.succ acc)\nend Math\n',
    ps: 'namespace Math\ndef accumulate(n : Nat, acc : Nat) : Nat := match n with {\n' +
      '  | Nat.zero => acc\n  | Nat.succ k => accumulate(k, Nat.succ(acc))\n}\nend Math\n',
  };
  const ordinary = {
    lean: 'namespace Loop\npartial def prior (n : Nat) : Id Nat := do\n' +
      '  if Nat.beq n 0 then\n    return 0\n  let mut i := 0\n  while Nat.blt i 1 do\n' +
      '    let previous : Nat := Id.run (prior (Nat.sub n 1))\n' +
      '    return Nat.succ previous\n  return 999\nend Loop\n',
    ps: 'namespace Loop\npartial def prior(n : Nat) : Id(Nat) := do {\n' +
      '  if (Nat.beq(n, 0)) { return 0 }\n  let mut i := 0\n  while (Nat.blt(i, 1)) {\n' +
      '    let previous : Nat := Id.run(prior(Nat.sub(n, 1)))\n' +
      '    return Nat.succ(previous)\n  }\n  return 999\n}\nend Loop\n',
  };
  for (const grammar of ['lean', 'ps']) {
    const data = analyze([capture(declarations[grammar], grammar)]);
    const roles = data.modules[0].origins.flatMap(o => o.members.map(m => m.role));
    for (const role of ['inductiveType', 'constructor', 'recursor', 'structureType'])
      assert.ok(roles.includes(role), role);
    const normalizedIndex = analyze([capture(normalized[grammar], grammar)]);
    const origin = normalizedIndex.modules[0].origins[0];
    assert.deepEqual(origin.members.map(m => m.role), ['normalizedWorker', 'publicWrapper']);
    assert.ok(origin.normalization);
    assert.ok(origin.members[0].name.some(c => c[0] === 'n'));
    const partial = capture(ordinary[grammar], grammar);
    rejects(() => tool.analyze({ snapshots: [partial], entry: 'Test.Main' }), /OWNERSHIP_REFUSED/);
    const loop = analyze([partial], 'Test.Main', 'ordinary-checked');
    assert.ok(loop.partialNames.length);
    assert.ok(loop.modules[0].origins.flatMap(o => o.members).some(m => m.role === 'normalizedWorker'));
    assert.ok(loop.modules[0].origins.flatMap(o => o.members).some(m => m.role === 'publicWrapper'));
  }

  // A host-selected malformed helper is a transport test, never an alternate compiler.
  const goodWire = native('index', [{ module: 'Test.Base', kind: 'lean',
    text: 'def seed : Nat := 7\n' }], 'Test.Base');
  goodWire.wire.requestId = hash(JSON.stringify(['psc1-source-ownership/1',
    goodWire.wire.sourceClosureDigest, 'Test.Base', 'checked']));
  const mutations = [
    w => { w.sourceClosureDigest = '0'.repeat(64); },
    w => { w.modules[0].module = 'Wrong'; },
    w => { w.modules[0].byteLength++; },
    w => { w.modules[0].origins[0].sourceIndex++; },
    w => { w.modules[0].origins[0].nameSpan.start.byteOffset++; },
    w => { w.modules[0].origins[0].members[0].role = 'invented'; },
    w => { w.modules[0].origins[0].members[0].index++; },
    w => { w.modules[0].origins[0].members[0].displayName = 'misleading'; },
    w => { w.modules[0].origins[0].members[0].name = [['n', '01']]; },
    w => { w.modules[0].origins[0].members[0].name = []; },
    w => { w.modules[0].origins[0].members.push(w.modules[0].origins[0].members[0]); },
    w => { w.sourceCoreDeclarations++; },
    w => { w.authority = 'publish'; },
    w => { w.modules[0].origins[0].normalization = {
      workerName: [['s', 'other']], span: w.modules[0].origins[0].span }; },
  ];
  for (const [i, mutate] of mutations.entries()) {
    const wire = structuredClone(goodWire.wire); mutate(wire);
    const helper = path.join(directory, 'malformed-' + i);
    fs.writeFileSync(helper, '#!/usr/bin/python3\nimport sys\nopen(sys.argv[3],"w").write(' +
      JSON.stringify(JSON.stringify(wire)) + ')\n', { mode: 0o700 });
    const malformed = createSourceOwnershipTool({ ...configuration,
      executable: helper, sha256: hash(fs.readFileSync(helper)) });
    rejects(() => malformed.analyze({ snapshots: [prepared.lean.base], entry: 'Test.Base' }));
  }

  function transportFixture(file, admissions) {
    fs.writeFileSync(file, '#!/usr/bin/python3\nimport sys\n' +
      'open(sys.argv[3],"w").write(' + JSON.stringify(JSON.stringify(goodWire.wire)) + ')\n' +
      'open(sys.argv[4],"w").write(' + JSON.stringify(admissions.toString('utf8')) + ')\n' +
      'open(sys.argv[5],"w").write(' + JSON.stringify(goodWire.ir.toString('utf8')) + ')\n',
      { mode: 0o700 });
    return createSourceOwnershipTool({ ...configuration, executable: file,
      sha256: hash(fs.readFileSync(file)) });
  }
  const replay = transportFixture(path.join(directory, 'valid-wire'), goodWire.admissions)
    .analyze({ snapshots: [prepared.lean.base], entry: 'Test.Base' });
  assert.equal(replay.checker.accepted, true);
  assert.equal(replay.admissionsSha256, hash(goodWire.admissions));
  const invalidGraph = transportFixture(path.join(directory, 'invalid-graph'), Buffer.from('{}\n'));
  rejects(() => invalidGraph.analyze({ snapshots: [prepared.lean.base], entry: 'Test.Base' }), /PSC1_CHECKER_/);

  // Exact current compiler import closure is preserved; this sidecar is not promoted.
  const owned = readOwnedCompilerSources('Ps.CompilerUnified.Service');
  const digest = compilerSourceClosureDigest(owned.map(s => ({ ...s, kind: 'lean' })));
  assert.equal(owned.length, 121);
  assert.equal(digest, '60dd756e29cf6fbd44386e342318c53b22f41f2f3beb21b05aa39505a366271a');
  const changed = spawnSync('git', ['diff', '--name-only',
    'b63d09c8f79f3886565c788c478cb9937057080d', 'HEAD', '--',
    'packages', 'npm-cli', 'lean-toolchain', 'scripts/bounded-process.py',
    'scripts/selfhost-qualification-profiles.mjs', 'scripts/slim-universal-input.json',
    'scripts/slim-universal-package.mjs'], { encoding: 'utf8' });
  assert.equal(changed.status, 0);
  assert.equal(changed.stdout.trim(), '');

  const compilerSnapshots = owned.map(row => capture(row.text, 'lean', row.module));
  const compilerIndex = analyze(compilerSnapshots, 'Ps.CompilerUnified.Service', 'ordinary-checked');
  console.log('PSC1_OWNERSHIP_COMPILER:', JSON.stringify({ grammar: 'lean', modules: compilerIndex.modules.length,
    members: compilerIndex.sourceCoreDeclarations, ...compilerIndex.metrics }));
  const translatedOutput = path.join(directory, 'ps-census.json');
  const census = boundedRun(path.resolve('.lake/build/bin/psc1_source_census_probe'),
    ['--grammar', 'ps', '--out', translatedOutput, '--modules',
      ...owned.flatMap(row => [row.module, path.resolve(row.path)])],
    { timeoutMs: 240000, timeoutPolicy: 'standard-240s' });
  assert.equal(census.status, 0, census.stderr);
  const translated = JSON.parse(fs.readFileSync(translatedOutput, 'utf8')).records;
  assert.equal(translated.length, owned.length);
  assert.ok(translated.every(row => row.parse === 'accepted' && row.elaboration === 'accepted'));
  const psCompiler = analyze(translated.map(row => capture(row.inputSource, 'ps', row.module)),
    'Ps.CompilerUnified.Service', 'ordinary-checked');
  assert.equal(psCompiler.admissionsSha256, compilerIndex.admissionsSha256);
  assert.equal(psCompiler.originalIrSha256, compilerIndex.originalIrSha256);
  console.log('PSC1_OWNERSHIP_COMPILER:', JSON.stringify({ grammar: 'ps', modules: psCompiler.modules.length,
    members: psCompiler.sourceCoreDeclarations, ...psCompiler.metrics }));


  fs.mkdirSync('dist/source-ownership', { recursive: true });
  const receipt = { schema: 'psc1-source-ownership-tests/1', status: 'passed',
    implementation: process.env.GITHUB_SHA ?? null, references, negativeCases: negatives,
    nativeHelperSha256: sha256, checkerSha256,
    preservedCompiler: { modules: owned.length, sourceClosureDigest: digest },
    records, authority: { readOnlyOwnership: true, rename: false, publication: false } };
  fs.writeFileSync('dist/source-ownership/qualification.json', JSON.stringify(receipt, null, 2) + '\n');
  console.log('PSC1_SOURCE_OWNERSHIP: PASS', JSON.stringify({ references, negatives, records: records.length }));
} finally { fs.rmSync(directory, { recursive: true, force: true }); }
