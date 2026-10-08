// CLI-level assurance: exactly one supported TypeScript compiler version.
import assert from 'node:assert/strict';
import test from 'node:test';
import { mkdtemp, writeFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { createRequire } from 'node:module';
import {
  pinnedTypeScriptVersion,
  pinnedTypeScriptVersionText,
  checkedTypeScriptToolchain,
  strictTypeScriptArgs,
  resolveTypeScriptCli,
  assertPinnedTypeScriptCli,
} from './typescript-cli.mjs';

test('TypeScript 7.0.2 is the sole supported checked output toolchain', () => {
  assert.equal(pinnedTypeScriptVersion, '7.0.2');
  assert.equal(pinnedTypeScriptVersionText, 'Version 7.0.2');
  assert.equal(checkedTypeScriptToolchain.version, '7.0.2');
  assert.equal(checkedTypeScriptToolchain.package, 'typescript');
  assert.equal(checkedTypeScriptToolchain.profile, 'strict-es2022-esm-ignoreconfig/1');
  for (const flag of [
    '--ignoreConfig', '--strict', '--declaration', '--sourceMap',
    '--noEmitOnError', '--skipLibCheck', '--moduleResolution',
  ]) assert.ok(strictTypeScriptArgs.includes(flag), flag);
  assert.equal(strictTypeScriptArgs[strictTypeScriptArgs.indexOf('--moduleResolution') + 1], 'bundler');
});

test('the installed native TypeScript 7 CLI is discoverable and exactly pinned', () => {
  const require = createRequire(import.meta.url);
  const pkg = require('typescript/package.json');
  assert.equal(pkg.version, pinnedTypeScriptVersion);
  const cli = assertPinnedTypeScriptCli(resolveTypeScriptCli());
  assert.ok(cli.endsWith('/typescript/bin/tsc') || cli.replaceAll('\\', '/').endsWith('/typescript/bin/tsc'));
});

test('a foreign compiler version is never silently substituted', async () => {
  const dir = await mkdtemp(path.join(tmpdir(), 'psc0-ts7-version-'));
  try {
    const file = path.join(dir, 'old.cjs');
    await writeFile(file, 'console.log("Version 6.0.3")\n');
    assert.throws(() => assertPinnedTypeScriptCli(file), /PSC2_TYPESCRIPT_PIN/);
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
});
