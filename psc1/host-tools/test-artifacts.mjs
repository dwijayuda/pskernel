// These publication tests exercise I/O with artificial metadata, not logical
// proof admission. The independent native provider has its own separate tests.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { TraceMap, originalPositionFor } from '@jridgewell/trace-mapping';
import { formatEcma, exportedNames, sourceMap, vlq, scalarWitApi, createStage, publish } from './artifacts.mjs';

let passed = 0;
async function test(name, action) {
  await action();
  passed++;
  console.log(`PSC1_HOST_TEST_PASS: ${name}`);
}

await test('formatting preserves JS literals, operators and exports', async () => {
  const input = 'const hidden="export function x(){ return 3; } 🌍"; export function identity(x){return x===hidden?x:`value:${x}`;}';
  const result = await formatEcma(input, 'js');
  assert.deepEqual(exportedNames(result.program), ['identity']);
  assert.match(result.text, /\n/);
  assert.equal((await formatEcma(result.text, 'js')).text, result.text);
});
await test('formatting preserves nested constructor keys and computed field semantics', async () => {
  const input = `export function answer(flag) {
    const inner = ({ "$ps$tag": "ok", "$ps$fields": { ["value"]: flag, ["__proto__"]: false } });
    const outer = ({ "$ps$tag": "ok", "$ps$fields": { ["item"]: inner } });
    const fields = outer["$ps$fields"]["item"]["$ps$fields"];
    if (outer["$ps$tag"] !== "ok" || inner["$ps$tag"] !== "ok" ||
        !Object.prototype.hasOwnProperty.call(fields, "__proto__") ||
        fields["__proto__"] !== false || Object.getPrototypeOf(fields) !== Object.prototype) {
      throw new Error("PSC1_TAGGED_FORMAT_FIELD_SEMANTICS_CHANGED");
    }
    return fields["value"];
  }`;
  const result = await formatEcma(input, 'js');
  assert.deepEqual(exportedNames(result.program), ['answer']);
  const formattedModule = await import('data:text/javascript,' + encodeURIComponent(result.text));
  assert.equal(formattedModule.answer(false), false);
  assert.equal(formattedModule.answer(true), true);
  assert.equal((await formatEcma(result.text, 'js')).text, result.text);
});
await test('formatting preserves TS declarations and types', async () => {
  const input = 'export declare function identity(x: bigint):bigint;';
  const result = await formatEcma(input, 'ts');
  assert.deepEqual(exportedNames(result.program), ['identity']);
});
await test('negative source-map VLQ values', () => {
  assert.equal(vlq(-1), 'D');
  assert.equal(vlq(-10), 'V');
  assert.equal(vlq(-2147483648), 'B');
  assert.throws(() => vlq(2147483648), /DELTA_RANGE/);
});
await test('independent source-map reader resolves final formatted multi-file origins and gaps', async () => {
  const result = await formatEcma('function generated(){return 0;} function dep(x){return x;} export function entry(x){return dep(x);}', 'js');
  const info = { entryPath: '/project/Main.lean', sources: [
    { path: '/project/Dep.lean', text: '\n\n/- 🌍 -/ def dep (x : Bool) : Bool := x\n', origins: [{ name: 'dep', line: 2, column: 9 }] },
    { path: '/project/Main.lean', text: 'import Dep\ndef entry (x : Bool) : Bool := dep x\n', origins: [{ name: 'entry', line: 1, column: 0 }] }
  ] };
  const map = new TraceMap(sourceMap(result.program, info, 'module.js'));
  const statements = result.program.body;
  const at = statement => originalPositionFor(map, { line: statement.loc.start.line, column: statement.loc.start.column });
  assert.equal(at(statements[0]).source, null);
  assert.deepEqual(at(statements[1]), { source: 'Dep.lean', line: 3, column: 9, name: null });
  assert.deepEqual(at(statements[2]), { source: 'Main.lean', line: 2, column: 0, name: null });
  assert.equal(originalPositionFor(map, { line: statements[1].loc.end.line, column: statements[1].loc.end.column }).source, null);
});
await test('WIT comparison is structural, complete and trivia-independent', () => {
  const first = 'package proofscript:psc1; world app { export identity: func(x: u64) -> u64; }';
  const second = '// observed\npackage root:component;\nworld root {\nexport identity : func( x : u64 ) -> u64;\n}\n';
  assert.deepEqual(scalarWitApi(first), scalarWitApi(second));
  assert.notDeepEqual(scalarWitApi(first), scalarWitApi(first.replace('x: u64', 'x: u32')));
  assert.throws(() => scalarWitApi(first.replace('export identity', 'import identity')), /WIT_SYNTAX/);
  assert.throws(() => scalarWitApi(first.replace(' }', ' export identity: func(x: u64) -> u64; }')), /DUPLICATE_EXPORT/);
  assert.throws(() => scalarWitApi(first + ' world extra {}'), /TRAILING_SYNTAX/);
  assert.throws(() => scalarWitApi(first.replace('identity:', 'identity-:')), /UNRECOGNIZED_TOKEN/);
});

