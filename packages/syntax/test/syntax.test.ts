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
  lowerV061ModuleToProofScript,
  lowerV061TypeToLean,
  sourceKindFromFileName,
  createDefaultSourceFrontendRegistry,
  createDefaultTranslationTargetPrinterRegistry,
  type SourceFrontend,
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
  equal(sourceKindFromFileName('main.ps'),'proofscript');
  equal(sourceKindFromFileName('Main.lean'),'lean-subset');
  equal(sourceKindFromFileName('UPPER.PS'),'proofscript');
  throws(
    ()=>sourceKindFromFileName('main.ts'),
    /PS_FRONTEND_SOURCE_KIND/,
  );

  const registry=createDefaultSourceFrontendRegistry();
  equal(registry.forFile('main.ps').kind,'proofscript');
  equal(
    registry.forFile('main.ps').parse('def id(x : Nat) : Nat := x;').declarations.length,
    1,
  );
  throws(
    ()=>registry.forFile('Main.lean'),
    /PS_FRONTEND_UNAVAILABLE/,
  );

  const leanStub:SourceFrontend={
    kind:'lean-subset',
    parse:parseV061Module,
    print:lowerV061ModuleToProofScript,
  };
  registry.register(leanStub);
  equal(registry.forFile('Main.lean'),leanStub);
  throws(
    ()=>registry.register(leanStub),
    /PS_FRONTEND_DUPLICATE/,
  );
}

{
  const source=[
    'structure Box(α : Type) where { value : α; };',
    'class Sized(α : Type) where { size : α -> Nat; };',
    'inductive Maybe(α : Type) where { | none; | some(value : α); };',
    'function choose(x : Nat, y : Nat) : Nat := '+
      'if (x < y) { x } else { y };',
    'def identity {α : Type}(x : α) : α := x;',
    'def unwrap(x : Maybe(Nat), fallback : Nat) : Nat := '+
      'match x with { | .none => fallback; | .some value => value; };',
    'def localDemo(x : Nat) : Nat := helper(x) where { '+
      'helper(y : Nat) : Nat := y + 1; };',
    'instance boxedNat : Box(Nat) := { value := 0 : Box(Nat) };',
    'theorem reflViaSearch(P : Prop, h : P) : P := by exact?;',
  ].join('\n');
  const first=parseV061Module(source);
  const printed=lowerV061ModuleToProofScript(first);
  const second=parseV061Module(printed);
  const printedAgain=lowerV061ModuleToProofScript(second);
  equal(printedAgain,printed);
  equal(
    createDefaultSourceFrontendRegistry()
      .forFile('canonical.ps')
      .print(first),
    printed,
  );
  equal(printed.includes('function choose(x : Nat, y : Nat)'),true);
  equal(printed.includes('def identity {α : Type}(x : α)'),true);
  equal(printed.includes('match x with { | .none => fallback;'),true);
  equal(printed.includes('where {\n  helper(y : Nat)'),true);

  const targets=createDefaultTranslationTargetPrinterRegistry();
  equal(targets.require('ps').print(first),printed);
  equal(
    targets.require('lean').print(first),
    lowerV061ModuleToLean(first),
  );
  equal(targets.require('ps').extension,'.ps');
  equal(targets.require('lean').extension,'.lean');
  throws(
    ()=>targets.register(targets.require('ps')),
    /PS_TRANSLATION_TARGET_DUPLICATE/,
  );
}

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


// v0.6.1 E-MATCH-BODY: braces/separators change, patterns retain Lean meaning.
{
  const module=parseV061Module(
    'function choose(flag : Bool) : Nat := match flag with { | true => 1; | false => 2; };',
  );
  const body=module.declarations[0]?.body;
  equal(body?.kind,'match');
  equal(module.featureIds.includes('E-MATCH-BODY'),true);
  if(body?.kind==='match'){
    equal(body.alternatives.length,2);
    equal(body.alternatives[0]?.pattern.kind,'bool');
  }
  equal(
    lowerV061ModuleToLean(module),
    'def choose (flag : Bool) : Nat := match flag with\n  | true => 1\n  | false => 2\n',
  );
}
{
  const module=parseV061Module(
    'function get(value : Bool) : Nat := match value with { | _ => 1; };',
  );
  const body=module.declarations[0]?.body;
  equal(body?.kind,'match');
  if(body?.kind==='match')equal(body.alternatives[0]?.pattern.kind,'wildcard');
}
{
  const module=parseV061Module(
    'function get(value : Bool) : Nat := match value with { | .some x => transform(x); | .none => 0; };',
  );
  const body=module.declarations[0]?.body;
  equal(body?.kind,'match');
  if(body?.kind==='match'){
    equal(body.alternatives[0]?.pattern.kind,'constructor');
    if(body.alternatives[0]?.pattern.kind==='constructor'){
      equal(body.alternatives[0].pattern.name,'.some');
      equal(body.alternatives[0].pattern.binders[0],'x');
    }
  }
}


