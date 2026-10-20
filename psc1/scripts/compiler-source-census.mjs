// Linux cloud CI diagnostic; never qualifies a self-hosted compiler.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

import { censusOptions, validateCensusLane, requireStrictCensus } from './compiler-source-census-contract.mjs';
const options = censusOptions(process.argv.slice(2));

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const lake = fs.readFileSync(path.join(root, 'lakefile.lean'), 'utf8');
const index = new Map();
for (const match of lake.matchAll(/lean_lib\s+(\w+)\s+where\n([\s\S]*?)(?=\n(?:lean_|@)|$)/g)) {
  const directory = match[2].match(/srcDir\s*:=\s*"([^"]+)"/)?.[1];
  if (!directory) continue;
  for (const entry of match[2].matchAll(/`([\w.]+)/g)) {
    const name = entry[1], relative = path.join(directory, ...name.split('.')) + '.lean';
    const bytes = fs.readFileSync(path.join(root, relative));
    const imports = [...bytes.toString('utf8').matchAll(/^import\s+(.+)$/gm)].flatMap(m => m[1].trim().split(/\s+/));
    index.set(name, { name, path: relative.split(path.sep).join('/'), utf8Bytes: bytes.length,
      sha256: crypto.createHash('sha256').update(bytes).digest('hex'), imports });
  }
}
const phases = [
  { name: 'semantic-compiler', roots: ['Ps.Compiler.Api', 'Ps.Compiler.Ordinary'] },
  { name: 'directjs-compiler', roots: ['Ps.Compiler.Api', 'Ps.Compiler.Ordinary', 'Ps.BackendCommon.Plan',
    'Ps.BackendJs.Lower', 'Ps.BackendJs.Validate', 'Ps.BackendJs.Print'] },
  { name: 'rust-compiler', roots: ['Ps.Compiler.Api', 'Ps.Compiler.Ordinary', 'Ps.BackendCommon.Plan', 'Ps.BackendRust.Module'] }
];
const all = new Set();
for (const phase of phases) {
  const seen = new Set(), ordered = [], stack = new Set();
  function visit(name) {
    if (seen.has(name)) return;
    if (stack.has(name)) throw new Error('PSC1_CENSUS_CYCLE: ' + name);
    const entry = index.get(name);
    if (!entry) throw new Error('PSC1_CENSUS_EXTERNAL_PORTABLE_IMPORT: ' + name);
    stack.add(name);
    for (const dependency of entry.imports) visit(dependency);
    stack.delete(name); seen.add(name); ordered.push(name); all.add(name);
  }
  phase.roots.forEach(visit);
  phase.modules = ordered;
  phase.utf8Bytes = ordered.reduce((n, name) => n + index.get(name).utf8Bytes, 0);
}
const ordered = [], seen = new Set();
function visit(name) {
  if (seen.has(name)) return;
  for (const dependency of index.get(name).imports) visit(dependency);
  seen.add(name); ordered.push(index.get(name));
}
for (const name of all) visit(name);
const evidence = path.join(root, 'dist/scoped-correctness/compiler-source-census');
fs.mkdirSync(evidence, { recursive: true });
const binary = process.env.PSC1_CENSUS_PROBE || path.join(root, '.lake/build/bin/psc1_source_census_probe');
const lanes = {};
for (const grammar of ['lean', 'ps']) {
  const filename = grammar === 'lean' ? 'stages.json' : 'stages-ps.json';
  const output = path.join(evidence, filename);
  // Remove only our exact previous output, before spawning; partial output cannot reuse stale acceptance.
  fs.rmSync(output, { force: true });
  const run = spawnSync(binary, ['--grammar', grammar, '--out', output, '--modules',
    ...ordered.flatMap(m => [m.name, m.path])], {
    cwd: root, encoding: 'utf8', timeout: 240000, maxBuffer: 32 * 1024 * 1024
  });
  let observed = null, integrityError = null;
  try {
    observed = JSON.parse(fs.readFileSync(output, 'utf8'));
    validateCensusLane(observed, ordered, grammar);
  } catch (error) { integrityError = error.message; }
  const probe = { status: run.status, signal: run.signal, error: run.error?.message || null,
    stdout: run.stdout, stderr: run.stderr,
    completed: !integrityError && observed?.records?.length === ordered.length,
    integrityError };
  lanes[grammar] = { probe, observed, stages: filename,
    sourceDerivation: grammar === 'lean' ? 'repository-lean-source' : 'owned-canonical-translation-from-lean' };
}
for (const entry of ordered) {
  const current = fs.readFileSync(path.join(root, entry.path));
  if (current.length !== entry.utf8Bytes ||
      crypto.createHash('sha256').update(current).digest('hex') !== entry.sha256)
    throw new Error('PSC1_CENSUS_SOURCE_CHANGED: ' + entry.name);
}
const psDirectory = path.join(evidence, 'translated-ps');
fs.mkdirSync(psDirectory, { recursive: true });
const ownedNames = new Set(ordered.map(m => m.name + '.ps'));
for (const filename of fs.readdirSync(psDirectory)) {
  if (!ownedNames.has(filename) || !fs.lstatSync(path.join(psDirectory, filename)).isFile())
    throw new Error('PSC1_CENSUS_UNEXPECTED_TRANSLATED_FILE: ' + filename);
  fs.rmSync(path.join(psDirectory, filename));
}
if (lanes.ps.probe.completed) {
  for (const row of lanes.ps.observed.records) {
    if (row.translation !== 'accepted') continue;
    if (!/^Ps(?:\.[A-Za-z0-9_]+)+$/.test(row.module))
      throw new Error('PSC1_CENSUS_UNSAFE_MODULE: ' + row.module);
    const input = Buffer.from(row.inputSource, 'utf8');
    row.inputSha256 = crypto.createHash('sha256').update(input).digest('hex');
    row.inputArtifact = 'translated-ps/' + row.module + '.ps';
    fs.writeFileSync(path.join(evidence, row.inputArtifact), input);
    delete row.inputSource;
  }
  fs.writeFileSync(path.join(evidence, lanes.ps.stages), JSON.stringify(lanes.ps.observed, null, 2) + '\n');
}
const observed = lanes.lean.observed;
const report = { schema: 'psc1-compiler-source-census/1', commit: process.env.GITHUB_SHA || null,
  explicitImportGraphOnly: true, implicitPreludeCensus: 'not-run', phases, modules: ordered,
  probe: lanes.lean.probe,
  lanes: Object.fromEntries(Object.entries(lanes).map(([grammar, lane]) => [grammar,
    { probe: lane.probe, stages: lane.stages, sourceDerivation: lane.sourceDerivation }])),
  selectedStrictPhase: options.strictPhase,
  generatedExecution: 'not-run', selfCompilation: 'not-run', fixedPoint: 'not-run' };
fs.writeFileSync(path.join(evidence, 'inventory.json'), JSON.stringify(report, null, 2) + '\n');
for (const [grammar, lane] of Object.entries(lanes)) {
  if (lane.probe.error || lane.probe.status !== 0 || !lane.probe.completed)
    throw new Error('PSC1_CENSUS_PROBE_FAILED: ' + grammar + ': ' +
      (lane.probe.error || lane.probe.integrityError || lane.probe.stderr));
  for (const phase of phases) {
    const rows = lane.observed.records.filter(row => phase.modules.includes(row.module));
    console.log('PSC1_COMPILER_CENSUS: ' + grammar + '/' + phase.name + ' ' + rows.length +
      ' modules; parse accepted=' + rows.filter(row => row.parse === 'accepted').length +
      '; elaboration accepted=' + rows.filter(row => row.elaboration === 'accepted').length);
    for (const stage of ['translation', 'parse', 'elaboration']) {
      const first = rows.find(row => row[stage] === 'refused');
      if (first) console.log('PSC1_COMPILER_CENSUS_FIRST_REFUSAL: ' +
        JSON.stringify({ grammar, phase: phase.name, stage, module: first.module,
          path: first.path, detail: first.detail, sourceDeclaration: first.sourceDeclaration,
          sourceIndex: first.sourceIndex, line: first.line, column: first.column }));
    }
  }
}
requireStrictCensus(phases, lanes, options.strictPhase);
// Diagnostic mode retains all source refusals; strict mode requires both complete lanes.

// These normalized compiler modules are maintained regressions, not a waiver for
// any other refusal. The full inventory above still reports every module.
for (const [module, stage] of [
  ['Ps.Syntax.Ast', 'parse'], ['Ps.Syntax.Ast', 'elaboration'],
  ['Ps.Erasure.Definition', 'elaboration'],
  ['Ps.Syntax.ParseCommon', 'parse'], ['Ps.Syntax.ParseCommon', 'elaboration'],
  ['Ps.Syntax.ParseBinding', 'parse'], ['Ps.Syntax.ParseBinding', 'elaboration'],
  ['Ps.Syntax.Operators', 'parse'], ['Ps.Syntax.Operators', 'elaboration'],
  ['Ps.Syntax.ParseLean', 'parse'], ['Ps.Syntax.ParseLean', 'elaboration'],
  ['Ps.Syntax.ParseData', 'parse'], ['Ps.Syntax.ParseData', 'elaboration'],
  ['Ps.Syntax.ParseDo', 'parse'], ['Ps.Syntax.ParseDo', 'elaboration']
]) {
  const row = observed.records.find(row => row.module === module);
  if (!row || row[stage] !== 'accepted') {
    throw new Error('PSC1_CENSUS_NORMALIZATION_REGRESSION: ' +
      JSON.stringify({ module, stage, observed: row || null }));
  }
}
