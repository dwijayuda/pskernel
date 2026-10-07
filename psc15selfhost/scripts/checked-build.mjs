import { readFile, writeFile, mkdir, mkdtemp, rename, rm } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { readCheckedSourceSnapshot } from './checked-source-snapshot.mjs';
import { createCheckedCompilerService } from './compiler-checked-service.mjs';
import { createCheckedBuildGraph, readCheckedBuildHostSources } from './checked-build-evidence.mjs';
import { packObservedBuildArchive } from './observed-build-archive.mjs';
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
}) {
  const kernelDescriptor = checkedKernelDescriptor(kernel);
  const selectedProviderSecurity = assertProviderSecurity(kernel, securityProfile);
  const secondaryProviderSecurity = dualCheck
    ? assertProviderSecurity(dualCheck, securityProfile)
    : undefined;
  if (dualCheck) checkedKernelDescriptor(dualCheck);
  if (compilerPath && seedPath) throw new Error('PSC2_CHECKED_SELECT_ONE_COMPILER');
  if (!checkOnly && !outputPath) throw new Error('PSC2_CHECKED_OUTPUT_REQUIRED');
  const snapshot = await readCheckedSourceSnapshot(entryPath, sourceResourceLimits);
  let admissions;
  let typeScript;
  let compilerIdentity;
  let compilerBytes;
  let irStages;
  let parity;
  let providerToolInputs = [];
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
    });
    admissions = result.admissions;
    typeScript = result.typeScript;
    irStages = result.stages;
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
    if (!checkOnly) {
      const emitted = session.emitArtifact(handle);
      typeScript = emitted.payload;
      irStages = emitted.stages;
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
    canonicalAdmissionsSha256: digest(admissions),
    providerInputObservations: providerToolInputs.map(item => item.details),
    ...(parity ? { dualCheck: parity } : {}),
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
    const evidence = createCheckedBuildGraph({ sourceKind: snapshot.kind, sources: snapshot.sources,
      admissions, typeScript, javaScript, declarations, sourceMap, compilerBytes, sourceResources: snapshot.resourceObservation,
      compilerKind: compilerIdentity.engine, typeScriptCompilerBytes, typeScriptToolInputs, outputStem: stem, irStages,
      provider: receipt.provider, providerSecurity: selectedProviderSecurity, kernelContract: kernelContractV1, providerToolInputs,
      hostSources, runtime: { implementation: 'node', version: process.version, platform: process.platform, arch: process.arch } });
    receipt.buildGraph = evidence.identity;
    receipt.typeScriptToolInputs = evidence.typeScriptToolInputs;
    receipt.providerInputs = evidence.providerInputs;
    const archive = packObservedBuildArchive(evidence);
    receipt.buildArchive = archive.identity;
    await writeFile(path.join(staging, stem + '.build-archive.json'), archive.bytes);
    await writeFile(path.join(staging, stem + '.build-graph.json'), evidence.bytes);
    await writeFile(path.join(staging, stem + '.admissions.json'), admissions);
    for (const suffix of ['.ts', '.js', '.d.ts', '.js.map', '.admissions.json', '.build-graph.json', '.build-archive.json']) {
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
    else if (['--out', '--compiler', '--seed', '--kernel', '--dual-check', '--security-profile'].includes(flag)) {
      const value = args.shift();
      if (!value || value.startsWith('--')) throw new Error(`Missing value for ${flag}`);
      options[{ '--out': 'outputPath', '--compiler': 'compilerPath', '--seed': 'seedPath', '--kernel': 'kernel', '--dual-check': 'dualCheck', '--security-profile': 'securityProfile' }[flag]] = value;
    } else throw new Error(`Unknown checked-build option: ${flag}`);
  }
  if (!entryPath) {
    throw new Error('usage: checked-build.mjs <entry> [--check | --out file.js] [--compiler file.js | --seed binary] [--kernel lean434|lean434-wasm|pskernel-core|pskernel-core.old3] [--dual-check pskernel-core|lean434|lean434-wasm] [--security-profile development-v1|compatibility-v1|paranoid-v1]');
  }
  const receipt = await buildChecked(options);
  console.log('PSC2_CHECKED_BUILD: PASS ' + JSON.stringify(receipt));
}
