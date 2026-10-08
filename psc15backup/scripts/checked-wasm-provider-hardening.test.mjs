import assert from 'node:assert/strict';
import { test } from 'node:test';
import { mkdtemp, writeFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { checkCanonicalAdmissions } from '../packages/pskernel-lean-wasm/index.mjs';
import { leanCheckedIdentity } from './kernel-checked-session.mjs';

async function withLauncher(source, fn) {
  const dir = await mkdtemp(path.join(tmpdir(), 'psc2-wasm-provider-double-'));
  try {
    const launcherPath = path.join(dir, 'provider.cjs');
    await writeFile(launcherPath, source, 'utf8');
    await fn(launcherPath);
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
}

test('WASM provider rejects mismatched profile', async () => {
  await withLauncher(
    `console.log(${JSON.stringify(JSON.stringify({ ...leanCheckedIdentity, profile: 'wrong', accepted: true }))});`,
    async launcherPath => {
      await assert.rejects(
        checkCanonicalAdmissions('{}', { launcherPath }),
        /profile mismatch/,
      );
    },
  );
});

test('WASM provider invocation has a mandatory timeout', async () => {
  await withLauncher('setInterval(() => {}, 1000);', async launcherPath => {
    await assert.rejects(
      checkCanonicalAdmissions('{}', { launcherPath, timeoutMs: 100 }),
      /ETIMEDOUT|timed out|failed to start/,
    );
  });
});

test('invalid WASM timeout cannot disable the bound', async () => {
  await assert.rejects(
    checkCanonicalAdmissions('{}', { launcherPath: '/unused', timeoutMs: 0 }),
    /positive integer/,
  );
});
