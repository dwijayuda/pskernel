import assert from 'node:assert/strict';
import { access, readFile, readdir } from 'node:fs/promises';

const root = new URL('../', import.meta.url);
const json = async path => JSON.parse(await readFile(new URL(path, root), 'utf8'));
const [migration, legacy, registry, trust, handoff] = await Promise.all([
  json('contracts/registry/V5_MIGRATION_STATUS.json'),
  json('contracts/registry/V3_IMPLEMENTATION_STATUS.json'),
  json('contracts/registry/ARCHITECTURE_REGISTRY.json'), json('TRUST_MANIFEST.json'),
  json('contracts/registry/V3_ASSURANCE_HANDOFF.json'),
]);
const sorted = values => [...values].sort();
const same = (a, b, label) => assert.deepEqual(sorted(a), sorted(b), label);
const unique = (values, label) => assert.equal(new Set(values).size, values.length, label);
assert.equal(migration.contract, 'psc-v5-migration-status/1');
assert.equal(migration.schemaVersion, 1);
assert.equal(migration.masterPlan, 'THE_PSCV_COMPILER_REFERENCE_VERSION_5.1.md');
assert.equal(registry.masterPlan, migration.masterPlan);
assert.equal(trust.masterPlan, migration.masterPlan);
assert.equal(trust.legacyImplementationReference, migration.decision.legacyImplementationReference);
assert.equal(migration.legacyLedger.sectionCount, legacy.sectionCoverage.length);
assert.equal(migration.legacyLedger.workstreamCount, legacy.workstreams.length);
unique(migration.workstreams.map(item => item.id), 'duplicate workstream');
same(migration.workstreams.map(item => item.id), legacy.workstreams.map(item => item.id), 'workstream coverage');
for (const item of migration.workstreams) {
  const old = legacy.workstreams.find(old => old.id === item.id);
  same(item.existingOwners, old.owners, 'lost owner: ' + item.id);
  same(item.v3Sections, old.sections, 'lost section: ' + item.id);
  const added = item.addedOwners ?? [];
  unique([...item.existingOwners, ...added], 'duplicate owner: ' + item.id);
  for (const owner of added) {
    assert.equal(typeof owner, 'string');
    assert.ok(!owner.startsWith('/') && !owner.includes('..') && !owner.includes('\\'), 'invalid owner path');
    await access(new URL(owner, root));
  }
  assert.ok(item.classifications.length > 0);
  for (const classification of item.classifications) assert.ok(migration.classificationVocabulary.includes(classification));
}
unique(migration.registeredSubsystems.map(item => item.id), 'duplicate subsystem');
const additions = new Set(['pscv-architecture/v5.1', 'psc-v5-migration-status/1']);
unique(migration.targetSubsystems.map(item => item.id), 'duplicate target subsystem');
same([...migration.registeredSubsystems, ...migration.targetSubsystems].map(item => item.id), registry.entries.filter(item => !additions.has(item.id)).map(item => item.id), 'registered subsystem coverage');
for (const item of [...migration.registeredSubsystems, ...migration.targetSubsystems]) assert.ok(migration.classificationVocabulary.includes(item.classification));
same(migration.assuranceObligations.map(item => item.id), handoff.obligations.map(item => item.id), 'lost assurance obligation');
const directory = 'packages/compiler-ir/src/Ps/CompilerIr/';
const files = (await readdir(new URL(directory, root))).filter(name => name.endsWith('.lean')).map(name => directory + name);
same(migration.compilerIrOwnership.map(item => item.path), files, 'compiler-ir ownership coverage');
for (const item of migration.compilerIrOwnership) assert.equal(item.physicalMove, 'deferred');
for (const relative of [migration.masterPlan, migration.decision.languageAuthority, ...migration.historicalEvidence]) await access(new URL(relative, root));
assert.equal(migration.decision.kernelScope, 'consume-contracts-and-evidence-only');
assert.equal(migration.acceptance.globalPreservationProved, false);
assert.equal(migration.acceptance.v5Conformance, false);
assert.equal(migration.acceptance.assuredRelease, false);
process.stdout.write('PSCV_V5_RECONCILIATION: PASS (' + migration.workstreams.length + ' workstreams; ' +
  migration.registeredSubsystems.length + ' inherited identities; ' + files.length + ' IR files; inventory only)\n');
