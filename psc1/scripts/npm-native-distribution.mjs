// Package an already-built native compiler and qualify unpublished npm tarballs.
// Run in Linux CI after lake build; never generates a self-host compiler.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { createHash } from 'node:crypto';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const output = path.join(root, 'dist/scoped-correctness/npm-native');
const pin = JSON.parse(fs.readFileSync(path.join(root, 'NATIVE_SOURCE_PIN.json'), 'utf8'));
const version = '0.1.0-psc1.2';
const targets = ['js', 'ts', 'rust', 'wasm-core', 'wasm-component', 'python', 'php'];
const json = value => JSON.stringify(value, null, 2) + '\n';
const sha = file => createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const cleanEnv = { ...process.env };
for (const key of ['PSC1_NATIVE', 'PSC1_HOST_TOOLS', 'PSC1_LIBRARY_RESOLVER', 'PSC1_TSC']) delete cleanEnv[key];
function run(command, args, options = {}) {
  const result = spawnSync('timeout', ['--kill-after=5s', '180s', command, ...args],
    { cwd: root, env: cleanEnv, encoding: 'utf8', timeout: 190000, maxBuffer: 32 * 1024 * 1024, ...options });
  if (result.error || result.status !== 0) throw Error('PSC1_NPM_COMMAND: ' + command + ' ' + args.join(' ') +
    '\n' + (result.error?.message || '') + result.stdout + result.stderr);
  return result.stdout;
}
function write(file, value) { fs.mkdirSync(path.dirname(file), { recursive: true }); fs.writeFileSync(file, value); }
function copy(from, to) { fs.mkdirSync(path.dirname(to), { recursive: true }); fs.cpSync(from, to, { recursive: true, dereference: true }); }
function identity(binary, env = cleanEnv) {
  const value = JSON.parse(run(binary, ['--identity'], { env }));
  assert.equal(value.protocol, pin.compilerProtocol); assert.equal(value.profile, pin.compilerProfile);
  assert.equal(value.lean, pin.version); assert.equal(value.leanCommit, pin.commit);
  assert.deepEqual([...value.targets].sort(), [...targets].sort(), 'native compiler must contain all seven selected backends');
  return value;
}
if (process.platform !== 'linux' || process.arch !== 'x64' || !process.report.getReport().header.glibcVersionRuntime) {
  throw Error('PSC1_NPM_PLATFORM: this qualification requires Linux x64 glibc');
}
fs.mkdirSync(output, { recursive: true });
const runRoot = fs.mkdtempSync(path.join(output, 'run-'));
const stage = path.join(runRoot, 'package');
const native = path.join(root, '.lake/build/bin/psc1');
const nativeIdentity = identity(native);
copy(native, path.join(stage, 'native/bin/psc1'));
fs.chmodSync(path.join(stage, 'native/bin/psc1'), 0o755);
for (const file of ['psc.js', 'libraries.mjs']) copy(path.join(root, 'npm-cli', file), path.join(stage, 'npm-cli', file));
fs.chmodSync(path.join(stage, 'npm-cli/psc.js'), 0o755);
copy(path.join(root, 'NATIVE_SOURCE_PIN.json'), path.join(stage, 'NATIVE_SOURCE_PIN.json'));
copy(path.join(root, 'profile.json'), path.join(stage, 'profile.json'));
for (const item of fs.readdirSync(path.join(root, 'host-tools'), { withFileTypes: true })) {
  if (item.isFile() && item.name !== '.npmrc' && item.name !== 'package-lock.json' && !item.name.startsWith('test-')) {
    copy(path.join(root, 'host-tools', item.name), path.join(stage, 'host-tools', item.name));
  }
}
const leanPrefix = run('lean', ['--print-prefix']).trim();
const licenses = fs.readdirSync(leanPrefix).filter(name => /^LICENSE(?:S|\.|$)|^NOTICE/u.test(name));
assert.ok(licenses.length, 'Lean distribution must retain its license notices');
for (const name of licenses) copy(path.join(leanPrefix, name), path.join(stage, 'licenses/lean', name));
const ldd = spawnSync('ldd', [native], { encoding: 'utf8', env: cleanEnv });
if (ldd.error) throw ldd.error;
if (ldd.status !== 0 && !/not a dynamic executable|statically linked/.test(ldd.stdout + ldd.stderr)) {
  throw Error('PSC1_NPM_NATIVE_LINK: ' + ldd.stdout + ldd.stderr);
}
if (/=>\s+not found/.test(ldd.stdout)) throw Error('PSC1_NPM_NATIVE_LIBRARY_MISSING');
const sharedLibraries = [];
for (const line of ldd.stdout.split('\n')) {
  const match = /^\s*(\S+)\s+=>\s+(\/[^\s]+)\s+\(/u.exec(line);
  if (!match) continue;
  const [, name, source] = match;
  if (source.startsWith('/lib/') || source.startsWith('/lib64/') || source.startsWith('/usr/lib/')) continue;
  const resolved = fs.realpathSync(source);
  if (!resolved.startsWith(fs.realpathSync(leanPrefix) + path.sep)) throw Error('PSC1_NPM_UNDECLARED_NATIVE_LIBRARY: ' + source);
  const destination = path.join(stage, 'native/lib', name);
  copy(resolved, destination);
  sharedLibraries.push({ name, sha256: sha(destination), bytes: fs.statSync(destination).size });
}
const hostMeta = JSON.parse(fs.readFileSync(path.join(root, 'host-tools/package.json'), 'utf8'));
const workspaceMeta = JSON.parse(fs.readFileSync(path.join(root, 'package.json'), 'utf8'));
const meta = {
  name: 'proofscript', version, private: true, type: 'module',
  description: 'Checked native ProofScript PSC1 toolchain; unpublished Linux qualification package',
  ...(workspaceMeta.license ? { license: workspaceMeta.license } : {}),
  bin: { psc: './npm-cli/psc.js', psc1: './npm-cli/psc.js' },
  exports: { './package.json': './package.json' }, engines: { node: '>=22' },
  os: ['linux'], cpu: ['x64'], libc: ['glibc'],
  files: ['npm-cli/', 'native/', 'host-tools/', 'licenses/', 'NATIVE_SOURCE_PIN.json', 'NATIVE_DISTRIBUTION.json', 'profile.json', 'README.md'],
  dependencies: hostMeta.dependencies, bundledDependencies: Object.keys(hostMeta.dependencies),
  proofscript: { compilerProfile: pin.compilerProfile, sourceKind: 'native-lean',
    builtInTargets: targets, publicationStatus: 'unpublished-qualification-only' }
};
write(path.join(stage, 'package.json'), json(meta));
const lock = JSON.parse(fs.readFileSync(path.join(root, 'host-tools/package-lock.json'), 'utf8'));
lock.name = meta.name; lock.version = meta.version;
lock.packages[''] = { name: meta.name, version: meta.version, dependencies: meta.dependencies,
  engines: meta.engines, bin: meta.bin, os: meta.os, cpu: meta.cpu, libc: meta.libc };
for (const [key, value] of Object.entries(lock.packages)) if (value.dev === true) delete lock.packages[key];
write(path.join(stage, 'package-lock.json'), json(lock));
run('npm', ['--prefix', stage, '--workspaces=false', 'ci', '--omit=dev', '--ignore-scripts', '--no-audit', '--no-fund']);
run('npm', ['--prefix', stage, '--workspaces=false', 'shrinkwrap', '--ignore-scripts']);
write(path.join(stage, 'README.md'), '# ProofScript PSC1\n\nUnpublished Linux x64/glibc native toolchain.\n\n' +
  'Install this tarball with npm install ./proofscript-' + version + '.tgz. Use npx psc --help.\n\n' +
  'All seven built-in backends are compiled into the native binary. Core logical and runtime declarations are compiled in.\n' +
  'JavaScript output needs no TypeScript compiler. Selected Rust/Wasm/Python/PHP targets require their target tools.\n' +
  'The compiler, host formatter and libraries resolver ship together. Portable source libraries are independently checked.\n' +
  'No npm installation script, network binary download, compiler fallback or package publication is used.\n');
const distribution = { schemaVersion: 1, sourceCommit: process.env.GITHUB_SHA || null,
  compilerIdentity: nativeIdentity, nativeSha256: sha(native), nativeBytes: fs.statSync(native).size,
  platform: { os: 'linux', cpu: 'x64', libc: 'glibc', qualifiedGlibc: process.report.getReport().header.glibcVersionRuntime },
  hostDependencyLockSha256: sha(path.join(root, 'host-tools/package-lock.json')),
  bundledNpmDependencies: meta.dependencies, bundledNativeLibraries: sharedLibraries,
  logicalAdmission: 'official Lean ' + pin.version, noSelfHostQualification: true,
  publicationStatus: 'unpublished', packageQualification: 'receipt written only after install and execution tests' };
write(path.join(stage, 'NATIVE_DISTRIBUTION.json'), json(distribution));
const tarballs = path.join(runRoot, 'tarballs');
fs.mkdirSync(tarballs, { recursive: true });
const packed = JSON.parse(run('npm', ['pack', stage, '--pack-destination', tarballs, '--ignore-scripts', '--json']));
assert.equal(packed.length, 1);
const tarball = path.join(tarballs, packed[0].filename);
const consumer = path.join(runRoot, 'consumer');
write(path.join(consumer, 'package.json'), json({ name: 'psc1-native-canary', version: '0.0.0', private: true, type: 'module' }));
const emptyCache = path.join(runRoot, 'empty-npm-cache');
run('npm', ['install', '--prefix', consumer, '--cache', emptyCache, '--offline', '--ignore-scripts', '--no-audit', '--no-fund', tarball]);
const installed = path.join(consumer, 'node_modules/proofscript');
const cli = path.join(installed, 'npm-cli/psc.js');
const npmIdentity = JSON.parse(run(process.execPath, [cli, '--identity'], { cwd: consumer }));
assert.deepEqual(npmIdentity, nativeIdentity);
assert.equal(JSON.parse(run(path.join(consumer, 'node_modules/.bin/psc'), ['--identity'], { cwd: consumer })).leanCommit, pin.commit);
const nativeEnv = { ...cleanEnv, LD_LIBRARY_PATH: path.join(installed, 'native/lib') };
const installedLdd = spawnSync('ldd', [path.join(installed, 'native/bin/psc1')], { env: nativeEnv, encoding: 'utf8' });
assert.equal(installedLdd.error, undefined);
assert.doesNotMatch(installedLdd.stdout + installedLdd.stderr, /=>\s+not found|\/\.elan\//u,
  'installed executable must resolve bundled native libraries independently of build toolchain');
assert.deepEqual(identity(path.join(installed, 'native/bin/psc1'), nativeEnv), nativeIdentity);
assert.equal(sha(path.join(installed, 'native/bin/psc1')), distribution.nativeSha256);
for (const name of ['typescript', '@typescript', '@proofscript/compiler', '@proofscript/pskernel-core']) {
  assert.equal(fs.existsSync(path.join(installed, 'node_modules', name)), false, 'archived/compiler tool dependency must be absent: ' + name);
}
const source = path.join(consumer, 'Main.ps'), generated = path.join(consumer, 'Main.js');
write(source, 'def answer : Nat := 42\n');
run(process.execPath, [cli, 'build', source, '--target', 'js', '--out', generated], { cwd: consumer });
const program = await import(pathToFileURL(generated).href);
assert.equal(typeof program.answer === 'function' ? program.answer() : program.answer, 42n);
run(path.join(installed, 'native/bin/psc1'), ['build', source, '--target', 'js', '--out', path.join(consumer, 'Native.js')], { cwd: consumer, env: nativeEnv });
const globalPrefix = path.join(runRoot, 'global');
run('npm', ['install', '--global', '--prefix', globalPrefix, '--cache', emptyCache, '--offline', '--ignore-scripts', '--no-audit', '--no-fund', tarball]);
assert.deepEqual(JSON.parse(run(path.join(globalPrefix, 'bin/psc'), ['--identity'])), nativeIdentity);
run(process.execPath, [path.join(root, 'scripts/npm-native-library-canary.mjs'), path.join(runRoot, 'library'), cli]);
const receipt = { ...distribution, qualification: 'passed', tarball: path.relative(root, tarball),
  tarballSha256: sha(tarball), tarballBytes: fs.statSync(tarball).size,
  offlineLocalInstall: true, offlineGlobalInstall: true, nativeNpmIdentityAgreement: true,
  nativeDirectBuild: true, generatedJavaScriptExecuted: true, typeScriptInstalled: false,
  optionalLibraryReceipt: path.relative(root, path.join(runRoot, 'library/qualification.json')),
  nodeVersion: process.version, npmVersion: run('npm', ['--version']).trim() };
write(path.join(output, 'qualification.json'), json(receipt));
console.log('PSC1_NPM_NATIVE_DISTRIBUTION: PASS ' + JSON.stringify(receipt));
