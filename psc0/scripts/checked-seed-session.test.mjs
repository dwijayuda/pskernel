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
  const end = '\n';
  const sources = ['def first : Nat := 7' + end, 'def second : Nat := first' + end];
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
