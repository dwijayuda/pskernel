import { createPortableWasmCanonicalRequest, deriveWasmCanonicalArtifacts } from './wasm-canonical-artifact.mjs';
import { fixture as originFixture } from './js-origin-test-fixture.mjs';
import assert from 'node:assert/strict';
import { test } from 'node:test';
import { createHash } from 'node:crypto';
import { createCheckedCompilerService } from './compiler-checked-service.mjs';
import { uniformJsRepresentationProfile } from './uniform-specialization.mjs';
import { canonicalBytes, canonicalArtifact } from './artifact-evidence.mjs';
import { leanCheckedIdentity } from './checked-kernel-identity.mjs';

const ok = value => ({ $ps$tag: 'ok', $ps$fields: { value } });
const emptyIr = '["psc-runtime-ir-json/1",[],[],[],[]]';
const emptyJsIr = '["psc-js-ir-json/1",[],[]]';
const emptyWasmIr = '["psc-wasm-ir-json/1",[],[],[],[],[],[]]';
const wasm = [0, 97, 115, 109, 1, 0, 0, 0];
const list = values => values.reduceRight((tail, head) =>
  ({ $ps$tag: 'cons', $ps$fields: { head, tail } }), { $ps$tag: 'nil', $ps$fields: {} });
function fixture(options = {}) {
  const emitted = [];
  const compiler = {
    psCompilerPrepareSource: (kind, source) => ok({ kind, source }),
    psCompilerAdmissionsFromPrepared: value => ok(JSON.stringify({
      admissions: [{ source: value.source }], format: 'proofscript-checked-admissions', version: 2,
    })),
    psCompilerTypeScriptFromPrepared: value => { emitted.push(value); return ok('export const value: number = 7;'); },
    psCompilerJavaScriptFromPrepared: value => { emitted.push(value); return ok('export const value = 7;'); },
    psCompilerRustFromPrepared: value => { emitted.push(value); return ok('pub fn value() -> u32 { 7 }'); },
    psCompilerWasm32Target: { wordSize: 'wasm32' },
    psCompilerWasmFromPrepared: (target, value) => {
      assert.equal(target, compiler.psCompilerWasm32Target); emitted.push(value); return ok(list(wasm));
    },
  };
  const service = createCheckedCompilerService({ compiler,
    checkAdmissions: () => ({ ...leanCheckedIdentity, accepted: true }),
    identity: leanCheckedIdentity, targets: ['typescript', 'javascript', 'rust', 'wasm'], ...options });
  return { service, emitted, compiler };
}

test('all permitted backends emit from the same accepted object and bind byte digests', async () => {
  const { service, emitted } = fixture();
  const handle = await service.check('lean', 'def value : Nat := 7');
  const certificate = service.certificate(handle);
  const certified = service.describe(handle);
  assert.equal(handle.capability, 'psc-certified-source-capability/1');
  assert.equal(certificate.identity.contract, 'pscv-cert/1');
  assert.equal(certified.contract, 'psc-certified-source/1');
  for (const target of handle.targets) {
    const artifact = service.emitArtifact(handle, target);
    assert.equal(artifact.checkedCore.capability, 'psc-checked-core-capability/1');
    assert.deepEqual(artifact.pscvCert, certificate.identity);
    assert.deepEqual(artifact.certifiedSource.identity, certified.identity);
    assert.equal(artifact.transformationAssurance, 'trusted-implementation-global-preservation-unproved');
    const bytes = typeof artifact.payload === 'string' ? Buffer.from(artifact.payload) : artifact.payload;
    assert.equal(artifact.artifact.digest, createHash('sha256').update(bytes).digest('hex'));
    assert.equal(artifact.artifact.byteLength, bytes.length);
    if (target === 'wasm') assert.equal(WebAssembly.validate(bytes), true);
  }
  assert.ok(emitted.every(value => value === emitted[0] && Object.isFrozen(value)));
});

test('serialized, foreign, revoked and closed capabilities cannot emit', async () => {
  const { service } = fixture();
  const handle = await service.check('lean', 'accepted');
  assert.throws(() => service.emitArtifact(JSON.parse(JSON.stringify(handle))), /CERTIFIED_SOURCE_NOT_LIVE/);
  assert.throws(() => fixture().service.emitArtifact(handle), /CERTIFIED_SOURCE_NOT_LIVE/);
  const serializedCertificate = JSON.parse(service.certificate(handle).bytes);
  service.revoke(handle);
  assert.equal(serializedCertificate.contract, 'pscv-cert/1');
  assert.throws(() => service.emitArtifact(handle), /CERTIFIED_SOURCE_NOT_LIVE/);
  assert.throws(() => service.emitArtifact(serializedCertificate), /CERTIFIED_SOURCE_NOT_LIVE/);
  const second = await service.check('lean', 'accepted again');
  service.close();
  assert.throws(() => service.emitArtifact(second), /SESSION_CLOSED/);
  await assert.rejects(service.check('lean', 'new'), /SESSION_CLOSED/);
});

test('target policy is captured before callers mutate it and forbidden emitters never run', async () => {
  const targets = ['javascript'];
  const { service, emitted } = fixture({ targets });
  targets.push('rust');
  const handle = await service.check('lean', 'accepted');
  assert.throws(() => service.emitArtifact(handle, 'rust'), /TARGET_FORBIDDEN/);
  assert.equal(emitted.length, 0);
  service.emitArtifact(handle, 'javascript');
  assert.equal(emitted.length, 1);
});

test('closing a session during kernel acceptance cannot mint a new handle', async () => {
  let accept;
  const { service } = fixture({ checkAdmissions: () => new Promise(resolve => { accept = resolve; }) });
  const pending = service.check('lean', 'pending');
  service.close();
  accept({ ...leanCheckedIdentity, accepted: true });
  await assert.rejects(pending, /SESSION_CLOSED/);
});

test('byte budgets reject both text and Wasm output', async () => {
  const { service } = fixture({ maxOutputBytes: 7 });
  const handle = await service.check('lean', 'accepted');
  assert.throws(() => service.emitArtifact(handle, 'javascript'), /OUTPUT_RESOURCE_EXHAUSTED/);
  assert.throws(() => service.emitArtifact(handle, 'wasm'), /OUTPUT_RESOURCE_EXHAUSTED/);
});

