// New-source installed package acceptance. Source fixtures are installed as data;
// package JS is never imported. Compiler/checker selection stays with the host.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { spawnSync } from 'node:child_process';
import { readQualifiedArtifact, sha256 as sha } from './kernel435-qualified-artifact.mjs';
import { compilerSourceClosureDigest } from '../host-tools/compiler-host-protocol.mjs';
import { readOwnedCompilerSources } from '../host-tools/compiler-source-inputs.mjs';
import { executeApplication } from './output-abi-applications.mjs';
const out = path.resolve('dist/slim-universal');
const assembly = JSON.parse(fs.readFileSync(path.join(out, 'package-receipt.json')));
assert.ok(assembly.input.qualifiedCompilerGenerations, 'new-source G3 qualification is mandatory');
const referenceInput = JSON.parse(fs.readFileSync('scripts/generated-io-application-reference.json'));
const archive = await readQualifiedArtifact(referenceInput, path.join(out, 'application-reference'));
const reference = JSON.parse(fs.readFileSync(path.join(archive, 'output-abi/native-reference.json')));
assert.equal(reference.applications.length, 4);
const census = JSON.parse(fs.readFileSync(path.join(archive, 'source-conversion/census-lean.json')));
// Lean census records contain measured stage/byte/import facts; only the PS
// translation lane carries inputSource. Hash the actual owned source bytes and
// bind the archived ordered census to those same modules, bytes and imports.
const owned = readOwnedCompilerSources('Ps.CompilerUnified.Service');
assert.equal(compilerSourceClosureDigest(owned.map(row => ({ ...row, kind: 'lean' }))),
  assembly.compilerSourceClosureDigest);
assert.equal(census.schema, 'psc1-live-source-stage-probe/1');
assert.equal(census.grammar, 'lean');
assert.deepEqual(census.records.map(row => row.module), owned.map(row => row.module));
census.records.forEach((row, index) => {
  const source = owned[index];
  assert.equal(row.grammar, 'lean');
  assert.equal(row.translation, 'not-applicable');
  assert.equal(row.parse, 'accepted'); assert.equal(row.elaboration, 'accepted');
  assert.equal(row.utf8Bytes, Buffer.byteLength(source.text));
  assert.equal(row.inputUtf8Bytes, Buffer.byteLength(source.text));
  const imports = [...source.text.matchAll(/^import\s+(.+)$/gm)]
    .flatMap(match => match[1].trim().split(/\s+/));
  assert.deepEqual(row.parsedImports, imports);
});

const temporary = fs.mkdtempSync(path.join(os.tmpdir(), 'proofscript-installed-applications-'));
const consumer = path.join(temporary, 'consumer'), prefix = path.join(temporary, 'global');
fs.mkdirSync(consumer);
fs.writeFileSync(path.join(consumer, 'package.json'), '{"private":true,"type":"module"}\n');
const npm = path.resolve(path.dirname(process.execPath), '../lib/node_modules/npm/bin/npm-cli.js');
const env = { ...process.env, PATH: path.dirname(process.execPath) };
for (const key of Object.keys(env))
  if (key === 'NODE_OPTIONS' || key.startsWith('PSC1_') || key === 'LEAN_PATH' ||
      key === 'ELAN_TOOLCHAIN' || key === 'LD_LIBRARY_PATH' || key === 'DYLD_LIBRARY_PATH' ||
      key === 'PSC_LEAN_KERNEL_PROVIDER_BIN') delete env[key];
function run(args, options = {}) {
  const result = spawnSync(process.execPath, args, { cwd: consumer, env, encoding: 'utf8',
    timeout: 240000, maxBuffer: 32 * 1024 * 1024, ...options });
  assert.equal(result.error, undefined, String(result.error));
  assert.equal(result.status, 0, result.stdout + result.stderr);
  return result.stdout;
}
const dataPackage = path.join(temporary, 'source-package');
fs.mkdirSync(dataPackage);
const fixtureManifest = { schema: 'psc1-acceptance-source-fixtures/1', fixtures: [] };
for (const expected of reference.applications) {
  const native = reference.requestInventory.find(item => item.request[1] === expected.id);
  assert.ok(native);
  const wire = native.request;
  const sources = wire[6].map(([module, text]) => {
    assert.match(module, /^[A-Za-z_][A-Za-z_0-9]*(\.[A-Za-z_][A-Za-z_0-9]*)*$/);
    const relative = 'sources/' + expected.id + '/' + module.replaceAll('.', '/') + '.' + wire[3];
    const file = path.join(dataPackage, relative);
    fs.mkdirSync(path.dirname(file), { recursive: true }); fs.writeFileSync(file, text);
    return { module, kind: wire[3], file: relative, bytes: Buffer.byteLength(text), sha256: sha(text) };
  });
  fixtureManifest.fixtures.push({ id: expected.id, entryModule: wire[5], sources });
}
fs.writeFileSync(path.join(dataPackage, 'source-inputs.json'), JSON.stringify(fixtureManifest, null, 2));
fs.writeFileSync(path.join(dataPackage, 'never-run.mjs'),
  'throw new Error("source fixture package JavaScript must never execute");\n');
