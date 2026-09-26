import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

import {
  anonymous,
  strName,
  numName,
  nameFromDotted,
  nameAppendAfter,
  nameAppendIndexAfter,
  nameIsPrefixOf,
  nameAppend,
  nameReplacePrefix,
  nameEq,
  nameKey,
  nameCmp,
  nameToString,
} from '../dist/src/core/name.js';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const selfhost = path.join(root, 'selfhost');

function fail(message) {
  console.error(`PSCKERNEL_NAME_DIFFERENTIAL_FAIL: ${message}`);
  process.exit(1);
}

const fixtureRun = spawnSync('lake', ['exe', 'psckernel_name_fixture'], {
  cwd: selfhost,
  encoding: 'utf8',
});

if (fixtureRun.error) {
  fail(`could not run Lean fixture: ${fixtureRun.error.message}`);
}
if (fixtureRun.status !== 0) {
  if (fixtureRun.stdout) process.stderr.write(fixtureRun.stdout);
  if (fixtureRun.stderr) process.stderr.write(fixtureRun.stderr);
  fail(`Lean fixture exited with status ${fixtureRun.status}`);
}

const fixture = new Map();
for (const rawLine of fixtureRun.stdout.split(/\r?\n/)) {
  if (rawLine === '') continue;
  const tab = rawLine.indexOf('\t');
  if (tab <= 0) fail(`malformed fixture line: ${JSON.stringify(rawLine)}`);
  const key = rawLine.slice(0, tab);
  const value = rawLine.slice(tab + 1);
  if (fixture.has(key)) fail(`duplicate fixture key: ${key}`);
  fixture.set(key, value);
}

const a = nameFromDotted('A');
const ab = nameFromDotted('A.B');
const ab3 = numName(ab, 3);
const x = nameFromDotted('X');
const z = nameFromDotted('Z');
const appendBase = numName(a, 2);
const appendSuffix = numName(nameFromDotted('B'), 3);
const freshLeft = strName(strName(anonymous, 'A'), 'B');
const freshRight = strName(strName(anonymous, 'A'), 'B');
const numeral = numName(a, 1);
const text = strName(a, 'x');
const bmp = strName(a, '\uE000');
const astral = strName(a, '\u{10000}');
const matchedReplacement = nameReplacePrefix(ab3, a, x);

if (matchedReplacement === null) {
  fail('TS replacePrefix unexpectedly rejected a matching prefix');
}

const expectedParity = new Map([
  ['fromDotted.empty.key', nameKey(nameFromDotted(''))],
  ['fromDotted.dotted.toString', nameToString(nameFromDotted('A..B'))],
  ['appendAfter.toString', nameToString(nameAppendAfter(ab, '_x'))],
  ['appendIndexAfter.toString', nameToString(nameAppendIndexAfter(ab, 7))],
  ['prefix.true', String(nameIsPrefixOf(a, ab3))],
  ['append.key', nameKey(nameAppend(appendBase, appendSuffix))],
  ['replace.match.key', nameKey(matchedReplacement)],
  ['fresh.eq', String(nameEq(freshLeft, freshRight))],
  ['fresh.key', nameKey(freshLeft)],
  ['cmp.numString', String(nameCmp(numeral, text))],
  ['cmp.unicode', String(nameCmp(bmp, astral))],
  ['unicode.key', nameKey(astral)],
]);

const allowedFixtureKeys = new Set([
  ...expectedParity.keys(),
  'anonymous.toString',
  'replace.miss.key',
]);

for (const key of fixture.keys()) {
  if (!allowedFixtureKeys.has(key)) {
    fail(`unclassified PSCKernel fixture output: ${key}`);
  }
}

for (const [key, expected] of expectedParity) {
  if (!fixture.has(key)) fail(`missing fixture key: ${key}`);
  const actual = fixture.get(key);
  if (actual !== expected) {
    fail(`${key}: TS=${JSON.stringify(expected)} PSCKernel=${JSON.stringify(actual)}`);
  }
}

if (fixture.size !== allowedFixtureKeys.size) {
  for (const key of allowedFixtureKeys) {
    if (!fixture.has(key)) fail(`missing fixture key: ${key}`);
  }
  fail(`unexpected fixture size ${fixture.size}; expected ${allowedFixtureKeys.size}`);
}

const psAnonymousText = fixture.get('anonymous.toString');
const tsAnonymousText = nameToString(anonymous);
if (tsAnonymousText !== '_') {
  fail(`classified anonymous TS behavior drifted: ${JSON.stringify(tsAnonymousText)}`);
}
if (psAnonymousText !== '[anonymous]') {
  fail(`Lean-authoritative anonymous display drifted: ${JSON.stringify(psAnonymousText)}`);
}

const tsMissingReplacement = nameReplacePrefix(ab3, z, x);
if (tsMissingReplacement !== null) {
  fail('classified nonmatching TS replacePrefix behavior drifted: expected null');
}
const psMissingReplacementKey = fixture.get('replace.miss.key');
const originalKey = nameKey(ab3);
if (psMissingReplacementKey !== originalKey) {
  fail(
    `Lean-authoritative nonmatching replacePrefix drifted: expected ${JSON.stringify(originalKey)}, ` +
      `got ${JSON.stringify(psMissingReplacementKey)}`,
  );
}

console.log(
  `PSCKERNEL_NAME_DIFFERENTIAL: PASS (${expectedParity.size} parity cases, 2 classified Lean-4.34 deviations)`,
);
