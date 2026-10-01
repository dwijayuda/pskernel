import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const file = path.join(root, 'packages/pskernel-one/src/Ps/KernelOne/Level.lean');
const original = fs.readFileSync(file, 'utf8');
const changes = [
  ['drop-reverse-inclusion', '    psKernelOneLevelMaxSubset right left', '    true'],
  ['drop-left-max-branch', 'if subsetA right then subsetB right else false', 'subsetA right'],
];
try {
  for (const [name, before, after] of changes) {
    if (original.split(before).length !== 2) throw new Error(`MUTATION_ANCHOR: ${name}`);
    fs.writeFileSync(file, original.replace(before, after));
    const r = spawnSync('lake', ['exe', 'pskernel_one_level_tests'], {cwd: root, encoding: 'utf8', timeout: 120000});
    if (r.status === 0 || !`${r.stdout}\n${r.stderr}`.includes('LEVEL_PARITY:')) {
      throw new Error(`MUTATION_NOT_KILLED_SEMANTICALLY: ${name}\n${r.stdout}\n${r.stderr}`);
    }
    console.log(`PSKERNEL_ONE_MUTATION: KILLED ${name}`);
  }
} finally {
  fs.writeFileSync(file, original);
}
const restored = spawnSync('lake', ['exe', 'pskernel_one_level_tests'], {cwd: root, encoding: 'utf8', timeout: 120000});
if (restored.status !== 0) throw new Error(`RESTORED_TEST_FAILED: ${restored.stdout}\n${restored.stderr}`);
console.log('PSKERNEL_ONE_MUTATIONS: PASS (2 semantic mutants; restored source green)');
