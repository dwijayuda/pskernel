import { mkdir, mkdtemp, readFile, rm, rename } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { buildChecked, defaultCheckedSeed } from './checked-build.mjs';
import { checkedKernelIdentity } from './checked-kernel-identity.mjs';
import { checkedKernelDescriptor, defaultCheckedKernel } from './checked-kernel-provider.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
let base;
const hash = bytes => createHash('sha256').update(bytes).digest('hex');

function runNpm(args, cwd = root) {
  if (process.platform !== 'win32') return run('npm', args, cwd);
  const candidates = [
    path.join(path.dirname(process.execPath), 'node_modules/npm/bin/npm-cli.js'),
    ...(process.env.APPDATA ? [path.join(process.env.APPDATA, 'npm/node_modules/npm/bin/npm-cli.js')] : []),
  ];
  const cli = candidates.find(candidate => existsSync(candidate));
  if (!cli) throw new Error('PSC2_CHECKED_NPM_CLI_MISSING');
  return run(process.execPath, [cli, ...args], cwd);
}

function run(command, args, cwd = root) {
  const result = spawnSync(command, args, {
    cwd,
    stdio: 'inherit',
    timeout: 1200000,
    env: { ...process.env, PSC2_FIXED_POINT_PROBE_ACTIVE: '1' },
  });
  if (result.error) throw result.error;
  if (result.status !== 0) throw new Error(`PSC2_CHECKED_STEP_FAILED: ${command} ${args.join(' ')}`);
}

async function validateGeneration(generation, kernel) {
  const compiler = path.join(generation, 'packages/compiler/index.js');
  const receipt = JSON.parse(await readFile(compiler.replace(/\.js$/u, '.checked.json'), 'utf8'));
  for (const [key, value] of Object.entries(checkedKernelIdentity(kernel))) {
    if (receipt.provider?.[key] !== value) throw new Error('PSC2_CHECKED_GENERATION_PROVIDER');
  }
  const expectedKernel = checkedKernelDescriptor(kernel);
  if (Object.entries(expectedKernel).some(([key, value]) => receipt.kernel?.[key] !== value)) {
    throw new Error('PSC2_CHECKED_GENERATION_KERNEL');
  }
  if (receipt.kind !== 'psc2-checked-build' || receipt.schemaVersion !== 3 ||
      hash(await readFile(compiler)) !== receipt.javaScriptSha256 ||
      hash(await readFile(compiler.replace(/\.js$/u, '.ts'))) !== receipt.typeScriptSha256 ||
      hash(await readFile(compiler.replace(/\.js$/u, '.admissions.json'))) !== receipt.canonicalAdmissionsSha256) {
    throw new Error('PSC2_CHECKED_GENERATION_INTEGRITY');
  }
  return compiler; // Integrity check only; a receipt is not an independently signed certificate.
}

async function promote(staging, name) {
  const destination = path.join(base, name);
  await rm(destination, { recursive: true, force: true });
  await rename(staging, destination);
}

async function bootstrap(kernel) {
  // Fail fast on the real PSC1 project parse/elaboration gate before the
  // broader bootstrap suite or the longer checked seed session.
  runNpm(['run', 'bootstrap:check']);
  runNpm(['run', 'bootstrap:lean']);
  const hostTargets = kernel === 'lean434'
    ? ['build', 'psc2_lean_checked_seed', 'psc2_lean_kernel_provider']
    : ['build', 'psc2_lean_checked_seed'];
  run('lake', hostTargets, path.join(root, 'lean-checked'));
  const config = JSON.parse(await readFile(path.join(root, 'psconfig.json'), 'utf8'));
  await buildChecked({
    entryPath: path.join(root, config.entry),
    seedPath: defaultCheckedSeed,
    checkOnly: true,
    kernel,
  });
  await mkdir(base, { recursive: true });
  const stage = await mkdtemp(path.join(base, '.bootstrap-'));
  try {
    run(process.execPath, ['scripts/bootstrap-project.mjs', config.entry, path.join(stage, 'workspace')]);
    const manifest = JSON.parse(await readFile(path.join(stage, 'workspace/.proofscript-bootstrap.json'), 'utf8'));
    await buildChecked({
      entryPath: path.join(stage, 'workspace', manifest.entry),
      seedPath: defaultCheckedSeed,
      outputPath: path.join(stage, 'packages/compiler/index.js'),
      kernel,
    });
    await promote(stage, 'bootstrap');
  } finally {
    await rm(stage, { recursive: true, force: true });
  }
  console.log(`PSC2_LEAN_CHECKED_BOOTSTRAP: PASS kernel=${kernel}`);
}

