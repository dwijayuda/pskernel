import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { access, copyFile, mkdir, mkdtemp, readFile, realpath, rm, symlink, writeFile } from 'node:fs/promises';
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
export async function qualifyInstalledPackage(tarballArgument, outputArgument, psdevTarballArgument, thirdPartyTarballArgument) {
  assert(tarballArgument && outputArgument && psdevTarballArgument,
    'usage: platform-release-smoke.mjs <proofscript-tarball> <evidence-directory> <psdev-tarball> [third-party-tarball]');
  const tarball = path.resolve(tarballArgument);
  const evidence = path.resolve(outputArgument);
  const extensionTarballs = [psdevTarballArgument, thirdPartyTarballArgument].filter(Boolean).map(file => path.resolve(file));
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
  const extensionDemos = [];
  let libraryEvidence = null;

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
      scripts: { existing: 'node dist/consumer.js' },
      existingProjectSentinel: 'preserve this project metadata',
      proofscript: { profile: 'checked', extensions: [] },
    }, null, 2) + '\n');
    await writeConsumer(42);
    await writeFile(path.join(project, 'tsconfig.json'), JSON.stringify({
      compilerOptions: {
        target: 'ES2022', module: 'NodeNext', moduleResolution: 'NodeNext',
        strict: true, noEmitOnError: true, rootDir: 'src', outDir: 'dist',
      }, include: ['src/**/*.ts'],
    }, null, 2) + '\n');
    const existingProjectFiles = await Promise.all(['package.json', 'tsconfig.json', 'src/consumer.ts']
      .map(async file => ({ file, bytes: await readFile(path.join(project, file)) })));

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
      invoke = (args, cwd = project) => {
        const request = powershellCmdInvocation(shell, command, args, env);
        return run(request.command, request.args, { env: request.env, cwd });
      };
    } else {
      invoke = (args, cwd = project) => run(command, args, { env, cwd });
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
      defaultExtensions: [], configuredExtensions: [], loadedExtensions: [],
      executionSupported: true, protocol: 'psc-command/1',
    });

    const initialized = path.join(temporary, 'initialized project');
    const initializedResult = JSON.parse(success(invoke(['init', initialized, '--json']),
      'new project initialization from the installed executable').stdout);
    assert.equal(initializedResult.mode, 'new');
    assert.equal(path.resolve(initializedResult.projectRoot), initialized);
    assert.deepEqual([...initializedResult.createdFiles].sort(), ['PROOFSCRIPT.md', 'package.json', 'src/Main.ps']);
    const initializedMetadata = JSON.parse(await readFile(path.join(initialized, 'package.json'), 'utf8'));
    assert.equal(initializedMetadata.devDependencies.proofscript, release.version);
    assert.deepEqual(initializedMetadata.proofscript, {
      profile: 'checked', entry: 'src/Main.ps', out: 'src/Main.ts', extensions: [],
    });
    await missing(path.join(initialized, 'node_modules'));
    const initializedFiles = await Promise.all(initializedResult.createdFiles
      .map(async file => ({ file, bytes: await readFile(path.join(initialized, file)) })));
    const repeatedInit = invoke(['init', initialized, '--json']);
    assert.notEqual(repeatedInit.status, 0);
    assert.equal(repeatedInit.stdout, '');
    assert.match(repeatedInit.stderr, /PSC_INIT_CONFLICT/u);
    for (const file of initializedFiles) {
      assert.deepEqual(await readFile(path.join(initialized, file.file)), file.bytes);
    }
    observations.push('repeated initialization refuses conflicts without replacing files');

    const exampleList = JSON.parse(success(invoke(['examples', '--json']),
      'installed example catalog is available').stdout);
    assert.deepEqual(exampleList.examples.map(item => item.name).sort(),
      ['checked-library', 'checked-nat', 'existing-typescript', 'rejected-source']);
    for (const item of exampleList.examples) {
      assert.equal(item.path, path.join(installed, 'examples/platform', item.name));
      assert.equal(typeof item.description, 'string');
      assert(item.description.length > 0);
      await access(path.join(item.path, 'README.md'));
    }
    const checkedExample = await readFile(path.join(installed, 'examples/platform/checked-nat/src/Main.ps'));
    assert.deepEqual(await readFile(path.join(initialized, 'src/Main.ps')), checkedExample);
    const initializedCheck = JSON.parse(success(invoke(['check', '--json'], initialized),
      'initialized project defaults admit the bundled Nat example').stdout);
    assert.equal(initializedCheck.kernelAdmissionAccepted, true);
    const initializedBuild = JSON.parse(success(invoke(['build', '--json'], initialized),
      'initialized project defaults publish checked neighboring TypeScript').stdout);
    assert.equal(initializedBuild.runtimeIr.runtimeIrTypingAccepted, true);
    assert.equal(initializedBuild.kernel.binarySha256, kernelArtifact.sha256);
    assert.equal(initializedBuild.targetValidation.version, '7.0.2');
    assert.equal(initializedBuild.semanticPreservationProved, false);
    assert.deepEqual(initializedBuild.extensions, []);
    assert.equal(digest(await readFile(path.join(initialized, 'src/Main.ts'))), initializedBuild.artifacts[0].sha256);

    const existingInit = JSON.parse(success(invoke(['init', '--json']),
      'initialization adds ProofScript to an existing TypeScript project').stdout);
    assert.equal(existingInit.mode, 'existing');
    assert.deepEqual([...existingInit.createdFiles].sort(), ['PROOFSCRIPT.md', 'src/Main.ps']);
    for (const file of existingProjectFiles) {
      assert.deepEqual(await readFile(path.join(project, file.file)), file.bytes);
    }
    observations.push('existing package scripts, TypeScript configuration and consumer source are unchanged');

    const source = path.join(project, 'src/Main.ps');
    assert.equal(await readFile(source, 'utf8'), 'def answer : Nat := 42\n');
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

    await writeFile(source, await readFile(path.join(installed, 'examples/platform/rejected-source/Main.ps')));
    const refused = invoke(['build', 'src/Main.ps', '--out', 'src/Main.ts', '--json']);
    assert.notEqual(refused.status, 0);
    assert.equal(refused.stdout, '');
    assert.match(refused.stderr, /PSC2_CHECKED_(?:PREPARE|EMIT)_FAILED|PSC2_KERNEL_REJECTED/u);
    assert.deepEqual(await readFile(path.join(project, 'src/Main.ts')), generated);
    assert.deepEqual(await readFile(path.join(project, 'src/Main.checked.json')), savedReceipt);
    observations.push('invalid source cannot replace the previous completed output');


    const libraryExample = path.join(installed, 'examples/platform/checked-library');
    const libraryFiles = ['README.md', 'package.json', 'tsconfig.json',
      'src/Quantity.ps', 'src/Main.ps', 'src/consumer.ts'];
    async function copyLibrary(directory) {
      for (const file of libraryFiles) {
        const target = path.join(directory, file);
        await mkdir(path.dirname(target), { recursive: true });
        await copyFile(path.join(libraryExample, file), target);
      }
    }
    const libraryProject = path.join(temporary, 'checked library project');
    await copyLibrary(libraryProject);
    const libraryMetadataBytes = await readFile(path.join(libraryProject, 'package.json'));
    const libraryMetadata = JSON.parse(libraryMetadataBytes.toString('utf8'));
    assert.equal(libraryMetadata.devDependencies.proofscript, release.version);
    assert.equal(libraryMetadata.devDependencies.typescript, '7.0.2');
    const libraryConfig = libraryMetadata.proofscript;
    assert.equal(libraryConfig.entry, 'src/Main.ps');
    assert.deepEqual(libraryConfig.exports, {
      'src/Quantity.ps': ['Quantity', 'makeQuantity'],
      'src/Main.ps': ['readQuantity', 'sameQuantity'],
    });
    const libraryBundle = libraryConfig.out;
    const libraryReceiptPath = libraryBundle.replace(/\.ts$/u, '.checked.json');
    const facadeSources = Object.keys(libraryConfig.exports);
    const facadeFiles = facadeSources.map(file => file.replace(/\.ps$/u, '.ts'));
    const libraryArtifactNames = [libraryBundle, ...facadeFiles].sort();
    const handwritten = await Promise.all(['README.md', 'package.json', 'tsconfig.json', 'src/consumer.ts']
      .map(async file => ({ file, bytes: await readFile(path.join(libraryProject, file)) })));
    const libraryCheck = JSON.parse(success(invoke(['check', '--json'], libraryProject),
      'installed T1 project checks both source modules without publication').stdout);
    assert.equal(libraryCheck.kernelAdmissionAccepted, true);
    assert.equal(libraryCheck.kernel.binarySha256, kernelArtifact.sha256);
    assert.equal(libraryCheck.sourceCount, 2);
    assert.equal(libraryCheck.library.profile, 'psc-ts-library/1');
    assert.equal(libraryCheck.library.abiStatus, 'not-requested');
    assert.equal(Object.hasOwn(libraryCheck, 'artifacts'), false);
    for (const file of [...libraryArtifactNames, libraryReceiptPath]) {
      await missing(path.join(libraryProject, file));
    }
    async function verifyLibraryReceipt(value) {
      assert.equal(value.schemaVersion, 4);
      assert.equal(value.kind, 'psc0-checked-build');
      assert.equal(value.compiler.sha256, release.compiler.sha256);
      assert.equal(value.kernel.binarySha256, kernelArtifact.sha256);
      assert.equal(value.kernelAdmissionAccepted, true);
      assert.equal(value.sourceCount, 2);
      assert.equal(value.outputOwner, 'src/Main.ps');
      assert.equal(value.library.profile, 'psc-ts-library/1');
      assert.equal(value.library.abiStatus, 'checked-bounded');
      assert.match(value.library.exportSelectionSha256, /^[a-f0-9]{64}$/u);
      assert.equal(value.library.configSha256, digest(libraryMetadataBytes));
      assert.match(value.library.publicInterfaceSha256, /^[a-f0-9]{64}$/u);
      assert.equal(value.runtimeIr.publicInterfaceSha256, value.library.publicInterfaceSha256);
      assert.equal(value.runtimeIr.emitter, 'psCompilerCheckedTypeScriptProjectFromPrepared');
      assert.equal(value.runtimeIr.runtimeIrTypingAccepted, true);
      assert.equal(value.runtimeIr.traversalComplete, true);
      assert.equal(value.runtimeIr.sameOriginalIrCheckedBeforeEmission, true);
      assert.equal(value.targetValidation.version, '7.0.2');
      assert.equal(value.targetValidation.strict, true);
      assert.equal(value.targetValidation.noEmitOnError, true);
      assert.equal(value.publication.layout, 'psc-ts-library/1');
      assert.equal(value.publication.bundle, libraryBundle);
      assert.deepEqual([...value.publication.facadeSources].sort(), [...facadeSources].sort());
      assert.deepEqual(value.artifacts.map(item => item.name).sort(), libraryArtifactNames);
      assert.deepEqual(value.extensions, []);
      for (const field of ['pscvVerified', 'strictSh1Qualified', 'semanticPreservationProved']) {
        assert.equal(value[field], false);
      }
      const files = new Map();
      for (const artifact of value.artifacts) {
        const bytes = await readFile(path.join(libraryProject, artifact.name));
        assert.equal(digest(bytes), artifact.sha256, artifact.name + ' T1 digest');
        assert.equal(bytes.length, artifact.bytes, artifact.name + ' T1 byte length');
        files.set(artifact.name, bytes);
      }
      assert.equal(digest(files.get(libraryBundle)), value.typeScriptSha256);
      const saved = await readFile(path.join(libraryProject, libraryReceiptPath));
      assert.deepEqual(JSON.parse(saved.toString('utf8')), value);
      files.set(libraryReceiptPath, saved);
      for (const item of handwritten) {
        assert.deepEqual(await readFile(path.join(libraryProject, item.file)), item.bytes);
      }
      return files;
    }
    const firstLibrary = JSON.parse(success(invoke(['build', '--json'], libraryProject),
      'installed T1 build publishes one bundle and both owned neighboring facades').stdout);
    await verifyLibraryReceipt(firstLibrary);
    success(run(process.execPath, [tsLauncher, '--project', 'tsconfig.json'],
      { env, cwd: libraryProject }), 'installed T1 neighbors typecheck in a handwritten TypeScript project');
    const libraryConsumer = success(run(process.execPath, ['dist/consumer.js'], { env, cwd: libraryProject }),
      'installed T1 consumer shares opaque identity and rejects malformed boundary values');
    assert.equal(libraryConsumer.stdout.trim(), 'ProofScript library answer: 42');
    await writeFile(path.join(evidence, 'installed-library-first-receipt.json'),
      JSON.stringify(firstLibrary, null, 2) + '\n');

    const quantityPath = path.join(libraryProject, 'src/Quantity.ps');
    const initialQuantity = await readFile(quantityPath, 'utf8');
    const changedQuantity = initialQuantity.replace('Quantity.mk(value)', 'Quantity.mk(Nat.succ(value))');
    assert.notEqual(changedQuantity, initialQuantity);
    await writeFile(quantityPath, changedQuantity);
    const rebuiltLibrary = JSON.parse(success(invoke(['build', '--json'], libraryProject),
      'installed T1 imported-body edit replaces one complete owned generation').stdout);
    assert.notEqual(rebuiltLibrary.transactionId, firstLibrary.transactionId);
    assert.notEqual(rebuiltLibrary.typeScriptSha256, firstLibrary.typeScriptSha256);
    const acceptedLibraryFiles = await verifyLibraryReceipt(rebuiltLibrary);
    success(run(process.execPath, [tsLauncher, '--project', 'tsconfig.json'],
      { env, cwd: libraryProject }), 'installed T1 changed generation typechecks before downstream execution');
    const changedLibraryConsumer = success(run(process.execPath, ['--input-type=module', '--eval',
      "import { makeQuantity } from './dist/Quantity.js';\n" +
      "import { readQuantity, sameQuantity } from './dist/Main.js';\n" +
      "const q = makeQuantity(42n);\n" +
      "if (readQuantity(q) !== 43n || sameQuantity(q) !== q) throw new Error('changed library result');\n" +
      "console.log('PSC_INSTALLED_LIBRARY: 43');\n"], { env, cwd: libraryProject }),
    'installed T1 changed consumer observes the imported-body result');
    assert.equal(changedLibraryConsumer.stdout.trim(), 'PSC_INSTALLED_LIBRARY: 43');

    const mainPath = path.join(libraryProject, 'src/Main.ps');
    const initialMain = await readFile(mainPath, 'utf8');
    const invalidMain = initialMain.replace(
      'def readQuantity(value : Quantity) : Nat', 'def readQuantity(value : Quantity) : Quantity');
    assert.notEqual(invalidMain, initialMain);
    await writeFile(mainPath, invalidMain);
    const rejectedLibrary = invoke(['build', '--json'], libraryProject);
    assert.notEqual(rejectedLibrary.status, 0);
    assert.equal(rejectedLibrary.stdout, '');
    assert.match(rejectedLibrary.stderr,
      /PSC2_(?:CHECKED_(?:PROJECT_)?(?:PREPARE|EMIT)_FAILED|KERNEL_REJECTED)/u);
    for (const [file, bytes] of acceptedLibraryFiles) {
      assert.deepEqual(await readFile(path.join(libraryProject, file)), bytes);
    }
    observations.push('invalid T1 source preserves every artifact and the last completed project receipt');

    const collisionProject = path.join(temporary, 'library collision project');
    await copyLibrary(collisionProject);
    const handwrittenFacade = 'export const handwritten = true;\n';
    await writeFile(path.join(collisionProject, 'src/Main.ts'), handwrittenFacade);
    const collision = invoke(['build', '--json'], collisionProject);
    assert.notEqual(collision.status, 0);
    assert.equal(collision.stdout, '');
    assert.match(collision.stderr, /PSC0_OUTPUT_UNOWNED/u);
    assert.equal(await readFile(path.join(collisionProject, 'src/Main.ts'), 'utf8'), handwrittenFacade);
    for (const file of [libraryBundle, 'src/Quantity.ts', libraryReceiptPath]) {
      await missing(path.join(collisionProject, file));
    }
    observations.push('T1 refuses a handwritten neighbor before publishing any project artifact');
    libraryEvidence = {
      profile: 'psc-ts-library/1', sourceCount: 2,
      projectConfigSha256: digest(libraryMetadataBytes),
      compilerSha256: release.compiler.sha256, kernelSha256: kernelArtifact.sha256,
      bundle: libraryBundle, facadeSources, artifacts: libraryArtifactNames,
      firstTransactionId: firstLibrary.transactionId, changedTransactionId: rebuiltLibrary.transactionId,
      publicInterfaceSha256: rebuiltLibrary.library.publicInterfaceSha256,
      firstConsumer: libraryConsumer.stdout.trim(), changedConsumer: changedLibraryConsumer.stdout.trim(),
      handwrittenFilesPreserved: true, rejectedBuildPreservedCompletedGeneration: true,
      handwrittenCollisionRefused: true, passed: true,
    };
    await writeFile(path.join(evidence, 'installed-library-build-receipt.json'),
      JSON.stringify(rebuiltLibrary, null, 2) + '\n');

    for (const [extensionIndex, extensionTarball] of extensionTarballs.entries()) {
      const packageName = extensionIndex === 0 ? 'psdev' : '@psc-demo/pshello';
      const packageVersion = release.version;
      const packageRoot = path.join(project, 'node_modules', packageName);
      const archive = await readFile(extensionTarball);
      const inactiveMetadata = JSON.parse(await readFile(path.join(project, 'package.json'), 'utf8'));
      inactiveMetadata.proofscript.extensions = [];
      await writeFile(path.join(project, 'package.json'), JSON.stringify(inactiveMetadata, null, 2) + '\n');
      await writeFile(source, 'def answer : Nat := ' + (44 + extensionIndex) + '\n');
      success(run(process.execPath, [npmCli, 'install', '--save-dev', '--save-exact',
        '--ignore-scripts', '--no-audit', '--no-fund', extensionTarball], { env }),
      'local ' + packageName + ' tarball installs without lifecycle scripts');
      const packageJsonPath = path.join(packageRoot, 'package.json');
      const packageMetadata = JSON.parse(await readFile(packageJsonPath, 'utf8'));
      assert.equal(packageMetadata.name, packageName);
      assert.equal(packageMetadata.version, packageVersion);
      assert.equal(Object.hasOwn(packageMetadata, 'scripts'), false);
      assert.equal(Object.keys(packageMetadata.dependencies ?? {}).length, 0);
      const lockBytes = await readFile(path.join(project, 'package-lock.json'));
      const lock = JSON.parse(lockBytes.toString('utf8'));
      assert.equal(lock.lockfileVersion, 3);
      const lockedPackage = lock.packages['node_modules/' + packageName];
      assert.equal(lockedPackage.version, packageVersion);
      assert.equal(lockedPackage.link, undefined);
      assert.equal(lockedPackage.integrity, 'sha512-' + createHash('sha512').update(archive).digest('base64'));
      const inactive = JSON.parse(success(invoke(['extensions', '--json']),
        'installing ' + packageName + ' alone leaves extensions inactive').stdout);
      assert.deepEqual(inactive.configuredExtensions, []);
      assert.deepEqual(inactive.loadedExtensions, []);
      const inactiveDev = invoke(['dev', 'src/Main.ps', '--once', '--out', 'src/Main.ts', '--json']);
      assert.notEqual(inactiveDev.status, 0);
      assert.equal(inactiveDev.stdout, '');
      assert.match(inactiveDev.stderr, /PSC_DEV_EXTENSION_REQUIRED/u);
      assert.deepEqual(await readFile(path.join(project, 'src/Main.ts')), generated);
      assert.deepEqual(await readFile(path.join(project, 'src/Main.checked.json')), savedReceipt);
      observations.push('unactivated ' + packageName + ' cannot run a dev build');

      // npm package metadata may advertise executable JS. The command loader
      // reads only its data descriptor and authenticated Wasm bytes. This poison
      // entry is an observable assertion that Node package loading never occurs.
      const poisonSentinel = path.join(temporary, 'poison-' + extensionIndex + '.txt');
      await writeFile(path.join(packageRoot, 'ignored-main.mjs'),
        "import { writeFileSync } from 'node:fs';\n" +
        'writeFileSync(' + JSON.stringify(poisonSentinel) + ", 'executed');\n" +
        "throw new Error('PSC_SMOKE_JAVASCRIPT_ENTRYPOINT_EXECUTED');\n");
      packageMetadata.main = './ignored-main.mjs';
      await writeFile(packageJsonPath, JSON.stringify(packageMetadata, null, 2) + '\n');
      const activeMetadata = JSON.parse(await readFile(path.join(project, 'package.json'), 'utf8'));
      activeMetadata.proofscript.extensions = [{ package: packageName, enable: ['command:dev'] }];
      await writeFile(path.join(project, 'package.json'), JSON.stringify(activeMetadata, null, 2) + '\n');
      const descriptorBytes = await readFile(path.join(packageRoot, 'proofscript-extension.json'));
      const descriptor = JSON.parse(descriptorBytes.toString('utf8'));
      const modulePath = path.join(packageRoot, 'command.wasm');
      const moduleBytes = await readFile(modulePath);
      assert.equal(digest(moduleBytes), descriptor.sha256);
      const configured = JSON.parse(success(invoke(['extensions', '--json']),
        'root activation resolves ' + packageName + ' without executing it').stdout);
      assert.equal(configured.configuredExtensions.length, 1);
      assert.deepEqual(configured.loadedExtensions, []);
      assert.equal(configured.configuredExtensions[0].package, packageName);
      assert.equal(configured.configuredExtensions[0].status, 'configured');
      assert.equal(configured.configuredExtensions[0].instantiated, false);
      await missing(poisonSentinel);
      if (extensionIndex === 0) {
        const watch = invoke(['dev', 'src/Main.ps', '--watch', '--json']);
        assert.notEqual(watch.status, 0);
        assert.equal(watch.stdout, '');
        assert.match(watch.stderr, /PSC_DEV_WATCH_UNSUPPORTED/u);
        assert.deepEqual(await readFile(path.join(project, 'src/Main.ts')), generated);
        assert.deepEqual(await readFile(path.join(project, 'src/Main.checked.json')), savedReceipt);
        observations.push('watch is explicitly refused without changing the previous output');
      }
      const dev = success(invoke(['dev', 'src/Main.ps', '--once', '--out', 'src/Main.ts', '--json']),
        'isolated ' + packageName + ' requests the ordinary checked build');
      const devResult = JSON.parse(dev.stdout);
      assert.equal(devResult.command, 'dev');
      assert.equal(devResult.extensions.length, 1);
      const record = devResult.extensions[0];
      assert.equal(record.package, packageName);
      assert.equal(record.version, packageVersion);
      assert.equal(record.origin, 'project');
      assert.equal(record.packageRoot, await realpath(packageRoot));
      assert.equal(record.entry, 'command.wasm');
      assert.equal(record.packageJsonSha256, digest(await readFile(packageJsonPath)));
      assert.equal(record.descriptorSha256, digest(descriptorBytes));
      assert.equal(record.moduleSha256, digest(moduleBytes));
      assert.equal(record.projectPackageSha256, digest(await readFile(path.join(project, 'package.json'))));
      assert.equal(record.lockfileSha256, digest(lockBytes));
      assert.equal(record.lockResolved, lockedPackage.resolved);
      assert.equal(record.lockIntegrity, lockedPackage.integrity);
      assert.equal(record.protocol, 'psc-command/1');
      assert.equal(record.operation, 'command:dev');
      assert.deepEqual(record.grants, ['command:dev']);
      assert.deepEqual(record.imports, []);
      assert.deepEqual(record.engine, {
        name: 'v8-webassembly', node: process.versions.node, v8: process.versions.v8,
      });
      assert.deepEqual(record.limits, {
        moduleBytes: 4096, linearMemoryBytes: 0, locals: 32, controlDepth: 32, wallTimeMs: 2000,
      });
      assert.equal(record.status, 'completed');
      assert.equal(record.instantiated, true);
      assert.equal(record.requestBuild, true);
      const disclosures = dev.stderr.split('\n')
        .filter(line => line.startsWith('PSC_EXTENSIONS: '))
        .map(line => JSON.parse(line.slice('PSC_EXTENSIONS: '.length)));
      assert.deepEqual(disclosures[0], []);
      assert(disclosures.some(items => items.some(item =>
        item.status === 'executing' && item.package === packageName && item.moduleSha256 === record.moduleSha256)),
      'PSC_SMOKE_EXTENSION_IDENTITY_DISCLOSED_BEFORE_EXECUTION');
      assert.deepEqual(disclosures.at(-1), devResult.extensions);
      const devReceipt = devResult.receipt;
      assert.equal(devReceipt.schemaVersion, 4);
      assert.deepEqual(devReceipt.extensions, devResult.extensions);
      assert.equal(devReceipt.compiler.sha256, release.compiler.sha256);
      assert.equal(devReceipt.kernel.binarySha256, kernelArtifact.sha256);
      assert.equal(devReceipt.runtimeIr.runtimeIrTypingAccepted, true);
      assert.equal(devReceipt.runtimeIr.sameOriginalIrCheckedBeforeEmission, true);
      assert.equal(devReceipt.targetValidation.version, '7.0.2');
      for (const field of ['pscvVerified', 'strictSh1Qualified', 'semanticPreservationProved']) {
        assert.equal(devReceipt[field], false);
      }
      savedReceipt = await readFile(path.join(project, 'src/Main.checked.json'));
      assert.deepEqual(JSON.parse(savedReceipt.toString('utf8')), devReceipt);
      generated = await readFile(path.join(project, 'src/Main.ts'));
      assert.equal(digest(generated), devReceipt.artifacts[0].sha256);
      assert.equal(devReceipt.artifacts[0].name, 'Main.ts');
      await missing(poisonSentinel);
      await writeConsumer(44 + extensionIndex);
      success(run(process.execPath, [tsLauncher, '--project', 'tsconfig.json'], { env }),
        'TypeScript checks the ' + packageName + ' requested output');
      const devConsumer = success(run(process.execPath, ['dist/consumer.js'], { env }),
        'TypeScript consumer executes the ' + packageName + ' requested output');
      assert.equal(devConsumer.stdout.trim(), 'PSC_INSTALLED_CONSUMER: ' + (44 + extensionIndex));

      const corruptedModule = Buffer.from(moduleBytes);
      corruptedModule[0] ^= 0xff;
      await writeFile(modulePath, corruptedModule);
      const tampered = invoke(['dev', 'src/Main.ps', '--once', '--out', 'src/Main.ts', '--json']);
      assert.notEqual(tampered.status, 0);
      assert.equal(tampered.stdout, '');
      assert.match(tampered.stderr, /PSC_EXTENSION_MODULE_HASH/u);
      assert(tampered.stderr.startsWith('PSC_EXTENSIONS: []\n'));
      assert.deepEqual(await readFile(path.join(project, 'src/Main.ts')), generated);
      assert.deepEqual(await readFile(path.join(project, 'src/Main.checked.json')), savedReceipt);
      await missing(poisonSentinel);
      await writeFile(modulePath, moduleBytes);
      observations.push('altered ' + packageName + ' module is refused without replacing the checked output');
      extensionDemos.push({
        package: packageName, version: packageVersion,
        tarballSha256: digest(archive), tarballBytes: archive.length,
        installedWithIgnoreScripts: true, installedLocally: true,
        installationAutoActivated: false, javascriptEntrypointExecuted: false,
        tamperedModuleRefused: true, configuredRecord: configured.configuredExtensions[0],
        executedRecord: record, receiptTransactionId: devReceipt.transactionId,
        outputSha256: devReceipt.artifacts[0].sha256, consumerResult: 44 + extensionIndex,
        semanticPreservationProved: false, pscvVerified: false,
      });
    }
    await writeFile(path.join(evidence, 'installed-extension-demos.json'), JSON.stringify(extensionDemos, null, 2) + '\n');

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
      extensionDemos, libraryEvidence,
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
