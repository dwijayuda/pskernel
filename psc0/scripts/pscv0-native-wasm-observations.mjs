// Reuse the shared expected-value table; wrappers execute the actual compiled
// source operation, then compare its result inside the GC runtime.
import { observations, panicObservations } from './pscv0-native-observations.mjs';
import { readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
const directory = path.resolve(process.argv[2]);
const source = await readFile(path.join(directory, 'application.ps'), 'utf8');
// Encode source literals, not JavaScript display strings. In particular,
// JSON escapes and JSON's unescaped DEL do not define PSCV0 string syntax.
function sourceLiteral(value) {
  if (typeof value !== 'string') return String(value);
  let result = '"';
  for (const character of value) {
    const code = character.codePointAt(0);
    if (character === '"') result += '\\"';
    else if (character === '\\') result += '\\\\';
    else if (character === '\n') result += '\\n';
    else if (character === '\t') result += '\\t';
    else if (code < 32 || code === 127) result += '\\x' + code.toString(16).padStart(2, '0');
    else result += character;
  }
  return result + '"';
}
const wrappers = observations.map(({name, type, args, expected}, i) => {
  const call = name + (args === null ? '' : '(' + args.map(sourceLiteral).join(', ') + ')');
  // Check Int through its already modeled, canonical decimal representation.
  // This uses String's existing decidable equality and adds no kernel axiom.
  // Never infer the source type from the sign of the expected output.
  const compare = typeof expected === 'boolean'
    ? (expected ? call : 'if (' + call + ') { false } else { true }')
    : typeof expected === 'string'
      ? 'if (' + call + ' = ' + sourceLiteral(expected) + ') { true } else { false }'
    : type === 'int'
      ? 'if (Int.repr(' + call + ') = ' + sourceLiteral(String(expected)) +
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
