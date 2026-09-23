import {
  V061_BASELINE_FEATURE_IDS,
  V061ExpressionParser,
  V061ParseContext,
  lowerDCallSource,
  lowerV061ExprToLean,
  lowerV061ModuleToLean,
  parseV061Module,
} from '../src/index.js';

function equal(actual:unknown,expected:unknown,label:string):void{
  if(actual!==expected){
    throw new Error(label+': expected '+JSON.stringify(expected)+', got '+JSON.stringify(actual));
  }
}

function sorted(ids:readonly string[]):string {
  return [...ids].sort().join(',');
}

function lowerModule(source:string):{
  readonly lean:string;
  readonly featureIds:readonly string[];
} {
  const module=parseV061Module(source);
  return {
    lean:lowerV061ModuleToLean(module).trimEnd(),
    featureIds:module.featureIds,
  };
}

function lowerExpression(source:string):{
  readonly lean:string;
  readonly featureIds:readonly string[];
} {
  const context=new V061ParseContext(source);
  const parser=new V061ExpressionParser(context);
  const expression=parser.parse();
  if(!context.cursor.done){
    throw new Error(
      "expression conformance case left trailing token '"+context.cursor.peek().text+"'",
    );
  }
  return {
    lean:lowerV061ExprToLean(expression),
    featureIds:[...context.features],
  };
}

const covered=new Set<string>();

function cover(...ids:readonly string[]):void{
  for(const id of ids)covered.add(id);
}

const moduleCases=[
  {
    id:'const-value',
    source:'const answer : Nat := 42;',
    expected:'def answer : Nat := 42',
    covers:['D-CONST-ALIAS','D-DECL-SEMI'] as const,
  },
  {
    id:'const-function-value',
    source:'const increment : Nat -> Nat := fun x => x + 1;',
    expected:'def increment : Nat -> Nat := fun x => x + 1',
    covers:['D-CONST-ALIAS','D-DECL-SEMI'] as const,
  },
  {
    id:'function-add',
    source:'function add(x : Nat, y : Nat) : Nat := x + y;',
    expected:'def add (x : Nat) (y : Nat) : Nat := x + y',
    covers:['D-FUNCTION-ALIAS','D-EXPLICIT-PARAMS','D-DECL-SEMI'] as const,
  },
  {
    id:'def-general',
    source:'def mul(x : Nat, y : Nat) : Nat := x * y;',
    expected:'def mul (x : Nat) (y : Nat) : Nat := x * y',
    covers:['D-EXPLICIT-PARAMS','D-DECL-SEMI'] as const,
  },
  {
    id:'structure-body',
    source:'structure Point where { x : Float; y : Float; }',
    expected:'structure Point where\n  x : Float\n  y : Float',
    covers:['E-STRUCT-BODY','D-DECL-SEMI'] as const,
  },
  {
    id:'structure-implicit-field',
    source:'structure Box where { {α : Type}; value : α; }',
    expected:'structure Box where\n  {α : Type}\n  value : α',
    covers:['E-STRUCT-BODY','D-DECL-SEMI'] as const,
  },
  {
    id:'inductive-body',
    source:'inductive Option(α : Type) where { | none; | some(value : α); }',
    expected:'inductive Option (α : Type) where\n  | none\n  | some (value : α)',
    covers:['E-INDUCTIVE-BODY','D-EXPLICIT-PARAMS','D-DECL-SEMI'] as const,
  },
  {
    id:'where-body',
    source:'def f(x : Nat) : Nat := helper(x) where { helper(y : Nat) : Nat := y + 1; }',
    expected:'def f (x : Nat) : Nat := helper x where\n  helper (y : Nat) : Nat := y + 1',
    covers:['E-WHERE-BODY','D-EXPLICIT-PARAMS','D-CALL','D-DECL-SEMI'] as const,
  },
  {
    id:'class-body',
    source:'class Sized(α : Type) where { size : α -> Nat; }',
    expected:'class Sized (α : Type) where\n  size : α -> Nat',
    covers:['E-CLASS-BODY','D-EXPLICIT-PARAMS','D-DECL-SEMI'] as const,
  },
] as const;

for(const entry of moduleCases){
  const actual=lowerModule(entry.source);
  equal(actual.lean,entry.expected,entry.id);
  equal(sorted(actual.featureIds),sorted(entry.covers),entry.id+' feature ownership');
  cover(...actual.featureIds);
}

for(const entry of [
  {
    id:'braced-if',
    source:'if (x > y) { x } else { y }',
    expected:'if x > y then x else y',
    covers:['E-IF-BRACE'] as const,
  },
  {
    id:'match-body',
    source:'match value with { | .none => 0; | .some x => f(x); }',
    expected:'match value with\n  | .none => 0\n  | .some x => f x',
    covers:['E-MATCH-BODY','D-CALL','D-DECL-SEMI'] as const,
  },
] as const){
  const actual=lowerExpression(entry.source);
  equal(actual.lean,entry.expected,entry.id);
  equal(sorted(actual.featureIds),sorted(entry.covers),entry.id+' feature ownership');
  cover(...actual.featureIds);
}

for(const entry of [
  {id:'adjacent-call-two',source:'add(1, 2)',expected:'add 1 2',covers:['D-CALL'] as const},
  {id:'tuple-argument',source:'f((x, y))',expected:'f (x, y)',covers:['D-CALL'] as const},
] as const){
  const lowered=lowerDCallSource(entry.source);
  equal(lowered.kind,'proofscript',entry.id+' ownership');
  if(lowered.kind==='proofscript'){
    equal(lowered.node.leanText,entry.expected,entry.id);
  }
  cover(...entry.covers);
}

const inherited=lowerDCallSource('f (x)');
equal(inherited.kind,'defer','L-CORE-LEAN protected neighbor');
cover('L-CORE-LEAN');

const missing=V061_BASELINE_FEATURE_IDS.filter((id)=>!covered.has(id));
equal(missing.join(','),'','v0.6.1 feature coverage');
equal(covered.size,V061_BASELINE_FEATURE_IDS.length,'v0.6.1 exact feature coverage');

console.log(
  'ok - v0.6.1 feature-complete lowering corpus ('+
  V061_BASELINE_FEATURE_IDS.length+' registered features)',
);
