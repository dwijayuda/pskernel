// Reuse the shared expected-value table; wrappers execute the actual compiled
// source operation, then compare its result inside the GC runtime.
import { observations } from './pscv0-native-observations.mjs';
import { readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
const directory = path.resolve(process.argv[2]);
const source = await readFile(path.join(directory, 'application.ps'), 'utf8');
const wrappers = observations.map(({name, args, expected}, i) => {
  const call = name + (args === null ? '' : '(' + args.map(String).join(', ') + ')');
  const compare = typeof expected === 'boolean'
    ? (expected ? call : 'if (' + call + ') { false } else { true }')
    : 'Nat.beq(' + call + ', ' + String(expected) + ')';
  return 'const wasmCheck' + i + ': Bool := ' + compare;
});
await writeFile(path.join(directory, 'wasm/observations.ps'), source + '\n' + wrappers.join('\n') + '\n');
await writeFile(path.join(directory, 'wasm/observations.exports.json'),
  JSON.stringify(observations.map((_, i) => 'wasmCheck' + i)));
