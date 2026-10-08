#!/usr/bin/env node
/**
 * M0 experimental bridge:
 *   PSC2 .ps parser/printer (Lean 4.34 bootstrap)
 *     -> generated Lean source
 *     -> pinned Lean 4.35-rc3 elaborator/kernel
 *     -> optional UNVERIFIED development C source.
 *
 * NO PSCV-CERT-v1, approved-spec gate, axiom-closure audit, or validated
 * executable handoff exists here. No output is a PSCV verified executable.
 */
import path from 'node:path';
import os from 'node:os';
import { existsSync } from 'node:fs';
import { copyFile, mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { requireM0SourcePolicy } from './policy.mjs';

const frontendDir = path.dirname(fileURLToPath(import.meta.url));
const selfhostDir = path.resolve(frontendDir, '..');
const targetHash = '470d5ce1400764999581fd26d5d72b00d990b0f4';
const developmentHeader = [
  '-- PSCV_LEAN_FRONTEND_M0: Lean checked; NOT a PSCV verified executable.',
  '-- Generated from the bounded PSC2 translator. No PSCV-CERT-v1 exists.',
  '',
].join('\n');

function usage() {
  return [
    'Experimental PSCV -> Lean 4.35 native frontend (M0, NOT PSCV certified).',
    'Usage:',
    '  node psc-lean.mjs check source.ps',
    '  node psc-lean.mjs emit-lean source.ps --out output.lean',
    '  node psc-lean.mjs emit-c source.ps --out output.c --development-unverified',
    '',
    'The existing Lean-4.34-hosted PSC2 translator provides bounded .ps syntax.',
    'The pinned Lean 4.35.0-rc3 kernel checks the translated Lean source.',
    'Development C output is NOT PSCV verified or compiler-preservation evidence.',
    'For a prebuilt translator set PSCV_LEAN_TRANSLATOR_BIN to its path.',
  ].join('\n');
}

function parseCli(argv) {
  const [command, input, ...rest] = argv;
  if (command === '--help' || command === '-h' || command === undefined) {
    return { help: true };
  }
  if (!['check', 'emit-lean', 'emit-c'].includes(command) || !input) {
    throw new Error(usage());
  }
  let output;
  let developmentUnverified = false;
  for (let i = 0; i < rest.length; i++) {
    if (rest[i] === '--out' && !output && i + 1 < rest.length) {
      output = rest[++i];
    } else if (rest[i] === '--development-unverified' && !developmentUnverified) {
      developmentUnverified = true;
    } else {
      throw new Error('PSCV_LEAN_CLI: unsupported or duplicate option ' + rest[i] + '\n' + usage());
    }
  }
  if (command !== 'check' && !output) {
    throw new Error('PSCV_LEAN_CLI: --out is required');
  }
  if (command === 'check' && (output || developmentUnverified)) {
    throw new Error('PSCV_LEAN_CLI: check accepts no output or development flags');
  }
  if (command === 'emit-c' && !developmentUnverified) {
    throw new Error('PSCV_LEAN_NO_CERT: emitting executable C requires --development-unverified');
  }
  if (command === 'emit-lean' && developmentUnverified) {
    throw new Error('PSCV_LEAN_CLI: --development-unverified applies only to emit-c');
  }
  return { command, input: path.resolve(input), output: output && path.resolve(output) };
}

function run(command, args, cwd, extraEnv = {}) {
  const result = spawnSync(command, args, {
    cwd,
    encoding: 'utf8',
    maxBuffer: 64 * 1024 * 1024,
    windowsHide: true,
    env: { ...process.env, ...extraEnv },
  });
  if (result.error) {
    throw new Error('PSCV_LEAN_TOOL: ' + command + ': ' + result.error.message);
  }
  if (result.status !== 0) {
    throw new Error('PSCV_LEAN_TOOL_FAILED: ' + command + ' ' + args.join(' ') +
      '\nexit=' + result.status + '\n' + result.stdout + '\n' + result.stderr);
  }
  return result.stdout;
}

function enforcePinnedLean() {
  const lean = process.env.PSCV_LEAN_BIN || 'lean';
  const actualHash = run(lean, ['--githash'], frontendDir).trim();
  if (actualHash !== targetHash) {
    throw new Error('PSCV_LEAN_PIN_MISMATCH: expected ' + targetHash +
      ', got ' + actualHash + '. Use leanprover/lean4:v4.35.0-rc3.');
  }
  return lean;
}

function translateExistingPsc2(input) {
  const override = process.env.PSCV_LEAN_TRANSLATOR_BIN;
  const bin = override
    ? path.resolve(override)
    : path.join(selfhostDir, '.lake', 'build', 'bin',
      process.platform === 'win32' ? 'psc.exe' : 'psc');
  if (!override) run('lake', ['build', 'psc'], selfhostDir);
  if (!existsSync(bin)) {
    throw new Error('PSCV_LEAN_TRANSLATOR_MISSING: ' + bin);
  }
  const translated = run(bin, ['emit-lean', input], selfhostDir);
  if (!translated.trim()) {
    throw new Error('PSCV_LEAN_TRANSLATOR_EMPTY: translator produced empty output');
  }
  return developmentHeader + translated + '\n';
}

async function main() {
  const options = parseCli(process.argv.slice(2));
  if (options.help) {
    console.log(usage());
    return;
  }
  if (!options.input.endsWith('.ps')) {
    throw new Error('PSCV_LEAN_INPUT: expected a .ps source file');
  }
  const source = await readFile(options.input, 'utf8');
  requireM0SourcePolicy(source);
  const lean = enforcePinnedLean();
  const directory = await mkdtemp(path.join(os.tmpdir(), 'pscv-lean-m0-'));
  try {
    const generatedPath = path.join(directory, 'PSCVGenerated.lean');
    const translated = translateExistingPsc2(options.input);
    await writeFile(generatedPath, translated, 'utf8');
    // Lean does the actual parsing, elaboration, proof checking and typechecking.
    run(lean, [generatedPath], frontendDir);
    if (options.command === 'check') {
      console.log('PSCV_LEAN_CHECK: PASS (Lean kernel only; NOT PSCV verified)');
      return;
    }
    await mkdir(path.dirname(options.output), { recursive: true });
    if (options.command === 'emit-lean') {
      await copyFile(generatedPath, options.output);
      console.log('PSCV_LEAN_EMIT_SOURCE: ' + options.output + ' (NOT PSCV verified)');
      return;
    }
    // Explicitly named development-only emission. PSCV verified builds are
    // fail-closed until PSCV-CERT-v1 and its semantic gates are implemented.
    const cPath = path.join(directory, 'PSCVGenerated.c');
    // Lean 4.35 requires native compilation inputs to reside within its root.
    // Running inside the isolated source directory keeps that invariant.
    // Explicitly select the pinned toolchain because the temporary directory
    // does not itself contain a lean-toolchain file.
    run(lean, ['-c', cPath, generatedPath], directory,
      { LEAN_TOOLCHAIN: 'leanprover/lean4:v4.35.0-rc3' });
    await copyFile(cPath, options.output);
    console.log('PSCV_LEAN_EMIT_C_DEVELOPMENT_UNVERIFIED: ' + options.output);
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
}

main().catch(error => {
  console.error(error instanceof Error ? error.message : String(error));
  process.exitCode = 1;
});
