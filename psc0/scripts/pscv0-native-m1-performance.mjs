import assert from 'node:assert/strict';
import {readFile, writeFile} from 'node:fs/promises';
import {pathToFileURL} from 'node:url';
import path from 'node:path';
const directory = path.resolve(process.argv[2]);
const native = JSON.parse(await readFile(path.join(directory, 'native.json'), 'utf8'));
const generated = await import(pathToFileURL(path.join(directory, 'runtime.js')).href);
const median = values => [...values].sort((a,b) => a-b)[Math.floor(values.length / 2)];
const rows = [];
for (const size of [256, 8192]) {
  const n = BigInt(size);
  const xs = generated.m1MakeList(n);
  const array = generated.m1MakeArray(n);
  for (const [name, operation, iterations, expected] of [
    ['listHead', i => generated.m1ListAt(xs, i % 2n), 128, 192n],
    ['listTail', i => generated.m1ListAt(xs, n - 1n + i % 2n), 16, 8n * n],
    ['arrayHead', i => generated.m1ArrayAt(array, i % 2n), 128, 192n],
    ['arrayTail', i => generated.m1ArrayAt(array, n - 1n + i % 2n), 128, 64n * n],
    ['fromList', i => generated.m1FromList(xs) + i % 2n, 8, 8n * n + 4n],
    ['toList', i => generated.m1ToList(array) + i % 2n, 8, 8n * n + 4n]]) {
    const times = [];
    for (let trial = 0; trial < 6; trial++) {
      const start = process.hrtime.bigint();
      let checksum = 0n;
      for (let i = 0; i < iterations; i++) checksum += operation(BigInt(i));
      const elapsed = Number(process.hrtime.bigint() - start);
      assert.equal(checksum, expected, name);
      if (trial > 0) times.push(elapsed);
    }
    const reference = native.nativeLeanRuntime.find(row => row.name === name && row.size === size);
    assert.equal(reference.checksum, Number(expected));
    const jsNs = median(times), leanNs = median(reference.samplesNs);
    rows.push({name, size, iterations, samplesNs: times, medianNs: jsNs,
      nativeLeanMedianNs: leanNs, ratioToNativeLean: jsNs / Math.max(1, leanNs)});
  }
}
const compiler = [];
for (const count of [16, 128]) for (const indexed of [false, true]) {
  const samples = native.compilerSamples.filter(row => row.count === count && row.indexed === indexed && row.trial > 0);
  assert.equal(samples.length, 3);
  const timings = Object.fromEntries(Object.keys(samples[0].timings)
    .map(key => [key, median(samples.map(row => row.timings[key]))]));
  compiler.push({count, indexed, medianTimings: timings});
}
const report = {
  schema: native.schema, leanCommit: native.leanCommit, node: process.version,
  sourceSha: process.env.GITHUB_SHA ?? null,
  method: 'One warmup; five runtime samples; three compiler samples after warmup. Setup excluded. Native Lean and generated JS execute matching operations; these are different runtime systems, not a compiler-equivalence benchmark.',
  compilerComparison: 'Same PSCV0 compiler and process: identical Array/proof binder telescopes, direct index return versus checked collection lookup; 16 versus 128 declarations. Prelude initialization reported separately.',
  preludeMs: native.preludeMs, compiler, runtime: rows
};
await writeFile(path.join(directory, 'comparison.json'), JSON.stringify(report, null, 2) + '\n');
console.log(JSON.stringify(report));