test('stage emission uses the exact live checked object without legacy fallback', async () => {
  const { service, compiler, emitted } = fixture();
  let observed;
  compiler.psCompilerTypeScriptStagesFromPrepared = prepared => {
    observed = prepared;
    return ok({ typeScript: 'export const answer = 42n;', runtimeIr: emptyIr, verifiedIr: emptyIr });
  };
  const handle = await service.check('lean', 'checked source');
  const result = service.emitArtifact(handle);
  assert.equal(observed.source, 'checked source');
  assert.equal(Object.isFrozen(observed), true);
  assert.deepEqual(result.stages, { runtimeIr: emptyIr, verifiedIr: emptyIr });
  assert.equal(Object.isFrozen(result.stages), true);
  assert.equal(emitted.length, 0);
  compiler.psCompilerTypeScriptStagesFromPrepared = () => ({ $ps$tag: 'error' });
  assert.throws(() => service.emitArtifact(handle), /EMIT_STAGES_FAILED/);
  assert.equal(emitted.length, 0);
  compiler.psCompilerTypeScriptStagesFromPrepared = () => ok({ typeScript: 'output', runtimeIr: 'missing verified' });
  assert.throws(() => service.emitArtifact(handle), /STAGES_SHAPE/);
  service.revoke(handle);
  assert.throws(() => service.emitArtifact(handle), /CERTIFIED_SOURCE_NOT_LIVE/);
});

test('staged JavaScript output binds actual stage domains and rejects missing, changed or oversized stages', async () => {
  const { service, compiler, emitted } = fixture();
  const good = { javaScript: 'export const value = 7;', runtimeIr: emptyIr, verifiedIr: emptyIr, specializedIr: emptyIr, jsIr: emptyJsIr };
  let prepared;
  compiler.psCompilerJavaScriptStagesFromPrepared = value => { prepared = value; return ok(good); };
  const handle = await service.check('lean', 'checked JS source');
  const output = service.emitArtifact(handle, 'javascript');
  assert.equal(prepared.source, 'checked JS source');
  assert.equal(Object.isFrozen(prepared), true);
  assert.equal(output.stageArtifacts.runtimeIr.domain, 'runtime-ir');
  assert.equal(output.stageArtifacts.verifiedIr.domain, 'verified-ir');
  assert.equal(output.stageArtifacts.specializedIr.domain, 'specialized-ir');
  assert.equal(output.stageArtifacts.jsIr.domain, 'js-ir');
  assert.equal(output.specializationCorrespondence.correspondenceChecked, true);
  assert.equal(output.specializationInstances.contract, 'psc-specialization-instance-map/1');
  assert.equal(emitted.length, 0);
  compiler.psCompilerJavaScriptStagesFromPrepared = () => ok({ ...good, specializedIr: undefined });
  assert.throws(() => service.emitArtifact(handle, 'javascript'), /STAGES_SHAPE/);
  compiler.psCompilerJavaScriptStagesFromPrepared = undefined;
  assert.throws(() => service.emitArtifact(handle, 'javascript'), /STAGES_API_SHAPE/);
  compiler.psCompilerJavaScriptStagesFromPrepared = () => ok({ ...good, specializedIr: 'malformed' });
  assert.throws(() => service.emitArtifact(handle, 'javascript'), /export-json/);
  compiler.psCompilerJavaScriptStagesFromPrepared = () => ok({ ...good,
    verifiedIr: '["psc-runtime-ir-json/1",[],[],[],[["extra",[],[],["primitive","nat"],["literal",["natural","1"]]]]]' });
  assert.throws(() => service.emitArtifact(handle, 'javascript'), /VALIDATION_CHANGED_IR/);
  compiler.psCompilerJavaScriptStagesFromPrepared = () => ok({ ...good,
    specializedIr: '["psc-runtime-ir-json/1",[],[],[],[["extra",[],[],["primitive","nat"],["literal",["natural","1"]]]]]' });
  assert.throws(() => service.emitArtifact(handle, 'javascript'), /UNJUSTIFIED_TARGET/);
  const small = fixture({ maxOutputBytes: 100 });
  small.compiler.psCompilerJavaScriptStagesFromPrepared = () => ok(good);
  assert.throws(() => small.service.emitArtifact(handle, 'javascript'), /CERTIFIED_SOURCE_NOT_LIVE/);
  const smallHandle = await small.service.check('lean', 'same');
  assert.throws(() => small.service.emitArtifact(smallHandle, 'javascript'), /OUTPUT_RESOURCE_EXHAUSTED/);
  assert.equal(emitted.length, 0);
});

test('staged Wasm uses the pinned target and exact checked object, with bounded byte copying and no failure fallback', async () => {
  const { service, compiler, emitted } = fixture();
  const good = { wasm: list(wasm), runtimeIr: emptyIr, verifiedIr: emptyIr, specializedIr: emptyIr, wasmIr: emptyWasmIr };
  compiler.psCompilerWasmStagesFromPrepared = (profile, prepared) => {
    assert.equal(profile, compiler.psCompilerWasm32Target);
    assert.equal(prepared.source, 'checked Wasm source');
    assert.equal(Object.isFrozen(prepared), true);
    return ok(good);
  };
  const handle = await service.check('lean', 'checked Wasm source');
  const output = service.emitArtifact(handle, 'wasm');
  assert.deepEqual(output.payload, Uint8Array.from(wasm));
  assert.equal(output.specializationCorrespondence.correspondenceChecked, true);
  assert.equal(output.specializationInstances.contract, 'psc-specialization-instance-map/1');
  assert.equal(output.stageArtifacts.specializedIr.domain, 'specialized-ir');
  assert.equal(output.stageArtifacts.wasmIr.domain, 'wasm-ir');
  good.wasm.$ps$fields.head = 255;
  assert.equal(output.payload[0], 0);
  compiler.psCompilerWasmStagesFromPrepared = () => ok({ ...good, wasm: 'wrong' });
  assert.throws(() => service.emitArtifact(handle, 'wasm'), /STAGES_SHAPE/);
  const cyclic = list([0]); cyclic.$ps$fields.tail = cyclic;
  compiler.psCompilerWasmStagesFromPrepared = () => ok({ ...good, wasm: cyclic });
  assert.throws(() => service.emitArtifact(handle, 'wasm'), /BYTES_CYCLE/);
  compiler.psCompilerWasmStagesFromPrepared = () => ({ $ps$tag: 'error' });
  assert.throws(() => service.emitArtifact(handle, 'wasm'), /EMIT_STAGES_FAILED/);
  compiler.psCompilerWasmStagesFromPrepared = null;
  assert.throws(() => service.emitArtifact(handle, 'wasm'), /STAGES_API_SHAPE/);
  const small = fixture({ maxOutputBytes: 7 });
  small.compiler.psCompilerWasmStagesFromPrepared = () => ok(good);
  const smallHandle = await small.service.check('lean', 'small');
  assert.throws(() => small.service.emitArtifact(smallHandle, 'wasm'), /OUTPUT_RESOURCE_EXHAUSTED/);
  assert.equal(emitted.length, 0);
});

