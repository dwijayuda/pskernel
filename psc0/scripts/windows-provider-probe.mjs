// Windows artifact discovery and clean-runner checks only; not a release manifest.
// The provider implementation is built unchanged from the source pinned below.
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { copyFileSync, existsSync, mkdirSync, readFileSync, readdirSync, realpathSync, statSync, writeFileSync } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const sourceRef = '963030dc2d154008fccc82e7c8ed29331f138799';
const sourceTree = '38c8c55bd2b214753e56c58c15c4901c32c01b86';
const identity = Object.freeze({
  protocol: 'pskernel-core/1', provider: 'pskernel-core-native',
  leanVersion: '4.34.0', leanCommit: '293d5d0c0c3f3dded4688b3ccd6a33939ac5102b',
  profile: 'lean4.34-core',
});
const archive = Object.freeze({
  assetId: 563514503,
  url: 'https://github.com/leanprover/lean4/releases/download/v4.34.0/lean-4.34.0-windows.zip',
  sha256: 'd382797e1abb1becd1b22593c059c223bf0698f6593bb9cdeddbf7fe23f54ca0',
  bytes: 850488083,
});
// OS facilities, not "every DLL found somewhere in System32". In particular,
// Visual C++ redistributables and Lean/LLVM/MinGW runtime DLLs are not exempt.
const systemDlls = new Set([
  'advapi32.dll', 'bcrypt.dll', 'bcryptprimitives.dll', 'cabinet.dll',
  'combase.dll', 'comctl32.dll', 'comdlg32.dll', 'crypt32.dll', 'cryptbase.dll',
  'dbghelp.dll', 'dnsapi.dll', 'gdi32.dll', 'icu.dll', 'imm32.dll',
  'iphlpapi.dll', 'kernel32.dll', 'kernelbase.dll', 'msvcrt.dll', 'ncrypt.dll',
  'netapi32.dll', 'normaliz.dll', 'ntdll.dll', 'ole32.dll', 'oleaut32.dll',
  'powrprof.dll', 'profapi.dll', 'psapi.dll', 'rpcrt4.dll', 'secur32.dll',
  'setupapi.dll', 'shell32.dll', 'shlwapi.dll', 'ucrtbase.dll', 'user32.dll',
  'userenv.dll', 'version.dll', 'winhttp.dll', 'winmm.dll', 'wintrust.dll',
  'ws2_32.dll', 'wtsapi32.dll',
]);
const sha256 = bytes => createHash('sha256').update(bytes).digest('hex');
const writeJson = (file, value) => writeFileSync(file, JSON.stringify(value, null, 2) + '\n');
const runner = () => ({
  platform: process.platform, architecture: process.arch, osRelease: os.release(),
  osVersion: os.version(), node: process.version,
  imageOS: process.env.ImageOS ?? null, imageVersion: process.env.ImageVersion ?? null,
  runId: process.env.GITHUB_RUN_ID ?? null, runAttempt: process.env.GITHUB_RUN_ATTEMPT ?? null,
  workflowCommit: process.env.GITHUB_SHA ?? null,
});
assert.equal(process.platform, 'win32');
assert.equal(process.arch, 'x64');

function peHeader(bytes) {
  assert(bytes.length > 256 && bytes.readUInt16LE(0) === 0x5a4d, 'Expected PE MZ header');
  const offset = bytes.readUInt32LE(0x3c);
  assert(offset + 26 <= bytes.length && bytes.readUInt32LE(offset) === 0x00004550, 'Expected PE signature');
  assert.equal(bytes.readUInt16LE(offset + 4), 0x8664, 'Expected AMD64 PE');
  assert.equal(bytes.readUInt16LE(offset + 24), 0x20b, 'Expected PE32+');
  return { machine: 'AMD64', format: 'PE32+', coffTimeDateStamp: bytes.readUInt32LE(offset + 8) };
}
function identityCheck(response) {
  for (const [key, expected] of Object.entries(identity)) assert.equal(response[key], expected, key);
}
function cleanEnvironment() {
  const systemRoot = process.env.SystemRoot;
  assert(systemRoot && path.isAbsolute(systemRoot), 'Missing Windows SystemRoot');
  return {
    SystemRoot: systemRoot, WINDIR: systemRoot,
    SystemDrive: process.env.SystemDrive ?? path.parse(systemRoot).root.replace(/\\$/, ''),
    TEMP: process.env.TEMP, TMP: process.env.TMP,
    PATH: path.join(systemRoot, 'System32'),
  };
}

