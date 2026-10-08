import assert from 'node:assert/strict';
import { mkdtemp, writeFile, readFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const compiler = fileURLToPath(new URL('../.lake/build/bin/' +
  (process.platform === 'win32' ? 'psc1.exe' : 'psc1'), import.meta.url));
const directory = await mkdtemp(path.join(tmpdir(), 'psc2-native-tsc-'));
try {
  const source = path.join(directory, 'answer.lean');
  const output = path.join(directory, 'nested/answer.js');
  await writeFile(source, 'def answer : Nat := 42\n');
  const result = spawnSync(compiler, ['build', source, '--out', output], {
    cwd: directory, encoding: 'utf8', timeout: 30000,
  });
  assert.equal(result.status, 0, result.stderr || String(result.error));
  assert.match(await readFile(output, 'utf8'), /export const answer/);
  // No package installation or arbitrary tsc shim may replace the pinned CLI.
  await writeFile(path.join(directory, 'tsc'), 'must not execute this shim');
  const { PSC_TYPESCRIPT_CLI: _pinnedTypeScriptCli, ...withoutPinnedTypeScriptCli } = process.env;
  const missing = spawnSync(compiler, ['build', source, '--out', path.join(directory, 'missing.js')], {
    cwd: directory,
    env: { ...withoutPinnedTypeScriptCli, PATH: directory },
    encoding: 'utf8',
    timeout: 30000,
  });
  assert.notEqual(missing.status, 0);
  assert.match(missing.stderr, /PSC1_TYPESCRIPT_CLI_MISSING/);
  console.log('PSC2_NATIVE_TYPESCRIPT_CLI: PASS (PATH installation, isolated cwd, output parents and no installation fallback)');
} finally {
  await rm(directory, { recursive: true, force: true });
}
