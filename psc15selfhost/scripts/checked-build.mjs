import { captureWasmCanonicalSelection, wasmCanonicalSelectionContract } from './wasm-canonical-artifact.mjs';
import { readObservedFileBytes } from './observed-file-bytes.mjs';
import { artifactId, artifactKey, canonicalArtifact } from './artifact-evidence.mjs';
import { collectBuildOutputFiles } from './build-output-files.mjs';
import { bindObservedBuildContext } from './observed-build-context.mjs';
import { readFile, writeFile, mkdir, mkdtemp, rename, rm } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { readCheckedSourceSnapshot } from './checked-source-snapshot.mjs';
import { createCheckedCompilerService } from './compiler-checked-service.mjs';
import { createCheckedBuildGraph, readCheckedBuildHostSources } from './checked-build-evidence.mjs';
import { packObservedBuildArchive, observedBuildArchiveLimits } from './observed-build-archive.mjs';
import { createEvidenceEnvelope } from './evidence-envelope.mjs';
import { checkedKernelIdentity } from './checked-kernel-identity.mjs';
import { checkAdmissionsWithDual } from './checked-kernel-dual.mjs';
import { kernelContractV1 } from './kernel-contract.mjs';
import {
  checkAdmissionsWithKernel,
  checkedKernelDescriptor,
  defaultCheckedKernel,
} from './checked-kernel-provider.mjs';
import { runCheckedSeedSession, checkedSeedProductsProtocol, checkedSeedRustSourceProfile } from './checked-seed-session.mjs';
import { pinnedTypeScriptVersionText, resolveTypeScriptCli } from './typescript-cli.mjs';
import { captureTypeScriptToolInputs, verifyTypeScriptToolInputs } from './typescript-tool-inputs.mjs';
import { captureCheckedProviderInputs, verifyCheckedProviderInputs } from './checked-provider-inputs.mjs';
import { assertProviderSecurity, defaultProviderSecurityProfile } from './provider-security.mjs';
import { decodeJsAbiPolicy } from './js-abi-artifact.mjs';
import { closedJsRepresentationProfile, uniformJsRepresentationProfile } from './uniform-specialization.mjs';
import { directJsDeclarationProfile, directJsUniformDeclarationProfile } from './js-declarations.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const digest = data => createHash('sha256').update(data).digest('hex');
const nativeSuffix = process.platform === 'win32' ? '.exe' : '';
export const defaultCheckedSeed = path.join(root, 'lean-checked/.lake/build/bin/psc2_lean_checked_seed' + nativeSuffix);
export function checkedCompilerPath(kernel = defaultCheckedKernel) {
  checkedKernelDescriptor(kernel);
  return path.join(root, 'dist/checked', kernel, 'bootstrap/packages/compiler/index.js');
}
// Historical generated compiler location, retained for explicit --compiler use.
export const defaultCheckedCompiler = checkedCompilerPath();

/** Choose the implementation independently of the kernel provider and backend.
 * A missing native compiler fails; it never selects generated or unchecked code.
 */
export function selectCheckedCompiler({ compilerPath, seedPath } = {}) {
  if (compilerPath !== undefined && seedPath !== undefined)
    throw new Error('PSC2_CHECKED_SELECT_ONE_COMPILER');
  for (const value of [compilerPath, seedPath]) {
    if (value !== undefined && (typeof value !== 'string' || value.length === 0))
      throw new Error('PSC2_CHECKED_COMPILER_PATH');
  }
  return Object.freeze(compilerPath !== undefined
    ? { engine: 'generated-js', path: path.resolve(compilerPath) }
    : { engine: 'native-seed', path: path.resolve(seedPath ?? defaultCheckedSeed) });
}

/** Select before loading source/compiler bytes. Backend and product requests
 * cannot be inferred from an output suffix or silently replaced by another lane.
 */
