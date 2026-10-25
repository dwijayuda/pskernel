// Trusted installed-package selection only. Compiler wire data never selects tools.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import os from 'node:os';
import { createRequire } from 'node:module';
import { fileURLToPath, pathToFileURL } from 'node:url';
import {
  expectedDistributionSha256,
  expectedCompilerSourceClosureDigest,
} from '../DISTRIBUTION_PIN.mjs';

export const installationRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
export const compilerRoot = expectedCompilerSourceClosureDigest;
export const leanCommit = 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc';
export const hash = (bytes) => crypto.createHash('sha256').update(bytes).digest('hex');
const fail = (message) => {
  throw Error('PSC1_INSTALLED_' + message);
};
const require = createRequire(path.join(installationRoot, 'package.json'));
const closedEngines = ['js', 'rust', 'ts', 'wasm-core'];
// Resolve only a pinned regular file under its declared package root.
// Walking every path component keeps parent-directory symlinks out of the boundary.
export function verifyFile(root, record, maxBytes = 128 * 1024 * 1024) {
  if (
    !record ||
    typeof record.path !== 'string' ||
    !/^[A-Za-z0-9_@.\/-]+$/.test(record.path) ||
    !/^[0-9a-f]{64}$/.test(record.sha256 || '') ||
    !Number.isSafeInteger(record.bytes) ||
    record.bytes < 1 ||
    record.bytes > maxBytes
  )
    fail('INVALID_PIN');
  const file = path.resolve(root, record.path),
    relative = path.relative(root, file);
  if (!relative || relative.startsWith('..') || path.isAbsolute(relative)) fail('PATH_ESCAPE');
  for (let p = file; p !== root; p = path.dirname(p))
    if (fs.lstatSync(p).isSymbolicLink()) fail('RESOURCE_SYMLINK');
  const stat = fs.lstatSync(file);
  if (!stat.isFile() || stat.size !== record.bytes || hash(fs.readFileSync(file)) !== record.sha256)
    fail('RESOURCE_IDENTITY:' + record.path);
  return { path: file, sha256: record.sha256 };
}
function manifestPin() {
  const file = path.join(installationRoot, 'UNIVERSAL_DISTRIBUTION.json'),
    stat = fs.lstatSync(file);
  if (!stat.isFile() || stat.isSymbolicLink() || stat.size > 2 * 1024 * 1024)
    fail('DISTRIBUTION_KIND');
  const bytes = fs.readFileSync(file);
  if (hash(bytes) !== expectedDistributionSha256) fail('DISTRIBUTION_IDENTITY');
  return { bytes, pin: { path: file, sha256: expectedDistributionSha256 } };
}
export function loadDistribution() {
  if (process.version !== 'v22.23.3') fail('NODE_PIN');
  if (!/^[a-f0-9]{64}$/.test(compilerRoot)) fail('COMPILER_SOURCE_PIN');
  const { bytes } = manifestPin(),
    d = JSON.parse(bytes);
  if (
    d.schema !== 'psc1-universal-npm-distribution/1' ||
    d.compilerSourceClosureDigest !== compilerRoot ||
    d.defaultEngine !== 'js' ||
    d.defaultKernel !== 'wasm' ||
    d.leanCommit !== leanCommit ||
    Object.keys(d.engines || {})
      .sort()
      .join(',') !== closedEngines.join(',') ||
    Object.keys(d.kernels || {})
      .sort()
      .join(',') !== 'native,wasm' ||
    !Array.isArray(d.hostFiles) ||
    !d.hostFiles.length
  )
    fail('DISTRIBUTION_POLICY');
  const meta = JSON.parse(fs.readFileSync(path.join(installationRoot, 'package.json'), 'utf8'));
  if (
    meta.name !== 'proofscript' ||
    meta.version !== d.version ||
    meta.proofscript?.defaultKernel !== 'wasm' ||
    meta.proofscript?.defaultEngine !== 'js' ||
    meta.os ||
    meta.cpu ||
    meta.libc
  )
    fail('PACKAGE_POLICY');
  for (const pin of d.hostFiles) verifyFile(installationRoot, pin);
  return d;
}
export function commonPins(distribution = loadDistribution()) {
  // Include the seal itself in per-request before/after checks without a circular manifest hash.
  return [
    ...distribution.hostFiles.map((p) => verifyFile(installationRoot, p)),
    manifestPin().pin,
    {
      path: path.join(installationRoot, 'DISTRIBUTION_PIN.mjs'),
      sha256: hash(fs.readFileSync(path.join(installationRoot, 'DISTRIBUTION_PIN.mjs'))),
    },
  ];
}
// Package metadata locates resources; trusted distribution pins authorize their bytes.
// Resolution never imports an arbitrary package entry point or downloads a missing add-on.
function packagePins(descriptor) {
  if (
    !descriptor ||
    (descriptor.package !== 'typescript' &&
      descriptor.package !== '@typescript/typescript-linux-x64' &&
      !/^@proofscript\/[a-z0-9-]+$/.test(descriptor.package || '')) ||
    !Array.isArray(descriptor.files) ||
    !descriptor.files.length
  )
    fail('PACKAGE_DESCRIPTOR');
  let file;
  try {
    file = require.resolve(descriptor.package + '/package.json');
  } catch (error) {
    if (error.code !== 'MODULE_NOT_FOUND' && error.code !== 'ERR_PACKAGE_PATH_NOT_EXPORTED')
      throw error;
    fail('OPTIONAL_PACKAGE_MISSING: npm install ' + descriptor.package + '@' + descriptor.version);
  }
  const root = fs.realpathSync(path.dirname(file));
  const pins = descriptor.files.map((p) => verifyFile(root, p));
  const meta = JSON.parse(fs.readFileSync(path.join(root, 'package.json'), 'utf8'));
  if (meta.name !== descriptor.package || meta.version !== descriptor.version)
    fail('OPTIONAL_PACKAGE_VERSION');
  if (
    !descriptor.files.some((p) => p.path === 'package.json') ||
    !descriptor.files.some((p) => p.path === descriptor.entry)
  )
    fail('PACKAGE_ENTRY_NOT_PINNED');
  return {
    root,
    pins,
    entry: verifyFile(
      root,
      descriptor.files.find((p) => p.path === descriptor.entry),
    ),
  };
}
export function resolveEngine(engine = 'js', distribution = loadDistribution()) {
  if (!Object.hasOwn(distribution.engines, engine)) fail('UNKNOWN_ENGINE');
  const descriptor = distribution.engines[engine],
    common = commonPins(distribution);
  if (
    descriptor.compilerSourceClosureDigest !== compilerRoot ||
    descriptor.qualification !== 'qualified'
  )
    fail('ENGINE_SOURCE_IDENTITY');
  if (descriptor.kind === 'embedded') {
    if (!['js', 'ts'].includes(engine)) fail('ENGINE_KIND');
    const pins = descriptor.files.map((p) => verifyFile(installationRoot, p));
    return {
      engine,
      descriptor,
      service: verifyFile(installationRoot, descriptor.adapter),
      candidate: verifyFile(installationRoot, descriptor.candidate),
      candidateKind: 'embedded',
      pins: [...common, ...pins],
    };
  }
  if (descriptor.kind !== 'optional-package' || !['rust', 'wasm-core'].includes(engine))
    fail('ENGINE_KIND');
  if (engine === 'rust' && (process.platform !== 'linux' || process.arch !== 'x64'))
    fail('UNSUPPORTED_RUST_PLATFORM');
  const resolved = packagePins(descriptor);
  const bundle = JSON.parse(
    fs.readFileSync(path.join(resolved.root, 'BUNDLE_MANIFEST.json'), 'utf8'),
  );
  if (
    bundle.schema !== 'psc1-compiled-compiler-execution-bundle/1' ||
    bundle.engine !== engine ||
    bundle.compilerSourceClosureDigest !== compilerRoot ||
    bundle.executableSha256 !== descriptor.executableSha256 ||
    bundle.publicationAuthority !== false
  )
    fail('BUNDLE_COMPILER_IDENTITY');
  return {
    engine,
    descriptor,
    service: verifyFile(installationRoot, descriptor.adapter),
    candidate: resolved.entry,
    candidateKind: 'bundle',
    pins: [...common, ...resolved.pins, verifyFile(installationRoot, descriptor.adapter)],
  };
}
export function resolveCheckedTarget(
  target,
  distribution = loadDistribution(),
  { rustToolchainRoot } = {},
) {
  if (['wasm-component', 'python', 'php'].includes(target)) {
    if (process.platform !== 'linux' || process.arch !== 'x64')
      fail('DISPATCH_PLATFORM_UNQUALIFIED');
    const descriptor = distribution.dispatchPackages?.[target];
    if (
      !descriptor ||
      descriptor.target !== target ||
      descriptor.platform !== 'linux-x64' ||
      descriptor.entry !== 'tool' ||
      !/^[a-f0-9]{40}$/.test(descriptor.sourceCommit || '') ||
      descriptor.limits?.timeoutMs !== 240000 ||
      descriptor.limits?.addressSpaceBytes !== 4294967296 ||
      descriptor.limits?.stackBytes !== 8388608 ||
      descriptor.limits?.responseBytes !== 33554432
    )
      fail('DISPATCH_DESCRIPTOR');
    const selected = packagePins(descriptor);
    const meta = JSON.parse(fs.readFileSync(path.join(selected.root, 'package.json')));
    if (
      meta.proofscript?.schema !== 'psc1-checked-dispatch-package/1' ||
      meta.proofscript.target !== target ||
      meta.proofscript.sourceCommit !== descriptor.sourceCommit ||
      meta.proofscript.authority !== 'candidate-only' ||
      meta.proofscript.compilerFrontend !== false ||
      meta.proofscript.admissionAuthority !== false ||
      meta.proofscript.publicationAuthority !== false
    )
      fail('DISPATCH_AUTHORITY');
    const tool = { ...descriptor, executable: selected.entry.path, pins: selected.pins };
    return target === 'wasm-component' ? { componentTools: tool } : { optionalProvider: tool };
  }
  if (target === 'rust') {
    const descriptor = distribution.targetConsumers?.rust;
    if (
      process.platform !== 'linux' ||
      process.arch !== 'x64' ||
      !descriptor ||
      descriptor.toolchain?.version !== '1.90.0'
    )
      fail('RUST_CONSUMER_PLATFORM');
    const resolved = packagePins(descriptor),
      sdk = path.resolve(
        rustToolchainRoot ||
          path.join(os.homedir(), '.rustup/toolchains', descriptor.toolchain.directoryName),
      );
    if (!fs.lstatSync(sdk).isDirectory() || fs.lstatSync(sdk).isSymbolicLink())
      fail('RUST_SDK_ROOT');
    const sdkPins = descriptor.toolchain.files.map((pin) =>
      verifyFile(sdk, pin, 512 * 1024 * 1024),
    );
    const externs = ['num_bigint', 'num_traits'].map((name) => {
      const rows = descriptor.files.filter(
        (pin) => pin.path.startsWith('deps/lib' + name + '-') && pin.path.endsWith('.rlib'),
      );
      if (rows.length !== 1) fail('RUST_DEPENDENCY');
      return { name, file: verifyFile(resolved.root, rows[0]).path };
    });
    return {
      rust: {
        sysroot: sdk,
        rustc: path.join(sdk, 'bin/rustc'),
        inspector: path.join(resolved.root, descriptor.inspector),
        dependencyDirectory: path.join(resolved.root, 'deps'),
        externs,
        pins: [...resolved.pins, ...sdkPins],
      },
    };
  }
  if (target === 'js' || target === 'wasm-core') return {};
  if (
    target !== 'ts' ||
    distribution.targetConsumers?.ts?.package !== 'typescript' ||
    distribution.targetConsumers.ts.version !== '7.0.2'
  )
    fail('CHECKED_TARGET_CONSUMER');
  const resolved = packagePins(distribution.targetConsumers.ts);
  if (
    process.platform !== 'linux' ||
    process.arch !== 'x64' ||
    distribution.targetConsumers.ts.platform !== 'linux-x64' ||
    distribution.targetConsumers.ts.dependencies?.length !== 1 ||
    distribution.targetConsumers.ts.dependencies[0].package !==
      '@typescript/typescript-linux-x64' ||
    distribution.targetConsumers.ts.dependencies[0].version !== '7.0.2'
  )
    fail('TYPESCRIPT_CONSUMER_PLATFORM');
  const native = packagePins(distribution.targetConsumers.ts.dependencies[0]);
  return {
    typescript: {
      entry: resolved.entry.path,
      executable: native.entry.path,
      pins: [...resolved.pins, ...native.pins],
    },
  };
}
export function resolveKernel(provider = 'wasm', distribution = loadDistribution()) {
  if (!['wasm', 'native'].includes(provider)) fail('UNKNOWN_KERNEL');
  const descriptor = distribution.kernels[provider],
    resolved = packagePins(descriptor);
  return { ...resolved, provider, pins: [...commonPins(distribution), ...resolved.pins] };
}
// Select one explicit checker and retain before/after resource verification.
// Native fallback is disabled; the default Wasm checker cannot silently change providers.
export async function kernelHandle(provider = 'wasm', distribution = loadDistribution()) {
  const selected = resolveKernel(provider, distribution),
    verify = () =>
      selected.pins.forEach((p) => {
        const stat = fs.lstatSync(p.path);
        if (!stat.isFile() || stat.isSymbolicLink() || hash(fs.readFileSync(p.path)) !== p.sha256)
          fail('RESOURCE_CHANGED');
      });
  verify();
  const module = await import(pathToFileURL(selected.entry.path).href),
    env = { ...process.env };
  delete env.PSC_LEAN_KERNEL_PROVIDER_BIN;
  const handle = await module.createKernel(
    provider === 'native'
      ? { env, allowSourceCheckoutFallback: false, timeoutMs: 120000, maxBuffer: 32 * 1024 * 1024 }
      : { timeoutMs: 120000, maxBuffer: 32 * 1024 * 1024 },
  );
  if (
    handle.metadata.leanVersion !== '4.35.0' ||
    handle.metadata.leanCommit !== leanCommit ||
    handle.metadata.profile !== 'lean4.35-core'
  )
    fail('KERNEL_IDENTITY');
  verify();
  return { handle, verify };
}
export async function checkInstalledAdmissions(source, provider = 'wasm') {
  if (typeof source !== 'string' || Buffer.byteLength(source) > 128 * 1024 * 1024)
    fail('ADMISSIONS_LIMIT');
  if (!['wasm', 'native', 'both'].includes(provider)) fail('UNKNOWN_KERNEL');
  const d = loadDistribution(),
    selected = provider === 'both' ? ['wasm', 'native'] : [provider],
    results = {};
  for (const key of selected) {
    const { handle, verify } = await kernelHandle(key, d);
    verify();
    results[key] = await handle.checkCanonicalAdmissions(source);
    verify();
  }
  const accepted = selected.every((k) => results[k].accepted === true),
    agreement = selected.every((k) => results[k].accepted === results[selected[0]].accepted);
  return Object.freeze({
    schema: 'psc1-universal-kernel-result/1',
    provider,
    accepted,
    agreement,
    admissionsSha256: hash(source),
    leanVersion: '4.35.0',
    leanCommit,
    wasmMemoryModel: 'linear',
    results,
  });
}
export function describeInstallation() {
  const d = loadDistribution(),
    engines = {};
  for (const engine of closedEngines) {
    try {
      const r = resolveEngine(engine, d);
      engines[engine] = {
        installed: true,
        kind: r.descriptor.kind,
        compilerSourceClosureDigest: compilerRoot,
      };
    } catch (error) {
      if (!/OPTIONAL_PACKAGE_MISSING|UNSUPPORTED_RUST_PLATFORM/.test(error.message)) throw error;
      engines[engine] = { installed: false, kind: d.engines[engine].kind, reason: error.message };
    }
  }
  return Object.freeze({
    schema: d.schema,
    version: d.version,
    defaultEngine: 'js',
    defaultKernel: 'wasm',
    compilerSourceClosureDigest: compilerRoot,
    leanVersion: '4.35.0',
    leanCommit,
    engines,
    checkedTargets: ['js', 'ts', 'rust', 'wasm-core', 'wasm-component', 'python', 'php'],
    publicationProtocols: ['legacy-symlink', 'portable-file'],
    candidateTargets: ['js', 'ts', 'rust', 'wasm-core'],
    publicationPlatforms: ['linux'],
    finalCrossPlatformRelease: false,
  });
}
