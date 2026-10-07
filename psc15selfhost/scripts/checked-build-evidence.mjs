import { artifactId, artifactKey, canonicalArtifact, canonicalBytes, passDefinition, recordPassExecution, verifyArtifact } from './artifact-evidence.mjs';
import { createHash } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { checkedIrStageArtifacts } from './ir-artifact.mjs';
import { checkedTargetIrStageArtifacts } from './target-ir-artifact.mjs';
import { createJsGeneratedPositionMap } from './js-generated-positions.mjs';
import { createErasureDeclarationMap } from './erasure-declarations.mjs';
import { createDeclarationOriginGraph } from './declaration-origins.mjs';
import { createSourcePreparationArtifacts } from './source-preparation-origins.mjs';
import { publicApiArtifact } from './public-api-artifact.mjs';
import { runtimeInterfaceArtifact } from './runtime-interface-artifact.mjs';
import { createSpecializationInstanceMap } from './specialization-correspondence.mjs';
import { jsAbiArtifactsFromVerifiedIr } from './js-abi-artifact.mjs';
import { verifyWasmCanonicalProjection, verifyWasmCanonicalBinary } from './wasm-canonical-artifact.mjs';

export async function readCheckedBuildHostSources() {
  const root = path.dirname(fileURLToPath(import.meta.url));
  const pending = ['checked-build.mjs'], seen = new Set(), sources = [];
  while (pending.length) {
    const relative = pending.pop();
    if (seen.has(relative)) continue;
    if (seen.size >= 256) throw new Error('PSC_BUILD_GRAPH_HOST_CLOSURE_LIMIT');
    const absolute = path.resolve(root, relative), local = path.relative(root, absolute);
    if (local === '..' || local.startsWith('..' + path.sep) || path.isAbsolute(local)) throw new Error('PSC_BUILD_GRAPH_HOST_SOURCE_ESCAPE');
    seen.add(relative);
    const bytes = await readFile(absolute);
    if (bytes.length > 16 * 1024 * 1024) throw new Error('PSC_BUILD_GRAPH_HOST_SOURCE_LIMIT');
    sources.push({ path: 'scripts/' + local.split(path.sep).join('/'), bytes });
    const source = bytes.toString('utf8');
    for (const match of source.matchAll(/(?:\bfrom\s*|\bimport\s*)['"](\.[^'"]+\.mjs)['"]/gu)) {
      pending.push(path.relative(root, path.resolve(path.dirname(absolute), match[1])));
    }
  }
  return sources.sort((left, right) => left.path < right.path ? -1 : left.path > right.path ? 1 : 0);
}

/** Actual observed build edges. Composite edges remain named as such: hidden IR
 * stages are not replaced by invented fingerprints or preservation evidence.
 * The checked builder packages every listed byte snapshot in its build archive.
 */
