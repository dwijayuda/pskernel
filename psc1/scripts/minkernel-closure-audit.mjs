// Linux CI measurement of the actual current compiler admissions and foundation.
// This audit grants no checker authority and never qualifies a self-hosted kernel.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import { readOwnedCompilerSources } from '../host-tools/compiler-source-inputs.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
assert.equal(process.platform, 'linux', 'PSC1_MIN_AUDIT_LINUX_ONLY');
assert.equal(path.resolve(process.cwd()), root, 'run from the psc1 workspace');
assert.match(process.env.GITHUB_SHA || '', /^[0-9a-f]{40}$/, 'exact cloud commit required');
const directory = path.join(root, 'dist/pskernel-min/closure');
fs.mkdirSync(directory, { recursive: true });
const hash = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const fileIdentity = file => {
  const bytes = fs.readFileSync(file);
  return { path: path.relative(root, file).split(path.sep).join('/'), bytes: bytes.length,
    sha256: hash(bytes) };
};
const output = name => path.join(directory, name);
const sourceRows = readOwnedCompilerSources('Ps.CompilerUnified.Service');
assert.ok(sourceRows.length > 0);
const sources = sourceRows.map(row => ({ module: row.module, ...fileIdentity(path.join(root, row.path)),
  imports: [...row.text.matchAll(/^import\s+(.+)$/gm)].flatMap(m => m[1].trim().split(/\s+/)) }));
assert.equal(new Set(sources.map(row => row.module)).size, sources.length);
const names = new Set(sources.map(row => row.module));
for (const row of sources) {
  assert.ok(row.imports.every(name => names.has(name)), 'closed explicit source import graph');
  assert.ok(!/^PsKernelLean\.|^Lean\.|^Std\./.test(row.module), 'no reference checker in compiler closure');
}
const unchangedSources = () => {
  for (const row of sources) assert.deepEqual(fileIdentity(path.join(root, row.path)),
    { path: row.path, bytes: row.bytes, sha256: row.sha256 }, 'exact source bytes unchanged');
};
const tools = {};
const events = [];
function run(binaryName, args, logName) {
  const binary = path.join(root, '.lake/build/bin', binaryName);
  const identity = fileIdentity(binary);
  tools[binaryName] = identity;
  const started = Date.now();
  const result = spawnSync(binary, args, { cwd: root, encoding: 'utf8', timeout: 240000,
    maxBuffer: 32 * 1024 * 1024 });
  fs.writeFileSync(output(logName + '.stdout.log'), result.stdout || '');
  fs.writeFileSync(output(logName + '.stderr.log'), result.stderr || '');
  const event = { binary: binaryName, args, status: result.status, signal: result.signal,
    elapsedMs: Date.now() - started, error: result.error?.message || null };
  events.push(event);
  assert.deepEqual(fileIdentity(binary), identity, 'probe executable unchanged');
  unchangedSources();
  assert.ok(!result.error && result.status === 0, JSON.stringify(event) + '\n' + result.stderr);
}
for (const name of ['compiler-qualification.json', 'compiler-admissions.json',
  'compiler-admissions.json.ir.json', 'prelude.json', 'report.json']) {
  fs.rmSync(output(name), { force: true });
}
run('psc1_source_census_probe', ['--qualify', '--assurance', 'ordinary-checked',
  '--grammar', 'lean', '--out', output('compiler-qualification.json'),
  '--admissions', output('compiler-admissions.json'), '--modules',
  ...sources.flatMap(row => [row.module, row.path])], 'compiler');
