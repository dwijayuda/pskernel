import { canonicalArtifact } from './artifact-evidence.mjs';
import { bindObservedBuildContext } from './observed-build-context.mjs';
import { readFile, writeFile, mkdir, mkdtemp, rename, rm } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { readCheckedSourceSnapshot } from './checked-source-snapshot.mjs';
import { createCheckedCompilerService } from './compiler-checked-service.mjs';
import { createCheckedBuildGraph, readCheckedBuildHostSources } from './checked-build-evidence.mjs';
import { packObservedBuildArchive } from './observed-build-archive.mjs';
import { createEvidenceEnvelope } from './evidence-envelope.mjs';
import { checkedKernelIdentity } from './checked-kernel-identity.mjs';
import { checkAdmissionsWithDual } from './checked-kernel-dual.mjs';
import { kernelContractV1 } from './kernel-contract.mjs';
import {
  checkAdmissionsWithKernel,
  checkedKernelDescriptor,
  defaultCheckedKernel,
} from './checked-kernel-provider.mjs';
import { runCheckedSeedSession } from './checked-seed-session.mjs';
import { pinnedTypeScriptVersionText, resolveTypeScriptCli } from './typescript-cli.mjs';
import { captureTypeScriptToolInputs, verifyTypeScriptToolInputs } from './typescript-tool-inputs.mjs';
import { captureCheckedProviderInputs, verifyCheckedProviderInputs } from './checked-provider-inputs.mjs';
import { assertProviderSecurity, defaultProviderSecurityProfile } from './provider-security.mjs';
import { decodeJsAbiPolicy } from './js-abi-artifact.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const digest = data => createHash('sha256').update(data).digest('hex');
const nativeSuffix = process.platform === 'win32' ? '.exe' : '';
export const defaultCheckedSeed = path.join(root, 'lean-checked/.lake/build/bin/psc2_lean_checked_seed' + nativeSuffix);
export function checkedCompilerPath(kernel = defaultCheckedKernel) {
  checkedKernelDescriptor(kernel);
  return path.join(root, 'dist/checked', kernel, 'bootstrap/packages/compiler/index.js');
}
export const defaultCheckedCompiler = checkedCompilerPath();

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
  jsAbiPolicyPath,
}) {
  const kernelDescriptor = checkedKernelDescriptor(kernel);
  const selectedProviderSecurity = assertProviderSecurity(kernel, securityProfile);
  const secondaryProviderSecurity = dualCheck
    ? assertProviderSecurity(dualCheck, securityProfile)
    : undefined;
  if (dualCheck) checkedKernelDescriptor(dualCheck);
  if (compilerPath && seedPath) throw new Error('PSC2_CHECKED_SELECT_ONE_COMPILER');
  if (!checkOnly && !outputPath) throw new Error('PSC2_CHECKED_OUTPUT_REQUIRED');
  const [languageAuthorityValue, backendRegistryValue] = await Promise.all([
    readFile(path.join(root, 'language-authority.json'), 'utf8'),
    readFile(path.join(root, 'contracts/backends/BACKEND_REGISTRY_V1.json'), 'utf8'),
  ]);
  const languageAuthority = canonicalArtifact(JSON.parse(languageAuthorityValue), 'language-authority', 'psc-language-authority-snapshot/1');
  const backendRegistry = canonicalArtifact(JSON.parse(backendRegistryValue), 'backend-registry', 'psc-backend-registry/1');
  const snapshot = await readCheckedSourceSnapshot(entryPath, sourceResourceLimits);
  let admissions;
  let typeScript;
  let compilerIdentity;
  let compilerBytes;
  let irStages;
  let publicApi;
  let seedResources;
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

  if (seedPath) {
    const binary = path.resolve(seedPath);
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
      certificationContext: {
        provider: checkedKernelIdentity(kernel),
        providerSecurity: selectedProviderSecurity,
        kernelContract: kernelContractV1,
        assumptionPolicy: 'kernel-contract-default',
        resourcePolicy: 'checked-native-seed-session/1',
        targets: ['typescript'],
        executionBoundary: 'native-seed-checked-session',
      },
    });
    admissions = result.admissions;
    pscvCertificate = result.pscvCertificate;
    certifiedSourceArtifact = result.certifiedSourceArtifact;
    typeScript = result.typeScript;
    irStages = result.stages;
    publicApi = result.publicApi;
    seedResources = result.resourceObservation;
  } else {
    const file = path.resolve(compilerPath ?? checkedCompilerPath(kernel));
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
    }, identity: checkedKernelIdentity(kernel), kernelContract: kernelContractV1, providerSecurity: selectedProviderSecurity });
    const handle = await session.checkSources(kind, snapshot.sources);
    pscvCertificate = session.certificate(handle);
    certifiedSourceArtifact = session.certifiedSourceArtifact(handle);
    if (!checkOnly) {
      const emitted = session.emitArtifact(handle);
      typeScript = emitted.payload;
      irStages = emitted.stages;
      publicApi = emitted.publicApi;
    }
  }

  const receipt = {
    schemaVersion: 4,
    kind: 'psc2-checked-build',
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
    canonicalAdmissionsSha256: digest(admissions),
    providerInputObservations: providerToolInputs.map(item => item.details),
    ...(parity ? { dualCheck: parity } : {}),
    pscvCert: pscvCertificate?.identity,
    certifiedSource: certifiedSourceArtifact?.identity,
  };
  if (checkOnly) return receipt;
  if (typeof typeScript !== 'string') throw new Error('PSC2_CHECKED_TS_RESULT');
  const output = path.resolve(outputPath);
  if (!/\.(?:ts|js)$/u.test(output)) throw new Error('PSC2_CHECKED_OUTPUT_KIND');
  const stem = path.basename(output).replace(/\.(?:ts|js)$/u, '');

  // Kernel acceptance has already happened. TypeScript writes only into staging;
  // a failed tsc cannot create a new final output or checked receipt.
  const tsc = resolveTypeScriptCli();
  const toolCapture = await captureTypeScriptToolInputs(tsc);
  const version = spawnSync(toolCapture.command, [...toolCapture.argumentsPrefix, '--version'],
    { encoding: 'utf8', timeout: 10000, windowsHide: true });
  if (version.error || version.status !== 0 || version.stdout.trim() !== pinnedTypeScriptVersionText) {
    throw new Error('PSC2_CHECKED_TYPESCRIPT_PIN: require TypeScript 7.0.2');
  }
  await mkdir(path.dirname(output), { recursive: true });
  const staging = await mkdtemp(path.join(path.dirname(output), '.checked-stage-'));
  try {
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
    receipt.typeScriptSha256 = digest(typeScript);
    const [javaScript, declarations, sourceMap, hostSources] = await Promise.all([
      readFile(path.join(staging, stem + '.js')), readFile(path.join(staging, stem + '.d.ts')),
      readFile(path.join(staging, stem + '.js.map')), readCheckedBuildHostSources(),
    ]);
    const typeScriptCompilerBytes = typeScriptToolInputs.files.find(item => item.path === typeScriptToolInputs.details.entryPath).bytes;
    receipt.javaScriptSha256 = digest(javaScript);
    const observed = createCheckedBuildGraph({ sourceKind: snapshot.kind, sources: snapshot.sources,
      admissions, typeScript, javaScript, declarations, sourceMap, compilerBytes, sourceResources: snapshot.resourceObservation, seedResources,
      compilerKind: compilerIdentity.engine, typeScriptCompilerBytes, typeScriptToolInputs, outputStem: stem, irStages,
      provider: receipt.provider, providerSecurity: selectedProviderSecurity, kernelContract: kernelContractV1, providerToolInputs,
      hostSources, pscvCertificate, certifiedSourceArtifact, jsAbiPolicy, publicApi,
      runtime: { implementation: 'node', version: process.version, platform: process.platform, arch: process.arch } });
    const evidence = bindObservedBuildContext(observed, { languageAuthority, backendRegistry, backendId: 'typescript' });
    receipt.profileEnvironment = evidence.profileEnvironment.identity;
    receipt.buildActions = evidence.buildActions.map(item => item.action.identity);
    receipt.queryKeys = evidence.queryKeys.map(item => item.identity);
    receipt.backendDescriptor = evidence.backendDescriptor.identity;
    receipt.artifactBundle = evidence.artifactBundle.identity;
    receipt.claimSet = evidence.claimSet.identity;
    receipt.buildGraph = evidence.identity;
    if (evidence.runtimeInterface) receipt.runtimeInterface = evidence.runtimeInterface;
    if (evidence.publicApi) receipt.publicApi = evidence.publicApi.identity;
    if (evidence.jsAbi) {
      receipt.jsAbiPlan = evidence.jsAbi.plan.identity;
      receipt.jsAbiPolicy = evidence.jsAbi.policy.identity;
    }
    receipt.typeScriptToolInputs = evidence.typeScriptToolInputs;
    receipt.providerInputs = evidence.providerInputs;
    const archive = packObservedBuildArchive(evidence);
    receipt.buildArchive = archive.identity;
    if (!evidence.executableArtifact) throw new Error('PSC2_CHECKED_EXECUTABLE_ARTIFACT_MISSING');
    const envelope = createEvidenceEnvelope({
      executableArtifact: evidence.executableArtifact,
      pscvCert: pscvCertificate.identity,
      certifiedSource: certifiedSourceArtifact.identity,
      buildGraph: evidence.identity,
      buildArchive: archive.identity,
      runtimeInterface: evidence.runtimeInterface,
      targetAdapters: evidence.jsAbi ? [evidence.jsAbi.policy.identity, evidence.jsAbi.plan.identity] : [],
      providerInputs: evidence.providerInputs ?? [],
      typeScriptToolInputs: evidence.typeScriptToolInputs,
      sourceResources: snapshot.resourceObservation,
      seedResources,
    });
    receipt.evidenceEnvelope = envelope.identity;
    await writeFile(path.join(staging, stem + '.evidence-envelope.json'), envelope.bytes);
    if (evidence.jsAbi) {
      await writeFile(path.join(staging, stem + '.abi-plan.json'), evidence.jsAbi.plan.bytes);
      await writeFile(path.join(staging, stem + '.abi-policy.json'), evidence.jsAbi.policy.bytes);
    }
    await writeFile(path.join(staging, stem + '.pscv-cert.json'), pscvCertificate.bytes);
    await writeFile(path.join(staging, stem + '.certified-source.json'), certifiedSourceArtifact.bytes);
    await writeFile(path.join(staging, stem + '.build-archive.json'), archive.bytes);
    await writeFile(path.join(staging, stem + '.build-graph.json'), evidence.bytes);
    if (evidence.publicApi) await writeFile(path.join(staging, stem + '.public-api.json'), evidence.publicApi.bytes);
    await writeFile(path.join(staging, stem + '.profile-environment.json'), evidence.profileEnvironment.bytes);
    await writeFile(path.join(staging, stem + '.backend-descriptor.json'), evidence.backendDescriptor.bytes);
    await writeFile(path.join(staging, stem + '.artifact-bundle.json'), evidence.artifactBundle.bytes);
    await writeFile(path.join(staging, stem + '.claim-set.json'), evidence.claimSet.bytes);
    await writeFile(path.join(staging, stem + '.admissions.json'), admissions);
    const outputSuffixes = ['.ts', '.js', '.d.ts', '.js.map', '.admissions.json', '.pscv-cert.json', '.certified-source.json', '.build-graph.json', '.build-archive.json', '.evidence-envelope.json'];
    outputSuffixes.push('.profile-environment.json', '.backend-descriptor.json', '.artifact-bundle.json', '.claim-set.json');
    if (evidence.jsAbi) outputSuffixes.push('.abi-plan.json', '.abi-policy.json');
    for (const suffix of outputSuffixes) {
      await rename(path.join(staging, stem + suffix), path.join(path.dirname(output), stem + suffix));
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
    else if (['--out', '--compiler', '--seed', '--kernel', '--dual-check', '--security-profile', '--js-abi-policy'].includes(flag)) {
      const value = args.shift();
      if (!value || value.startsWith('--')) throw new Error(`Missing value for ${flag}`);
      options[{ '--out': 'outputPath', '--compiler': 'compilerPath', '--seed': 'seedPath', '--kernel': 'kernel', '--dual-check': 'dualCheck', '--security-profile': 'securityProfile', '--js-abi-policy': 'jsAbiPolicyPath' }[flag]] = value;
    } else throw new Error(`Unknown checked-build option: ${flag}`);
  }
  if (!entryPath) {
    throw new Error('usage: checked-build.mjs <entry> [--check | --out file.js] [--compiler file.js | --seed binary] [--kernel lean434|lean434-wasm|pskernel-core|pskernel-core.old3] [--dual-check pskernel-core|lean434|lean434-wasm] [--security-profile development-v1|compatibility-v1|paranoid-v1] [--js-abi-policy policy.json]');
  }
  const receipt = await buildChecked(options);
  console.log('PSC2_CHECKED_BUILD: PASS ' + JSON.stringify(receipt));
}
