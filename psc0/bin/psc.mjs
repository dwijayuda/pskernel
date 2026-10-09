#!/usr/bin/env node
import { readFile, realpath } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';
import { buildChecked } from '../scripts/checked-build.mjs';
import { initProject } from '../scripts/project-init.mjs';
import {
  validateCommandExtensionConfig, discoverCommandExtensions, executeCommandExtension,
} from '../scripts/command-extensions.mjs';
import {
  readReleaseManifest, releaseRuntimePaths, assertReleasePlatform,
} from '../scripts/release-manifest.mjs';

const installedRoot = fileURLToPath(new URL('../', import.meta.url));
const help = `Usage: psc init [directory] [--json]
       psc check [entry.ps|entry.lean] [--json]
       psc build [entry.ps|entry.lean] [--out file.ts|file.js] [--json]
       psc dev [entry.ps|entry.lean] --once [--out file.ts] [--json]
       psc examples [--json]
       psc extensions [--json]
       psc version [--json]

A root package.json can set proofscript.entry and proofscript.out.
Without an output setting, build writes neighboring .ts plus a checked receipt.
init never installs packages; existing package.json and tsconfig.json are preserved.
dev requires an explicitly enabled, locally installed psc-command/1 Wasm extension.
This preview supports one-shot dev requests. Watch, LSP, PSCV, general language
extensions, and neighboring module facades remain later milestones.
`;

function fail(message) { throw new Error(message); }

async function nearestPackage(start) {
  let directory = path.resolve(start);
  for (let depth = 0; depth < 64; depth++) {
    const file = path.join(directory, 'package.json');
    let source;
    try { source = await readFile(file, 'utf8'); }
    catch (error) { if (error.code !== 'ENOENT') throw error; }
    if (source !== undefined) {
      if (Buffer.byteLength(source) > 1024 * 1024) fail('PSC_PROJECT_PACKAGE_JSON: size');
      let metadata;
      try { metadata = JSON.parse(source.replace(/^\uFEFF/u, '')); }
      catch (cause) { throw new Error('PSC_PROJECT_PACKAGE_JSON: ' + file, { cause }); }
      if (metadata === null || typeof metadata !== 'object' || Array.isArray(metadata)) {
        fail('PSC_PROJECT_PACKAGE_JSON: ' + file);
      }
      return { root: directory, file, metadata };
    }
    const parent = path.dirname(directory);
    if (parent === directory) return null;
    directory = parent;
  }
  fail('PSC_PROJECT_ROOT_DEPTH');
}

function configuredPath(value, kind) {
  return typeof value === 'string' && value.length > 0 && value.length <= 4096 &&
    !/[\u0000-\u001f\\:]/u.test(value) &&
    !path.posix.isAbsolute(value) && !path.win32.isAbsolute(value) &&
    !value.split('/').some(part => part === '..' || part === '') &&
    (kind === 'entry' ? /\.(?:ps|lean)$/u : /\.(?:ts|js)$/u).test(value);
}

function checkProjectPolicy(project) {
  if (!project || !Object.hasOwn(project.metadata, 'proofscript')) return;
  const config = project.metadata.proofscript;
  if (config === null || typeof config !== 'object' || Array.isArray(config) ||
      Object.keys(config).some(key => !['profile', 'entry', 'out', 'extensions'].includes(key))) {
    fail('PSC_PROJECT_CONFIGURATION_UNSUPPORTED: ' + project.file +
      ' supports proofscript.profile="checked", entry, out, and command extensions');
  }
  if (Object.hasOwn(config, 'profile') && config.profile !== 'checked') {
    fail('PSC_PROJECT_PROFILE_UNSUPPORTED: ' + project.file);
  }
  for (const key of ['entry', 'out']) {
    if (Object.hasOwn(config, key) && !configuredPath(config[key], key)) {
      fail('PSC_PROJECT_PATH: proofscript.' + key + ' must be a relative project file path using /');
    }
  }
  validateCommandExtensionConfig(config.extensions);
}

async function selectedProject(cwd, entry) {
  // The caller selects the project. A nested source/dependency package cannot
  // replace its policy. With no caller project, an entry-owned project may apply.
  const caller = await nearestPackage(cwd);
  const project = caller ?? (entry ? await nearestPackage(path.dirname(entry)) : null);
  checkProjectPolicy(project);
  return project;
}

async function assertEntryProject(project, entry) {
  if (!project) return;
  const [root, source] = await Promise.all([realpath(project.root), realpath(entry)]);
  const relative = path.relative(root, source);
  if (relative === '..' || relative.startsWith('..' + path.sep) || path.isAbsolute(relative)) {
    fail('PSC_ENTRY_OUTSIDE_PROJECT: run psc from the intended project directory');
  }
}

