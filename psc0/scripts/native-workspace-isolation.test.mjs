import assert from 'node:assert/strict';
import { mkdir, mkdtemp, writeFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const compiler = path.join(root, '.lake/build/bin', process.platform === 'win32' ? 'psc1.exe' : 'psc1');
const temporary = await mkdtemp(path.join(tmpdir(), 'psc2-native-isolation-'));
try {
  const parent = path.join(temporary, 'parent');
  const workspace = path.join(parent, 'dist/generated');
  const entry = path.join(workspace, 'packages/bootstrap/src/Ps/Bootstrap/Entry.ps');
  const dependency = 'packages/foundation/src/Ps/Foundation/OnlyHere.ps';
  const put = async (file, content) => { await mkdir(path.dirname(file), { recursive: true }); await writeFile(file, content); };
  await mkdir(path.join(parent, 'stdlib'), { recursive: true });
  await put(path.join(parent, dependency.replace(/\.ps$/u, '.lean')), 'def originalOnly : Nat := 1\n');
  await put(entry, 'import Ps.Foundation.OnlyHere;\ndef result : Nat := generatedOnly;\n');
  await put(path.join(workspace, dependency), 'def generatedOnly : Nat := 42;\n');
  for (const manifest of ['.proofscript-bootstrap.json', '.proofscript-selfhost.json', '.proofscript-project.json']) {
    const manifestPath = path.join(workspace, manifest);
    await put(manifestPath, '{}');
    const accepted = spawnSync(compiler, ['check', entry], { cwd: parent, encoding: 'utf8', timeout: 30000 });
    assert.equal(accepted.status, 0, accepted.stderr || String(accepted.error));
    await put(entry, 'import Ps.Foundation.OnlyHere;\ndef result : Nat := originalOnly;\n');
    const rejected = spawnSync(compiler, ['check', entry], { cwd: parent, encoding: 'utf8', timeout: 30000 });
    assert.notEqual(rejected.status, 0, 'native resolution must not escape to the original workspace');
    assert.match(rejected.stderr, /unknownName:originalOnly/);
    await put(entry, 'import Ps.Foundation.OnlyHere;\ndef result : Nat := generatedOnly;\n');
    await rm(manifestPath);
  }
  console.log('PSC2_NATIVE_WORKSPACE_ISOLATION: PASS (bootstrap, selfhost and project roots without stdlib; original sources rejected)');
} finally {
  await rm(temporary, { recursive: true, force: true });
}
