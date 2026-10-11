// Prepare a compact target harness; the compiler and backend remain native Lean.
import assert from 'node:assert/strict';
import {readFile, writeFile} from 'node:fs/promises';
import path from 'node:path';
import {observations} from './pscv0-native-observations.mjs';

const directory = path.resolve(process.argv[2]);
const manifest = JSON.parse(await readFile(path.join(directory, 'application.rs.origins.json'), 'utf8'));
assert.equal(manifest.target, 'rust');
const names = new Map(manifest.symbols.map(s => [s.semantic, s.output]));
const value = v => typeof v === 'bigint'
  ? 'nat("' + String(v) + '")' : String(v);
const assertions = observations.map(({name, args, expected}) => {
  assert(names.has(name), 'missing source export: ' + name);
  return '    assert_eq!(application::' + names.get(name) +
    '(' + (args ?? []).map(value).join(', ') + '), ' + value(expected) + ', "' + name + '");';
});
await writeFile(path.join(directory, 'rust-checks.rs'),
  '#![forbid(unsafe_code)]\nmod application;\n' +
  'fn nat(text: &str) -> application::PsNat { text.parse().unwrap() }\n' +
  'fn main() {\n' + assertions.join('\n') +
  '\n    println!("PSCV0_NATIVE_RUST_RUNTIME: PASS ' + observations.length + ' shared runtime observations");\n}\n');
console.log('PSCV0_NATIVE_RUST_HARNESS: ' + observations.length + ' shared observations');
