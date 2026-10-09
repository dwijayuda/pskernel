#!/usr/bin/env node
import { readFile, realpath } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';
import { buildChecked } from '../scripts/checked-build.mjs';
import {
  readReleaseManifest, releaseRuntimePaths, assertReleasePlatform,
} from '../scripts/release-manifest.mjs';

const installedRoot = fileURLToPath(new URL('../', import.meta.url));
const help = `Usage: psc check <entry.ps|entry.lean> [--json]
       psc build <entry.ps|entry.lean> --out <file.ts|file.js> [--json]
       psc extensions [--json]
       psc version [--json]

This preview checks canonical admissions with PSKernel Core and validates
RuntimeIR before TypeScript emission. External extensions, watch, LSP, PSCV,
and neighboring module facades are not available in this release.
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
      let metadata;
      try { metadata = JSON.parse(source); }
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

function checkProjectPolicy(project) {
  if (!project || !Object.hasOwn(project.metadata, 'proofscript')) return;
  const config = project.metadata.proofscript;
  if (config === null || typeof config !== 'object' || Array.isArray(config) ||
      Object.keys(config).some(key => !['profile', 'extensions'].includes(key))) {
    fail('PSC_PROJECT_CONFIGURATION_UNSUPPORTED: ' + project.file +
      ' supports only proofscript.profile="checked" and proofscript.extensions=[]');
  }
  if (Object.hasOwn(config, 'profile') && config.profile !== 'checked') {
    fail('PSC_PROJECT_PROFILE_UNSUPPORTED: ' + project.file);
  }
  if (Object.hasOwn(config, 'extensions') &&
      (!Array.isArray(config.extensions) || config.extensions.length !== 0)) {
    fail('PSC_EXTENSIONS_UNSUPPORTED: external extension execution is not available');
  }
}

async function selectedProject(cwd, entry) {
  // The caller selects the project. A nested source/dependency package cannot
  // replace its policy. With no caller project, an entry-owned project may apply.
  const caller = await nearestPackage(cwd);
  const project = caller ?? (entry ? await nearestPackage(path.dirname(entry)) : null);
  checkProjectPolicy(project);
  if (project && entry) {
    const [root, source] = await Promise.all([realpath(project.root), realpath(entry)]);
    const relative = path.relative(root, source);
    if (relative === '..' || relative.startsWith('..' + path.sep) || path.isAbsolute(relative)) {
      fail('PSC_ENTRY_OUTSIDE_PROJECT: run psc from the intended project directory');
    }
  }
  return project;
}

function parseCommand(args) {
  const [command = 'help', ...rest] = args;
  if (['help', '--help', '-h'].includes(command)) {
    if (rest.length) fail('PSC_CLI_ARGUMENT: help takes no arguments');
    return { command: 'help' };
  }
  if (['version', '--version', '-v', 'extensions'].includes(command)) {
    if (rest.length > 1 || (rest.length === 1 && rest[0] !== '--json')) {
      fail('PSC_CLI_ARGUMENT: only --json is supported for ' + command);
    }
    return { command: command === 'extensions' ? command : 'version', json: rest.length === 1 };
  }
  if (['watch', 'lsp', 'dev'].includes(command)) fail('PSC_COMMAND_UNSUPPORTED: ' + command);
  if (!['check', 'build'].includes(command)) fail('PSC_CLI_COMMAND: ' + command);
  const entry = rest.shift();
  if (!entry || entry.startsWith('-') || !/\.(?:ps|lean)$/u.test(entry)) {
    fail('PSC_CLI_ENTRY: expected a .ps or .lean source path');
  }
  let output;
  let json = false;
  while (rest.length) {
    const flag = rest.shift();
    if (flag === '--json' && !json) json = true;
    else if (flag === '--out' && command === 'build' && output === undefined) {
      output = rest.shift();
      if (!output || output.startsWith('-') || !/\.(?:ts|js)$/u.test(output)) {
        fail('PSC_CLI_OUTPUT: --out requires a .ts or .js path');
      }
    } else fail('PSC_CLI_ARGUMENT_UNSUPPORTED: ' + flag);
  }
  if (command === 'build' && output === undefined) fail('PSC_CLI_OUTPUT_REQUIRED: use --out');
  return { command, entry, output, json };
}

async function main() {
  // No external code has been loaded. This supervisor-owned report is emitted
  // before configuration, compilation, or any output publication.
  process.stderr.write('PSC_EXTENSIONS: []\n');
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
    }, null, 2) + '\n' : 'psc ' + release.version + '\n');
    return;
  }
  const cwd = process.cwd();
  const entryPath = options.entry ? path.resolve(cwd, options.entry) : undefined;
  await selectedProject(cwd, entryPath);
  if (options.command === 'extensions') {
    process.stdout.write(options.json
      ? JSON.stringify({ defaultExtensions: [], loadedExtensions: [], executionSupported: false }) + '\n'
      : 'No external extensions loaded. Extension execution is not available in this preview.\n');
    return;
  }
  assertReleasePlatform(release);
  // Development-only compiler/provider/TypeScript overrides must not affect the
  // public release path. The installed TS7 dependency is resolved by the host.
  for (const variable of ['PSC0_TSC', 'PSC0_TYPESCRIPT_VERSION', 'PSC_KERNEL_CORE_PROVIDER_BIN',
    'PSC_LEAN_KERNEL_PROVIDER_BIN']) {
    if (Object.hasOwn(process.env, variable)) {
      fail('PSC_RELEASE_OVERRIDE_UNSUPPORTED: ' + variable);
    }
  }
  if (options.command === 'build') {
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
    const receipt = await buildChecked({
      entryPath,
      ...(options.output ? { outputPath: path.resolve(cwd, options.output) } : {}),
      ...releaseRuntimePaths(installedRoot),
      compilerSha256: release.compiler.sha256,
      kernel: release.kernel.selector,
      profile: 'checked',
      checkOnly: options.command === 'check',
      signal: controller.signal,
    });
    process.stdout.write(options.json ? JSON.stringify(receipt, null, 2) + '\n'
      : 'psc: ' + options.command + ' completed for ' + options.entry + '\n');
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
