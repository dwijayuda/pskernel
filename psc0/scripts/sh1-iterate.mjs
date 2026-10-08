import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { mkdir, mkdtemp, rename, rm, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { performance } from 'node:perf_hooks';
import { createInterface } from 'node:readline';
import { createGeneratedPreparationSession } from './generated-preparation-session.mjs';
import {
  loadGeneratedCompiler, readBootstrapClosure, stripBootstrapImports,
} from './sh1-source-snapshot.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const usage = 'node scripts/sh1-iterate.mjs --compiler <bundle.js> --compiler-sha256 <sha256> --once|--loop [--emit] [--out <directory>] [--workspace <psc0-root>]';
const args = process.argv.slice(2);
if (args.includes('--help')) { process.stdout.write(usage + '\n'); process.exit(0); }
const valued = new Set(['--compiler', '--compiler-sha256', '--out', '--workspace']);
const flags = new Set(['--once', '--loop', '--emit']);
const options = new Map();
for (let index = 0; index < args.length; index++) {
  const name = args[index];
  assert(!options.has(name) && (valued.has(name) || flags.has(name)), usage);
  if (valued.has(name)) {
    assert(index + 1 < args.length && !args[index + 1].startsWith('--'), usage);
    options.set(name, args[++index]);
  } else options.set(name, true);
}
assert(options.has('--compiler') && /^[a-f0-9]{64}$/u.test(options.get('--compiler-sha256') ?? ''), usage);
assert(options.has('--once') !== options.has('--loop'), usage);
const workspace = path.resolve(root, options.get('--workspace') ?? '.');
const outputRoot = path.resolve(root, options.get('--out') ?? 'dist/sh1-iteration');
const loadStart = performance.now();
const { compiler, compilerSha256 } = await loadGeneratedCompiler(
  path.resolve(root, options.get('--compiler')),
  { expectedSha256: options.get('--compiler-sha256') },
);
const session = createGeneratedPreparationSession(compiler, { compilerSha256 });
const sha256 = (value) => createHash('sha256').update(value).digest('hex');
const json = (value) => JSON.stringify(value, null, 2) + '\n';
let requestNumber = 0;

function unwrap(value, stage) {
  const tag = value && typeof value === 'object'
    ? Object.getOwnPropertySymbols(value).map((symbol) => value[symbol]).find((x) => x === 'ok' || x === 'error')
    : undefined;
  if (tag === 'ok') return value.value;
  const detail = JSON.stringify(value?.error, (_key, item) => {
    if (typeof item === 'bigint') return item.toString();
    if (item && typeof item === 'object' && !Array.isArray(item)) {
      const tags = Object.getOwnPropertySymbols(item).map((symbol) => item[symbol]);
      if (tags.length) return { ...item, $constructors: tags };
    }
    return item;
  });
  throw new Error('PSC0_SH1_ITERATION_' + stage + ': ' + (detail ?? 'invalid result shape'));
}

// Stage the complete product set on the same filesystem, then publish its
// directory with one rename. A failed request never overwrites an earlier one.
async function publish(products, receipt) {
  await mkdir(outputRoot, { recursive: true });
  const staging = await mkdtemp(path.join(outputRoot, '.preparing-'));
  const destination = path.join(outputRoot, 'emission-' + path.basename(staging).slice('.preparing-'.length));
  try {
    for (const [name, text] of Object.entries(products)) await writeFile(path.join(staging, name), text);
    receipt.outputDirectory = destination;
    await writeFile(path.join(staging, 'receipt.json'), json(receipt));
    await rename(staging, destination);
  } catch (error) {
    await rm(staging, { recursive: true, force: true });
    throw error;
  }
}

async function prepare(emit) {
  const start = performance.now();
  const closure = await readBootstrapClosure(workspace);
  const snapshotDone = performance.now();
  const result = session.prepare('lean', closure.ordered.map(({ path: sourcePath, source }) => ({
    path: sourcePath, source: stripBootstrapImports(source),
  })));
  const preparedDone = performance.now();
  let products;
  let artifacts;
  if (emit) {
    const admissions = unwrap(compiler.psCompilerAdmissionsFromPrepared(result.prepared), 'ADMISSIONS');
    const typeScript = unwrap(compiler.psCompilerTypeScriptFromPrepared(result.prepared), 'EMIT');
    products = { 'admissions.json': admissions, 'index.ts': typeScript, 'source-closure.json': json(closure.manifest) };
    artifacts = { admissionsSha256: sha256(admissions), typeScriptSha256: sha256(typeScript) };
  }
  const emittedDone = performance.now();
  assert.equal((await readBootstrapClosure(workspace)).sha256, closure.sha256,
    'PSC0_SH1_ITERATION_SOURCE_CHANGED_DURING_REQUEST');
  const receipt = {
    schemaVersion: 1, kind: 'psc0-sh1-iteration', request: ++requestNumber,
    evidence: 'admission-ready', kernelChecked: false, strictSh1Qualified: false,
    compilerSha256, sourceClosureSha256: closure.sha256, moduleCount: closure.moduleCount,
    unchangedPrefixModules: result.receipt.cache.prefixModules,
    rebuiltSuffixModules: result.receipt.cache.preparedModules,
    preparation: result.receipt, artifacts,
    timingsMs: {
      snapshot: snapshotDone - start, prepare: preparedDone - snapshotDone,
      emit: emittedDone - preparedDone, revalidateSources: performance.now() - emittedDone,
      throughSourceRevalidation: performance.now() - start,
    },
  };
  const publishStart = performance.now();
  if (products) await publish(products, receipt);
  process.stdout.write('PSC0_SH1_ITERATION: ' + JSON.stringify({
    ...receipt, publicationMs: performance.now() - publishStart, totalMs: performance.now() - start,
  }) + '\n');
}

async function request(emit) {
  try { await prepare(emit); process.exitCode = 0; }
  catch (error) {
    process.exitCode = 1;
    process.stderr.write('PSC0_SH1_ITERATION_FAILED: ' + error.message + '\n');
  }
}

process.stdout.write('PSC0_SH1_ITERATION_SESSION: ' + JSON.stringify({
  compilerSha256, workspace, loadMs: performance.now() - loadStart,
  compilerReload: 'Restart the process with a new explicit digest to change compiler instances.',
}) + '\n');
await request(options.has('--emit'));
if (options.has('--loop')) {
  process.stderr.write('Commands: Enter or prepare, emit, reset, quit. Every request rereads the current closure.\n');
  const lines = createInterface({ input: process.stdin, crlfDelay: Infinity });
  try {
    for await (const line of lines) {
      const command = line.trim();
      if (command === 'quit') break;
      if (command === 'reset') {
        session.reset();
        process.stdout.write('PSC0_SH1_ITERATION_RESET\n');
      } else if (command === '' || command === 'prepare' || command === 'emit') {
        await request(command === 'emit');
      } else {
        process.exitCode = 1;
        process.stderr.write('PSC0_SH1_ITERATION_COMMAND: prepare, emit, reset, quit\n');
      }
    }
  } finally { lines.close(); }
}
