import assert from 'node:assert/strict';
import { test } from 'node:test';
import { createHash } from 'node:crypto';
import { createCheckedCompilerService } from './compiler-checked-service.mjs';
import { leanCheckedIdentity } from './checked-kernel-identity.mjs';

const ok = value => ({ $ps$tag: 'ok', $ps$fields: { value } });
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
  return { service, emitted };
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