export function selectCheckedBuildProducts({
  backend = 'typescript', products = backend === 'typescript' ? 'metadata' : backend === 'rust' ? 'source' : 'executable',
  javaScriptRepresentation = closedJsRepresentationProfile,
} = {}) {
  if (!['typescript', 'javascript', 'wasm', 'rust'].includes(backend)) throw new Error('PSC2_CHECKED_BACKEND');
  if (!['executable', 'metadata', 'declarations', 'source-map', 'all', 'source', 'declaration-map', 'linked'].includes(products)) throw new Error('PSC2_CHECKED_PRODUCTS');
  if (![closedJsRepresentationProfile, uniformJsRepresentationProfile].includes(javaScriptRepresentation) ||
      (backend !== 'javascript' && javaScriptRepresentation !== closedJsRepresentationProfile))
    throw new Error('PSC2_CHECKED_JAVASCRIPT_REPRESENTATION');
  if ((backend === 'typescript' && products !== 'metadata') ||
      (backend === 'wasm' && !['executable', 'metadata'].includes(products)) ||
      (backend === 'rust' && !['source', 'metadata'].includes(products)) ||
      (backend !== 'rust' && products === 'source'))
    throw new Error('PSC2_CHECKED_PRODUCT_TARGET');
  const linking = products === 'linked';
  const declarationMap = products === 'declaration-map' || products === 'all' || linking;
  const selection = Object.freeze({ metadata: products === 'metadata' || declarationMap,
    declarations: products === 'declarations' || declarationMap, sourceMap: products === 'source-map' || products === 'all' || linking });
  return Object.freeze({ backend, products, javaScriptRepresentation, selection, declarationMap, linking,
    ...(selection.declarations ? { declarationProfile: javaScriptRepresentation === uniformJsRepresentationProfile ?
      directJsUniformDeclarationProfile : directJsDeclarationProfile } : {}) });
}

