import assert from 'node:assert/strict';
import { test } from 'node:test';
import { mkdtemp, mkdir, writeFile, readFile, appendFile, rm, symlink } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { captureTargetTrees, fingerprintTargetFile } from '../npm-cli/target-files.mjs';
import { targetEnvironment, runTargetProcess } from '../npm-cli/target-process.mjs';
import { captureTypeScriptInstallation } from '../npm-cli/target-toolchain.mjs';
import { publishGeneration } from '../npm-cli/publication.mjs';
async function directory(t) {
  const root = await mkdtemp(path.join(os.tmpdir(), 'psc-target-'));
  t.after(() => rm(root, { recursive: true, force: true }));
  return root;
}
async function tree(t) {
  const root = await directory(t); await mkdir(path.join(root, 'lib'));
  await writeFile(path.join(root, 'package.json'), '{"name":"fixture"}');
  await writeFile(path.join(root, 'lib/native'), Buffer.from([0, 255, 1, 254]));
  await writeFile(path.join(root, 'lib/stdlib.d.ts'), 'interface A {}');
  return root;
}
const capture = root => captureTargetTrees([{ id: 'fixture', directory: root }]);
const products = { '.ts': 'export const a=42;', '.js': 'export const a=42;', '.d.ts': 'export declare const a:number;', '.js.map': '{}' };
test('target identity is binary-safe, immutable and captures libraries', async t => {
  const root = await tree(t), item = await capture(root);
  const binary = item.identity.entries.find(e => e.id === 'fixture/lib/native');
  assert.equal(binary.bytes, 4); assert.match(binary.sha256, /^[a-f0-9]{64}$/u);
  assert(Object.isFrozen(item.identity.entries));
  assert.equal(item.sha256, (await capture(root)).sha256);
  await item.revalidate();
});
for (const change of ['binary', 'library', 'addition', 'removal']) test('target rejects ' + change + ' drift', async t => {
  const root = await tree(t), item = await capture(root);
  if (change === 'binary') await appendFile(path.join(root, 'lib/native'), 'changed');
  if (change === 'library') await writeFile(path.join(root, 'lib/stdlib.d.ts'), 'interface B {}');
  if (change === 'addition') await writeFile(path.join(root, 'new-file'), 'extra');
  if (change === 'removal') await rm(path.join(root, 'lib/stdlib.d.ts'));
  await assert.rejects(item.revalidate(), /IDENTITY_CHANGED/);
});
test('target inventory budgets bound file, aggregate and entry counts', async t => {
  const root = await tree(t);
  await assert.rejects(captureTargetTrees([{ id: 't', directory: root }], { maxFileBytes: 2 }), /FILE_LIMIT/);
  await assert.rejects(captureTargetTrees([{ id: 't', directory: root }], { maxTotalBytes: 4 }), /TREE_BYTE_LIMIT/);
  await assert.rejects(captureTargetTrees([{ id: 't', directory: root }], { maxFiles: 2 }), /TREE_LIMIT/);
  await assert.rejects(captureTargetTrees([{ id: 't', directory: root }], { maxDepth: 1 }), /TREE_LIMIT/);
});
test('target library junctions are not followed outside the inventory', async t => {
  const root = await tree(t), outside = await directory(t);
  await symlink(outside, path.join(root, 'lib/junction'), process.platform === 'win32' ? 'junction' : 'dir');
  await assert.rejects(capture(root), /TREE_SYMLINK/);
});
test('file products require bounded regular files and valid UTF8', async t => {
  const root = await tree(t);
  await assert.rejects(fingerprintTargetFile(path.join(root, 'lib')), /NOT_REGULAR/);
  await assert.rejects(fingerprintTargetFile(path.join(root, 'lib/native'), { text: true }), /encoded data|UTF-8|encoding/i);
  await assert.rejects(fingerprintTargetFile(path.join(root, 'lib/native'), { maxBytes: 2 }), /FILE_LIMIT/);
});
test('TypeScript metadata cannot substitute a version or platform', async t => {
  const root = await directory(t), ts = path.join(root, 'node_modules/typescript'), name = '@typescript/typescript-' + process.platform + '-' + process.arch;
  const native = path.join(root, 'node_modules', name);
  await mkdir(path.join(ts, 'lib'), { recursive: true }); await mkdir(path.join(native, 'lib'), { recursive: true });
  const metadata = { name: 'typescript', version: '7.0.2', bin: { tsc: 'lib/tsc.js' }, optionalDependencies: { [name]: '7.0.2' } };
  await writeFile(path.join(ts, 'package.json'), JSON.stringify(metadata));
  await writeFile(path.join(ts, 'lib/tsc.js'), '// fixture, not executed');
  await writeFile(path.join(native, 'package.json'), JSON.stringify({ name, version: '7.0.2', os: [process.platform], cpu: [process.arch] }));
  await writeFile(path.join(native, 'lib/tsc' + (process.platform === 'win32' ? '.exe' : '')), 'fixture binary, not executed');
  const selected = await captureTypeScriptInstallation(path.join(ts, 'package.json'));
  assert.equal(selected.identity.nativePackage, name);
  metadata.version = '7.0.3'; await writeFile(path.join(ts, 'package.json'), JSON.stringify(metadata));
  await assert.rejects(captureTypeScriptInstallation(path.join(ts, 'package.json')), /TYPESCRIPT_PIN/);
});
test('target environment excludes ambient execution overrides', () => {
  const environment = targetEnvironment({ NODE_OPTIONS: '--require evil', NODE_PATH: 'evil', PATH: 'evil', LD_PRELOAD: 'evil', DYLD_INSERT_LIBRARIES: 'evil', GODEBUG: 'evil', GOGC: 'off', TEMP: '/tmp', SystemRoot: 'C:\\Windows' });
  assert.deepEqual(environment, { LANG: 'C.UTF-8', LC_ALL: 'C.UTF-8', SystemRoot: 'C:\\Windows', TEMP: '/tmp' });
});
test('native process result waits for close and forwards no preload', async () => {
  const result = await runTargetProcess(process.execPath, ['-e', 'console.log(JSON.stringify({pid:process.pid,nodeOptions:process.env.NODE_OPTIONS??null}))']);
  assert.equal(result.closed, true); assert.notEqual(result.childPid, process.pid);
  assert.equal(JSON.parse(result.stdout).nodeOptions, null);
});
test('target process timeout terminates a busy executable', async () => {
  await assert.rejects(runTargetProcess(process.execPath, ['-e', 'while(true){}'], { timeoutMs: 1000 }), /TIME_LIMIT/);
});
test('target process cancellation is observed without blocking the parent', async () => {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 100);
  try { await assert.rejects(runTargetProcess(process.execPath, ['-e', 'while(true){}'], { signal: controller.signal }), /TARGET_ABORTED/); }
  finally { clearTimeout(timer); }
});
test('target process bounds diagnostics before accumulating output', async () => {
  await assert.rejects(runTargetProcess(process.execPath, ['-e', 'process.stdout.write("x".repeat(65536));setTimeout(()=>{},3000)'], { maxBytes: 1024 }), /DIAGNOSTIC_LIMIT/);
});
test('target refuses process failure, relative executables and shell scripts', async () => {
  await assert.rejects(runTargetProcess(process.execPath, ['-e', 'process.exit(7)']), /TSC_FAILED/);
  await assert.rejects(runTargetProcess('tsc', []), /PROCESS_ARGUMENTS/);
  await assert.rejects(runTargetProcess(path.resolve('tsc.cmd'), []), /PROCESS_ARGUMENTS/);
  await assert.rejects(runTargetProcess(process.execPath, [], { timeoutMs: 0 }), /PROCESS_BUDGET/);
});
test('toolchain drift at the final commit cannot replace the old executable', async t => {
  const root = await tree(t), snapshot = await capture(root), outputDir = await directory(t), output = path.join(outputDir, 'Main.js');
  await writeFile(output, 'previous generation');
  await appendFile(path.join(root, 'lib/native'), 'change');
  await assert.rejects(publishGeneration({ output, products, receipt: {}, snapshot: { protectedPaths: [], revalidate: snapshot.revalidate } }), /IDENTITY_CHANGED/);
  assert.equal(await readFile(output, 'utf8'), 'previous generation');
});