function parseCommand(args) {
  const [command = 'help', ...rest] = args;
  if (['help', '--help', '-h'].includes(command)) {
    if (rest.length) fail('PSC_CLI_ARGUMENT: help takes no arguments');
    return { command: 'help' };
  }
  if (['version', '--version', '-v', 'extensions', 'examples'].includes(command)) {
    if (rest.length > 1 || (rest.length === 1 && rest[0] !== '--json')) {
      fail('PSC_CLI_ARGUMENT: only --json is supported for ' + command);
    }
    return { command: ['extensions', 'examples'].includes(command) ? command : 'version',
      json: rest.length === 1 };
  }
  if (command === 'init') {
    let directory;
    let json = false;
    for (const argument of rest) {
      if (argument === '--json' && !json) json = true;
      else if (!argument.startsWith('-') && directory === undefined) directory = argument;
      else fail('PSC_CLI_ARGUMENT_UNSUPPORTED: ' + argument);
    }
    return { command, directory: directory ?? '.', json };
  }
  if (['watch', 'lsp'].includes(command)) fail('PSC_COMMAND_UNSUPPORTED: ' + command);
  if (!['check', 'build', 'dev'].includes(command)) fail('PSC_CLI_COMMAND: ' + command);
  let entry;
  if (rest.length && !rest[0].startsWith('-')) {
    entry = rest.shift();
    if (!/\.(?:ps|lean)$/u.test(entry)) fail('PSC_CLI_ENTRY: expected a .ps or .lean source path');
  }
  let output;
  let json = false;
  let once = false;
  while (rest.length) {
    const flag = rest.shift();
    if (flag === '--json' && !json) json = true;
    else if (flag === '--once' && command === 'dev' && !once) once = true;
    else if (flag === '--watch' && command === 'dev') {
      fail('PSC_DEV_WATCH_UNSUPPORTED: watch follows the module/export and ABI milestone; use --once');
    } else if (flag === '--out' && command !== 'check' && output === undefined) {
      output = rest.shift();
      if (!output || output.startsWith('-') || !/\.(?:ts|js)$/u.test(output)) {
        fail('PSC_CLI_OUTPUT: --out requires a .ts or .js path');
      }
    } else fail('PSC_CLI_ARGUMENT_UNSUPPORTED: ' + flag);
  }
  if (command === 'dev' && !once) fail('PSC_DEV_ONCE_REQUIRED: use dev --once');
  return { command, entry, output, json };
}

