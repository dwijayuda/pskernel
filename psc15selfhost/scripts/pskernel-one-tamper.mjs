import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const source = 'packages/pskernel-one/src/Ps/KernelOne/Name.lean';
const cases = [
  ['changed-source', dir => fs.appendFileSync(path.join(dir, source), '\n'), /SOURCE_MANIFEST_MISMATCH/],
  ['undeclared-import', dir => fs.appendFileSync(path.join(dir, source), '\nimport Ps.KernelCore.Name\n'), /EXTERNAL_IMPORT/],
  ['symlink-escape', dir => {
    const file = path.join(dir, source); const target = path.join(dir, 'outside.lean');
    fs.renameSync(file, target); fs.symlinkSync(target, file);
  }, /SOURCE_ESCAPE/],
  ['corrupt-manifest', dir => fs.writeFileSync(path.join(dir, 'packages/pskernel-one/SOURCE_MANIFEST.json'), '{}'), /SOURCE_MANIFEST_MISMATCH/],
];
for (const [name, mutate, expected] of cases) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'pskernel-one-tamper-'));
  try {
    fs.cpSync(path.join(root, 'packages/pskernel-one'), path.join(dir, 'packages/pskernel-one'), {recursive: true});
    fs.mkdirSync(path.join(dir, 'scripts'));
    const script = path.join(dir, 'scripts/pskernel-one-profile.mjs');
    fs.copyFileSync(path.join(root, 'scripts/pskernel-one-profile.mjs'), script);
    mutate(dir);
    const result = spawnSync(process.execPath, [script], {encoding: 'utf8', timeout: 10000});
    assert.notEqual(result.status, 0); assert.match(result.stderr, expected);
    console.log(`PSKERNEL_ONE_TAMPER: PASS ${name}`);
  } finally { fs.rmSync(dir, {recursive: true, force: true}); }
}