// v0.6.1 E-STRUCT-BODY: outer braces delimit structure members.
{
  const module=parseV061Module(
    'structure User where { name : String; age : Nat; }',
  );
  const declaration=module.declarations[0];
  equal(declaration?.kind,'structure');
  equal(module.featureIds.includes('E-STRUCT-BODY'),true);
  if(declaration?.kind==='structure'){
    equal(declaration.fields.length,2);
    equal(declaration.fields[0]?.name,'name');
    equal(declaration.fields[1]?.name,'age');
  }
  equal(
    lowerV061ModuleToLean(module),
    'structure User where\n  name : String\n  age : Nat\n',
  );
}
{
  const module=parseV061Module(
    'structure Box(α : Type) where { value : α; }',
  );
  const declaration=module.declarations[0];
  equal(declaration?.kind,'structure');
  if(declaration?.kind==='structure'){
    equal(declaration.params.length,1);
    equal(declaration.params[0]?.name,'α');
  }
  equal(
    lowerV061ModuleToLean(module),
    'structure Box (α : Type) where\n  value : α\n',
  );
}


// Inherited Lean structure value syntax used by the software profile.
{
  const module=parseV061Module(
    'structure User where { name : String; age : Nat; } const ada : User := { name := "Ada", age := 33 : User };',
  );
  const declaration=module.declarations[1];
  equal(declaration?.kind,'const');
  if(declaration?.kind==='const'){
    equal(declaration.body.kind,'record');
    if(declaration.body.kind==='record'){
      equal(declaration.body.fields.length,2);
      equal(declaration.body.fields[0]?.name,'name');
      equal(declaration.body.type.kind,'named');
    }
  }
  equal(
    lowerV061ModuleToLean(module),
    'structure User where\n  name : String\n  age : Nat\n\ndef ada : User := { name := "Ada", age := 33 : User }\n',
  );
}


// v0.6.1 E-INDUCTIVE-BODY: braces/semicolons decorate Lean inductive declarations.
{
  const module=parseV061Module(
    'inductive Color where { | red; | blue; }',
  );
  const declaration=module.declarations[0];
  equal(declaration?.kind,'inductive');
  equal(module.featureIds.includes('E-INDUCTIVE-BODY'),true);
  if(declaration?.kind==='inductive'){
    equal(declaration.constructors.length,2);
    equal(declaration.constructors[0]?.name,'red');
    equal(declaration.constructors[1]?.name,'blue');
  }
  equal(
    lowerV061ModuleToLean(module),
    'inductive Color where\n  | red\n  | blue\n',
  );
}
{
  const module=parseV061Module(
    'inductive Result(α : Type, ε : Type) where { | ok(value : α); | error(error : ε); }',
  );
  const declaration=module.declarations[0];
  equal(declaration?.kind,'inductive');
  if(declaration?.kind==='inductive'){
    equal(declaration.params.length,2);
    equal(declaration.constructors[0]?.params.length,1);
    equal(declaration.constructors[1]?.params.length,1);
  }
  equal(
    lowerV061ModuleToLean(module),
    'inductive Result (α : Type) (ε : Type) where\n  | ok (value : α)\n  | error (error : ε)\n',
  );
}
{
  throws(
    ()=>parseV061Module(
      'inductive Vector where { | nil : Vector; }',
    ),
    /explicit constructor result types are not yet implemented/,
  );
}