fs.writeFileSync(path.join(dataPackage, 'package.json'), JSON.stringify({
  name: '@proofscript/acceptance-sources', version: '0.0.0', private: true, type: 'module',
  exports: { '.': './never-run.mjs', './package.json': './package.json' },
  files: ['sources/', 'source-inputs.json', 'never-run.mjs'],
}));
const packed = JSON.parse(run([npm, 'pack', dataPackage, '--ignore-scripts', '--json',
  '--pack-destination', temporary]));
assert.equal(packed.length, 1);
const packages = [path.join(out, 'tarballs', assembly.tarball),
  ...['rust', 'wasm-core', 'nativeKernel'].map(key =>
    path.join(out, 'tarballs', assembly.input.packages[key].tarball))];
const install = (args, cache) => run([npm, 'install', '--cache', cache, '--offline',
  '--registry', 'http://127.0.0.1:9', '--ignore-scripts', '--no-audit', '--no-fund', ...args]);
install(['--prefix', consumer, ...packages, path.join(temporary, packed[0].filename)],
  path.join(temporary, 'local-empty-cache'));
install(['--global', '--prefix', prefix, ...packages], path.join(temporary, 'global-empty-cache'));
const localRoot = path.join(consumer, 'node_modules/proofscript');
const localCli = path.join(localRoot, 'npm-cli/universal-cli.mjs');
const globalRoot = path.join(prefix, 'lib/node_modules/proofscript');
const globalCli = path.join(globalRoot, 'npm-cli/universal-cli.mjs');
const metadata = JSON.parse(run([localCli, '--identity']));
assert.equal(metadata.compilerSourceClosureDigest, assembly.compilerSourceClosureDigest);
for (const engine of ['js', 'ts', 'rust', 'wasm-core']) assert.equal(metadata.engines[engine].installed, true);
const installedSourceRoot = path.join(consumer, 'node_modules/@proofscript/acceptance-sources');
const installedManifest = JSON.parse(fs.readFileSync(path.join(installedSourceRoot, 'source-inputs.json')));
assert.deepEqual(installedManifest, fixtureManifest);
const launcherText = "import fs from 'node:fs';\nimport path from 'node:path';\nimport {pathToFileURL} from 'node:url';\nimport {createTypedIo} from 'proofscript/io';\n" +
  "process.env.PATH=path.dirname(process.execPath);\n" +
  "const [target,modulePath,configPath,...argv]=process.argv.slice(2);if(target!=='js')throw Error('checked target');\n" +
  "const config=JSON.parse(fs.readFileSync(configPath));let io;try{io=createTypedIo(config);}catch(error){if(String(error).includes('PSC1_IO_REQUIRED_CAPABILITY_DENIED'))process.exit(78);throw error;}\n" +
  "try{const program=await import(pathToFileURL(fs.realpathSync(modulePath)).href);process.exitCode=program.run(JSON.stringify(argv),request=>io.execute(request))?0:2;}finally{io.close();}\n";
const localLauncher = path.join(consumer, 'application-launcher.mjs');
const globalLauncher = path.join(prefix, 'lib/application-launcher.mjs');
fs.writeFileSync(localLauncher, launcherText); fs.writeFileSync(globalLauncher, launcherText);
const records = [], globalCases = [], negatives = [];
const report = { schema: 'psc1-installed-generated-io-applications/1',
  testedCommit: process.env.GITHUB_SHA, tarballSha256: assembly.sha256,
  compilerSourceClosureDigest: metadata.compilerSourceClosureDigest,
  sourceFixtureTarballSha256: sha(fs.readFileSync(path.join(temporary, packed[0].filename))),
  sourcePackages: 'offline installed data only; explicit dependency-ordered source arrays',
  automaticSourcePackageResolution: false, independentKernel: 'official Lean 4.35 linear-memory Wasm',
  optionalPackages: 'explicitly installed', noCompilerSdkOnExecutionPath: true,
  status: 'running', records, globalCases, negatives, publication: 'unpublished npm artifacts',
  fullCrossPlatformRelease: false };
const checkpoint = () => fs.writeFileSync(path.join(out, 'application-qualification.json'),
  JSON.stringify(report, null, 2) + '\n');
