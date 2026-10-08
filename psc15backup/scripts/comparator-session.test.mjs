import assert from 'node:assert/strict';
import { test } from 'node:test';
import { canonicalArtifact, canonicalBytes } from './artifact-evidence.mjs';
import { createComparatorSession } from './comparator-session.mjs';
import { checkedKernelIdentity } from './checked-kernel-identity.mjs';

// Orchestration fixtures only: mocked kernels do not establish a Lean theorem.
const reference = canonicalBytes({ format: 'proofscript-checked-admissions', version: 2, admissions: [
  { kind: 'constant', declaration: { k: 'theorem', lp: [], n: { k: 'anonymous' },
    t: { k: 'sort', l: { k: 'zero' } }, v: { k: 'nat', v: '0' } } },
] }).toString();
const theoryBase = canonicalArtifact({ theoryId: 'test-only' }, 'theory-base', 'test-theory/1');
const source = canonicalArtifact({ sources: ['fixture'] }, 'source', 'psc-source-snapshot/1');
const producer = { runtimeBinary: process.execPath, endpoint: 'unix:///var/run/docker.sock',
  image: 'example.invalid/producer@sha256:' + 'a'.repeat(64), command: ['/producer'],
  policy: { memoryBytes: 67108864, temporaryBytes: 1048576, processCount: 32, cpuCount: 1, platform: 'linux/amd64' } };
function exported(options, admissions = reference) {
  const { challenge } = JSON.parse(options.input);
  return { kind: 'accepted', value: { stdout: canonicalBytes({ contract: 'psc-comparator-export/1',
    challengeId: challenge.identity, sourceClosureId: challenge.value.sourceClosureId, admissions }) },
    isolation: { contract: 'psc-isolated-producer/1', image: producer.image, policy: producer.policy,
      mechanism: 'test-double-only', hardeningAssurance: 'not-tested' } };
}
async function fixture(options = {}) {
  const calls = [];
  const session = await createComparatorSession({ theoryBase, produce: async options => exported(options),
    check: async (admissions, selector) => {
      calls.push({ admissions, selector }); return { result: { ...checkedKernelIdentity(selector), accepted: true } };
    }, ...options });
  const challenge = session.issue({ source, referenceAdmissions: reference, producer });
  return { session, challenge, calls };
}

test('both pinned checkers see exact exported bytes before a non-replayable live handle is minted', async () => {
  const { session, challenge, calls } = await fixture();
  const result = await session.run(challenge);
  assert.equal(result.kind, 'accepted'); assert.equal(calls.length, 2);
  assert.ok(calls.every(call => call.admissions === reference));
  assert.equal(session.checkedAdmissions(result.value), reference);
  assert.equal(session.describe(result.value).executablePreservation, 'not-established');
  assert.throws(() => session.describe(JSON.parse(JSON.stringify(result.value))), /NOT_A_LIVE/);
  assert.equal((await session.run(challenge)).kind, 'rejected');
  session.revoke(result.value);
  assert.throws(() => session.checkedAdmissions(result.value), /NOT_A_LIVE/);
});

test('a changed statement fails before any checker invocation', async () => {
  const altered = JSON.parse(reference); altered.admissions[0].declaration.t = { k: 'nat', v: '42' };
  const { session, challenge, calls } = await fixture({ produce: async options => exported(options, canonicalBytes(altered).toString()) });
  const result = await session.run(challenge);
  assert.equal(result.kind, 'rejected'); assert.equal(calls.length, 0);
});

test('checker disagreement and unavailable required model checking are inconclusive', async () => {
  const disagree = await fixture({ check: async (_admissions, selector) => ({ result: selector === 'pskernel-core'
    ? { ...checkedKernelIdentity(selector), accepted: false, errorKind: 'kernel-rejection', declarationIndex: 0, message: 'definition type mismatch' }
    : { ...checkedKernelIdentity(selector), accepted: true } }) });
  assert.equal((await disagree.session.run(disagree.challenge)).kind, 'inconclusive');
  const model = await fixture({ requireModelCheck: true });
  const result = await model.session.run(model.challenge);
  assert.equal(result.kind, 'inconclusive'); assert.equal(result.code, 'model-checker-unavailable');
});

test('producer limits, false identity and missing isolation cannot become acceptance', async () => {
  const limited = await fixture({ produce: async () => ({ kind: 'resourceExhausted', resource: 'wallTime' }) });
  assert.equal((await limited.session.run(limited.challenge)).kind, 'resourceExhausted');
  const identity = await fixture({ check: async () => ({ result: { accepted: true, provider: 'wrong' } }) });
  assert.equal((await identity.session.run(identity.challenge)).kind, 'infrastructureFailure');
  const isolated = await fixture({ produce: async options => ({ ...exported(options), isolation: null }) });
  assert.equal((await isolated.session.run(isolated.challenge)).kind, 'infrastructureFailure');
});

test('closing during production prevents new authority and paranoid rules remain enforced', async () => {
  let finish;
  const { session, challenge, calls } = await fixture({ produce: options => new Promise(resolve => {
    finish = () => resolve(exported(options));
  }) });
  const pending = session.run(challenge); session.close(); finish();
  assert.equal((await pending).kind, 'resourceExhausted'); assert.equal(calls.length, 0);
  await assert.rejects(createComparatorSession({ theoryBase, securityProfile: 'paranoid-v1' }));
});