// v0.6.1 E-WHERE-BODY: braces delimit Lean local declarations, not statements.
{
  const module=parseV061Module(
    'def f(x : Nat) : Nat := helper(x) where { helper(y : Nat) : Nat := y + 1; }',
  );
  const declaration=module.declarations[0];
  equal(declaration?.kind,'def');
  equal(module.featureIds.includes('E-WHERE-BODY'),true);
  if(declaration?.kind==='def'){
    equal(declaration.whereDeclarations?.length,1);
    equal(declaration.whereDeclarations?.[0]?.name,'helper');
    equal(declaration.whereDeclarations?.[0]?.params.length,1);
  }
  equal(
    lowerV061ModuleToLean(module),
    'def f (x : Nat) : Nat := helper x where\n  helper (y : Nat) : Nat := y + 1\n',
  );
}
{
  throws(
    ()=>parseV061Module(
      'def f(x : Nat) : Nat := x where { helper(y : Nat) : Nat := y where { z : Nat := 1; }; }',
    ),
    /nested where blocks are not yet implemented/,
  );
}


// v0.6.1 positive corpus: inner braces are Lean implicit structure-field binders.
{
  const module=parseV061Module(
    'structure Box where { {α : Type}; value : α; }',
  );
  const declaration=module.declarations[0];
  equal(declaration?.kind,'structure');
  if(declaration?.kind==='structure'){
    equal(declaration.fields[0]?.binderKind,'implicit');
    equal(declaration.fields[0]?.name,'α');
    equal(declaration.fields[1]?.binderKind,'explicit');
  }
  equal(
    lowerV061ModuleToLean(module),
    'structure Box where\n  {α : Type}\n  value : α\n',
  );
}
{
  const module=parseV061Module(
    'structure Box where { {α : Type}; [showα : ToString α]; value : α; }',
  );
  const declaration=module.declarations[0];
  equal(declaration?.kind,'structure');
  if(declaration?.kind==='structure'){
    equal(declaration.fields[1]?.binderKind,'instance');
    equal(declaration.fields[1]?.type.kind,'application');
  }
  equal(
    lowerV061ModuleToLean(module),
    'structure Box where\n  {α : Type}\n  [showα : ToString α]\n  value : α\n',
  );
}


// v0.6.1 E-CLASS-BODY: class remains Lean typeclass syntax, not a JS class.
{
  const module=parseV061Module(
    'class Sized(α : Type) where { size : α -> Nat; }',
  );
  const declaration=module.declarations[0];
  equal(declaration?.kind,'class');
  equal(module.featureIds.includes('E-CLASS-BODY'),true);
  if(declaration?.kind==='class'){
    equal(declaration.params.length,1);
    equal(declaration.fields.length,1);
    equal(declaration.fields[0]?.name,'size');
  }
  equal(
    lowerV061ModuleToLean(module),
    'class Sized (α : Type) where\n  size : α -> Nat\n',
  );
}


// Type application is a term-level concept: native whitespace and D-CALL normalize to Lean application.
{
  const native=parseV061Module('const x : ToString Nat := y;');
  const type=native.declarations[0]?.kind==='const'
    ? native.declarations[0].resultType
    : undefined;
  equal(type?.kind,'application');
  if(type!==undefined)equal(lowerV061TypeToLean(type),'ToString Nat');
}
{
  const decorated=parseV061Module('const x : Result(Nat, String) := y;');
  const type=decorated.declarations[0]?.kind==='const'
    ? decorated.declarations[0].resultType
    : undefined;
  equal(type?.kind,'application');
  equal(decorated.featureIds.includes('D-CALL'),true);
  if(type!==undefined)equal(lowerV061TypeToLean(type),'Result Nat String');
}


// D-EXPLICIT-PARAMS is a non-empty binder group, matching the frozen v0.6.1 grammar.
{
  throws(
    ()=>parseV061Module('def bad() : Nat := 0;'),
    /D-EXPLICIT-PARAMS requires at least one explicit binding/,
  );
}
{
  throws(
    ()=>parseV061Module('inductive EmptyArgs() where { | mk; }'),
    /D-EXPLICIT-PARAMS requires at least one explicit binding/,
  );
}


{
  const module=parseV061Module(
    'def binders {α : Type}{{β : Type}}[inst : α](x : β) : β := x;',
  );
  const declaration=module.declarations[0];
  equal(declaration?.kind,'def');
  if(declaration?.kind==='def'){
    equal(declaration.params.map((p)=>p.binderInfo??'default').join(','),
      'implicit,strictImplicit,instImplicit,default');
  }
  equal(
    lowerV061ModuleToLean(module),
    'def binders {α : Type} {{β : Type}} [inst : α] (x : β) : β := x\n',
  );
}
{
  throws(
    ()=>parseV061Module(
      'function onlyImplicit {α : Type} : Type := α;',
    ),
    /function requires at least one D-EXPLICIT-PARAMS group/,
  );
}


