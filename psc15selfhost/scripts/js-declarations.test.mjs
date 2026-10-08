import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { bindObservedBuildContext } from './observed-build-context.mjs';
import { test } from 'node:test';
import { artifactId, artifactKey, canonicalBytes, canonicalArtifact } from './artifact-evidence.mjs';
import { publicApiArtifact } from './public-api-artifact.mjs';
import { projectSourceSignature, printSourceSignatureType } from './public-api-signature.mjs';
import { createDirectJsDeclarations, verifyDirectJsDeclarations, directJsDeclarationProfile, directJsUniformDeclarationProfile } from './js-declarations.mjs';
import { createCheckedBuildGraph } from './checked-build-evidence.mjs';
import { packObservedBuildArchive, verifyObservedBuildArchive } from './observed-build-archive.mjs';
import { uniformSpecializationArtifact, uniformJsRepresentationProfile } from './uniform-specialization.mjs';
import { fixture as genericFixture } from './js-origin-test-fixture.mjs';

const name = v => ({ k: 's', p: { k: 'a' }, v });
const constant = v => ({ k: 'const', n: name(v), ls: [] });
const forall = (n, t, b) => ({ k: 'forall', n: name(n), t, b, bi: 'default' });
const record = (value, domain, contract = 'psc-runtime-ir-json/1') => {
  const bytes = canonicalBytes(value); return { bytes, identity: artifactId(bytes, domain, contract) };
};
const textRecord = (text, domain, contract) => {
  const bytes = Buffer.from(text); return { bytes, identity: artifactId(bytes, domain, contract) };
};
function fixture() {
  const runtime = ['psc-runtime-ir-json/1', [], [], [], [
    ['actualValue', [], [], ['primitive', 'nat'], ['literal', ['natural', '42']]],
    ['actualFn', [], [['x', ['primitive', 'bool']]], ['primitive', 'bool'], ['var', 'x']],
  ]];
  return {
    publicApi: publicApiArtifact(canonicalBytes(['psc-public-api-ir/1', 'all-prepared-declarations', [
      ['constant', 'definition', name('sourceValue'), [], constant('Nat')],
      ['constant', 'definition', name('sourceFn'), [], forall('input', constant('Bool'), constant('Bool'))],
    ]])),
    erasureTable: record(['psc-erasure-declarations/1', 'declaration-inventory', [
      [name('sourceValue'), ['runtime', 'actualValue']], [name('sourceFn'), ['runtime', 'actualFn']],
    ]], 'erasure-table', 'psc-erasure-declarations/1'),
    runtimeIr: record(runtime, 'runtime-ir'), verifiedIr: record(runtime, 'verified-ir'),
    specializedIr: record(runtime, 'specialized-ir'),
    jsIr: record(['psc-js-ir-json/1', [], [
      ['actualValue', [], ['literal', ['natural', '42']]], ['actualFn', ['x'], ['var', 'x']],
    ]], 'js-ir', 'psc-js-ir-json/1'),
    javaScript: textRecord('export const actualValue = 42n;\nexport function actualFn(x) { return x; }\n',
      'javascript-output', 'psc-direct-javascript/es2022'),
  };
}
const ids = subjects => Object.fromEntries(Object.entries(subjects).map(([key, record]) => [key, record.identity]));

test('source signatures preserve generic binders and reject unsupported source types without fallbacks', () => {
  const generic = forall('A', { k: 'sort', l: { k: 's', o: { k: 'z' } } },
    forall('value', { k: 'b', i: 0 }, { k: 'b', i: 1 }));
  const projected = projectSourceSignature(generic);
  assert.equal(projected.typeParameters[0].sourceName.v, 'A');
  assert.deepEqual(projected.type, ['function', [['parameter', 0]], ['parameter', 0]]);
  assert.equal(printSourceSignatureType(projected.type), '(_arg0: T0) => T0');
  const array = { k: 'app', f: constant('Array'), a: constant('Nat') };
  assert.equal(printSourceSignatureType(projectSourceSignature(forall('values', array, array)).type),
    '(_arg0: Array<bigint>) => Array<bigint>');
  assert.throws(() => projectSourceSignature({ ...array, f: { ...array.f, ls: [{ k: 'z' }] } }), /TYPE_FORM_UNSUPPORTED/);
  assert.throws(() => projectSourceSignature(forall('x', constant('Nat'), { k: 'b', i: 0 })), /DEPENDENT_VALUE/);
  assert.throws(() => projectSourceSignature(forall('P', { k: 'sort', l: { k: 'z' } }, constant('Nat'))), /AMBIGUOUS_SORT/);
  assert.throws(() => projectSourceSignature(constant('UnresolvedAlias')), /NAMED_TYPE_UNSUPPORTED/);
  assert.throws(() => projectSourceSignature(generic, { maxDepth: 1 }), /RESOURCE/);
  assert.throws(() => projectSourceSignature(generic, { maxNodes: 1 }), /RESOURCE/);
});