test('PublicApiIR uses the same accepted object and remains independent of executable lowering', async () => {
  const { service, compiler } = fixture();
  const api = '["psc-public-api-ir/1","all-prepared-declarations",[]]';
  let prepared;
  compiler.psCompilerPublicApiFromPrepared = value => {
    prepared = value; return ok(api);
  };
  const handle = await service.check('lean', 'generic source');
  const product = service.emitPublicApiArtifact(handle);
  assert.equal(product.payload, api);
  assert.equal(product.artifact.domain, 'public-api');
  assert.equal(Object.isFrozen(prepared), true);
  assert.equal(prepared.source, 'generic source');
  assert.deepEqual(product.pscvCert, service.certificate(handle).identity);
  const emitted = service.emitArtifact(handle, 'javascript');
  assert.equal(emitted.publicApi, api);
  assert.deepEqual(emitted.publicApiArtifact, product.artifact);
  compiler.psCompilerJavaScriptFromPrepared = () => ({ $ps$tag: 'error' });
  assert.equal(service.emitPublicApiArtifact(handle).payload, api);
  assert.throws(() => service.emitArtifact(handle, 'javascript'), /EMIT_FAILED/);
  assert.throws(() => service.emitPublicApiArtifact({ ...handle }), /CERTIFIED_SOURCE_NOT_LIVE/);
  compiler.psCompilerPublicApiFromPrepared = () => ok('["wrong"]');
  assert.throws(() => service.emitPublicApiArtifact(handle), /PUBLIC_API_SCHEMA/);
  compiler.psCompilerPublicApiFromPrepared = undefined;
  assert.throws(() => service.emitPublicApiArtifact(handle), /PUBLIC_API_API_SHAPE/);
  delete compiler.psCompilerPublicApiFromPrepared;
  assert.throws(() => service.emitPublicApiArtifact(handle), /PUBLIC_API_UNSUPPORTED/);
  service.revoke(handle);
  assert.throws(() => service.emitPublicApiArtifact(handle), /CERTIFIED_SOURCE_NOT_LIVE/);
});

test('PublicApiIR bytes count against the combined emission budget', async () => {
  const { service, compiler } = fixture({ maxOutputBytes: 60 });
  compiler.psCompilerPublicApiFromPrepared = () => ok('["psc-public-api-ir/1","all-prepared-declarations",[]]');
  const handle = await service.check('lean', 'accepted');
  assert.equal(service.emitPublicApiArtifact(handle).artifact.domain, 'public-api');
  assert.throws(() => service.emitArtifact(handle, 'javascript'), /OUTPUT_RESOURCE_EXHAUSTED/);
});

test('origin-aware preparation is single-pass, immutable, optional only when absent and live-gated', async () => {
  const { compiler, service } = fixture();
  compiler.psCompilerPrepareSource = () => { throw new Error('LEGACY_PREPARATION_MUST_NOT_RUN'); };
  compiler.psCompilerPrepareSourceWithOrigins = (kind, source) => ok({ prepared: { kind, source },
    origins: '["psc-declaration-origins/1","declaration-batch",1,[]]' });
  compiler.psCompilerPublicApiFromPrepared = () => ok('["psc-public-api-ir/1","all-prepared-declarations",[]]');
  const handle = await service.check('lean', 'source text');
  const result = service.emitOriginGraph(handle);
  assert.equal(result.graph.identity.domain, 'origin-graph');
  assert.equal(JSON.parse(result.graph.bytes).granularity, 'declaration-batch');
  assert.equal(service.emitArtifact(handle).originGraph.digest, result.graph.identity.digest);
  assert.throws(() => service.emitOriginGraph({ ...handle }), /CERTIFIED_SOURCE_NOT_LIVE/);
  compiler.psCompilerPrepareSourceWithOrigins = undefined;
  await assert.rejects(service.check('lean', 'again'), /ORIGIN_PREPARE_API_SHAPE/);
  service.close();
  assert.throws(() => service.emitOriginGraph(handle), /SESSION_CLOSED/);
});

test('ordered origin inputs are captured before asynchronous checking', async () => {
  let accept;
  const { compiler, service } = fixture({ checkAdmissions: () => new Promise(resolve => { accept = resolve; }) });
  compiler.List = { nil: () => [], cons: (head, tail) => [head, ...tail] };
  compiler.psCompilerPrepareSources = () => { throw new Error('LEGACY_MUST_NOT_RUN'); };
  compiler.psCompilerPrepareSourcesWithOrigins = (kind, values) => ok({ prepared: { kind, source: values.join('') },
    origins: '["psc-declaration-origins/1","declaration-batch",1,[]]' });
  compiler.psCompilerPublicApiFromPrepared = () => ok('["psc-public-api-ir/1","all-prepared-declarations",[]]');
  const sources = ['before'];
  const pending = service.checkSources('lean', sources);
  sources[0] = 'after';
  accept({ ...leanCheckedIdentity, accepted: true });
  const result = service.emitOriginGraph(await pending);
  assert.equal(result.artifacts.find(item => item.identity.domain === 'prepared-source').bytes.toString(), 'before');
});

