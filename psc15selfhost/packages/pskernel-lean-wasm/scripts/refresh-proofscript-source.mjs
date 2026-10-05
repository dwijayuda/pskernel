import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { cp, mkdir, readFile, readdir, rm, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const packageRoot = path.resolve(here, '..');
const workspaceRoot = path.resolve(packageRoot, '../..');
const snapshotRoot = path.join(packageRoot, 'source', 'proofscript');
const manifestPath = path.join(packageRoot, 'PROOFSCRIPT_SOURCE_MANIFEST.json');
const checkOnly = process.argv.includes('--check');

const componentSources = Object.freeze({
  foundation: path.join(workspaceRoot, 'packages', 'foundation', 'src'),
  core: path.join(workspaceRoot, 'packages', 'core', 'src'),
  environment: path.join(workspaceRoot, 'packages', 'environment', 'src'),
  bridge: path.join(workspaceRoot, 'packages', 'bridge', 'src'),
  provider: path.join(workspaceRoot, 'packages', 'pskernel-lean', 'provider'),
  'wasm-provider': path.join(packageRoot, 'provider'),
});

function gitObjectSha(type, body) {
  const payload = Buffer.isBuffer(body) ? body : Buffer.from(body);
  return createHash('sha1')
    .update(Buffer.from(`${type} ${payload.length}\0`))
    .update(payload)
    .digest();
}

async function gitTreeSha(root) {
  const entries = (await readdir(root, { withFileTypes: true }))
    .sort((a, b) => Buffer.from(a.name).compare(Buffer.from(b.name)));
  const treeParts = [];
  for (const entry of entries) {
    const entryPath = path.join(root, entry.name);
    if (entry.isFile()) {
      treeParts.push(Buffer.from(`100644 ${entry.name}\0`));
      treeParts.push(gitObjectSha('blob', await readFile(entryPath)));
    } else if (entry.isDirectory()) {
      treeParts.push(Buffer.from(`40000 ${entry.name}\0`));
      treeParts.push(Buffer.from(await gitTreeSha(entryPath), 'hex'));
    } else {
      throw new Error(`unsupported source snapshot entry: ${entryPath}`);
    }
  }
  return gitObjectSha('tree', Buffer.concat(treeParts)).toString('hex');
}

function repositoryRevision() {
  const explicit = process.env.PSC_LEAN_WASM_SOURCE_REVISION;
  if (explicit) return explicit;
  const result = spawnSync('git', ['rev-parse', 'HEAD'], {
    cwd: workspaceRoot,
    encoding: 'utf8',
    windowsHide: true,
  });
  if (result.status !== 0) {
    throw new Error(`cannot resolve repository revision: ${result.stderr ?? ''}`);
  }
  return result.stdout.trim();
}

async function componentHashes(root) {
  const hashes = {};
  for (const name of Object.keys(componentSources)) {
    hashes[name] = await gitTreeSha(path.join(root, name));
  }
  return hashes;
}

if (checkOnly) {
  const manifest = JSON.parse(await readFile(manifestPath, 'utf8'));
  assert.equal(manifest.schemaVersion, 1);
  assert.equal(manifest.packageName, '@proofscript/pskernel-lean-wasm');
  assert.equal(manifest.snapshotRoot, 'source/proofscript');
  assert.match(manifest.sourceRevision, /^[0-9a-f]{40}$/u);
  assert.match(manifest.sourceTreeSha, /^[0-9a-f]{40}$/u);

  const live = {};
  for (const [name, source] of Object.entries(componentSources)) {
    live[name] = await gitTreeSha(source);
  }
  const snapshot = await componentHashes(snapshotRoot);
  assert.deepEqual(snapshot, live, 'bundled ProofScript source snapshot is stale');
  assert.deepEqual(manifest.components, snapshot, 'ProofScript source component manifest drift');
  assert.equal(
    manifest.sourceTreeSha,
    await gitTreeSha(snapshotRoot),
    'ProofScript source tree manifest drift',
  );
  console.log(
    `PSC2_LEAN_KERNEL_WASM_CURRENT_SOURCE: PASS ${manifest.sourceTreeSha} ${manifest.sourceRevision}`,
  );
} else {
  await rm(snapshotRoot, { recursive: true, force: true });
  await mkdir(snapshotRoot, { recursive: true });
  for (const [name, source] of Object.entries(componentSources)) {
    await cp(source, path.join(snapshotRoot, name), {
      recursive: true,
      force: true,
      preserveTimestamps: false,
    });
  }

  const manifest = {
    schemaVersion: 1,
    packageName: '@proofscript/pskernel-lean-wasm',
    snapshotRoot: 'source/proofscript',
    sourceRevision: repositoryRevision(),
    sourceTreeSha: await gitTreeSha(snapshotRoot),
    components: await componentHashes(snapshotRoot),
  };
  await writeFile(manifestPath, JSON.stringify(manifest, null, 2) + '\n', 'utf8');
  console.log(
    `PSC2_LEAN_KERNEL_WASM_SOURCE_REFRESH: PASS ${manifest.sourceTreeSha} ${manifest.sourceRevision}`,
  );
}
