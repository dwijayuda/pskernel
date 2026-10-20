// Real unpublished npm source packages through the installed native compiler.
// No manifest is an admission certificate; malformed source must still fail.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { pathToFileURL, fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';
const workspace = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const [output, cli] = process.argv.slice(2);
if (!output || !cli) throw Error('usage: npm-native-library-canary.mjs <output-directory> <installed-cli>');
const root = path.resolve(output);
const compiler = path.resolve(cli);
const pin = JSON.parse(fs.readFileSync(path.join(workspace, 'NATIVE_SOURCE_PIN.json'), 'utf8'));
fs.mkdirSync(root, { recursive: true });
const packDirectory = path.join(root, 'tarballs');
fs.mkdirSync(packDirectory, { recursive: true });
const json = value => JSON.stringify(value, null, 2) + '\n';
const sha = file => createHash('sha256').update(fs.readFileSync(file)).digest('hex');
function write(file, value) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, value);
}
function run(command, args, cwd = root, negative = false) {
  const env = { ...process.env };
  delete env.PSC1_NATIVE; delete env.PSC1_HOST_TOOLS; delete env.PSC1_LIBRARY_RESOLVER;
  const result = spawnSync('timeout', ['--kill-after=5s', '180s', command, ...args],
    { cwd, env, encoding: 'utf8', timeout: 190000, maxBuffer: 32 * 1024 * 1024 });
  if (result.error || (negative ? result.status === 0 : result.status !== 0)) {
    throw Error('PSC1_NPM_CANARY_COMMAND: ' + command + ' ' + args.join(' ') + '\n' +
      (result.error?.message || '') + result.stdout + result.stderr);
  }
  return result;
}
function contract(prefix, publicModules) {
  return { schemaVersion: 2, kind: 'portable-source', sourceRoot: 'src', sourceKind: 'ps',
    modulePrefix: prefix, publicModules, compilerProfile: pin.compilerProfile,
    leanVersion: pin.version, leanCommit: pin.commit };
}
function pack(directory) {
  const result = run('npm', ['pack', directory, '--json', '--ignore-scripts', '--pack-destination', packDirectory]);
  const parsed = JSON.parse(result.stdout);
  assert.equal(parsed.length, 1);
  return path.join(packDirectory, parsed[0].filename);
}
const seed = path.join(root, 'seed-package');
write(path.join(seed, 'package.json'), json({
  name: '@psc1-demo/seed', version: '0.0.1', private: true, type: 'module', files: ['src/'],
  exports: { './package.json': './package.json' },
  proofscript: { library: contract('Seed', ['Seed.Value']) }
}));
write(path.join(seed, 'src/Seed/Value.ps'), 'def seedValue : Nat := 40\n');
const seedTarball = pack(seed);
const library = path.join(root, 'naturals-package');
write(path.join(library, 'package.json'), json({
  name: '@psc1-demo/naturals', version: '0.0.1', private: true, type: 'module', files: ['src/'],
  exports: { './package.json': './package.json' }, dependencies: { '@psc1-demo/seed': '0.0.1' },
  proofscript: { library: contract('Demo', ['Demo.Math']), libraries: { Seed: '@psc1-demo/seed' } }
}));
write(path.join(library, 'src/Demo/Private.ps'), 'def privateOffset : Nat := 2\n');
write(path.join(library, 'src/Demo/Math.ps'),
  'import Seed.Value\nimport Demo.Private\n\ndef demoAnswer : Nat := seedValue + privateOffset\n');
const libraryTarball = pack(library);
const project = path.join(root, 'consumer');
write(path.join(project, 'package.json'), json({
  name: 'psc1-installed-library-consumer', version: '0.0.0', private: true, type: 'module',
  proofscript: { libraries: { Demo: '@psc1-demo/naturals' } }
}));
run('npm', ['install', '--offline', '--ignore-scripts', '--no-audit', '--no-fund',
  '--prefix', project, seedTarball, libraryTarball]);
