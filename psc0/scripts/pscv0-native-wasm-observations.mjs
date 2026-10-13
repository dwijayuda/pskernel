// Reuse the shared expected-value table; wrappers execute the actual compiled
// source operation, then compare its result inside the GC runtime.
import { observations, panicObservations } from './pscv0-native-observations.mjs';
import { readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
const directory = path.resolve(process.argv[2]);
const source = await readFile(path.join(directory, 'application.ps'), 'utf8');
const wrappers = observations.map(({name, type, args, expected}, i) => {
  const call = name + (args === null ? '' : '(' + args.map(String).join(', ') + ')');
  // Check Int through its already modeled, canonical decimal representation.
  // This uses String's existing decidable equality and adds no kernel axiom.
  // Never infer the source type from the sign of the expected output.
  const compare = typeof expected === 'boolean'
    ? (expected ? call : 'if (' + call + ') { false } else { true }')
    : type === 'int'
      ? 'if (Int.repr(' + call + ') = ' + JSON.stringify(String(expected)) +
        ') { true } else { false }'
      : 'Nat.beq(' + call + ', ' + String(expected) + ')';
  return 'const wasmCheck' + i + ': Bool := ' + compare;
});
await writeFile(path.join(directory, 'wasm/observations.ps'), source + '\n' +
  wrappers.join('\n') + '\n' +
  panicObservations.map(({name, wasm}) =>
    'const ' + wasm + ': Bool := Nat.beq(' + name + '(0), 0)\n').join(''));
await writeFile(path.join(directory, 'wasm/observations.exports.json'),
  JSON.stringify([...observations.map((_, i) => 'wasmCheck' + i), ...panicObservations.map(({wasm}) => wasm)]));

await writeFile(path.join(directory, 'wasm/observation-count.txt'), String(observations.length));
