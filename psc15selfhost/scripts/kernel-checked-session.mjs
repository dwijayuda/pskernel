import { createHash, randomUUID } from 'node:crypto';
import { createPortableJsDeclarationRequest, directJsDeclarationProfile, directJsUniformDeclarationProfile } from './js-declarations.mjs';

import { closedJsRepresentationProfile, uniformJsRepresentationProfile } from './uniform-specialization.mjs';
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
  const javaScriptRepresentation = policy.javaScriptRepresentation ?? closedJsRepresentationProfile;
  if (![closedJsRepresentationProfile, uniformJsRepresentationProfile].includes(javaScriptRepresentation))
    throw new Error('PSC2_CHECKED_JAVASCRIPT_REPRESENTATION');
  const uniformJavaScript = javaScriptRepresentation === uniformJsRepresentationProfile;
  const targets = Object.freeze([...(policy.targets ?? ['typescript'])]);
  const wasmCanonicalRequest = policy.wasmCanonicalRequest;
  if (wasmCanonicalRequest !== undefined && (!targets.includes('wasm') || typeof wasmCanonicalRequest !== 'string' ||
      Buffer.byteLength(wasmCanonicalRequest) > 1048576)) throw new Error('PSC2_CHECKED_WASM_EXPORT_POLICY');
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
  function requireStableItem(handle, item) {
    if (checkedItem(handle) !== item) throw new Error('PSC2_CHECKED_UNCHECKED_MODULE');
    if (admissionsFrom(compiler, item.prepared) !== item.admissions)
      throw new Error('PSC2_CHECKED_PAYLOAD_CHANGED');
    checkedItem(handle);
  }
  function prepare(name, ...args) {
    const observed = name + 'WithOrigins';
    if (!(observed in compiler)) return { prepared: unwrapCompilerResult(compiler[name](...args), 'PREPARE') };
    if (typeof compiler[observed] !== 'function') throw new Error('PSC2_CHECKED_ORIGIN_PREPARE_API_SHAPE');
    const product = unwrapCompilerResult(compiler[observed](...args), 'PREPARE_ORIGINS');
    if (!product || typeof product !== 'object') throw new Error('PSC2_CHECKED_ORIGIN_PREPARE_RESULT_SHAPE');
    const prepared = Object.getOwnPropertyDescriptor(product, 'prepared');
    if (!prepared || !Object.hasOwn(prepared, 'value') || !prepared.value || typeof prepared.value !== 'object')
      throw new Error('PSC2_CHECKED_ORIGIN_PREPARE_RESULT_SHAPE');
    const origins = Object.getOwnPropertyDescriptor(product, 'origins');
    const originMalformed = !origins || !Object.hasOwn(origins, 'value') || typeof origins.value !== 'string';
    // Only prepared Core participates in logical acceptance. Malformed debug
    // data is retained as a lazy product error; no fallback/repreparation occurs.
    return { prepared: prepared.value, origins: originMalformed ? undefined : origins.value, originMalformed };
  }
  async function checkPrepared(prepared, source, origins, inputs, originMalformed = false) {
      requireOpen();
      const sourceInputs = Object.freeze([...inputs]);
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
        ...(wasmCanonicalRequest === undefined ? {} : { wasmExportRequestSha256: hash(wasmCanonicalRequest) }),
        ...(targets.includes('javascript') ? { javaScriptRepresentation } : {}),
        sourceSha256: hash(source),
        canonicalAdmissionsSha256: hash(admissions),
        kernelContract: kernelContractV1,
        provider: identity,
        providerSecurity: security,
      });
      modules.set(handle, { prepared, admissions, source, origins, originMalformed, inputs: sourceInputs });
      return handle;
  }
  function emitTargetWithStages(handle, target, { includeMetadata = true, includeErasureCorrespondence = includeMetadata } = {}) {
      if (typeof includeMetadata !== 'boolean' || typeof includeErasureCorrespondence !== 'boolean') throw new Error('PSC2_CHECKED_PRODUCT_SELECTION');
      const item = checkedItem(handle);
      if (!targets.includes(target)) throw new Error('PSC2_CHECKED_TARGET_FORBIDDEN');
      if (admissionsFrom(compiler, item.prepared) !== item.admissions) {
        throw new Error('PSC2_CHECKED_PAYLOAD_CHANGED');
      }
      const stageApi = target === 'typescript' ? 'psCompilerTypeScriptStagesFromPrepared' :
        target === 'javascript' ? (uniformJavaScript ? 'psCompilerUniformJavaScriptStagesFromPrepared' : 'psCompilerJavaScriptStagesFromPrepared') :
        target === 'wasm' ? (wasmCanonicalRequest === undefined ? 'psCompilerWasmStagesFromPrepared' : 'psCompilerWasmCanonicalStagesFromPrepared') :
        target === 'rust' ? 'psCompilerRustStagesFromPrepared' : undefined;
      if (stageApi && stageApi in compiler) {
        if (typeof compiler[stageApi] !== 'function') throw new Error('PSC2_CHECKED_EMIT_STAGES_API_SHAPE');
        if (target === 'wasm' && wasmCanonicalRequest === undefined && !compiler.psCompilerWasm32Target) throw new Error('PSC2_CHECKED_WASM_TARGET_MISSING');
        const product = unwrapCompilerResult(target === 'wasm' ?
          compiler[stageApi](wasmCanonicalRequest ?? compiler.psCompilerWasm32Target, item.prepared) : compiler[stageApi](item.prepared), 'EMIT_STAGES');
        const outputKey = target === 'typescript' ? 'typeScript' : target === 'wasm' ? 'wasm' : target === 'rust' ? 'rustSource' : 'javaScript';
        if (!product || typeof product !== 'object') throw new Error('PSC2_CHECKED_EMIT_STAGES_SHAPE');
        const specializationField = target === 'javascript' && uniformJavaScript ? 'uniformSpecializedIr' : 'specializedIr';
        const fields = [outputKey, 'runtimeIr', 'verifiedIr',
          ...((target === 'javascript' || target === 'wasm') ? [specializationField] : []),
          ...(target === 'javascript' ? ['jsIr'] : []), ...(target === 'wasm' ? ['wasmIr'] : []),
          ...(includeErasureCorrespondence ? ['erasureCorrespondence'] : []),
          ...(includeMetadata ? ['generatedPositions'] : []),
          ...(target === 'wasm' && wasmCanonicalRequest !== undefined ? ['interfaceJson', 'bindingJson'] : [])];
        const staged = {};
        for (const field of fields) {
          const descriptor = Object.getOwnPropertyDescriptor(product, field);
          if (!descriptor) continue;
          if (!Object.hasOwn(descriptor, 'value')) throw new Error('PSC2_CHECKED_EMIT_STAGES_SHAPE');
          staged[field] = descriptor.value;
        }
        // The service copies/validates the Wasm linked byte list under its byte
        // budget; avoid an unbounded deep-freeze traversal before that boundary.
        if (target !== 'wasm') freezeGraph(staged);
        if ((target === 'wasm' ? !staged?.[outputKey] || typeof staged[outputKey] !== 'object' : typeof staged?.[outputKey] !== 'string') ||
            typeof staged.runtimeIr !== 'string' || typeof staged.verifiedIr !== 'string' ||
            ((target === 'javascript' || target === 'wasm') && typeof staged[specializationField] !== 'string') ||
            (target === 'javascript' && typeof staged.jsIr !== 'string') ||
            (target === 'wasm' && typeof staged.wasmIr !== 'string')) {
          throw new Error('PSC2_CHECKED_EMIT_STAGES_SHAPE');
        }
        if (Object.hasOwn(staged, 'erasureCorrespondence') && typeof staged.erasureCorrespondence !== 'string')
          throw new Error('PSC2_CHECKED_ERASURE_CORRESPONDENCE_SHAPE');
        if (Object.hasOwn(staged, 'generatedPositions') &&
            (target !== 'javascript' || typeof staged.generatedPositions !== 'string'))
          throw new Error('PSC2_CHECKED_GENERATED_POSITIONS_SHAPE');
        if (target === 'wasm' && wasmCanonicalRequest !== undefined &&
            (typeof staged.interfaceJson !== 'string' || typeof staged.bindingJson !== 'string'))
          throw new Error('PSC2_CHECKED_CANONICAL_PRODUCTS_REQUIRED');
        requireStableItem(handle, item);
        return Object.freeze({ output: staged[outputKey],
          ...(target === 'wasm' && wasmCanonicalRequest !== undefined ? {
            wasmCanonical: Object.freeze({ interfaceJson: staged.interfaceJson, bindingJson: staged.bindingJson }) } : {}),
          ...(Object.hasOwn(staged, 'generatedPositions') ? { generatedPositions: staged.generatedPositions } : {}),
          ...(Object.hasOwn(staged, 'erasureCorrespondence') ? { erasureCorrespondence: staged.erasureCorrespondence } : {}),
          stages: Object.freeze({
            runtimeIr: staged.runtimeIr,
            verifiedIr: staged.verifiedIr,
            ...((target === 'javascript' || target === 'wasm') ? { [specializationField]: staged[specializationField] } : {}),
            ...(target === 'javascript' ? { jsIr: staged.jsIr } : {}),
            ...(target === 'wasm' ? { wasmIr: staged.wasmIr } : {}),
          }) });
      }
      if (target === 'javascript' && uniformJavaScript) throw new Error('PSC2_CHECKED_UNIFORM_STAGES_API_REQUIRED');
      if (target === 'wasm' && wasmCanonicalRequest !== undefined) throw new Error('PSC2_CHECKED_CANONICAL_STAGES_API_REQUIRED');
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
      requireStableItem(handle, item);
      return Object.freeze({ output });
  }
  // Legacy selected compiler modules can lack this product. Presence with a
  // malformed or failing API is never treated as an optional-product absence.
  function publicApi(handle) {
    const item = checkedItem(handle);
    if (admissionsFrom(compiler, item.prepared) !== item.admissions) throw new Error('PSC2_CHECKED_PAYLOAD_CHANGED');
    if (!('psCompilerPublicApiFromPrepared' in compiler)) {
      requireStableItem(handle, item);
      return undefined;
    }
    if (typeof compiler.psCompilerPublicApiFromPrepared !== 'function') throw new Error('PSC2_CHECKED_PUBLIC_API_API_SHAPE');
    const output = unwrapCompilerResult(compiler.psCompilerPublicApiFromPrepared(item.prepared), 'PUBLIC_API');
    if (typeof output !== 'string') throw new Error('PSC2_CHECKED_PUBLIC_API_RESULT_SHAPE');
    requireStableItem(handle, item);
    return output;
  }
  function javaScriptDeclarations(handle, bindings, maxBytes) {
    const item = checkedItem(handle);
    if (!targets.includes('javascript')) throw new Error('PSC2_CHECKED_TARGET_FORBIDDEN');
    const request = createPortableJsDeclarationRequest({
      profile: uniformJavaScript ? directJsUniformDeclarationProfile : directJsDeclarationProfile, bindings, maxBytes,
    });
    if (admissionsFrom(compiler, item.prepared) !== item.admissions) throw new Error('PSC2_CHECKED_PAYLOAD_CHANGED');
    if (typeof compiler.psCompilerJavaScriptDeclarationsFromPrepared !== 'function')
      throw new Error('PSC2_CHECKED_DECLARATIONS_API_REQUIRED');
    checkedItem(handle);
    const output = unwrapCompilerResult(
      compiler.psCompilerJavaScriptDeclarationsFromPrepared(request, item.prepared), 'DECLARATIONS');
    if (typeof output !== 'string') throw new Error('PSC2_CHECKED_DECLARATIONS_RESULT_SHAPE');
    if (Buffer.byteLength(output) > Math.min(maxBytes, 67108864)) throw new Error('PSC2_CHECKED_DECLARATIONS_OUTPUT_RESOURCE');
    requireStableItem(handle, item);
    return output;
  }
  function emitTarget(handle, target) { return emitTargetWithStages(handle, target, { includeMetadata: false }).output; }
  return Object.freeze({
    async check(sourceKind, source) {
      requireOpen();
      if (typeof source !== 'string') throw new TypeError('Expected immutable source text');
      const product = prepare('psCompilerPrepareSource', sourceKind, source);
      return checkPrepared(product.prepared, source, product.origins, [source], product.originMalformed);
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
      const product = prepare('psCompilerPrepareSources', sourceKind, values);
      return checkPrepared(product.prepared, source, product.origins, sources, product.originMalformed);
    },
    emit(handle) {
      return emitTarget(handle, 'typescript');
    },
    emitTarget,
    emitTargetWithStages,
    publicApi,
    javaScriptDeclarations,
    declarationOrigins(handle) {
      const item = checkedItem(handle);
      if (item.originMalformed) throw new Error('PSC2_CHECKED_ORIGIN_PREPARE_RESULT_SHAPE');
      return item.origins === undefined ? undefined : Object.freeze({ text: item.origins, sources: item.inputs });
    },
    describe(handle) { checkedItem(handle); return handle; },
    certificationSubject(handle) {
      const item = checkedItem(handle);
      return Object.freeze({ source: item.source, admissions: item.admissions });
    },
    revoke(handle) { checkedItem(handle); modules.delete(handle); },
    close() { closed = true; },
  });
}
