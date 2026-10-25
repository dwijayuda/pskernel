import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';
import { createLosslessSourceTool, createSourceOwnershipTool,
  createCheckedSourceConverter } from '../host-tools/source-refactoring.mjs';
import { compilerSourceClosureDigest } from '../host-tools/compiler-host-protocol.mjs';
import { readOwnedCompilerSources } from '../host-tools/compiler-source-inputs.mjs';
import { boundedRun } from '../host-tools/generated-target-tools.mjs';

const focused = process.argv.includes('--focused'), fullOnly = process.argv.includes('--full-only');
assert.ok(process.argv.length === 2 || (process.argv.length === 3 && (focused || fullOnly)));
const root = process.cwd(), work = fs.mkdtempSync(path.join(os.tmpdir(), 'psc1-convert-tests-'));
const hash = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const toolPath = name => path.resolve('.lake/build/bin/' + name);
const executable = toolPath('psc1_source_ownership');
const checkerExecutable = toolPath('psc1_independent_checker');
const lexicalExecutable = toolPath('psc1_lossless_source');
const lexical = createLosslessSourceTool({
  executable: lexicalExecutable, sha256: hash(fs.readFileSync(lexicalExecutable)),
});
const configuration = {
  lexicalTool: lexical, executable, sha256: hash(fs.readFileSync(executable)),
  checkerExecutable, checkerSha256: hash(fs.readFileSync(checkerExecutable)),
};
const ownership = createSourceOwnershipTool(configuration);
const converter = createCheckedSourceConverter({ ownershipTool: ownership });
const records = [];
let negatives = 0;
const capture = (text, module = 'Test.Main', grammar = 'lean') =>
  lexical.capture({ module, grammar, bytes: Buffer.from(text) });
const comments = snapshot => snapshot.pieces.filter(p =>
  ['lineComment', 'blockComment'].includes(p.kind)).map(p => [p.kind, p.raw]);
