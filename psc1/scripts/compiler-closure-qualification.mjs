// Exact selected-closure admission and strict IR qualification, Linux CI only.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { phaseNames } from './compiler-source-census-contract.mjs';
import { validateClosureCounts } from './compiler-closure-contract.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const args = process.argv.slice(2);
assert.ok([2, 4].includes(args.length) && args[0] === '--phase' && phaseNames.includes(args[1]) &&
  (args.length === 2 || args[2] === '--assurance'),
  'usage: compiler-closure-qualification.mjs --phase ' + phaseNames.join('|') +
    ' [--assurance checked|ordinary-checked]');
const selected = args[1];
const assurance = args[3] || 'checked';
assert.ok(['checked', 'ordinary-checked'].includes(assurance), 'PSC1_CLOSURE_UNKNOWN_ASSURANCE');
const commit = process.env.GITHUB_SHA;
assert.ok(commit, 'PSC1_CLOSURE_REQUIRES_CLOUD_COMMIT');
const census = path.join(root, 'dist/scoped-correctness/compiler-source-census');
const inventory = JSON.parse(fs.readFileSync(path.join(census, 'inventory.json'), 'utf8'));
assert.equal(inventory.commit, commit);
const phase = inventory.phases.find(p => p.name === selected);
assert.ok(phase);
assert.equal(new Set(phase.modules).size, phase.modules.length);
assert.ok(phase.modules.length > 0);
const moduleIndex = new Map(inventory.modules.map(entry => [entry.name, entry]));
assert.equal(moduleIndex.size, inventory.modules.length);
const hash = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const sourceEntries = phase.modules.map(name => {
  const entry = moduleIndex.get(name);
  assert.ok(entry, 'owned phase module: ' + name);
  const bytes = fs.readFileSync(path.join(root, entry.path));
  assert.equal(bytes.length, entry.utf8Bytes);
  assert.equal(hash(bytes), entry.sha256);
  return entry;
});
const inputs = {};
for (const grammar of ['lean', 'ps']) {
  const lane = inventory.lanes[grammar];
  assert.equal(lane.probe.completed, true);
  assert.equal(lane.probe.status, 0);
  const stages = JSON.parse(fs.readFileSync(path.join(census, lane.stages), 'utf8'));
  assert.equal(stages.grammar, grammar);
  assert.equal(stages.records.length, inventory.modules.length);
  const byModule = new Map(stages.records.map(row => [row.module, row]));
  assert.equal(byModule.size, stages.records.length);
  inputs[grammar] = sourceEntries.map(entry => {
    const row = byModule.get(entry.name);
    assert.ok(row, 'complete selected lane');
    assert.equal(row.path, entry.path);
    assert.equal(row.parse, 'accepted');
    assert.equal(row.elaboration, 'accepted');
    assert.deepEqual(row.parsedImports, entry.imports);
    let inputPath = entry.path;
    let inputSha256 = entry.sha256;
    let inputUtf8Bytes = entry.utf8Bytes;
    if (grammar === 'ps') {
      assert.equal(row.translation, 'accepted');
      assert.equal(row.inputArtifact, 'translated-ps/' + entry.name + '.ps');
      inputPath = path.relative(root, path.join(census, row.inputArtifact)).split(path.sep).join('/');
      inputSha256 = row.inputSha256;
      inputUtf8Bytes = row.inputUtf8Bytes;
    }
    const input = fs.readFileSync(path.join(root, inputPath));
    assert.equal(input.length, inputUtf8Bytes);
    assert.equal(hash(input), inputSha256);
    return { module: entry.name, originalPath: entry.path, originalSha256: entry.sha256,
      imports: entry.imports, inputPath, inputUtf8Bytes, inputSha256 };
  });
}
function unchanged() {
  for (const entry of sourceEntries) {
    const bytes = fs.readFileSync(path.join(root, entry.path));
    assert.equal(bytes.length, entry.utf8Bytes);
    assert.equal(hash(bytes), entry.sha256, 'original closure changed during qualification');
  }
  for (const entries of Object.values(inputs)) for (const entry of entries) {
    const bytes = fs.readFileSync(path.join(root, entry.inputPath));
    assert.equal(bytes.length, entry.inputUtf8Bytes);
    assert.equal(hash(bytes), entry.inputSha256, 'parser input changed during qualification');
  }
}
const evidence = path.join(root, 'dist/scoped-correctness/compiler-closure', selected, assurance);
fs.mkdirSync(evidence, { recursive: true });
const binary = process.env.PSC1_CENSUS_PROBE || path.join(root, '.lake/build/bin/psc1_source_census_probe');
const binarySha256 = hash(fs.readFileSync(binary));
const lanes = {};
for (const grammar of ['lean', 'ps']) {
  const directory = path.join(evidence, grammar);
  fs.mkdirSync(directory, { recursive: true });
  const output = path.join(directory, 'qualification.json');
  const admissions = path.join(directory, 'admissions.json');
  const ir = admissions + '.ir.json';
  for (const owned of [output, admissions, ir]) fs.rmSync(owned, { force: true });
  const run = spawnSync(binary, ['--qualify', '--assurance', assurance, '--grammar', grammar, '--out', output,
    '--admissions', admissions, '--modules', ...inputs[grammar].flatMap(row => [row.module, row.inputPath])],
    { cwd: root, encoding: 'utf8', timeout: 240000, maxBuffer: 32 * 1024 * 1024 });
  let observed = null, integrityError = null, admissionsArtifact = null, irArtifact = null;
  try {
    unchanged();
    observed = JSON.parse(fs.readFileSync(output, 'utf8'));
    assert.equal(observed.schema, 'psc1-compiler-closure-probe/2');
    assert.equal(observed.authoritative, false);
    assert.equal(observed.grammar, grammar);
    assert.equal(observed.assurance, assurance);
    assert.equal(observed.frontend, 'owned-native-PSC1');
    assert.equal(observed.leanVersion, '4.35.0');
    assert.equal(observed.leanCommit, 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
    for (const key of ['generatedExecution', 'selfCompilation', 'fixedPoint'])
      assert.equal(observed[key], 'not-run');
    assert.equal(observed.formalPreservation, 'not-provided');
    assert.equal(observed.records.length, inputs[grammar].length, 'exact complete selected closure');
    observed.records.forEach((row, index) => {
      const expected = inputs[grammar][index];
      assert.equal(row.module, expected.module);
      assert.equal(row.inputPath, expected.inputPath);
      assert.equal(row.inputUtf8Bytes, expected.inputUtf8Bytes);
      assert.deepEqual(row.parsedImports, expected.imports);
      assert.equal(row.parse, 'accepted');
      assert.equal(row.elaboration, 'accepted');
      assert.equal(row.origins.length, row.sourceDeclarations, 'every source declaration has actual origins');
      row.origins.forEach((origin, sourceIndex) => {
        assert.equal(origin.sourceIndex, sourceIndex);
        assert.equal(typeof origin.sourceDeclaration, 'string');
        origin.members.forEach((member, index) => {
          assert.equal(member.index, index);
          assert.equal(typeof member.name, 'string');
        });
      });
    });
    for (const key of ['preparation', 'admission', 'ir'])
      assert.ok(['accepted', 'refused', 'not-run', 'in-progress'].includes(observed[key]));
    if (observed.admission === 'accepted' || observed.ir !== 'not-run')
      assert.equal(observed.preparation, 'accepted');
    if (observed.ir !== 'not-run') assert.equal(observed.admission, 'accepted');
    if (observed.preparation === 'accepted') {
      const sourceCount = observed.records.reduce((sum, row) => sum +
        row.origins.reduce((count, origin) => count + origin.members.length, 0), 0);
      validateClosureCounts(observed, sourceCount, assurance);
      const bytes = fs.readFileSync(admissions);
      assert.equal(bytes.length, observed.admissionsUtf8Bytes);
      admissionsArtifact = { path: grammar + '/admissions.json', utf8Bytes: bytes.length, sha256: hash(bytes) };
    }
    if (observed.ir === 'accepted' && observed.irEncoding === 'accepted') {
      const bytes = fs.readFileSync(ir);
      assert.equal(bytes.length, observed.irUtf8Bytes);
      const graph = JSON.parse(bytes.toString('utf8'));
      assert.equal(JSON.stringify(graph), bytes.toString('utf8'), 'deterministic compact IR encoding');
      assert.ok(Array.isArray(graph) && graph.length === 5 && graph[0] === 'psc1-ir/1');
      for (const index of [1, 2, 3, 4]) assert.ok(Array.isArray(graph[index]));
      assert.equal(graph[2].length, observed.irStructures);
      assert.equal(graph[3].length, observed.irInductives);
      assert.equal(graph[4].length, observed.irDeclarations);
      const intrinsics = new Set(), primitiveTypes = new Set();
      function visit(value) {
        if (!Array.isArray(value)) return;
        if (value.length === 4 && value[0] === 'intrinsic' &&
            Array.isArray(value[1]) && typeof value[1][0] === 'string')
          intrinsics.add(JSON.stringify(value[1]));
        if (value.length === 2 && value[0] === 'primitive' && typeof value[1] === 'string')
          primitiveTypes.add(value[1]);
        value.forEach(visit);
      }
      visit(graph);
      irArtifact = { path: grammar + '/admissions.json.ir.json',
        utf8Bytes: bytes.length, sha256: hash(bytes),
        inventoryScope: 'all expressions and types in the actual original validated IR',
        intrinsics: [...intrinsics].sort().map(text => JSON.parse(text)),
        primitiveTypes: [...primitiveTypes].sort() };
    }
  } catch (error) { integrityError = error.message; }
  const passed = !run.error && run.status === 0 && !integrityError &&
    observed?.preparation === 'accepted' && observed?.admission === 'accepted' && observed?.ir === 'accepted' && observed?.irEncoding === 'accepted';
  lanes[grammar] = { inputs: inputs[grammar], observed, admissionsArtifact, irArtifact,
    probe: { status: run.status, signal: run.signal, error: run.error?.message || null,
      stdout: run.stdout, stderr: run.stderr, integrityError },
    passed };
  console.log('PSC1_CLOSURE_LANE: ' + JSON.stringify({ grammar, passed, status: run.status,
    preparation: observed?.preparation, admission: observed?.admission, ir: observed?.ir, irEncoding: observed?.irEncoding,
    sourceCoreDeclarations: observed?.sourceCoreDeclarations,
    logicalCoreDeclarations: observed?.coreDeclarations, partialNames: observed?.partialNames, admissionsArtifact, irArtifact,
    detail: observed?.detail, firstFindings: observed?.findings?.slice(0, 8),
    findingCount: observed?.findingCount,
    integrityError, error: run.error?.message }));
}
unchanged();
const canonicalAdmissionBytesParity = lanes.lean.admissionsArtifact && lanes.ps.admissionsArtifact ?
  (lanes.lean.admissionsArtifact.sha256 === lanes.ps.admissionsArtifact.sha256 ? 'accepted' : 'refused') : 'not-run';
const canonicalIrBytesParity = lanes.lean.irArtifact && lanes.ps.irArtifact ?
  (lanes.lean.irArtifact.sha256 === lanes.ps.irArtifact.sha256 ? 'accepted' : 'refused') : 'not-run';
const passed = lanes.lean.passed && lanes.ps.passed &&
  canonicalAdmissionBytesParity === 'accepted' && canonicalIrBytesParity === 'accepted';
const report = { schema: 'psc1-compiler-closure-qualification/2', commit,
  phase: selected, assurance, binarySha256, roots: phase.roots, modules: sourceEntries.length, explicitImportGraphOnly: true,
  psSourceDerivation: 'owned-canonical-translation-from-lean', independentlyAuthoredPsCompiler: false,
  passed, canonicalAdmissionBytesParity, canonicalIrBytesParity, lanes, generatedExecution: 'not-run', selfCompilation: 'not-run',
  fixedPoint: 'not-run', formalPreservation: 'not-provided' };
fs.writeFileSync(path.join(evidence, 'results.json'), JSON.stringify(report, null, 2) + '\n');
console.log('PSC1_COMPILER_CLOSURE_QUALIFICATION: ' +
  JSON.stringify({ phase: selected, modules: report.modules, passed, canonicalAdmissionBytesParity, canonicalIrBytesParity,
    binarySha256, lanes: Object.fromEntries(Object.entries(lanes).map(([grammar, lane]) => [grammar,
      { passed: lane.passed, coreDeclarations: lane.observed?.coreDeclarations,
        admissions: lane.admissionsArtifact, ir: lane.irArtifact }])),
    generatedExecution: 'not-run', fixedPoint: 'not-run' }));
assert.equal(passed, true, 'PSC1_COMPILER_CLOSURE_REFUSED: retained exact lane diagnostics');
