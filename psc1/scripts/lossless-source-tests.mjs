import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { createLosslessSourceTool, losslessProfile, losslessLimits } from '../host-tools/source-refactoring.mjs';
import { readOwnedCompilerSources } from '../host-tools/compiler-source-inputs.mjs';
import { compilerSourceClosureDigest } from '../host-tools/compiler-host-protocol.mjs';

const hash = b => crypto.createHash('sha256').update(b).digest('hex');
const executable = path.resolve('.lake/build/bin/psc1_lossless_source');
const sha256 = hash(fs.readFileSync(executable));
const tool = createLosslessSourceTool({ executable, sha256 });
const bytes = s => Buffer.from(s);
let captures = 0, negatives = 0;
const measurements = [];
function capture(text, grammar = 'lean', module = 'Tests.Main', uri) {
  const input = typeof text === 'string' ? bytes(text) : text;
  let snapshot;
  try { snapshot = tool.capture({ bytes: input, module, grammar, uri }); }
  catch (error) {
    console.error('PSC1_LOSSLESS_CASE_REFUSED:', { module, grammar, bytes: input.length,
      sha256: hash(input), captures, expectedNegative: true });
    throw error;
  }
  captures++;
  assert.deepEqual(tool.reconstruct(snapshot), Buffer.from(input));
  assert.equal(snapshot.profile, losslessProfile);
  assert.equal(snapshot.authority.publication, false);
  assert.equal(snapshot.authority.admission, 'not-run');
  assert.equal(snapshot.metrics.timeoutMs, 240000);
  assert.equal(snapshot.sourceSha256, hash(input));
  assert.equal(snapshot.pieces.map(p => p.raw).join(''), input.toString('utf8'));
  measurements.push({ module, grammar, bytes: input.length, pieces: snapshot.pieces.length,
    status: snapshot.status, sourceId: snapshot.sourceId, sourceSha256: snapshot.sourceSha256,
    ...snapshot.metrics });
  for (const [i, p] of snapshot.pieces.entries()) {
    assert.equal(p.id, snapshot.sourceId + ':' + i);
    assert.ok(Object.isFrozen(p) && Object.isFrozen(p.span.start));
  }
  return snapshot;
}
function rejects(fn, code) {
  assert.throws(fn, code ? new RegExp('PSC1_LOSSLESS_' + code) : /PSC1_LOSSLESS_/);
  negatives++;
}
const accepted = [
  '', ' \r\n  ', '-- eof', '/- outer /- nested -/ end -/',
  '/-- doc -/def x:=1-- tail\r\n/- eof -/',
  'def α := "😀 e\u0301 /- -- \\" raw" -- comment\n',
  "def x := '\\n'\n", "def x := '😀'\n",
  'x--a\n/-b-/y', '\uFEFFdef x := 2\r\n', '-- \t \r\nx',
];
for (const grammar of ['lean', 'ps']) {
  for (const source of accepted) assert.equal(capture(source, grammar).status, 'accepted');
}
const trivia = capture('\uFEFF  /- a /- b -/ c -/-- tail\r\nx  ', 'ps');
assert.deepEqual(trivia.pieces.map(p => p.kind),
  ['byteOrderMark', 'whitespace', 'blockComment', 'lineComment', 'whitespace', 'token', 'whitespace', 'token']);
