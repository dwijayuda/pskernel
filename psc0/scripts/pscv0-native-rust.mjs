// Prepare a compact target harness; the compiler and backend remain native Lean.
import assert from 'node:assert/strict';
import {readFile, writeFile} from 'node:fs/promises';
import path from 'node:path';
import {observations} from './pscv0-native-observations.mjs';

const directory = path.resolve(process.argv[2]);
const manifest = JSON.parse(await readFile(path.join(directory, 'application.rs.origins.json'), 'utf8'));
assert.equal(manifest.target, 'rust');
const names = new Map(manifest.symbols.map(s => [s.semantic, s.output]));
// Each typed observation chooses the target's concrete source scalar. Result
// and argument types are independent, even when a current fixture uses both Int.
const value = (v, type = 'nat') => typeof v === 'bigint'
  ? (type === 'int' ? 'int("' : 'nat("') + String(v) + '")' : String(v);
const assertions = observations.map(({name, type, argTypes, args, expected}) => {
  assert(names.has(name), 'missing source export: ' + name);
  return '    assert_eq!(application::' + names.get(name) +
    '(' + (args ?? []).map((v, i) => value(v, argTypes?.[i] ?? 'nat')).join(', ') +
    '), ' + value(expected, type) + ', "' + name + '");';
});
await writeFile(path.join(directory, 'rust-checks.rs'),
  '#![forbid(unsafe_code)]\nmod application;\n' +
  'fn nat(text: &str) -> application::PsNat { text.parse().unwrap() }\n' +
  'fn int(text: &str) -> application::PsInt { text.parse().unwrap() }\n' +
  'fn main() {\n' + assertions.join('\n') +
  '\n    println!("PSCV0_NATIVE_RUST_RUNTIME: PASS ' + observations.length + ' shared runtime observations");\n}\n');
console.log('PSCV0_NATIVE_RUST_HARNESS: ' + observations.length + ' shared observations');
