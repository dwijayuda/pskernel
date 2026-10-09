import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { access, copyFile, mkdir, mkdtemp, readFile, rm, symlink, writeFile } from 'node:fs/promises';
import { tmpdir, release as operatingSystemRelease } from 'node:os';
import path from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';

export function installedPaths(prefix, platform = process.platform) {
  if (platform === 'win32') return {
    installed: path.win32.join(prefix, 'node_modules/proofscript'),
    command: path.win32.join(prefix, 'psc.cmd'),
  };
  assert.equal(platform, 'linux', 'PSC_SMOKE_PLATFORM');
  return {
    installed: path.posix.join(prefix, 'lib/node_modules/proofscript'),
    command: path.posix.join(prefix, 'bin/psc'),
  };
}

export function nodeOnlyEnvironment(original, nodeDirectory) {
  const blocked = new Set(['PATH', 'PSC0_TSC', 'PSC0_TYPESCRIPT_VERSION',
    'PSC_KERNEL_CORE_PROVIDER_BIN', 'PSC_LEAN_KERNEL_PROVIDER_BIN',
    'PSC0_TEST_KERNEL_CORE_PROVIDER_BIN', 'PSC0_PLATFORM_COMPILER',
    'LEAN_PATH', 'LEAN_SRC_PATH', 'ELAN_HOME', 'NODE_PATH', 'NODE_OPTIONS',
    'LD_LIBRARY_PATH', 'LD_PRELOAD', 'DYLD_LIBRARY_PATH', 'DYLD_INSERT_LIBRARIES',
    'PSMODULEPATH', 'PSC0_SMOKE_NPM_CLI', 'PSC0_SMOKE_EXPECT_NPM',
    'PSC0_SMOKE_POWERSHELL', 'PSC0_SMOKE_COMMAND']);
  // Windows environment names are case-insensitive; do not retain a second
  // Path entry that can select a different executable search path.
  const env = {};
  for (const [name, value] of Object.entries(original)) {
    if (!blocked.has(name.toUpperCase())) env[name] = value;
  }
  env.PATH = nodeDirectory;
  return env;
}