assert.deepEqual(trivia.pieces[0].span.stop, { byteOffset: 3, line: 1, column: 1 });
assert.equal(capture('\uFEFFx', 'lean').pieces[0].kind, 'token');
const astral = capture('α😀\r\nx');
assert.deepEqual(astral.pieces.at(-1).span.stop, { byteOffset: 9, line: 2, column: 2 });
for (const grammar of ['lean', 'ps']) {
  for (const [source, code] of [
    ['/- unfinished', 'unterminatedBlockComment'], ['"unfinished', 'unterminatedString'],
    ['"line\n', 'newlineInString'], ["'x", 'unterminatedCharacter'],
  ]) {
    const snapshot = capture(source, grammar);
    assert.equal(snapshot.status, 'lexically-refused');
    assert.equal(snapshot.diagnostic.code, code);
    assert.deepEqual(snapshot.pieces.map(p => p.kind), ['unlexed']);
  }
}
for (const source of ['\tx', 'x\r', 'x\uFEFF']) {
  assert.equal(capture(source, 'ps').status, 'lexically-refused');
  assert.equal(capture(source, 'lean').status, 'accepted');
}
const original = bytes('-- keep\r\ndef α := 1 -- 😀\r\n');
const snapshot = capture(original, 'lean', 'A.Module', '/first/location.lean');
const again = capture(original, 'lean', 'A.Module', '/other/location.lean');
assert.equal(snapshot.sourceId, again.sourceId);
assert.deepEqual(snapshot.pieces.map(p => p.id), again.pieces.map(p => p.id));
assert.notEqual(snapshot.sourceId, capture(original, 'ps', 'A.Module').sourceId);
assert.notEqual(snapshot.sourceId, capture(original, 'lean', 'B.Module').sourceId);
assert.notEqual(snapshot.sourceId, capture(Buffer.concat([original, bytes('\n')]), 'lean', 'A.Module').sourceId);
assert.throws(() => { snapshot.pieces[0].raw = 'changed'; }, TypeError);
const before = Buffer.from(original);
original.fill(0);
assert.deepEqual(tool.reconstruct(snapshot), before);
const copy = tool.reconstruct(snapshot); copy.fill(0);
assert.deepEqual(tool.reconstruct(snapshot), before);
const digit = before.indexOf(bytes('1'));
const edit = [{ startByte: digit, endByte: digit + 1, replacement: bytes('42') }];
const candidate = tool.stageTextEdits(snapshot, before, edit);
assert.deepEqual(candidate.bytes, Buffer.concat([before.subarray(0, digit), bytes('42'), before.subarray(digit + 1)]));
assert.equal(candidate.publicationAuthority, false);
assert.equal(candidate.semanticEquivalence, 'not-claimed');
assert.equal(candidate.admission, 'not-run');
candidate.bytes.fill(0);
assert.deepEqual(tool.reconstruct(snapshot), before);
assert.deepEqual(tool.stageTextEdits(snapshot, before, []).bytes, before);
rejects(() => tool.stageTextEdits(snapshot, Buffer.concat([before, bytes(' ')]), []), 'STALE_SNAPSHOT');
rejects(() => tool.reconstruct({ ...snapshot }), 'SNAPSHOT');
const other = createLosslessSourceTool({ executable, sha256 });
rejects(() => other.stageTextEdits(snapshot, before, []), 'SNAPSHOT');
const alpha = before.indexOf(bytes('α'));
for (const edits of [
  [{ startByte: alpha + 1, endByte: alpha + 2, replacement: bytes('x') }],
  [{ startByte: 3, endByte: 1, replacement: bytes('x') }],
  [{ startByte: -1, endByte: 0, replacement: bytes('x') }],
  [{ startByte: 0.5, endByte: 1, replacement: bytes('x') }],
  [{ startByte: 0, endByte: 5, replacement: bytes('') }, { startByte: 4, endByte: 6, replacement: bytes('') }],
  [{ startByte: 2, endByte: 2, replacement: bytes('') }, { startByte: 1, endByte: 1, replacement: bytes('') }],
  [{ startByte: 2, endByte: 2, replacement: bytes('a') }, { startByte: 2, endByte: 2, replacement: bytes('b') }],
  [{ startByte: 0, endByte: 0, replacement: Buffer.from([0xff]) }],
  [{ startByte: 0, endByte: 0, replacement: bytes('x'), tool: executable }],
]) rejects(() => tool.stageTextEdits(snapshot, before, edits));
const adjacent = tool.stageTextEdits(snapshot, before, [
  { startByte: 0, endByte: 1, replacement: bytes('a') },
  { startByte: 1, endByte: 2, replacement: bytes('b') },
]);
assert.deepEqual(adjacent.bytes, Buffer.concat([bytes('ab'), before.subarray(2)]));
for (const bad of [[0xff], [0xc0, 0xaf], [0xe2, 0x82], [0xed, 0xa0, 0x80]]) {
  rejects(() => capture(Buffer.from(bad)), 'UTF8');
}
rejects(() => capture(Buffer.alloc(losslessLimits.sourceBytes + 1)), 'BYTES_OR_LIMIT');
rejects(() => tool.capture({ module: '\ud800', grammar: 'lean', bytes: bytes('') }), 'IDENTITY');
rejects(() => tool.capture({ module: 'A', grammar: 'other', bytes: bytes('') }), 'IDENTITY');
rejects(() => tool.capture({ module: 'A\0B', grammar: 'lean', bytes: bytes('') }), 'IDENTITY');
rejects(() => createLosslessSourceTool({ executable, sha256: '0'.repeat(64) }), 'TOOL_IDENTITY');