export async function buildChecked({
  entryPath,
  outputPath,
  compilerPath,
  seedPath,
  checkOnly = false,
  kernel = defaultCheckedKernel,
  dualCheck,
  securityProfile = defaultProviderSecurityProfile,
  sourceResourceLimits,
  seedResourceLimits,
  archiveResourceLimits,
  jsAbiPolicyPath,
  wasmCanonicalSelectionPath,
  backend,
  products,
  javaScriptRepresentation,
}) {
  const selected = selectCheckedBuildProducts({ backend, products, javaScriptRepresentation });
  const archiveLimits = observedBuildArchiveLimits(archiveResourceLimits);
  const kernelDescriptor = checkedKernelDescriptor(kernel);
  const selectedProviderSecurity = assertProviderSecurity(kernel, securityProfile);
  const secondaryProviderSecurity = dualCheck
    ? assertProviderSecurity(dualCheck, securityProfile)
    : undefined;
  if (dualCheck) checkedKernelDescriptor(dualCheck);
  const selectedCompiler = selectCheckedCompiler({ compilerPath, seedPath });
  if (!checkOnly && !outputPath) throw new Error('PSC2_CHECKED_OUTPUT_REQUIRED');
  if (jsAbiPolicyPath !== undefined && !['typescript', 'javascript'].includes(selected.backend)) throw new Error('PSC2_CHECKED_JS_ABI_TARGET');
  if (wasmCanonicalSelectionPath !== undefined && selected.backend !== 'wasm') throw new Error('PSC2_CHECKED_WASM_EXPORT_TARGET');
  const output = checkOnly ? undefined : path.resolve(outputPath);
  const extension = selected.backend === 'wasm' ? /\.wasm$/u : selected.backend === 'javascript' ? /\.js$/u : selected.backend === 'rust' ? /\.rs$/u : /\.(?:ts|js)$/u;
  if (output !== undefined && !extension.test(output)) throw new Error('PSC2_CHECKED_OUTPUT_KIND');
  const stem = output === undefined ? undefined : path.basename(output).replace(extension, '');
  const [languageAuthorityValue, backendRegistryValue] = await Promise.all([
    readFile(path.join(root, 'language-authority.json'), 'utf8'),
    readFile(path.join(root, selected.linking ? 'contracts/backends/BACKEND_REGISTRY_V3.json' : selected.declarationMap ? 'contracts/backends/BACKEND_REGISTRY_V2.json' : 'contracts/backends/BACKEND_REGISTRY_V1.json'), 'utf8'),
  ]);
  const languageAuthority = canonicalArtifact(JSON.parse(languageAuthorityValue), 'language-authority', 'psc-language-authority-snapshot/1');
  const backendRegistry = canonicalArtifact(JSON.parse(backendRegistryValue), 'backend-registry', 'psc-backend-registry/1');
  let wasmCanonicalSelection;
  if (wasmCanonicalSelectionPath !== undefined) {
    const bytes = await readObservedFileBytes(path.resolve(wasmCanonicalSelectionPath), 1048576);
    wasmCanonicalSelection = captureWasmCanonicalSelection({
      bytes, identity: artifactId(bytes, 'abi-policy', wasmCanonicalSelectionContract),
    }).selection;
  }
  const snapshot = await readCheckedSourceSnapshot(entryPath, sourceResourceLimits);
  let admissions;
  let typeScript;
  let selectedEmission;
  let compilerIdentity;
  let compilerBytes;
  let irStages;
  let publicApi;
  let declarationOrigins;
  let erasureCorrespondence;
  let generatedPositions;
  let seedResources;
  let seedProductProtocol;
  let parity;
  let providerToolInputs = [];
  let pscvCertificate;
  let certifiedSourceArtifact;
  let jsAbiPolicy;
  if (jsAbiPolicyPath !== undefined) {
    const policyBytes = await readFile(path.resolve(jsAbiPolicyPath));
    jsAbiPolicy = decodeJsAbiPolicy(policyBytes);
  }
  const checkAdmissions = async text => {
    const captures = await Promise.all([kernel, ...(dualCheck ? [dualCheck] : [])].map(selector => captureCheckedProviderInputs(selector)));
    const pinnedOptions = Object.assign({}, ...captures.map(captured => captured.invocationOptions));
    const checked = dualCheck
      ? await checkAdmissionsWithDual(text, kernel, dualCheck, { securityProfile, ...pinnedOptions })
      : await checkAdmissionsWithKernel(text, kernel, { securityProfile, ...pinnedOptions });
    providerToolInputs = await Promise.all(captures.map(captured => verifyCheckedProviderInputs(captured)));
    parity = checked.parity;
    return checked.result;
  };

  if (selectedCompiler.engine === 'native-seed') {
    const binary = selectedCompiler.path;
    compilerBytes = await readFile(binary);
    compilerIdentity = { engine: 'native-seed', sha256: digest(compilerBytes) };
    const result = await runCheckedSeedSession({
      binaryPath: binary,
      sourceKind: snapshot.kind,
      source: snapshot.source,
      sources: snapshot.sources,
      checkAdmissions,
      emit: !checkOnly,
      resourceLimits: seedResourceLimits,
      productRequest: selected.backend === 'typescript' ? undefined : {
        target: selected.backend, representation: selected.backend === 'rust' ? checkedSeedRustSourceProfile : selected.javaScriptRepresentation, ...selected.selection,
        ...(wasmCanonicalSelection ? { wasmCanonicalSelection } : {}) },
      certificationContext: {
        provider: checkedKernelIdentity(kernel),
        providerSecurity: selectedProviderSecurity,
        kernelContract: kernelContractV1,
        assumptionPolicy: 'kernel-contract-default',
        resourcePolicy: 'checked-native-seed-session/1',
        targets: [selected.backend],
        executionBoundary: 'native-seed-checked-session',
      },
    });
    admissions = result.admissions;
    pscvCertificate = result.pscvCertificate;
    certifiedSourceArtifact = result.certifiedSourceArtifact;
    typeScript = result.typeScript;
    selectedEmission = result.directProduct;
    const captured = selectedEmission ?? result;
    irStages = captured.stages;
    publicApi = captured.publicApi;
    declarationOrigins = captured.declarationOrigins;
    erasureCorrespondence = captured.erasureCorrespondence;
    generatedPositions = captured.generatedPositions;
    seedResources = result.resourceObservation;
    seedProductProtocol = result.productProtocol;
  } else {
    const file = selectedCompiler.path;
    compilerBytes = await readFile(file);
    compilerIdentity = { engine: 'generated-js', sha256: digest(compilerBytes) };
    const compiler = await import(pathToFileURL(file).href);
    const kind = snapshot.kind === 'ps'
      ? compiler.PsCompilerSourceKind?.proofScript
      : compiler.PsCompilerSourceKind?.lean;
    if (kind === undefined) throw new Error('PSC2_CHECKED_SOURCE_KIND_API_MISSING');
    const session = createCheckedCompilerService({ compiler, checkAdmissions: async text => {
      admissions = text;
      return checkAdmissions(text);
    }, identity: checkedKernelIdentity(kernel), kernelContract: kernelContractV1, providerSecurity: selectedProviderSecurity,
      targets: [selected.backend], javaScriptRepresentation: selected.javaScriptRepresentation, wasmCanonicalSelection });
    try {
      const handle = await session.checkSources(kind, snapshot.sources);
      pscvCertificate = session.certificate(handle);
      certifiedSourceArtifact = session.certifiedSourceArtifact(handle);
      if (!checkOnly) {
        const emitted = selected.backend === 'typescript' ? session.emitArtifact(handle) :
          session.emitSelectedArtifact(handle, selected.backend, selected.selection);
        if (selected.backend === 'typescript') typeScript = emitted.payload;
        else selectedEmission = emitted;
        irStages = emitted.stages;
        publicApi = emitted.publicApi;
        declarationOrigins = emitted.declarationOrigins;
        erasureCorrespondence = emitted.erasureCorrespondence;
        generatedPositions = emitted.generatedPositions;
      }
    } finally { session.close(); }
  }

  const receipt = {
    schemaVersion: 4,
    kind: 'psc2-checked-build',
    backend: selected.backend,
    requestedProducts: selected.products,
    ...(selected.backend === 'javascript' ? { javaScriptRepresentation: selected.javaScriptRepresentation } : {}),
    kernelContract: kernelContractV1,
    provider: checkedKernelIdentity(kernel),
    providerSecurity: selectedProviderSecurity,
    ...(secondaryProviderSecurity ? { secondaryProviderSecurity } : {}),
    kernel: kernelDescriptor,
    compiler: compilerIdentity,
    sourceClosureSha256: snapshot.closureSha256,
    flattenedSourceSha256: digest(snapshot.source),
    sourceCount: snapshot.ordered.length,
    sourceResources: snapshot.resourceObservation,
    ...(seedResources ? { seedResources } : {}),
    ...(seedProductProtocol ? { seedProductProtocol } : {}),
    canonicalAdmissionsSha256: digest(admissions),
    providerInputObservations: providerToolInputs.map(item => item.details),
    ...(parity ? { dualCheck: parity } : {}),
    pscvCert: pscvCertificate?.identity,
    certifiedSource: certifiedSourceArtifact?.identity,
  };
  if (checkOnly) return receipt;
  if (selected.backend === 'typescript' && typeof typeScript !== 'string') throw new Error('PSC2_CHECKED_TS_RESULT');
  if (selected.backend !== 'typescript' && !selectedEmission?.stages) throw new Error('PSC2_CHECKED_DIRECT_STAGES_REQUIRED');

  // Every backend uses the same graph-driven publication path. Only the
  // explicitly selected TypeScript lane invokes the pinned external compiler.
  let toolCapture;
  if (selected.backend === 'typescript') {
    const tsc = resolveTypeScriptCli();
    toolCapture = await captureTypeScriptToolInputs(tsc);
    const version = spawnSync(toolCapture.command, [...toolCapture.argumentsPrefix, '--version'],
      { encoding: 'utf8', timeout: 10000, windowsHide: true });
    if (version.error || version.status !== 0 || version.stdout.trim() !== pinnedTypeScriptVersionText)
      throw new Error('PSC2_CHECKED_TYPESCRIPT_PIN: require TypeScript 7.0.2');
  }
  await mkdir(path.dirname(output), { recursive: true });
  const staging = await mkdtemp(path.join(path.dirname(output), '.checked-stage-'));
  try {
    let backendProducts;
    if (selected.backend === 'typescript') {
      const tsFile = path.join(staging, stem + '.ts');
      await writeFile(tsFile, typeScript);
      const run = spawnSync(toolCapture.command, [...toolCapture.argumentsPrefix, tsFile, '--ignoreConfig', '--target', 'ES2022', '--module', 'ES2022',
        '--moduleResolution', 'bundler', '--strict', '--declaration', '--sourceMap',
        '--noEmitOnError', '--skipLibCheck', '--pretty', 'false'], {
        encoding: 'utf8', timeout: 120000, maxBuffer: 16 * 1024 * 1024, windowsHide: true,
      });
      if (run.error) throw run.error;
      if (run.status !== 0) throw new Error(`PSC2_CHECKED_TSC_FAILED: ${run.stdout}\n${run.stderr}`);
      const typeScriptToolInputs = await verifyTypeScriptToolInputs(toolCapture);
      const [javaScript, declarations, sourceMap] = await Promise.all([
        readFile(path.join(staging, stem + '.js')), readFile(path.join(staging, stem + '.d.ts')),
        readFile(path.join(staging, stem + '.js.map')),
      ]);
      const typeScriptCompilerBytes = typeScriptToolInputs.files.find(item => item.path === typeScriptToolInputs.details.entryPath).bytes;
      receipt.typeScriptSha256 = digest(typeScript);
      receipt.javaScriptSha256 = digest(javaScript);
      backendProducts = { typeScript, javaScript, declarations, sourceMap, typeScriptCompilerBytes, typeScriptToolInputs };
    } else {
      backendProducts = selected.backend === 'javascript' ? { directJavaScript: selectedEmission.payload } :
        selected.backend === 'rust' ? { rustSource: selectedEmission.payload } : { directWasm: selectedEmission.payload };
      receipt[selected.backend === 'javascript' ? 'javaScriptSha256' : selected.backend === 'rust' ? 'rustSourceSha256' : 'wasmSha256'] = digest(selectedEmission.payload);
      if (selected.backend === 'rust') receipt.rustTarget = { product: 'source', edition: '2021',
        compilerInvoked: false, nativeBinaryProduced: false, globalPreservationProved: false };
      if (selectedEmission.declarationProduction) receipt.declarationProduction = selectedEmission.declarationProduction;
    }
    const hostSources = await readCheckedBuildHostSources();
    const observed = createCheckedBuildGraph({ sourceKind: snapshot.kind, sources: snapshot.sources,
      admissions, ...backendProducts, compilerBytes, sourceResources: snapshot.resourceObservation, seedResources,
      compilerKind: compilerIdentity.engine, outputStem: stem, irStages,
      javaScriptRepresentation: selected.javaScriptRepresentation, declarationProfile: selected.declarationProfile,
      includeSpecializationInstances: selected.selection.metadata || selected.selection.sourceMap,
      includeDeclarationMap: selected.declarationMap, includeLinkedSourceMaps: selected.linking,
      provider: receipt.provider, providerSecurity: selectedProviderSecurity, kernelContract: kernelContractV1, providerToolInputs,
      hostSources, pscvCertificate, certifiedSourceArtifact, jsAbiPolicy, publicApi,
      sourceOrigins: selected.selection.metadata || selected.selection.sourceMap ? snapshot.sourceOrigins : undefined,
      declarationOrigins, erasureCorrespondence, generatedPositions, wasmCanonical: selectedEmission?.wasmCanonical,
      runtime: { implementation: 'node', version: process.version, platform: process.platform, arch: process.arch } });
    if (selected.selection.declarations) {
      for (const key of ['declarations', 'sourceSignatures', 'binding']) {
        const live = selectedEmission?.directDeclarations?.[key], recorded = observed.directDeclarations?.[key];
        if (!live || !recorded || artifactKey(live.identity) !== artifactKey(recorded.identity) ||
            !Buffer.from(live.bytes).equals(recorded.bytes)) throw new Error('PSC2_CHECKED_DECLARATION_BUILD_BINDING');
      }
    }
    if (selected.declarationMap && !observed.directDeclarationMap) throw new Error('PSC2_CHECKED_DECLARATION_MAP_BUILD_BINDING');
    if (selected.linking && !observed.directMapLinks) throw new Error('PSC2_CHECKED_MAP_LINK_BUILD_BINDING');
    if (selected.selection.sourceMap) {
      if (!observed.directSourceMap) throw new Error('PSC2_CHECKED_SOURCE_MAP_BUILD_BINDING');
      if (compilerIdentity.engine === 'native-seed') {
        // This transport returns captured native tables; the common graph is
        // their first full map materializer, over the same checked source.
        if (selectedEmission?.protocol !== checkedSeedProductsProtocol)
          throw new Error('PSC2_CHECKED_SOURCE_MAP_BUILD_BINDING');
      } else if (!selectedEmission?.declarationLineage ||
          artifactKey(observed.declarationLineage.identity) !== artifactKey(selectedEmission.declarationLineage))
        throw new Error('PSC2_CHECKED_SOURCE_MAP_BUILD_BINDING');
    }
    if (wasmCanonicalSelection) {
      for (const key of ['selection', 'interface', 'binding']) {
        const live = selectedEmission?.wasmCanonical?.[key], recorded = observed.wasmCanonical?.[key];
        if (!live || !recorded || artifactKey(live.identity) !== artifactKey(recorded.identity) ||
            !Buffer.from(live.bytes).equals(recorded.bytes)) throw new Error('PSC2_CHECKED_WASM_BUILD_BINDING');
      }
      if (artifactKey(observed.wasmCanonical.selection.identity) !== artifactKey(wasmCanonicalSelection.identity))
        throw new Error('PSC2_CHECKED_WASM_BUILD_BINDING');
    }
    const evidence = bindObservedBuildContext(observed, { languageAuthority, backendRegistry, backendId: selected.backend,
      javaScriptRepresentation: selected.javaScriptRepresentation });
    receipt.profileEnvironment = evidence.profileEnvironment.identity;
    receipt.buildActions = evidence.buildActions.map(item => item.action.identity);
    receipt.queryKeys = evidence.queryKeys.map(item => item.identity);
    receipt.backendDescriptor = evidence.backendDescriptor.identity;
    receipt.artifactBundle = evidence.artifactBundle.identity;
    receipt.claimSet = evidence.claimSet.identity;
    receipt.buildGraph = evidence.identity;
    if (evidence.runtimeInterface) receipt.runtimeInterface = evidence.runtimeInterface;
    if (evidence.publicApi) receipt.publicApi = evidence.publicApi.identity;
    if (evidence.sourceOrigins) receipt.sourceOrigins = evidence.sourceOrigins.identity;
    if (evidence.originGraph) receipt.originGraph = evidence.originGraph.identity;
    if (evidence.erasureMap) receipt.erasureMap = evidence.erasureMap.identity;
    if (evidence.specializationInstances) receipt.specializationInstances = evidence.specializationInstances.identity;
    if (evidence.generatedPositionMap) receipt.generatedPositionMap = evidence.generatedPositionMap.identity;
    if (evidence.declarationLineage) receipt.declarationLineage = evidence.declarationLineage.identity;
    if (evidence.directDeclarations) receipt.directDeclarations = Object.fromEntries(
      Object.entries(evidence.directDeclarations).map(([key, record]) => [key, record.identity]));
    if (evidence.directDeclarationMap) receipt.directDeclarationMap = Object.fromEntries(
      Object.entries(evidence.directDeclarationMap).map(([key, record]) => [key, record.identity]));
    if (evidence.directMapLinks) receipt.directMapLinks = Object.fromEntries(
      Object.entries(evidence.directMapLinks).map(([key, record]) => [key, record.identity]));
    if (selected.linking) {
      if (!evidence.directMapLinks?.linkedJavaScript || !evidence.directMapLinks?.linkedDeclarations)
        throw new Error('PSC2_CHECKED_MAP_LINK_BUILD_BINDING');
      receipt.unlinkedJavaScriptSha256 = receipt.javaScriptSha256;
      receipt.javaScriptSha256 = digest(evidence.directMapLinks.linkedJavaScript.bytes);
      receipt.linkedDeclarationsSha256 = digest(evidence.directMapLinks.linkedDeclarations.bytes);
    }
    if (evidence.directSourceMap) receipt.directSourceMap = {
      sourceMap: evidence.directSourceMap.sourceMap.identity, recipe: evidence.directSourceMap.recipe.identity };
    if (evidence.jsAbi) {
      receipt.jsAbiPlan = evidence.jsAbi.plan.identity;
      receipt.jsAbiPolicy = evidence.jsAbi.policy.identity;
    }
    if (evidence.wasmCanonical) receipt.wasmCanonical = Object.fromEntries(
      Object.entries(evidence.wasmCanonical).map(([key, record]) => [key, record.identity]));
    receipt.typeScriptToolInputs = evidence.typeScriptToolInputs;
    receipt.providerInputs = evidence.providerInputs;
    const archive = packObservedBuildArchive(evidence, archiveLimits);
    receipt.archiveResourceLimits = archiveLimits;
    receipt.buildArchive = archive.identity;
    if (!evidence.executableArtifact) throw new Error('PSC2_CHECKED_EXECUTABLE_ARTIFACT_MISSING');
    const envelope = createEvidenceEnvelope({
      executableArtifact: evidence.executableArtifact,
      pscvCert: pscvCertificate.identity,
      certifiedSource: certifiedSourceArtifact.identity,
      buildGraph: evidence.identity,
      buildArchive: archive.identity,
      runtimeInterface: evidence.runtimeInterface,
      targetAdapters: evidence.jsAbi ? [evidence.jsAbi.policy.identity, evidence.jsAbi.plan.identity] :
        evidence.wasmCanonical ? Object.values(evidence.wasmCanonical).map(record => record.identity) : [],
      providerInputs: evidence.providerInputs ?? [],
      typeScriptToolInputs: evidence.typeScriptToolInputs,
      sourceResources: snapshot.resourceObservation,
      seedResources,
    });
    receipt.evidenceEnvelope = envelope.identity;
    const outputFiles = collectBuildOutputFiles(evidence, [
      { suffix: '.evidence-envelope.json', record: envelope },
      { suffix: '.build-archive.json', record: archive },
      { suffix: '.build-graph.json', record: evidence },
      { suffix: '.profile-environment.json', record: evidence.profileEnvironment },
      { suffix: '.backend-descriptor.json', record: evidence.backendDescriptor },
      { suffix: '.artifact-bundle.json', record: evidence.artifactBundle },
      { suffix: '.claim-set.json', record: evidence.claimSet },
      ...(evidence.jsAbi ? [{ suffix: '.abi-policy.json', record: evidence.jsAbi.policy }] : []),
      ...(evidence.wasmCanonical ? [{ suffix: '.wasm-export-selection.json', record: evidence.wasmCanonical.selection }] : []),
    ]);
    for (const file of outputFiles) await writeFile(path.join(staging, stem + file.suffix), file.bytes);
    for (const file of outputFiles) {
      await rename(path.join(staging, stem + file.suffix), path.join(path.dirname(output), stem + file.suffix));
    }
    // This receipt is an audit record, not a transferable proof/capability.
    await writeFile(path.join(staging, 'receipt.json'), JSON.stringify(receipt, null, 2) + '\n');
    await rename(path.join(staging, 'receipt.json'), path.join(path.dirname(output), stem + '.checked.json'));
  } finally {
    await rm(staging, { recursive: true, force: true });
  }
  return receipt;
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const args = process.argv.slice(2);
  const entryPath = args.shift();
  const options = { entryPath };
  while (args.length) {
    const flag = args.shift();
    if (flag === '--check') options.checkOnly = true;
    else if (flag === '--archive-max-bytes' || flag === '--archive-max-total-bytes') {
      const value = args.shift();
      if (!/^(?:0|[1-9][0-9]*)(?![\s\S])/u.test(value ?? '') || !Number.isSafeInteger(Number(value)))
        throw new Error('PSC_BUILD_ARCHIVE_LIMIT_POLICY');
      options.archiveResourceLimits ??= {};
      options.archiveResourceLimits[flag === '--archive-max-bytes' ? 'maxArchiveBytes' : 'maxTotalBytes'] = Number(value);
    }
    else if (['--out', '--compiler', '--seed', '--kernel', '--dual-check', '--security-profile', '--js-abi-policy', '--wasm-exports', '--backend', '--products', '--js-representation'].includes(flag)) {
      const value = args.shift();
      if (!value || value.startsWith('--')) throw new Error(`Missing value for ${flag}`);
      options[{ '--out': 'outputPath', '--compiler': 'compilerPath', '--seed': 'seedPath', '--kernel': 'kernel', '--dual-check': 'dualCheck', '--security-profile': 'securityProfile', '--js-abi-policy': 'jsAbiPolicyPath', '--wasm-exports': 'wasmCanonicalSelectionPath', '--backend': 'backend', '--products': 'products', '--js-representation': 'javaScriptRepresentation' }[flag]] =
        flag === '--js-representation' ? ({ closed: closedJsRepresentationProfile, uniform: uniformJsRepresentationProfile }[value] ?? value) : value;
    } else throw new Error(`Unknown checked-build option: ${flag}`);
  }
  if (!entryPath) {
    throw new Error('usage: checked-build.mjs <entry> [--check | --out file.js] [--compiler file.js | --seed binary] [--kernel lean434|lean434-wasm|pskernel-core|pskernel-core.old3] [--dual-check pskernel-core|lean434|lean434-wasm] [--security-profile development-v1|compatibility-v1|paranoid-v1] [--js-abi-policy policy.json] [--wasm-exports selection.json] [--backend typescript|javascript|wasm|rust] [--products source|executable|metadata|declarations|source-map|declaration-map|linked|all] [--js-representation closed|uniform] [--archive-max-bytes n] [--archive-max-total-bytes n]');
  }
  const receipt = await buildChecked(options);
  console.log('PSC2_CHECKED_BUILD: PASS ' + JSON.stringify(receipt));
}