test('erasure inventory comes from the single checked emission and malformed metadata never falls back', async () => {
  const { compiler, service, emitted } = fixture();
  const api = '["psc-public-api-ir/1","all-prepared-declarations",[]]';
  const table = '["psc-erasure-declarations/1","declaration-inventory",[]]';
  let count = 0;
  compiler.psCompilerPublicApiFromPrepared = () => ok(api);
  compiler.psCompilerTypeScriptStagesFromPrepared = () => {
    count++;
    return ok({ typeScript: '', runtimeIr: emptyIr, verifiedIr: emptyIr, erasureCorrespondence: table });
  };
  const handle = await service.check('lean', '');
  const result = service.emitArtifact(handle);
  assert.equal(count, 1);
  assert.equal(result.erasureCorrespondence, table);
  assert.equal(result.erasureMap.domain, 'erasure-map');
  assert.equal(emitted.length, 0);
  compiler.psCompilerTypeScriptStagesFromPrepared = () =>
    ok({ typeScript: '', runtimeIr: emptyIr, verifiedIr: emptyIr, erasureCorrespondence: 0 });
  assert.throws(() => service.emitArtifact(handle), /ERASURE_CORRESPONDENCE_SHAPE/);
  compiler.psCompilerTypeScriptStagesFromPrepared = () =>
    ok({ typeScript: '', runtimeIr: emptyIr, verifiedIr: emptyIr, erasureCorrespondence: '[]' });
  assert.throws(() => service.emitArtifact(handle), /PSC_ERASURE_DECL_/);
  assert.equal(emitted.length, 0);
});

test('generated positions remain exact checked emission metadata and malformed fields reject', async () => {
  const { service, compiler } = fixture();
  const good = { javaScript: '', runtimeIr: emptyIr, verifiedIr: emptyIr, specializedIr: emptyIr, jsIr: emptyJsIr,
    generatedPositions: '["psc-js-generated-positions/1","declaration-emission-chunk",[]]' };
  compiler.psCompilerJavaScriptStagesFromPrepared = () => ok(good);
  const handle = await service.check('lean', '');
  const result = service.emitArtifact(handle, 'javascript');
  assert.equal(result.generatedPositionMap.contract, 'psc-js-generated-position-map/1');
  assert.equal(result.generatedPositions, good.generatedPositions);
  compiler.psCompilerJavaScriptStagesFromPrepared = () => ok({ ...good, generatedPositions: null });
  assert.throws(() => service.emitArtifact(handle, 'javascript'), /GENERATED_POSITIONS_SHAPE/);
  compiler.psCompilerJavaScriptStagesFromPrepared = () => ok({ ...good, generatedPositions: '[]' });
  assert.throws(() => service.emitArtifact(handle, 'javascript'), /PSC_JS_POSITION_/);
});

test('live direct-JS composition uses one emission and binds all exact metadata parents', async () => {
  const { service, compiler, emitted } = fixture();
  compiler.psCompilerPrepareSourceWithOrigins = (kind, source) => ok({ prepared: { kind, source },
    origins: '["psc-declaration-origins/1","declaration-batch",1,[]]' });
  compiler.psCompilerPublicApiFromPrepared = () => ok('["psc-public-api-ir/1","all-prepared-declarations",[]]');
  let count = 0;
  compiler.psCompilerJavaScriptStagesFromPrepared = () => {
    count++;
    return ok({ javaScript: '', runtimeIr: emptyIr, verifiedIr: emptyIr, specializedIr: emptyIr, jsIr: emptyJsIr,
      generatedPositions: '["psc-js-generated-positions/1","declaration-emission-chunk",[]]',
      erasureCorrespondence: '["psc-erasure-declarations/1","declaration-inventory",[]]' });
  };
  const handle = await service.check('lean', '');
  const result = service.emitArtifact(handle, 'javascript');
  assert.equal(count, 1);
  assert.equal(emitted.length, 0);
  assert.equal(result.declarationLineage.contract, 'psc-js-declaration-lineage/1');
  assert.equal(result.sourceMapArtifact.contract, 'psc-direct-javascript-source-map/1');
  assert.equal(JSON.parse(result.sourceMap).version, 3);
  assert.equal(JSON.parse(result.sourceMap).mappings, '');
  assert.equal(result.sourceMapRecipe.contract, 'psc-direct-javascript-source-map-recipe/1');
  assert.equal(result.transformationAssurance, 'trusted-implementation-global-preservation-unproved');
  service.revoke(handle);
  assert.throws(() => service.emitArtifact(handle, 'javascript'), /CERTIFIED_SOURCE_NOT_LIVE/);
  assert.equal(count, 1);
});

test('malformed optional origins do not decide logical acceptance or executable-only output', async () => {
  let checked = 0, preparedCount = 0, stageCount = 0, originGetterCalls = 0;
  const { service, compiler, emitted } = fixture({ checkAdmissions: () => {
    checked++; return { ...leanCheckedIdentity, accepted: true };
  } });
  compiler.psCompilerPrepareSource = () => { throw new Error('LEGACY_PREPARATION_FORBIDDEN'); };
  compiler.psCompilerPrepareSourceWithOrigins = (kind, source) => {
    preparedCount++;
    return ok(Object.defineProperty({ prepared: { kind, source } }, 'origins', {
      get() { originGetterCalls++; throw new Error('OPTIONAL_GETTER_MUST_NOT_RUN'); }, enumerable: true,
    }));
  };
  compiler.psCompilerPublicApiFromPrepared = () => ok('["psc-public-api-ir/1","all-prepared-declarations",[]]');
  compiler.psCompilerJavaScriptStagesFromPrepared = prepared => {
    stageCount++; assert.equal(Object.isFrozen(prepared), true); assert.equal(prepared.source, 'source');
    return ok({ javaScript: '', runtimeIr: emptyIr, verifiedIr: emptyIr, specializedIr: emptyIr, jsIr: emptyJsIr });
  };
  const handle = await service.check('lean', 'source');
  assert.equal(checked, 1); assert.equal(preparedCount, 1); assert.equal(originGetterCalls, 0);
  assert.throws(() => service.emitOriginGraph(handle), /ORIGIN_PREPARE_RESULT_SHAPE/);
  assert.throws(() => service.emitArtifact(handle, 'javascript'), /ORIGIN_PREPARE_RESULT_SHAPE/);
  assert.equal(stageCount, 1);
  const output = service.emitExecutableArtifact(handle, 'javascript');
  assert.equal(stageCount, 2);
  assert.equal(output.payload, '');
  assert.equal(output.requestedProducts, 'executable-only');
  assert.equal(output.specializationCorrespondence.correspondenceChecked, true);
  assert.equal(output.specializationInstances, undefined);
  assert.equal(output.originGraph, undefined); assert.equal(output.publicApi, undefined);
  assert.equal(emitted.length, 0); assert.equal(preparedCount, 1); assert.equal(checked, 1);
  assert.equal(originGetterCalls, 0);
  assert.equal(service.describe(handle).contract, 'psc-certified-source/1');
  service.revoke(handle);
  assert.throws(() => service.emitExecutableArtifact(handle, 'javascript'), /CERTIFIED_SOURCE_NOT_LIVE/);
});