async function next(parentName, name, kernel) {
  const parent = path.join(base, parentName);
  const compiler = await validateGeneration(parent, kernel);
  const parentWorkspace = path.join(parent, 'workspace');
  const manifestFile = parentName === 'bootstrap' ? '.proofscript-bootstrap.json' : '.proofscript-selfhost.json';
  const manifest = JSON.parse(await readFile(path.join(parentWorkspace, manifestFile), 'utf8'));
  const stage = await mkdtemp(path.join(base, `.${name}-`));
  try {
    run(process.execPath, [
      'scripts/reemit-project-with-generated.mjs',
      compiler,
      parentWorkspace,
      path.join(stage, 'workspace'),
    ]);
    await buildChecked({
      entryPath: path.join(stage, 'workspace', manifest.entry),
      compilerPath: compiler,
      outputPath: path.join(stage, 'packages/compiler/index.js'),
      kernel,
    });
    await promote(stage, name);
  } finally {
    await rm(stage, { recursive: true, force: true });
  }
  console.log(`PSC2_LEAN_CHECKED_GENERATION: PASS ${name} kernel=${kernel}`);
}

async function compare(kernel) {
  for (const name of ['bootstrap', 'selfhost', 'repeat']) {
    await validateGeneration(path.join(base, name), kernel);
  }
  for (const name of ['selfhost', 'repeat']) {
    run(process.execPath, [
      'scripts/compare-source-workspaces.mjs',
      path.join(base, 'bootstrap/workspace'),
      path.join(base, name, 'workspace'),
    ]);
    run(process.execPath, [
      'scripts/compare-selfhost.mjs',
      path.join(base, 'bootstrap/packages/compiler/index.ts'),
      path.join(base, name, 'packages/compiler/index.ts'),
    ]);
  }
  console.log(`PSC2_LEAN_CHECKED_GENERATION_INTEGRITY_AND_PARITY: PASS kernel=${kernel}`);
}

const args = process.argv.slice(2);
const stage = args.shift();
let kernel = defaultCheckedKernel;
while (args.length) {
  const flag = args.shift();
  if (flag === '--kernel') {
    const value = args.shift();
    if (!value || value.startsWith('--')) throw new Error('Missing value for --kernel');
    kernel = value;
  } else {
    throw new Error(`Unknown checked-selfhost option: ${flag}`);
  }
}
checkedKernelDescriptor(kernel);
base = path.join(root, 'dist/checked', kernel);
if (!stage) throw new Error('usage: checked-selfhost.mjs bootstrap|next|fixed-point|verify [--kernel lean434-wasm|pskernel-core|lean434]');

switch (stage) {
  case 'bootstrap':
    await bootstrap(kernel);
    break;
  case 'next':
    await next('bootstrap', 'selfhost', kernel);
    break;
  case 'verify':
    await compare(kernel);
    break;
  case 'fixed-point':
    await bootstrap(kernel);
    await next('bootstrap', 'selfhost', kernel);
    await next('selfhost', 'repeat', kernel);
    await compare(kernel);
    console.log(`PSC2_LEAN_CHECKED_FIXED_POINT: PASS kernel=${kernel}`);
    break;
  default:
    throw new Error('Unknown checked self-host command');
}
