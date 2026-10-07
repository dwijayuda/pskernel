import { createHash, randomUUID } from 'node:crypto';

import { leanCheckedIdentity } from './checked-kernel-identity.mjs';
import {
  assertCanonicalAdmissionsEnvelope,
  assertKernelContractDecision,
  kernelContractV1,
} from './kernel-contract.mjs';
export { leanCheckedIdentity } from './checked-kernel-identity.mjs';
export { kernelContractV1 } from './kernel-contract.mjs';
const hash = text => createHash('sha256').update(text, 'utf8').digest('hex');

export function unwrapCompilerResult(result, stage) {
  if (result !== null && typeof result === 'object') {
    if (Object.hasOwn(result, '$ps$tag')) {
      if (result.$ps$tag === 'ok' && result.$ps$fields && Object.hasOwn(result.$ps$fields, 'value')) return result.$ps$fields.value;
      if (result.$ps$tag === 'error') throw new Error(`PSC2_CHECKED_${stage}_FAILED`);
      throw new Error(`PSC2_CHECKED_${stage}_RESULT_SHAPE`);
    }
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
  assertCanonicalAdmissionsEnvelope(source);
  return source;
}

/**
 * Trusted host composition boundary. compiler and checkAdmissions are selected by
 * the host, never by a serialized receipt or an untrusted caller's checked flag.
 * Production supplies the selected, pinned kernel identity. Test doubles
 * exercise orchestration only. This does not sandbox malicious compiler/host JS
 * and does not claim a portable, universally unforgeable CheckedCore type.
 */
export function createKernelCheckedSession(
  compiler,
  checkAdmissions,
  expectedIdentity = leanCheckedIdentity,
  kernelContract = kernelContractV1,
  providerSecurity = Object.freeze({ contract: 'psc-provider-security/1', profile: 'unclassified-development' }),
  policy = {},
) {
  const sessionIdentity = randomUUID();
  const targets = Object.freeze([...(policy.targets ?? ['typescript'])]);
  const permittedTargets = new Set(['typescript', 'javascript', 'wasm', 'rust']);
  if (targets.length === 0 || targets.some(target => !permittedTargets.has(target))) throw new Error('PSC2_CHECKED_TARGET_POLICY');
  const security = freezeGraph(structuredClone(providerSecurity));
  const assumptionPolicy = policy.assumptionPolicy ?? 'kernel-contract-default';
  const resourcePolicy = policy.resourcePolicy ?? 'kernel-contract-default';
  if (typeof assumptionPolicy !== 'string' || !assumptionPolicy || typeof resourcePolicy !== 'string' || !resourcePolicy) throw new Error('PSC2_CHECKED_POLICY_IDENTITY');
  let closed = false;
  const identity = Object.freeze({ ...expectedIdentity });
  if (!identity.protocol || !identity.provider || !identity.profile) {
    throw new Error('PSC2_CHECKED_IDENTITY_REQUIRED');
  }
  if (kernelContract?.id !== kernelContractV1.id ||
      kernelContract?.sha256 !== kernelContractV1.sha256) {
    throw new Error('PSC2_KERNEL_CONTRACT_IDENTITY');
  }
  for (const name of ['psCompilerPrepareSource', 'psCompilerAdmissionsFromPrepared']) {
    if (typeof compiler?.[name] !== 'function') throw new Error(`PSC2_CHECKED_API_MISSING: ${name}`);
  }
  if (typeof checkAdmissions !== 'function') throw new TypeError('Expected kernel checker');
  const modules = new WeakMap();
  function requireOpen() { if (closed) throw new Error('PSC2_CHECKED_SESSION_CLOSED'); }
  function checkedItem(handle) {
    requireOpen();
    const item = handle !== null && typeof handle === 'object' ? modules.get(handle) : undefined;
    if (!item) throw new Error('PSC2_CHECKED_UNCHECKED_MODULE');
    return item;
  }
  async function checkPrepared(prepared, source) {
      requireOpen();
      if (prepared === null || typeof prepared !== 'object') throw new Error('PSC2_CHECKED_PREPARE_RESULT_SHAPE');
      freezeGraph(prepared);
      const admissions = admissionsFrom(compiler, prepared);
      const result = assertKernelContractDecision(
        await checkAdmissions(admissions),
      );
      for (const [field, expected] of Object.entries(identity)) {
        if (result?.[field] !== expected) throw new Error(`PSC2_CHECKED_PROVIDER_IDENTITY: ${field}`);
      }
      if (!result.accepted) throw new Error(`PSC2_KERNEL_REJECTED: ${result.errorKind}`);
      requireOpen();
      const handle = Object.freeze({
        capability: 'psc-checked-core-capability/1',
        sessionIdentity,
        semanticProfile: identity.profile,
        assumptionPolicy,
        resourcePolicy,
        targets,
        sourceSha256: hash(source),
        canonicalAdmissionsSha256: hash(admissions),
        kernelContract: kernelContractV1,
        provider: identity,
        providerSecurity: security,
      });
      modules.set(handle, { prepared, admissions, source });
      return handle;
  }
  function emitTargetWithStages(handle, target) {
      const item = checkedItem(handle);
      if (!targets.includes(target)) throw new Error('PSC2_CHECKED_TARGET_FORBIDDEN');
      if (admissionsFrom(compiler, item.prepared) !== item.admissions) {
        throw new Error('PSC2_CHECKED_PAYLOAD_CHANGED');
      }
      const stageApi = target === 'typescript' ? 'psCompilerTypeScriptStagesFromPrepared' :
        target === 'javascript' ? 'psCompilerJavaScriptStagesFromPrepared' :
        target === 'wasm' ? 'psCompilerWasmStagesFromPrepared' : undefined;
      if (stageApi && stageApi in compiler) {
        if (typeof compiler[stageApi] !== 'function') throw new Error('PSC2_CHECKED_EMIT_STAGES_API_SHAPE');
        if (target === 'wasm' && !compiler.psCompilerWasm32Target) throw new Error('PSC2_CHECKED_WASM_TARGET_MISSING');
        const staged = unwrapCompilerResult(target === 'wasm' ?
          compiler[stageApi](compiler.psCompilerWasm32Target, item.prepared) : compiler[stageApi](item.prepared), 'EMIT_STAGES');
        const outputKey = target === 'typescript' ? 'typeScript' : target === 'wasm' ? 'wasm' : 'javaScript';
        // The service copies/validates the Wasm linked byte list under its byte
        // budget; avoid an unbounded deep-freeze traversal before that boundary.
        if (target !== 'wasm') freezeGraph(staged);
        if ((target === 'wasm' ? !staged?.[outputKey] || typeof staged[outputKey] !== 'object' : typeof staged?.[outputKey] !== 'string') ||
            typeof staged.runtimeIr !== 'string' || typeof staged.verifiedIr !== 'string' ||
            (target !== 'typescript' && typeof staged.specializedIr !== 'string') ||
            (target === 'javascript' && typeof staged.jsIr !== 'string') ||
            (target === 'wasm' && typeof staged.wasmIr !== 'string')) {
          throw new Error('PSC2_CHECKED_EMIT_STAGES_SHAPE');
        }
        return Object.freeze({ output: staged[outputKey],
          stages: Object.freeze({
            runtimeIr: staged.runtimeIr,
            verifiedIr: staged.verifiedIr,
            ...(target !== 'typescript' ? { specializedIr: staged.specializedIr } : {}),
            ...(target === 'javascript' ? { jsIr: staged.jsIr } : {}),
            ...(target === 'wasm' ? { wasmIr: staged.wasmIr } : {}),
          }) });
      }
      const names = { typescript: 'psCompilerTypeScriptFromPrepared', javascript: 'psCompilerJavaScriptFromPrepared',
        rust: 'psCompilerRustFromPrepared', wasm: 'psCompilerWasmFromPrepared' };
      const name = names[target];
      if (typeof compiler[name] !== 'function') throw new Error(`PSC2_CHECKED_API_MISSING: ${name}`);
      let result;
      if (target === 'typescript') result = compiler.psCompilerTypeScriptFromPrepared(item.prepared);
      else if (target === 'wasm') {
        if (!compiler.psCompilerWasm32Target) throw new Error('PSC2_CHECKED_WASM_TARGET_MISSING');
        result = compiler[name](compiler.psCompilerWasm32Target, item.prepared);
      } else result = compiler[name](item.prepared);
      const output = unwrapCompilerResult(result, 'EMIT');
      if (target !== 'wasm' && typeof output !== 'string') throw new Error('PSC2_CHECKED_EMIT_RESULT_SHAPE');
      return Object.freeze({ output });
  }
  // Legacy selected compiler modules can lack this product. Presence with a
  // malformed or failing API is never treated as an optional-product absence.
  function publicApi(handle) {
    const item = checkedItem(handle);
    if (admissionsFrom(compiler, item.prepared) !== item.admissions) throw new Error('PSC2_CHECKED_PAYLOAD_CHANGED');
    if (!('psCompilerPublicApiFromPrepared' in compiler)) return undefined;
    if (typeof compiler.psCompilerPublicApiFromPrepared !== 'function') throw new Error('PSC2_CHECKED_PUBLIC_API_API_SHAPE');
    const output = unwrapCompilerResult(compiler.psCompilerPublicApiFromPrepared(item.prepared), 'PUBLIC_API');
    if (typeof output !== 'string') throw new Error('PSC2_CHECKED_PUBLIC_API_RESULT_SHAPE');
    return output;
  }
  function emitTarget(handle, target) { return emitTargetWithStages(handle, target).output; }
  return Object.freeze({
    async check(sourceKind, source) {
      requireOpen();
      if (typeof source !== 'string') throw new TypeError('Expected immutable source text');
      const prepared = unwrapCompilerResult(compiler.psCompilerPrepareSource(sourceKind, source), 'PREPARE');
      return checkPrepared(prepared, source);
    },
    async checkSources(sourceKind, sources) {
      requireOpen();
      if (!Array.isArray(sources) || sources.some(source => typeof source !== 'string')) {
        throw new TypeError('Expected immutable source texts');
      }
      if (typeof compiler.psCompilerPrepareSources !== 'function' ||
          typeof compiler.List?.cons !== 'function' || typeof compiler.List.nil !== 'function') {
        throw new Error('PSC2_CHECKED_API_MISSING: module preparation');
      }
      const source = sources.join('\n\n') + '\n';
      let values = compiler.List.nil();
      for (let index = sources.length - 1; index >= 0; index--) values = compiler.List.cons(sources[index], values);
      const prepared = unwrapCompilerResult(compiler.psCompilerPrepareSources(sourceKind, values), 'PREPARE');
      return checkPrepared(prepared, source);
    },
    emit(handle) {
      return emitTarget(handle, 'typescript');
    },
    emitTarget,
    emitTargetWithStages,
    publicApi,
    describe(handle) { checkedItem(handle); return handle; },
    certificationSubject(handle) {
      const item = checkedItem(handle);
      return Object.freeze({ source: item.source, admissions: item.admissions });
    },
    revoke(handle) { checkedItem(handle); modules.delete(handle); },
    close() { closed = true; },
  });
}
