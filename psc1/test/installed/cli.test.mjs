// Real offline npm consumer test for the new CLI. No compiler/checker stubs.
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {pathToFileURL} from 'node:url';
import {sha256} from '../../scripts/kernel435-qualified-artifact.mjs';
const out = path.resolve('dist/slim-universal'), artifacts = path.resolve('dist/cli');
fs.mkdirSync(artifacts, {recursive: true});
const assembly = JSON.parse(fs.readFileSync(path.join(out, 'package-receipt.json')));
const tarballs = path.join(out, 'tarballs'), tar = path.join(tarballs, assembly.tarball);
assert.equal(sha256(fs.readFileSync(tar)), assembly.sha256);
const temporary = fs.mkdtempSync(path.join(os.tmpdir(), 'psc1-cli-installed-'));
const consumer = path.join(temporary, 'consumer with spaces'), prefix = path.join(temporary, 'global');
fs.mkdirSync(consumer);
fs.writeFileSync(path.join(consumer, 'package.json'), JSON.stringify({private: true, type: 'module',
  scripts: {check: 'psc check'}}));
// npm intentionally executes user-owned package scripts through the OS shell.
// Keep SDK-free PATH and choose that shell explicitly instead of restoring tools.
const env = {...process.env, PATH: path.dirname(process.execPath),
  npm_config_script_shell: '/bin/sh'};
for (const key of Object.keys(env))
  if (key === 'NODE_OPTIONS' || key.startsWith('PSC1_') || key === 'LEAN_PATH' ||
      key === 'ELAN_TOOLCHAIN' || key === 'LD_LIBRARY_PATH' || key === 'DYLD_LIBRARY_PATH')
    delete env[key];
const npm = path.resolve(path.dirname(process.execPath), '../lib/node_modules/npm/bin/npm-cli.js');
const requests = [], cases = [];
function call(executable, args, cwd = consumer) {
  const start = Date.now();
  const r = spawnSync(executable, args, {cwd, env, encoding: 'utf8',
    timeout: 240000, maxBuffer: 32 * 1024 * 1024});
  assert.equal(r.error, undefined, String(r.error));
  requests.push({command: path.basename(executable), args, elapsedMs: Date.now() - start, exit: r.status});
  return r;
}
function run(executable, args, cwd) {
  const r = call(executable, args, cwd); assert.equal(r.status, 0, r.stdout + r.stderr); return r.stdout;
}
function install(args, cache) {
  return run(process.execPath, [npm, 'install', '--offline', '--registry', 'http://127.0.0.1:9',
    '--ignore-scripts', '--no-audit', '--no-fund', '--cache', cache, ...args]);
}
install(['--prefix', consumer, tar], path.join(temporary, 'empty-cache'));
install(['--global', '--prefix', prefix, tar], path.join(temporary, 'global-empty-cache'));
const cli = path.join(consumer, 'node_modules/.bin/psc'), globalCli = path.join(prefix, 'bin/psc');
const root = path.join(consumer, 'node_modules/proofscript');
function observe(result) {
  return run(process.execPath, ['--input-type=module', '-e',
    'const m=await import(' + JSON.stringify(pathToFileURL(result.artifact).href) +
    ');console.log(String(m.answer));']).trim();
}
for (const name of ['psc', 'psc1', 'proofscript']) {
  assert.match(run(path.join(consumer, 'node_modules/.bin', name), ['--help']), /--showConfig/);
  assert.equal(run(path.join(prefix, 'bin', name), ['--version']).trim(),
    'proofscript 0.1.0-psc1.11');
}
const identity = JSON.parse(run(cli, ['--identity']));
assert.equal(identity.defaultKernel, 'wasm');
assert.equal(identity.compilerSourceClosureDigest, assembly.compilerSourceClosureDigest);
for (const [scope, bin] of [['local', cli], ['global', globalCli]]) {
  for (const kind of ['lean', 'ps']) {
    const project = path.join(consumer, scope + '-' + kind); fs.mkdirSync(project);
    run(bin, ['init', '--kind', kind], project);
    const inspected = JSON.parse(run(bin, ['--showConfig'], project));
    assert.equal(inspected.logicalAdmission, 'not-run');
    assert.equal(inspected.files[0].kind, kind);
    assert.equal(inspected.selection.engine, 'js');
    const checked = JSON.parse(run(bin, ['check'], project));
    assert.equal(checked.logicalAdmission, 'accepted'); assert.equal(checked.source, undefined);
    assert.deepEqual(checked.kernelProviders, ['wasm']);
    const compiled = JSON.parse(run(bin, ['compile', '-p', '.', '--engine=ts'], project));
    assert.equal(compiled.engine, 'ts'); assert.equal(compiled.publication, 'not-requested');
    assert.ok(compiled.source.includes('42'));
    const store = path.join(project, 'output with spaces');
    const built = JSON.parse(run(bin, ['build', '-o', store,
      '--publication-protocol=portable-file'], project));
    assert.equal(observe(built), '42');
    const source = path.join(project, 'Main.' + kind);
    fs.writeFileSync(source, '-- Unicode λ 😀\r\ndef answer : Nat := 43\r\n');
    const changed = JSON.parse(run(bin, ['build', '-p', project, '--out', store,
      '--publication-protocol', 'portable-file'], consumer));
    assert.equal(observe(changed), '43');
    assert.notEqual(changed.sourceClosureDigest, built.sourceClosureDigest);
    const pointer = fs.readFileSync(path.join(store, 'current.json'));
    const outputBytes = fs.readFileSync(changed.artifact);
    fs.writeFileSync(source, 'def answer : Nat := true\n');
    const denied = call(bin, ['build', '--out', store,
      '--publication-protocol', 'portable-file', '--diagnostics=json'], project);
    assert.notEqual(denied.status, 0); assert.equal(denied.stdout, '');
    const diagnostic = JSON.parse(denied.stderr);
    assert.equal(diagnostic.schema, 'proofscript-cli-diagnostic/1');
    assert.match(diagnostic.code, /^PSC1_/); assert.ok(diagnostic.message.length);
    assert.deepEqual(fs.readFileSync(path.join(store, 'current.json')), pointer);
    assert.deepEqual(fs.readFileSync(changed.artifact), outputBytes);
    cases.push({scope, grammar: kind, independentlyChecked: true,
      initialValue: 42, editedValue: 43, illTypedReplacementPreservedPrior: true});
    // Actual compiler-origin diagnostics and checked receipts are retained.
    fs.writeFileSync(path.join(artifacts, scope + '-' + kind + '.json'),
      JSON.stringify({inspected, checked, compiled: {...compiled, source: undefined},
        built, changed, diagnostic}, null, 2) + '\n');
  }
}
const multi = path.join(consumer, 'multi module'); fs.mkdirSync(multi);
fs.writeFileSync(path.join(multi, 'Lib.lean'), 'namespace Lib\ndef base : Nat := 40\nend Lib\n');
fs.writeFileSync(path.join(multi, 'Entry.lean'), 'import Lib\ndef answer : Nat := Lib.base + 2\n');
fs.writeFileSync(path.join(multi, 'proofscript.json'), JSON.stringify({
  schema: 'proofscript-project/1', entryModule: 'Entry',
  files: [{module: 'Lib', path: 'Lib.lean'}, {module: 'Entry', path: 'Entry.lean'}],
}));
const multiBuilt = JSON.parse(run(cli, ['build', '-p', multi, '-o', path.join(multi, 'out')]));
assert.equal(observe(multiBuilt), '42');
const npmProject = path.join(consumer, 'npm project'); fs.mkdirSync(npmProject);
run(cli, ['init'], npmProject);
fs.writeFileSync(path.join(npmProject, 'package.json'),
  '{"private":true,"scripts":{"check":"psc check"}}');
