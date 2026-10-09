import assert from 'node:assert/strict';
import { existsSync } from 'node:fs';
import { mkdtemp, writeFile, readFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import { expectedTypeScriptVersion, resolveTypeScriptCli } from './typescript-cli.mjs';

const compiler = fileURLToPath(new URL('../.lake/build/bin/' +
  (process.platform === 'win32' ? 'psc1.exe' : 'psc1'), import.meta.url));
const expected = expectedTypeScriptVersion();
const cli = resolveTypeScriptCli();
const directory = await mkdtemp(path.join(tmpdir(), 'psc2-native-tsc-'));
try {
  const source = path.join(directory, 'answer.lean');
  const output = path.join(directory, 'nested/answer.js');
  const availableEnv = { ...process.env, PSC0_TYPESCRIPT_VERSION: expected,
    PATH: path.dirname(cli) + path.delimiter + (process.env.PATH ?? '') };
  const selectedEnv = { ...availableEnv, PSC0_TSC: cli };
  await writeFile(source, 'def answer : Nat := 42\n');
  // This unrelated config must not suppress positional-file compilation.
  await writeFile(path.join(directory, 'tsconfig.json'),
    JSON.stringify({ compilerOptions: { noEmit: true }, files: [] }));
  const result = spawnSync(compiler, ['build', source, '--out', output], {
    cwd: directory, env: selectedEnv, encoding: 'utf8', timeout: 30000,
  });
  assert.equal(result.status, 0, result.stderr || String(result.error));
  assert.match(await readFile(output, 'utf8'), /export const answer/);
  assert(result.stdout.includes('PSC2_TYPESCRIPT: ' + expected), result.stdout);

  // Discovery still works from an isolated cwd when no override is present.
  const discoveryEnv = { ...availableEnv };
  delete discoveryEnv.PSC0_TSC;
  const discoveryOutput = path.join(directory, 'path-discovery.js');
  const discovery = spawnSync(compiler, ['build', source, '--out', discoveryOutput], {
    cwd: directory, env: discoveryEnv, encoding: 'utf8', timeout: 30000,
  });
  assert.equal(discovery.status, 0, discovery.stderr || String(discovery.error));
  assert.match(await readFile(discoveryOutput, 'utf8'), /export const answer/);
  assert(discovery.stdout.includes('PSC2_TYPESCRIPT: ' + expected), discovery.stdout);

  // A valid installed launcher with the wrong allowed profile must fail before tsc compilation.
  const mismatchOutput = path.join(directory, 'wrong-profile.js');
  const mismatch = spawnSync(compiler, ['build', source, '--out', mismatchOutput], {
    cwd: directory, env: { ...selectedEnv,
      PSC0_TYPESCRIPT_VERSION: expected === '7.0.2' ? '5.8.3' : '7.0.2' },
    encoding: 'utf8', timeout: 30000,
  });
  assert.notEqual(mismatch.status, 0);
  assert.match(mismatch.stderr, /PSC1_TSC_VERSION_MISMATCH/);
  assert(!existsSync(mismatchOutput), 'a version mismatch must not emit JavaScript');

  // Invalid explicit overrides must not fall back to the valid launcher on PATH.
  const shim = path.join(directory, 'tsc');
  await writeFile(shim, 'must not execute this shim');
  const invalidOverrides = [
    ['empty', ''], ['relative', 'tsc'], ['missing', path.join(directory, 'missing-tsc')],
    ['directory', directory], ['unowned', shim],
  ];
  if (process.platform === 'win32') invalidOverrides.push(['drive-relative', 'C:tsc']);
  for (const [label, override] of invalidOverrides) {
    const invalidOutput = path.join(directory, 'invalid-' + label + '.js');
    const invalid = spawnSync(compiler, ['build', source, '--out', invalidOutput], {
      cwd: directory, env: { ...availableEnv, PSC0_TSC: override },
      encoding: 'utf8', timeout: 30000,
    });
    assert.notEqual(invalid.status, 0, label);
    assert.match(invalid.stderr, /PSC0_TYPESCRIPT_CLI_OVERRIDE/, label);
    assert(!existsSync(invalidOutput), label + ' override must not fall back to compilation');
  }

  // No package installation or arbitrary tsc shim may replace the pinned CLI.
  const missingEnv = { ...process.env, PATH: directory };
  delete missingEnv.PSC0_TSC;
  delete missingEnv.PSC0_TYPESCRIPT_VERSION;
  const missing = spawnSync(compiler, ['build', source, '--out', path.join(directory, 'missing.js')], {
    cwd: directory, env: missingEnv, encoding: 'utf8', timeout: 30000,
  });
  assert.notEqual(missing.status, 0);
  assert.match(missing.stderr, /PSC1_TYPESCRIPT_CLI_MISSING/);
  console.log('PSC2_NATIVE_TYPESCRIPT_CLI: PASS (exact profile, unrelated config, installed override and PATH discovery, precompile rejection and no fallback)');
} finally {
  await rm(directory, { recursive: true, force: true });
}