test('direct declaration products bind source signatures to actual export names and replay exact subjects', async () => {
  const subjects = fixture(), product = createDirectJsDeclarations({ subjects });
  const text = product.declarations.bytes.toString();
  assert.equal(text, 'declare const $pscDeclaration0: bigint;\nexport { $pscDeclaration0 as actualValue };\n' +
    'declare const $pscDeclaration1: (_arg0: boolean) => boolean;\nexport { $pscDeclaration1 as actualFn };\n');
  assert.equal(text.includes('sourceValue'), false);
  const signature = JSON.parse(product.sourceSignatures.bytes);
  assert.equal(signature.signatures[0].sourceName.v, 'sourceValue');
  assert.equal(signature.inferredFromTarget, false);
  const byId = new Map(Object.values(subjects).map(record => [artifactKey(record.identity), record.bytes]));
  const options = { expectedSubjects: ids(subjects), resolveArtifact: async id => byId.get(artifactKey(id)) };
  assert.equal((await verifyDirectJsDeclarations(product, options)).exportInventoryChecked, true);
  for (const key of ['declarations', 'sourceSignatures', 'binding']) {
    const before = product[key];
    const changed = key === 'declarations' ? Buffer.from(text.replace('bigint', 'number')) :
      canonicalBytes({ ...JSON.parse(before.bytes), invented: true });
    const forged = { bytes: changed, identity: artifactId(changed, before.identity.domain, before.identity.contract) };
    await assert.rejects(verifyDirectJsDeclarations({ ...product, [key]: forged }, options), /PRODUCT_BINDING/);
  }
  await assert.rejects(verifyDirectJsDeclarations(product, { ...options, expectedProfile: 'invented' }), /PROFILE/);
  assert.throws(() => createDirectJsDeclarations({ subjects, maxBytes: 1 }), /RESOURCE/);
  assert.throws(() => createDirectJsDeclarations({ subjects, maxTotalBytes: 1 }), /RESOURCE/);
});

test('signature drift, target drift and generic instance names cannot create a false public API', () => {
  const subjects = fixture();
  const api = JSON.parse(subjects.publicApi.bytes); api[2][0][4] = constant('String');
  assert.throws(() => createDirectJsDeclarations({ subjects: { ...subjects, publicApi: publicApiArtifact(canonicalBytes(api)) } }),
    /SOURCE_RUNTIME_SIGNATURE/);
  const target = JSON.parse(subjects.jsIr.bytes); target[2][1][1][0] = 'other';
  assert.throws(() => createDirectJsDeclarations({ subjects: { ...subjects,
    jsIr: record(target, 'js-ir', 'psc-js-ir-json/1') } }), /TARGET_DECLARATION_INVENTORY/);
  const generic = genericFixture();
  assert.throws(() => createDirectJsDeclarations({ subjects: {
    publicApi: generic.publicApi,
    erasureTable: textRecord(generic.erasureTable, 'erasure-table', 'psc-erasure-declarations/1'),
    runtimeIr: generic.runtimeIr, verifiedIr: generic.verifiedIr, specializedIr: generic.specializedIr, jsIr: generic.jsIr,
    javaScript: textRecord(generic.javaScript, 'javascript-output', 'psc-direct-javascript/es2022'),
  } }), /GENERIC_EXPORT_UNAVAILABLE/);
});

