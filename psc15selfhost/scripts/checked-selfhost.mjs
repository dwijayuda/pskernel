import { mkdir, mkdtemp, readFile, rm, rename } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { buildChecked, defaultCheckedSeed, defaultCheckedCompiler } from './checked-build.mjs';
import { leanCheckedIdentity } from './checked-prepared-session.mjs';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const base = path.join(root, 'dist/lean-checked');
const npm = process.platform === 'win32' ? 'npm.cmd' : 'npm';
const hash = bytes => createHash('sha256').update(bytes).digest('hex');
function run(command, args, cwd = root) {
  const result = spawnSync(command, args, { cwd, stdio: 'inherit', timeout: 1200000,
    env: { ...process.env, PSC2_FIXED_POINT_PROBE_ACTIVE: '1' } });
  if (result.error) throw result.error;
  if (result.status !== 0) throw new Error(`PSC2_CHECKED_STEP_FAILED: ${command} ${args.join(' ')}`);
}
async function validateGeneration(generation) {
  const compiler = path.join(generation, 'packages/compiler/index.js');
  const receipt = JSON.parse(await readFile(compiler.replace(/\.js$/u, '.checked.json'), 'utf8'));
  for (const [key, value] of Object.entries(leanCheckedIdentity)) {
    if (receipt.provider?.[key] !== value) throw new Error('PSC2_CHECKED_GENERATION_PROVIDER');
  }
  if (receipt.kind !== 'psc2-lean-checked-build' ||
      hash(await readFile(compiler)) !== receipt.javaScriptSha256 ||
      hash(await readFile(compiler.replace(/\.js$/u, '.ts'))) !== receipt.typeScriptSha256 ||
      hash(await readFile(compiler.replace(/\.js$/u, '.admissions.json'))) !== receipt.canonicalAdmissionsSha256) {
    throw new Error('PSC2_CHECKED_GENERATION_INTEGRITY');
  }
  return compiler; // Integrity check only; a receipt is not an independently signed certificate.
}
async function promote(staging, name) {
  const destination = path.join(base, name);
  // Only the fixed, tool-owned output location is replaced, after a complete build.
  await rm(destination, { recursive: true, force: true });
  await rename(staging, destination);
}
async function bootstrap() {
  run(npm, ['run', 'bootstrap:lean']);
  run('lake', ['build', 'psc2_lean_checked_seed', 'psc2_lean_kernel_provider'], path.join(root, 'lean-checked'));
  const config = JSON.parse(await readFile(path.join(root, 'psconfig.json'), 'utf8'));
  // The checked seed receives one flattened snapshot, never the old host loader's
  // parent-directory import fallback. Every generated compiler is admitted again.
  await buildChecked({ entryPath: path.join(root, config.entry), seedPath: defaultCheckedSeed, checkOnly: true });
  await mkdir(base, { recursive: true }); const stage = await mkdtemp(path.join(base, '.bootstrap-'));
  try {
    run(process.execPath, ['scripts/bootstrap-project.mjs', config.entry, path.join(stage, 'workspace')]);
    const manifest = JSON.parse(await readFile(path.join(stage, 'workspace/.proofscript-bootstrap.json'), 'utf8'));
    await buildChecked({ entryPath: path.join(stage, 'workspace', manifest.entry), seedPath: defaultCheckedSeed,
      outputPath: path.join(stage, 'packages/compiler/index.js') });
    await promote(stage, 'bootstrap');
  } finally { await rm(stage, { recursive: true, force: true }); }
  console.log('PSC2_LEAN_CHECKED_BOOTSTRAP: PASS');
}
async function next(parentName, name) {
  const parent = path.join(base, parentName); const compiler = await validateGeneration(parent);
  const parentWorkspace = path.join(parent, 'workspace');
  const manifestFile = parentName === 'bootstrap' ? '.proofscript-bootstrap.json' : '.proofscript-selfhost.json';
  const manifest = JSON.parse(await readFile(path.join(parentWorkspace, manifestFile), 'utf8'));
  const stage = await mkdtemp(path.join(base, `.${name}-`));
  try {
    run(process.execPath, ['scripts/reemit-project-with-generated.mjs', compiler, parentWorkspace, path.join(stage, 'workspace')]);
    await buildChecked({ entryPath: path.join(stage, 'workspace', manifest.entry), compilerPath: compiler,
      outputPath: path.join(stage, 'packages/compiler/index.js') });
    await promote(stage, name);
  } finally { await rm(stage, { recursive: true, force: true }); }
  console.log(`PSC2_LEAN_CHECKED_GENERATION: PASS ${name}`);
}
async function compare() {
  for (const name of ['bootstrap', 'selfhost', 'repeat']) await validateGeneration(path.join(base, name));
  for (const name of ['selfhost', 'repeat']) {
    run(process.execPath, ['scripts/compare-source-workspaces.mjs', path.join(base, 'bootstrap/workspace'), path.join(base, name, 'workspace')]);
    run(process.execPath, ['scripts/compare-selfhost.mjs', defaultCheckedCompiler.replace(/\.js$/u, '.ts'), path.join(base, name, 'packages/compiler/index.ts')]);
  }
  console.log('PSC2_LEAN_CHECKED_GENERATION_INTEGRITY_AND_PARITY: PASS');
}
const args = process.argv.slice(2);
if (args.length !== 1) throw new Error('usage: checked-selfhost.mjs bootstrap|next|fixed-point|verify');
switch (args[0]) {
  case 'bootstrap': await bootstrap(); break;
  case 'next': await next('bootstrap', 'selfhost'); break;
  case 'verify': await compare(); break;
  case 'fixed-point':
    await bootstrap(); await next('bootstrap', 'selfhost'); await next('selfhost', 'repeat'); await compare();
    // Emitted only when this invocation actually rebuilt and kernel-checked all
    // three generations. Standalone receipt inspection never emits this marker.
    console.log('PSC2_LEAN_CHECKED_FIXED_POINT: PASS'); break;
  default: throw new Error('Unknown checked self-host command');
}
