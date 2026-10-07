import assert from 'node:assert/strict';
import { test } from 'node:test';
import { spawnSync } from 'node:child_process';
import { artifactId, artifactKey, canonicalBytes, canonicalArtifact, passDefinition, recordPassExecution } from './artifact-evidence.mjs';
import { verifySpecializationCorrespondence, createSpecializationInstanceMap, verifySpecializationInstanceMap } from './specialization-correspondence.mjs';
import { packObservedBuildArchive, verifyObservedBuildArchive } from './observed-build-archive.mjs';

const nat = ['primitive', 'nat'], bool = ['primitive', 'bool'], unit = ['primitive', 'unit'], aType = ['typeParameter', 'A'];
const ref = name => ['var', name], lit = number => ['literal', ['natural', String(number)]];
const call = (name, types = [], args = []) => ['call', ref(name), types, args];
const decl = (name, parameters, result, body, binders = []) => [name, binders, parameters, result, body];
const module = declarations => ['psc-runtime-ir-json/1', [], [], [], declarations];
const identity = decl('id', [['x', aType]], aType, ref('x'), ['A']);
function artifact(value, domain) {
  const bytes = canonicalBytes(value); return { bytes, identity: artifactId(bytes, domain, 'psc-runtime-ir-json/1') };
}
function check(input, output, limits) {
  return verifySpecializationCorrespondence(artifact(input, 'verified-ir'), artifact(output, 'specialized-ir'), limits);
}
function actual(flag = '--artifacts') {
  const result = spawnSync('.lake/build/bin/psc1_ir_specialize_tests' + (process.platform === 'win32' ? '.exe' : ''),
    [flag], { encoding: 'utf8', timeout: 30000, maxBuffer: 16 * 1024 * 1024 });
  assert.equal(result.status, 0, result.error?.message ?? result.stderr);
  const stages = JSON.parse(result.stdout);
  return [JSON.parse(stages.verifiedIr), JSON.parse(stages.specializedIr)];
}

test('actual strictly validated recursive List, Box and function specializations satisfy independent correspondence', async () => {
  const [source, target] = actual(), checked = check(source, target);
  assert.equal(checked.correspondenceChecked, true);
  assert.equal(checked.observed.instances, 7);
  assert.equal(checked.globalPreservationProved, false);
  assert.equal(checked.invariantValidation, false);
  // The relation does not depend on producer mangling or worklist order.
  const names = new Map([['Box$spec$U32', 'different.box'], ['List$spec$U32', 'different.list'],
    ['id$spec$U32', 'different.id'], ['length$spec$U32', 'different.length']]);
  const renamed = JSON.parse(JSON.stringify(target), (_key, value) => typeof value === 'string' ? names.get(value) ?? value : value);
  renamed[4].reverse();
  assert.equal(check(source, renamed).correspondenceChecked, true);
  const input = artifact(source, 'verified-ir'), output = artifact(renamed, 'specialized-ir');
  const { map, result } = createSpecializationInstanceMap(input, output);
  const value = JSON.parse(map.bytes);
  assert.equal(value.instances.length, result.observed.instances);
  assert.deepEqual(value.instances.filter(item => item[0] === 'declaration').map(item => item[3]), renamed[4].map(item => item[0]));
  assert.deepEqual(value.instances.find(item => item[3] === 'different.id'),
    ['declaration', 'id', [['primitive', 'uint32']], 'different.id']);
  const artifacts = new Map([input, output].map(item => [artifactKey(item.identity), item.bytes]));
  const policy = { resolveArtifact: id => artifacts.get(artifactKey(id)), expectedInputId: input.identity, expectedOutputId: output.identity };
  const replay = await verifySpecializationInstanceMap(map, policy);
  assert.equal(replay.correspondenceChecked, true);
  assert.equal(replay.globalPreservationProved, false);
  const changed = structuredClone(value); changed.instances.find(item => item[3] === 'different.id')[1] = 'wrong-source';
  await assert.rejects(verifySpecializationInstanceMap(
    canonicalArtifact(changed, 'specialization-map', 'psc-specialization-instance-map/1'), policy), /WITNESS_CORRESPONDENCE/);
  await assert.rejects(verifySpecializationInstanceMap(map, { ...policy, expectedOutputId: input.identity }), /WITNESS_SUBJECT/);
  await assert.rejects(verifySpecializationInstanceMap(map, { ...policy, resourceLimits: { maxWork: 0 } }),
    error => error.kind === 'resourceExhausted');
});

test('changed computations, layouts, signatures, missing roots and unjustified instances reject', () => {
  const [source, target] = actual();
  const mutations = [
    value => { value[4].find(item => item[0] === 'id$spec$U32')[4] = ['literal', ['machineInteger', 'uint32', '1']]; },
    value => { value[2][0][2][0][1] = nat; },
    value => { value[3][0][2].reverse(); },
    value => { value[4].find(item => item[0] === 'length$spec$U32')[4][4][1][2][1][2] = 'sub'; },
    value => { value[4] = value[4].filter(item => item[0] !== 'lengthTwo'); },
    value => { value[4].push(decl('extra', [], nat, lit(0))); },
    value => { value[4].push(structuredClone(value[4][0])); },
  ];
  for (const mutate of mutations) {
    const changed = structuredClone(target); mutate(changed);
    assert.throws(() => check(source, changed), /PSC_SPECIALIZATION_/);
  }
});

