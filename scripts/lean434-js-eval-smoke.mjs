import fs from 'node:fs';
import {
  Lean4ExportReplay,
  TypeChecker,
  constant,
  levelZero,
  mkAppN,
  nameFromDotted,
  natLit,
  nameToString,
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
    constant(nameFromDotted('id'),[levelZero]),
    [constant(Nat),natLit(42n)],
  ),
  42n,
);

console.log(
  'ok - pinned Lean 4.34 Init.Prelude executes through pskernel + JavaScript runtime',
);
