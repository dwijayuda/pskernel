import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import {
  cpSync, existsSync, mkdirSync, readFileSync, readdirSync, rmSync,
  statSync, writeFileSync,
} from 'node:fs';
import { createRequire } from 'node:module';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const target = `${process.platform}-${process.arch}`;
const supported = new Set([
  'linux-x64', 'linux-arm64', 'darwin-x64', 'darwin-arm64', 'win32-x64',
]);
assert.ok(supported.has(target), `unsupported native PSC toolchain target: ${target}`);

const executableSuffix = process.platform === 'win32' ? '.exe' : '';
const pscSource = path.join(root, '.lake/build/bin/psc' + executableSuffix);
const kernelSource = path.join(
  root, 'packages/pskernel-lean/.lake/build/bin/psc2_lean_kernel_provider' + executableSuffix,
);
assert.ok(existsSync(pscSource), 'native psc is missing; run lake build psc');
assert.ok(existsSync(kernelSource), 'slim native pskernel-lean is missing; run its build-native-slim.mjs');

const tsPackageName = `@typescript/typescript-${target}`;
let tsPackageRoot = process.env.PSC_TYPESCRIPT_NATIVE_PACKAGE_ROOT;
if (!tsPackageRoot) {
  const require = createRequire(import.meta.url);
  try {
    tsPackageRoot = path.dirname(require.resolve(tsPackageName + '/package.json'));
  } catch (cause) {
    throw new Error(
      `native TypeScript package ${tsPackageName} is unavailable; install typescript@7.0.2 or set PSC_TYPESCRIPT_NATIVE_PACKAGE_ROOT`,
      { cause },
    );
  }
}
tsPackageRoot = path.resolve(tsPackageRoot);
const tsPackage = JSON.parse(readFileSync(path.join(tsPackageRoot, 'package.json'), 'utf8'));
assert.equal(tsPackage.version, '7.0.2', 'native TypeScript platform package must be 7.0.2');

const tscName = process.platform === 'win32' ? 'tsc.exe' : 'tsc';
const tscSource = path.join(tsPackageRoot, 'lib', tscName);
assert.ok(existsSync(tscSource), `native TypeScript executable is missing: ${tscSource}`);

const outputRoot = path.resolve(
  process.env.PSC_NATIVE_TOOLCHAIN_OUT ??
  path.join(root, 'dist/native-toolchain', target),
);
rmSync(outputRoot, { recursive: true, force: true });
mkdirSync(path.join(outputRoot, 'bin'), { recursive: true });
mkdirSync(path.join(outputRoot, 'typescript'), { recursive: true });
mkdirSync(path.join(outputRoot, 'licenses'), { recursive: true });

const pscDest = path.join(outputRoot, 'bin', 'psc' + executableSuffix);
const kernelDest = path.join(outputRoot, 'bin', 'pskernel-lean' + executableSuffix);
cpSync(pscSource, pscDest);
cpSync(kernelSource, kernelDest);
cpSync(path.join(tsPackageRoot, 'lib'), path.join(outputRoot, 'typescript', 'lib'), { recursive: true });
for (const name of ['package.json', 'LICENSE', 'NOTICE.txt']) {
  const source = path.join(tsPackageRoot, name);
  if (existsSync(source)) cpSync(source, path.join(outputRoot, 'typescript', name));
}
for (const [source, dest] of [
  [path.join(root, 'packages/pskernel-lean/LEAN_LICENSE'), 'Lean-4.34-LICENSE'],
  [path.join(tsPackageRoot, 'LICENSE'), 'TypeScript-LICENSE'],
  [path.join(tsPackageRoot, 'NOTICE.txt'), 'TypeScript-NOTICE.txt'],
]) {
  if (existsSync(source)) cpSync(source, path.join(outputRoot, 'licenses', dest));
}

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: outputRoot,
    encoding: 'utf8',
    windowsHide: true,
    maxBuffer: 16 * 1024 * 1024,
    ...options,
  });
  assert.equal(
    result.status,
    0,
    `${command} ${args.join(' ')} failed\nstdout:\n${result.stdout ?? ''}\nstderr:\n${result.stderr ?? ''}`,
  );
  return result.stdout.trim();
}
assert.match(run(pscDest, ['--version']), /^psc native-bootstrap /u);
assert.equal(run(path.join(outputRoot, 'typescript/lib', tscName), ['--version']), 'Version 7.0.2');
const kernelHealth = JSON.parse(run(kernelDest, ['--health']));
assert.equal(kernelHealth.protocol, 'pskernel-lean/1');
assert.equal(kernelHealth.leanVersion, '4.34.0');
assert.equal(kernelHealth.leanCommit, '293d5d0c0c3f3dded4688b3ccd6a33939ac5102b');
assert.equal(kernelHealth.profile, 'lean4.34-core');

