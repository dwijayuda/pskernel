import assert from 'node:assert/strict';
import { censusOptions, validateCensusLane, requireStrictCensus } from './compiler-source-census-contract.mjs';
const modules = [
  { name: 'Ps.A', path: 'Ps/A.lean', utf8Bytes: 4, imports: [] },
  { name: 'Ps.B', path: 'Ps/B.lean', utf8Bytes: 7, imports: ['Ps.A'] }
];
function report(grammar) {
  return { schema: 'psc1-live-source-stage-probe/1', authoritative: false, grammar,
    sourceDerivation: grammar === 'lean' ? 'repository-lean-source' : 'owned-canonical-translation-from-lean',
    admission: 'not-run', ir: 'not-run', generatedExecution: 'not-run', fixedPoint: 'not-run',
    records: modules.map(m => ({ module: m.name, path: m.path, grammar, utf8Bytes: m.utf8Bytes,
      translation: grammar === 'lean' ? 'not-applicable' : 'accepted',
      ...(grammar === 'ps' ? { inputSource: 'α', inputUtf8Bytes: 2 } : { inputUtf8Bytes: m.utf8Bytes }),
      parse: 'accepted', elaboration: 'accepted', parsedImports: m.imports })) };
}
let checks = 0;
function rejects(change, grammar = 'lean') {
  const data = report(grammar); change(data);
  assert.throws(() => validateCensusLane(data, modules, grammar)); checks++;
}
for (const grammar of ['lean', 'ps']) {
  validateCensusLane(report(grammar), modules, grammar); checks++;
  rejects(r => r.records.pop(), grammar);
  rejects(r => r.records.push(r.records[0]), grammar);
  rejects(r => r.records[1] = structuredClone(r.records[0]), grammar);
  rejects(r => r.records.reverse(), grammar);
  rejects(r => r.records[1].module = 'Ps.Unknown', grammar);
  rejects(r => r.records[0].path = 'stale.lean', grammar);
  rejects(r => r.records[0].utf8Bytes++, grammar);
  rejects(r => r.records[1].parsedImports = [], grammar);
  rejects(r => r.records[0].grammar = 'unknown', grammar);
  rejects(r => r.sourceDerivation = 'independently-authored', grammar);
}
rejects(r => r.records[0].inputUtf8Bytes++, 'ps');
rejects(r => r.records[0].inputSource = undefined, 'ps');
rejects(r => r.records[0].parse = 'skipped');
rejects(r => r.records[0].elaboration = 'blocked-by-import');
rejects(r => { r.records[0].elaboration = 'refused'; r.records[0].detail = 'refusal'; });
const blocked = report('lean');
blocked.records[0].parse = 'refused';
blocked.records[0].elaboration = 'blocked-by-parse';
blocked.records[0].detail = 'expected source refusal';
blocked.records[1].elaboration = 'blocked-by-import';
blocked.records[1].blockedImports = ['Ps.A'];
validateCensusLane(blocked, modules, 'lean'); checks++;
const translated = report('ps');
translated.records[0] = { module: 'Ps.A', path: 'Ps/A.lean', grammar: 'ps', utf8Bytes: 4,
  translation: 'refused', parse: 'blocked-by-translation', elaboration: 'blocked-by-translation',
  detail: 'expected printer refusal' };
translated.records[1].elaboration = 'blocked-by-import';
translated.records[1].blockedImports = ['Ps.A'];
validateCensusLane(translated, modules, 'ps'); checks++;
const phases = [{ name: 'semantic-compiler', modules: modules.map(m => m.name) }];
const lanes = Object.fromEntries(['lean', 'ps'].map(g => [g, {
  probe: { completed: true, status: 0 }, observed: report(g) }]));
requireStrictCensus(phases, lanes, 'semantic-compiler'); checks++;
lanes.ps.observed = translated;
assert.throws(() => requireStrictCensus(phases, lanes, 'semantic-compiler')); checks++;
lanes.ps.observed = report('ps'); lanes.ps.probe.completed = false;
assert.throws(() => requireStrictCensus(phases, lanes, 'semantic-compiler')); checks++;
assert.deepEqual(censusOptions([]), { strictPhase: null }); checks++;
assert.equal(censusOptions(['--strict-phase', 'semantic-compiler']).strictPhase, 'semantic-compiler'); checks++;
for (const args of [['--strict-phase', 'unknown'], ['--unknown'], ['--strict-phase'], ['extra']]) {
  assert.throws(() => censusOptions(args)); checks++;
}
console.log('PSC1_CENSUS_CONTRACT: ' + checks + ' checks passed');