test('lexical shadowing is preserved and generated global names cannot capture local calls', () => {
  const [scopeSource, scopeTarget] = actual('--scope-artifacts');
  assert.equal(check(scopeSource, scopeTarget).observed.instances, 5);
  assert.deepEqual(scopeTarget[4].map(item => item[0]), ['parameterScope', 'letScope', 'lambdaScope', 'matchScope']);
  const fnType = ['function', [nat], nat];
  const localBody = ['let', 'id', fnType, ['lambda', [['x', nat]], nat, ref('x')],
    ['if', ['literal', ['bool', true]], call('id', [], [lit(42)]), lit(0)]];
  const source = module([identity, decl('answer', [], nat, localBody)]);
  assert.equal(check(source, module([source[4][1]])).observed.instances, 1);
  const lambdaSource = module([identity, decl('apply', [], ['function', [fnType], nat],
    ['lambda', [['id', fnType]], nat, call('id', [], [lit(42)])])]);
  assert.equal(check(lambdaSource, module([lambdaSource[4][1]])).observed.instances, 1);
  const captureSource = module([identity, decl('answer', [['chosen', fnType]], nat, call('id', [nat], [lit(42)]))]);
  const captureTarget = module([decl('answer', [['chosen', fnType]], nat, call('chosen', [], [lit(42)])),
    decl('chosen', [['x', nat]], nat, ref('x'))]);
  assert.throws(() => check(captureSource, captureTarget), /INSTANCE_CAPTURE/);
});

test('ground witnesses compose across nested generic layouts and distinct instances cannot alias', () => {
  const boxNat = ['named', 'Box', [nat]], monoBox = ['named', 'b', []];
  const source = module([identity, decl('answer', [['value', boxNat]], boxNat, call('id', [boxNat], [ref('value')]))]);
  source[2] = [['Box', ['A'], [['value', aType]]]];
  const target = module([decl('answer', [['value', monoBox]], monoBox, call('i', [], [ref('value')])),
    decl('i', [['x', monoBox]], monoBox, ref('x'))]);
  target[2] = [['b', [], [['value', nat]]]];
  assert.equal(check(source, target).observed.instances, 3);
  const ignore = decl('ignore', [], unit, ['literal', ['unit']], ['A']);
  const two = module([ignore, decl('n', [], unit, call('ignore', [nat])), decl('b', [], unit, call('ignore', [bool]))]);
  const collision = module([decl('n', [], unit, call('same')), decl('b', [], unit, call('same')),
    decl('same', [], unit, ['literal', ['unit']])]);
  assert.throws(() => check(two, collision), /INSTANCE_COLLISION/);
});

test('artifact identities, canonical schema and explicit work/instance/depth bounds are mandatory', () => {
  const [source, target] = actual();
  for (const limits of [{ maxWork: 0 }, { maxInstances: 0 }, { maxBytes: 0 }, { maxTypeDepth: 0 }, { maxInstanceKeyBytes: 0 }]) {
    assert.throws(() => check(source, target, limits), error => error.kind === 'resourceExhausted');
  }
  assert.throws(() => check(source, target, { unknown: 1 }), /LIMIT_POLICY/);
  assert.throws(() => check(source, target, { maxTypeDepth: 513 }), /LIMIT_POLICY/);
  assert.throws(() => verifySpecializationCorrespondence(artifact(source, 'runtime-ir'), artifact(target, 'specialized-ir')), /ARTIFACT_CONTRACT/);
  const wrong = artifact(target, 'specialized-ir'); wrong.bytes = canonicalBytes(source);
  assert.throws(() => verifySpecializationCorrespondence(artifact(source, 'verified-ir'), wrong));
});

test('offline archive replay rejects a fully rehashed false specialization with a freshly pinned graph', async () => {
  const [source, target] = actual();
  target[4].find(item => item[0] === 'id$spec$U32')[4] = ['literal', ['machineInteger', 'uint32', '9']];
  const input = artifact(source, 'verified-ir'), output = artifact(target, 'specialized-ir');
  const implementation = canonicalArtifact({ fixture: 'false-specialization' }, 'implementation', 'fixture/1');
  const definition = passDefinition({ passId: 'psc-pass-specialize/1', version: 1,
    inputContract: input.identity.contract, outputContract: output.identity.contract,
    semanticRelationId: 'psc-specialization-runtime-refinement/1', resourceContractId: 'fixture/1',
    determinismClass: 'fixture', totalityClass: 'fixture', implementationId: implementation.identity,
    validatorId: null, theoremIds: [], assumptionIds: [] });
  const execution = recordPassExecution({ definition, inputs: [input], outputs: [output],
    parameters: {}, semanticIdentity: { fixture: true }, resourcePolicy: { fixture: true } });
  const items = [input, output, implementation, definition, execution.action, execution];
  const graph = canonicalArtifact({ schemaVersion: 1, contract: 'psc-observed-build-graph/1', authority: 'audit-record-only',
    entries: items.map(item => ({ identity: item.identity, source: { kind: 'archive-required' },
      ...([definition, execution.action, execution].includes(item) ? { canonicalValue: JSON.parse(item.bytes) } : {}) })),
    executions: [execution.identity], coverage: 'observed-composite-edges', remaining: ['synthetic malicious fixture'] },
  'build-graph', 'psc-observed-build-graph/1');
  const archive = packObservedBuildArchive({ ...graph, artifacts: new Map(items.map(item => [artifactKey(item.identity), item.bytes])) });
  const replay = await verifyObservedBuildArchive(archive.bytes, { expectedGraphId: graph.identity, allowedAssumptions: [] });
  assert.equal(replay.kind, 'rejectedInvalid');
  assert.match(replay.reason, /SPECIALIZATION_CORRESPONDENCE/);
});
