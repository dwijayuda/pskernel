#!/usr/bin/env node
// Thin CLI: no independent prepare/check/emit implementation lives here.
import { readFileSync, existsSync } from 'node:fs';
import { mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { runCheckedBuild } from './build.mjs';
const meta = JSON.parse(readFileSync(new URL('../package.json', import.meta.url), 'utf8'));
const help = [
  'ProofScript PSC0 npm compiler',
  'Usage: psc version [--json]',
  '       psc init [directory] [--syntax ps|lean]',
  '       psc check <entry.ps|entry.lean> [--json]',
  '       psc build <entry.ps|entry.lean> [--out output.js|output.ts] [--json]',
  '       psc packages [--json]',
  'Check/build resources: --frontend-timeout-ms N --frontend-heap-mb N',
  'Defaults: 300000 ms accumulated frontend request time; 4096 MiB V8 old space.',
  'Resource overrides do not bypass kernel acceptance or change language rules.',
  'Bounded new-only ps-0.9-r3; JS PSKernel Core; TypeScript 7.0.2.',
  'Outputs use immutable .psc-artifacts generations and one public entry point.',
  'Lean-WASM is not an automatic fallback. Receipts are audit data, not authority.',
].join('\n');
function options(args, valueFlags, booleanFlags = ['--json']) {
  const parsed = {};
  for (let i = 0; i < args.length; i++) {
    const flag = args[i];
    if (Object.hasOwn(parsed, flag)) throw new Error('PSC_DUPLICATE_FLAG: ' + flag);
    if (booleanFlags.includes(flag)) parsed[flag] = true;
    else if (valueFlags.includes(flag)) {
      const value = args[++i];
      if (!value || value.startsWith('--')) throw new Error('PSC_FLAG_VALUE: ' + flag);
      parsed[flag] = value;
    } else throw new Error('PSC_UNKNOWN_FLAG: ' + flag);
  }
  return parsed;
}
async function init(directory, syntax) {
  if (!['ps', 'lean'].includes(syntax)) throw new Error('PSC_INIT_SYNTAX');
  const root = path.resolve(directory);
  await mkdir(path.join(root, 'src'), { recursive: true });
  const source = path.join(root, 'src', 'Main.' + syntax);
  await writeFile(source, 'def answer : Nat := 42\n', { flag: 'wx' });
  const manifest = path.join(root, 'package.json');
  if (!existsSync(manifest)) await writeFile(manifest, JSON.stringify({ name: 'proofscript-app', private: true, type: 'module', proofscript: { entry: 'src/Main.' + syntax, out: 'src/Main.js', libraries: {} }, scripts: { check: 'psc check src/Main.' + syntax, build: 'psc build src/Main.' + syntax + ' --out src/Main.js' } }, null, 2) + '\n', { flag: 'wx' });
  return { initialized: true, projectRoot: root, source };
}
async function main(args) {
  const [command = 'help', ...rest] = args;
  if (['help', '--help', '-h'].includes(command)) { console.log(help); return; }
  if (['version', '--version', '-v', 'packages'].includes(command)) {
    const flags = options(rest, []);
    const info = { name: 'proofscript', version: meta.version, distribution: meta.proofscript?.sourceVariant || 'unknown', compiler: 'PSC0 ps-0.9-r3 new-only bounded self-host subset', checker: '@proofscript/pskernel-core/check / JS Core (boundedly qualified)', installedCorePackages: meta.proofscript?.corePackages || [], optionalPackages: meta.proofscript?.optionalPackages || [], packageCount: (meta.proofscript?.corePackages || []).length };
    console.log(flags['--json'] || command === 'packages' ? JSON.stringify(info, null, 2) : 'psc ' + meta.version); return;
  }
  if (command === 'init') {
    const directory = rest[0] && !rest[0].startsWith('--') ? rest.shift() : '.';
    const flags = options(rest, ['--syntax']);
    console.log(JSON.stringify(await init(directory, flags['--syntax'] || meta.proofscript?.sourceVariant || 'ps'), null, 2)); return;
  }
  if (!['check', 'build'].includes(command)) throw new Error('PSC_COMMAND_UNSUPPORTED: ' + command);
  const entry = rest.shift();
  if (!entry || entry.startsWith('--')) throw new Error('PSC_ENTRY_REQUIRED');
  const flags = options(rest, ['--frontend-timeout-ms', '--frontend-heap-mb', ...(command === 'build' ? ['--out'] : [])]);
  const frontendLimits = {};
  for (const [flag, field] of [['--frontend-timeout-ms', 'timeoutMs'], ['--frontend-heap-mb', 'heapMb']]) {
    if (flags[flag] === undefined) continue;
    if (!/^[1-9][0-9]*$/u.test(flags[flag])) throw new Error('PSC_FRONTEND_INVALID_LIMIT: ' + flag);
    frontendLimits[field] = Number(flags[flag]);
  }
  const result = await runCheckedBuild({ entry, output: flags['--out'], checkOnly: command === 'check', version: meta.version, frontendLimits });
  console.log(flags['--json'] ? JSON.stringify(result, null, 2) : 'PSC_' + command.toUpperCase() + '_PASS: ' + entry);
}
try { await main(process.argv.slice(2)); }
catch (error) { console.error('psc: ' + String(error?.message || error)); process.exitCode = 1; }
