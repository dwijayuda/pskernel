// Integrity and strict closure policy shared by the live census and its contract tests.
import assert from 'node:assert/strict';

export const phaseNames = ['semantic-compiler', 'directjs-compiler', 'rust-compiler'];
export function censusOptions(args) {
  if (args.length === 0) return { strictPhase: null };
  if (args.length === 2 && args[0] === '--strict-phase' && phaseNames.includes(args[1]))
    return { strictPhase: args[1] };
  throw new Error('PSC1_CENSUS_ARGUMENTS: expected [--strict-phase ' + phaseNames.join('|') + ']');
}
export function validateCensusLane(observed, modules, grammar) {
  assert.equal(observed.schema, 'psc1-live-source-stage-probe/1');
  assert.equal(observed.authoritative, false);
  assert.equal(observed.grammar, grammar);
  assert.equal(observed.sourceDerivation, grammar === 'lean' ?
    'repository-lean-source' : 'owned-canonical-translation-from-lean');
  for (const stage of ['admission', 'ir', 'generatedExecution', 'fixedPoint'])
    assert.equal(observed[stage], 'not-run');
  assert.equal(observed.records.length, modules.length, 'complete census record count');
  const failed = new Set();
  observed.records.forEach((row, i) => {
    const expected = modules[i];
    assert.equal(row.module, expected.name, 'exact unique ordered module identity');
    assert.equal(row.path, expected.path);
    assert.equal(row.grammar, grammar);
    assert.equal(row.utf8Bytes, expected.utf8Bytes);
    if (grammar === 'lean') {
      assert.equal(row.translation, 'not-applicable');
      assert.equal(row.inputUtf8Bytes, expected.utf8Bytes);
    } else if (row.translation === 'refused') {
      assert.equal(row.parse, 'blocked-by-translation');
      assert.equal(row.elaboration, 'blocked-by-translation');
      assert.equal(typeof row.detail, 'string');
      assert.equal(row.inputSource, undefined);
    } else {
      assert.equal(row.translation, 'accepted');
      assert.equal(typeof row.inputSource, 'string');
      assert.equal(Buffer.byteLength(row.inputSource), row.inputUtf8Bytes);
    }
    if (row.translation !== 'refused') {
      assert.ok(['accepted', 'refused'].includes(row.parse), 'measured parse verdict');
      if (row.parse === 'refused') {
        assert.equal(row.elaboration, 'blocked-by-parse');
        assert.equal(typeof row.detail, 'string');
      } else {
        assert.deepEqual(row.parsedImports, expected.imports, 'exact parsed import ownership');
        const blocked = expected.imports.filter(name => failed.has(name));
        if (blocked.length) {
          assert.equal(row.elaboration, 'blocked-by-import');
          assert.deepEqual(row.blockedImports, blocked);
        } else {
          assert.ok(['accepted', 'refused'].includes(row.elaboration), 'measured elaboration verdict');
          if (row.elaboration === 'refused') assert.equal(typeof row.detail, 'string');
        }
      }
    }
    if (row.elaboration !== 'accepted') failed.add(row.module);
  });
  return observed;
}
export function requireStrictCensus(phases, lanes, selected) {
  if (!selected) return;
  const phase = phases.find(row => row.name === selected);
  assert.ok(phase, 'known strict phase');
  for (const grammar of ['lean', 'ps']) {
    const lane = lanes[grammar];
    assert.equal(lane.probe.completed, true, 'strict lane complete: ' + grammar);
    assert.equal(lane.probe.status, 0);
    const rows = lane.observed.records.filter(row => phase.modules.includes(row.module));
    assert.equal(rows.length, phase.modules.length);
    const refused = rows.filter(row => row.parse !== 'accepted' ||
      row.elaboration !== 'accepted' || (grammar === 'ps' && row.translation !== 'accepted'));
    assert.deepEqual(refused.map(row => row.module), [],
      'PSC1_CENSUS_STRICT_REFUSAL: ' + grammar + '/' + selected);
  }
}
