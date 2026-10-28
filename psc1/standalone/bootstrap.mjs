// One-time Linux bootstrap and CI isolation harness. Never shipped as a development dependency.
// Every compiler/kernel payload is reused from a qualified, hash-pinned .13 artifact.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { spawnSync } from 'node:child_process';
import { readQualifiedArtifact, sha256 } from '../scripts/kernel435-qualified-artifact.mjs';
import { createLosslessSourceTool, createSourceOwnershipTool,
  createCheckedSourceConverter } from '../host-tools/source-refactoring.mjs';
import { readOwnedCompilerSources } from '../host-tools/compiler-source-inputs.mjs';
import { compilerSourceClosureDigest } from '../host-tools/compiler-host-protocol.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
process.chdir(root);
const args = process.argv.slice(2), mode = args.shift() ?? 'assemble';
const outputRoot = path.resolve('dist/independent-development');
const encoded = value => JSON.stringify(value, null, 2) + '\n';
const read = file => JSON.parse(fs.readFileSync(file, 'utf8'));
const put = (file, data) => { fs.mkdirSync(path.dirname(file), { recursive: true }); fs.writeFileSync(file, data); };
const requireLinux = () => {
  assert.equal(process.platform, 'linux'); assert.equal(process.arch, 'x64');
  assert.equal(process.versions.node, '22.23.3');
};
function run(executable, argv, options = {}) {
  const result = spawnSync(executable, argv, { encoding: 'utf8', timeout: 240000,
    maxBuffer: 256 * 1024 * 1024, ...options });
  assert.equal(result.error, undefined, String(result.error));
  assert.equal(result.status, 0, String(result.stdout) + String(result.stderr));
  return result.stdout;
}
function files(directory, prefix = '') {
  return fs.readdirSync(path.join(directory, prefix)).sort().flatMap(name => {
    const relative = prefix ? prefix + '/' + name : name;
    const target = path.join(directory, relative), stat = fs.lstatSync(target);
    assert.ok(!stat.isSymbolicLink(), 'symlink is not a distribution input: ' + relative);
    if (stat.isDirectory()) return files(directory, relative);
    assert.ok(stat.isFile(), 'regular distribution file required: ' + relative);
    return [{ path: relative, bytes: stat.size, sha256: sha256(fs.readFileSync(target)) }];
  });
}
function option(name) {
  const index = args.indexOf(name);
  assert.ok(index >= 0 && args[index + 1] && !args[index + 1].startsWith('--'), name);
  return args[index + 1];
}
function copy(from, to, executable = false) {
  const stat = fs.lstatSync(from); assert.ok(stat.isFile() && !stat.isSymbolicLink(), from);
  put(to, fs.readFileSync(from)); fs.chmodSync(to, executable ? 0o755 : 0o644);
}
function findOne(directory, basename) {
  const matches = files(directory).filter(row => path.basename(row.path) === basename);
  assert.equal(matches.length, 1, basename);
  return path.join(directory, matches[0].path);
}
function unpackPinnedTar(archive, pin, destination) {
  const tar = findOne(archive, pin.tarball), bytes = fs.readFileSync(tar);
  assert.equal(bytes.length, pin.bytes); assert.equal(sha256(bytes), pin.sha256);
  const names = run('tar', ['tzf', tar]).split('\n').filter(Boolean);
  assert.ok(names.every(name => name.startsWith('package/') && !name.split('/').includes('..')));
  fs.mkdirSync(destination, { recursive: true });
  run('tar', ['xzf', tar, '-C', destination]);
  files(path.join(destination, 'package'));
  return path.join(destination, 'package');
}
async function fetchBytes(url) {
  const response = await fetch(url, { signal: AbortSignal.timeout(120000) });
  assert.equal(response.ok, true, 'upstream HTTP ' + response.status + ': ' + url);
  const bytes = Buffer.from(await response.arrayBuffer());
  assert.ok(bytes.length < 256 * 1024 * 1024); return bytes;
}
async function assemble() {
  requireLinux();
  assert.equal(args.length, 0);
  const destination = path.join(outputRoot, 'toolchain');
  assert.ok(!fs.existsSync(destination), 'fresh standalone output required');
  fs.mkdirSync(destination, { recursive: true });
  const sourceCommit = run('git', ['rev-parse', 'HEAD']).trim();
  assert.match(sourceCommit, /^[0-9a-f]{40}$/);
  run('git', ['diff', '--exit-code', '--', 'packages']);
  const receipt = read('docs/PSC1_NPM_UMBRELLA_QUALIFICATION_2026-10-27.json');
  assert.equal(receipt.status, 'qualified-linux-npm-umbrella-scope');
  const defaultInput = {
    run: 40509034127, job: 122205738648, artifact: 12736333322,
    commit: '892e1895b6be54f2fff4957a66b34d293c4105b8',
    zipSha256: '80a0082b533ca7f0f1280df4beb5e2f7678a376f97624f7e7ee7b58edf0cd594',
  };
  const optionalInput = {
    run: 40509034127, job: 122205738648, artifact: 12736781848,
    commit: '892e1895b6be54f2fff4957a66b34d293c4105b8',
    zipSha256: 'c88036b06889606bcc3bc4b9af2d888ccffe2d1330187e932e2602230d1e0eff',
  };
  const compilerPin = { tarball: 'proofscript-compiler-0.1.0-psc1.13.tgz', bytes: 3270363,
    sha256: '80027f4042c4b88b14ac6bf929f19522bc0d03a52e56cca05e01c2647104fedb' };
  const kernelPin = { tarball: 'proofscript-pskernel-lean-4.35.0-psc1.13.tgz', bytes: 6453041,
    sha256: '472eff8cf60b17bbb551d1ef1a331c417fd4833dccd86478a6ae5242fe20bbc7' };
  for (const pin of [compilerPin, kernelPin]) {
    const recorded = receipt.qualification.packages.find(row => row.tarball === pin.tarball);
    assert.ok(recorded); assert.equal(recorded.sha256, pin.sha256); assert.equal(recorded.bytes, pin.bytes);
  }
  const defaultArchive = await readQualifiedArtifact(defaultInput, path.join(outputRoot, 'input-default'));
  const optionalArchive = await readQualifiedArtifact(optionalInput, path.join(outputRoot, 'input-optional'));
  const compilerPackage = unpackPinnedTar(defaultArchive, compilerPin, path.join(outputRoot, 'unpacked-compiler'));
  const kernelPackage = unpackPinnedTar(optionalArchive, kernelPin, path.join(outputRoot, 'unpacked-kernel'));
  const implementation = path.join(compilerPackage, 'dist/implementation');
  const nativeRoot = path.join(kernelPackage, 'dist/implementation');
  const prebuilt = read(path.join(nativeRoot, 'PREBUILT_MANIFEST.json'));
  for (const [key, value] of Object.entries({
    protocol: 'pskernel-lean/1', provider: 'lean4-cpp', leanVersion: '4.35.0',
    leanCommit: 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc', profile: 'lean4.35-core',
  })) assert.equal(prebuilt[key], value, key);
  const native = prebuilt.targets['linux-x64'];
  assert.ok(native && /^[a-zA-Z0-9_./-]+$/.test(native.path) && !native.path.split('/').includes('..'));
  const nativeBinary = path.join(nativeRoot, native.path);
  assert.equal(fs.statSync(nativeBinary).size, native.size);
  assert.equal(sha256(fs.readFileSync(nativeBinary)), native.sha256);
  copy(path.join(implementation, 'selfhost/js/module.js'), path.join(destination, 'engine/compiler.mjs'));
  assert.equal(sha256(fs.readFileSync(path.join(destination, 'engine/compiler.mjs'))),
    'e7d9c7b6eb9ea22aaaecad2bbf21adcf9856a0518dba0079eb63e8db0d03a0aa', 'qualified frozen G3 JS seed');
  copy(nativeBinary, path.join(destination, 'kernel/checker'), true);
  const seed = await import(pathToFileURL(path.join(destination, 'engine/compiler.mjs')).href);
  const exports = ['psCompilerServiceCandidate', 'compileCandidate'].filter(name => typeof seed[name] === 'function');
  assert.equal(exports.length, 1, 'qualified compiler must expose one supported scalar facade');
  const exportName = exports[0];

  // The private Node executable is a distributed runtime, not a required installed SDK.
  // Verify against the exact official release archive over HTTPS; no signature claim.
  const nodeArchiveName = 'node-v22.23.3-linux-x64.tar.xz';
  const nodeBase = 'https://nodejs.org/dist/v22.23.3/';
  const sums = await fetchBytes(nodeBase + 'SHASUMS256.txt');
  const sumRow = sums.toString('utf8').split('\n').find(line => line.trim().endsWith('  ' + nodeArchiveName));
  assert.ok(sumRow); const nodeArchiveSha256 = sumRow.split(/\s+/)[0];
  assert.match(nodeArchiveSha256, /^[0-9a-f]{64}$/);
  const archiveBytes = await fetchBytes(nodeBase + nodeArchiveName);
  assert.equal(sha256(archiveBytes), nodeArchiveSha256);
  const archivePath = path.join(outputRoot, nodeArchiveName); put(archivePath, archiveBytes);
  const nodeBytes = run('tar', ['xOf', archivePath, 'node-v22.23.3-linux-x64/bin/node'], { encoding: null });
  assert.equal(sha256(nodeBytes), sha256(fs.readFileSync(process.execPath)), 'setup-node and official release executable differ');
  put(path.join(destination, 'libexec/psc-runtime'), nodeBytes);
  fs.chmodSync(path.join(destination, 'libexec/psc-runtime'), 0o755);
  put(path.join(destination, 'notices/NODE_LICENSE'),
    run('tar', ['xOf', archivePath, 'node-v22.23.3-linux-x64/LICENSE'], { encoding: null }));
  put(path.join(destination, 'notices/NODE_SHASUMS256.txt'), sums);
  for (const [label, directory] of [['PSC1', compilerPackage], ['KERNEL', kernelPackage]]) {
    for (const name of ['LICENSE', 'NOTICE']) {
      const candidate = path.join(directory, name);
      assert.ok(fs.existsSync(candidate), label + ' ' + name);
      copy(candidate, path.join(destination, 'notices', label + '_' + name));
    }
  }
  const leanLicense = path.join(nativeRoot, 'LEAN_LICENSE');
  assert.ok(fs.existsSync(leanLicense)); copy(leanLicense, path.join(destination, 'notices/LEAN_LICENSE'));
  copy(path.join(nativeRoot, 'PREBUILT_MANIFEST.json'), path.join(destination, 'metadata/KERNEL_PREBUILT_MANIFEST.json'));
  copy(path.join(implementation, 'UNIVERSAL_DISTRIBUTION.json'),
    path.join(destination, 'metadata/FROZEN_COMPILER_DISTRIBUTION.json'));
  for (const relative of [
    'standalone/host.mjs', 'standalone/runner.mjs', 'standalone/qualification.mjs',
    'host-tools/compiler-host-protocol.mjs', 'host-tools/runtime-policy.mjs',
    'host-tools/contracts/compiler-closure.mjs',
  ]) copy(path.join(root, relative), path.join(destination, relative));
  const parameter = '$' + '{0%/*}';
  put(path.join(destination, 'bin/psc'), [
    '#!/bin/sh', 'set -eu',
    'unset NODE_OPTIONS NODE_PATH ENV BASH_ENV LD_PRELOAD LD_LIBRARY_PATH OPENSSL_CONF OPENSSL_MODULES',
    'case "$0" in */*) psc_dir=' + parameter + ' ;; *) psc_dir=. ;; esac',
    'psc_root=$(CDPATH= cd -- "$psc_dir/.." && pwd -P)',
    'exec "$psc_root/libexec/psc-runtime" --max-old-space-size=4096 "$psc_root/standalone/host.mjs" "$@"', '',
  ].join('\n'));
  fs.chmodSync(path.join(destination, 'bin/psc'), 0o755);

  // Existing independently checked source-conversion API is used once during bootstrap.
  // Subsequent edits/rebuilds consume only the delivered .ps project.
  const binary = name => path.join(root, '.lake/build/bin', name);
  const lexicalExecutable = binary('psc1_lossless_source');
  const ownershipExecutable = binary('psc1_source_ownership');
  const checkerExecutable = binary('psc1_independent_checker');
  const lexical = createLosslessSourceTool({ executable: lexicalExecutable,
    sha256: sha256(fs.readFileSync(lexicalExecutable)) });
  const ownership = createSourceOwnershipTool({
    lexicalTool: lexical, executable: ownershipExecutable,
    sha256: sha256(fs.readFileSync(ownershipExecutable)),
    checkerExecutable, checkerSha256: sha256(fs.readFileSync(checkerExecutable)),
  });
  const converter = createCheckedSourceConverter({ ownershipTool: ownership });
  const rows = readOwnedCompilerSources('Ps.CompilerUnified.Service');
  assert.equal(rows.length, 125, 'current complete compiler source closure changed');
  const started = Date.now();
  const snapshots = rows.map(row => lexical.capture({
    module: row.module, grammar: 'lean', bytes: Buffer.from(row.text),
  }));
  const before = ownership.analyze({
    snapshots, entry: 'Ps.CompilerUnified.Service', assurance: 'ordinary-checked',
  });
  const report = converter.convert({
    index: before, snapshots, targetGrammar: 'ps', commentPolicy: 'owner-notes',
  });
  const after = converter.candidateIndex(report);
  const targets = converter.candidateSnapshots(report);
  const sourceRoot = path.join(destination, 'compiler'), sourceRows = [], projectRows = [], psSources = [];
  for (let index = 0; index < rows.length; index++) {
    const row = rows[index];
    assert.ok(row.path.startsWith('packages/') && row.path.endsWith('.lean') && !row.path.split('/').includes('..'));
    const relative = row.path.replace(/\.lean$/, '.ps');
    const bytes = converter.readCandidate(report, row.module);
    put(path.join(sourceRoot, relative), bytes);
    projectRows.push({ module: row.module, path: relative });
    psSources.push({ module: row.module, kind: 'ps', text: Buffer.from(bytes).toString('utf8') });
    sourceRows.push({ module: row.module, path: relative, bytes: bytes.length, sha256: sha256(bytes),
      bootstrapPath: row.path, bootstrapSha256: sha256(row.text),
      fromSourceId: snapshots[index].sourceId, toSourceId: targets[index].sourceId });
  }
  assert.equal(compilerSourceClosureDigest(psSources), after.sourceClosureDigest);
  put(path.join(sourceRoot, 'project.json'), encoded({
    schemaVersion: 1, entryModule: 'Ps.CompilerUnified.Service', sources: projectRows,
  }));
  const sourceManifest = {
    schema: 'psc1-independent-compiler-source/1', sourceCommit, modules: sourceRows,
    authority: 'Editable .ps development project in this distribution; repository .lean remains the bootstrap source.',
    commentPolicy: 'owner-notes: exact original comment bytes and order, relocated to declaration-leading owner notes',
    before: { sourceClosureDigest: before.sourceClosureDigest, indexId: before.id, metrics: before.metrics },
    after: { sourceClosureDigest: after.sourceClosureDigest, indexId: after.id, metrics: after.metrics },
    sourceCoreDeclarations: after.sourceCoreDeclarations,
    admissionsSha256: report.admissionsSha256, originalIrSha256: report.originalIrSha256,
    checker: after.checker, report, elapsedMs: Date.now() - started,
    helperHashes: {
      lexical: sha256(fs.readFileSync(lexicalExecutable)), ownership: sha256(fs.readFileSync(ownershipExecutable)),
      checker: sha256(fs.readFileSync(checkerExecutable)),
    },
    hostMaxRssKiB: process.resourceUsage().maxRSS,
    memoryScope: 'bootstrap host only; helper metrics are recorded separately',
    independentlyRebuilt: false,
  };
  put(path.join(destination, 'metadata/SOURCE_MANIFEST.json'), encoded(sourceManifest));
  put(path.join(destination, 'README.txt'), [
    'PSC1 independent development candidate, Linux x64.',
    'Run bin/psc --help. Edit compiler/project.json and its ordered .ps modules.',
    'From this directory, run:',
    '  ./bin/psc identity',
    '  ./bin/psc build compiler/project.json --profile correctness-3600s --out build/g1',
    '  ./bin/psc build compiler/project.json --profile correctness-3600s --compiler build/g1 --out build/g2',
    '  ./bin/psc diagnostic --compiler build/g2',
    '  ./bin/psc selfhost compiler/project.json --out build/repeat',
    'Outputs must be fresh paths. Full builds may take tens of minutes and several GiB RAM.',
    'The private libexec/psc-runtime is Node 22.23.3; no installed Node executable or SDK is required.',
    'kernel/checker is the genuine precompiled official Lean4.35 C++ provider.',
    'A POSIX /bin/sh, Linux /proc and documented system shared libraries are runtime dependencies.',
    'The compiler is still subject to independent kernel admission and strict checked-IR boundaries.',
    'Bootstrap source conversion used Lean/Lake, but those tools are not included or called by the development host.',
    'The seed remains the qualified frozen JS compiler; metadata records the newer 125-source .ps project separately.',
    'Self-development qualification is recorded separately; this archive alone does not claim a fixed point.',
    '',
  ].join('\n'));
  const toolchain = {
    schema: 'psc1-independent-toolchain/1', platform: 'linux-x64', nodeVersion: '22.23.3', sourceCommit,
    runtime: { path: 'libexec/psc-runtime', sha256: sha256(nodeBytes) },
    checker: { path: 'kernel/checker', sha256: native.sha256 },
    compiler: { path: 'engine/compiler.mjs', sha256: sha256(fs.readFileSync(path.join(destination, 'engine/compiler.mjs'))), exportName },
    currentSource: { project: 'compiler/project.json', modules: rows.length,
      sourceClosureDigest: after.sourceClosureDigest, sourceCoreDeclarations: after.sourceCoreDeclarations },
    bootstrap: { defaultInput, optionalInput, compilerPin, kernelPin,
      runtime: { implementation: 'Node.js', version: '22.23.3', upstream: nodeBase,
        archive: nodeArchiveName, archiveSha256: nodeArchiveSha256, verification: 'official HTTPS release SHA256; no signature claim' } },
    frozenSeed: { sourceModules: 122, sourceCoreDeclarations: 4742,
      sourceClosureDigest: '073e5156a3fb521119bcfb4b06ad18ff136e734a0b2e10a676b1e16225835ef9' },
    resources: files(destination).filter(row => !row.path.startsWith('compiler/')),
  };
  put(path.join(destination, 'toolchain.json'), encoded(toolchain));
  const health = JSON.parse(run(path.join(destination, 'kernel/checker'), ['--health']));
  assert.equal(health.leanVersion, '4.35.0'); assert.equal(health.leanCommit, prebuilt.leanCommit);
  assert.equal(health.provider, 'lean4-cpp');
  run(path.join(destination, 'bin/psc'), ['--help']);
  run('git', ['diff', '--exit-code', '--', 'packages']);
  const tarball = path.join(outputRoot, 'psc1-independent-linux-x64.tar.gz');
  run('tar', ['--sort=name', '--mtime=@0', '--owner=0', '--group=0', '--numeric-owner',
    '-czf', tarball, '-C', outputRoot, 'toolchain']);
  const archive = fs.readFileSync(tarball);
  const summary = { schema: 'psc1-independent-bootstrap/1', status: 'assembled-awaiting-development-qualification',
    sourceCommit, toolchainSha256: sha256(fs.readFileSync(path.join(destination, 'toolchain.json'))),
    tarball: path.basename(tarball), bytes: archive.length, sha256: sha256(archive),
    sourceModules: rows.length, sourceClosureDigest: after.sourceClosureDigest,
    sourceConversionElapsedMs: sourceManifest.elapsedMs,
    sourceAdmissionsSha256: sourceManifest.admissionsSha256,
    sourceOriginalIrSha256: sourceManifest.originalIrSha256,
    privateRuntimeSha256: toolchain.runtime.sha256,
    checkerSha256: toolchain.checker.sha256, compilerSha256: toolchain.compiler.sha256 };
  put(path.join(outputRoot, 'bootstrap.json'), encoded(summary));
  console.log('PSC1_INDEPENDENT_BOOTSTRAP ' + JSON.stringify(summary));
}