{
  const module=parseV061Module(
    'theorem exactProof(P : Prop, h : P) : P := by exact h;',
  );
  const body=module.declarations[0]?.body;
  equal(body?.kind,'by');
  if(body?.kind==='by'){
    equal(body.tactics.length,1);
    equal(body.tactics[0]?.kind,'exact');
  }
  equal(
    lowerV061ModuleToLean(module),
    'theorem exactProof (P : Prop) (h : P) : P := by exact h\n',
  );
}
{
  const module=parseV061Module(
    'theorem assumptionProof(P : Prop, h : P) : P := by assumption;',
  );
  const body=module.declarations[0]?.body;
  equal(body?.kind,'by');
  if(body?.kind==='by'){
    equal(body.tactics.length,1);
    equal(body.tactics[0]?.kind,'assumption');
  }
}


{
  const module=parseV061Module(
    'theorem introProof(P : Prop) : P -> P := by intro h; assumption;',
  );
  const body=module.declarations[0]?.body;
  equal(body?.kind,'by');
  if(body?.kind==='by'){
    equal(body.tactics.length,2);
    equal(body.tactics[0]?.kind,'intro');
    if(body.tactics[0]?.kind==='intro'){
      equal(body.tactics[0].name,'h');
    }
    equal(body.tactics[1]?.kind,'assumption');
  }
  equal(
    lowerV061ModuleToLean(module),
    'theorem introProof (P : Prop) : P -> P := by intro h; assumption\n',
  );
}
{
  const module=parseV061Module(
    'theorem applyProof(P : Prop, Q : Prop, f : P -> Q, h : P) : Q := '+
    'by apply f; assumption;',
  );
  const body=module.declarations[0]?.body;
  equal(body?.kind,'by');
  if(body?.kind==='by'){
    equal(body.tactics.length,2);
    equal(body.tactics[0]?.kind,'apply');
    if(body.tactics[0]?.kind==='apply'){
      equal(body.tactics[0].proof.kind,'reference');
    }
    equal(body.tactics[1]?.kind,'assumption');
  }
  equal(
    lowerV061ModuleToLean(module),
    'theorem applyProof (P : Prop) (Q : Prop) (f : P -> Q) (h : P) : Q := by apply f; assumption\n',
  );
}

{
  const module=parseV061Module(
    'theorem refineProof(P : Prop, Q : Prop, f : P -> Q, h : P) : Q := '+
    'by refine f(?_); assumption;',
  );
  const body=module.declarations[0]?.body;
  equal(body?.kind,'by');
  if(body?.kind==='by'){
    equal(body.tactics.length,2);
    equal(body.tactics[0]?.kind,'refine');
    if(body.tactics[0]?.kind==='refine'){
      equal(body.tactics[0].proof.kind,'call');
      if(body.tactics[0].proof.kind==='call'){
        equal(body.tactics[0].proof.args[0]?.kind,'syntheticHole');
      }
    }
  }
  equal(
    lowerV061ModuleToLean(module),
    'theorem refineProof (P : Prop) (Q : Prop) (f : P -> Q) (h : P) : Q := by refine f ?_; assumption\n',
  );
}

{
  const module=parseV061Module(
    'theorem ctorProof : Choice := by constructor;',
  );
  const body=module.declarations[0]?.body;
  equal(body?.kind,'by');
  if(body?.kind==='by'){
    equal(body.tactics.length,1);
    equal(body.tactics[0]?.kind,'constructor');
  }
  equal(
    lowerV061ModuleToLean(module),
    'theorem ctorProof : Choice := by constructor\n',
  );
}

{
  const module=parseV061Module(
    'theorem casesProof(c : Choice) : P := by cases c; assumption; assumption;',
  );
  const body=module.declarations[0]?.body;
  equal(body?.kind,'by');
  if(body?.kind==='by'){
    equal(body.tactics.length,3);
    equal(body.tactics[0]?.kind,'cases');
    if(body.tactics[0]?.kind==='cases'){
      equal(body.tactics[0].target,'c');
    }
  }
  equal(
    lowerV061ModuleToLean(module),
    'theorem casesProof (c : Choice) : P := by cases c; assumption; assumption\n',
  );
}