function digest(file) {
  return createHash('sha256').update(readFileSync(file)).digest('hex');
}
function collectFiles(directory, base = directory) {
  const items = [];
  for (const entry of readdirSync(directory, { withFileTypes: true }).sort((a,b)=>a.name.localeCompare(b.name))) {
    const absolute = path.join(directory, entry.name);
    if (entry.isDirectory()) items.push(...collectFiles(absolute, base));
    else if (entry.isFile()) items.push({
      path: path.relative(base, absolute).split(path.sep).join('/'),
      bytes: statSync(absolute).size,
      sha256: digest(absolute),
    });
  }
  return items;
}

const readme = `# ProofScript native toolchain (${target})

This directory is a platform-specific native PSC toolchain.

- \`bin/psc${executableSuffix}\` — PSC compiler built by Lean 4.34.
- \`bin/pskernel-lean${executableSuffix}\` — native Lean 4.34 kernel provider.
- \`typescript/lib/${tscName}\` — native TypeScript 7.0.2 compiler.
- \`typescript/lib/lib*.d.ts\` — TypeScript standard-library declarations.

The native PSC executable auto-detects the bundled TypeScript compiler relative to
its own executable path, so normal \`psc build\` does not require Node.

Examples:

    bin/psc${executableSuffix} --version
    bin/psc${executableSuffix} check example.ps
    bin/psc${executableSuffix} build example.ps --out example.js
    bin/pskernel-lean${executableSuffix} --health
    typescript/lib/${tscName} --version

The default checked profile in the source repository is \`lean434-wasm\`.
The bundled native Lean provider remains an explicit reference alternative via \`lean434\`.

The kernel remains outside the 55-module compiler bootstrap closure.
`;
writeFileSync(path.join(outputRoot, 'README.md'), readme, 'utf8');

const manifest = {
  schemaVersion: 1,
  kind: 'psc2-native-toolchain',
  target,
  psc: {
    path: `bin/psc${executableSuffix}`,
    sha256: digest(pscDest),
    bytes: statSync(pscDest).size,
    implementation: 'Lean 4.34 bootstrap compiler',
  },
  kernel: {
    path: `bin/pskernel-lean${executableSuffix}`,
    sha256: digest(kernelDest),
    bytes: statSync(kernelDest).size,
    protocol: 'pskernel-lean/1',
    leanVersion: '4.34.0',
    leanCommit: '293d5d0c0c3f3dded4688b3ccd6a33939ac5102b',
    proofScriptSourceRevision: '1b21b2483df7e8de7542873c24eaff2501539b1b',
  },
  typescript: {
    package: tsPackageName,
    version: '7.0.2',
    path: `typescript/lib/${tscName}`,
    sha256: digest(path.join(outputRoot, 'typescript/lib', tscName)),
    bytes: statSync(path.join(outputRoot, 'typescript/lib', tscName)).size,
  },
};
writeFileSync(path.join(outputRoot, 'TOOLCHAIN.json'), JSON.stringify(manifest, null, 2) + '\n');

const files = collectFiles(outputRoot);
writeFileSync(
  path.join(outputRoot, 'FILES.json'),
  JSON.stringify({ schemaVersion: 1, target, files }, null, 2) + '\n',
);
console.log(`PSC2_NATIVE_TOOLCHAIN_BUNDLE: PASS ${target} ${outputRoot}`);
console.log(JSON.stringify(manifest));