async function checkDeclarationGraph(subjects, profile) {
  const uniform = profile === directJsUniformDeclarationProfile;
  const selection = uniform ? { javaScriptRepresentation: uniformJsRepresentationProfile } : {};
  const selectedStage = uniform ? 'uniformSpecializedIr' : 'specializedIr';
  const admissions = '{"admissions":[],"format":"proofscript-checked-admissions","version":2}';
  const canonicalAdmissionsId = artifactId(Buffer.from(admissions), 'canonical-admissions', 'proofscript-checked-admissions/2');
  const pscvCertificate = canonicalArtifact({ contract: 'pscv-cert/1', canonicalAdmissionsId, fixture: true }, 'pscv-cert', 'pscv-cert/1');
  const certifiedSourceArtifact = canonicalArtifact({ contract: 'psc-certified-source/1', canonicalAdmissionsId,
    certificateId: pscvCertificate.identity, fixture: true }, 'certified-source', 'psc-certified-source/1');
  const inputs = {
    sourceKind: 'lean', sources: ['synthetic source/authority fixture; exact independent product checks only'], admissions,
    publicApi: subjects.publicApi.bytes.toString(), erasureCorrespondence: subjects.erasureTable.bytes.toString(),
    irStages: Object.fromEntries(['runtimeIr', 'verifiedIr', selectedStage, 'jsIr'].map(key => [key, subjects[key].bytes.toString()])),
    directJavaScript: subjects.javaScript.bytes.toString(), declarationProfile: profile, ...selection,
    pscvCertificate, certifiedSourceArtifact, compilerBytes: Buffer.from('synthetic compiler'), compilerKind: 'fixture',
    provider: { profile: 'fixture' }, providerSecurity: { profile: 'fixture' }, kernelContract: { id: 'fixture' },
    hostSources: [], runtime: { implementation: 'fixture' },
  };
  const backendRegistry = canonicalArtifact(JSON.parse(await readFile(new URL('../contracts/backends/BACKEND_REGISTRY_V1.json', import.meta.url))),
    'backend-registry', 'psc-backend-registry/1');
  const languageAuthority = canonicalArtifact({ languageEdition: 'fixture' }, 'language-authority', 'psc-language-authority-snapshot/1');
  const observed = createCheckedBuildGraph(inputs);
  const context = { backendRegistry, languageAuthority, backendId: 'javascript', ...selection };
  const build = bindObservedBuildContext(observed, context);
  if (uniform) {
    assert.throws(() => createCheckedBuildGraph({ ...inputs, javaScriptRepresentation: undefined }), /UNSELECTED_UNIFORM_STAGE/);
    assert.throws(() => createCheckedBuildGraph({ ...inputs, irStages: { ...inputs.irStages, specializedIr: inputs.irStages.verifiedIr } }), /MIXED_SPECIALIZATION/);
    assert.throws(() => bindObservedBuildContext(observed, { ...context, javaScriptRepresentation: undefined }), /REPRESENTATION_GRAPH/);
    assert.equal(JSON.parse(build.backendDescriptor.bytes).inputDomain, 'uniform-specialized-ir');
    assert.equal(build.specializationInstances, undefined);
  }
  const bundle = JSON.parse(build.artifactBundle.bytes);
  assert.deepEqual(bundle.publicApiArtifacts.map(item => item.role),
    ['source-api', 'declarations', 'declaration-signatures', 'declaration-binding']);
  assert.equal(bundle.targetToolchainArtifacts.length, 0);
  assert.ok(build.graph.entries.some(entry => entry.source.suffix === '.d.ts'));
  assert.equal(build.originGraph, undefined); assert.equal(build.directSourceMap, undefined);
  const definitions = build.graph.entries.flatMap(entry => entry.canonicalValue?.passId ? [entry.canonicalValue] : []);
  const pass = definitions.find(value => value.passId === 'psc-emit-direct-js-declarations/1');
  assert.equal(pass.effects.authorityEffect, 'none');
  assert.equal(definitions.some(value => value.passId === 'typescript-to-es2022/1'), false);
  const archive = packObservedBuildArchive(build);
  const replay = await verifyObservedBuildArchive(archive.bytes, { expectedGraphId: build.identity,
    allowedAssumptions: [...new Set(definitions.flatMap(value => value.assumptionIds))] });
  assert.equal(replay.kind, 'accepted', replay.reason);
  assert.equal(replay.preservationVerified, false);
  assert.throws(() => createCheckedBuildGraph({ ...inputs, declarationProfile: 'unknown' }), /DECLARATION_PROFILE/);
  if (uniform) {
    assert.equal(replay.uniformSpecializationCorrespondences.length, 1);
    assert.equal(replay.uniformSpecializationCorrespondences[0].bytesPreserved, true);
    assert.equal(replay.specializationCorrespondences.length, 0);
    assert.equal(replay.buildContext.artifactBundle.profileSelection.profile, uniformJsRepresentationProfile);
    assert.equal(replay.buildContext.queryKeysVerified, true);
  }
  return build;
}
test('requested direct declaration products publish through the shared graph and replay without origins or tsc', async () => {
  await checkDeclarationGraph(fixture(), directJsDeclarationProfile);
});