async function main() {
  // Guest output never owns this channel. Status is host-serialized before any
  // external instantiation, and every executed extension appears in the receipt.
  const disclose = records => process.stderr.write('PSC_EXTENSIONS: ' + JSON.stringify(records) + '\n');
  disclose([]);
  const options = parseCommand(process.argv.slice(2));
  if (options.command === 'help') {
    process.stdout.write(help);
    return;
  }
  const release = await readReleaseManifest(installedRoot);
  if (options.command === 'version') {
    process.stdout.write(options.json ? JSON.stringify({
      name: 'proofscript', version: release.version,
      platform: { os: process.platform, arch: process.arch }, supportedPlatforms: release.platforms,
      compiler: release.compiler, kernel: release.kernel,
      typescriptVersion: release.typescriptVersion, extensions: [],
      extensionProtocols: ['psc-command/1'],
    }, null, 2) + '\n' : 'psc ' + release.version + '\n');
    return;
  }
  const cwd = process.cwd();
  if (options.command === 'init') {
    const result = await initProject({ directory: options.directory, cwd, version: release.version });
    process.stdout.write(options.json ? JSON.stringify(result, null, 2) + '\n'
      : 'psc: initialized ' + result.projectRoot + '\nRead PROOFSCRIPT.md for installation and build commands.\n');
    return;
  }
  if (options.command === 'examples') {
    const examples = [
      { name: 'checked-nat', description: 'A checked Nat constant and neighboring TypeScript output.' },
      { name: 'existing-typescript', description: 'A handwritten TypeScript consumer of one generated module.' },
      { name: 'rejected-source', description: 'An ill-typed source that must not publish output.' },
    ].map(item => ({ ...item, path: path.join(installedRoot, 'examples/platform', item.name) }));
    process.stdout.write(options.json ? JSON.stringify({ examples }, null, 2) + '\n'
      : examples.map(item => item.name + ': ' + item.description + '\n  ' + item.path).join('\n') + '\n');
    return;
  }
  const explicitEntry = options.entry ? path.resolve(cwd, options.entry) : undefined;
  const project = await selectedProject(cwd, explicitEntry);
  if (options.command === 'extensions') {
    const configured = project ? await discoverCommandExtensions({
      projectRoot: project.root, projectMetadata: project.metadata,
    }) : [];
    const result = { defaultExtensions: [], configuredExtensions: configured.map(item => item.report),
      loadedExtensions: [], executionSupported: true, protocol: 'psc-command/1' };
    process.stdout.write(options.json ? JSON.stringify(result, null, 2) + '\n'
      : (configured.length ? configured.map(item => item.report.package).join(', ') +
        ' configured for command:dev; no guest executed by this command.\n'
        : 'No external extensions configured or loaded. The psc-command/1 demo protocol is available.\n'));
    return;
  }
  const config = project?.metadata.proofscript;
  const entryPath = explicitEntry ?? (config?.entry ? path.resolve(project.root, config.entry) : undefined);
  if (!entryPath) fail('PSC_CLI_ENTRY_REQUIRED: provide an entry or set proofscript.entry in package.json');
  await assertEntryProject(project, entryPath);
  const outputPath = options.command === 'check' ? undefined : options.output
    ? path.resolve(cwd, options.output)
    : !explicitEntry && config?.out ? path.resolve(project.root, config.out)
      : entryPath.replace(/\.(?:ps|lean)$/u, '.ts');
  if (options.command === 'dev' && !outputPath.endsWith('.ts')) {
    fail('PSC_DEV_OUTPUT_KIND: the one-shot command demo publishes a .ts project bundle');
  }
  assertReleasePlatform(release);
  for (const variable of ['PSC0_TSC', 'PSC0_TYPESCRIPT_VERSION', 'PSC_KERNEL_CORE_PROVIDER_BIN',
    'PSC_LEAN_KERNEL_PROVIDER_BIN']) {
    if (Object.hasOwn(process.env, variable)) fail('PSC_RELEASE_OVERRIDE_UNSUPPORTED: ' + variable);
  }
  if (options.command !== 'check') {
    let metadata;
    try {
      const installed = createRequire(import.meta.url).resolve('typescript/package.json');
      metadata = JSON.parse(await readFile(installed, 'utf8'));
    } catch (cause) {
      throw new Error('PSC_RELEASE_TYPESCRIPT_MISSING: reinstall the complete proofscript package', { cause });
    }
    if (metadata.name !== 'typescript' || metadata.version !== release.typescriptVersion) {
      fail('PSC_RELEASE_TYPESCRIPT_PIN: require installed TypeScript ' + release.typescriptVersion);
    }
  }
  const controller = new AbortController();
  let interrupted;
  const stop = signal => {
    interrupted = signal;
    controller.abort(new Error('PSC_INTERRUPTED: ' + signal));
  };
  const onInterrupt = () => stop('SIGINT');
  const onTerminate = () => stop('SIGTERM');
  process.once('SIGINT', onInterrupt);
  process.once('SIGTERM', onTerminate);
  try {
    let extensionExecution;
    if (options.command === 'dev') {
      const configured = project ? await discoverCommandExtensions({
        projectRoot: project.root, projectMetadata: project.metadata,
      }) : [];
      if (configured.length === 0) fail('PSC_DEV_EXTENSION_REQUIRED: install and enable a command:dev extension in the root project');
      if (configured.length !== 1) fail('PSC_DEV_EXTENSION_AMBIGUOUS');
      extensionExecution = await executeCommandExtension(configured[0], {
        event: 0, signal: controller.signal, onState: record => { disclose([record]); },
      });
      if (!extensionExecution.requestBuild) fail('PSC_DEV_BUILD_NOT_REQUESTED');
    }
    const receipt = await buildChecked({
      entryPath, ...(outputPath ? { outputPath } : {}),
      ...releaseRuntimePaths(installedRoot),
      compilerSha256: release.compiler.sha256,
      kernel: release.kernel.selector, profile: 'checked',
      checkOnly: options.command === 'check', signal: controller.signal,
      ...(extensionExecution ? { extensionExecution } : {}),
    });
    const result = options.command === 'dev'
      ? { command: 'dev', extensions: receipt.extensions, receipt } : receipt;
    process.stdout.write(options.json ? JSON.stringify(result, null, 2) + '\n'
      : 'psc: ' + options.command + ' completed for ' + (options.entry ?? config?.entry) + '\n');
  } finally {
    process.removeListener('SIGINT', onInterrupt);
    process.removeListener('SIGTERM', onTerminate);
    if (interrupted) process.exitCode = interrupted === 'SIGINT' ? 130 : 143;
  }
}

try { await main(); }
catch (error) {
  process.stderr.write('psc: ' + (error?.message ?? String(error)) + '\n');
  process.exitCode ||= 1;
}
