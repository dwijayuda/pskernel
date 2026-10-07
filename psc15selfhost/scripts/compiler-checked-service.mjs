import { createHash } from 'node:crypto';
import { createKernelCheckedSession } from './kernel-checked-session.mjs';
import { kernelContractV1 } from './kernel-contract.mjs';
import { checkedIrStageArtifacts } from './ir-artifact.mjs';
import { verifySpecializationCorrespondence } from './specialization-correspondence.mjs';

function byteList(value, limit) {
  const bytes = [], seen = new WeakSet();
  let cursor = value;
  while (cursor && typeof cursor === 'object') {
    if (seen.has(cursor)) throw new Error('PSC_CHECKED_BYTES_CYCLE');
    seen.add(cursor);
    const tag = cursor.$ps$tag ?? Object.getOwnPropertySymbols(cursor).map(key => cursor[key]).find(tag => tag === 'nil' || tag === 'cons');
    if (tag === 'nil') return Uint8Array.from(bytes);
    if (tag !== 'cons') break;
    const fields = cursor.$ps$fields ?? cursor;
    if (!Number.isInteger(fields.head) || fields.head < 0 || fields.head > 255) break;
    if (bytes.length >= limit) throw new Error('PSC_CHECKED_OUTPUT_RESOURCE_EXHAUSTED');
    bytes.push(fields.head); cursor = fields.tail;
  }
  throw new Error('PSC_CHECKED_BYTES_SHAPE');
}

/** Host composition root. A receipt can describe a capability but cannot mint one. */
export function createCheckedCompilerService({
  compiler, checkAdmissions, identity, providerSecurity, kernelContract = kernelContractV1,
  targets = ['typescript'], assumptionPolicy = 'kernel-contract-default',
  resourcePolicy = 'checked-host-output/1', maxOutputBytes = 256 * 1024 * 1024,
}) {
  if (!Number.isSafeInteger(maxOutputBytes) || maxOutputBytes < 0) throw new Error('PSC_CHECKED_OUTPUT_BUDGET');
  const session = createKernelCheckedSession(compiler, checkAdmissions, identity, kernelContract, providerSecurity,
    { targets, assumptionPolicy, resourcePolicy });
  function emitArtifact(handle, target = 'typescript') {
    const capability = session.describe(handle);
    const emission = session.emitTargetWithStages(handle, target);
    const raw = emission.output;
    const payload = target === 'wasm' ? byteList(raw, maxOutputBytes) : raw;
    const bytes = typeof payload === 'string' ? Buffer.from(payload, 'utf8') : payload;
    if (bytes.byteLength > maxOutputBytes) throw new Error('PSC_CHECKED_OUTPUT_RESOURCE_EXHAUSTED');
    if (emission.stages && bytes.byteLength + Object.values(emission.stages).reduce((sum, value) => sum + Buffer.byteLength(value), 0)
        > maxOutputBytes) throw new Error('PSC_CHECKED_OUTPUT_RESOURCE_EXHAUSTED');
    const stages = checkedIrStageArtifacts(emission.stages, { maxBytes: maxOutputBytes });
    if (stages && !stages.runtimeIr.bytes.equals(stages.verifiedIr.bytes)) throw new Error('PSC_CHECKED_VALIDATION_CHANGED_IR');
    const specialization = stages?.specializedIr ?
      verifySpecializationCorrespondence(stages.verifiedIr, stages.specializedIr, { maxBytes: maxOutputBytes }) : undefined;
    return Object.freeze({
      contract: 'psc-checked-emission/1', target, payload,
      artifact: Object.freeze({ algorithm: 'sha256', domain: 'target-bytes', schemaVersion: 1,
        digest: createHash('sha256').update(bytes).digest('hex'), byteLength: bytes.byteLength }),
      checkedCore: capability,
      ...(specialization ? { specializationCorrespondence: specialization } : {}),
      ...(emission.stages ? { stages: emission.stages,
        stageArtifacts: Object.freeze(Object.fromEntries(Object.entries(stages).map(([key, value]) => [key, value.identity]))) } : {}),
      transformationAssurance: 'trusted-implementation-global-preservation-unproved',
    });
  }
  return Object.freeze({
    check: session.check, checkSources: session.checkSources,
    emit: handle => emitArtifact(handle, 'typescript').payload,
    emitArtifact, describe: session.describe, revoke: session.revoke, close: session.close,
  });
}