test('executable selection ignores unrequested metadata accessors and budgets while preserving stage checks', async () => {
  const { service, compiler, emitted } = fixture();
  let count = 0, getters = 0;
  compiler.psCompilerPublicApiFromPrepared = () => { throw new Error('API_PRODUCT_NOT_REQUESTED'); };
  const good = { javaScript: '', runtimeIr: emptyIr, verifiedIr: emptyIr, specializedIr: emptyIr, jsIr: emptyJsIr };
  compiler.psCompilerJavaScriptStagesFromPrepared = () => {
    count++;
    return ok(Object.defineProperty({ ...good }, 'generatedPositions', {
      get() { getters++; throw new Error('DEBUG_GETTER_NOT_REQUESTED'); }, enumerable: true,
    }));
  };
  const handle = await service.check('lean', '');
  assert.equal(service.emitExecutableArtifact(handle, 'javascript').payload, '');
  assert.equal(count, 1); assert.equal(getters, 0); assert.equal(emitted.length, 0);
  assert.throws(() => service.emitArtifact(handle, 'javascript'), /STAGES_SHAPE/);
  assert.equal(count, 2); assert.equal(getters, 0); assert.equal(emitted.length, 0);
  compiler.psCompilerJavaScriptStagesFromPrepared = () => ok(Object.defineProperty({ ...good }, 'runtimeIr', {
    get() { getters++; return emptyIr; }, enumerable: true,
  }));
  assert.throws(() => service.emitExecutableArtifact(handle, 'javascript'), /STAGES_SHAPE/);
  assert.equal(getters, 0);
  compiler.psCompilerJavaScriptStagesFromPrepared = () => ok({ ...good, verifiedIr: 'malformed' });
  assert.throws(() => service.emitExecutableArtifact(handle, 'javascript'), /export-json/);
  compiler.psCompilerJavaScriptStagesFromPrepared = () => ({ $ps$tag: 'error' });
  assert.throws(() => service.emitExecutableArtifact(handle, 'javascript'), /EMIT_STAGES_FAILED/);
  assert.equal(emitted.length, 0);
  const small = fixture({ maxOutputBytes: 4096 });
  small.compiler.psCompilerJavaScriptStagesFromPrepared = () => ok({ ...good, generatedPositions: 'x'.repeat(8192) });
  const smallHandle = await small.service.check('lean', '');
  assert.equal(small.service.emitExecutableArtifact(smallHandle, 'javascript').payload, '');
  assert.throws(() => small.service.emitArtifact(smallHandle, 'javascript'), /OUTPUT_RESOURCE_EXHAUSTED/);
});

test('the convenience executable emitter does not request source API projection', async () => {
  const { service, compiler } = fixture();
  compiler.psCompilerPublicApiFromPrepared = () => { throw new Error('API_PRODUCT_FAILED'); };
  const handle = await service.check('lean', 'source');
  assert.match(service.emit(handle), /export const value/);
  assert.throws(() => service.emitArtifact(handle), /API_PRODUCT_FAILED/);
});

test('requested declarations share the checked emission and do not require optional debug products', async () => {
  const { service, compiler } = fixture();
  let emissions = 0, debugReads = 0, declarations = 0, acceptedPrepared;
  compiler.psCompilerPrepareSourceWithOrigins = (kind, source) => {
    acceptedPrepared = { kind, source }; return ok({ prepared: acceptedPrepared, origins: null });
  };
  compiler.psCompilerPublicApiFromPrepared = () => ok('["psc-public-api-ir/1","all-prepared-declarations",[]]');
  compiler.psCompilerJavaScriptStagesFromPrepared = () => {
    emissions++;
    return ok(Object.defineProperty({ javaScript: '', runtimeIr: emptyIr, verifiedIr: emptyIr,
      specializedIr: emptyIr, jsIr: emptyJsIr,
      erasureCorrespondence: '["psc-erasure-declarations/1","declaration-inventory",[]]' }, 'generatedPositions', {
      get() { debugReads++; throw new Error('UNREQUESTED_DEBUG'); },
    }));
  };
  compiler.psCompilerJavaScriptDeclarationsFromPrepared = (request, prepared) => {
    assert.equal(prepared, acceptedPrepared); assert.equal(Object.isFrozen(prepared), true); declarations++;
    assert.deepEqual(JSON.parse(request), ['psc-ts-declaration-request/1',
      'psc-direct-js-declarations-closed-structural/1', '67108864', []]);
    return ok('export {};\n');
  };
  const handle = await service.check('lean', '');
  const product = service.emitDeclarationsArtifact(handle);
  assert.equal(product.requestedProducts, 'executable-and-source-declarations');
  assert.equal(product.directDeclarations.declarations.bytes.toString(), 'export {};\n');
  assert.equal(product.originGraph, undefined); assert.equal(product.generatedPositions, undefined);
  assert.equal(emissions, 1); assert.equal(debugReads, 0); assert.equal(declarations, 1);
  assert.equal(product.declarationProduction.hostBytesCompared, true);
  assert.throws(() => service.emitDeclarationsArtifact(handle, { profile: 'invented' }), /PROFILE/);
  assert.equal(emissions, 1);
  compiler.psCompilerJavaScriptDeclarationsFromPrepared = () => ok('export {};\n// unexpected');
  assert.throws(() => service.emitDeclarationsArtifact(handle), /DECLARATION_PRODUCER_MISMATCH/);
  compiler.psCompilerJavaScriptDeclarationsFromPrepared = () => ({ $ps$tag: 'error' });
  assert.throws(() => service.emitDeclarationsArtifact(handle), /DECLARATIONS_FAILED/);
  compiler.psCompilerJavaScriptDeclarationsFromPrepared = () => ok({});
  assert.throws(() => service.emitDeclarationsArtifact(handle), /DECLARATIONS_RESULT_SHAPE/);
  delete compiler.psCompilerJavaScriptDeclarationsFromPrepared;
  assert.throws(() => service.emitDeclarationsArtifact(handle), /DECLARATIONS_API_REQUIRED/);
  assert.equal(service.emitExecutableArtifact(handle, 'javascript').payload, '');
  assert.equal(debugReads, 0);
  service.revoke(handle);
  assert.throws(() => service.emitDeclarationsArtifact(handle), /CERTIFIED_SOURCE_NOT_LIVE/);
});

