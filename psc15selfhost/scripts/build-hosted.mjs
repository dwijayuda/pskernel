import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

// Lake resolves the pinned host toolchain in each workspace. Build the native
// CLI and checked compiler; compiler self-application is an explicit legacy job.
for (const [cwd, target] of [
  [root, 'psc'],
  [path.join(root, 'lean-checked'), 'psc2_lean_checked_seed'],
]) {
  const result = spawnSync('lake', ['build', target], {
    cwd, stdio: 'inherit', windowsHide: true,
  });
  if (result.error) throw result.error;
  if (result.status !== 0) process.exit(result.status ?? 1);
}
process.stdout.write('PSCV_HOSTED_BUILD: native CLI and checked compiler built\n');