function collect(providerDirectory, toolchainDirectory, outputDirectory, readobjPath) {
  const provider = realpathSync(providerDirectory);
  const toolchain = realpathSync(toolchainDirectory);
  const output = path.resolve(outputDirectory);
  const payload = path.join(output, 'payload');
  const evidence = path.join(output, 'evidence');
  assert(!existsSync(output), 'Refuse to reuse a candidate output directory');
  mkdirSync(payload, { recursive: true });
  mkdirSync(evidence);
  const native = path.join(provider, 'psc0', '.lake', 'build', 'bin', 'psc_kernel_core_provider.exe');
  assert(statSync(native).isFile());
  const dllCandidates = new Map();
  function indexDlls(directory) {
    if (!existsSync(directory)) return;
    for (const entry of readdirSync(directory, { withFileTypes: true })) {
      const file = path.join(directory, entry.name);
      if (entry.isDirectory()) indexDlls(file);
      else if (entry.isFile() && /\.dll$/i.test(entry.name)) {
        const key = entry.name.toLowerCase();
        const candidates = dllCandidates.get(key) ?? [];
        candidates.push(file);
        dllCandidates.set(key, candidates);
      }
    }
  }
  indexDlls(path.join(toolchain, 'bin'));
  indexDlls(path.join(toolchain, 'lib'));
  indexDlls(path.dirname(native));
  const queue = [native], seen = new Set(), files = [], systemImports = new Map();
  for (let next = 0; next < queue.length; next++) {
    const file = queue[next], name = path.basename(file), key = name.toLowerCase();
    if (seen.has(key)) continue;
    seen.add(key);
    const bytes = readFileSync(file);
    const header = peHeader(bytes);
    const inspected = spawnSync(readobjPath, ['--file-headers', '--coff-imports', file], {
      encoding: 'utf8', timeout: 60000, windowsHide: true, maxBuffer: 16 * 1024 * 1024,
    });
    assert.ifError(inspected.error);
    assert.equal(inspected.status, 0, inspected.stderr);
    writeFileSync(path.join(evidence, name + '.llvm-readobj.txt'), inspected.stdout);
    const imports = [...inspected.stdout.matchAll(/^(?:Import|DelayImport) \{\r?\n\s+Name: ([^\r\n]+)$/gm)]
      .map(match => match[1].trim()).sort();
    assert(imports.length > 0, 'No imports decoded for ' + name);
    for (const imported of imports) {
      assert.equal(path.basename(imported), imported, 'Unexpected DLL path');
      const lowered = imported.toLowerCase();
      const apiSet = /^(api|ext)-ms-win-.*\.dll$/.test(lowered);
      if (apiSet || systemDlls.has(lowered)) {
        const systemPath = path.join(process.env.SystemRoot, 'System32', imported);
        if (!apiSet) assert(existsSync(systemPath), 'Missing expected OS DLL ' + imported);
        systemImports.set(lowered, {
          name: imported, kind: apiSet ? 'windows-api-set' : 'windows-os',
          buildHostSha256: existsSync(systemPath) ? sha256(readFileSync(systemPath)) : null,
        });
        continue;
      }
      const candidates = dllCandidates.get(lowered) ?? [];
      assert(candidates.length > 0, 'Unresolved non-system DLL ' + imported);
      const digests = new Set(candidates.map(candidate => sha256(readFileSync(candidate))));
      assert.equal(digests.size, 1, 'Ambiguous runtime DLL bytes for ' + imported);
      queue.push(candidates[0]);
    }
    copyFileSync(file, path.join(payload, name));
    files.push({
      name, sha256: sha256(bytes), bytes: bytes.length, ...header, imports,
      origin: file.startsWith(toolchain + path.sep)
        ? { kind: 'official-lean-toolchain', path: path.relative(toolchain, file).replaceAll('\\', '/') }
        : { kind: 'pinned-provider-build', path: path.relative(provider, file).replaceAll('\\', '/') },
    });
  }
  files.sort((a, b) => a.name.localeCompare(b.name));
  const licenseFiles = [];
  for (const entry of readdirSync(toolchain, { withFileTypes: true })) {
    if (entry.isFile() && /^(LICENSE|COPYING|NOTICE)/i.test(entry.name)) {
      mkdirSync(path.join(output, 'licenses'), { recursive: true });
      copyFileSync(path.join(toolchain, entry.name), path.join(output, 'licenses', entry.name));
      licenseFiles.push({ name: entry.name, sha256: sha256(readFileSync(path.join(toolchain, entry.name))) });
    }
  }
  const manifest = {
    schema: 1, kind: 'psc0-windows-native-provider-candidate',
    claim: 'Artifact discovery only; fresh-runner native smoke and final installed-package qualification are separate evidence.',
    sourceRef, sourceTree, buildTarget: 'psc_kernel_core_provider', toolchainArchive: archive,
    identity, executable: 'psc_kernel_core_provider.exe', files,
    systemImports: [...systemImports.values()].sort((a, b) => a.name.localeCompare(b.name)),
    licenseFiles, runner: runner(), releaseQualified: false, rebuildReproducibilityProved: false,
    compilerSemanticPreservationProved: false, logicalConsistencyProved: false,
  };
  writeJson(path.join(output, 'probe-manifest.json'), manifest);
  copyFileSync(fileURLToPath(import.meta.url), path.join(output, 'windows-provider-probe.mjs'));
  console.log(JSON.stringify(manifest, null, 2));
}

function verify(candidateDirectory, evidenceDirectory) {
  const candidate = realpathSync(candidateDirectory);
  const manifestBytes = readFileSync(path.join(candidate, 'probe-manifest.json'));
  const manifest = JSON.parse(manifestBytes);
  assert.equal(manifest.kind, 'psc0-windows-native-provider-candidate');
  assert.equal(manifest.sourceRef, sourceRef);
  assert.equal(manifest.sourceTree, sourceTree);
  assert.deepEqual(manifest.identity, identity);
  assert.equal(manifest.releaseQualified, false);
  const payload = path.join(candidate, 'payload');
  const native = path.join(payload, manifest.executable);
  assert.equal(manifest.executable, 'psc_kernel_core_provider.exe');
  function authenticate() {
    assert.deepEqual(readdirSync(payload).sort(), manifest.files.map(file => file.name).sort());
    for (const file of manifest.files) {
      assert.equal(path.basename(file.name), file.name);
      const bytes = readFileSync(path.join(payload, file.name));
      assert.equal(sha256(bytes), file.sha256, file.name);
      assert.equal(bytes.length, file.bytes, file.name);
      peHeader(bytes);
    }
  }
  const env = cleanEnvironment(), observations = [];
  function call(label, args, input, expected) {
    authenticate();
    const started = Date.now();
    const result = spawnSync(native, args, {
      input, encoding: 'utf8', cwd: payload, env, windowsHide: true,
      timeout: 60000, killSignal: 'SIGKILL', maxBuffer: 16 * 1024 * 1024,
    });
    assert.ifError(result.error);
    assert.equal(result.status, 0, label + ': ' + result.stderr);
    const response = JSON.parse(result.stdout.trim());
    identityCheck(response);
    for (const [key, value] of Object.entries(expected)) assert.equal(response[key], value, label + ': ' + key);
    authenticate();
    observations.push({
      label, args, inputSha256: input === undefined ? null : sha256(input),
      response, stdoutSha256: sha256(result.stdout), stderr: result.stderr,
      elapsedMs: Date.now() - started,
    });
  }
  const envelope = admissions => JSON.stringify({ format: 'proofscript-checked-admissions', version: 2, admissions });
  const name = value => ({ k: 's', p: { k: 'a' }, v: value });
  const declaration = (n, t, v) => ({
    kind: 'constant', declaration: { k: 'definition', n: name(n), lp: [], t, v, s: 'safe', h: { k: 'regular', h: '0' } },
  });
  call('native identity', ['--version'], undefined, { status: 'ready' });
  call('native health', ['--health'], undefined, { status: 'ready' });
  call('fresh prelude and empty admissions', ['--check'], envelope([]), { accepted: true });
  call('valid Nat definition', ['--check'], envelope([
    declaration('WindowsProbeAnswer', { k: 'const', n: name('Nat'), ls: [] }, { k: 'nat', v: '42' }),
  ]), { accepted: true });
  call('ill-typed definition rejected', ['--check'], envelope([
    declaration('WindowsProbeInvalid', { k: 'sort', l: { k: 'z' } }, { k: 'sort', l: { k: 'z' } }),
  ]), { accepted: false, errorKind: 'kernel-rejection' });
  call('wrong canonical protocol rejected', ['--check'],
    JSON.stringify({ format: 'proofscript-checked-admissions', version: 1, admissions: [] }),
    { accepted: false, errorKind: 'protocol-version' });
  call('fresh acceptance after rejection', ['--check'], envelope([]), { accepted: true });
  mkdirSync(evidenceDirectory, { recursive: true });
  const evidence = {
    schema: 1, kind: 'psc0-windows-native-provider-clean-runner',
    candidateManifestSha256: sha256(manifestBytes), sourceRef, sourceTree,
    executableSha256: manifest.files.find(file => file.name === manifest.executable).sha256,
    payloadFiles: manifest.files.map(({ name, sha256, bytes }) => ({ name, sha256, bytes })),
    identity, runner: runner(), executionPath: env.PATH, executionCwd: payload,
    leanInstalledByThisJob: false, sourceCheckedOutByThisJob: false,
    observations, allObservationsPassed: true, releaseQualified: false,
    limits: [
      'Static and delay-import closure plus exercised protocol paths; no theorem about arbitrary dynamic loading.',
      'Windows Server 2022 x64 runner evidence; no universal Windows-version compatibility claim.',
      'Candidate byte authentication and native smoke only; final package and Node-version tests are separate.',
      'No compiler, bootstrap, metatheory, or logical-consistency proof is added.',
    ],
  };
  writeJson(path.join(evidenceDirectory, 'clean-runner.json'), evidence);
  console.log(JSON.stringify(evidence, null, 2));
}

const [mode, ...args] = process.argv.slice(2);
if (mode === 'collect') {
  assert.equal(args.length, 4, 'collect PROVIDER_ROOT TOOLCHAIN_ROOT CANDIDATE_ROOT LLVM_READOBJ');
  collect(...args);
} else if (mode === 'verify') {
  assert.equal(args.length, 2, 'verify CANDIDATE_ROOT EVIDENCE_ROOT');
  verify(...args);
} else throw new Error('Expected collect or verify');