test('uniform representation is fixed by host policy, cannot fall back, and retains checked generic declarations', async () => {
  const { service, compiler, emitted } = fixture({ javaScriptRepresentation: uniformJsRepresentationProfile });
  let calls = 0;
  const name = v => ({ k: 's', p: { k: 'a' }, v });
  const type = { k: 'forall', n: name('A'), bi: 'default', t: { k: 'sort', l: { k: 's', o: { k: 'z' } } },
    b: { k: 'forall', n: name('x'), bi: 'default', t: { k: 'b', i: 0 }, b: { k: 'b', i: 1 } } };
  const raw = ['psc-runtime-ir-json/1', [], [], [], [
    ['forward', ['RuntimeA'], [['x', ['typeParameter', 'RuntimeA']]], ['typeParameter', 'RuntimeA'], ['var', 'x']],
  ]];
  const api = ['psc-public-api-ir/1', 'all-prepared-declarations', [
    ['constant', 'definition', name('forward'), [], type],
  ]];
  compiler.psCompilerPublicApiFromPrepared = () => ok(canonicalBytes(api).toString());
  compiler.psCompilerJavaScriptStagesFromPrepared = () => { throw new Error('CLOSED_FALLBACK_FORBIDDEN'); };
  const handle = await service.check('lean', 'generic fixture');
  assert.throws(() => service.emitExecutableArtifact(handle, 'javascript'), /UNIFORM_STAGES_API_REQUIRED/);
  const good = { javaScript: 'export function forward(x) { return x; }\n',
    runtimeIr: JSON.stringify(raw), verifiedIr: JSON.stringify(raw),
    uniformSpecializedIr: JSON.stringify(['psc-uniform-specialized-ir/1', uniformJsRepresentationProfile, raw]),
    jsIr: '["psc-js-ir-json/1",[],[["forward",["x"],["var","x"]]]]',
    erasureCorrespondence: canonicalBytes(['psc-erasure-declarations/1', 'declaration-inventory',
      [[name('forward'), ['runtime', 'forward']]]]).toString(),
  };
  compiler.psCompilerUniformJavaScriptStagesFromPrepared = prepared => {
    assert.equal(Object.isFrozen(prepared), true); calls++; return ok(good);
  };
  compiler.psCompilerJavaScriptDeclarationsFromPrepared = (request, prepared) => {
    assert.equal(Object.isFrozen(prepared), true);
    assert.deepEqual(JSON.parse(request), ['psc-ts-declaration-request/1',
      'psc-direct-js-declarations-uniform-structural/1', '67108864', [['0', 'forward']]]);
    return ok('declare const $pscDeclaration0: <T0>(_arg0: T0) => T0;\nexport { $pscDeclaration0 as forward };\n');
  };
  const product = service.emitDeclarationsArtifact(handle);
  assert.equal(calls, 1);
  assert.equal(product.checkedCore.javaScriptRepresentation, uniformJsRepresentationProfile);
  assert.equal(product.javaScriptRepresentation, uniformJsRepresentationProfile);
  assert.equal(product.uniformSpecializationCorrespondence.bytesPreserved, true);
  assert.equal(product.specializationCorrespondence, undefined);
  assert.equal(product.stageArtifacts.uniformSpecializedIr.domain, 'uniform-specialized-ir');
  assert.match(product.directDeclarations.declarations.bytes.toString(), /<T0>\(_arg0: T0\) => T0/);
  assert.throws(() => service.emitDeclarationsArtifact(handle, { profile: 'psc-direct-js-declarations-closed-structural/1' }), /PROFILE/);
  compiler.psCompilerUniformJavaScriptStagesFromPrepared = () => ({ $ps$tag: 'error' });
  assert.throws(() => service.emitExecutableArtifact(handle, 'javascript'), /EMIT_STAGES_FAILED/);
  compiler.psCompilerUniformJavaScriptStagesFromPrepared = () => ok({ ...good, uniformSpecializedIr: undefined });
  assert.throws(() => service.emitExecutableArtifact(handle, 'javascript'), /STAGES_SHAPE/);
  assert.equal(emitted.length, 0);
  service.revoke(handle);
  assert.throws(() => service.emitDeclarationsArtifact(handle), /CERTIFIED_SOURCE_NOT_LIVE/);
  assert.throws(() => fixture({ javaScriptRepresentation: 'invented' }), /JAVASCRIPT_REPRESENTATION/);
});

test('uniform live metadata composes real retained declarations without closed instance products', async () => {
  const f = originFixture({ uniform: true });
  const { service, compiler } = fixture({ javaScriptRepresentation: uniformJsRepresentationProfile });
  compiler.psCompilerPrepareSourceWithOrigins = (kind, source) => ok({
    prepared: { kind, source }, origins: f.sourceTable.toString() });
  compiler.psCompilerPublicApiFromPrepared = () => ok(f.publicApi.bytes.toString());
  compiler.psCompilerUniformJavaScriptStagesFromPrepared = () => ok({
    javaScript: f.javaScript, runtimeIr: f.runtimeIr.bytes.toString(), verifiedIr: f.verifiedIr.bytes.toString(),
    uniformSpecializedIr: f.uniformSpecializedIr.bytes.toString(), jsIr: f.jsIr.bytes.toString(),
    erasureCorrespondence: f.erasureTable.toString(), generatedPositions: f.generatedTable.toString(),
  });
  compiler.psCompilerJavaScriptDeclarationsFromPrepared = () => { throw new Error('UNREQUESTED_DECLARATIONS'); };
  const handle = await service.check('lean', f.sources[0]);
  const product = service.emitArtifact(handle, 'javascript');
  assert.equal(product.payload, f.javaScript);
  assert.equal(product.specializationInstances, undefined);
  assert.equal(product.directDeclarations, undefined);
  assert.equal(product.declarationLineage.contract, 'psc-js-uniform-declaration-lineage/1');
  assert.equal(product.sourceMapRecipe.contract, 'psc-direct-javascript-source-map-recipe/2');
  assert.deepEqual(JSON.parse(product.sourceMap).sourcesContent, f.sources);
  service.revoke(handle);
  assert.throws(() => service.emitArtifact(handle, 'javascript'), /CERTIFIED_SOURCE_NOT_LIVE/);
});

