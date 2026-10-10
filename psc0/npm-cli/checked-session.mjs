// Provider-neutral host authority. Not part of the portable compiler closure.
// A local handle prevents API misuse; this is NOT a sandbox for hostile host JS.
import { createHash } from 'node:crypto';
const hash = text => createHash('sha256').update(text, 'utf8').digest('hex');

export function unwrapCompilerResult(result, stage) {
  if (result !== null && typeof result === 'object') {
    const tags = Object.getOwnPropertySymbols(result).map(key => result[key]);
    if (tags.includes('ok') && !tags.includes('error')) return result.value;
    if (tags.includes('error') && !tags.includes('ok')) throw new Error(`PSC2_CHECKED_${stage}_FAILED`);
  }
  throw new Error(`PSC2_CHECKED_${stage}_RESULT_SHAPE`);
}

export function freezeDataGraph(root, maxNodes = 2_000_000) {
  if (!Number.isSafeInteger(maxNodes) || maxNodes < 1) throw new TypeError('Invalid graph budget');
  const pending = [root], seen = new WeakSet();
  let count = 0;
  while (pending.length) {
    const value = pending.pop();
    if (typeof value === 'function') throw new Error('PSC2_CHECKED_FUNCTION_FORBIDDEN');
    if (value === null || typeof value !== 'object' || seen.has(value)) continue;
    if (++count > maxNodes) throw new Error('PSC2_CHECKED_GRAPH_LIMIT');
    seen.add(value);
    const proto = Object.getPrototypeOf(value);
    if (proto !== null && proto !== Object.prototype && proto !== Array.prototype) throw new Error('PSC2_CHECKED_UNSUPPORTED_OBJECT');
    for (const key of Reflect.ownKeys(value)) {
      const descriptor = Object.getOwnPropertyDescriptor(value, key);
      if (!Object.hasOwn(descriptor, 'value')) throw new Error('PSC2_CHECKED_ACCESSOR_FORBIDDEN');
      pending.push(descriptor.value);
    }
    Object.freeze(value);
  }
  return root;
}

export function createCheckedPreparedSession(compiler, checkAdmissions, expectedIdentity) {
  const identity = freezeDataGraph({ ...expectedIdentity });
  if (!identity.protocol || !identity.provider || !identity.profile) throw new Error('PSC2_CHECKED_IDENTITY_REQUIRED');
  for (const name of ['psCompilerPrepareSource', 'psCompilerAdmissionsFromPrepared', 'psCompilerTypeScriptFromPrepared']) {
    if (typeof compiler?.[name] !== 'function') throw new Error(`PSC2_CHECKED_API_MISSING: ${name}`);
  }
  if (typeof checkAdmissions !== 'function') throw new TypeError('Expected kernel checker');
  const modules = new WeakMap();
  function encode(prepared) {
    const text = unwrapCompilerResult(compiler.psCompilerAdmissionsFromPrepared(prepared), 'ADMISSIONS');
    if (typeof text !== 'string') throw new Error('PSC2_CHECKED_ADMISSIONS_RESULT_SHAPE');
    if (Buffer.byteLength(text) > 16 * 1024 * 1024) throw new Error('PSC2_CHECKED_ADMISSIONS_LIMIT');
    return text;
  }
  function current(handle) {
    const item = handle !== null && typeof handle === 'object' ? modules.get(handle) : undefined;
    if (!item) throw new Error('PSC2_CHECKED_UNCHECKED_MODULE');
    if (encode(item.prepared) !== item.admissions) throw new Error('PSC2_CHECKED_PAYLOAD_CHANGED');
    return item;
  }
  async function checkPrepared(prepared, source, binding) {
    if (prepared === null || typeof prepared !== 'object') throw new Error('PSC2_CHECKED_PREPARE_RESULT_SHAPE');
    freezeDataGraph(prepared);
    const bound = freezeDataGraph(structuredClone(binding));
    const admissions = encode(prepared);
    const result = await checkAdmissions(admissions);
    for (const [field, expected] of Object.entries(identity)) {
      if (result?.[field] !== expected) throw new Error(`PSC2_CHECKED_PROVIDER_IDENTITY: ${field}`);
    }
    if (typeof result.accepted !== 'boolean') throw new Error('PSC2_CHECKED_PROVIDER_RESULT');
    if (!result.accepted) throw new Error(`PSC2_KERNEL_REJECTED: ${result.errorKind ?? 'kernel-rejection'}`);
    if ('errorKind' in result || 'declarationIndex' in result) throw new Error('PSC2_CHECKED_CONTRADICTORY_ACCEPTANCE');
    const handle = Object.freeze({ sourceSha256: hash(source), canonicalAdmissionsSha256: hash(admissions), provider: identity, binding: bound });
    modules.set(handle, { prepared, admissions });
    return handle;
  }
  return Object.freeze({
    async check(sourceKind, source, binding = {}) {
      if (typeof source !== 'string') throw new TypeError('Expected immutable source text');
      return checkPrepared(unwrapCompilerResult(compiler.psCompilerPrepareSource(sourceKind, source), 'PREPARE'), source, binding);
    },
    async checkSources(sourceKind, sources, binding = {}) {
      if (!Array.isArray(sources) || sources.some(s => typeof s !== 'string')) throw new TypeError('Expected immutable source texts');
      if (typeof compiler.psCompilerPrepareSources !== 'function' || typeof compiler.List?.nil !== 'function' || typeof compiler.List.cons !== 'function') throw new Error('PSC2_CHECKED_API_MISSING: module preparation');
      const captured = sources.slice();
      let values = compiler.List.nil();
      for (let i = captured.length - 1; i >= 0; i--) values = compiler.List.cons(captured[i], values);
      const prepared = unwrapCompilerResult(compiler.psCompilerPrepareSources(sourceKind, values), 'PREPARE');
      return checkPrepared(prepared, captured.join('\n\n') + '\n', binding);
    },
    emit(handle) {
      const item = current(handle);
      const output = unwrapCompilerResult(compiler.psCompilerTypeScriptFromPrepared(item.prepared), 'EMIT');
      if (typeof output !== 'string') throw new Error('PSC2_CHECKED_EMIT_RESULT_SHAPE');
      return output;
    },
    assertCurrent(handle) { current(handle); },
    revoke(handle) { modules.delete(handle); },
  });
}