{
  const module=parseV061Module(
    'theorem inductionProof(xs : Chain) : P := '+
    'by induction xs; assumption; assumption;',
  );
  const body=module.declarations[0]?.body;
  equal(body?.kind,'by');
  if(body?.kind==='by'){
    equal(body.tactics.length,3);
    equal(body.tactics[0]?.kind,'induction');
    if(body.tactics[0]?.kind==='induction'){
      equal(body.tactics[0].target,'xs');
    }
  }
  equal(
    lowerV061ModuleToLean(module),
    'theorem inductionProof (xs : Chain) : P := by induction xs; assumption; assumption\n',
  );
}

{
  const module=parseV061Module(
    'theorem exactSearchProof(P : Prop, h : P) : P := by exact?;',
  );
  const body=module.declarations[0]?.body;
  equal(body?.kind,'by');
  if(body?.kind==='by'){
    equal(body.tactics.length,1);
    equal(body.tactics[0]?.kind,'exactSearch');
  }
  equal(
    lowerV061ModuleToLean(module),
    'theorem exactSearchProof (P : Prop) (h : P) : P := by exact?\n',
  );
}

{
  const module=parseV061Module(
    'theorem rwProof(a : Nat, b : Nat, h : a = b) : a = b := '+
    'by rw [h]; rw [← h]; assumption;',
  );
  const body=module.declarations[0]?.body;
  equal(body?.kind,'by');
  if(body?.kind==='by'){
    equal(body.tactics.length,3);
    equal(body.tactics[0]?.kind,'rw');
    equal(body.tactics[1]?.kind,'rw');
    if(body.tactics[0]?.kind==='rw')equal(body.tactics[0].symm,false);
    if(body.tactics[1]?.kind==='rw')equal(body.tactics[1].symm,true);
  }
  equal(
    lowerV061ModuleToLean(module),
    'theorem rwProof (a : Nat) (b : Nat) (h : a = b) : a = b := '+
    'by rw [h]; rw [← h]; assumption\n',
  );
}

{
  const module=parseV061Module(
    'theorem succEq(a : Nat, h : Nat.succ(a) = a) : '+
    'Nat.succ(a) = a := by rw [h];',
  );
  equal(
    lowerV061ModuleToLean(module),
    'theorem succEq (a : Nat) (h : Nat.succ a = a) : '+
    'Nat.succ a = a := by rw [h]\n',
  );
}

{
  const module=parseV061Module(
    'theorem addZero(n : Nat, h : n + 0 = n) : n + 0 = n := by rw [h];',
  );
  equal(
    lowerV061ModuleToLean(module),
    'theorem addZero (n : Nat) (h : n + 0 = n) : n + 0 = n := by rw [h]\n',
  );
}

{
  const module=parseV061Module(
    'theorem leAssumed(x : Nat, y : Nat, h : x <= y) : '+
    'x <= y := by assumption;',
  );
  equal(
    lowerV061ModuleToLean(module),
    'theorem leAssumed (x : Nat) (y : Nat) (h : x <= y) : '+
    'x <= y := by assumption\n',
  );
}
{
  const module=parseV061Module(
    'theorem reversedRelations(x : Nat, y : Nat, h1 : x > y, h2 : x >= y) : '+
    'x > y := by assumption;',
  );
  equal(
    lowerV061ModuleToLean(module),
    'theorem reversedRelations (x : Nat) (y : Nat) (h1 : x > y) '+
    '(h2 : x >= y) : x > y := by assumption\n',
  );
}

{
  const module=parseV061Module(
    'theorem beqAssumed(x : Nat, y : Nat, h : x == y = true) : '+
    'x == y = true := by assumption;',
  );
  equal(
    lowerV061ModuleToLean(module),
    'theorem beqAssumed (x : Nat) (y : Nat) (h : (x == y) = true) : '+
    '(x == y) = true := by assumption\n',
  );
}
{
  const module=parseV061Module(
    'theorem boolLogicAssumed(p : Bool, q : Bool, h : !p || q = true) : '+
    '!p || q = true := by assumption;',
  );
  equal(
    lowerV061ModuleToLean(module),
    'theorem boolLogicAssumed (p : Bool) (q : Bool) '+
    '(h : (!p || q) = true) : (!p || q) = true := by assumption\n',
  );
}

throws(
  ()=>parseV061Module(
    'theorem badEq(a : Nat, b : Nat, c : Nat) : a = b = c := by assumption;',
  ),
  /propositional equality is non-associative/,
);

{
  const module=parseV061Module(
    'const depFn : (x : Nat) -> Fin(x) -> Nat := fun x => fun i => x;',
  );
  equal(
    lowerV061ModuleToLean(module),
    'def depFn : (x : Nat) -> Fin x -> Nat := fun x => fun i => x\n',
  );
}

