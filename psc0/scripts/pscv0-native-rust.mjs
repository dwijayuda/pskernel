// Prepare a compact target harness; the compiler and backend remain native Lean.
import {quotedSourceString} from './pscv0-native-literals.mjs';
import assert from 'node:assert/strict';
import {readFile, writeFile} from 'node:fs/promises';
import path from 'node:path';
import {observations, panicObservations} from './pscv0-native-observations.mjs';

const directory = path.resolve(process.argv[2]);
const manifest = JSON.parse(await readFile(path.join(directory, 'application.rs.origins.json'), 'utf8'));
assert.equal(manifest.target, 'rust');
const names = new Map(manifest.symbols.map(s => [s.semantic, s.output]));
// Each typed observation chooses the target's concrete source scalar. Result
// and argument types are independent, even when a current fixture uses both Int.
const value = (v, type = 'nat') => typeof v === 'string'
  ? quotedSourceString(v) + '.to_owned()'
  : typeof v === 'bigint'
  ? (type === 'int64' ? String(v) + 'i64' :
    type === 'uint64' ? String(v) + 'u64' :
    (type === 'int' ? 'int("' : 'nat("') + String(v) + '")') : String(v);
const assertions = observations.map(({name, type, argTypes, args, expected}) => {
  assert(names.has(name), 'missing source export: ' + name);
  return '    assert_eq!(application::' + names.get(name) +
    '(' + (args ?? []).map((v, i) => value(v, argTypes?.[i] ?? 'nat')).join(', ') +
    '), ' + value(expected, type) + ', "' + name + '");';
});
const panicAssertions = panicObservations.map(({name}) => {
  const output = names.get(name);
  assert(output, 'missing checked panic symbol: ' + name);
  return [
    '    let trapped = std::panic::catch_unwind(|| application::' + output + '(nat("0")));',
    '    match trapped {',
    '        Ok(_) => panic!("' + name + ' returned default"),',
    '        Err(error) => {',
    '            let message = error.downcast_ref::<String>().map(String::as_str)',
    '                .or_else(|| error.downcast_ref::<&str>().copied());',
    '            assert_eq!(message, Some("index out of bounds"));',
    '        }',
    '    }',
  ].join('\n');
}).join('\n');
await writeFile(path.join(directory, 'rust-checks.rs'),
  '#![forbid(unsafe_code)]\nmod application;\n' +
  'fn nat(text: &str) -> application::PsNat { text.parse().unwrap() }\n' +
  'fn int(text: &str) -> application::PsInt { text.parse().unwrap() }\n' +
  'fn main() {\n' + assertions.join('\n') +
  '\n' + panicAssertions +
  '\n    println!("PSCV0_NATIVE_RUST_RUNTIME: PASS ' + observations.length + ' shared runtime observations");\n}\n');
console.log('PSCV0_NATIVE_RUST_HARNESS: ' + observations.length + ' shared observations');