function refuse(fn, code = 'CONVERSION_') {
  assert.throws(fn, new RegExp('PSC1_LOSSLESS_' + code)); negatives++;
}
function convert(index, snapshots, targetGrammar, commentPolicy = 'preserve', tool = converter) {
  console.log('PSC1_CONVERSION_STARTED:', { from: index.grammar, targetGrammar,
    modules: snapshots.length, commentPolicy });
  const report = tool.convert({ index, snapshots, targetGrammar, commentPolicy });
  assert.equal(report.admissionsSha256, index.admissionsSha256);
  assert.equal(report.originalIrSha256, index.originalIrSha256);
  assert.equal(report.authority.sourceFilesWritten, false);
  assert.equal(report.authority.publication, false);
  assert.equal(report.authority.rename, false);
  assert.equal(tool.assertCurrent(report, snapshots), true);
  const candidateSnapshots = tool.candidateSnapshots(report);
  for (let i = 0; i < snapshots.length; i++) {
    assert.deepEqual(comments(candidateSnapshots[i]), comments(snapshots[i]));
    assert.equal(candidateSnapshots[i].grammar, targetGrammar);
    assert.equal(candidateSnapshots[i].status, 'accepted');
    const bytes = tool.readCandidate(report, snapshots[i].module), before = Buffer.from(bytes);
    bytes.fill(0);
    assert.deepEqual(tool.readCandidate(report, snapshots[i].module), before);
    assert.equal(report.originMap[i].from, snapshots[i].sourceId);
    assert.equal(report.originMap[i].to, candidateSnapshots[i].sourceId);
  }
  assert.ok(Object.isFrozen(report.originMap[0]));
  assert.ok(Object.isFrozen(candidateSnapshots));
  records.push({ id: report.id, sourceGrammar: report.sourceGrammar, targetGrammar,
    modules: snapshots.length, elapsedMs: report.elapsedMs,
    admissionsSha256: report.admissionsSha256, originalIrSha256: report.originalIrSha256 });
  return { report, snapshots: candidateSnapshots, index: tool.candidateIndex(report) };
}
function run(command, args, options = {}) {
  const result = boundedRun(command, args, { timeoutMs: 240000, timeoutPolicy: 'standard-240s', ...options });
  assert.equal(result.error, null, result.stderr);
  assert.equal(result.status, 0, result.stdout + result.stderr);
  return result;
}
function fixtureOwnership(name, change) {
  const helper = path.join(work, name);
  fs.writeFileSync(helper, '#!/usr/bin/python3\nimport sys,subprocess,json\n' +
    'code=subprocess.run([' + JSON.stringify(executable) + ']+sys.argv[1:]).returncode\n' +
    'if code: sys.exit(code)\n' +
    'if sys.argv[1] in ["to-lean","to-ps"]:\n' +
    '  value=json.load(open(sys.argv[3]))\n' + change + '\n' +
    '  json.dump(value,open(sys.argv[3],"w"),ensure_ascii=False)\n', { mode: 0o700 });
  const fixture = createSourceOwnershipTool({ ...configuration,
    executable: helper, sha256: hash(fs.readFileSync(helper)) });
  return { ownership: fixture, converter: createCheckedSourceConverter({ ownershipTool: fixture }) };
}
try {
  if (!fullOnly) {
  const base = capture('-- license\r\ndef seed : Nat := 7\n', 'Test.Seed');
  const main = capture('import Test.Seed\nnamespace Model\n/- Unicode 😀 /- nested -/ -/\n' +
    'def choose (seed : Nat) : Nat := let seed : Nat := Nat.add seed 1; seed\n' +
    '-- keep next\n' +
    'def answer : Nat := choose seed\nend Model\n-- eof', 'Test.Main');
  const before = [base, main], index = ownership.analyze({ snapshots: before, entry: 'Test.Main' });
  const ps = convert(index, before, 'ps');
  const restored = convert(ps.index, ps.snapshots, 'lean');
  assert.equal(restored.index.admissionsSha256, index.admissionsSha256);
  assert.ok(converter.readCandidate(ps.report, 'Test.Main').toString('utf8').includes('namespace Model'));
  refuse(() => converter.readCandidate({ ...ps.report }, 'Test.Main'), 'CONVERSION_REPORT');
  refuse(() => converter.readCandidate(ps.report, 'Absent'), 'CONVERSION_MODULE');
  refuse(() => converter.assertCurrent(ps.report, [main, base]), 'OWNERSHIP_STALE');
  refuse(() => converter.convert({ index: { ...index }, snapshots: before, targetGrammar: 'ps' }), 'OWNERSHIP_INDEX');
  refuse(() => converter.convert({ index, snapshots: before, targetGrammar: 'python' }), 'CONVERSION_REQUEST');
  refuse(() => converter.convert({ index, snapshots: before, targetGrammar: 'ps', commentPolicy: 'discard' }),
    'CONVERSION_REQUEST');
  refuse(() => createCheckedSourceConverter({ ownershipTool: { ...ownership } }), 'CONVERSION_OWNERSHIP_TOOL');

  const inside = capture('def increment (value : Nat) : Nat :=\n' +
    '  /- body note 😀 -/\n  Nat.add value 1\n');
  const insideIndex = ownership.analyze({ snapshots: [inside], entry: 'Test.Main' });
  refuse(() => converter.convert({ index: insideIndex, snapshots: [inside], targetGrammar: 'ps' }),
    'CONVERSION_INNER_COMMENT');
  const notes = convert(insideIndex, [inside], 'ps', 'owner-notes');
  assert.ok(converter.readCandidate(notes.report, 'Test.Main').toString('utf8').startsWith('/- body note'));

  const data = capture('namespace Data\ninductive Flag where\n  | off\n  | on\n' +
    'structure Box where\n  value : Nat\nend Data\n');
  const dataIndex = ownership.analyze({ snapshots: [data], entry: 'Test.Main' });
  const dataPs = convert(dataIndex, [data], 'ps');
  convert(dataPs.index, dataPs.snapshots, 'lean');
  const normalized = capture('namespace Math\ndef accumulate (n : Nat) (acc : Nat) : Nat := match n with\n' +
    '  | Nat.zero => acc\n  | Nat.succ k => accumulate k (Nat.succ acc)\nend Math\n');
  const normalizedIndex = ownership.analyze({ snapshots: [normalized], entry: 'Test.Main' });
  const normalizedPs = convert(normalizedIndex, [normalized], 'ps');
  convert(normalizedPs.index, normalizedPs.snapshots, 'lean');
  const ordinary = capture('partial def count (n : Nat) : Nat :=\n' +
    '  if Nat.beq n 0 then 0 else Nat.succ (count (Nat.sub n 1))\n');
  const ordinaryIndex = ownership.analyze({
    snapshots: [ordinary], entry: 'Test.Main', assurance: 'ordinary-checked',
  });
  const ordinaryPs = convert(ordinaryIndex, [ordinary], 'ps');
  assert.deepEqual(ordinaryPs.index.partialNames, ordinaryIndex.partialNames);
  convert(ordinaryPs.index, ordinaryPs.snapshots, 'lean');
  const text = capture('def text : String := "😀 /- literal -- not trivia"\n');
  const textIndex = ownership.analyze({ snapshots: [text], entry: 'Test.Main' });
  convert(textIndex, [text], 'ps');

  // A real independently accepted alternate graph must still fail correspondence.
  const alternate = fixtureOwnership('different-body',
    '  value["modules"][0]["text"]=value["modules"][0]["text"].replace("41","42")');
  const constant = capture('def value : Nat := 41\n');
  const constantIndex = alternate.ownership.analyze({ snapshots: [constant], entry: 'Test.Main' });
  refuse(() => alternate.converter.convert({
    index: constantIndex, snapshots: [constant], targetGrammar: 'ps',
  }), 'CONVERSION_CORRESPONDENCE');
  const wrongIdentity = fixtureOwnership('wrong-identity', '  value["requestId"]="wrong"');
  const wrongIndex = wrongIdentity.ownership.analyze({ snapshots: [constant], entry: 'Test.Main' });
  refuse(() => wrongIdentity.converter.convert({
    index: wrongIndex, snapshots: [constant], targetGrammar: 'ps',
  }), 'CONVERSION_RESPONSE');

  // Developer CLI works outside the repository cwd and emits only candidate JSON.
  const manifest = {
    schema: 'psc1-source-tools/1',
    lexical: { path: lexicalExecutable, sha256: hash(fs.readFileSync(lexicalExecutable)) },
    ownership: { path: executable, sha256: configuration.sha256 },
    checker: { path: checkerExecutable, sha256: configuration.checkerSha256 },
  };
  const manifestPath = path.join(work, 'tools.json'), sourcePath = path.join(work, 'Main.lean');
  fs.writeFileSync(manifestPath, JSON.stringify(manifest));
  fs.writeFileSync(sourcePath, lexical.reconstruct(constant));
  const originalSha = hash(fs.readFileSync(sourcePath)), cli = path.resolve('scripts/refactor-source.mjs');
  const cliResult = run(process.execPath, [cli, '--manifest', manifestPath,
    '--entry', 'Test.Main', '--grammar', 'lean', '--to', 'ps', '--source', 'Test.Main=' + sourcePath],
    { cwd: work });
  const cliWire = JSON.parse(cliResult.stdout);
  assert.equal(cliWire.schema, 'psc1-source-conversion-candidate/1');
  assert.equal(cliWire.report.authority.publication, false);
  assert.equal(hash(fs.readFileSync(sourcePath)), originalSha);
  assert.match(cliWire.modules[0].text, /41/);
  assert.match(run(process.execPath, [cli, '--help'], { cwd: work }).stdout, /usage:/);
  const badCli = boundedRun(process.execPath, [cli, '--manifest', manifestPath,
    '--entry', 'Test.Main', '--grammar', 'lean', '--to', 'ps',
    '--source', 'Wrong=' + sourcePath], { cwd: work, timeoutMs: 240000, timeoutPolicy: 'standard-240s' });
  assert.notEqual(badCli.status, 0); negatives++;
  assert.equal(badCli.stdout, '');
  assert.equal(hash(fs.readFileSync(sourcePath)), originalSha);

  }
  if (!focused) {
    // Real CLI/JSON/file application, from a trusted authored fixture closure.
    const application = [], seen = new Set();
    function visit(module) {
      if (seen.has(module)) return;
      const relative = module.replaceAll('.', '/') + '.lean';
      const candidates = [path.join('test/applications', relative), path.join('stdlib', relative)];
      const file = candidates.find(p => fs.existsSync(p));
      assert.ok(file, 'authored fixture module ' + module);
      const source = fs.readFileSync(file, 'utf8');
      for (const match of source.matchAll(/^import\s+(.+)$/gm))
        for (const dependency of match[1].trim().split(/\s+/)) visit(dependency);
      seen.add(module);
      application.push(capture(source, module));
    }
    visit('PracticalCli.Run');
    const applicationIndex = ownership.analyze({
      snapshots: application, entry: 'PracticalCli.Run', assurance: 'ordinary-checked',
    });
    const converted = convert(applicationIndex, application, 'ps', 'owner-notes');
    const folder = path.join(work, 'application'), sourceRoot = path.join(folder, 'source');
    fs.mkdirSync(sourceRoot, { recursive: true });
    fs.writeFileSync(path.join(folder, 'package.json'), '{"type":"module"}\n');
    for (const source of application) {
      const file = path.join(sourceRoot, source.module.replaceAll('.', '/') + '.ps');
      fs.mkdirSync(path.dirname(file), { recursive: true });
      fs.writeFileSync(file, converter.readCandidate(converted.report, source.module));
    }
    const entryFile = path.join(sourceRoot, 'Run.ps');
    fs.writeFileSync(entryFile, converter.readCandidate(converted.report, 'PracticalCli.Run'));
    const output = path.join(folder, 'application.js');
    run(toolPath('psc1'), ['build', entryFile, '--target', 'js',
      '--assurance', 'ordinary', '--abi', 'io-dispatcher', '--out', output],
      { env: { ...process.env, PSC1_HOST_TOOLS: path.join(root, 'host-tools/artifacts.mjs') } });
    const config = path.join(folder, 'io.json');
    fs.writeFileSync(config, JSON.stringify({
      abi: 'psc1-node-linux-string-io/1', capabilities: ['readUtf8', 'writeUtf8', 'writeLine'],
      required: ['readUtf8', 'writeUtf8', 'writeLine'], root: folder,
      maxFileBytes: 512, maxLineBytes: 128, inputFd: 0, outputFd: 1,
    }));
    fs.writeFileSync(path.join(folder, 'input.json'), '[{"text":"A","count":2}]');
    fs.writeFileSync(path.join(folder, 'output.json'), 'previous');
    const result = run(process.execPath, [path.join(root, 'scripts/practical-application-node.mjs'),
      'js', output, config, 'transform', 'input.json', 'output.json']);
    assert.equal(result.stdout, 'ok\n');
    assert.equal(fs.readFileSync(path.join(folder, 'output.json'), 'utf8'), '[{"count":2,"text":"processed:A"}]');
    console.log('PSC1_CONVERSION_APPLICATION:', JSON.stringify({
      modules: application.length, nativeCompilation: 'passed', actualFileIO: 'passed',
      admissionsSha256: converted.index.admissionsSha256,
    }));

    const owned = readOwnedCompilerSources('Ps.CompilerUnified.Service');
    if (process.env.PSC1_CONVERSION_SCOPE_GUARD === 'true') {
      assert.equal(owned.length, 121);
      assert.equal(compilerSourceClosureDigest(owned.map(row => ({ ...row, kind: 'lean' }))),
        '60dd756e29cf6fbd44386e342318c53b22f41f2f3beb21b05aa39505a366271a');
    }
    const snapshots = owned.map(row => capture(row.text, row.module));
    const sourceIndex = ownership.analyze({
      snapshots, entry: 'Ps.CompilerUnified.Service', assurance: 'ordinary-checked',
    });
    const convertedCompiler = convert(sourceIndex, snapshots, 'ps', 'owner-notes');
    const restoredCompiler = convert(convertedCompiler.index, convertedCompiler.snapshots, 'lean', 'owner-notes');
    assert.equal(restoredCompiler.index.admissionsSha256, sourceIndex.admissionsSha256);
    console.log('PSC1_CONVERSION_COMPILER:', JSON.stringify({
      modules: owned.length, members: sourceIndex.sourceCoreDeclarations,
      forwardMs: convertedCompiler.report.elapsedMs, reverseMs: restoredCompiler.report.elapsedMs,
      exactAdmissionAndIr: true, rawCommentsRetained: true,
    }));
  }
  fs.mkdirSync('dist/source-conversion', { recursive: true });
  fs.writeFileSync('dist/source-conversion/qualification-' + (focused ? 'focused' : fullOnly ? 'full' : 'all') + '.json', JSON.stringify({
    schema: 'psc1-source-conversion-tests/1', status: 'passed', focused,
    implementation: process.env.GITHUB_SHA ?? null, helperSha256: configuration.sha256,
    checkerSha256: configuration.checkerSha256, negativeCases: negatives, records,
    relation: 'identical canonical admission, strict IR, partial names and source member ownership',
    authority: { candidateOnly: true, publication: false, formalCompilerPreservation: false },
  }, null, 2) + '\n');
  console.log('PSC1_SOURCE_CONVERSION: PASS', JSON.stringify({ focused, cases: records.length, negatives }));
} finally { fs.rmSync(work, { recursive: true, force: true }); }
