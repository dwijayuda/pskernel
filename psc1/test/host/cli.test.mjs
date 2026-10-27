// CLI source boundary and real subprocess UX regressions. No compiler mocks.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import {readInput, captureProject, parseCompilation, initializeProject} from '../../npm-cli/cli-project.mjs';
const root = fs.mkdtempSync(path.join(os.tmpdir(), 'psc1-cli-unit-'));
const cli = fileURLToPath(new URL('../../npm-cli/proofscript-cli.mjs', import.meta.url));
const cases = [];
function test(name, run) { run(); cases.push(name); }
function call(args, cwd = root) {
  const r = spawnSync(process.execPath, [cli, ...args], {
    cwd, encoding: 'utf8', timeout: 10000, maxBuffer: 1024 * 1024,
  });
  assert.equal(r.error, undefined);
  return r;
}
const write = (name, value) => fs.writeFileSync(path.join(root, name), value);
const select = args => captureProject(parseCompilation(args), root);
const config = files => ({schema: 'proofscript-project/1', entryModule: 'Main', files});
try {
  test('watch aliases and invalid combinations are finite host options', () => {
    for (const flag of ['--watch', '-w', '-watch']) assert.equal(parseCompilation([flag]).watch, true);
    for (const args of [['--watch', '-w'], ['--watch', '--showConfig'], ['--watch=1']])
      assert.throws(() => parseCompilation(args), /watch|option/i);
  });
  test('help and empty invocation succeed without distribution, compiler or kernel', () => {
    for (const args of [[], ['--help'], ['-h'], ['help'], ['build', '--help']]) {
      const r = call(args); assert.equal(r.status, 0); assert.match(r.stdout, /--engine/);
      assert.match(r.stdout, /--target/); assert.match(r.stdout, /--showConfig/);
      assert.equal(r.stderr, '');
    }
  });
  test('version is human readable without verifying/executing a compiler', () => {
    const r = call(['--version']); assert.equal(r.status, 0);
    assert.match(r.stdout, /\S+ \d+\.\d+\.\d+/);
  });
  test('unknown command/option, duplicates, aliases and values refuse', () => {
    for (const args of [['wat'], ['check', '--targt', 'js'],
      ['check', '-p', 'x', '--project', 'y'], ['check', '--target', 'ruby'],
      ['check', '--kernel', 'wasm', '--provider', 'native'],
      ['check', '--engine'], ['check', '--out', 'out']]) {
      const r = call([...args, '--diagnostics=json']); assert.notEqual(r.status, 0);
      assert.equal(r.stdout, ''); const d = JSON.parse(r.stderr);
      assert.equal(d.schema, 'proofscript-cli-diagnostic/1'); assert.match(d.code, /^PSC1_CLI_/);
    }
  });
  test('build requires explicit output before touching a project', () => {
    const r = call(['build', '--diagnostics=json']); assert.notEqual(r.status, 0);
    assert.equal(JSON.parse(r.stderr).code, 'PSC1_CLI_OUTPUT_DIRECTORY');
    assert.equal(fs.existsSync(path.join(root, 'dist')), false);
  });
  test('missing project is actionable', () => {
    const r = call(['check']); assert.notEqual(r.status, 0);
    assert.match(r.stderr, /PROJECT_MISSING/); assert.match(r.stderr, /psc init/);
  });
  test('init creates editable .ps source and source-only project', () => {
    const r = call(['init']); assert.equal(r.status, 0, r.stderr);
    assert.equal(fs.readFileSync(path.join(root, 'Main.ps'), 'utf8'), 'def answer : Nat := 42\n');
    assert.deepEqual(JSON.parse(fs.readFileSync(path.join(root, 'proofscript.json'))),
      config([{module: 'Main', path: 'Main.ps'}]));
  });
  test('second init preserves exact files; no force/overwrite option', () => {
    const before = fs.readFileSync(path.join(root, 'Main.ps'));
    assert.notEqual(call(['--init']).status, 0);
    assert.deepEqual(fs.readFileSync(path.join(root, 'Main.ps')), before);
    assert.notEqual(call(['init', '--force']).status, 0);
  });
  test('init Lean variant and existing source refusal', () => {
    const lean = path.join(root, 'lean'); fs.mkdirSync(lean);
    assert.equal(call(['init', '--kind', 'lean'], lean).status, 0);
    assert.ok(fs.existsSync(path.join(lean, 'Main.lean')));
    const existing = path.join(root, 'existing'); fs.mkdirSync(existing);
    fs.writeFileSync(path.join(existing, 'Main.ps'), 'keep');
    assert.notEqual(call(['init'], existing).status, 0);
    assert.equal(fs.existsSync(path.join(existing, 'proofscript.json')), false);
  });
  test('showConfig captures hashes, never claims admission or creates output', () => {
    const r = call(['build', '--showConfig', '-o', 'must-not-exist']);
    assert.equal(r.status, 0, r.stderr); const d = JSON.parse(r.stdout);
    assert.equal(d.logicalAdmission, 'not-run'); assert.equal(d.publication, 'not-requested');
    assert.equal(d.files[0].bytes, 23); assert.match(d.files[0].sha256, /^[a-f0-9]{64}$/);
    assert.equal(fs.existsSync(path.join(root, 'must-not-exist')), false);
  });
  test('directory project, aliases, equals and explicit files', () => {
    assert.equal(select(['-p', '.']).project.entryModule, 'Main');
    assert.equal(select(['--project=proofscript.json']).project.sources[0].kind, 'ps');
    assert.equal(select(['--', 'Main.ps']).project.sources[0].text, 'def answer : Nat := 42\n');
    assert.throws(() => select(['Main.ps', '-p', '.']), /Choose a source file/);
    const parsed = parseCompilation(['-o', 'space out', '--engine=ts', '-p=.']);
    assert.equal(parsed.options.get('--out'), 'space out'); assert.equal(parsed.options.get('--engine'), 'ts');
  });
  test('no parent directory discovery', () => {
    const nested = path.join(root, 'nested'); fs.mkdirSync(nested);
    assert.match(call(['check'], nested).stderr, /PROJECT_MISSING/);
  });
  test('files resolve from config location, preserve order and source bytes', () => {
    fs.mkdirSync(path.join(root, 'src'));
    write('src/Other.ps', '\ufeff-- Unicode λ\r\ndef other : Nat := 1\r\n');
    write('proofscript.json', JSON.stringify(config([
      {module: 'Other', path: 'src/Other.ps'}, {module: 'Main', path: 'Main.ps'},
    ])));
    const c = select(['-p', path.join(root, 'proofscript.json')]);
    assert.deepEqual(c.project.sources.map(s => s.module), ['Other', 'Main']);
    assert.ok(c.project.sources[0].text.startsWith('\ufeff-- Unicode λ\r\n'));
  });
  test('source authority injection and unknown schema refuse', () => {
    const base = config([{module: 'Main', path: 'Main.ps'}]);
    for (const field of ['out', 'engine', 'kernel', 'checkerExecutable', 'serviceFile',
      'rustToolchainRoot', 'publicationProtocol', 'extends', 'plugins']) {
      write('bad.json', JSON.stringify({...base, [field]: 'arbitrary'}));
      assert.throws(() => select(['-p', 'bad.json']), /Invalid proofscript-project/);
    }
    write('bad.json', JSON.stringify({...base, schema: 'untrusted/2'}));
    assert.throws(() => select(['-p', 'bad.json']), /Invalid proofscript-project/);
  });
  test('absolute, traversal, backslash and drive source paths refuse', () => {
    for (const relative of ['../Main.ps', '/tmp/Main.ps', 'C:/Main.ps', 'src\\Other.ps',
      './Main.ps', 'src//Other.ps', 'src/../Main.ps']) {
      write('bad.json', JSON.stringify(config([{module: 'Main', path: relative}])));
      assert.throws(() => select(['-p', 'bad.json']), /relative to the project/);
    }
  });
  test('source and parent symlinks, project symlinks and FIFO refuse', () => {
    fs.symlinkSync(path.join(root, 'Main.ps'), path.join(root, 'Link.ps'));
    fs.symlinkSync(path.join(root, 'src'), path.join(root, 'linkdir'));
    fs.symlinkSync(path.join(root, 'proofscript.json'), path.join(root, 'link.json'));
    for (const relative of ['Link.ps', 'linkdir/Other.ps']) {
      write('bad.json', JSON.stringify(config([{module: 'Main', path: relative}])));
      assert.throws(() => select(['-p', 'bad.json']), /symlink/);
    }
    assert.throws(() => select(['-p', 'link.json']), /symlink/);
    const mk = spawnSync('mkfifo', [path.join(root, 'Pipe.ps')]); assert.equal(mk.status, 0);
    assert.throws(() => readInput(path.join(root, 'Pipe.ps')), /regular file/);
  });
  test('bounded actual reads, invalid UTF8 and BOM capture', () => {
    write('bytes', '123456789'); assert.throws(() => readInput(path.join(root, 'bytes'), 8), /regular file/);
    write('bytes', Buffer.from([0xc0, 0xaf]));
    assert.throws(() => readInput(path.join(root, 'bytes')), /encoded data/);
    write('bytes', '\ufeffhello'); assert.equal(readInput(path.join(root, 'bytes')).text, '\ufeffhello');
  });
  test('duplicates, missing entry, extra source fields and module types refuse', () => {
    const main = {module: 'Main', path: 'Main.ps'};
    for (const files of [[main, main], [{module: 'Other', path: 'Main.ps'}],
      [{...main, engine: 'rust'}], [{...main, module: ['Main']}], []]) {
      write('bad.json', JSON.stringify(config(files)));
      assert.throws(() => select(['-p', 'bad.json']));
    }
  });
  test('legacy inline project accepted without host-option authority', () => {
    const legacy = {entryModule: 'Main', sources: [{module: 'Main', kind: 'ps', text: 'def a : Nat := 1'}]};
    write('legacy.json', JSON.stringify(legacy));
    assert.deepEqual(select(['-p', 'legacy.json']).project, legacy);
    write('legacy.json', JSON.stringify({...legacy, out: 'no'}));
    assert.throws(() => select(['-p', 'legacy.json']), /Legacy projects/);
  });
  test('malformed JSON and comments refuse with useful project code', () => {
    write('bad.json', '{//comment\n}');
    const r = call(['--showConfig', '-p', 'bad.json', '--diagnostics=json']);
    assert.notEqual(r.status, 0); assert.equal(JSON.parse(r.stderr).code, 'PSC1_CLI_PROJECT_JSON');
  });
  const out = path.resolve('dist/cli'); fs.mkdirSync(out, {recursive: true});
  const receipt = {schema: 'psc1-cli-source-tests/1', testedCommit: process.env.GITHUB_SHA,
    status: 'passed', cases, noCompilerMock: true, logicalAdmission: 'not-run'};
  fs.writeFileSync(path.join(out, 'source-tests.json'), JSON.stringify(receipt, null, 2) + '\n');
  console.log('PSC1_CLI_SOURCE_TESTS: ' + JSON.stringify(receipt));
} finally {
  fs.rmSync(root, {recursive: true, force: true});
}