test('selected declaration and required-map products share one accepted preparation and emission', async () => {
  const { service, compiler, emitted } = fixture();
  let preparations = 0, stages = 0, writers = 0;
  compiler.psCompilerPrepareSourceWithOrigins = (kind, source) => {
    preparations++;
    return ok({ prepared: { kind, source }, origins: '["psc-declaration-origins/1","declaration-batch",1,[]]' });
  };
  compiler.psCompilerPublicApiFromPrepared = () => ok('["psc-public-api-ir/1","all-prepared-declarations",[]]');
  const good = { javaScript: '', runtimeIr: emptyIr, verifiedIr: emptyIr, specializedIr: emptyIr, jsIr: emptyJsIr,
    generatedPositions: '["psc-js-generated-positions/1","declaration-emission-chunk",[]]',
    erasureCorrespondence: '["psc-erasure-declarations/1","declaration-inventory",[]]' };
  compiler.psCompilerJavaScriptStagesFromPrepared = () => { stages++; return ok(good); };
  compiler.psCompilerJavaScriptDeclarationsFromPrepared = () => { writers++; return ok('export {};\n'); };
  const handle = await service.check('lean', '');
  const selection = { declarations: true, sourceMap: true };
  const product = service.emitSelectedArtifact(handle, 'javascript', selection);
  selection.declarations = false;
  assert.deepEqual(product.productSelection, { contract: 'psc-compiler-product-selection/1',
    executable: true, metadata: false, declarations: true, sourceMap: true });
  assert.equal(product.directDeclarations.declarations.bytes.toString(), 'export {};\n');
  assert.equal(JSON.parse(product.sourceMap).version, 3);
  assert.equal(preparations, 1); assert.equal(stages, 1); assert.equal(writers, 1); assert.equal(emitted.length, 0);
  for (const invalid of [null, [], { metadata: 'yes' }, { unknown: true },
    Object.defineProperty({}, 'metadata', { get() { throw new Error('GETTER_MUST_NOT_RUN'); } })])
    assert.throws(() => service.emitSelectedArtifact(handle, 'javascript', invalid), /PRODUCT_SELECTION/);
  assert.throws(() => service.emitSelectedArtifact(handle, 'wasm', { sourceMap: true }), /PRODUCT_TARGET/);
  assert.equal(stages, 1);
  compiler.psCompilerJavaScriptStagesFromPrepared = () => ok({ ...good, generatedPositions: undefined });
  assert.throws(() => service.emitSelectedArtifact(handle, 'javascript', { sourceMap: true }), /GENERATED_POSITIONS_SHAPE/);
  compiler.psCompilerJavaScriptStagesFromPrepared = () => ok({ javaScript: '', runtimeIr: emptyIr,
    verifiedIr: emptyIr, specializedIr: emptyIr, jsIr: emptyJsIr });
  assert.throws(() => service.emitSelectedArtifact(handle, 'javascript', { sourceMap: true }), /SOURCE_MAP_REQUIRED/);
  assert.equal(service.emitSelectedArtifact(handle, 'javascript').payload, '');
});

for (const staged of [false, true]) for (const close of [false, true])
  test(`emission rechecks liveness after a ${staged ? 'staged' : 'legacy'} producer ${close ? 'closes' : 'revokes'} its session`, async () => {
    const { service, compiler } = fixture();
    const handle = await service.check('lean', '');
    const interrupt = () => close ? service.close() : service.revoke(handle);
    if (staged) compiler.psCompilerJavaScriptStagesFromPrepared = () => {
      interrupt(); return ok({ javaScript: '', runtimeIr: emptyIr, verifiedIr: emptyIr,
        specializedIr: emptyIr, jsIr: emptyJsIr });
    };
    else compiler.psCompilerJavaScriptFromPrepared = () => { interrupt(); return ok(''); };
    assert.throws(() => service.emitSelectedArtifact(handle, 'javascript'), /UNCHECKED_MODULE|SESSION_CLOSED/);
  });

test('source API projection rechecks liveness before returning a product', async () => {
  const { service, compiler } = fixture();
  const handle = await service.check('lean', '');
  compiler.psCompilerPublicApiFromPrepared = () => {
    service.revoke(handle); return ok('["psc-public-api-ir/1","all-prepared-declarations",[]]');
  };
  assert.throws(() => service.emitPublicApiArtifact(handle), /UNCHECKED_MODULE/);
});