// Trusted, host-selected test executables exercise every wire boundary. They
// are never chosen by source text; the real helper supplies the baseline tape.
const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'psc1-lossless-negative-'));
try {
  const base = capture('def x := 1\n');
  const wire = {
    protocol: base.protocol, grammar: base.grammar, status: base.status,
    byteLength: base.byteLength,
    pieces: base.pieces.map(({ id, ...piece }) => piece),
    tokens: base.pieces.filter(p => p.token).map(p => p.token), diagnostic: base.diagnostic,
  };
  const malformed = [
    w => { w.extra = true; }, w => { w.protocol = 'untrusted'; },
    w => { w.byteLength++; }, w => { w.pieces[0].raw = 'bad'; },
    w => { w.pieces[0].span.stop.column++; }, w => { w.pieces[0].ordinal++; },
    w => { w.pieces.splice(1, 1); }, w => { w.tokens[0].text = 'false'; },
    w => { w.tokens.pop(); }, w => { w.pieces.at(-1).token.kind = 'symbol'; },
    w => { w.pieces[1].kind = 'other'; }, w => { w.pieces[1].token = w.tokens[0]; },
    w => { w.status = 'lexically-refused'; }, w => { w.diagnostic = { code: 'approved' }; },
    w => { w.pieces[1].kind = 'lineComment'; },
  ];
  let i = 0;
  for (const mutate of malformed) {
    const bad = structuredClone(wire); mutate(bad);
    const file = path.join(directory, 'helper-' + i++);
    fs.writeFileSync(file, '#!/usr/bin/python3\nimport json,sys\nwire=json.loads(' +
      JSON.stringify(JSON.stringify(bad)) + ')\nopen(sys.argv[3],"w").write(json.dumps(wire))\n', { mode: 0o700 });
    const fake = createLosslessSourceTool({ executable: file, sha256: hash(fs.readFileSync(file)) });
    rejects(() => fake.capture({ module: 'Bad', grammar: 'lean', bytes: bytes('def x := 1\n') }));
  }
  const tamper = path.join(directory, 'tamper');
  fs.writeFileSync(tamper, '#!/usr/bin/python3\nimport sys\nopen(sys.argv[0],"a").write("# changed")\n',
    { mode: 0o700 });
  const fake = createLosslessSourceTool({ executable: tamper, sha256: hash(fs.readFileSync(tamper)) });
  rejects(() => fake.capture({ module: 'Bad', grammar: 'lean', bytes: bytes('') }), 'TOOL_IDENTITY');
  const link = path.join(directory, 'symlink'); fs.symlinkSync(executable, link);
  rejects(() => createLosslessSourceTool({ executable: link, sha256 }), 'FILE');
} finally { fs.rmSync(directory, { recursive: true, force: true }); }

// Scope guard: only the additive sidecar and host tooling can change production
// input. Frozen packages and the unified compiler closure remain byte-identical.
const sources = readOwnedCompilerSources('Ps.CompilerUnified.Service');
const closure = compilerSourceClosureDigest(sources.map(s => ({ ...s, kind: 'lean' })));
if (process.env.PSC1_LOSSLESS_SCOPE_GUARD === 'true') {
assert.equal(sources.length, 121);
assert.equal(closure, '7a49ccbd8b11d029e54fa0d78da9e8fe66943193cc73d00c29b4ed392126a000');
const baseline = 'd7e845b35e6c5cc80ffafe2f6f41fc475bf3842c';
const diff = spawnSync('git', ['diff', '--name-only', baseline, 'HEAD', '--', 'packages', 'host', 'lean-toolchain'],
  { encoding: 'utf8' });
assert.equal(diff.status, 0);
assert.deepEqual(diff.stdout.trim().split('\n').filter(Boolean),
  ['psc1/packages/syntax/src/Ps/Syntax/Lossless.lean']);
}
for (const row of sources) {
  for (const grammar of ['lean', 'ps']) assert.equal(capture(row.text, grammar, row.module).status, 'accepted');
}
rejects(() => capture('x '.repeat(131072)), 'PROCESS');
for (const grammar of ['lean', 'ps']) {
  assert.equal(capture('/- ' + '😀 /- nested -/ '.repeat(8192) + '-/\r\nx', grammar).status, 'accepted');
  assert.equal(capture(('x /- c -/ \n').repeat(4096), grammar).status, 'accepted');
}
fs.mkdirSync('dist/lossless', { recursive: true });
const receipt = {
  schema: 'psc1-lossless-qualification/1', commit: process.env.GITHUB_SHA ?? null,
  runtime: process.version, profile: losslessProfile, limits: losslessLimits,
  helperSha256: sha256, captures, negativeCases: negatives,
  sourceClosure: { modules: sources.length, sha256: closure },
  scope: 'lexical capture and staged byte edits only', admission: 'not-run',
  semanticEquivalence: 'not-claimed', publicationAuthority: false, measurements,
};
fs.writeFileSync('dist/lossless/qualification.json', JSON.stringify(receipt, null, 2) + '\n');
console.log('PSC1_LOSSLESS_SOURCE_TESTS: PASS ' + JSON.stringify({
  captures, negativeCases: negatives, modules: sources.length, closure,
  maxElapsedMs: Math.max(...measurements.map(m => m.elapsedMs)),
  maxRssKiB: Math.max(...measurements.map(m => m.maxRssKiB)),
}));
