import { createHash } from 'node:crypto';
import { createKernelCheckedSession } from './kernel-checked-session.mjs';
import { kernelContractV1 } from './kernel-contract.mjs';
import { checkedIrStageArtifacts } from './ir-artifact.mjs';
import { checkedTargetIrStageArtifacts } from './target-ir-artifact.mjs';
import { createJsGeneratedPositionMap } from './js-generated-positions.mjs';
import { createErasureDeclarationMap } from './erasure-declarations.mjs';
import { createDeclarationOriginGraph } from './declaration-origins.mjs';
import { publicApiArtifact } from './public-api-artifact.mjs';
import { createSpecializationInstanceMap } from './specialization-correspondence.mjs';
import { createCertifiedSourceSession } from './certified-source.mjs';

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
  const certified = createCertifiedSourceSession(session);
  async function check(sourceKind, source) {
    return certified.certify(await session.check(sourceKind, source));
  }
  async function checkSources(sourceKind, sources) {
    return certified.certify(await session.checkSources(sourceKind, sources));
  }
  function apiProduct(handle) {
    const text = session.publicApi(certified.checkedCore(handle));
    if (text === undefined) return undefined;
    if (Buffer.byteLength(text) > maxOutputBytes) throw new Error('PSC_CHECKED_OUTPUT_RESOURCE_EXHAUSTED');
    return { text, record: publicApiArtifact(text, { maxBytes: maxOutputBytes }) };
  }
  function originProduct(handle, api) {
    const captured = session.declarationOrigins(certified.checkedCore(handle));
    if (captured === undefined) return undefined;
    if (!api) throw new Error('PSC_CHECKED_ORIGIN_PUBLIC_API_REQUIRED');
    if (Buffer.byteLength(captured.text) > maxOutputBytes) throw new Error('PSC_CHECKED_OUTPUT_RESOURCE_EXHAUSTED');
    return { table: captured.text,
      ...createDeclarationOriginGraph({ table: captured.text, sources: captured.sources, publicApi: api.record, maxBytes: maxOutputBytes }) };
  }
  function emitOriginGraph(handle) {
    const product = originProduct(handle, apiProduct(handle));
    if (!product) throw new Error('PSC_CHECKED_ORIGINS_UNSUPPORTED');
    if (product.graph.bytes.byteLength + product.artifacts.reduce((sum, item) => sum + item.bytes.byteLength, 0) > maxOutputBytes)
      throw new Error('PSC_CHECKED_OUTPUT_RESOURCE_EXHAUSTED');
    return Object.freeze({ ...product, certifiedSource: certified.describe(handle),
      pscvCert: certified.certificate(handle).identity });
  }
  function emitPublicApiArtifact(handle) {
    const product = apiProduct(handle);
    if (!product) throw new Error('PSC_CHECKED_PUBLIC_API_UNSUPPORTED');
    return Object.freeze({
      contract: 'psc-checked-public-api-emission/1', payload: product.text,
      artifact: product.record.identity, pscvCert: certified.certificate(handle).identity,
      certifiedSource: certified.describe(handle),
      transformationAssurance: 'trusted-source-projection-target-correspondence-unproved',
    });
  }
  function emitArtifact(handle, target = 'typescript') {
    const certifiedSource = certified.describe(handle);
    const certificate = certified.certificate(handle);
    const checkedCoreHandle = certified.checkedCore(handle);
    const capability = session.describe(checkedCoreHandle);
    const emission = session.emitTargetWithStages(checkedCoreHandle, target);
    const api = apiProduct(handle);
    const origins = originProduct(handle, api);
    const raw = emission.output;
    const payload = target === 'wasm' ? byteList(raw, maxOutputBytes) : raw;
    const bytes = typeof payload === 'string' ? Buffer.from(payload, 'utf8') : payload;
    if (bytes.byteLength > maxOutputBytes) throw new Error('PSC_CHECKED_OUTPUT_RESOURCE_EXHAUSTED');
    const productByteLength = bytes.byteLength + Buffer.byteLength(emission.generatedPositions ?? '') + Buffer.byteLength(emission.erasureCorrespondence ?? '') + (api?.record.bytes.byteLength ?? 0) +
        (origins ? origins.graph.bytes.byteLength + Buffer.byteLength(origins.table) : 0) +
        Object.values(emission.stages ?? {}).reduce((sum, value) => sum + Buffer.byteLength(value), 0);
    if (productByteLength > maxOutputBytes) throw new Error('PSC_CHECKED_OUTPUT_RESOURCE_EXHAUSTED');
    const stages = checkedIrStageArtifacts(emission.stages, { maxBytes: maxOutputBytes });
    const targetStages = checkedTargetIrStageArtifacts(emission.stages, { maxBytes: maxOutputBytes });
    let erasureMap;
    if (emission.erasureCorrespondence !== undefined) {
      if (!api || !stages) throw new Error('PSC_CHECKED_ERASURE_SUBJECT_REQUIRED');
      erasureMap = createErasureDeclarationMap({ table: emission.erasureCorrespondence,
        publicApi: api.record, runtimeIr: stages.runtimeIr, maxBytes: maxOutputBytes }).map;
      if (productByteLength + erasureMap.bytes.byteLength > maxOutputBytes)
        throw new Error('PSC_CHECKED_OUTPUT_RESOURCE_EXHAUSTED');
    }
    if (stages && !stages.runtimeIr.bytes.equals(stages.verifiedIr.bytes)) throw new Error('PSC_CHECKED_VALIDATION_CHANGED_IR');
    const specializationProduct = stages?.specializedIr ?
      createSpecializationInstanceMap(stages.verifiedIr, stages.specializedIr, { maxBytes: maxOutputBytes }) : undefined;
    const specialization = specializationProduct?.result;
    let generatedPositionMap;
    if (emission.generatedPositions !== undefined) {
      if (target !== 'javascript' || !targetStages?.jsIr) throw new Error('PSC_CHECKED_GENERATED_POSITION_SUBJECT');
      generatedPositionMap = createJsGeneratedPositionMap({ table: emission.generatedPositions, javaScript: payload,
        jsIr: targetStages.jsIr, maxBytes: maxOutputBytes }).map;
    }
    if (productByteLength + (erasureMap?.bytes.byteLength ?? 0) + (specializationProduct?.map.bytes.byteLength ?? 0) +
        (generatedPositionMap?.bytes.byteLength ?? 0) > maxOutputBytes)
      throw new Error('PSC_CHECKED_OUTPUT_RESOURCE_EXHAUSTED');
    return Object.freeze({
      contract: 'psc-checked-emission/1', target, payload,
      artifact: Object.freeze({ algorithm: 'sha256', domain: 'target-bytes', schemaVersion: 1,
        digest: createHash('sha256').update(bytes).digest('hex'), byteLength: bytes.byteLength }),
      checkedCore: capability,
      pscvCert: certificate.identity,
      certifiedSource,
      ...(specialization ? { specializationCorrespondence: specialization,
        specializationInstances: specializationProduct.map.identity } : {}),
      ...(emission.stages ? { stages: emission.stages,
        stageArtifacts: Object.freeze(Object.fromEntries(
          [...Object.entries(stages ?? {}), ...Object.entries(targetStages ?? {})]
            .map(([key, value]) => [key, value.identity]))) } : {}),
      ...(generatedPositionMap ? { generatedPositions: emission.generatedPositions, generatedPositionMap: generatedPositionMap.identity } : {}),
      ...(erasureMap ? { erasureCorrespondence: emission.erasureCorrespondence, erasureMap: erasureMap.identity } : {}),
      ...(api ? { publicApi: api.text, publicApiArtifact: api.record.identity } : {}),
      ...(origins ? { declarationOrigins: origins.table, originGraph: origins.graph.identity } : {}),
      transformationAssurance: 'trusted-implementation-global-preservation-unproved',
    });
  }
  return Object.freeze({
    check, checkSources,
    emit: handle => emitArtifact(handle, 'typescript').payload,
    emitArtifact,
    emitPublicApiArtifact,
    emitOriginGraph,
    describe: certified.describe,
    certificate: certified.certificate,
    certifiedSourceArtifact: certified.certifiedSourceArtifact,
    revoke: certified.revoke,
    close: certified.close,
  });
}