function canonicalFixture(options={}) {
  const selection=canonicalArtifact({schemaVersion:1,contract:'psc-wasm-canonical-selection/1',
    wordBits:32,packageNamespace:'psc',packageName:'live',worldName:'world',interfaceName:'api',
    exports:[{sourceName:'source',foreignName:'answer'}]},'abi-policy','psc-wasm-canonical-selection/1');
  const raw=['psc-runtime-ir-json/1',[],[],[],[
    ['source',[],[],['primitive','uint32'],['literal',['machineInteger','uint32','7']]]]];
  const ir=JSON.stringify(raw), specialized=canonicalArtifact(raw,'specialized-ir','psc-runtime-ir-json/1');
  const derived=deriveWasmCanonicalArtifacts(specialized,selection);
  const target=JSON.stringify(['psc-wasm-ir-json/1',[],[],[],[
    ['source',['none'],[],[['i32']],[],[['i32Const','7']]]],[],[['answer','source']]]);
  const binary=[0,97,115,109,1,0,0,0,1,5,1,96,0,1,127,3,2,1,0,
    7,10,1,6,97,110,115,119,101,114,0,0,10,6,1,4,0,65,7,11];
  const wire=createPortableWasmCanonicalRequest(selection);
  let prepared, calls=0, service;
  const product=()=>({wasm:list(binary),runtimeIr:ir,verifiedIr:ir,specializedIr:ir,wasmIr:target,
    interfaceJson:derived.interface.bytes.toString(),bindingJson:derived.binding.bytes.toString()});
  const compiler={
    psCompilerPrepareSource:(kind,source)=>{prepared={kind,source};return ok(prepared);},
    psCompilerAdmissionsFromPrepared:value=>{assert.equal(value,prepared);return ok(
      '{"admissions":[],"format":"proofscript-checked-admissions","version":2}');},
    psCompilerWasmCanonicalStagesFromPrepared:(request,value)=>{
      calls++;assert.equal(request,wire);assert.equal(value,prepared);assert.equal(Object.isFrozen(value),true);
      const output=product();if(options.mutate)options.mutate(output,service);
      return ok(output);
    },
    psCompilerWasmStagesFromPrepared:()=>{throw new Error('PRIVATE_WASM_FALLBACK');},
    psCompilerPublicApiFromPrepared:()=>{throw new Error('UNREQUESTED_API');},
  };
  service=createCheckedCompilerService({compiler,checkAdmissions:()=>({...leanCheckedIdentity,accepted:true}),
    identity:leanCheckedIdentity,targets:['wasm'],wasmCanonicalSelection:selection,...options.service});
  return {service,compiler,selection,wire,calls:()=>calls};
}

test('Canonical checked service pins a copied selection and binds one actual staged emission',async()=>{
  const fixture=canonicalFixture(), {service,selection,wire}=fixture;
  selection.bytes.fill(0);
  const handle=await service.check('lean','selected checked source');
  const emitted=service.emitSelectedArtifact(handle,'wasm');
  assert.equal(fixture.calls(),1);
  assert.equal(emitted.wasmCanonical.validation.targetSignaturesChecked,true);
  assert.equal(emitted.wasmCanonical.validation.preservationVerified,false);
  assert.equal(createPortableWasmCanonicalRequest(emitted.wasmCanonical.selection),wire);
  const instance=new WebAssembly.Instance(new WebAssembly.Module(emitted.payload));
  assert.equal(instance.exports.answer(),7);
  assert.deepEqual(Object.keys(instance.exports),['answer']);
  assert.equal(emitted.publicApi,undefined);
  assert.equal(emitted.checkedCore.wasmExportRequestSha256,createHash('sha256').update(wire).digest('hex'));
  emitted.wasmCanonical.selection.bytes.fill(0);
  assert.equal(service.emitExecutableArtifact(handle,'wasm').wasmCanonical.validation.signaturesChecked,true);
  service.revoke(handle);
  assert.throws(()=>service.emitExecutableArtifact(handle,'wasm'),/CERTIFIED_SOURCE_NOT_LIVE/);
});

test('Canonical checked service has no private fallback and rejects mismatched products',async()=>{
  for(const mutate of [
    output=>{delete output.interfaceJson;},
    output=>{const value=JSON.parse(output.interfaceJson);value[5][0][2][0][2]=['some',['scalar','u16']];
      output.interfaceJson=JSON.stringify(value);},
    output=>{const value=JSON.parse(output.bindingJson);value.bindings[0].sourceName='other';
      output.bindingJson=canonicalBytes(value).toString();},
    output=>{const value=JSON.parse(output.wasmIr);value[6][0][1]='other';output.wasmIr=JSON.stringify(value);},
    output=>{output.wasm=list([0,97,115,109,1,0,0,0]);},
    (output,service)=>{service.close();},
  ]){
    const {service}=canonicalFixture({mutate}),handle=await service.check('lean','source');
    assert.throws(()=>service.emitExecutableArtifact(handle,'wasm'),
      /CANONICAL_PRODUCTS_REQUIRED|PROJECTION_RELATION|TARGET_SIGNATURE_RELATION|EXPORT_SURFACE|SESSION_CLOSED/);
  }
  const {service,compiler}=canonicalFixture(),handle=await service.check('lean','source');
  delete compiler.psCompilerWasmCanonicalStagesFromPrepared;
  assert.throws(()=>service.emitExecutableArtifact(handle,'wasm'),/CANONICAL_STAGES_API_REQUIRED/);
  const bounded=canonicalFixture({service:{maxOutputBytes:1}});
  const boundedHandle=await bounded.service.check('lean','source');
  assert.throws(()=>bounded.service.emitExecutableArtifact(boundedHandle,'wasm'),/OUTPUT_RESOURCE_EXHAUSTED/);
});

test('Rust stages retain the exact generic validation input without claiming specialization or rustc acceptance', async () => {
  const { service, compiler, emitted } = fixture();
  const source = 'pub fn answer() -> u32 { 42 }';
  let observed;
  compiler.psCompilerRustStagesFromPrepared = prepared => {
    observed = prepared; return ok({ rustSource: source, runtimeIr: emptyIr, verifiedIr: emptyIr });
  };
  const handle = await service.check('lean', 'actual input of this transport fixture');
  const product = service.emitSelectedArtifact(handle, 'rust');
  assert.equal(product.payload, source);
  assert.equal(product.requestedProducts, 'target-source-only');
  assert.ok(Object.isFrozen(observed));
  assert.equal(emitted.length, 0);
  assert.deepEqual(Object.keys(product.stages), ['runtimeIr', 'verifiedIr']);
  assert.equal(product.specializationCorrespondence, undefined);
  compiler.psCompilerRustStagesFromPrepared = () => ok({ rustSource: source, runtimeIr: emptyIr });
  assert.throws(() => service.emitSelectedArtifact(handle, 'rust'), /STAGES_SHAPE/);
  compiler.psCompilerRustStagesFromPrepared = () => ({ $ps$tag: 'error' });
  assert.throws(() => service.emitSelectedArtifact(handle, 'rust'), /EMIT_STAGES_FAILED/);
  compiler.psCompilerRustStagesFromPrepared = () => {
    service.close(); return ok({ rustSource: source, runtimeIr: emptyIr, verifiedIr: emptyIr });
  };
  assert.throws(() => service.emitSelectedArtifact(handle, 'rust'), /SESSION_CLOSED/);
  assert.equal(emitted.length, 0);
});