function capture(fixture) {
  const sources = fixture.sources.map(source => {
    assert.match(source.file, /^sources\/[A-Za-z0-9_\/.+-]+$/);
    const file = path.resolve(installedSourceRoot, source.file);
    assert.ok(file.startsWith(installedSourceRoot + path.sep));
    assert.equal(fs.lstatSync(file).isSymbolicLink(), false);
    const bytes = fs.readFileSync(file);
    assert.equal(bytes.length, source.bytes); assert.equal(sha(bytes), source.sha256);
    return { module: source.module, kind: source.kind,
      text: new TextDecoder('utf-8', { fatal: true, ignoreBOM: true }).decode(bytes) };
  });
  return { entryModule: fixture.entryModule, assurance: 'ordinary-checked', sources };
}
try {
  for (const engine of ['js', 'ts', 'rust', 'wasm-core']) for (const fixture of installedManifest.fixtures) {
    const expected = reference.applications.find(item => item.id === fixture.id);
    const project = path.join(consumer, engine + '-' + fixture.id + '.json');
    fs.writeFileSync(project, JSON.stringify(capture(fixture)));
    const store = path.join(out, 'installed-applications', engine, fixture.id, 'store');
    const result = JSON.parse(run([localCli, 'build', '--project', project, '--engine', engine,
      '--output-abi', 'io-dispatcher', '--out', store]));
    assert.equal(result.logicalAdmission, 'accepted');
    assert.equal(result.outputAbi, 'io-dispatcher');
    assert.deepEqual(result.kernelProviders, ['wasm']);
    assert.equal(result.compilerSourceClosureDigest, assembly.compilerSourceClosureDigest);
    for (const key of ['sourceClosureDigest', 'admissionsSha256', 'originalIrSha256', 'sourceSha256'])
      assert.equal(result.receipt[key], expected[key], engine + '/' + fixture.id + ':' + key);
    const contractFile = expected.application === 'cli-json'
      ? 'docs/PSC1_APPLICATION_EXECUTION_CONTRACT.json' : 'docs/PSC1_COMPILER_APPLICATION_CONTRACT.json';
    assert.equal(sha(fs.readFileSync(contractFile)), expected.contractSha256);
    const contract = JSON.parse(fs.readFileSync(contractFile));
    const cases = executeApplication({ ...expected, contract }, result.artifact,
      path.join(out, 'installed-applications', engine, fixture.id, 'executions'), localLauncher);
    records.push({ engine, id: fixture.id, sourceClosureDigest: result.receipt.sourceClosureDigest,
      admissionsSha256: result.receipt.admissionsSha256, originalIrSha256: result.receipt.originalIrSha256,
      sourceSha256: result.receipt.sourceSha256, generation: result.generation, cases });
    checkpoint();
    if (expected.application === 'cli-json') {
      const globalStore = path.join(out, 'installed-applications', engine, fixture.id, 'global-store');
      const global = JSON.parse(run([globalCli, 'build', '--project', project, '--engine', engine,
        '--output-abi', 'io-dispatcher', '--out', globalStore]));
      assert.equal(global.receipt.sourceSha256, expected.sourceSha256);
      const help = { ...contract, cases: contract.cases.filter(item => item.id === 'help') };
      const observations = executeApplication({ ...expected, contract: help }, global.artifact,
        path.join(out, 'installed-applications', engine, fixture.id, 'global-execution'), globalLauncher);
      globalCases.push({ engine, id: fixture.id, actualGlobalIoEntry: true, cases: observations });
      const prior = fs.readlinkSync(path.join(store, 'current'));
      const injected = { ...capture(fixture), outputAbi: 'io-dispatcher' };
      fs.writeFileSync(project, JSON.stringify(injected));
      const denied = spawnSync(process.execPath, [localCli, 'build', '--project', project, '--out', store],
        { cwd: consumer, env, encoding: 'utf8', timeout: 240000, maxBuffer: 32 * 1024 * 1024 });
      assert.notEqual(denied.status, 0); assert.match(denied.stderr, /PROJECT_FIELDS/);
      assert.equal(fs.readlinkSync(path.join(store, 'current')), prior);
      negatives.push({ engine, id: fixture.id, sourceMetadataCannotSelectAbi: true, priorPreserved: true });
    }
    console.log('PSC1_INSTALLED_IO_APPLICATION: ' + JSON.stringify({
      engine, id: fixture.id, cases: cases.length, generation: result.generation }));
  }
  assert.equal(records.length, 16);
  assert.equal(records.reduce((count, record) => count + record.cases.length, 0), 264);
  assert.equal(globalCases.length, 8); assert.equal(negatives.length, 8);
  report.status = 'passed';
} catch (error) { report.status = 'failed'; report.failure = error.message; throw error; }
finally {
  checkpoint();
  console.log('PSC1_INSTALLED_IO_APPLICATIONS: ' + JSON.stringify({ status: report.status,
    applications: records.length, cases: records.reduce((count, record) => count + record.cases.length, 0),
    globalCases: globalCases.length, failure: report.failure }));
}