const input = path.join(project, 'src/Main.ps');
write(input, 'import Demo.Math\n\ndef answer : Nat := demoAnswer\n');
const outputJs = path.join(project, 'dist/Main.js');
const command = ['build', input, '--target', 'js', '--out', outputJs];
const checked = run(process.execPath, [compiler, 'check', input], project);
const built = run(process.execPath, [compiler, ...command], project);
const mod = await import(pathToFileURL(outputJs).href);
assert.deepEqual(Object.keys(mod), ['answer'], 'private or dependency declarations escaped public API');
assert.equal(typeof mod.answer === 'function' ? mod.answer() : mod.answer, 42n);
const manifestPath = outputJs + '.bundle.json';
const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
assert.equal(manifest.logicalChecker, 'lean4:' + pin.version);
assert.equal(manifest.logicalCheckerCommit, pin.commit);
assert.equal(manifest.behaviorallyVerified, false);
assert.equal(manifest.assurance, 'checked-logical');
const stage = path.dirname(fs.realpathSync(outputJs));
const captured = JSON.parse(fs.readFileSync(path.join(stage, 'psc1-input.json'), 'utf8'));
assert.equal(captured.sources.length, 4, 'complete transitive checked source closure');
assert.ok(captured.sources.some(x => x.path.endsWith('/Seed/Value.ps')));
assert.ok(captured.sources.some(x => x.path.endsWith('/Demo/Private.ps')));
const admitted = fs.readFileSync(path.join(stage, 'admissions.json'), 'utf8');
assert.ok(admitted.includes('seedValue') && admitted.includes('privateOffset') && admitted.includes('demoAnswer'));
const previous = sha(outputJs), previousManifest = sha(manifestPath);
function rejected(source, expected) {
  write(input, source);
  const failed = run(process.execPath, [compiler, ...command], project, true);
  assert.match(failed.stdout + failed.stderr, expected);
  assert.equal(sha(outputJs), previous, 'failed build changed previous source output');
  assert.equal(sha(manifestPath), previousManifest, 'failed build changed previous manifest');
}
rejected('import Demo.Private\n\ndef answer : Nat := privateOffset\n', /PSC1_LIBRARY_PRIVATE_MODULE/);
const installedMeta = path.join(project, 'node_modules/@psc1-demo/naturals/package.json');
const goodMeta = fs.readFileSync(installedMeta, 'utf8');
const badMeta = JSON.parse(goodMeta);
badMeta.proofscript.library.leanCommit = '0'.repeat(40);
write(installedMeta, json(badMeta));
rejected('import Demo.Math\n\ndef answer : Nat := demoAnswer\n', /PSC1_LIBRARY_PROFILE_MISMATCH/);
write(installedMeta, goodMeta);
const installedSource = path.join(project, 'node_modules/@psc1-demo/seed/src/Seed/Value.ps');
write(installedSource, 'def seedValue : Nat := true\n');
rejected('import Demo.Math\n\ndef answer : Nat := demoAnswer\n', /PSC1_PROJECT_ELAB_FAILED/);
write(installedSource, 'def seedValue : Nat := 40\n');
write(input, 'import Demo.Math\n\ndef answer : Nat := demoAnswer\n');
const receipt = { schemaVersion: 1, sourceCommit: process.env.GITHUB_SHA || null, branchHeadCommit: process.env.PSC1_HEAD_SHA || null,
  compilerIdentity: pin, installedPackages: ['@psc1-demo/seed@0.0.1', '@psc1-demo/naturals@0.0.1'],
  target: 'js', result: '42', capturedSources: captured.sources.length,
  independentlyAdmitted: true, sourceOnly: true, publicExports: Object.keys(mod),
  transitivePackageDependency: true, privateModuleRefused: true, incompatibleProfileRefused: true,
  illTypedDependencyRefused: true, failedBuildPreservedPrevious: true,
  sourceClosureSha256: manifest.sourceClosureSha256, outputSha256: previous,
  libraryTarballs: [seedTarball, libraryTarball].map(file => ({ file: path.basename(file), sha256: sha(file) })),
  checkOutput: checked.stdout, buildOutput: built.stdout };
write(path.join(root, 'qualification.json'), json(receipt));
console.log('PSC1_NPM_SOURCE_LIBRARY: PASS ' + JSON.stringify(receipt));
