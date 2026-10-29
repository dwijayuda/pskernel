// Real offline root installation and default independent Wasm admission.
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { pathToFileURL } from 'node:url';
import { sha256 } from './kernel435-qualified-artifact.mjs';
import { fixtures } from './kernel435-fixtures.mjs';
const out = path.resolve('dist/modular-toolchain'),
  receipt = JSON.parse(fs.readFileSync(path.join(out, 'package-receipt.json')));
const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'psc1-modular-root-'));
const runtime = process.argv[2] || process.execPath;
const bun = path.basename(runtime).startsWith('bun'),
  flags = bun ? ['--no-install', '--no-macros', '--no-env-file'] : [];
function call(exe, args, cwd = directory) {
  const r = spawnSync(exe, args, { cwd, encoding: 'utf8', timeout: 240000, maxBuffer: 33554432 });
  assert.equal(r.error, undefined, String(r.error));
  return r;
}
function run(exe, args, cwd = directory) {
  const r = call(exe, args, cwd);
  assert.equal(r.status, 0, r.stdout + r.stderr);
  return r.stdout;
}
const npm = path.resolve(path.dirname(process.execPath), '../lib/node_modules/npm/bin/npm-cli.js');
const records = [];
try {
  fs.writeFileSync(path.join(directory, 'package.json'), '{"private":true,"type":"module"}');
  run(process.execPath, [
    npm,
    'install',
    '--offline',
    '--ignore-scripts',
    '--no-audit',
    '--no-fund',
    '--registry',
    'http://127.0.0.1:9',
    '--cache',
    path.join(directory, 'empty-cache'),
    path.join(out, 'tarballs', receipt.tarball),
  ]);
  const root = path.join(directory, 'node_modules/proofscript'),
    cli = path.join(root, 'dist/psc.mjs');
  assert.match(run(runtime, [...flags, cli, '--help']), /psc check/);
  assert.equal(run(runtime, [...flags, cli, '--version']).trim(), 'proofscript ' + receipt.version);
  const identity = JSON.parse(run(runtime, [...flags, cli, '--identity']));
  assert.equal(identity.compilerSourceClosureDigest, receipt.compilerSourceClosureDigest);
  assert.equal(identity.defaultKernel, 'wasm');
  assert.equal(identity.engines.js.kind, 'modular-graph');
  assert.equal(identity.engines.ts.kind, 'modular-graph');
  assert.equal(identity.engines.rust.installed, false);
  assert.equal(identity.engines['wasm-core'].installed, false);
  for (const name of ['backend-python', 'backend-php', 'compiler-rust-linux-x64', 'compiler-wasm'])
    assert.equal(fs.existsSync(path.join(root, 'node_modules/@proofscript', name)), false);
  const program = path.join(directory, 'exercise.mjs');
  fs.writeFileSync(
    program,
    [
      "import assert from 'node:assert/strict';import fs from 'node:fs';import {pathToFileURL}from'node:url';",
      "import {build,compile,checkCanonicalAdmissions} from 'proofscript';",
      "import {compile as direct}from 'proofscript/compiler';",
      'assert.equal(compile,direct);',
      "const records=[];for(const engine of ['js','ts'])for(const kind of ['lean','ps'])for(const target of ['js','wasm-core']){",
      "const options={engine,target,sources:[{module:'Entry',kind,text:'def answer : Nat := 42\\n'}],entryModule:'Entry',publicationProtocol:'portable-file',out:'out-'+engine+'-'+kind+'-'+target};",
      "const r=build(options),api=await import(pathToFileURL(r.runtimeArtifact));assert.equal(String((api.default||api).answer),'42');",
      "assert.equal(r.kernelProviders.join(','),'wasm');assert.equal(r.logicalAdmission,'accepted');records.push({engine,kind,target,receipt:r.receipt});}",
      "for(const f of JSON.parse(fs.readFileSync(process.argv[2]))){const r=await checkCanonicalAdmissions(f.input);assert.equal(r.accepted,f.accepted,f.id);assert.equal(r.leanVersion,'4.35.0');records.push({kernel:f.id,accepted:r.accepted});}",
      "console.log('PSC1_MODULAR_ROOT_EXERCISE '+JSON.stringify(records));",
    ].join('\n'),
  );
  const fixtureFile = path.join(directory, 'kernel-fixtures.json');
  fs.writeFileSync(fixtureFile, JSON.stringify(fixtures));
  const result = run(runtime, [...flags, program, fixtureFile]);
  const line = result.split('\n').find((l) => l.startsWith('PSC1_MODULAR_ROOT_EXERCISE '));
  assert.ok(line);
  records.push(...JSON.parse(line.slice('PSC1_MODULAR_ROOT_EXERCISE '.length)));
  const generatedProgram = path.join(directory,'generated-imports.mjs');
  fs.writeFileSync(generatedProgram,
    "import assert from'node:assert/strict';import{pathToFileURL}from'node:url';"+
    "for(const variant of ['js','ts']){const root=await import('proofscript/foundation/generated/runtime'+(variant==='ts'?'/ts':''));"+
    "const direct=await import(pathToFileURL(process.argv[2]+'/node_modules/@proofscript/foundation/dist/'+variant+'/generated/runtime.mjs'));"+
    "assert.deepEqual(Object.keys(root),Object.keys(direct));for(const k of Object.keys(root))assert.equal(root[k],direct[k]);}");
  run(runtime,[...flags,generatedProgram,root]);
  const compiler = path.join(root, 'node_modules/@proofscript/compiler');
  assert.equal(fs.existsSync(path.join(compiler, 'dist/implementation')), false);
  assert.equal(fs.existsSync(path.join(compiler, 'dist/host/selfhost')), false);
  const nodes = path.join(root, 'node_modules'),
    manifest = JSON.parse(fs.readFileSync(path.join(root, 'dist/COMPILER_GRAPH.json')));
  assert.equal(manifest.units.length, 134);
  assert.equal(manifest.sourceGraph.manifestSha256, receipt.sourceGraphManifestSha256);
  assert.equal(manifest.compilerSelfHosting.status, 'qualified-finite-linux-modular-js-ts');
  assert.deepEqual(manifest.compilerSelfHosting, receipt.compilerSelfHosting);
  const selfHostBytes = fs.readFileSync(path.join(root, receipt.compilerSelfHosting.receiptPath));
  assert.equal(sha256(selfHostBytes), receipt.compilerSelfHosting.receiptSha256);
  const selfHost = JSON.parse(selfHostBytes);
  assert.equal(selfHost.sourceClosureDigest, receipt.compilerSourceClosureDigest);
  for (const variant of ['js', 'ts']) {
    assert.equal(selfHost.generations[variant].report.status, 'passed');
    assert.equal(selfHost.generations[variant].report.nativeFrontendCalls, 0);
  }
  const sample = manifest.files.find(
    (r) => r.path.includes('/dist/js/generated/') && r.path.endsWith('.mjs'),
  );
  const file = path.join(nodes, sample.path),
    before = fs.readFileSync(file);
  fs.appendFileSync(file, "\nthrow Error('UNVERIFIED_MODULE_EXECUTED');");
  try {
    const refused = call(runtime, [...flags, cli, '--identity']);
    assert.notEqual(refused.status, 0);
    assert.match(refused.stderr, /PSC1_EXECUTABLE/);
    assert.doesNotMatch(refused.stderr, /UNVERIFIED_MODULE_EXECUTED/);
  } finally {
    fs.writeFileSync(file, before);
  }
  const report = {
    schema: 'psc1-modular-root-smoke/1',
    status: 'passed',
    testedCommit: process.env.GITHUB_SHA,
    runtime,
    runtimeVersion: run(runtime, ['--version']).trim(),
    records,
    corePackages: 20,
    checkedBuilds: 8,
    kernelCases: fixtures.length,
    tamperedModuleRefused: true,
    oldExecutorsAbsent: true,
    defaultKernel: 'wasm',
    tarballSha256: receipt.sha256,
  };
  fs.writeFileSync(
    path.join(out, 'smoke-' + (bun ? 'bun' : 'node') + '.json'),
    JSON.stringify(report, null, 2) + '\n',
  );
  console.log('PSC1_MODULAR_ROOT_SMOKE ' + JSON.stringify(report));
} finally {
  fs.rmSync(directory, { recursive: true, force: true });
}
