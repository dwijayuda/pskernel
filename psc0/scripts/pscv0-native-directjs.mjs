// Independent consumer of final JS, declarations and ECMA-426 mappings.
// No compiler implementation is imported by these checks.
import assert from 'node:assert/strict';
import {readFile, writeFile, mkdir, copyFile} from 'node:fs/promises';
import path from 'node:path';
const root = path.resolve(process.argv[2]);
const read = name => readFile(path.join(root, name), 'utf8');
const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
function decode(text) {
  const values = [];
  let value = 0, shift = 0;
  for (const char of text) {
    const digit = alphabet.indexOf(char);
    assert(digit >= 0, 'invalid base64 digit');
    value += (digit & 31) * 2 ** shift;
    if (digit & 32) { shift += 5; assert(shift < 53); }
    else {
      values.push((value & 1 ? -1 : 1) * Math.floor(value / 2));
      value = 0; shift = 0;
    }
  }
  assert.equal(shift, 0, 'unfinished VLQ');
  return values;
}
function mappings(map, generated) {
  assert.equal(map.version, 3);
  const lines = generated.split('\n'), input = map.sourcesContent.map(s => s.split('\n'));
  let source = 0, originalLine = 0, originalColumn = 0, name = 0;
  return map.mappings.split(';').map((line, row) => {
    let column = 0;
    assert(row < lines.length);
    return line === '' ? [] : line.split(',').map(segment => {
      const delta = decode(segment);
      assert([1,4,5].includes(delta.length), 'invalid segment shape');
      assert(delta[0] >= 0, 'out of order generated position');
      column += delta[0];
      assert(column <= lines[row].length, 'generated UTF-16 column outside line');
      if (delta.length === 1) return {column};
      source += delta[1]; originalLine += delta[2]; originalColumn += delta[3];
      assert(input[source]?.[originalLine] !== undefined, 'source line outside input');
      assert(originalColumn >= 0 && originalColumn <= input[source][originalLine].length);
      if (delta.length === 5) {
        name += delta[4];
        assert(name >= 0 && name < map.names.length);
      }
      return {column, source, originalLine, originalColumn, name: delta.length === 5 ? map.names[name] : null};
    });
  });
}
function coordinate(text, byte) {
  const bytes = Buffer.from(text);
  assert(byte >= 0 && byte <= bytes.length);
  const before = bytes.subarray(0, byte).toString('utf8');
  assert.equal(Buffer.byteLength(before), byte, 'non-scalar UTF-8 boundary');
  const lines = before.split('\n');
  return {line: lines.length - 1, column: lines.at(-1).length};
}
const js = await read('application.js'), ts = await read('application.ts');
const declaration = await read('application.d.ts');
const map = JSON.parse(await read('application.js.map'));
const manifest = JSON.parse(await read('application.js.origins.json'));
assert.equal(manifest.assurance, 'ordinary-checked', 'saved single-file artifact assurance');
assert.equal(map.file, 'application.js');
assert.equal(map.sourcesContent[0], await read('application.ps'));
assert(js.endsWith('//# sourceMappingURL=application.js.map\n'));
assert.equal(manifest.sourceResolution, 'owning-declaration-span');
const rows = mappings(map, js);
const origins = new Map(manifest.origins.map(o => [o.semantic, o]));
const symbols = new Map(manifest.symbols.map(s => [s.output, s.semantic]));
let mapped = 0, generatedParents = 0;
for (const range of manifest.ranges) {
  const semantic = symbols.get(range.output), origin = origins.get(semantic);
  if (!origin) continue;
  const generated = coordinate(js, range.startByte);
  const source = coordinate(map.sourcesContent[0], origin.sourceStartByte);
  const point = rows[generated.line]?.find(p => p.column === generated.column);
  assert(point, 'missing declaration mapping: ' + semantic);
  assert.equal(point.name, semantic);
  assert.equal(point.originalLine, source.line);
  assert.equal(point.originalColumn, source.column);
  assert(origin.sourceEndByte >= origin.sourceStartByte);
  mapped++;
  if (origin.generatedReason) generatedParents++;
}
assert(mapped > 100, 'source provenance unexpectedly lost');
assert(generatedParents > 0, 'normalization/projection provenance unexpectedly lost');
assert(manifest.origins.some(o => o.semantic === 'Library.Inner.inherited'));
assert(rows.slice(0, 20).every(row => row.every(p => p.source === undefined)),
  'runtime helpers must not claim user source');
const unicodeJs = await read('unicode-output.js');
const unicodeMap = JSON.parse(await read('unicode-output.js.map'));
const unicodeRows = mappings(unicodeMap, unicodeJs);
assert.equal(unicodeRows[0][0].column, '/* 🦀 */ '.length);
assert.equal(unicodeRows[0][0].originalColumn, '/* 😀 */ '.length);
assert.equal(unicodeRows[0][0].name, 'λ');
assert(unicodeRows.at(-1).at(-1).source === undefined, 'synthetic suffix must be unmapped');
// The declaration surface comes from the runtime IR, including erased Unit slots.
assert(!declaration.includes('__ps$Computation'));
assert(!declaration.includes('function*'));
assert(!declaration.includes('export declare function inductionTrue'));
assert(js.includes('function* __ps$impl$') && ts.includes('__ps$Computation<'));
assert(js.includes('while (true)') && ts.includes('while (true)'));
assert(!js.includes(': bigint') && !js.includes(' as const'));
// Isolate the declarations: a sibling application.ts would take precedence
// over application.d.ts when TypeScript resolves an application.js import.
const consumerRoot = path.join(root, 'declaration-consumer');
await mkdir(consumerRoot, {recursive: true});
await copyFile(path.join(root, 'application.d.ts'), path.join(consumerRoot, 'application.d.ts'));
await copyFile(path.join(root, 'application.js'), path.join(consumerRoot, 'application.js'));
await writeFile(path.join(consumerRoot, 'consumer.ts'), `import { answer, keep, choose, apply, identity, useUnit, checkedPair } from "./application.js";
const value: bigint = keep(answer);
const generic: string = choose<string>("first", "second");
const higher: bigint = apply(identity, value);
const unit: bigint = useUnit(undefined);
const field: bigint = checkedPair.first;
void [generic, higher, unit, field];
// @ts-expect-error Nat is bigint
keep(1);
// @ts-expect-error Unit call slot remains part of the runtime ABI
useUnit();
// @ts-expect-error value export is not callable
answer();
// @ts-expect-error nominal record fields are readonly
checkedPair.first = 0n;
`);
console.log(`PSCV0_DIRECTJS_ARTIFACTS: PASS ${mapped} declaration mappings; ${generatedParents} generated-parent origins; Unicode UTF-16 boundaries; declaration consumer prepared`);

// A compact review sample, not a golden-file acceptance requirement.
const start = js.indexOf('export function keep(');
console.log('PSCV0_READABLE_JS_SAMPLE\n' + js.slice(start, js.indexOf('\n\n', start)));
console.log(JSON.stringify({artifactBytes: {js: Buffer.byteLength(js), typescript: Buffer.byteLength(ts),
  declarations: Buffer.byteLength(declaration), sourceMap: Buffer.byteLength(JSON.stringify(map))},
  javascriptLines: js.split('\n').length}));
