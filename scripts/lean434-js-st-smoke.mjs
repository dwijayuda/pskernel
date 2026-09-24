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

const worldType=constant(nameFromDotted('IO.RealWorld'));
const worldToken=evaluator.evaluate(worldType);
const natTypeToken=evaluator.evaluate(Nat);
if(
  typeof worldToken!=='object'||worldToken===null||
  Array.isArray(worldToken)||worldToken.kind!=='type'
){
  throw new Error('IO.RealWorld was not erased to a runtime type token');
}
if(
  typeof natTypeToken!=='object'||natTypeToken===null||
  Array.isArray(natTypeToken)||natTypeToken.kind!=='type'
){
  throw new Error('Nat was not erased to a runtime type token');
}
console.log('ok - real Lean type constants erase to runtime type tokens');

let manualGet=evaluator.evaluate(
  constant(nameFromDotted('ST.Prim.Ref.get'),[levelZero,levelZero]),
);
manualGet=evaluator.applyRuntimeValue(manualGet,worldToken);
manualGet=evaluator.applyRuntimeValue(manualGet,natTypeToken);
manualGet=evaluator.applyRuntimeValue(manualGet,allocated);
const manualGetValue=evaluator.runStateAction(manualGet).value;
if(manualGetValue!==41n){
  throw new Error(
    'manual real Lean ST.Prim.Ref.get returned '+
    String(manualGetValue)+' instead of 41',
  );
}
console.log('ok - manual real Lean ST.Prim.Ref.get runtime application works');

const getExpr=mkAppN(
  constant(nameFromDotted('ST.Prim.Ref.get'),[levelZero,levelZero]),
  [worldType,Nat,allocated],
);
const directGet=evaluator.runStateAction(evaluator.evaluate(getExpr)).value;
if(directGet!==41n){
  throw new Error(
    'real Lean ST.Prim.Ref.get returned '+String(directGet)+' instead of 41',
  );
}
console.log('ok - real Lean ST.Prim.Ref.get extern mapping receives the ref');

const setExpr=mkAppN(
  constant(nameFromDotted('ST.Prim.Ref.set'),[levelZero,levelZero]),
  [worldType,Nat,allocated,natLit(40n)],
);
evaluator.runStateAction(evaluator.evaluate(setExpr));
if(lean_st_ref_get(allocated)!==40n){
  throw new Error('real Lean ST.Prim.Ref.set did not update the ref');
}
console.log('ok - real Lean ST.Prim.Ref.set extern mapping receives the ref');

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
    worldType,
    Nat,
    allocated,
    increment,
  ],
);
const modifyAction=evaluator.evaluate(modifyExpr);
evaluator.runStateAction(modifyAction);
if(lean_st_ref_get(allocated)!==41n){
  throw new Error(
    'real Lean ST.Prim.Ref.modify did not execute get/bind/set semantics',
  );
}
console.log(
  'ok - real Lean-written ST.Prim.Ref.modify executes through Lean bind + JS refs',
);