function isolate() {
  requireLinux();
  assert.equal(args.length, 6);
  const distribution = path.resolve(option('--toolchain')), phase = option('--phase');
  const output = path.resolve(option('--output'));
  assert.ok(['smoke', 'baseline', 'changed'].includes(phase));
  assert.ok(output.startsWith(outputRoot + path.sep), 'CI evidence must remain inside owned dist directory');
  assert.ok(!fs.existsSync(output), 'fresh isolation output required');
  const jail = path.join(output, 'jail'); fs.mkdirSync(jail, { recursive: true });
  const manifest = read(path.join(distribution, 'toolchain.json'));
  assert.equal(manifest.schema, 'psc1-independent-toolchain/1');
  for (const pin of manifest.resources) {
    const file = path.resolve(distribution, pin.path);
    assert.ok(file.startsWith(distribution + path.sep));
    assert.equal(fs.statSync(file).size, pin.bytes); assert.equal(sha256(fs.readFileSync(file)), pin.sha256);
  }
  fs.cpSync(distribution, path.join(jail, 'toolchain'), { recursive: true });
  for (const directory of ['bin', 'proc', 'dev', 'tmp', 'work/home', 'usr/bin', 'usr/local/bin'])
    fs.mkdirSync(path.join(jail, directory), { recursive: true });
  // Copy only the shell and ELF system dependencies, never the runner's toolchains.
  const shell = fs.realpathSync('/bin/sh'); copy(shell, path.join(jail, 'bin/sh'), true);
  const dependencies = new Map();
  for (const executable of [path.join(distribution, manifest.runtime.path),
    path.join(distribution, manifest.checker.path), shell]) {
    const listing = run('ldd', [executable]);
    assert.ok(!listing.includes('not found'), listing);
    for (const match of listing.matchAll(/(?:=>\s*)?(\/[^\s()]+)\s+\(/g)) {
      const absolute = match[1];
      assert.ok(absolute.startsWith('/lib/') || absolute.startsWith('/lib64/') ||
        absolute.startsWith('/usr/lib/x86_64-linux-gnu/'), 'non-system shared library: ' + absolute);
      const bytes = fs.readFileSync(absolute), real = fs.realpathSync(absolute);
      dependencies.set(absolute, { path: absolute, resolvedPath: real, bytes: bytes.length, sha256: sha256(bytes) });
      put(path.join(jail, absolute), bytes); fs.chmodSync(path.join(jail, absolute), 0o755);
    }
  }
  const forbidden = ['lean', 'lake', 'elan', 'node', 'nodejs', 'npm', 'npx', 'bun', 'bunx',
    'tsc', 'rustc', 'cargo', 'gcc', 'g++', 'cc', 'c++', 'clang', 'clang++', 'python', 'python3',
    'wasm-tools', 'wat2wasm', 'wasm-opt', 'deno'];
  const before = files(jail);
  assert.ok(before.every(row => !forbidden.includes(path.basename(row.path))), 'forbidden development tool in isolated image');
  const inventory = { schema: 'psc1-independent-isolation-input/1', phase,
    distributionSha256: sha256(fs.readFileSync(path.join(distribution, 'toolchain.json'))),
    systemLibraries: [...dependencies.values()], shell: { implementationPath: shell,
      sha256: sha256(fs.readFileSync(shell)) }, forbiddenTools: forbidden,
    network: 'fresh network namespace; no external interfaces',
    processes: 'fresh PID namespace; private proc; no host /proc bind',
    ordinaryUser: '65534:65534', availableFiles: before };
  put(path.join(output, 'isolation-input.json'), encoded(inventory));
  // Nodes are created before entering the private namespace; no privileged helper ships.
  run('sudo', ['mknod', '-m', '666', path.join(jail, 'dev/null'), 'c', '1', '3']);
  run('sudo', ['mknod', '-m', '666', path.join(jail, 'dev/urandom'), 'c', '1', '9']);
  run('sudo', ['chown', '-R', 'root:root', path.join(jail, 'toolchain')]);
  run('sudo', ['chmod', '-R', 'a-w', path.join(jail, 'toolchain')]);
  fs.chmodSync(path.join(jail, 'tmp'), 0o1777);
  run('sudo', ['chown', '-R', '65534:65534', path.join(jail, 'work'), path.join(jail, 'tmp')]);
  const trace = path.join(output, 'execve.log'), started = Date.now();
  const argv = ['/usr/bin/env', '-i', 'HOME=/work/home', 'TMPDIR=/tmp', 'PATH=/toolchain/bin',
    'LANG=C.UTF-8', 'LC_ALL=C.UTF-8', 'PSC1_ISOLATION=fresh-chroot-pid-mount-net',
    '/usr/bin/timeout', '--signal=TERM', '--kill-after=10s', '168m',
    '/usr/bin/strace', '-f', '-qq', '-s', '4096', '-e', 'trace=execve,execveat', '-o', trace,
    '/usr/bin/unshare', '--mount', '--pid', '--fork', '--kill-child=KILL',
    '--mount-proc=' + path.join(jail, 'proc'), '--net',
    '/usr/sbin/chroot', '--userspec=65534:65534', jail,
    '/toolchain/libexec/psc-runtime', '--max-old-space-size=4096',
    '/toolchain/standalone/qualification.mjs', '--phase', phase, '--out', '/work/' + phase];
  const processResult = spawnSync('sudo', argv, {
    encoding: 'utf8', timeout: 170 * 60 * 1000, maxBuffer: 64 * 1024 * 1024,
  });
  put(path.join(output, 'stdout.log'), processResult.stdout ?? '');
  put(path.join(output, 'stderr.log'), processResult.stderr ?? '');
  run('sudo', ['chown', '-R', process.getuid() + ':' + process.getgid(),
    path.join(jail, 'work'), path.join(jail, 'tmp'), ...(fs.existsSync(trace) ? [trace] : [])]);
  if (fs.existsSync(path.join(jail, 'work', phase)))
    fs.cpSync(path.join(jail, 'work', phase), path.join(output, phase), { recursive: true });
  const traceText = fs.existsSync(trace) ? fs.readFileSync(trace, 'utf8') : '';
  const executions = [...traceText.matchAll(/execve\("([^"]+)"/g)].map(match => match[1]);
  const permitted = executable => ['/usr/bin/unshare', '/usr/sbin/chroot', '/bin/sh'].includes(executable) ||
    /^\/(?:toolchain|work\/[^"]+)\/(?:libexec\/psc-runtime|kernel\/checker|bin\/psc)$/.test(executable);
  const unexpectedExecutions = executions.filter(executable => !permitted(executable));
  const qualificationFile = path.join(output, phase, 'qualification.json');
  const qualification = fs.existsSync(qualificationFile) ? read(qualificationFile) : null;
  const passed = processResult.error === undefined && processResult.status === 0 &&
    traceText.length > 0 && !traceText.includes('execveat(') && unexpectedExecutions.length === 0 &&
    qualification?.status === 'passed' && qualification?.phase === phase;
  const result = { schema: 'psc1-independent-isolation-result/1', phase, status: passed ? 'passed' : 'failed',
    exitStatus: processResult.status, signal: processResult.signal,
    processError: processResult.error ? String(processResult.error) : null,
    elapsedMs: Date.now() - started, executions, unexpectedExecutions,
    traceSha256: sha256(traceText), qualification,
    scope: 'Observed real commands in an isolated Linux development environment; not a formal sandbox or compiler-correctness proof.' };
  put(path.join(output, 'isolation.json'), encoded(result));
  // Keep only evidence, not a duplicated runtime image or proc/dev tree.
  run('sudo', ['rm', '-rf', '--', jail]);
  console.log('PSC1_INDEPENDENT_ISOLATION ' + JSON.stringify({
    phase, status: result.status, elapsedMs: result.elapsedMs, exitStatus: result.exitStatus,
    unexpectedExecutions, traceSha256: result.traceSha256,
  }));
  if (!passed) {
    console.error('PSC1_INDEPENDENT_FAILURE: ' + JSON.stringify({
      failure: qualification?.failure ?? null, processError: result.processError,
      stderr: (processResult.stderr ?? '').slice(-24000), stdout: (processResult.stdout ?? '').slice(-12000),
    }));
  }
  assert.equal(passed, true, 'isolated development qualification failed; inspect retained receipts and logs');
}
if (mode === 'assemble') await assemble();
else if (mode === 'isolate') isolate();
else throw new Error('usage: bootstrap.mjs assemble | isolate --toolchain DIR --phase smoke|baseline|changed --output DIR');