export function createCheckedBuildGraph({ sourceKind, sources, admissions, typeScript,
  javaScript, directJavaScript, directWasm, declarations, sourceMap, compilerBytes, compilerKind, typeScriptCompilerBytes,
  provider, providerSecurity, kernelContract, hostSources, runtime, outputStem, irStages, typeScriptToolInputs, providerToolInputs = [], sourceResources, seedResources,
  pscvCertificate, certifiedSourceArtifact, jsAbiPolicy, wasmCanonical, publicApi, sourceOrigins, declarationOrigins, erasureCorrespondence, generatedPositions }) {
  const artifacts = new Map(), entries = [], executions = [];
  const directBackend = directJavaScript !== undefined ? 'javascript' : directWasm !== undefined ? 'wasm' : undefined;
  if ((directJavaScript !== undefined && directWasm !== undefined) ||
      (directBackend && [typeScript, javaScript, declarations, sourceMap].some(value => value !== undefined)))
    throw new Error('PSC_BUILD_GRAPH_MIXED_BACKEND_PATHS');
  if (directWasm !== undefined && !(directWasm instanceof Uint8Array)) throw new Error('PSC_BUILD_GRAPH_WASM_BYTES');
  if (wasmCanonical !== undefined && directBackend !== 'wasm') throw new Error('PSC_BUILD_GRAPH_CANONICAL_TARGET');
  let canonicalAdapter;
  let toolInputs;
  let runtimeInterface;
  let executableArtifact;
  let specializationInstances;
  let generatedPositionMap;
  if (generatedPositions !== undefined && directBackend !== 'javascript') throw new Error('PSC_BUILD_GRAPH_GENERATED_POSITION_TARGET');
  let jsAbiPlan;
  let jsAbiPolicyArtifact;
  function add(item, source, inline = false) {
    const key = artifactKey(item.identity);
    if (!artifacts.has(key)) {
      artifacts.set(key, item.bytes);
      entries.push({ identity: item.identity, source,
        ...(inline ? { canonicalValue: JSON.parse(item.bytes) } : {}) });
    }
    return item;
  }
  function bytes(value, domain, contract, source) {
    const content = typeof value === 'string' ? Buffer.from(value) : value;
    return add({ bytes: content, identity: artifactId(content, domain, contract) }, source);
  }
  function json(value, domain, contract, source, inline = true) {
    return add(canonicalArtifact(value, domain, contract), source, inline);
  }
  function bindToolInputs(snapshot, contract, domain, role) {
    const { details, files } = snapshot;
    if (details.contract !== contract || details.fullInputClosureEstablished !== false ||
        !Array.isArray(files) || !Array.isArray(details.files) || files.length !== details.files.length || !files.length)
      throw new Error('PSC_BUILD_GRAPH_TOOL_INPUTS_SCHEMA');
    const capturedFiles = files.map((item, index) => {
      const expected = details.files[index];
      if (item.path !== expected.path || !(item.bytes instanceof Uint8Array) ||
          item.bytes.byteLength !== expected.byteLength || createHash('sha256').update(item.bytes).digest('hex') !== expected.sha256 ||
          (index > 0 && files[index - 1].path >= item.path)) throw new Error('PSC_BUILD_GRAPH_TOOL_INPUTS_BYTES');
      return { path: item.path, artifact: bytes(item.bytes, domain, 'psc-tool-file-bytes/1',
        { kind: 'archive-required', role, path: item.path }).identity };
    });
    return json({ ...details, files: capturedFiles,
      stabilityObservation: contract === 'psc-typescript-tool-inputs/1' ? 'same-inventory-and-bytes-before-and-after-execution' :
        'same-explicit-file-bytes-before-and-after-checking' }, 'tool-inputs', contract, { kind: 'inline' });
  }
  const providerInputs = providerToolInputs.map(snapshot =>
    bindToolInputs(snapshot, 'psc-checked-provider-inputs/1', 'provider-tool-file', 'selected-provider-file'));
  const compiler = bytes(compilerBytes, 'compiler', 'psc-compiler-module/1', { kind: 'archive-required', role: compilerKind });
  const hosts = hostSources.map(item => bytes(item.bytes, 'host-source', 'psc-host-source/1',
    { kind: 'repository-file', path: item.path }));
  const implementation = json({ compiler: compiler.identity, hosts: hosts.map(item => item.identity), runtime },
    'implementation', 'psc-hosted-compiler-implementation/1', { kind: 'inline' });
  const source = json({ sourceKind, sources }, 'source-snapshot', 'psc-source-snapshot/1',
    { kind: 'archive-required', role: 'ordered-preparation-inputs' }, false);
  const core = bytes(admissions, 'canonical-admissions', 'proofscript-checked-admissions/2',
    { kind: 'output-file', suffix: '.admissions.json' });
  const security = json({ provider, providerSecurity, kernelContract,
    ...(providerInputs.length ? { providerInputs: providerInputs.map(item => item.identity) } : {}) }, 'acceptance-context',
    'psc-acceptance-context/1', { kind: 'inline' });
  const semanticIdentity = { providerProfile: provider.profile, kernelContract, runtimeSemantics: 'psc-runtime-semantics/1' };
  const baseDependencies = [compiler.identity, ...hosts.map(item => item.identity), security.identity,
    ...providerInputs.map(item => item.identity)];
  const assumptions = ['trusted-host-composition', 'selected-compiler-module-closure', 'selected-host-runtime',
    'selected-kernel-invocation'];
  function execute(id, input, outputs, impl, relation, parameters, dependencies, extraAssumptions = [], validation, effectPolicy = {}) {
    const product = (item, index) => ({ role: 'artifact-' + index, domain: item.identity.domain, contract: item.identity.contract });
    const signature = {
      schemaVersion: 2, contract: 'psc-pass-definition/2',
      inputArtifacts: [product(input, 0)], outputArtifacts: outputs.map(product),
      effects: { supportedProfiles: [provider.profile], requiresAnalyses: [], preservesAnalyses: [], invalidatesAnalyses: ['*'],
        preservesInterfaces: [], invalidatesInterfaces: ['*'], preservesFingerprints: [], invalidatesFingerprints: ['*'],
        originPolicy: 'drop-with-reason', originReason: 'OriginGraph is not yet propagated through this projection.',
        authorityEffect: 'requiresRevalidation', assuranceClass: 'trustedImplementation', ...effectPolicy },
    };
    const definition = add(passDefinition({ passId: id, version: 1, ...signature, semanticRelationId: relation,
      resourceContractId: 'psc-compilation-resource/1', determinismClass: 'declared-inputs-with-trusted-host',
      totalityClass: 'partial-host-bounded', implementationId: impl.identity,
      validatorId: validation?.contract ?? null, theoremIds: [], assumptionIds: [...assumptions, ...extraAssumptions] }), { kind: 'inline' }, true);
    const record = recordPassExecution({ definition, inputs: [input], outputs, parameters,
      semanticIdentity, dependencies, resourcePolicy: { contract: 'psc-checked-host-resource/1',
        enforcement: 'existing-stage-specific-limits', completeBudgetCoverage: false,
        ...(validation ? { correspondence: validation.resourcePolicy } : {}),
        ...(id === 'psc-prepare-and-check/1' && sourceResources ? { sourceReading: sourceResources.limits } : {}),
        ...(id !== 'typescript-to-es2022/1' && id !== 'psc-project-runtime-interface/1' && seedResources ? { nativeSession: seedResources.limits } : {}) },
      resourceObservation: { hostObserved: true, inputBytes: input.bytes.byteLength,
        ...(validation ? { correspondence: validation.observed } : {}),
        outputBytes: outputs.reduce((sum, output) => sum + output.bytes.byteLength, 0),
        ...(id === 'psc-prepare-and-check/1' && sourceResources ? { sourceReading: sourceResources.observed } : {}),
        ...(id !== 'typescript-to-es2022/1' && id !== 'psc-project-runtime-interface/1' && seedResources ? { nativeSession: seedResources.observed,
          nativeSessionScope: 'whole-shared-session-not-per-pass-attribution' } : {}),
        unobserved: ['cpu', 'peak-memory', 'kernel-steps', 'ir-nodes'] },
      diagnostics: ['Global preservation is unproved; these records describe the executed composite edges.'], evidence: [] });
    add(record.action, { kind: 'inline' }, true); add(record, { kind: 'inline' }, true);
    executions.push(record.identity);
  }
  let preparationOrigins;
  if (sourceOrigins !== undefined) {
    const projection = createSourcePreparationArtifacts(sourceOrigins, source);
    for (const item of projection.artifacts) add(item, { kind: 'archive-required', role: 'source-preparation-text' });
    preparationOrigins = add(projection.map, { kind: 'output-file', suffix: '.source-origins.json' });
    execute('psc-source-preparation-origins/1', source, [preparationOrigins], implementation,
      'psc-source-preparation-origin-projection/1',
      { coordinateUnit: 'utf8-byte', observedStages: ['exact-source-preparation-origin-capture'],
        debugOnly: true, semanticPreservationProved: false },
      [...baseDependencies, ...projection.artifacts.map(item => item.identity)], [], undefined,
      { originPolicy: 'synthesize', authorityEffect: 'none',
        originReason: 'Record exact copied UTF-8 ranges across import removal, newline normalization and trimming; Core/IR origins remain absent.' });
  }
  execute('psc-prepare-and-check/1', source, [core], implementation, 'psc-source-checked-admissions/1',
    { sourceKind, sourceCount: sources.length, observedStages: ['prepare', 'kernel-check'] }, baseDependencies,
    ['trusted-frontend-source-interpretation']);
  let certifiedInput = core;
  let certification;
  if ((pscvCertificate === undefined) !== (certifiedSourceArtifact === undefined))
    throw new Error('PSC_BUILD_GRAPH_CERTIFICATION_PAIR');
  if (pscvCertificate !== undefined) {
    verifyArtifact(pscvCertificate.bytes, pscvCertificate.identity);
    verifyArtifact(certifiedSourceArtifact.bytes, certifiedSourceArtifact.identity);
    if (pscvCertificate.identity.contract !== 'pscv-cert/1' ||
        certifiedSourceArtifact.identity.contract !== 'psc-certified-source/1')
      throw new Error('PSC_BUILD_GRAPH_CERTIFICATION_CONTRACT');
    const certificateValue = JSON.parse(pscvCertificate.bytes);
    const certifiedValue = JSON.parse(certifiedSourceArtifact.bytes);
    if (certificateValue.contract !== 'pscv-cert/1' || certifiedValue.contract !== 'psc-certified-source/1' ||
        artifactKey(certificateValue.canonicalAdmissionsId) !== artifactKey(core.identity) ||
        artifactKey(certifiedValue.canonicalAdmissionsId) !== artifactKey(core.identity) ||
        artifactKey(certifiedValue.certificateId) !== artifactKey(pscvCertificate.identity))
      throw new Error('PSC_BUILD_GRAPH_CERTIFICATION_BINDING');
    const cert = add(pscvCertificate, { kind: 'output-file', suffix: '.pscv-cert.json' });
    const certified = add(certifiedSourceArtifact, { kind: 'output-file', suffix: '.certified-source.json' });
    execute('psc-certify-checked-core/1', core, [certified], implementation, 'psc-kernel-accepted-certified-source/1',
      { observedStages: ['pscv-cert', 'certified-source'], certificateId: cert.identity,
        serializedAuthority: false, liveCapabilityRequiredForTransformation: true },
      [...baseDependencies, cert.identity], ['trusted-host-certification-binding']);
    certifiedInput = certified;
    certification = { pscvCert: cert.identity, certifiedSource: certified.identity };
  }
  let sourceApi;
  if (publicApi !== undefined) {
    if (!certification || typeof publicApi !== 'string') throw new Error('PSC_BUILD_GRAPH_PUBLIC_API_SUBJECT');
    sourceApi = add(publicApiArtifact(publicApi), { kind: 'output-file', suffix: '.public-api.json' });
    execute('psc-project-public-api/1', certifiedInput, [sourceApi], implementation, 'psc-source-public-api-projection/1',
      { observedStages: ['source-signature-projection-before-erasure'], visibilityPolicy: 'all-prepared-declarations',
        sourceGenericsRetained: true, declarationBodiesRetained: false, targetCorrespondenceVerified: false,
        independentProjectionChecked: false }, baseDependencies, ['trusted-source-public-api-projection']);
  }
  let declarationOriginGraph;
  if (declarationOrigins !== undefined) {
    if (!sourceApi || !certification || typeof declarationOrigins !== 'string') throw new Error('PSC_BUILD_GRAPH_ORIGIN_SUBJECT');
    const projection = createDeclarationOriginGraph({ table: declarationOrigins, sources, publicApi: sourceApi });
    for (const item of projection.artifacts) add(item, { kind: 'archive-required', role: 'declaration-origin-subject' });
    declarationOriginGraph = add(projection.graph, { kind: 'output-file', suffix: '.origin-graph.json' });
    execute('psc-capture-declaration-origins/1', certifiedInput, [declarationOriginGraph], implementation,
      'psc-source-declaration-origins/1',
      { observedStages: ['observe-actual-elaboration-batches', 'bind-source-and-public-api'],
        granularity: 'declaration-batch', expressionCorrespondenceChecked: false, semanticPreservationProved: false },
      [...baseDependencies, source.identity, ...projection.artifacts.map(item => item.identity),
        ...(preparationOrigins ? [preparationOrigins.identity] : [])], [], undefined,
      { originPolicy: 'synthesize', authorityEffect: 'none',
        originReason: 'Bind actual declaration-batch parser spans to source Core names; expressions and later IR stages remain unmapped.' });
  }
  const stages = checkedIrStageArtifacts(irStages);
  const targetStages = checkedTargetIrStageArtifacts(irStages);
  let verifiedIr;
  let erasureMap;
  if (erasureCorrespondence !== undefined && (!stages || !sourceApi || !certification || (typeScript === undefined && !directBackend)))
    throw new Error('PSC_BUILD_GRAPH_ERASURE_SUBJECT');
  if (stages && (typeScript !== undefined || directBackend)) {
      const runtimeIr = add(stages.runtimeIr, { kind: 'archive-required', role: 'actual-erasure-output' });
      verifiedIr = add(stages.verifiedIr, { kind: 'archive-required', role: 'actual-validation-output' });
      if (!runtimeIr.bytes.equals(verifiedIr.bytes)) throw new Error('PSC_BUILD_GRAPH_VALIDATION_CHANGED_IR');
      execute('psc-erase-checked-core/1', certifiedInput, [runtimeIr], implementation,
        certifiedInput === core ? 'psc-core-runtime-refinement/1' : 'psc-certified-source-runtime-refinement/1',
        { observedStages: ['erase'], certifiedSourceRequired: certifiedInput !== core }, baseDependencies,
        ['trusted-erasure-implementation']);
      if (erasureCorrespondence !== undefined) {
        const projection = createErasureDeclarationMap({ table: erasureCorrespondence, publicApi: sourceApi, runtimeIr });
        for (const item of projection.artifacts) add(item, { kind: 'archive-required', role: 'erasure-declaration-subject' });
        erasureMap = add(projection.map, { kind: 'output-file', suffix: '.erasure-map.json' });
        execute('psc-capture-erasure-declarations/1', certifiedInput, [erasureMap], implementation,
          'psc-source-runtime-declaration-inventory/1',
          { observedStages: ['observe-actual-erasure-fold', 'check-source-and-runtime-inventories'],
            inventoryCorrespondenceChecked: true, proofDispositionIndependentlyChecked: false, semanticPreservationProved: false },
          [...baseDependencies, ...projection.artifacts.map(item => item.identity),
            ...(declarationOriginGraph ? [declarationOriginGraph.identity] : [])], [], undefined,
          { originPolicy: 'synthesize', authorityEffect: 'none',
            originReason: 'Record actual source declaration dispositions and runtime names; expression, layout and target origins remain unmapped.' });
      }
      execute('psc-validate-runtime-ir/1', runtimeIr, [verifiedIr], implementation, 'psc-runtime-ir-invariants/1',
        { observedStages: ['validate-ir'], bytesPreserved: true }, baseDependencies, ['trusted-strict-ir-validator']);
      runtimeInterface = add(runtimeInterfaceArtifact(verifiedIr), { kind: 'archive-required', role: 'runtime-structural-interface' });
      execute('psc-project-runtime-interface/1', verifiedIr, [runtimeInterface], implementation, 'psc-runtime-interface-projection/1',
        { observedStages: ['runtime-interface-projection'], excludes: ['declaration-bodies'],
          behavioralReuse: false }, baseDependencies, ['trusted-runtime-interface-projection']);
  }
  if (verifiedIr && (javaScript !== undefined || directBackend === 'javascript')) {
    const derived = jsAbiArtifactsFromVerifiedIr(verifiedIr, jsAbiPolicy);
    jsAbiPolicyArtifact = add(derived.policy, { kind: 'archive-required', role: 'javascript-abi-host-policy' });
    jsAbiPlan = add(derived.plan, { kind: 'output-file', suffix: '.abi-plan.json' });
    execute('psc-verified-ir-to-js-abi-plan/1', verifiedIr, [jsAbiPlan], implementation,
      derived.relation, { target: 'javascript', policyId: jsAbiPolicyArtifact.identity,
        observedStages: ['independent-verified-ir-abi-plan-derivation'], adapterAuthority: derived.authority },
      [...baseDependencies, jsAbiPolicyArtifact.identity],
      ['selected-host-abi-policy', 'trusted-js-abi-plan-derivation']);
  }
  if (typeScript !== undefined) {
    const ts = bytes(typeScript, 'typescript-source', 'psc-typescript-source/es2022', { kind: 'output-file', suffix: '.ts' });
    if (verifiedIr) {
      execute('psc-verified-ir-to-typescript/1', verifiedIr, [ts], implementation, 'psc-ir-typescript-refinement/1',
        { target: 'typescript', observedStages: ['typescript-emission'],
          unobservedInteriorStages: ['typescript-lower', 'typescript-print'] }, baseDependencies,
        ['trusted-typescript-emission']);
    } else {
      execute(certifiedInput === core ? 'psc-checked-core-to-typescript/1' : 'psc-certified-source-to-typescript/1',
        certifiedInput, [ts], implementation,
        certifiedInput === core ? 'psc-core-runtime-refinement/1' : 'psc-certified-source-runtime-refinement/1',
        { target: 'typescript', observedStages: ['checked-emission'],
          unobservedInteriorStages: ['erase', 'validate-ir', 'typescript-lower', 'typescript-print'] }, baseDependencies,
        ['trusted-erasure-and-typescript-emission']);
    }
    if (javaScript !== undefined) {
      if (typeof outputStem !== 'string' || !outputStem) throw new Error('PSC_BUILD_GRAPH_OUTPUT_STEM');
      const tool = bytes(typeScriptCompilerBytes, 'typescript-compiler-entry', 'typescript-compiler-entry/1',
        { kind: 'archive-required', role: 'typescript-compiler-entry' });
      if (typeScriptToolInputs) {
        const { details, files } = typeScriptToolInputs;
        toolInputs = bindToolInputs(typeScriptToolInputs, 'psc-typescript-tool-inputs/1', 'typescript-tool-file', 'typescript-package-file');
        const entry = files.find(item => item.path === details.entryPath);
        if (!entry || !Buffer.from(entry.bytes).equals(Buffer.from(typeScriptCompilerBytes))) throw new Error('PSC_BUILD_GRAPH_TOOL_ENTRY');
      }
      const outputs = [
        bytes(javaScript, 'javascript-output', 'typescript-emitted-file/1', { kind: 'output-file', suffix: '.js' }),
        bytes(declarations, 'declarations-output', 'typescript-emitted-file/1', { kind: 'output-file', suffix: '.d.ts' }),
        bytes(sourceMap, 'source-map-output', 'typescript-emitted-file/1', { kind: 'output-file', suffix: '.js.map' }),
      ];
      executableArtifact = outputs[0].identity;
      execute('typescript-to-es2022/1', ts, outputs, toolInputs ?? tool, 'typescript-erasure-to-es2022/1',
        { outputStem, inputClosureComplete: false,
          flags: ['--ignoreConfig', '--target', 'ES2022', '--module', 'ES2022', '--moduleResolution', 'bundler',
          '--strict', '--declaration', '--sourceMap', '--noEmitOnError', '--skipLibCheck', '--pretty', 'false'] },
        toolInputs ? [...baseDependencies, toolInputs.identity] : baseDependencies, ['selected-typescript-package-closure']);
    }
  }
  if (directBackend) {
    if (!verifiedIr || !stages?.specializedIr)
      throw new Error(directBackend === 'javascript' ? 'PSC_BUILD_GRAPH_JS_STAGES_REQUIRED' : 'PSC_BUILD_GRAPH_WASM_STAGES_REQUIRED');
    const specializedIr = add(stages.specializedIr, { kind: 'archive-required', role: 'actual-specialization-output' });
    const projection = createSpecializationInstanceMap(verifiedIr, specializedIr);
    const correspondence = projection.result;
    specializationInstances = add(projection.map, { kind: 'output-file', suffix: '.specialization-instances.json' });
    execute('psc-pass-specialize/1', verifiedIr, [specializedIr, specializationInstances], implementation, 'psc-specialization-runtime-refinement/1',
      { observedStages: ['specialize', 'validate-specialized-ir', 'check-specialization-correspondence'],
        postcondition: 'strict-runtime-ir-invariants', correspondenceRelation: correspondence.relation,
        globalPreservationProved: false },
      baseDependencies, ['trusted-specialization-implementation', 'trusted-strict-ir-validator',
        'trusted-specialization-correspondence-checker'], correspondence);
    if (directBackend === 'javascript') {
      if (!targetStages.jsIr) throw new Error('PSC_BUILD_GRAPH_JS_TARGET_IR_REQUIRED');
      const jsIr = add(targetStages.jsIr, { kind: 'archive-required', role: 'actual-validated-js-ir' });
      execute('psc-specialized-ir-to-js-ir/1', specializedIr, [jsIr], implementation, 'psc-specialized-ir-js-ir/1',
        { target: 'javascript', wordSize: 64,
          observedStages: ['javascript-lower', 'validate-js-ir', 'snapshot-js-ir'],
          validator: 'psc-js-ir-validator/1', globalPreservationProved: false },
        baseDependencies, ['trusted-javascript-lowering', 'trusted-js-ir-validator']);
      const js = bytes(directJavaScript, 'javascript-output', 'psc-direct-javascript/es2022', { kind: 'output-file', suffix: '.js' });
      executableArtifact = js.identity;
      const printOutputs = [js], printDependencies = [...baseDependencies];
      if (generatedPositions !== undefined) {
        const projection = createJsGeneratedPositionMap({ table: generatedPositions, javaScript: directJavaScript, jsIr });
        for (const item of projection.artifacts) add(item, { kind: 'archive-required', role: 'javascript-generated-position-subject' });
        generatedPositionMap = add(projection.map, { kind: 'output-file', suffix: '.generated-positions.json' });
        printOutputs.push(generatedPositionMap);
        printDependencies.push(...projection.artifacts.map(item => item.identity).filter(id => id.domain === 'generated-position-table'));
      }
      execute('psc-js-ir-to-javascript/1', jsIr, printOutputs, implementation, 'psc-js-ir-printing/1',
        { target: 'javascript', observedStages: ['stack-safe-print',
          ...(generatedPositionMap ? ['observe-actual-declaration-chunks', 'check-generated-positions'] : [])],
          productionPromotion: false },
        printDependencies, ['trusted-javascript-printer'], undefined,
        generatedPositionMap ? { originPolicy: 'synthesize',
          originReason: 'Capture actual declaration-chunk generated positions; source attribution and fine-grained expression origins remain separate.' } : {});
    } else {
      if (!targetStages.wasmIr) throw new Error('PSC_BUILD_GRAPH_WASM_TARGET_IR_REQUIRED');
      const wasmIr = add(targetStages.wasmIr, { kind: 'archive-required', role: 'actual-validated-wasm-ir' });
      let adapterDependencies = baseDependencies;
      let selection, foreignInterface, binding;
      if (wasmCanonical !== undefined) {
        const projection = verifyWasmCanonicalProjection({ specializedIr, selection: wasmCanonical.selection,
          interfaceArtifact: wasmCanonical.interface, binding: wasmCanonical.binding });
        selection = add(wasmCanonical.selection, { kind: 'archive-required', role: 'wasm-canonical-export-selection' });
        foreignInterface = add(wasmCanonical.interface, { kind: 'output-file', suffix: '.interface-ir.json' });
        binding = add(wasmCanonical.binding, { kind: 'output-file', suffix: '.wasm-abi-plan.json' });
        adapterDependencies = [...baseDependencies, selection.identity, foreignInterface.identity, binding.identity];
        execute('psc-specialized-ir-to-canonical-interface/1', specializedIr, [foreignInterface, binding],
          implementation, projection.relation,
          { selectionId: selection.identity, observedStages: ['independent-scalar-interface-projection'],
            sourceInvariantsVerified: false, globalPreservationProved: false },
          [...baseDependencies, selection.identity], ['selected-wasm-export-policy', 'trusted-wasm-interface-projection']);
      }
      execute('psc-specialized-ir-to-wasm-ir/1', specializedIr, [wasmIr], implementation, 'psc-specialized-ir-wasm-ir/1',
        { target: 'wasm', wordSize: binding ? JSON.parse(binding.bytes).wordBits : 32,
          observedStages: binding
            ? ['wasm-lower', 'canonical-scalar-export-selection', 'validate-canonical-core-signatures', 'validate-wasm-ir', 'snapshot-wasm-ir']
            : ['wasm-lower', 'selfhost-abi', 'validate-wasm-ir', 'snapshot-wasm-ir'],
          ...(selection ? { selectionId: selection.identity } : {}),
          validator: 'psc-wasm-ir-validator/1', globalPreservationProved: false },
        adapterDependencies, ['trusted-wasm-lowering-and-abi', 'trusted-wasm-ir-validator']);
      const wasm = bytes(directWasm, binding ? 'wasm-binary' : 'wasm-output',
        binding ? 'webassembly-core/1' : 'psc-direct-wasm/wasm32', { kind: 'output-file', suffix: '.wasm' });
      executableArtifact = wasm.identity;
      execute('psc-wasm-ir-to-wasm/1', wasmIr, [wasm], implementation, 'psc-wasm-ir-encoding/1',
        { target: 'wasm', observedStages: ['wasm-binary-encode'], globalPreservationProved: false },
        adapterDependencies, ['trusted-wasm-binary-encoder']);
      if (binding) {
        const checked = verifyWasmCanonicalBinary({ interfaceArtifact: foreignInterface, binding, binary: wasm, targetIr: wasmIr });
        const validation = json(checked, 'adapter-validation', 'psc-wasm-canonical-signatures-validation/1', { kind: 'inline' });
        execute('psc-check-canonical-wasm-exports/1', wasm, [validation], implementation, checked.relation,
          { interfaceId: foreignInterface.identity, bindingId: binding.identity, targetIrId: wasmIr.identity,
            observedStages: ['engine-binary-validation', 'exact-closed-export-signature-check'],
            guestExecuted: false, globalPreservationProved: false },
          [...adapterDependencies, wasmIr.identity], ['selected-wasm-engine-validation', 'trusted-wasm-signature-inspection']);
        canonicalAdapter = Object.freeze({ selection, interface: foreignInterface, binding, validation });
      }
    }
  }
  const graph = { schemaVersion: 1, contract: 'psc-observed-build-graph/1', authority: 'audit-record-only',
    entries, executions, coverage: directBackend ? 'observed-erasure-validation-specialization-target-ir-and-executable-edges' :
      irStages ? 'observed-erasure-validation-and-composite-backend-edges' : 'observed-composite-edges',
    remaining: [directBackend ? 'global backend preservation, target-validator soundness and target-specific assurance gates' :
      irStages ? 'specialization and backend-interior artifacts' : 'per-IR-stage artifacts',
      'complete toolchain closure', 'independent preservation evidence'] };
  const encoded = canonicalBytes(graph);
  return { graph, artifacts, bytes: encoded, ...(runtimeInterface ? { runtimeInterface: runtimeInterface.identity } : {}),
    ...(certification ? { certification } : {}),
    ...(sourceApi ? { publicApi: sourceApi } : {}),
    ...(preparationOrigins ? { sourceOrigins: preparationOrigins } : {}),
    ...(declarationOriginGraph ? { originGraph: declarationOriginGraph } : {}),
    ...(erasureMap ? { erasureMap } : {}),
    ...(specializationInstances ? { specializationInstances } : {}),
    ...(generatedPositionMap ? { generatedPositionMap } : {}),
    ...(executableArtifact ? { executableArtifact } : {}),
    ...(canonicalAdapter ? { wasmCanonical: canonicalAdapter } : {}),
    ...(jsAbiPlan && jsAbiPolicyArtifact ? { jsAbi: Object.freeze({ plan: jsAbiPlan, policy: jsAbiPolicyArtifact }) } : {}),
    identity: artifactId(encoded, 'build-graph', 'psc-observed-build-graph/1'),
    ...(providerInputs.length ? { providerInputs: providerInputs.map(item => item.identity) } : {}),
    ...(toolInputs ? { typeScriptToolInputs: toolInputs.identity } : {}) };
}
