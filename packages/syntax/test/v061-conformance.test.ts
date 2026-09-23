import {
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

function lowerModule(source:string):string {
  return lowerV061ModuleToLean(parseV061Module(source)).trimEnd();
}

function lowerExpression(source:string):string {
  const context=new V061ParseContext(source);
  const parser=new V061ExpressionParser(context);
  const expression=parser.parse();
  if(!context.cursor.done){
    throw new Error(
      "expression conformance case left trailing token '"+context.cursor.peek().text+"'",
    );
  }
  return lowerV061ExprToLean(expression);
}

const moduleCases=[
  {
    id:'const-value',
    source:'const answer : Nat := 42;',
    expected:'def answer : Nat := 42',
  },
  {
    id:'const-function-value',
    source:'const increment : Nat -> Nat := fun x => x + 1;',
    expected:'def increment : Nat -> Nat := fun x => x + 1',
  },
  {
    id:'function-add',
    source:'function add(x : Nat, y : Nat) : Nat := x + y;',
    expected:'def add (x : Nat) (y : Nat) : Nat := x + y',
  },
  {
    id:'def-general',
    source:'def mul(x : Nat, y : Nat) : Nat := x * y;',
    expected:'def mul (x : Nat) (y : Nat) : Nat := x * y',
  },
  {
    id:'structure-body',
    source:'structure Point where { x : Float; y : Float; }',
    expected:'structure Point where\n  x : Float\n  y : Float',
  },
  {
    id:'structure-implicit-field',
    source:'structure Box where { {α : Type}; value : α; }',
    expected:'structure Box where\n  {α : Type}\n  value : α',
  },
  {
    id:'inductive-body',
    source:'inductive Option(α : Type) where { | none; | some(value : α); }',
    expected:'inductive Option (α : Type) where\n  | none\n  | some (value : α)',
  },
  {
    id:'where-body',
    source:'def f(x : Nat) : Nat := helper(x) where { helper(y : Nat) : Nat := y + 1; }',
    expected:'def f (x : Nat) : Nat := helper x where\n  helper (y : Nat) : Nat := y + 1',
  },
] as const;

for(const entry of moduleCases){
  equal(lowerModule(entry.source),entry.expected,entry.id);
}

for(const entry of [
  {
    id:'braced-if',
    source:'if (x > y) { x } else { y }',
    expected:'if x > y then x else y',
  },
  {
    id:'match-body',
    source:'match value with { | .none => 0; | .some x => f(x); }',
    expected:'match value with\n  | .none => 0\n  | .some x => f x',
  },
] as const){
  equal(lowerExpression(entry.source),entry.expected,entry.id);
}

for(const entry of [
  {id:'adjacent-call-two',source:'add(1, 2)',expected:'add 1 2'},
  {id:'tuple-argument',source:'f((x, y))',expected:'f (x, y)'},
] as const){
  const lowered=lowerDCallSource(entry.source);
  equal(lowered.kind,'proofscript',entry.id+' ownership');
  if(lowered.kind==='proofscript'){
    equal(lowered.node.leanText,entry.expected,entry.id);
  }
}

console.log('ok - v0.6.1 authoritative 12-case lowering corpus');
