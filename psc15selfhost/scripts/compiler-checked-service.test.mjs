import assert from 'node:assert/strict';
import { test } from 'node:test';
import { createHash } from 'node:crypto';
import { createCheckedCompilerService } from './compiler-checked-service.mjs';
import { leanCheckedIdentity } from './checked-kernel-identity.mjs';

const ok = value => ({ $ps$tag: 'ok', $ps$fields: { value } });
const emptyIr = '["psc-runtime-ir-json/1",[],[],[],[]]';
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
  for (const target of handle.targets) {
    const artifact = service.emitArtifact(handle, target);
    assert.equal(artifact.checkedCore, handle);
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
  assert.throws(() => service.emitArtifact(JSON.parse(JSON.stringify(handle))), /UNCHECKED_MODULE/);
  assert.throws(() => fixture().service.emitArtifact(handle), /UNCHECKED_MODULE/);
  service.revoke(handle);
  assert.throws(() => service.emitArtifact(handle), /UNCHECKED_MODULE/);
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
  assert.throws(() => service.emitArtifact(handle), /UNCHECKED_MODULE/);
});

test('staged JavaScript output binds actual stage domains and rejects missing, changed or oversized stages', async () => {
  const { service, compiler, emitted } = fixture();
  const good = { javaScript: 'export const value = 7;', runtimeIr: emptyIr, verifiedIr: emptyIr, specializedIr: emptyIr };
  let prepared;
  compiler.psCompilerJavaScriptStagesFromPrepared = value => { prepared = value; return ok(good); };
  const handle = await service.check('lean', 'checked JS source');
  const output = service.emitArtifact(handle, 'javascript');
  assert.equal(prepared.source, 'checked JS source');
  assert.equal(Object.isFrozen(prepared), true);
  assert.equal(output.stageArtifacts.runtimeIr.domain, 'runtime-ir');
  assert.equal(output.stageArtifacts.verifiedIr.domain, 'verified-ir');
  assert.equal(output.stageArtifacts.specializedIr.domain, 'specialized-ir');
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
  const small = fixture({ maxOutputBytes: 100 });
  small.compiler.psCompilerJavaScriptStagesFromPrepared = () => ok(good);
  assert.throws(() => small.service.emitArtifact(handle, 'javascript'), /UNCHECKED_MODULE/);
  const smallHandle = await small.service.check('lean', 'same');
  assert.throws(() => small.service.emitArtifact(smallHandle, 'javascript'), /OUTPUT_RESOURCE_EXHAUSTED/);
  assert.equal(emitted.length, 0);
});
