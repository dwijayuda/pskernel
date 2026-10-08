#!/usr/bin/env node
import { readFile, stat } from 'node:fs/promises';
import { createCompilerCore } from '@proofscript/pscv-core';

const core = createCompilerCore();
const USAGE = [
  'psc-core — experimental PSCV V6 kernel-first core (NOT the full compiler)',
  'usage:',
  '  psc-core capabilities',
  '  psc-core inspect <file.ps>',
  '  psc-core check-admissions <file.json> [native|wasm]',
  '',
  'Unimplemented: psc-core build, psc-core verify, .ps parsing/codegen.',
].join('\n');

async function readBounded(file) {
  const info = await stat(file);
  if (!info.isFile() || info.size > 16 * 1024 * 1024) {
    throw new Error('PSCV_CLI_INPUT_SIZE_OR_TYPE');
  }
  const content = await readFile(file, 'utf8');
  if (Buffer.byteLength(content, 'utf8') > 16 * 1024 * 1024) {
    throw new Error('PSCV_CLI_INPUT_SIZE');
  }
  return content;
}

async function main(args) {
  if (args.length === 0 || (args.length === 1 && ['--help', '-h', 'help'].includes(args[0]))) {
    process.stdout.write(USAGE + '\n');
    return;
  }
  if (args.length === 1 && args[0] === 'capabilities') {
    process.stdout.write(JSON.stringify(core.describe(), null, 2) + '\n');
    return;
  }
  if (args.length === 2 && args[0] === 'inspect') {
    const source = await readBounded(args[1]);
    process.stdout.write(JSON.stringify(core.inspectSource({ source, path: args[1] }), null, 2) + '\n');
    return;
  }
  if ((args.length === 2 || args.length === 3) && args[0] === 'check-admissions') {
    const text = await readBounded(args[1]);
    const transport = args[2] ?? 'native';
    const result = await core.checkCanonicalAdmissions(text, { transport });
    process.stdout.write(JSON.stringify(result, null, 2) + '\n');
    if (result.status !== 'kernel-admissions-accepted') process.exitCode = 1;
    return;
  }
  throw new Error('PSCV_CLI_UNSUPPORTED_COMMAND\n' + USAGE);
}

main(process.argv.slice(2)).catch(error => {
  process.stderr.write((error?.message ?? String(error)) + '\n');
  process.exitCode = 1;
});