// This fixed PowerShell program treats paths/arguments as JSON data. It never
// inserts them into PowerShell source or enables Node's shell:true mode.
// The smoke uses fixed CLI arguments; reject cmd metacharacters rather than
// presenting this small test helper as a general Windows shell quoting API.
export function powershellCmdInvocation(shell, command, args, env) {
  assert(path.win32.isAbsolute(shell) && /\.exe$/iu.test(shell), 'PSC_SMOKE_POWERSHELL_PATH');
  assert(path.win32.isAbsolute(command) && /\.cmd$/iu.test(command), 'PSC_SMOKE_CMD_PATH');
  assert(Array.isArray(args) && args.every(value => typeof value === 'string'), 'PSC_SMOKE_CMD_ARGUMENTS');
  for (const value of [command, ...args]) {
    assert(!/["%!\^&|<>()\r\n]/u.test(value), 'PSC_SMOKE_CMD_UNSAFE_ARGUMENT');
  }
  const source = [
    '$ErrorActionPreference = "Stop"',
    '$PSNativeCommandUseErrorActionPreference = $false',
    '[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)',
    '$request = ConvertFrom-Json -InputObject $env:PSC0_SMOKE_COMMAND',
    '$arguments = @($request.args)',
    '& $request.command @arguments',
    'if ($null -eq $LASTEXITCODE) { exit 1 }',
    'exit $LASTEXITCODE',
  ].join('\n');
  return {
    command: shell,
    args: ['-NoLogo', '-NoProfile', '-NonInteractive', '-EncodedCommand',
      Buffer.from(source, 'utf16le').toString('base64')],
    env: { ...env, PSC0_SMOKE_COMMAND: JSON.stringify({ command, args }) },
  };
}

// Narrow, non-executing evidence reader for the already hash-pinned AMD64
// payload. Layout: Microsoft's PE/COFF specification, import directories.
// https://github.com/MicrosoftDocs/win32/blob/docs/desktop-src/Debug/pe-format.md
// Import tables do not enumerate arbitrary runtime LoadLibrary calls.
export function peImportInventory(bytes) {
  const bounds = (offset, length) => {
    assert(Number.isSafeInteger(offset) && Number.isSafeInteger(length) &&
      offset >= 0 && length >= 0 && offset + length <= bytes.length, 'PSC_SMOKE_PE_BOUNDS');
    return offset;
  };
  const u16 = offset => bytes.readUInt16LE(bounds(offset, 2));
  const u32 = offset => bytes.readUInt32LE(bounds(offset, 4));
  assert.equal(u16(0), 0x5a4d, 'PSC_SMOKE_PE_DOS');
  const pe = u32(0x3c);
  assert.equal(u32(pe), 0x4550, 'PSC_SMOKE_PE_SIGNATURE');
  assert.equal(u16(pe + 4), 0x8664, 'PSC_SMOKE_PE_MACHINE');
  const count = u16(pe + 6);
  assert(count > 0 && count <= 96, 'PSC_SMOKE_PE_SECTIONS');
  const optional = pe + 24;
  const optionalSize = u16(pe + 20);
  bounds(optional, optionalSize);
  assert(optionalSize >= 112 && u16(optional) === 0x20b, 'PSC_SMOKE_PE_OPTIONAL');
  const headersSize = u32(optional + 60);
  const directories = u32(optional + 108);
  const sections = Array.from({ length: count }, (_, index) => {
    const offset = bounds(optional + optionalSize + index * 40, 40);
    return { rva: u32(offset + 12), rawSize: u32(offset + 16), raw: u32(offset + 20) };
  });
  function offsetOf(rva, length = 1) {
    if (rva < headersSize && rva + length <= headersSize) return bounds(rva, length);
    const section = sections.find(item => rva >= item.rva && rva - item.rva + length <= item.rawSize);
    assert(section, 'PSC_SMOKE_PE_RVA');
    return bounds(section.raw + rva - section.rva, length);
  }
  function dllName(rva) {
    const first = offsetOf(rva);
    let end = first;
    while (end < bytes.length && end - first < 260 && bytes[end] !== 0) end++;
    assert(end < bytes.length && bytes[end] === 0, 'PSC_SMOKE_PE_NAME');
    const name = bytes.subarray(first, end).toString('ascii');
    assert(/^[A-Za-z0-9_.-]+\.dll$/iu.test(name), 'PSC_SMOKE_PE_DLL_NAME');
    return name;
  }
  function imports(index, stride, nameOffset) {
    if (directories <= index) return [];
    assert(112 + (index + 1) * 8 <= optionalSize, 'PSC_SMOKE_PE_DIRECTORY');
    const entry = optional + 112 + index * 8;
    const rva = u32(entry);
    const size = u32(entry + 4);
    if (rva === 0 && size === 0) return [];
    assert(rva !== 0 && size >= stride && size <= 1024 * 1024, 'PSC_SMOKE_PE_IMPORT_SIZE');
    const names = [];
    for (let position = 0; position + stride <= size; position += stride) {
      const record = offsetOf(rva + position, stride);
      if (bytes.subarray(record, record + stride).every(byte => byte === 0)) {
        return [...new Set(names)].sort((a, b) => a.localeCompare(b, 'en'));
      }
      let nameRva = u32(record + nameOffset);
      if (index === 13) {
        const attributes = u32(record);
        assert(attributes === 0 || attributes === 1, 'PSC_SMOKE_PE_DELAY_ATTRIBUTES');
        if (attributes === 0) {
          const imageBase = bytes.readBigUInt64LE(bounds(optional + 24, 8));
          const relative = BigInt(nameRva) - imageBase;
          assert(relative >= 0n && relative <= 0xffffffffn, 'PSC_SMOKE_PE_DELAY_POINTER');
          nameRva = Number(relative);
        }
      }
      names.push(dllName(nameRva));
    }
    assert.fail('PSC_SMOKE_PE_IMPORT_TERMINATOR');
  }
  return {
    kind: 'pe-import-table-inventory', format: 'PE32+', machine: 'AMD64',
    coffTimeDateStamp: u32(pe + 8),
    imports: imports(1, 20, 12), delayImports: imports(13, 32, 4),
    arbitraryDynamicLoadsEnumerated: false,
  };
}

async function existingFile(candidates, label) {
  for (const candidate of candidates.filter(Boolean)) {
    assert(path.isAbsolute(candidate), label + ': require an absolute file');
    try { await access(candidate); return candidate; }
    catch (error) { if (!['ENOENT', 'ENOTDIR'].includes(error.code)) throw error; }
  }
  throw new Error(label);
}


// Run only in a fresh Actions job with Node, npm and the release tarball.
// No checkout, Lean toolchain, bootstrap seed or source compiler is required.
// Windows invokes the real npm psc.cmd shim through the installed PowerShell;
// its absolute executable is recorded and is not searched for on runtime PATH.
export async function qualifyInstalledPackage(tarballArgument, outputArgument) {
  assert(tarballArgument && outputArgument, 'usage: platform-release-smoke.mjs <tarball> <evidence-directory>');
  const tarball = path.resolve(tarballArgument);
  const evidence = path.resolve(outputArgument);
  await mkdir(evidence, { recursive: true });
  const temporary = await mkdtemp(path.join(tmpdir(), 'proofscript installed-'));
  const prefix = path.join(temporary, 'global tools');
  const project = path.join(temporary, 'consumer project');
  const observations = [];
  const digest = bytes => createHash('sha256').update(bytes).digest('hex');
  let passed = false;
  let failure;
  let tarballSha256 = null;
  let tarballBytes = null;
  let releaseIdentity = null;
  let providerRuntime = null;
  let npmRuntime = null;
  let shellRuntime = null;
  let nodeOnlyExecutionPath = false;

  function run(command, args, options = {}) {
    const result = spawnSync(command, args, {
      encoding: 'utf8', timeout: 120000, maxBuffer: 8 * 1024 * 1024,
      cwd: project, ...options,
    });
    if (result.error) throw result.error;
    // Only normalize captured command text, never artifact bytes or hashes.
    result.stdout = result.stdout.replace(/\r\n/gu, '\n');
    result.stderr = result.stderr.replace(/\r\n/gu, '\n');
    return result;
  }
  function success(result, label) {
    assert.equal(result.status, 0, label + ': ' + result.stdout + '\n' + result.stderr);
    observations.push(label);
    return result;
  }
  async function missing(file) {
    await assert.rejects(access(file), { code: 'ENOENT' });
  }
  async function writeConsumer(value) {
    await writeFile(path.join(project, 'src/consumer.ts'),
      "import { answer } from './Main.js';\n" +
      'const result: bigint = answer;\n' +
      "if (result !== " + value + "n) throw new Error('wrong compiled result');\n" +
      "console.log('PSC_INSTALLED_CONSUMER: " + value + "');\n");
  }

  try {
    assert.equal(process.arch, 'x64', 'PSC_SMOKE_ARCHITECTURE');
    const archive = await readFile(tarball);
    tarballSha256 = digest(archive);
    tarballBytes = archive.length;
    await mkdir(path.join(project, 'src'), { recursive: true });
    await writeFile(path.join(project, 'package.json'), JSON.stringify({
      name: 'proofscript-installed-fixture', private: true, type: 'module',
      proofscript: { profile: 'checked', extensions: [] },
    }, null, 2) + '\n');

    // Execute npm's JS entry with this exact Node. npm.cmd cannot be executed
    // with spawnSync shell:false on Windows, and needs no shell here.
    const npmCli = await existingFile(process.env.PSC0_SMOKE_NPM_CLI
      ? [process.env.PSC0_SMOKE_NPM_CLI]
      : [path.resolve(path.dirname(process.execPath), 'node_modules/npm/bin/npm-cli.js'),
        path.resolve(path.dirname(process.execPath), '../lib/node_modules/npm/bin/npm-cli.js')],
    'PSC_SMOKE_NPM_CLI_MISSING');
    const npmVersion = run(process.execPath, [npmCli, '--version']);
    assert.equal(npmVersion.status, 0, npmVersion.stderr);
    assert.match(npmVersion.stdout.trim(), /^[0-9]+\.[0-9]+\.[0-9]+$/u);
    if (process.env.PSC0_SMOKE_EXPECT_NPM) {
      assert.equal(npmVersion.stdout.trim(), process.env.PSC0_SMOKE_EXPECT_NPM, 'PSC_SMOKE_NPM_VERSION');
    }
    npmRuntime = { cliPath: npmCli, version: npmVersion.stdout.trim(), nodeVersion: process.version };
    success(run(process.execPath, [npmCli, 'install', '--global', '--prefix', prefix,
      '--ignore-scripts', '--no-audit', '--no-fund', tarball]),
    'fresh global tarball install without lifecycle scripts');
    const { installed, command } = installedPaths(prefix);
    const release = JSON.parse(await readFile(path.join(installed, 'release.json'), 'utf8'));
    assert.equal(release.schemaVersion, 2);
    assert.equal(release.kind, 'proofscript-release');
    assert.deepEqual(release.platforms, [{ os: 'linux', arch: 'x64' }, { os: 'win32', arch: 'x64' }]);
    const platformKey = process.platform + '-' + process.arch;
    const kernelArtifact = release.kernel.artifacts[platformKey];
    assert(kernelArtifact, 'PSC_SMOKE_KERNEL_PLATFORM');
    assert.deepEqual(kernelArtifact.dependencies, [], 'PSC_SMOKE_KERNEL_DEPENDENCIES');
    releaseIdentity = {
      version: release.version, platforms: release.platforms, compiler: release.compiler,
      kernel: release.kernel, selectedPlatform: platformKey, typescriptVersion: release.typescriptVersion,
    };
    const metadata = JSON.parse(await readFile(path.join(installed, 'package.json'), 'utf8'));
    assert.equal(metadata.name, 'proofscript');
    assert.equal(metadata.version, release.version);
    assert.equal(metadata.dependencies.typescript, '7.0.2');
    assert.equal(Object.hasOwn(metadata, 'scripts'), false);
    assert.equal(digest(await readFile(path.join(installed, 'runtime/compiler/index.js'))), release.compiler.sha256);
    const providerName = 'psc_kernel_core_provider' + (process.platform === 'win32' ? '.exe' : '');
    const providerDirectory = path.join(installed, 'runtime/kernel', platformKey);
    const provider = path.join(providerDirectory, providerName);
    const providerBytes = await readFile(provider);
    assert.equal(digest(providerBytes), kernelArtifact.sha256);

    // No Lean/lake/npm/tsc executable on PATH can satisfy the smoke. The host
    // invokes absolute packaged tools. Copying node.exe avoids symlink privilege
    // requirements on Windows; the Linux gate retains its dedicated symlink.
    const nodeOnlyPath = path.join(temporary, 'node only');
    await mkdir(nodeOnlyPath);
    if (process.platform === 'win32') await copyFile(process.execPath, path.join(nodeOnlyPath, 'node.exe'));
    else await symlink(process.execPath, path.join(nodeOnlyPath, 'node'));
    const env = nodeOnlyEnvironment(process.env, nodeOnlyPath);
    nodeOnlyExecutionPath = true;
    let invoke;
    if (process.platform === 'win32') {
      const shell = await existingFile(process.env.PSC0_SMOKE_POWERSHELL
        ? [process.env.PSC0_SMOKE_POWERSHELL]
        : [path.join(process.env.ProgramFiles ?? 'C:\\Program Files', 'PowerShell/7/pwsh.exe')],
      'PSC_SMOKE_POWERSHELL_MISSING');
      const shellVersion = run(shell, ['-NoLogo', '-NoProfile', '-NonInteractive', '-EncodedCommand',
        Buffer.from('$PSVersionTable.PSVersion.ToString()', 'utf16le').toString('base64')], { env });
      assert.equal(shellVersion.status, 0, shellVersion.stderr);
      assert.match(shellVersion.stdout.trim(), /^7\.[0-9]+\.[0-9]+(?:-[A-Za-z0-9.-]+)?$/u);
      shellRuntime = { executable: shell, version: shellVersion.stdout.trim(), route: 'npm psc.cmd via PowerShell' };
      invoke = args => {
        const request = powershellCmdInvocation(shell, command, args, env);
        return run(request.command, request.args, { env: request.env });
      };
    } else {
      invoke = args => run(command, args, { env });
    }
    const version = success(invoke(['version', '--json']), 'installed executable and version');
    const versionInfo = JSON.parse(version.stdout);
    assert.equal(versionInfo.version, release.version);
    assert.deepEqual(versionInfo.platform, { os: process.platform, arch: process.arch });
    assert.deepEqual(versionInfo.supportedPlatforms, release.platforms);
    assert.deepEqual(versionInfo.kernel, release.kernel);
    assert.equal(version.stderr, 'PSC_EXTENSIONS: []\n');
    const extensions = success(invoke(['extensions', '--json']), 'supervisor extension disclosure');
    assert.deepEqual(JSON.parse(extensions.stdout), {
      defaultExtensions: [], loadedExtensions: [], executionSupported: false,
    });

    const source = path.join(project, 'src/Main.ps');
    await writeFile(source, 'def answer : Nat := 42\n');
    const check = JSON.parse(success(invoke(['check', 'src/Main.ps', '--json']),
      'packaged compiler and native Core admission').stdout);
    assert.equal(check.kernelAdmissionAccepted, true);
    assert.equal(check.kernel.binarySha256, kernelArtifact.sha256);
    assert.equal(check.runtimeIr.status, 'not-requested');
    await missing(path.join(project, 'src/Main.ts'));

    const built = success(invoke(['build', 'src/Main.ps', '--out', 'src/Main.ts', '--json']),
      'neighboring TypeScript publication from the installed package');
    assert.equal(built.stderr, 'PSC_EXTENSIONS: []\n');
    const receipt = JSON.parse(built.stdout);
    assert.equal(receipt.schemaVersion, 4);
    assert.equal(receipt.compiler.sha256, release.compiler.sha256);
    assert.equal(receipt.kernel.binarySha256, kernelArtifact.sha256);
    assert.equal(receipt.runtimeIr.runtimeIrTypingAccepted, true);
    assert.equal(receipt.runtimeIr.traversalComplete, true);
    assert.equal(receipt.runtimeIr.sameOriginalIrCheckedBeforeEmission, true);
    assert.equal(receipt.targetValidation.version, '7.0.2');
    for (const field of ['pscvVerified', 'strictSh1Qualified', 'semanticPreservationProved']) assert.equal(receipt[field], false);
    assert.deepEqual(receipt.extensions, []);
    assert.deepEqual(receipt.artifacts.map(item => item.name), ['Main.ts']);
    let savedReceipt = await readFile(path.join(project, 'src/Main.checked.json'));
    assert.deepEqual(JSON.parse(savedReceipt.toString('utf8')), receipt);
    let generated = await readFile(path.join(project, 'src/Main.ts'));
    assert.equal(digest(generated), receipt.artifacts[0].sha256);
    await missing(path.join(project, 'src/Main.js'));
    await missing(path.join(project, 'src/Main.d.ts'));
    await writeConsumer(42);
    await writeFile(path.join(project, 'tsconfig.json'), JSON.stringify({
      compilerOptions: {
        target: 'ES2022', module: 'NodeNext', moduleResolution: 'NodeNext',
        strict: true, noEmitOnError: true, rootDir: 'src', outDir: 'dist',
      }, include: ['src/**/*.ts'],
    }, null, 2) + '\n');
    const require = createRequire(path.join(installed, 'package.json'));
    const tsPackage = require.resolve('typescript/package.json');
    const tsMetadata = JSON.parse(await readFile(tsPackage, 'utf8'));
    assert.equal(tsMetadata.version, release.typescriptVersion);
    const tsLauncher = path.resolve(path.dirname(tsPackage), tsMetadata.bin.tsc);
    success(run(process.execPath, [tsLauncher, '--project', 'tsconfig.json'], { env }),
      'existing TypeScript project typechecks generated neighbor');
    const consumer = success(run(process.execPath, ['dist/consumer.js'], { env }),
      'existing TypeScript project executes generated neighbor');
    assert.equal(consumer.stdout.trim(), 'PSC_INSTALLED_CONSUMER: 42');

    // Exercise replacement of already-owned files, including Windows rename
    // behavior, before testing retention on a rejected rebuild.
    await writeFile(source, 'def answer : Nat := 43\n');
    const rebuilt = JSON.parse(success(invoke(['build', 'src/Main.ps', '--out', 'src/Main.ts', '--json']),
      'valid rebuild replaces owned TypeScript and receipt').stdout);
    assert.notEqual(rebuilt.transactionId, receipt.transactionId);
    assert.notEqual(rebuilt.artifacts[0].sha256, receipt.artifacts[0].sha256);
    savedReceipt = await readFile(path.join(project, 'src/Main.checked.json'));
    assert.deepEqual(JSON.parse(savedReceipt.toString('utf8')), rebuilt);
    generated = await readFile(path.join(project, 'src/Main.ts'));
    assert.equal(digest(generated), rebuilt.artifacts[0].sha256);
    await writeConsumer(43);
    success(run(process.execPath, [tsLauncher, '--project', 'tsconfig.json'], { env }),
      'existing TypeScript project typechecks rebuilt neighbor');
    const changedConsumer = success(run(process.execPath, ['dist/consumer.js'], { env }),
      'existing TypeScript project executes rebuilt neighbor');
    assert.equal(changedConsumer.stdout.trim(), 'PSC_INSTALLED_CONSUMER: 43');

    await writeFile(source, 'def answer : Nat := Type\n');
    const refused = invoke(['build', 'src/Main.ps', '--out', 'src/Main.ts', '--json']);
    assert.notEqual(refused.status, 0);
    assert.equal(refused.stdout, '');
    assert.match(refused.stderr, /PSC2_CHECKED_(?:PREPARE|EMIT)_FAILED|PSC2_KERNEL_REJECTED/u);
    assert.deepEqual(await readFile(path.join(project, 'src/Main.ts')), generated);
    assert.deepEqual(await readFile(path.join(project, 'src/Main.checked.json')), savedReceipt);
    observations.push('invalid source cannot replace the previous completed output');

    await writeFile(path.join(project, 'package.json'), JSON.stringify({
      name: 'proofscript-installed-fixture', type: 'module', proofscript: { profile: 'pscv' },
    }));
    const unsupported = invoke(['check', 'src/Main.ps', '--json']);
    assert.notEqual(unsupported.status, 0);
    assert.match(unsupported.stderr, /PSC_PROJECT_PROFILE_UNSUPPORTED/u);
    observations.push('requested PSCV is explicitly refused');

    if (process.platform === 'win32') {
      const inventory = peImportInventory(providerBytes);
      // These exact imported system names were independently recorded by LLVM
      // in provider probe run 37993071033. No additional import-table name is
      // accepted, and the release bundles no DLLs.
      const systemImports = ['ADVAPI32.dll', 'IPHLPAPI.DLL', 'KERNEL32.dll', 'SHELL32.dll',
        'USER32.dll', 'USERENV.dll', 'WS2_32.dll', 'bcrypt.dll', 'dbghelp.dll',
        'icu.dll', 'ole32.dll', 'ucrtbase.dll'];
      const importedNames = [...new Set([...inventory.imports, ...inventory.delayImports]
        .map(name => name.toLowerCase()))].sort();
      assert.deepEqual(importedNames, systemImports.map(name => name.toLowerCase()).sort(),
        'PSC_SMOKE_UNQUALIFIED_DLL_IMPORT');
      providerRuntime = {
        kind: 'windows-pe-imports',
        files: [{ name: providerName, sha256: kernelArtifact.sha256, bytes: providerBytes.length, ...inventory }],
        bundledDependencies: [], systemImports,
        importResolutionTestedBy: 'successful packaged native admission with the Node-only PATH',
        arbitraryDynamicLoadsEnumerated: false,
      };
      observations.push('packaged provider PE inspection admits only the qualified system imports');
      await writeFile(path.join(evidence, 'provider-pe-imports.json'), JSON.stringify(providerRuntime, null, 2) + '\n');
    } else {
      const dependencies = success(run('/usr/bin/ldd', [provider], { env }), 'packaged provider linked-library inspection');
      assert(!/not found|\.elan|provider-source|\.lake/u.test(dependencies.stdout + dependencies.stderr),
        'packaged provider has no unprovided Lean/source/build-path shared library dependency');
      const interpreter = success(run('/usr/bin/readelf', ['-l', provider], { env }), 'packaged provider ELF interpreter inspection');
      const versions = success(run('/usr/bin/readelf', ['--version-info', provider], { env }), 'packaged provider ABI version inspection');
      providerRuntime = {
        kind: 'linux-elf',
        linkedLibraries: dependencies.stdout.trim().split('\n').map(line => line.trim()),
        interpreter: /Requesting program interpreter: ([^\]]+)/u.exec(interpreter.stdout)?.[1] ?? null,
        requiredGlibcVersions: [...new Set(versions.stdout.match(/GLIBC_[0-9]+(?:\.[0-9]+)+/gu) ?? [])].sort(),
      };
      await writeFile(path.join(evidence, 'provider-ldd.txt'), dependencies.stdout + dependencies.stderr);
      await writeFile(path.join(evidence, 'provider-elf-program-headers.txt'), interpreter.stdout);
      await writeFile(path.join(evidence, 'provider-abi-versions.txt'), versions.stdout);
    }
    await writeFile(path.join(evidence, 'installed-build-receipt.json'), savedReceipt);
    await writeFile(path.join(evidence, 'release.json'), JSON.stringify(release, null, 2) + '\n');
    passed = true;
  } catch (error) {
    failure = { name: error.name, message: error.message };
    throw error;
  } finally {
    const result = {
      schemaVersion: 2, kind: 'proofscript-installed-package-qualification',
      sourceRef: process.env.GITHUB_SHA, runId: process.env.GITHUB_RUN_ID,
      tarballSha256, tarballBytes, releaseIdentity, providerRuntime, npmRuntime, shellRuntime,
      nodeOnlyExecutionPath, nodeVersion: process.version,
      platform: process.platform, architecture: process.arch, operatingSystemRelease: operatingSystemRelease(),
      runnerImage: process.env.ImageOS ?? null, runnerImageVersion: process.env.ImageVersion ?? null,
      observations, passed, ...(failure ? { failure } : {}),
      leanToolchainRequired: false, sourceCheckoutRequired: false,
      semanticPreservationProved: false, pscvVerified: false, strictSh1Qualified: false,
      selectedSeedChanged: false, npmPublished: false,
    };
    await writeFile(path.join(evidence, 'installed-package-qualification.json'), JSON.stringify(result, null, 2) + '\n');
    console.log('PSC0_INSTALLED_PACKAGE: ' + JSON.stringify(result));
    await rm(temporary, { recursive: true, force: true, maxRetries: 5, retryDelay: 100 });
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  await qualifyInstalledPackage(...process.argv.slice(2));
}
