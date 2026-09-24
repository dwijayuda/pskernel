import fs from 'node:fs';
import {
  Lean4ExportReplay,
  app,
  bvar,
  constant,
  lam,
  levelZero,
  mkAppN,
  nameFromDotted,
  natLit,
} from '../dist/src/index.js';
import {
  Lean434Evaluator,
} from '../packages/runtime/dist/src/lean4-eval.js';
import {
  LeanRef,
  lean_st_ref_get,
} from '../packages/runtime/dist/src/lean4.js';

const fixture=process.argv[2]??'lean434-runtime-st-bootstrap.ndjson';
if(!fs.existsSync(fixture)){
  throw new Error('missing generated Lean ST/IO bootstrap fixture: '+fixture);
}

const replay=new Lean4ExportReplay();
replay.replay(fs.readFileSync(fixture,'utf8'));
const evaluator=new Lean434Evaluator(replay.env);

const Nat=constant(nameFromDotted('Nat'));
const ioMkRef=mkAppN(
  constant(nameFromDotted('IO.mkRef'),[levelZero]),
  [Nat,natLit(41n)],
);
const allocated=evaluator.runIOAction(evaluator.evaluate(ioMkRef)).value;
if(!(allocated instanceof LeanRef)){
  throw new Error('real Lean IO.mkRef did not allocate a LeanRef');
}
if(lean_st_ref_get(allocated)!==41n){
  throw new Error('real Lean IO.mkRef stored the wrong initial value');
}
console.log('ok - real Lean-written IO.mkRef executes over JS ST primitive');

const x=nameFromDotted('x');
const increment=lam(
  x,
  Nat,
  mkAppN(
    constant(nameFromDotted('Nat.add')),
    [bvar(0),natLit(1n)],
  ),
);
const modifyExpr=mkAppN(
  constant(nameFromDotted('ST.Prim.Ref.modify'),[levelZero,levelZero]),
  [
    constant(nameFromDotted('IO.RealWorld')),
    Nat,
    allocated,
    increment,
  ],
);
const modifyAction=evaluator.evaluate(modifyExpr);
evaluator.runStateAction(modifyAction);
if(lean_st_ref_get(allocated)!==42n){
  throw new Error(
    'real Lean ST.Prim.Ref.modify did not execute get/bind/set semantics',
  );
}
console.log(
  'ok - real Lean-written ST.Prim.Ref.modify executes through Lean bind + JS refs',
);
