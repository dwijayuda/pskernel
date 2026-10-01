import { createHash } from 'node:crypto';

export const leanCheckedIdentity = Object.freeze({
  protocol: 'pskernel-lean/1', provider: 'lean4-cpp', leanVersion: '4.34.0',
  leanCommit: '293d5d0c0c3f3dded4688b3ccd6a33939ac5102b', profile: 'lean4.34-core',
});
const hash = text => createHash('sha256').update(text, 'utf8').digest('hex');

export function unwrapCompilerResult(result, stage) {
  if (result !== null && typeof result === 'object') {
    const tags = Object.getOwnPropertySymbols(result).map(key => result[key]);
    if (tags.includes('ok') && !tags.includes('error')) return result.value;
    if (tags.includes('error') && !tags.includes('ok')) {
      throw new Error(`PSC2_CHECKED_${stage}_FAILED`);
    }
  }
  throw new Error(`PSC2_CHECKED_${stage}_RESULT_SHAPE`);
}

function freezeGraph(root) {
  const pending = [root]; const seen = new WeakSet();
  while (pending.length) {
    const value = pending.pop();
    if (value === null || typeof value !== 'object' || seen.has(value)) continue;
    seen.add(value);
    const proto = Object.getPrototypeOf(value);
    if (proto !== null && proto !== Object.prototype && proto !== Array.prototype) {
      throw new Error('PSC2_CHECKED_UNSUPPORTED_OBJECT');
    }
    for (const key of Reflect.ownKeys(value)) {
      const descriptor = Object.getOwnPropertyDescriptor(value, key);
      if (!Object.hasOwn(descriptor, 'value')) throw new Error('PSC2_CHECKED_ACCESSOR_FORBIDDEN');
      if (typeof descriptor.value === 'function') throw new Error('PSC2_CHECKED_FUNCTION_FORBIDDEN');
      pending.push(descriptor.value);
    }
    Object.freeze(value);
  }
  return root;
}

function admissionsFrom(compiler, prepared) {
  const source = unwrapCompilerResult(compiler.psCompilerAdmissionsFromPrepared(prepared), 'ADMISSIONS');
  if (typeof source !== 'string') throw new Error('PSC2_CHECKED_ADMISSIONS_RESULT_SHAPE');
  return source;
}

/**
 * Trusted host composition boundary. compiler and checkAdmissions are selected by
 * the host, never by a serialized receipt or an untrusted caller's checked flag.
 * Production composes this with the pinned pskernel-lean package. Test doubles
 * exercise orchestration only. This does not sandbox malicious compiler/host JS
 * and does not claim a portable, universally unforgeable CheckedCore type.
 */
export function createCheckedPreparedSession(compiler, checkAdmissions) {
  for (const name of ['psCompilerPrepareSource', 'psCompilerAdmissionsFromPrepared',
    'psCompilerTypeScriptFromPrepared']) {
    if (typeof compiler?.[name] !== 'function') throw new Error(`PSC2_CHECKED_API_MISSING: ${name}`);
  }
  if (typeof checkAdmissions !== 'function') throw new TypeError('Expected kernel checker');
  const modules = new WeakMap();
  return Object.freeze({
    async check(sourceKind, source) {
      if (typeof source !== 'string') throw new TypeError('Expected immutable source text');
      const prepared = unwrapCompilerResult(compiler.psCompilerPrepareSource(sourceKind, source), 'PREPARE');
      if (prepared === null || typeof prepared !== 'object') throw new Error('PSC2_CHECKED_PREPARE_RESULT_SHAPE');
      freezeGraph(prepared);
      const admissions = admissionsFrom(compiler, prepared);
      const result = await checkAdmissions(admissions);
      for (const [field, expected] of Object.entries(leanCheckedIdentity)) {
        if (result?.[field] !== expected) throw new Error(`PSC2_CHECKED_PROVIDER_IDENTITY: ${field}`);
      }
      if (typeof result.accepted !== 'boolean') throw new Error('PSC2_CHECKED_PROVIDER_RESULT');
      if (!result.accepted) throw new Error(`PSC2_KERNEL_REJECTED: ${result.errorKind ?? 'kernel-rejection'}`);
      const handle = Object.freeze({
        sourceSha256: hash(source), canonicalAdmissionsSha256: hash(admissions),
        provider: leanCheckedIdentity,
      });
      modules.set(handle, { prepared, admissions });
      return handle;
    },
    emit(handle) {
      const item = handle !== null && typeof handle === 'object' ? modules.get(handle) : undefined;
      if (!item) throw new Error('PSC2_CHECKED_UNCHECKED_MODULE');
      if (admissionsFrom(compiler, item.prepared) !== item.admissions) {
        throw new Error('PSC2_CHECKED_PAYLOAD_CHANGED');
      }
      const output = unwrapCompilerResult(compiler.psCompilerTypeScriptFromPrepared(item.prepared), 'EMIT');
      if (typeof output !== 'string') throw new Error('PSC2_CHECKED_EMIT_RESULT_SHAPE');
      return output;
    },
  });
}
