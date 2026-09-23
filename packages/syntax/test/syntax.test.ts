import {
  LEAN_SEMANTICS_COMMIT,
  LEAN_SEMANTICS_VERSION,
  LEAN434_INHERITED_FEATURE_IDS,
  PROOFSCRIPT_SPEC_VERSION,
  SyntaxError,
  hasTriviaBefore,
  isAdjacentCallOpen,
  classifyCallOpen,
  decideDCallOpen,
  ParserError,
  TokenCursor,
  spanFromTokens,
  lowerDCallSource,
  parseTermSubset,
  TermParser,
  lex,
  significantTokens,
  parseV061Module,
  lowerV061ModuleToLean,
  lowerV061TypeToLean,
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
equal(LEAN434_INHERITED_FEATURE_IDS.length,4);
assert(LEAN434_INHERITED_FEATURE_IDS.includes('L-LEAN434-ERASED-DO'));

{
  const tokens=significantTokens('f(x)');
  equal(tokens.map(t=>t.text).join(' '), 'f ( x )');
  assert(isAdjacentCallOpen(tokens[1]!), 'f(x) must expose an adjacent call open');
  equal(classifyCallOpen(tokens[1]!).feature,'D-CALL');
  const owned=decideDCallOpen(tokens[1]!);
  equal(owned.kind,'proofscript');
  if(owned.kind==='proofscript')equal(owned.node.feature,'D-CALL');
  assert(!hasTriviaBefore(tokens[1]!));
}
{
  const tokens=significantTokens('f (x)');
  assert(!isAdjacentCallOpen(tokens[1]!), 'f (x) must defer rather than claim D-CALL');
  equal(classifyCallOpen(tokens[1]!).owner,'defer');
  equal(decideDCallOpen(tokens[1]!).kind,'defer');
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


// Shared parser-core contract used by every D/E feature parser.
{
  const tokens=lex('f(x)');
  const cursor=new TokenCursor(tokens);
  equal(cursor.peek().text,'f');
  const f=cursor.expectKind('identifier');
  const open=cursor.expect('(');
  equal(cursor.position,2);
  const mark=cursor.mark();
  equal(cursor.expectKind('identifier').text,'x');
  cursor.reset(mark);
  equal(cursor.consume().text,'x');
  const close=cursor.expect(')');
  equal(spanFromTokens(f,close).end.offset,4);
  assert(open.adjacentToPrevious);
  assert(cursor.done);
}
{
  const token=lex('x')[0]!;
  const error=new ParserError('PS_AMBIGUOUS_OWNERSHIP','ambiguous ownership',token.span);
  equal(error.code,'PS_AMBIGUOUS_OWNERSHIP');
  assert(error instanceof SyntaxError);
}




// Reusable inherited Lean term parser foundation, independent of D-CALL ownership.
{
  const term=parseTermSubset('f x y');
  equal(term.kind,'application');
  if(term.kind==='application'){
    equal(term.args.length,2);
    equal(term.span.start.offset,0);
    equal(term.span.end.offset,5);
  }
}
{
  const term=parseTermSubset('f (g x)');
  equal(term.kind,'application');
  if(term.kind==='application'){
    equal(term.args[0]?.kind,'group');
  }
}
{
  const term=parseTermSubset('(f x, g y)');
  equal(term.kind,'tuple');
  if(term.kind==='tuple'){
    equal(term.items.length,2);
    equal(term.items[0]?.kind,'application');
    equal(term.items[1]?.kind,'application');
  }
}
{
  throws(()=>parseTermSubset('f(x)'),/term subset stopped before '\\('/);
}



// Parser extensions fail closed: deferring must consume nothing, claiming must consume something.
{
  const parser=new TermParser(lex('f(x)'),[{
    feature:'D-CALL',
    tryParse(inner){
      if(inner.cursor.at('('))inner.cursor.consume();
      return undefined;
    },
  }]);
  throws(()=>parser.parseExpression(),/consumed input before deferring/);
}
{
  const parser=new TermParser(lex('f(x)'),[{
    feature:'D-CALL',
    tryParse(_inner,current){
      return current;
    },
  }]);
  throws(()=>parser.parseExpression(),/returned a node without consuming input/);
}



// Lean 4.34 inherited parenthesized type-ascription syntax.
{
  const term=parseTermSubset('(x : Nat)');
  equal(term.kind,'ascription');
  if(term.kind==='ascription'){
    equal(term.value.kind,'atom');
    equal(term.type?.kind,'atom');
  }
}
{
  const term=parseTermSubset('(x :)');
  equal(term.kind,'ascription');
  if(term.kind==='ascription')equal(term.type,undefined);
}
{
  const lowered=lowerDCallSource('f((x : Nat))');
  equal(lowered.kind,'proofscript');
  if(lowered.kind==='proofscript')equal(lowered.node.leanText,'f (x : Nat)');
}
{
  const lowered=lowerDCallSource('(f(x) : Nat)');
  equal(lowered.kind,'proofscript');
  if(lowered.kind==='proofscript')equal(lowered.node.leanText,'(f x : Nat)');
}
{
  const lowered=lowerDCallSource('f((x :))');
  equal(lowered.kind,'proofscript');
  if(lowered.kind==='proofscript')equal(lowered.node.leanText,'f (x :)');
}

// v0.7 D-CALL conformance slice.
{
  const lowered=lowerDCallSource('add(1, 2)');
  equal(lowered.kind,'proofscript');
  if(lowered.kind==='proofscript')equal(lowered.node.leanText,'add 1 2');
}
{
  const lowered=lowerDCallSource('f((x, y))');
  equal(lowered.kind,'proofscript');
  if(lowered.kind==='proofscript')equal(lowered.node.leanText,'f (x, y)');
}
{
  const lowered=lowerDCallSource('f()');
  equal(lowered.kind,'proofscript');
  if(lowered.kind==='proofscript')equal(lowered.node.leanText,'f ()');
}
{
  const lowered=lowerDCallSource('g(f(x), h(y))');
  equal(lowered.kind,'proofscript');
  if(lowered.kind==='proofscript')equal(lowered.node.leanText,'g (f x) (h y)');
}
{
  equal(lowerDCallSource('f (x)').kind,'defer');
  equal(lowerDCallSource('f (x, y)').kind,'defer');
  equal(lowerDCallSource('f/-comment-/(x)').kind,'defer');
}


// D-CALL arguments may contain the inherited Lean application-term slice.
{
  const lowered=lowerDCallSource('apply(f x, xs)');
  equal(lowered.kind,'proofscript');
  if(lowered.kind==='proofscript')equal(lowered.node.leanText,'apply (f x) xs');
}
{
  const lowered=lowerDCallSource('apply(f (x), g y)');
  equal(lowered.kind,'proofscript');
  if(lowered.kind==='proofscript')equal(lowered.node.leanText,'apply (f (x)) (g y)');
}
{
  const lowered=lowerDCallSource('f g(x)');
  equal(lowered.kind,'proofscript');
  if(lowered.kind==='proofscript')equal(lowered.node.leanText,'f (g x)');
}
{
  const lowered=lowerDCallSource('apply((f x, g y), z)');
  equal(lowered.kind,'proofscript');
  if(lowered.kind==='proofscript')equal(lowered.node.leanText,'apply (f x, g y) z');
}
{
  equal(lowerDCallSource('f x').kind,'defer');
}


// v0.6.1 compiler-ready declaration slice.
{
  const module=parseV061Module('const answer : Nat := 42; function add(x : Nat, y : Nat) : Nat := x + y;');
  equal(module.declarations.length,2);
  equal(module.declarations[0]?.kind,'const');
  equal(module.declarations[1]?.kind,'function');
  equal(module.declarations[0]?.resultType.kind,'named');
  equal(module.featureIds.includes('D-CONST-ALIAS'),true);
  equal(module.featureIds.includes('D-FUNCTION-ALIAS'),true);
  equal(module.featureIds.includes('D-EXPLICIT-PARAMS'),true);
  equal(module.featureIds.includes('D-DECL-SEMI'),true);
  equal(lowerV061ModuleToLean(module),'def answer : Nat := 42\n\ndef add (x : Nat) (y : Nat) : Nat := x + y\n');
}
{
  const module=parseV061Module('function choose(x : Nat, y : Nat) : Nat := if (x < y) { x } else { y };');
  equal(module.featureIds.includes('E-IF-BRACE'),true);
  equal(lowerV061ModuleToLean(module),'def choose (x : Nat) (y : Nat) : Nat := if x < y then x else y\n');
}
{
  const module=parseV061Module('function use(x : Nat) : Nat := add(inc(x), 2);');
  equal(module.featureIds.includes('D-CALL'),true);
  equal(lowerV061ModuleToLean(module),'def use (x : Nat) : Nat := add (inc x) 2\n');
}


// v0.6.1 inherited lexical let term.
{
  const module=parseV061Module('function incTwice(x : Nat) : Nat := let y : Nat := x + 1; y + 1;');
  const body=module.declarations[0]?.body;
  equal(body?.kind,'let');
  if(body?.kind==='let'){
    equal(body.name,'y');
    equal(body.declaredType?.kind,'named');
    if(body.declaredType?.kind==='named')equal(body.declaredType.name,'Nat');
    equal(body.value.kind,'binary');
    equal(body.body.kind,'binary');
  }
  equal(
    lowerV061ModuleToLean(module),
    'def incTwice (x : Nat) : Nat := let y : Nat := x + 1; y + 1\n',
  );
}
{
  const module=parseV061Module('function shadow(x : Nat) : Nat := let x := x + 1; x;');
  const body=module.declarations[0]?.body;
  equal(body?.kind,'let');
  if(body?.kind==='let')equal(body.declaredType,undefined);
}


// v0.6.1 inherited function type syntax.
{
  const module=parseV061Module('const increment : Nat -> Nat := 1;');
  const type=module.declarations[0]?.resultType;
  equal(type?.kind,'arrow');
  if(type?.kind==='arrow'){
    equal(lowerV061TypeToLean(type),'Nat -> Nat');
  }
}
{
  const module=parseV061Module('const composeType : Nat -> Bool -> String := "x";');
  const type=module.declarations[0]?.resultType;
  equal(type?.kind,'arrow');
  if(type?.kind==='arrow')equal(type.codomain.kind,'arrow');
}


// v0.6.1 inherited lambda syntax.
{
  const module=parseV061Module('const increment : Nat -> Nat := fun x => x + 1;');
  const body=module.declarations[0]?.body;
  equal(body?.kind,'lambda');
  if(body?.kind==='lambda'){
    equal(body.binders.length,1);
    equal(body.binders[0]?.name,'x');
    equal(body.binders[0]?.type,undefined);
  }
  equal(
    lowerV061ModuleToLean(module),
    'def increment : Nat -> Nat := fun x => x + 1\n',
  );
}
{
  const module=parseV061Module('const addFn : Nat -> Nat -> Nat := fun (x : Nat) (y : Nat) => x + y;');
  const body=module.declarations[0]?.body;
  equal(body?.kind,'lambda');
  if(body?.kind==='lambda'){
    equal(body.binders.length,2);
    equal(body.binders[0]?.type?.kind,'named');
    equal(body.binders[1]?.type?.kind,'named');
  }
  equal(
    lowerV061ModuleToLean(module),
    'def addFn : Nat -> Nat -> Nat := fun (x : Nat) (y : Nat) => x + y\n',
  );
}
{
  throws(
    ()=>parseV061Module('const bad : Nat -> Nat := fun => 1;'),
    /lambda requires at least one binder/,
  );
}


// Empty D-CALL is Unit application, not zero-arity invocation.
{
  const module=parseV061Module('function run(f : Unit -> Nat) : Nat := f();');
  const body=module.declarations[0]?.body;
  equal(body?.kind,'call');
  if(body?.kind==='call'){
    equal(body.args.length,1);
    equal(body.args[0]?.kind,'unit');
  }
  equal(lowerV061ModuleToLean(module),'def run (f : Unit -> Nat) : Nat := f ()\n');
}