const root = fs.mkdtempSync(path.join(os.tmpdir(), 'psc1-publication-unit-'));
function stageFor(output, literal) {
  const stage = createStage(output);
  const name = path.basename(output);
  const info = { profile: 'psc1-checked-direct/1', leanVersion: '4.35.0', leanCommit: 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc', entryPath: path.join(root, 'input.lean'),
    publicNames: ['answer'], sources: [{ path: path.join(root, 'input.lean'), text: `def answer : Bool := ${literal}\n`, origins: [] }] };
  fs.writeFileSync(path.join(stage, 'psc1-input.json'), JSON.stringify(info));
  fs.writeFileSync(path.join(stage, 'admissions.json'), '["artificial-I/O-test-metadata-not-a-proof"]\n');
  fs.writeFileSync(path.join(stage, name), `export const answer = ${literal};\n`);
  fs.writeFileSync(path.join(stage, name + '.map'), '{}\n');
  fs.writeFileSync(path.join(stage, name.replace(/\.js$/, '.d.ts')), 'export declare const answer: boolean;\n');
  return stage;
}
try {
  const output = path.join(root, 'module.js');
  let accepted;
  await test('complete first publication and checksummed inventory', () => {
    accepted = publish(stageFor(output, 'true'), output, 'js');
    assert.match(fs.readFileSync(output, 'utf8'), /true/);
    const manifest = JSON.parse(fs.readFileSync(output + '.bundle.json', 'utf8'));
    assert.equal(manifest.files.length, 5);
    assert.equal(fs.realpathSync(output), path.join(accepted.bundle, 'module.js'));
  });
  for (const phase of ['before-seal', 'after-seal', 'after-aliases', 'before-commit']) {
    await test(`failure at ${phase} leaves the prior generation untouched`, () => {
      const before = fs.realpathSync(output);
      process.env.PSC1_TEST_PUBLICATION_FAIL_AT = phase;
      try { assert.throws(() => publish(stageFor(output, 'false'), output, 'js'), /INJECTED_PUBLICATION_FAILURE/); }
      finally { delete process.env.PSC1_TEST_PUBLICATION_FAIL_AT; }
      assert.equal(fs.realpathSync(output), before);
      assert.match(fs.readFileSync(output, 'utf8'), /true/);
    });
  }
  await test('successful replacement preserves old immutable generation for pinned readers', () => {
    const old = fs.realpathSync(output);
    publish(stageFor(output, 'false'), output, 'js');
    assert.match(fs.readFileSync(output, 'utf8'), /false/);
    assert.match(fs.readFileSync(old, 'utf8'), /true/);
  });
  await test('repeat publication is content-addressed and stale stages do not block', () => {
    createStage(output);
    const a = publish(stageFor(output, 'false'), output, 'js');
    const b = publish(stageFor(output, 'false'), output, 'js');
    assert.equal(a.generation, b.generation);
  });
  await test('existing ordinary user output is never overwritten', () => {
    const ordinary = path.join(root, 'ordinary.js');
    fs.writeFileSync(ordinary, 'user-owned');
    assert.throws(() => publish(stageFor(ordinary, 'true'), ordinary, 'js'), /OUTPUT_NOT_MANAGED/);
    assert.equal(fs.readFileSync(ordinary, 'utf8'), 'user-owned');
  });
  await test('missing output and symlink payloads fail closed', () => {
    const missing = stageFor(path.join(root, 'missing.js'), 'true');
    fs.unlinkSync(path.join(missing, 'missing.js.map'));
    assert.throws(() => publish(missing, path.join(root, 'missing.js'), 'js'), /INVENTORY_MISMATCH/);
    const link = stageFor(path.join(root, 'linked.js'), 'true');
    fs.unlinkSync(path.join(link, 'linked.js.map'));
    fs.symlinkSync('/dev/null', path.join(link, 'linked.js.map'));
    assert.throws(() => publish(link, path.join(root, 'linked.js'), 'js'), /SYMLINK_REJECTED/);
  });
} finally {
  delete process.env.PSC1_TEST_PUBLICATION_FAIL_AT;
  fs.rmSync(root, { recursive: true, force: true });
}
console.log(`PSC1_HOST_TESTS: ${passed} passed`);