run('psc2_joint_closure_inventory', ['--prelude', output('prelude.json')], 'prelude');
const observed = JSON.parse(fs.readFileSync(output('compiler-qualification.json'), 'utf8'));
assert.equal(observed.schema, 'psc1-compiler-closure-probe/2');
assert.equal(observed.assurance, 'ordinary-checked');
assert.equal(observed.grammar, 'lean');
assert.equal(observed.leanVersion, '4.35.0');
assert.equal(observed.leanCommit, 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
for (const stage of ['preparation', 'admission', 'ir', 'irEncoding']) assert.equal(observed[stage], 'accepted');
assert.equal(observed.records.length, sources.length);
observed.records.forEach((row, index) => {
  const expected = sources[index];
  assert.equal(row.module, expected.module);
  assert.equal(row.inputPath, expected.path);
  assert.equal(row.inputUtf8Bytes, expected.bytes);
  assert.deepEqual(row.parsedImports, expected.imports);
  assert.equal(row.parse, 'accepted');
  assert.equal(row.elaboration, 'accepted');
  assert.equal(row.origins.length, row.sourceDeclarations);
});
const members = observed.records.reduce((sum, row) => sum + row.origins.reduce(
  (count, origin) => count + origin.members.length, 0), 0);
assert.equal(observed.sourceCoreDeclarations, members);
assert.equal(observed.coreDeclarations, members + observed.partialNames.length);
const canonical = JSON.parse(fs.readFileSync(output('compiler-admissions.json'), 'utf8'));
assert.equal(canonical.format, 'proofscript-checked-admissions');
assert.equal(canonical.version, 2);
assert.ok(Array.isArray(canonical.admissions));
const prelude = JSON.parse(fs.readFileSync(output('prelude.json'), 'utf8'));
assert.ok(Array.isArray(prelude) && prelude.length > 0);
const increment = (table, key) => { table[key] = (table[key] || 0) + 1; };
const sorted = table => Object.fromEntries(Object.entries(table).sort(([a], [b]) => a < b ? -1 : a > b ? 1 : 0));
function nameText(value) {
  const parts = [];
  let current = value;
  while (current && current.k !== 'a') {
    assert.ok(current.k === 's' || current.k === 'n', 'known structured name');
    parts.push(String(current.v)); current = current.p;
  }
  assert.equal(current?.k, 'a');
  return parts.reverse().join('.');
}
function emptyCounters() {
  // A declaration kind can be named "constructor"; inherited Object properties
  // must never participate in numerical counts, including constant names.
  const dictionary = () => Object.create(null);
  return { expressions: dictionary(), levels: dictionary(), binderInfo: dictionary(),
    constants: dictionary(), projectionTypes: dictionary(), declarationKinds: dictionary(),
    levelArgumentArities: dictionary(), levelParameterArities: dictionary(),
    universeParameters: dictionary(), inductiveTypes: 0, constructors: 0, inductiveGroups: 0 };
}
function countExpressions(roots, counter) {
  // Separate expression/level visitors avoid confusing overlapping name/level tags.
  const pending = roots.filter(value => value !== null).map(value => ['expr', value]);
  while (pending.length) {
    const [kind, value] = pending.pop();
    assert.ok(value && typeof value === 'object', 'well formed exported node');
    const tag = value.k;
    if (kind === 'level') {
      increment(counter.levels, tag);
      if (tag === 's') pending.push(['level', value.o]);
      else if (tag === 'max' || tag === 'imax') pending.push(['level', value.l], ['level', value.r]);
      else if (tag === 'p') increment(counter.universeParameters, nameText(value.n));
      else assert.equal(tag, 'z', 'unknown exported universe form');
      continue;
    }
    increment(counter.expressions, tag);
    switch (tag) {
      case 'b': case 'nat': case 'str': break;
      case 'sort': pending.push(['level', value.l]); break;
      case 'const':
        increment(counter.constants, nameText(value.n));
        assert.ok(Array.isArray(value.ls));
        increment(counter.levelArgumentArities, String(value.ls.length));
        for (const level of value.ls) pending.push(['level', level]);
        break;
      case 'app': pending.push(['expr', value.f], ['expr', value.a]); break;
      case 'lam': case 'forall':
        increment(counter.binderInfo, value.bi);
        pending.push(['expr', value.t], ['expr', value.b]); break;
      case 'let': pending.push(['expr', value.t], ['expr', value.v], ['expr', value.b]); break;
      case 'proj':
        increment(counter.projectionTypes, nameText(value.n));
        pending.push(['expr', value.e]); break;
      default: assert.fail('unknown exported expression tag: ' + tag);
    }
  }
}
const compiler = emptyCounters();
for (const admission of canonical.admissions) {
  const declaration = admission.declaration;
  if (admission.kind === 'constant') {
    increment(compiler.declarationKinds, declaration.k);
    increment(compiler.levelParameterArities, String(declaration.lp.length));
    countExpressions([declaration.t, declaration.v], compiler);
  } else {
    assert.equal(admission.kind, 'inductive');
    increment(compiler.declarationKinds, 'inductive');
    increment(compiler.levelParameterArities, String(declaration.lp.length));
    compiler.inductiveGroups++;
    for (const type of declaration.ts) {
      compiler.inductiveTypes++;
      compiler.constructors += type.cs.length;
      countExpressions([type.t, ...type.cs.map(ctor => ctor.t)], compiler);
    }
  }
}
const foundation = emptyCounters();
for (const declaration of prelude) {
  increment(foundation.declarationKinds, declaration.kind);
  increment(foundation.levelParameterArities, String(declaration.levelParameters.length));
  countExpressions([declaration.type, declaration.value], foundation);
  if (declaration.kind === 'inductive') foundation.inductiveTypes++;
  if (declaration.kind === 'constructor') foundation.constructors++;
}
function finish(counter) {
  for (const key of Object.keys(counter)) if (typeof counter[key] === 'object') counter[key] = sorted(counter[key]);
  return counter;
}
const foundationalAxioms = prelude.filter(row => row.kind === 'axiom').map(row => row.name).sort();
const usedFoundationalAxioms = foundationalAxioms.filter(name => compiler.constants[name]);
const primitiveFamilies = ['Nat', 'Int', 'Bool', 'String', 'Array', 'List', 'Option', 'Except', 'Prod', 'Quot', 'Quotient'];
const primitiveReferences = Object.fromEntries(primitiveFamilies.map(family => [family,
  Object.entries(compiler.constants).filter(([name]) => name === family || name.startsWith(family + '.'))
    .reduce((count, [, uses]) => count + uses, 0)]));
const artifacts = ['compiler-qualification.json', 'compiler-admissions.json',
  'compiler-admissions.json.ir.json', 'prelude.json'].map(name => fileIdentity(output(name)));
assert.equal(artifacts[1].bytes, observed.admissionsUtf8Bytes);
const report = {
  schema: 'psc1-min-kernel-current-closure-audit/1', commit: process.env.GITHUB_SHA,
  authoritative: false, root: 'Ps.CompilerUnified.Service', grammar: 'lean',
  scope: 'Current exact compiler source, actual canonical logical admissions and separately exported implicit prelude.',
  sourceModules: sources.length, sourceCoreMembers: members, logicalCoreMembers: observed.coreDeclarations,
  partialNames: observed.partialNames, sources,
  sourceInventorySha256: hash(JSON.stringify(sources)),
  explicitImportEdges: sources.reduce((count, row) => count + row.imports.length, 0),
  sourceBytes: sources.reduce((count, row) => count + row.bytes, 0),
  compiler: finish(compiler), foundation: finish(foundation),
  canonicalAdmissionRecords: canonical.admissions.length,
  preludeDeclarationCount: prelude.length, foundationalAxioms, usedFoundationalAxioms, primitiveReferences,
  officialNativeAdmission: 'accepted-exact-retained-bytes-by-production-probe',
  originalStrictIr: 'accepted', grammarParity: 'not-measured-by-this-audit',
  reductionUse: 'Syntax counts do not measure which beta/delta/zeta/iota/DefEq rules execute; profiling remains pending.',
  minProfile: {
    scope: 'initial simply typed fragment; no full compiler bridge qualification',
    qualifiedCompilerModules: 0, qualifiedPracticalCoreCriteria: 0,
    canonicalCompilerAdmission: 'unsupported-current-profile',
    blockers: {
      inductiveGroups: compiler.inductiveGroups,
      projectionOccurrences: compiler.expressions.proj || 0,
      literalOccurrences: (compiler.expressions.nat || 0) + (compiler.expressions.str || 0),
      quantifiedTypes: compiler.expressions.forall || 0,
      importedFoundationAxioms: foundationalAxioms.length,
      partialDefinitionsRequiringExactLogicalBodyPairing: observed.partialNames.length,
      dependentBinderClassification: 'not-inferred-from-syntax-counts'
    },
    generatedKernelCheckingClosure: 'not-run', generations: 'G1/G2/G3-not-qualified-with-min'
  },
  performanceScope: 'Probe wall time includes parsing/elaboration/admission/IR; not an isolated checker benchmark.',
  tools, events, artifacts,
  trustBoundary: 'No parsed count or audit result grants admission, checker selection, publication or proof authority.'
};
unchangedSources();
fs.writeFileSync(output('report.json'), JSON.stringify(report, null, 2) + '\n');
console.log('PSC1_MIN_KERNEL_CLOSURE_AUDIT: ' + JSON.stringify({
  commit: report.commit, sourceModules: report.sourceModules, sourceCoreMembers: members,
  logicalCoreMembers: observed.coreDeclarations, admissionRecords: canonical.admissions.length,
  preludeDeclarations: prelude.length, foundationAxioms: foundationalAxioms.length,
  expressions: compiler.expressions, levels: compiler.levels,
  declarationKinds: compiler.declarationKinds, primitiveReferences,
  minQualifiedModules: 0, minQualifiedPracticalCoreCriteria: 0,
  report: fileIdentity(output('report.json'))
}));