test('explicit uniform subjects retain source generics and replay without inferring them from instances', async () => {
  const generic = genericFixture(), raw = JSON.parse(generic.runtimeIr.bytes);
  const uniform = uniformSpecializationArtifact(canonicalBytes(['psc-uniform-specialized-ir/1', 'psc-js-uniform-values/1', raw]));
  const subjects = {
    publicApi: generic.publicApi,
    erasureTable: textRecord(generic.erasureTable, 'erasure-table', 'psc-erasure-declarations/1'),
    runtimeIr: generic.runtimeIr, verifiedIr: generic.verifiedIr, uniformSpecializedIr: uniform,
    jsIr: record(['psc-js-ir-json/1', [], [
      ['g', ['x'], ['var', 'x']], ['answer', [], ['call', ['var', 'g'], [['literal', ['natural', '7']]]]],
    ]], 'js-ir', 'psc-js-ir-json/1'),
    javaScript: textRecord('export function g(x) { return x; }\nexport const answer = g(7n);\n',
      'javascript-output', 'psc-direct-javascript/es2022'),
  };
  await checkDeclarationGraph(subjects, directJsUniformDeclarationProfile);
  const product = createDirectJsDeclarations({ subjects, profile: directJsUniformDeclarationProfile });
  assert.match(product.declarations.bytes.toString(), /<T0>\(_arg0: T0\) => T0/);
  assert.match(product.declarations.bytes.toString(), / as g }/);
  const byId = new Map(Object.values(subjects).map(record => [artifactKey(record.identity), record.bytes]));
  await verifyDirectJsDeclarations(product, { expectedSubjects: ids(subjects),
    expectedProfile: directJsUniformDeclarationProfile, resolveArtifact: id => byId.get(artifactKey(id)) });
  assert.throws(() => createDirectJsDeclarations({ subjects }), /SUBJECTS/);
  await assert.rejects(verifyDirectJsDeclarations(product, { expectedSubjects: ids(subjects),
    resolveArtifact: id => byId.get(artifactKey(id)) }), /SUBJECTS/);
  const genericConstant = ['psc-runtime-ir-json/1', [], [], [], [
    ['value', ['A'], [], ['primitive', 'nat'], ['literal', ['natural', '7']]],
  ]];
  const valueSubjects = {
    publicApi: publicApiArtifact(canonicalBytes(['psc-public-api-ir/1', 'all-prepared-declarations', [
      ['constant', 'definition', name('value'), [],
        forall('A', { k: 'sort', l: { k: 's', o: { k: 'z' } } }, constant('Nat'))],
    ]])),
    erasureTable: record(['psc-erasure-declarations/1', 'declaration-inventory', [[name('value'), ['runtime', 'value']]]],
      'erasure-table', 'psc-erasure-declarations/1'),
    runtimeIr: record(genericConstant, 'runtime-ir'), verifiedIr: record(genericConstant, 'verified-ir'),
    uniformSpecializedIr: uniformSpecializationArtifact(canonicalBytes(
      ['psc-uniform-specialized-ir/1', 'psc-js-uniform-values/1', genericConstant])),
    jsIr: record(['psc-js-ir-json/1', [], [['value', [], ['literal', ['natural', '7']]]]], 'js-ir', 'psc-js-ir-json/1'),
    javaScript: textRecord('export const value = 7n;\n', 'javascript-output', 'psc-direct-javascript/es2022'),
  };
  assert.throws(() => createDirectJsDeclarations({ subjects: valueSubjects, profile: directJsUniformDeclarationProfile }),
    /GENERIC_VALUE_EXPORT_UNSUPPORTED/);
});
