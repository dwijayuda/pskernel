import fs from 'node:fs';
import {
  Lean4ExportReplay,
  constant,
  exprEq,
  mkAppN,
  nameFromDotted,
  natLit,
} from '../dist/src/index.js';
import {
  Lean434Evaluator,
} from '../packages/runtime/dist/src/lean4-eval.js';
import {
  kernelExprToLean434Runtime,
  lean434RuntimeExprToKernel,
} from '../packages/runtime/dist/src/lean4-expr.js';

const fixture=process.argv[2]??'lean434-expr-bootstrap.ndjson';
if(!fs.existsSync(fixture)){
  throw new Error('missing generated Lean.Expr fixture: '+fixture);
}

const preludeFixture='oracle/fixtures/lean434-init-prelude.ndjson';
if(!fs.existsSync(preludeFixture)){
  throw new Error('missing pinned Lean 4.34 Init.Prelude fixture');
}

const prelude=new Lean4ExportReplay();
prelude.replay(fs.readFileSync(preludeFixture,'utf8'));
const replay=new Lean4ExportReplay(prelude.env);
replay.replay(fs.readFileSync(fixture,'utf8'));

const evaluator=new Lean434Evaluator(replay.env);
const source=mkAppN(
  constant(nameFromDotted('Nat.add')),
  [natLit(20n),natLit(22n)],
);
const runtimeSource=kernelExprToLean434Runtime(source);

let getAppFn=evaluator.evaluate(
  constant(nameFromDotted('Lean.Expr.getAppFn')),
);
const runtimeFn=evaluator.applyRuntimeValue(getAppFn,runtimeSource);
const actualFn=lean434RuntimeExprToKernel(runtimeFn);
const expectedFn=constant(nameFromDotted('Nat.add'));
if(!exprEq(actualFn,expectedFn)){
  throw new Error(
    'real Lean.Expr.getAppFn disagrees with pskernel expression structure',
  );
}
console.log(
  'ok - real Lean.Expr.getAppFn executes through canonical pskernel Expr bridge',
);

let getAppNumArgs=evaluator.evaluate(
  constant(nameFromDotted('Lean.Expr.getAppNumArgs')),
);
const argc=evaluator.applyRuntimeValue(getAppNumArgs,runtimeSource);
if(argc!==2n){
  throw new Error(
    'real Lean.Expr.getAppNumArgs expected 2, got '+String(argc),
  );
}
console.log(
  'ok - real Lean.Expr.getAppNumArgs executes on bridged pskernel Expr',
);
