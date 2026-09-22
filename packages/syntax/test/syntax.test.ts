import {
  LEAN_SEMANTICS_COMMIT,
  LEAN_SEMANTICS_VERSION,
  PROOFSCRIPT_SPEC_VERSION,
  SyntaxError,
  hasTriviaBefore,
  isAdjacentCallOpen,
  lex,
  significantTokens,
} from '../src/index.js';

function assert(condition: unknown, message = 'assertion failed'): asserts condition {
  if (!condition) throw new Error(message);
}
function equal(actual: unknown, expected: unknown, message = ''): void {
  if (actual !== expected) throw new Error(`${message ? message + ': ' : ''}expected ${String(expected)}, got ${String(actual)}`);
}
function throws(f: () => unknown, pattern: RegExp): void {
  try { f(); } catch (error) {
    const message=error instanceof Error?error.message:String(error);
    if (!pattern.test(message)) throw new Error(`expected error ${pattern}, got ${message}`);
    return;
  }
  throw new Error(`expected function to throw ${pattern}`);
}

equal(PROOFSCRIPT_SPEC_VERSION, '0.7.0');
equal(LEAN_SEMANTICS_VERSION, '4.34.0');
equal(LEAN_SEMANTICS_COMMIT, '293d5d0c0c3f3dded4688b3ccd6a33939ac5102b');

{
  const tokens=significantTokens('f(x)');
  equal(tokens.map(t=>t.text).join(' '), 'f ( x )');
  assert(isAdjacentCallOpen(tokens[1]!), 'f(x) must expose an adjacent call open');
  assert(!hasTriviaBefore(tokens[1]!));
}
{
  const tokens=significantTokens('f (x)');
  assert(!isAdjacentCallOpen(tokens[1]!), 'f (x) must defer rather than claim D-CALL');
  equal(tokens[1]!.leadingTrivia[0]?.kind, 'whitespace');
}
{
  const tokens=significantTokens('f/- nested /- block -/ comment -/(x)');
  assert(!isAdjacentCallOpen(tokens[1]!), 'comments must break D-CALL adjacency');
  equal(tokens[1]!.leadingTrivia[0]?.kind, 'block-comment');
}
{
  const tokens=significantTokens('x -- note\n y');
  equal(tokens.length,2);
  equal(tokens[1]!.leadingTrivia[0]?.kind,'whitespace');
  equal(tokens[1]!.leadingTrivia[1]?.kind,'line-comment');
  equal(tokens[1]!.span.start.line,2);
}
{
  const tokens=significantTokens('x//y');
  equal(tokens.map(t=>t.text).join(' '),'x / / y');
}
{
  const [token]=significantTokens('Math.αβ?');
  equal(token?.kind,'identifier');
  equal(token?.text,'Math.αβ?');
  equal(token?.span.start.column,1);
  equal(token?.span.end.offset,'Math.αβ?'.length);
}
{
  const [token]=significantTokens('"A\\n\\u263A"');
  equal(token?.kind,'string');
  equal(token?.text,'"A\\n\\u263A"');
  equal(token?.value,'A\n☺');
}
{
  equal(significantTokens('0xff 0b1010 1_000').map(t=>t.text).join(' '),'0xff 0b1010 1_000');
  throws(()=>lex('0x_'),/hex literal requires digits/);
  throws(()=>lex('0b_'),/binary literal requires digits/);
}
{
  try { lex('/- unclosed'); throw new Error('expected unterminated comment'); }
  catch (error) {
    assert(error instanceof SyntaxError);
    equal(error.span.start.offset,0);
    equal(error.span.start.line,1);
  }
  throws(()=>lex('"unterminated'),/unterminated string literal/);
}

console.log('ok - @proofscript/syntax lexer MVP');
