import assert from 'node:assert/strict';
import { existsSync } from 'node:fs';
import { test } from 'node:test';
import { fileURLToPath } from 'node:url';
import { runCheckedSeedSession } from './checked-seed-session.mjs';
import { checkAdmissionsWithKernel } from './checked-kernel-provider.mjs';

const binaryPath = fileURLToPath(new URL('../lean-checked/.lake/build/bin/psc2_lean_checked_seed' +
  (process.platform === 'win32' ? '.exe' : ''), import.meta.url));
const available = existsSync(binaryPath);
for (const sourceKind of ['lean', 'ps']) {
  const sources =
    sourceKind === 'lean'
      ? ['def first : Nat := 7\n', 'def second : Nat := first\n']
      : ['const first: Nat := { 7 }\n', 'const second: Nat := { first }\n'];
  const source = sources.join('\n\n') + '\n';
  test(`real ${sourceKind} module session emits only after the explicit Wasm check`, { skip: !available }, async () => {
    let calls = 0;
    const result = await runCheckedSeedSession({
      binaryPath, sourceKind, source, sources, emit: true,
      checkAdmissions: async admissions => {
        calls++;
        assert(admissions.includes('second'));
        return (await checkAdmissionsWithKernel(admissions, 'lean434-wasm')).result;
      },
    });
    assert.equal(calls, 1);
    assert.match(result.typeScript, /export const second/);
    assert.equal(typeof result.stages.runtimeIr, 'string');
    assert.equal(result.stages.runtimeIr, result.stages.verifiedIr);
    assert.equal(result.resourceObservation.observed.frames, 2);
    assert.equal(result.resourceObservation.observed.sourceCount, 2);
  });
  test(`real ${sourceKind} module session blocks emission on rejection`, { skip: !available }, async () => {
    await assert.rejects(runCheckedSeedSession({
      binaryPath, sourceKind, source, sources, emit: true,
      checkAdmissions: () => ({ accepted: false, errorKind: 'test-rejection' }),
    }), /PSC2_KERNEL_REJECTED: test-rejection/);
  });
}
test('module partition must exactly reproduce the immutable source', async () => {
  await assert.rejects(runCheckedSeedSession({
    binaryPath, sourceKind: 'lean', source: 'different', sources: ['original'],
    emit: true, checkAdmissions: () => { throw new Error('must not be called'); },
  }), /PSC2_CHECKED_SEED_SOURCE_PARTITION/);
});

test('native session enforces admissions/output limits and never calls checker after input/frame exhaustion', { skip: !available }, async () => {
  for (const [resource, resourceLimits, calls] of [
    ['sourceBytes', { sourceBytes: 0 }, 0], ['sourceCount', { sourceCount: 0 }, 0],
    ['snapshotBytes', { snapshotBytes: 0 }, 0], ['frameBytes', { frameBytes: 0 }, 0],
    ['stdoutBytes', { stdoutBytes: 0 }, 0], ['admissionsBytes', { admissionsBytes: 0 }, 0],
    ['generatedBytes', { generatedBytes: 0 }, 1],
  ]) {
    let invoked = 0;
    await assert.rejects(runCheckedSeedSession({ binaryPath, sourceKind: 'lean', source: 'def answer : Nat := 42\n',
      emit: true, resourceLimits, checkAdmissions: async admissions => {
        invoked++; return (await checkAdmissionsWithKernel(admissions, 'lean434-wasm')).result;
      } }), error => error.kind === 'resourceExhausted' && error.resource === resource);
    assert.equal(invoked, calls, resource);
  }
});

test('native session times out stalled kernel waits and confirms child termination', { skip: !available }, async () => {
  let invoked = false;
  await assert.rejects(runCheckedSeedSession({ binaryPath, sourceKind: 'lean', source: 'def answer : Nat := 42\n',
    emit: true, timeoutMs: 2000, checkAdmissions: () => { invoked = true; return new Promise(() => {}); } }),
    error => error.kind === 'resourceExhausted' && error.resource === 'phaseTimeMs' && error.phase === 'kernel-check');
  assert.equal(invoked, true);
});

test('native session bounds stderr from a process that rejects the protocol arguments', async () => {
  await assert.rejects(runCheckedSeedSession({ binaryPath: process.execPath, sourceKind: 'lean', source: '',
    emit: false, resourceLimits: { stderrBytes: 0 }, checkAdmissions: () => { throw new Error('must not check'); } }),
    error => error.kind === 'resourceExhausted' && error.resource === 'stderrBytes');
});

test('direct seed selection is copied as data and rejects unknown target/profile/flags before spawning', async () => {
  const good = { target: 'javascript', representation: 'psc-js-closed-instances/1',
    metadata: false, declarations: false, sourceMap: false };
  for (const productRequest of [null, { ...good, target: 'unknown' }, { ...good, metadata: 1 },
    { ...good, unknown: true }, { ...good, target: 'wasm', declarations: true },
    Object.defineProperty({ ...good }, 'metadata', { get() { throw new Error('GETTER_MUST_NOT_RUN'); } })])
    await assert.rejects(runCheckedSeedSession({ binaryPath: 'missing-binary', sourceKind: 'lean', source: '',
      emit: true, productRequest, checkAdmissions: () => { throw new Error('MUST_NOT_CHECK'); } }), /PRODUCT_SELECTION/);
});

test('Canonical native selection rejects wrong targets, missing artifacts and policy accessors before spawning',async()=>{
  const good={target:'wasm',representation:'psc-js-closed-instances/1',metadata:false,declarations:false,sourceMap:false};
  let accessed=false;
  const accessor=Object.defineProperty({...good},'wasmCanonicalSelection',{enumerable:true,
    get(){accessed=true;throw new Error('GETTER_MUST_NOT_RUN');}});
  for(const productRequest of [{...good,wasmCanonicalSelection:null},
    {...good,target:'javascript',wasmCanonicalSelection:{}},accessor]){
    await assert.rejects(runCheckedSeedSession({binaryPath:'missing-binary',sourceKind:'lean',source:'',
      emit:true,productRequest,checkAdmissions:()=>{throw new Error('MUST_NOT_CHECK');}}),
      /PRODUCT_SELECTION|SELECTION_RESOURCE/);
  }
  assert.equal(accessed,false);
});
