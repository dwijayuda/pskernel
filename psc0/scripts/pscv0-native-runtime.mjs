import assert from 'node:assert/strict';
import {observations} from './pscv0-native-observations.mjs';
import {pathToFileURL} from 'node:url';
import path from 'node:path';
import {readFile} from 'node:fs/promises';
const outputPath = path.resolve(process.argv[2]);
let output;
try {
  output = await import(pathToFileURL(outputPath).href);
} catch (error) {
  // Preserve the original failure and show the generated call sites in CI.
  const lines = (await readFile(outputPath, 'utf8')).split('\n');
  const locations = [...String(error.stack).matchAll(/application\.js:(\d+):\d+/g)]
    .map(match => Number(match[1]));
  const selected = new Set();
  for (const line of locations)
    for (let i = Math.max(1, line - 25); i <= Math.min(lines.length, line + 25); i++)
      selected.add(i);
  for (const i of [...selected].sort((a, b) => a - b))
    console.error(`${i}: ${lines[i - 1]}`);
  throw error;
}
for (const {name, args, expected} of observations)
  assert.equal(args === null ? output[name] : output[name](...args), expected, name);
assert.throws(() => output.bangDefaultTrap(0n),
  error => error instanceof Error && error.message.includes("index out of bounds"),
  "outOfBounds must not execute its kernel-level default at runtime");
assert.deepEqual(Object.keys(output.checkedPair), ['first', 'second']);
assert.deepEqual(Object.keys(output.checkedList), ['head', 'tail']);
console.log(`PSCV0_NATIVE_RUNTIME: PASS ${observations.length} shared runtime observations (${process.argv[3] ?? 'typescript'})`);
