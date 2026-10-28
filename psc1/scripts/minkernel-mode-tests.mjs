import assert from 'node:assert/strict';
import { checkerModes, defaultCheckerMode, createResearchKernelToolchain }
  from '../packages/pskernel-min/host/toolchain.mjs';
assert.deepEqual(checkerModes, ['min', 'lean-wasm', 'lean-native', 'dual']);
assert.equal(defaultCheckerMode, 'lean-wasm');
await assert.rejects(createResearchKernelToolchain({ mode: 'source-selected-anything' }));
for (const mode of ['min', 'dual']) {
  const checker = await createResearchKernelToolchain({ mode });
  for (const input of ['{', '{}', JSON.stringify({ protocol: 'pskernel-lean/1',
    format: 'proofscript-checked-admissions', version: 2, admissions: [],
    kernel: 'lean-native', accepted: true, canonicalBridgeQualified: true })]) {
    const result = await checker.checkCanonicalAdmissions(input);
    assert.equal(result.accepted, false);
    assert.equal(result.delegated, false);
    assert.equal(result.code, 'PSC1_MIN_CANONICAL_BRIDGE_UNPROVED');
  }
}
console.log('PSC1_MIN_MODES_PASS: canonical min/dual refuse before tool selection or fallback');
