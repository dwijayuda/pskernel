// Reuse the shared expected-value table; wrappers execute the actual compiled
// source operation, then compare its result inside the GC runtime.
import { quotedSourceString } from './pscv0-native-literals.mjs';
import { observations, panicObservations } from './pscv0-native-observations.mjs';
import { readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
const directory = path.resolve(process.argv[2]);
const source = await readFile(path.join(directory, 'application.ps'), 'utf8');
const sourceLiteral = value => typeof value === 'string' ? quotedSourceString(value) : String(value);
const signedWidths = {
  int8: ['Int8', 'UInt8', 8], int16: ['Int16', 'UInt16', 16],
  int32: ['Int32', 'UInt32', 32], int64: ['Int64', 'UInt64', 64]
};
const unsignedWidths = {
  uint8: ['UInt8', 8], uint16: ['UInt16', 16],
  uint32: ['UInt32', 32], uint64: ['UInt64', 64]
};
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
      : signedWidths[type]
        ? (() => {
            const [signed, unsigned, bits] = signedWidths[type];
            const expectedBits = BigInt.asUintN(bits, BigInt(expected));
            return 'Nat.beq(' + unsigned + '.toNat(' + signed + '.toUInt' +
              bits + '(' + call + ')), ' + expectedBits + ')';
          })()
        : unsignedWidths[type]
          ? (() => {
              const [unsigned, bits] = unsignedWidths[type];
              const expectedBits = BigInt.asUintN(bits, BigInt(expected));
              return 'Nat.beq(' + unsigned + '.toNat(' + call + '), ' +
                expectedBits + ')';
            })()
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