{
  const module=parseV061Module(
    'theorem simpProof(A : Type, B : Type, C : Type, D : Type, '+
    'h1 : BoxT(A) = B, h2 : WrapT(C) = D) : P := '+
    'by simp only [h1, ← h2];',
  );
  const body=module.declarations[0]?.body;
  equal(body?.kind,'by');
  if(body?.kind==='by'){
    equal(body.tactics.length,1);
    equal(body.tactics[0]?.kind,'simp');
    if(body.tactics[0]?.kind==='simp'){
      equal(body.tactics[0].rules.length,2);
      equal(body.tactics[0].rules[0]?.symm,false);
      equal(body.tactics[0].rules[1]?.symm,true);
    }
  }
  equal(
    lowerV061ModuleToLean(module),
    'theorem simpProof (A : Type) (B : Type) (C : Type) (D : Type) '+
    '(h1 : BoxT A = B) (h2 : WrapT C = D) : P := '+
    'by simp only [h1, ← h2]\n',
  );
}


{
  const module=parseV061Module(
    'instance boxedNat : Boxed(Nat) := { value := 0 : Boxed(Nat) };',
  );
  const declaration=module.declarations[0];
  equal(declaration?.kind,'instance');
  if(declaration?.kind==='instance'){
    equal(declaration.name,'boxedNat');
    equal(declaration.anonymous,false);
    equal(declaration.params.length,0);
  }
  equal(
    lowerV061ModuleToLean(module),
    'instance boxedNat : Boxed Nat := { value := 0 : Boxed Nat }\n',
  );
}
{
  const module=parseV061Module(
    'instance : Boxed(Nat) := { value := 0 : Boxed(Nat) };',
  );
  const declaration=module.declarations[0];
  equal(declaration?.kind,'instance');
  if(declaration?.kind==='instance'){
    equal(declaration.anonymous,true);
    equal(declaration.name.startsWith('__ps_inst_'),true);
  }
  equal(
    lowerV061ModuleToLean(module),
    'instance : Boxed Nat := { value := 0 : Boxed Nat }\n',
  );
}
{
  const proofScript=parseV061Module(
    'def choose(p : Bool, a : Nat, b : Nat) : Nat := '+
    'if (p) { a } else { b }; '+
    'theorem exactSearchProof(P : Prop, h : P) : P := by exact?;',
  );
  const lean=lowerV061ModuleToLean(proofScript);
  const parsed=parseV061LeanSubsetModule(lean);
  equal(lowerV061ModuleToLean(parsed),lean);
  equal(
    lowerV061ModuleToProofScript(parsed),
    'def choose(p : Bool, a : Nat, b : Nat) : Nat := if (p) { a } else { b };\n\n'+
    'theorem exactSearchProof(P : Prop, h : P) : P := by exact?;\n',
  );
}
{
  const lean=
    'def applyTwo (f : Nat -> Nat) (x : Nat) : Nat := f x\n\n'+
    'theorem rewriteProof (a : Nat) (b : Nat) (h : a = b) : a = b := '+
    'by rw [h]\n';
  const parsed=parseV061LeanSubsetModule(lean);
  equal(lowerV061ModuleToLean(parsed),lean);
}
{
  const lean=
    'def local (x : Nat) : Nat := let y : Nat := x; y\n\n'+
    'def identity : Nat -> Nat := fun x => x\n';
  const parsed=parseV061LeanSubsetModule(lean);
  equal(lowerV061ModuleToLean(parsed),lean);
}
throws(
  ()=>parseV061LeanSubsetModule(
    'structure Box where\n  value : Nat\n',
  ),
  /PS_LEAN_SUBSET_UNSUPPORTED_COMMAND/,
);
throws(
  ()=>parseV061LeanSubsetModule(
    'def bad (x : Nat) : Nat := match x with\n  | 0 => 0\n',
  ),
  /PS_LEAN_SUBSET_UNSUPPORTED_TERM/,
);
{
  const registry=createDefaultSourceFrontendRegistry();
  equal(registry.get('lean-subset'),undefined);
  equal(leanSubsetSourceFrontend.kind,'lean-subset');
}
console.log('ok - @proofscript/syntax DS2.1 bounded Lean value frontend');

console.log('ok - @proofscript/syntax inherited instance declarations');
