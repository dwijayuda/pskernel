import assert from 'node:assert/strict';
import { test } from 'node:test';
import { maskLeanSource } from './lean-source-mask.mjs';
import { maskLeanNonCode as stableMask, findForbiddenForms, readSelfhostProfile } from './selfhost-profile.mjs';
import { maskLeanNonCode as checkedMask, auditPsc1Source } from './psc1-source-profile.mjs';
import { findSelfhostStructuralViolations } from './selfhost-source-rules.mjs';
import { leanCode } from './compiler-ownership.mjs';

test('shared scanner preserves offsets across character escapes, Unicode and comments', () => {
  const source = [
    String.raw`def quote : Char := '"'`,
    String.raw`def apostrophe : Char := '\''`,
    String.raw`def slash : Char := '\\'`,
    String.raw`def escaped : Char := '\u0022'`,
    String.raw`def hex : Char := '\x22'`,
    "def unicode : Char := '😀'",
    "def newline : Char := '\n'",
    '/- outer /- " nested -/ end -/',
    '-- " line',
    "def x' : Nat := 1",
    'unsafe def forbidden : Nat := 0',
  ].join('\r\n');
  const output = maskLeanSource(source, { strict: true });
  assert.equal(output.length, source.length);
  assert.deepEqual([...output.matchAll(/[\r\n]/g)].map(x => x.index), [...source.matchAll(/[\r\n]/g)].map(x => x.index));
  assert(output.endsWith('unsafe def forbidden : Nat := 0'));
  assert(output.includes("def x' : Nat := 1"));
  assert(!output.includes('"'));
  assert.equal(stableMask(source), output);
  assert.equal(checkedMask(source), output);
  assert.equal(leanCode(source), output);
});

test('character quotes cannot conceal forbidden forms from either profile', async () => {
  const source = String.raw`def quote : Char := '"'
unsafe def forbidden : Nat := 0`;
  assert(findForbiddenForms(source, await readSelfhostProfile()).some(x => x.id === 'unsafe-definition'));
  assert(auditPsc1Source(source).some(x => x.key === 'unsafe'));
  assert(findSelfhostStructuralViolations(source + '\ndef f := { state with x := next }').some(x => x.id === 'record-update'));
});

test('identifier apostrophes cannot masquerade as character literals', () => {
  for (const name of ["f'", "f''", "α'", "value'x'"]) {
    const source = 'def ' + name + ' := "text"\nunsafe def next := 0';
    const output = maskLeanSource(source, { strict: true });
    assert(output.includes('def ' + name + ' := '));
    assert(output.endsWith('unsafe def next := 0'));
  }
});

test('ordinary and raw strings end at their own delimiters', () => {
  const source = String.raw`def s := "escaped \" -- /-"
def raw := r##"inner " and "# and \\""##
unsafe def next := 0`;
  const output = maskLeanSource(source, { strict: true });
  assert(output.endsWith('unsafe def next := 0'));
  assert(!output.includes('inner'));
  assert(maskLeanSource(source, { preserveStrings: true }).includes('inner " and "#'));
  for (const input of ['/- open', '"open', 'r##"open"#']) {
    assert.throws(() => maskLeanSource(input, { strict: true }), /LEXICAL_UNTERMINATED/);
  }
});

test('layout and delimiter rules inspect code rather than literal contents', () => {
  const source = String.raw`def f : Char :=
  let value : Char := '"'; -- apostrophe is not a string
  value
/- let fake := (
   unsafe
-/
def text := "let fake := ("
def g : Char :=
  let brace : Char := '{';
  brace`;
  assert.deepEqual(findSelfhostStructuralViolations(source), []);
  assert(findSelfhostStructuralViolations(String.raw`def f : Char :=
  let value : Char := '"'
  value`).some(x => x.id === 'layout-let-sequencing'));
  assert(!findSelfhostStructuralViolations(String.raw`def f (c : Char) : Bool :=
  match c with
  | '"' => true
  | _ => false`).some(x => x.id === 'string-literal-pattern'));
  assert(findSelfhostStructuralViolations('def f (s : String) :=\n  match s with\n  | "x" => true\n  | _ => false').some(x => x.id === 'string-literal-pattern'));
});