assert.match(run(process.execPath, [npm, 'run', 'check'], npmProject), /"logicalAdmission":"accepted"/);
const fromExec = JSON.parse(run(process.execPath,
  [npm, 'exec', '--offline', '--', 'psc', 'compile'], npmProject));
assert.equal(fromExec.logicalAdmission, 'accepted');
const projectFile = path.join(npmProject, 'proofscript.json');
const sourceData = JSON.parse(fs.readFileSync(projectFile));
fs.writeFileSync(projectFile, JSON.stringify({...sourceData, out: 'unauthorized'}));
const injection = call(cli, ['check', '--diagnostics=json'], npmProject);
assert.notEqual(injection.status, 0); assert.match(injection.stderr, /PROJECT_FIELDS/);
assert.equal(fs.existsSync(path.join(npmProject, 'unauthorized')), false);
fs.writeFileSync(projectFile, JSON.stringify(sourceData));
const optional = assembly.input.packages;
install(['--prefix', consumer, ...['rust', 'wasm-core'].map(key =>
  path.join(tarballs, optional[key].tarball))], path.join(temporary, 'optional-empty-cache'));
for (const engine of ['rust', 'wasm-core']) {
  const accepted = JSON.parse(run(cli, ['check', '-p', npmProject, '--engine', engine]));
  assert.equal(accepted.engine, engine); assert.equal(accepted.logicalAdmission, 'accepted');
}
const module = path.join(root, 'npm-cli/cli-project.mjs'), original = fs.readFileSync(module);
try {
  fs.appendFileSync(module, '\n// unexpected installed mutation\n');
  const refused = call(cli, ['--identity', '--diagnostics=json']);
  assert.notEqual(refused.status, 0); assert.match(refused.stderr, /RESOURCE_IDENTITY/);
} finally { fs.writeFileSync(module, original); }
const receipt = {schema: 'psc1-cli-installed/1', testedCommit: process.env.GITHUB_SHA,
  status: 'passed', rootSha256: assembly.sha256, version: assembly.version,
  sourceClosureDigest: assembly.compilerSourceClosureDigest, cases,
  npmRunAndExec: true, multiModuleFileProject: true, allThreeAliasesLocalGlobal: true,
  optionalFileProjectEngines: ['rust', 'wasm-core'], changedCliResourceRefused: true,
  sourceMetadataCannotSelectOutput: true, requests,
  humanUsability: 'pending-actual-participant', platform: 'linux-x64',
  compilerAndKernelPayloads: 'unchanged qualified G3 inputs'};
fs.writeFileSync(path.join(artifacts, 'installed.json'), JSON.stringify(receipt, null, 2) + '\n');
console.log('PSC1_CLI_INSTALLED: ' + JSON.stringify(receipt));
