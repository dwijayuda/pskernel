import { captureWasmCanonicalSelection, createWasmCanonicalProducts } from './wasm-canonical-artifact.mjs';
import { mkdtemp, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { spawn } from 'node:child_process';
import { checkedSeedLimits, checkedSeedFrames, checkedSeedExhausted, checkSeedBytes } from './checked-seed-protocol.mjs';
import { decodeErasureDeclarations } from './erasure-declarations.mjs';
import { decodeDeclarationOrigins } from './declaration-origins.mjs';
import { artifactId } from './artifact-evidence.mjs';
import { checkedIrStageArtifacts, decodeIrArtifact } from './ir-artifact.mjs';
import { checkedTargetIrStageArtifacts, decodeJsIrArtifact, assertJsDeclarationInventory } from './target-ir-artifact.mjs';
import { verifySpecializationCorrespondence } from './specialization-correspondence.mjs';
import { closedJsRepresentationProfile, uniformJsRepresentationProfile, uniformSpecializationArtifact,
  verifyUniformSpecialization } from './uniform-specialization.mjs';
import { createDirectJsDeclarations, createPortableJsDeclarationRequest,
  directJsDeclarationProfile, directJsUniformDeclarationProfile } from './js-declarations.mjs';
import { decodePublicApi } from './public-api-artifact.mjs';
import { createPscvCertification } from './certified-source.mjs';

export const checkedSeedProductsProtocol = 'psc-checked-seed-products/1';
export const checkedSeedCanonicalProtocol = 'psc-checked-seed-products/2';
export const checkedSeedRustProtocol = 'psc-checked-seed-products/3';
export const checkedSeedRustSourceProfile = 'psc-rust-source/2021';

function selectSeedProducts(value) {
  const names = ['declarations', 'metadata', 'representation', 'sourceMap', 'target'];
  if (value && Object.hasOwn(value, 'wasmCanonicalSelection')) names.push('wasmCanonicalSelection');
  if (!value || typeof value !== 'object' || Array.isArray(value) ||
      Reflect.ownKeys(value).length !== names.length || Reflect.ownKeys(value).some(key => !names.includes(key)))
    throw new Error('PSC2_CHECKED_SEED_PRODUCT_SELECTION');
  const fields = {};
  for (const key of names) {
    const descriptor = Object.getOwnPropertyDescriptor(value, key);
    if (!descriptor || !Object.hasOwn(descriptor, 'value')) throw new Error('PSC2_CHECKED_SEED_PRODUCT_SELECTION');
    fields[key] = descriptor.value;
  }
  if (!['javascript', 'wasm', 'rust'].includes(fields.target) ||
      ['metadata', 'declarations', 'sourceMap'].some(key => typeof fields[key] !== 'boolean'))
    throw new Error('PSC2_CHECKED_SEED_PRODUCT_SELECTION');
  const profiles = fields.target === 'rust' ? [checkedSeedRustSourceProfile] :
    [closedJsRepresentationProfile, uniformJsRepresentationProfile];
  if (!profiles.includes(fields.representation) ||
      (fields.target !== 'javascript' && (fields.declarations || fields.sourceMap)) ||
      (fields.target === 'wasm' && fields.representation !== closedJsRepresentationProfile))
    throw new Error('PSC2_CHECKED_SEED_PRODUCT_SELECTION');
  const canonical = Object.hasOwn(fields, 'wasmCanonicalSelection');
  if (canonical && fields.target !== 'wasm') throw new Error('PSC2_CHECKED_SEED_PRODUCT_SELECTION');
  const wasmPolicy = canonical ? captureWasmCanonicalSelection(fields.wasmCanonicalSelection) : undefined;
  delete fields.wasmCanonicalSelection;
  const protocol = fields.target === 'rust' ? checkedSeedRustProtocol : canonical ? checkedSeedCanonicalProtocol : checkedSeedProductsProtocol;
  const wire = JSON.stringify([protocol, fields.target, fields.representation,
    fields.metadata, fields.declarations, fields.sourceMap, ...(wasmPolicy ? [wasmPolicy.wire] : [])]);
  if (Buffer.byteLength(wire) > (canonical ? 2101248 : 4096)) throw new Error('PSC2_CHECKED_SEED_PRODUCT_SELECTION');
  return Object.freeze({ ...fields, protocol, wire, wasmPolicy });
}

function seedSelectedProduct(completed, selected, limits, observation, sources) {
  const uniform = selected.representation === uniformJsRepresentationProfile;
  const metadata = selected.metadata || selected.sourceMap, api = metadata || selected.declarations;
  const outputKey = selected.target === 'javascript' ? 'javaScript' : selected.target === 'rust' ? 'rustSource' : 'wasm';
  const stageKeys = ['runtimeIr', 'verifiedIr', ...(selected.target === 'rust' ? [] :
    [uniform ? 'uniformSpecializedIr' : 'specializedIr', selected.target === 'javascript' ? 'jsIr' : 'wasmIr'])];
  const textKeys = [...stageKeys, ...(selected.wasmPolicy ? ['interfaceJson', 'bindingJson'] : []), ...(api ? ['publicApi', 'erasureCorrespondence'] : []),
    ...(metadata ? ['declarationOrigins', ...(selected.target === 'javascript' ? ['generatedPositions'] : [])] : [])];
  const keys = ['phase', 'protocol', 'target', 'representation', outputKey, ...textKeys].sort();
  if (!completed || Object.keys(completed).sort().join(',') !== keys.join(',') ||
      completed.phase !== 'emitted' || completed.protocol !== selected.protocol ||
      completed.target !== selected.target || completed.representation !== selected.representation ||
      textKeys.some(key => typeof completed[key] !== 'string'))
    throw new Error('PSC2_CHECKED_SEED_PRODUCT_RESULT');
  if (selected.target === 'wasm' ?
      !Array.isArray(completed.wasm) || completed.wasm.some(byte => !Number.isInteger(byte) || byte < 0 || byte > 255) :
      typeof completed[outputKey] !== 'string')
    throw new Error('PSC2_CHECKED_SEED_PRODUCT_BYTES');
  observation.generatedBytes = textKeys.reduce((sum, key) => sum + Buffer.byteLength(completed[key]), 0) +
    (selected.target === 'wasm' ? completed.wasm.length : Buffer.byteLength(completed[outputKey]));
  if (observation.generatedBytes > limits.generatedBytes)
    throw checkedSeedExhausted('generatedBytes', limits.generatedBytes, observation.generatedBytes);
  const payload = selected.target === 'wasm' ? Uint8Array.from(completed.wasm) : completed[outputKey];
  const stages = Object.freeze(Object.fromEntries(stageKeys.map(key => [key, completed[key]])));
  const bound = { maxBytes: limits.generatedBytes };
  const ir = checkedIrStageArtifacts(stages, bound), target = checkedTargetIrStageArtifacts(stages, bound);
  if (!ir.runtimeIr.bytes.equals(ir.verifiedIr.bytes)) throw new Error('PSC2_CHECKED_SEED_VALIDATION_CHANGED_IR');
  const selectedIr = uniform ? uniformSpecializationArtifact(stages.uniformSpecializedIr, bound) : ir.specializedIr;
  if (uniform) {
    verifyUniformSpecialization(ir.verifiedIr, selectedIr, bound);
    assertJsDeclarationInventory(decodeIrArtifact(ir.verifiedIr.bytes, bound), decodeJsIrArtifact(target.jsIr.bytes, bound));
  } else if (selected.target !== 'rust') verifySpecializationCorrespondence(ir.verifiedIr, selectedIr, bound);
  if (api) {
    decodePublicApi(Buffer.from(completed.publicApi), bound);
    decodeErasureDeclarations(Buffer.from(completed.erasureCorrespondence), {
      publicApi: Buffer.from(completed.publicApi), runtimeIr: ir.runtimeIr.bytes, ...bound });
  }
  if (metadata) decodeDeclarationOrigins(Buffer.from(completed.declarationOrigins), {
    sources, publicApi: Buffer.from(completed.publicApi), ...bound });
  const wasmCanonical = selected.wasmPolicy ? createWasmCanonicalProducts({
    selection: selected.wasmPolicy.selection, specializedIr: ir.specializedIr, targetIr: target.wasmIr,
    binary: { bytes: payload, identity: artifactId(payload, 'wasm-binary', 'webassembly-core/1') },
    interfaceJson: completed.interfaceJson, bindingJson: completed.bindingJson,
  }, bound) : undefined;
  let directDeclarations, declarationRequest;
  if (selected.declarations) {
    const record = (text, domain, contract) => {
      const bytes = Buffer.from(text); return { bytes, identity: artifactId(bytes, domain, contract) };
    };
    const profile = uniform ? directJsUniformDeclarationProfile : directJsDeclarationProfile;
    directDeclarations = createDirectJsDeclarations({ profile, maxBytes: limits.generatedBytes,
      maxTotalBytes: limits.generatedBytes, subjects: {
        publicApi: record(completed.publicApi, 'public-api', 'psc-public-api-ir/1'),
        erasureTable: record(completed.erasureCorrespondence, 'erasure-table', 'psc-erasure-declarations/1'),
        runtimeIr: ir.runtimeIr, verifiedIr: ir.verifiedIr,
        ...(uniform ? { uniformSpecializedIr: selectedIr } : { specializedIr: selectedIr }),
        jsIr: target.jsIr, javaScript: record(payload, 'javascript-output', 'psc-direct-javascript/es2022'),
      } });
    declarationRequest = createPortableJsDeclarationRequest({ profile, maxBytes: limits.generatedBytes,
      bindings: JSON.parse(directDeclarations.binding.bytes).bindings });
  }
  return { product: Object.freeze({ target: selected.target, payload, stages,
    protocol: selected.protocol, ...(selected.target === 'javascript' ? { javaScriptRepresentation: selected.representation } : {}),
    ...(api ? { publicApi: completed.publicApi, erasureCorrespondence: completed.erasureCorrespondence } : {}),
    ...(metadata ? { declarationOrigins: completed.declarationOrigins,
      ...(selected.target === 'javascript' ? { generatedPositions: completed.generatedPositions } : {}) } : {}),
    ...(directDeclarations ? { directDeclarations } : {}),
    ...(wasmCanonical ? { wasmCanonical } : {}),
  }), declarationRequest };
}

function withTimeout(promise, timeoutMs, child, label) {
  let timer;
  const timeout = new Promise((_, reject) => {
    timer = setTimeout(() => {
      child.kill('SIGKILL');
      reject(Object.assign(checkedSeedExhausted('phaseTimeMs', timeoutMs), { phase: label }));
    }, timeoutMs);
  });
  return Promise.race([promise, timeout]).finally(() => clearTimeout(timer));
}

export async function runCheckedSeedSession({
  binaryPath,
  sourceKind,
  source,
  sources,
  checkAdmissions,
  emit,
  timeoutMs = 300000,
  resourceLimits,
  certificationContext,
  productRequest,
}) {
  const limits = checkedSeedLimits(resourceLimits);
  const selected = productRequest === undefined ? undefined : selectSeedProducts(productRequest);
  if (selected && certificationContext && (certificationContext.targets?.length !== 1 ||
      certificationContext.targets[0] !== selected.target)) throw new Error('PSC2_CHECKED_SEED_PRODUCT_CERT_TARGET');
  if (!['lean', 'ps'].includes(sourceKind)) throw new Error('PSC2_CHECKED_SEED_SOURCE_KIND');
  if (typeof source !== 'string') throw new TypeError('Expected immutable source text');
  if (sources !== undefined && !Array.isArray(sources)) throw new Error('PSC2_CHECKED_SEED_SOURCE_PARTITION');
  const observation = { sourceBytes: checkSeedBytes(source, 'sourceBytes', limits),
    sourceCount: sources === undefined ? 1 : sources.length, snapshotBytes: 0,
    stdoutBytes: 0, stderrBytes: 0, frames: 0, largestFrameBytes: 0, admissionsBytes: 0, generatedBytes: 0 };
  if (!Number.isSafeInteger(observation.sourceCount) || observation.sourceCount > limits.sourceCount)
    throw checkedSeedExhausted('sourceCount', limits.sourceCount, observation.sourceCount);
  if (sources !== undefined && (!Array.isArray(sources) || sources.some(value => typeof value !== 'string') ||
      sources.join('\n\n') + '\n' !== source)) throw new Error('PSC2_CHECKED_SEED_SOURCE_PARTITION');
  if (typeof checkAdmissions !== 'function') throw new TypeError('Expected kernel checker');
  if (!Number.isSafeInteger(timeoutMs) || timeoutMs <= 0 || timeoutMs > 2147483647) throw new TypeError('timeoutMs must be a positive timer interval');

  const inputSources = Object.freeze(sources === undefined ? [source] : [...sources]);
  const snapshot = sources === undefined ? source : JSON.stringify(inputSources);
  observation.snapshotBytes = checkSeedBytes(snapshot, 'snapshotBytes', limits);

  const directory = await mkdtemp(path.join(tmpdir(), 'psc2-checked-seed-'));
  const sourceFile = path.join(directory, sources === undefined ? `snapshot.${sourceKind === 'ps' ? 'ps' : 'lean'}` : 'snapshot.json');
  let child, closed, didClose = false;
  const stderr = [];
  try {
    await writeFile(sourceFile, snapshot, 'utf8');
    child = spawn(path.resolve(binaryPath), [`--session-${selected ? (selected.target === 'rust' ? 'products-v3-' : selected.wasmPolicy ? 'products-v2-' : 'products-') : ''}${sources === undefined ? '' : 'modules-'}${sourceKind}`, sourceFile], {
      stdio: ['pipe', 'pipe', 'pipe'],
      windowsHide: true,
    });
    let rejectFailure, firstFailure;
    const failure = new Promise((_, reject) => { rejectFailure = reject; });
    failure.catch(() => {}); // Failure may arrive between awaited phases.
    const fail = error => {
      if (firstFailure) return;
      firstFailure = error; child.kill('SIGKILL'); rejectFailure(error);
    };
    child.stderr.on('data', chunk => {
      if (firstFailure) return;
      observation.stderrBytes += chunk.length;
      if (observation.stderrBytes > limits.stderrBytes)
        fail(checkedSeedExhausted('stderrBytes', limits.stderrBytes, observation.stderrBytes));
      else stderr.push(chunk);
    });
    child.stdin.on('error', fail);
    child.stderr.on('error', fail);
    child.once('error', fail);
    closed = new Promise(resolve => {
      child.once('close', (code, signal) => { didClose = true; resolve({ code, signal }); });
    });
    const iterator = checkedSeedFrames(child.stdout, limits, observation, selected?.declarations && emit ? 3 : 2);
    const phase = (promise, label) => withTimeout(Promise.race([promise, failure]), timeoutMs, child, label);
    async function nextFrame(label) {
      const next = await phase(iterator.next(), label);
      if (next.done) throw new Error('PSC2_CHECKED_SEED_SESSION_EOF: ' + label);
      return next.value;
    }

    const prepared = await nextFrame('prepared');
    if (prepared?.phase !== 'prepared' || typeof prepared.admissions !== 'string') {
      throw new Error('PSC2_CHECKED_SEED_SESSION_PREPARED_RESULT');
    }

    if (selected && (prepared.protocol !== selected.protocol ||
        Object.keys(prepared).sort().join(',') !== 'admissions,phase,protocol'))
      throw new Error('PSC2_CHECKED_SEED_PRODUCT_PROTOCOL');

    observation.admissionsBytes = checkSeedBytes(prepared.admissions, 'admissionsBytes', limits);
    const kernelResult = await phase(Promise.resolve().then(() => checkAdmissions(prepared.admissions)), 'kernel-check');
    if (kernelResult?.accepted !== true) {
      throw new Error(`PSC2_KERNEL_REJECTED: ${kernelResult?.errorKind ?? 'kernel-rejection'}`);
    }

    let certification;
    if (certificationContext !== undefined) {
      const expected = certificationContext.provider;
      if (!expected || typeof expected !== 'object') throw new Error('PSC2_CHECKED_SEED_CERT_PROVIDER');
      for (const [field, value] of Object.entries(expected)) {
        if (kernelResult?.[field] !== value) throw new Error('PSC2_CHECKED_SEED_PROVIDER_IDENTITY: ' + field);
      }
      certification = createPscvCertification({
        source,
        admissions: prepared.admissions,
        semanticProfile: expected.profile,
        kernelContract: certificationContext.kernelContract,
        provider: expected,
        providerSecurity: certificationContext.providerSecurity,
        assumptionPolicy: certificationContext.assumptionPolicy,
        resourcePolicy: certificationContext.resourcePolicy,
        targets: certificationContext.targets,
        executionBoundary: certificationContext.executionBoundary,
      });
    }

    const command = emit ? (selected?.wire ?? 'emit') : 'checked';
    if (selected?.declarations && emit) child.stdin.write(command + '\n');
    else child.stdin.end(command + '\n');
    const completed = await nextFrame(emit ? 'emitted' : 'checked');
    let directProduct;
    if (emit && selected) {
      const captured = seedSelectedProduct(completed, selected, limits, observation, inputSources);
      directProduct = captured.product;
      if (captured.declarationRequest !== undefined) {
        child.stdin.end(captured.declarationRequest + '\n');
        const written = await nextFrame('declarations');
        if (!written || Object.keys(written).sort().join(',') !== 'declarations,phase,protocol' ||
            written.phase !== 'declarations' || written.protocol !== selected.protocol ||
            typeof written.declarations !== 'string') throw new Error('PSC2_CHECKED_SEED_DECLARATION_RESULT');
        const writerBytes = Buffer.byteLength(written.declarations);
        if (writerBytes > Math.min(limits.generatedBytes, 67108864))
          throw new Error('PSC2_CHECKED_DECLARATIONS_OUTPUT_RESOURCE');
        observation.generatedBytes += writerBytes;
        if (observation.generatedBytes > limits.generatedBytes)
          throw checkedSeedExhausted('generatedBytes', limits.generatedBytes, observation.generatedBytes);
        if (!Buffer.from(written.declarations).equals(directProduct.directDeclarations.declarations.bytes))
          throw new Error('PSC_CHECKED_DECLARATION_PRODUCER_MISMATCH');
        directProduct = Object.freeze({ ...directProduct, declarationProduction: Object.freeze({
          producer: 'portable-source-signature-writer/1', hostBytesCompared: true,
          globalPreservationProved: false, authority: 'descriptive-product-only',
        }) });
      }
    } else if (emit) {
      if (completed?.phase !== 'emitted' || typeof completed.typescript !== 'string') {
        throw new Error('PSC2_CHECKED_SEED_SESSION_EMIT_RESULT');
      }
      if ((completed.runtimeIr !== undefined || completed.verifiedIr !== undefined) &&
          (typeof completed.runtimeIr !== 'string' || typeof completed.verifiedIr !== 'string')) {
        throw new Error('PSC2_CHECKED_SEED_SESSION_STAGES_RESULT');
      }
      if (Object.hasOwn(completed, 'publicApi') && typeof completed.publicApi !== 'string')
        throw new Error('PSC2_CHECKED_SEED_SESSION_PUBLIC_API_RESULT');
      if (Object.hasOwn(completed, 'declarationOrigins') &&
          (typeof completed.declarationOrigins !== 'string' || typeof completed.publicApi !== 'string'))
        throw new Error('PSC2_CHECKED_SEED_SESSION_ORIGINS_RESULT');
      if (Object.hasOwn(completed, 'erasureCorrespondence') &&
          (typeof completed.erasureCorrespondence !== 'string' || typeof completed.publicApi !== 'string' ||
           typeof completed.runtimeIr !== 'string')) throw new Error('PSC2_CHECKED_SEED_SESSION_ERASURE_RESULT');
      observation.generatedBytes = Buffer.byteLength(completed.erasureCorrespondence ?? '') + Buffer.byteLength(completed.declarationOrigins ?? '') + Buffer.byteLength(completed.publicApi ?? '') + Buffer.byteLength(completed.typescript) +
        Buffer.byteLength(completed.runtimeIr ?? '') + Buffer.byteLength(completed.verifiedIr ?? '');
      if (observation.generatedBytes > limits.generatedBytes)
        throw checkedSeedExhausted('generatedBytes', limits.generatedBytes, observation.generatedBytes);
      if (completed.erasureCorrespondence !== undefined) decodeErasureDeclarations(Buffer.from(completed.erasureCorrespondence),
        { publicApi: Buffer.from(completed.publicApi), runtimeIr: Buffer.from(completed.runtimeIr), maxBytes: limits.generatedBytes });
      if (completed.declarationOrigins !== undefined) decodeDeclarationOrigins(Buffer.from(completed.declarationOrigins),
        { sources: inputSources, publicApi: Buffer.from(completed.publicApi), maxBytes: limits.generatedBytes });
      if (completed.publicApi !== undefined) decodePublicApi(Buffer.from(completed.publicApi), { maxBytes: limits.generatedBytes });
    } else if (completed?.phase !== 'checked' || (selected &&
        (completed.protocol !== selected.protocol || Object.keys(completed).sort().join(',') !== 'phase,protocol'))) {
      throw new Error('PSC2_CHECKED_SEED_SESSION_CHECK_RESULT');
    }

    if (!(await phase(iterator.next(), 'end-of-stream')).done) throw new Error('PSC2_CHECKED_SEED_SESSION_EXTRA_FRAME');
    const status = await phase(closed, 'close');
    if (status.code !== 0) {
      throw new Error(`PSC2_CHECKED_SEED_SESSION_FAILED: ${status.signal || status.code}`);
    }
    return Object.freeze({
      admissions: prepared.admissions,
      ...(selected ? { productProtocol: selected.protocol } : {}),
      resourceObservation: Object.freeze({ contract: 'psc-checked-seed-resources/1',
        limits: Object.freeze({ ...limits, phaseTimeMs: timeoutMs }), observed: Object.freeze({ ...observation }),
        unobserved: Object.freeze(['compiler-internal-work', 'cpu-time', 'peak-memory', 'descendants', 'host-stack']) }),
      ...(emit && !selected ? { typeScript: completed.typescript } : {}),
      ...(directProduct ? { directProduct } : {}),
      ...(emit && completed.publicApi !== undefined ? { publicApi: completed.publicApi } : {}),
      ...(emit && completed.erasureCorrespondence !== undefined ? { erasureCorrespondence: completed.erasureCorrespondence } : {}),
      ...(emit && completed.declarationOrigins !== undefined ? { declarationOrigins: completed.declarationOrigins } : {}),
      ...(emit && !selected && completed.runtimeIr !== undefined
        ? { stages: Object.freeze({ runtimeIr: completed.runtimeIr, verifiedIr: completed.verifiedIr }) } : {}),
      ...(certification ? {
        pscvCertificate: certification.certificate,
        certifiedSourceArtifact: certification.certifiedSource,
      } : {}),
    });
  } catch (error) {
    if (child && child.exitCode === null) child.kill('SIGKILL');
    const diagnostic = Buffer.concat(stderr).toString('utf8').trim().slice(0, 2000);
    if (diagnostic && !String(error.message).includes(diagnostic)) {
      error.message += ` | seed: ${diagnostic}`;
    }
    throw error;
  } finally {
    if (child && !didClose) {
      child.kill('SIGKILL');
      let timer;
      const confirmed = await Promise.race([closed.then(() => true),
        new Promise(resolve => { timer = setTimeout(() => resolve(false), limits.terminationGraceMs); })]);
      clearTimeout(timer);
      if (!confirmed) throw Object.assign(new Error('PSC2_CHECKED_SEED_TERMINATION_UNCONFIRMED'),
        { kind: 'infrastructureUnavailable' });
    }
    await rm(directory, { recursive: true, force: true });
  }
}
