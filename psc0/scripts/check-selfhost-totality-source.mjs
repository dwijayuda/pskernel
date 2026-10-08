import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { packageBySection, parseImports } from './workspace-layout.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const visited = new Set();
function assertTotal(source, label) {
  assert(!/^\s*(?:partial\s+def|axiom|opaque)\s+/m.test(source), `${label}: unsupported admission declaration`);
}
async function visit(module) {
  if (visited.has(module)) return;
  visited.add(module);
  const parts = module.split('.');
  const section = packageBySection.get(parts[1]);
  assert(section, `unknown portable section: ${module}`);
  const source = await readFile(path.join(root, 'packages', section, 'src', ...parts) + '.lean', 'utf8');
  assertTotal(source, module);
  for (const dependency of parseImports(source)) await visit(dependency);
}
await visit('Ps.Bootstrap.SelfHost');
for (const declaration of ['partial def', 'axiom', 'opaque']) {
  assert.throws(() => assertTotal(`${declaration} admitted : Nat := 0`, 'mutation'));
}
const sources = [
  ['foundation/src/Ps/Foundation/Name.lean', 'psStringEqFromWithFuel (Nat.succ (String.utf8ByteSize left))', 'Int.repr (Int.ofNat value)'],
  ['syntax/src/Ps/Syntax/Cursor.lean', 'psLexStringToListFromWithFuel (Nat.succ (String.utf8ByteSize source))'],
  ['erasure/src/Ps/Erasure/Basic.lean', 'psErasureSafeStringFromWithFuel (Nat.succ (String.utf8ByteSize raw))'],
  ['syntax/src/Ps/Syntax/ParseLean.lean', 'psLeanLowerEquationClauses rest;', 'match lowerClauses branchClauses with'],
  ['bridge/src/Ps/Bridge/Json.lean', 'psJsonParseValueWithFuelWorker fallback remaining;',
    'if Nat.blt requested (Nat.succ remaining) then smaller requested input',
    'psJsonParseValueWithFuelWorker fallback fuel fuel input',
    'psJsonEncodeCanonicalWithFuel remaining;', 'Except.error PsJsonEncodeError.fuelExhausted',
    'psJsonEncodeCanonicalWithFuel 4096 value'],
];
for (const [file, ...markers] of sources) {
  const source = await readFile(path.join(root, 'packages', file), 'utf8');
  const validate = text => markers.forEach(marker => assert(text.includes(marker), `${file}: missing ${marker}`));
  validate(source);
  for (const marker of markers) assert.throws(() => validate(source.replaceAll(marker, 'removed')));
}
console.log(`PSC2_SELFHOST_TOTALITY_SOURCE: PASS (${visited.size} portable modules; total declarations, input bounds and explicit JSON depth exhaustion)`);
