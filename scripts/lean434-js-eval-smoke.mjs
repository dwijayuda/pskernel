import fs from 'node:fs';
import {
  Lean4ExportReplay,
  TypeChecker,
  constant,
  levelSucc,
  levelZero,
  mkAppN,
  nameFromDotted,
  natLit,
  nameToString,
  strLit,
} from '../dist/src/index.js';
import {Lean434Evaluator} from '../packages/runtime/dist/src/lean4-eval.js';

const fixture='oracle/fixtures/lean434-init-prelude.ndjson';
if(!fs.existsSync(fixture)){
  throw new Error('missing pinned Lean 4.34 Init.Prelude fixture');
}

const replay=new Lean4ExportReplay();
replay.replay(fs.readFileSync(fixture,'utf8'));
const env=replay.env;
const checker=new TypeChecker(env);
const evaluator=new Lean434Evaluator(env);

const Nat=nameFromDotted('Nat');

function assertNatResult(label,expr,expected){
  const type=checker.check(expr);
  if(type.kind!=='const'||nameToString(type.name)!=='Nat'){
    throw new Error(label+' did not typecheck as Nat');
  }
  const value=evaluator.evaluate(expr);
  if(value!==expected){
    throw new Error(
      label+' expected '+String(expected)+', got '+String(value),
    );
  }
  console.log('ok - '+label+' = '+String(value));
}

assertNatResult(
  'real Init.Prelude Nat.add runtime override',
  mkAppN(
    constant(nameFromDotted('Nat.add')),
    [natLit(20n),natLit(22n)],
  ),
  42n,
);

assertNatResult(
  'real Lean-written id definition',
  mkAppN(
    constant(nameFromDotted('id'),[levelSucc(levelZero)]),
    [constant(Nat),natLit(42n)],
  ),
  42n,
);

{
  const unsafeCastExpr=mkAppN(
    constant(
      nameFromDotted('unsafeCast'),
      [levelSucc(levelZero),levelSucc(levelZero)],
    ),
    [constant(Nat),constant(Nat),natLit(42n)],
  );
  const value=evaluator.evaluate(unsafeCastExpr);
  if(value!==42n){
    throw new Error(
      'real Lean unsafeCast runtime expected 42, got '+String(value),
    );
  }
  console.log(
    'ok - real Lean unsafeCast executes as runtime-only unsafe code = 42',
  );
}

const List=nameFromDotted('List');
const ListNil=nameFromDotted('List.nil');
const ListCons=nameFromDotted('List.cons');
const listNat=mkAppN(
  constant(List,[levelZero]),
  [constant(Nat)],
);
const nilNat=mkAppN(
  constant(ListNil,[levelZero]),
  [constant(Nat)],
);
const twoNat=mkAppN(
  constant(ListCons,[levelZero]),
  [
    constant(Nat),
    natLit(10n),
    mkAppN(
      constant(ListCons,[levelZero]),
      [constant(Nat),natLit(20n),nilNat],
    ),
  ],
);
const lengthTRAuxExpr=mkAppN(
  constant(nameFromDotted('List.lengthTRAux'),[levelZero]),
  [constant(Nat),twoNat,natLit(0n)],
);
assertNatResult(
  'real recursive Lean List.lengthTRAux',
  lengthTRAuxExpr,
  2n,
);

const emptyArrayNat=mkAppN(
  constant(nameFromDotted('Array.emptyWithCapacity'),[levelZero]),
  [constant(Nat),natLit(4n)],
);
const pushedArrayNat=mkAppN(
  constant(nameFromDotted('Array.push'),[levelZero]),
  [constant(Nat),emptyArrayNat,natLit(7n)],
);
assertNatResult(
  'real Lean Array.size after extern-backed push',
  mkAppN(
    constant(nameFromDotted('Array.size'),[levelZero]),
    [constant(Nat),pushedArrayNat],
  ),
  1n,
);

assertNatResult(
  'real Lean String.utf8ByteSize extern',
  mkAppN(
    constant(nameFromDotted('String.utf8ByteSize')),
    [strLit('L∃∀N')],
  ),
  8n,
);

console.log(
  'ok - pinned Lean 4.34 Init.Prelude executes through pskernel + JavaScript runtime',
);
