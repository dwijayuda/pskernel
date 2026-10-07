import path from 'node:path';
import { verifyArtifact } from './artifact-evidence.mjs';
import { decodeIrArtifact, irEncodingContract } from './ir-artifact.mjs';
import { readObservedFileBytes } from './observed-file-bytes.mjs';
import { runBoundedProcess } from './bounded-process.mjs';

const defaults = Object.freeze({ maxBytes: 16 * 1024 * 1024, maxDepth: 256,
  maxNodes: 1000000, maxValidatorBytes: 128 * 1024 * 1024, wallTimeMs: 60000 });
const result = (kind, details = {}) => ({ kind, ...details, authority: 'none',
  preservationVerified: false, sourceAcceptanceVerified: false });

/** Caller selects and pins the validator, never the archive. Its implementation
 * and stable executable path are explicit trust assumptions; this is neither
 * a sandbox nor proof of validator soundness. No decoded object becomes a live
 * CheckedCore/CertifiedSource capability.
 */
export async function replayClosedIrArtifact(artifact, configuration) {
  let bytes, identity, binaryId, bound, root;
  try {
    if (!configuration || !path.isAbsolute(configuration.binary ?? '') ||
        !path.isAbsolute(configuration.cwd ?? '') ||
        Object.keys(configuration.limits ?? {}).some(key => !Object.hasOwn(defaults, key)))
      throw new Error('PSC_IR_REPLAY_CONFIGURATION');
    bound = { ...defaults, ...configuration.limits };
    if (Object.values(bound).some(value => !Number.isSafeInteger(value) || value < 0) ||
        bound.maxBytes > 134217728 || bound.wallTimeMs > 2147483647)
      throw new Error('PSC_IR_REPLAY_CONFIGURATION');
    if (!(artifact?.bytes instanceof Uint8Array) || artifact.bytes.byteLength > bound.maxBytes)
      return result('resourceExhausted', { resource: 'inputBytes' });
    bytes = Buffer.from(artifact.bytes);
    identity = Object.freeze({ ...artifact.identity });
    binaryId = Object.freeze({ ...configuration.expectedBinaryId });
    verifyArtifact(bytes, identity);
    if (identity.contract !== irEncodingContract ||
        !['runtime-ir', 'verified-ir', 'specialized-ir'].includes(identity.domain))
      throw new Error('PSC_IR_REPLAY_SUBJECT');
    root = decodeIrArtifact(bytes, bound);
  } catch (error) {
    return result(error.kind === 'resourceExhausted' || /EXHAUSTED/u.test(error.message)
      ? 'resourceExhausted' : 'rejectedInvalid', { reason: error.message });
  }
  if (root[1].length !== 0)
    return result('declinedUnsupported', { reason: 'PSC_IR_REPLAY_LINK_CONTEXT_REQUIRED' });
  try {
    verifyArtifact(await readObservedFileBytes(configuration.binary, bound.maxValidatorBytes), binaryId);
  } catch (error) {
    return result('infrastructureUnavailable', { reason: 'PSC_IR_REPLAY_VALIDATOR_IDENTITY', detail: error.message });
  }
  const executed = await runBoundedProcess({ binary: configuration.binary, args: ['--validate'],
    cwd: configuration.cwd, env: configuration.env ?? {}, input: bytes, signal: configuration.signal,
    limits: { inputBytes: bound.maxBytes, stdoutBytes: 256, stderrBytes: 4096, wallTimeMs: bound.wallTimeMs } });
  // Reject tool substitution observed across the execution interval.
  try {
    verifyArtifact(await readObservedFileBytes(configuration.binary, bound.maxValidatorBytes), binaryId);
  } catch (error) {
    return result('infrastructureUnavailable', { reason: 'PSC_IR_REPLAY_VALIDATOR_CHANGED', detail: error.message });
  }
  if (executed.kind === 'resourceExhausted' || executed.kind === 'infrastructureUnavailable')
    return result(executed.kind, { reason: executed.code, resource: executed.resource, observation: executed.observation });
  const output = executed.kind === 'accepted' ? executed.value : executed.process;
  const text = output?.stdout?.toString('utf8');
  if (executed.kind === 'accepted' && /^valid-closed-ir\r?\n$/u.test(text ?? '') && output.stderr.length === 0)
    return result('accepted', { contract: 'psc-closed-ir-invariant-replay/1', identity, validatorId: binaryId,
      validationScope: 'closed-ir-invariants-only', observation: executed.observation,
      assumptions: ['pinned-native-validator-implementation', 'stable-host-executable-path-and-runtime'] });
  if (output?.code === 1 && /^(schema|parse|non-canonical|invalid-ir)\r?\n$/u.test(text ?? ''))
    return result('rejectedInvalid', { reason: 'PSC_IR_REPLAY_' + text.trim(), identity });
  if (output?.code === 1 && /^resource-(depth|bytes|parse|encode)\r?\n$/u.test(text ?? ''))
    return result('resourceExhausted', { resource: text.trim(), identity });
  return result('infrastructureUnavailable', { reason: 'PSC_IR_REPLAY_PROTOCOL', observation: executed.observation });
}
