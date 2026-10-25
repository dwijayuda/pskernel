// Installed host API. Reuses the existing checked session; no compiler semantics here.
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { createGeneratedJsCompilerSession } from '../host-tools/generated-compiler-session.mjs';
import { compilerSourceClosureDigest } from '../host-tools/compiler-host-protocol.mjs';
import {
  installationRoot,
  loadDistribution,
  resolveEngine,
  resolveKernel,
  resolveCheckedTarget,
  commonPins,
  checkInstalledAdmissions,
  describeInstallation,
  kernelHandle,
  hash,
} from '../host-tools/installed-engine-resolver.mjs';
import {readPublication as readPublishedGeneration} from '../host-tools/transactional-publication.mjs';
const fail = (message) => {
  throw Error('PSC1_UNIVERSAL_' + message);
};
const clone = (value) => JSON.parse(JSON.stringify(value));
// Capture a private source snapshot before creating any compiler/checker session.
// Checked targets stay closed even though the separate candidate API has more emitters.
function selection(options = {}) {
  if (!options || typeof options !== 'object' || Array.isArray(options)) fail('OPTIONS');
  const engine = options.engine || 'js',
    kernel = options.kernel || 'wasm',
    assurance = options.assurance || 'checked',
    outputAbi = options.outputAbi ?? 'scalar',
    target = options.target ?? 'js',
    publicationProtocol = options.publicationProtocol ?? 'legacy-symlink';
  if (!['checked', 'ordinary-checked'].includes(assurance)) fail('ASSURANCE');
  if (!['scalar', 'io-dispatcher'].includes(outputAbi)) fail('OUTPUT_ABI');
  if (!['wasm', 'native', 'both'].includes(kernel)) fail('KERNEL');
  if (!['js','ts','wasm-core'].includes(target)) fail('CHECKED_TARGET_UNSUPPORTED');
  if (!['legacy-symlink','portable-file'].includes(publicationProtocol)) fail('PUBLICATION_PROTOCOL');
  const sources = clone(options.sources);
  compilerSourceClosureDigest(sources);
  if (
    typeof options.entryModule !== 'string' ||
    !sources.some((s) => s.module === options.entryModule)
  )
    fail('ENTRY');
  return { engine, kernel, assurance, outputAbi, target, publicationProtocol, sources, entryModule: options.entryModule };
}
// Only the installed host composes tool paths, pins and independent checkers.
// Source/project/wire data never supplies these capabilities.
function sessionFor(selected, publicationRoot) {
  const d = loadDistribution(),
    engine = resolveEngine(selected.engine, d),
    providers = selected.kernel === 'both' ? ['wasm', 'native'] : [selected.kernel];
  const deps = [...engine.pins, ...commonPins(d)];
  for (const provider of providers) deps.push(...resolveKernel(provider, d).pins);
  const script = path.join(
    installationRoot,
    'npm-cli/universal-' + (selected.kernel === 'native' ? 'native' : 'wasm') + '-checker.mjs',
  );
  const scriptSha = hash(fs.readFileSync(script));
  const extra =
    selected.kernel === 'both'
      ? [
          {
            name: 'native',
            scriptFile: path.join(installationRoot, 'npm-cli/universal-native-checker.mjs'),
            scriptSha256: hash(
              fs.readFileSync(path.join(installationRoot, 'npm-cli/universal-native-checker.mjs')),
            ),
          },
        ]
      : [];
  return createGeneratedJsCompilerSession({
    requestId: 'installed-' + crypto.randomUUID(),
    sources: selected.sources,
    entryModule: selected.entryModule,
    assurance: selected.assurance,
    outputAbi: selected.outputAbi,
    target: selected.target,
    publicationProtocol: selected.publicationProtocol,
    serviceKind: selected.target==='js'?'js-adapter':(engine.candidateKind==='embedded'?'unified-embedded':'unified-bundle'),
    ...resolveCheckedTarget(selected.target,d),
    serviceFile: selected.target==='js'?engine.service.path:engine.candidate.path,
    serviceSha256: selected.target==='js'?engine.service.sha256:engine.candidate.sha256,
    runnerFile: path.join(installationRoot,selected.target==='js'?'scripts/generated-compiler-runner.mjs':'scripts/universal-candidate-runner.mjs'),
    runnerSha256: selected.target==='js'?d.runner.sha256:d.hostFiles.find(row=>row.path==='scripts/universal-candidate-runner.mjs').sha256,
    checkerExecutable: process.execPath,
    checkerSha256: hash(fs.readFileSync(process.execPath)),
    checkerScriptFile: script,
    checkerScriptSha256: scriptSha,
    publicationRoot,
    serviceDependencies: [...new Map(deps.map((p) => [p.path, p])).values()],
    additionalCheckers: extra,
  });
}
export function getCompilerMetadata() {
  return describeInstallation();
}
export async function checkCanonicalAdmissions(source, { provider = 'wasm' } = {}) {
  return checkInstalledAdmissions(source, provider);
}
// Execute the complete checked session, then return the sealed JS bytes.
// Temporary staging is always removed; this API does not publish a generation.
export function compile(options) {
  const selected = selection(options),
    temporary = fs.mkdtempSync(path.join(os.tmpdir(), 'proofscript-checked-'));
  try {
    const session = sessionFor(selected, path.join(temporary, 'store')),
      receipt = session.execute();
    const sourceFile=selected.target==='ts'?'target.ts':selected.target==='wasm-core'?'target.wasm.hex':'target.mjs';
    const source = fs.readFileSync(path.join(session.stagingDirectory, sourceFile), 'utf8');
    if (hash(source) !== receipt.sourceSha256) fail('CHECKED_SOURCE_CHANGED');
    return Object.freeze({
      status: 'accepted',
      engine: selected.engine,
      target: selected.target,
      outputAbi: selected.outputAbi,
      kernelProviders: selected.kernel === 'both' ? ['wasm', 'native'] : [selected.kernel],
      compilerSourceClosureDigest: loadDistribution().compilerSourceClosureDigest,
      source,
      receipt,
      logicalAdmission: 'accepted',
      irValidation: 'original-and-transformed-by-pinned-compiler',
      publication: 'not-requested',
      formalPreservation: 'not-provided',
    });
  } finally {
    fs.rmSync(temporary, { recursive: true, force: true });
  }
}
export function build(options) {
  // Preserve Linux directory-fsync/symlink commit guarantees. Other platforms use compile().
  if (process.platform !== 'linux')
    fail('PUBLICATION_PLATFORM_UNQUALIFIED: use the checked compile API or compile stdout command');
  if (typeof options?.out !== 'string' || !options.out) fail('OUTPUT_DIRECTORY');
  const selected = selection(options),
    session = sessionFor(selected, path.resolve(options.out)),
    receipt = session.execute(),
    published = session.publish();
  return Object.freeze({
    status: 'accepted',
    engine: selected.engine,
    target: selected.target,
    outputAbi: selected.outputAbi,
    kernelProviders: selected.kernel === 'both' ? ['wasm', 'native'] : [selected.kernel],
    compilerSourceClosureDigest: loadDistribution().compilerSourceClosureDigest,
    logicalAdmission: 'accepted',
    sourceClosureDigest: receipt.sourceClosureDigest,
    artifact: published.immutableTarget,
    runtimeArtifact: published.runtimeTarget,
    publicationProtocol: selected.publicationProtocol,
    durability: published.durability,
    generation: published.generation,
    manifestSha256: published.manifestSha256,
    receipt,
    formalPreservation: 'not-provided',
  });
}
export function readPublication({out,publicationProtocol='legacy-symlink'}) {
  if(typeof out!=='string'||!out)fail('OUTPUT_DIRECTORY');
  return readPublishedGeneration(path.resolve(out),publicationProtocol);
}
export function compileCandidate(options) {
  // Explicit low-level candidate API. It never admits proofs or publishes files.
  if (!options || !['js', 'ts', 'rust', 'wasm-core'].includes(options.target))
    fail('CANDIDATE_TARGET');
  const d = loadDistribution(),
    engine = resolveEngine(options.engine || 'js', d),
    sources = clone(options.sources),
    digest = compilerSourceClosureDigest(sources);
  const assurance = options.assurance || 'checked';
  const outputAbi = options.outputAbi ?? 'scalar';
  if (!['scalar', 'io-dispatcher'].includes(outputAbi)) fail('OUTPUT_ABI');
  if (!['checked', 'ordinary-checked'].includes(assurance)) fail('ASSURANCE');
  if (
    !sources.every((s) => s.kind === sources[0].kind) ||
    !sources.some((s) => s.module === options.entryModule)
  )
    fail('SOURCE_CAPTURE');
  const inner = [
    outputAbi === 'scalar' ? 'psc1-compiler-service/1' : 'psc1-compiler-service/2',
    'candidate-' + crypto.randomUUID(),
    digest,
    sources[0].kind,
    assurance,
    options.entryModule,
    sources.map((s) => [s.module, s.text]),
    ...(outputAbi === 'scalar' ? [] : ['io-dispatcher']),
  ];
  const request = JSON.stringify(['psc1-unified-compiler-service/2', options.target, inner]);
  if (Buffer.byteLength(request) > 128 * 1024 * 1024) fail('REQUEST_LIMIT');
  const verify = () =>
    engine.pins.forEach((p) => {
      const stat = fs.lstatSync(p.path);
      if (!stat.isFile() || stat.isSymbolicLink() || hash(fs.readFileSync(p.path)) !== p.sha256)
        fail('CANDIDATE_RESOURCE_CHANGED');
    });
  const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'proofscript-candidate-'));
  try {
    const input = path.join(temp, 'request.json'),
      output = path.join(temp, 'response.json');
    fs.writeFileSync(input, request);
    verify();
    const ran = spawnSync(
      process.execPath,
      [
        path.join(installationRoot, 'scripts/universal-candidate-runner.mjs'),
        engine.candidate.path,
        engine.candidate.sha256,
        engine.candidateKind,
        input,
        output,
      ],
      {
        encoding: 'utf8',
        timeout: 240000,
        maxBuffer: 32 * 1024 * 1024,
        killSignal: 'SIGKILL',
        windowsHide: true,
      },
    );
    verify();
    if (ran.error || ran.status !== 0)
      fail('CANDIDATE_PROCESS: ' + (ran.error?.message || ran.stderr));
    if (hash(fs.readFileSync(input)) !== hash(request)) fail('CANDIDATE_REQUEST_CHANGED');
    const stat = fs.lstatSync(output);
    if (!stat.isFile() || stat.isSymbolicLink() || stat.size > 128 * 1024 * 1024)
      fail('CANDIDATE_RESPONSE_LIMIT');
    const candidate = JSON.parse(fs.readFileSync(output, 'utf8'));
    return Object.freeze({
      status: 'candidate-only',
      engine: options.engine || 'js',
      target: options.target,
      compilerSourceClosureDigest: d.compilerSourceClosureDigest,
      candidate,
      logicalAdmission: 'not-run',
      publicationAuthority: false,
    });
  } finally {
    fs.rmSync(temp, { recursive: true, force: true });
  }
}

export async function createIndependentKernelToolchain({
  root = installationRoot,
  provider = 'wasm',
} = {}) {
  if (path.resolve(root) !== installationRoot) fail('KERNEL_ROOT');
  if (!['wasm', 'native', 'both'].includes(provider)) fail('KERNEL');
  for (const key of provider === 'both' ? ['wasm', 'native'] : [provider]) {
    const { verify } = await kernelHandle(key);
    verify();
  }
  return Object.freeze({
    metadata: Object.freeze({
      schema: 'psc1-independent-kernel-toolchain/1',
      provider,
      leanVersion: '4.35.0',
      leanCommit: loadDistribution().leanCommit,
      canonicalAdmissionsVersion: 2,
      wasmMemoryModel: 'linear',
    }),
    async checkCanonicalAdmissions(source) {
      const result = await checkInstalledAdmissions(source, provider);
      return Object.freeze({
        ...result,
        schema: 'psc1-independent-kernel-toolchain-result/1',
        scope: 'independent canonical admission only; not compiler semantic preservation',
      });
    },
  });
}
