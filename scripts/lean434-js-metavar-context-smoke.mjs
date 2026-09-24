import fs from 'node:fs';
import {
  Lean4ExportReplay,
  anonymous,
  exprEq,
  nameFromDotted,
  natLit,
  numName,
  strName,
  constant,
} from '../dist/src/index.js';
import {
  Lean434Evaluator,
} from '../packages/runtime/dist/src/lean4-eval.js';
import {
  kernelExprToLean434Runtime,
  lean434RuntimeExprToKernel,
} from '../packages/runtime/dist/src/lean4-expr.js';
import {
  emptyLean434MetavarContext,
  lean434RuntimeMVarId,
  lean434RuntimeOptionValue,
} from '../packages/runtime/dist/src/lean4-mctx.js';

const fixture=process.argv[2]??'lean434-metavar-context-bootstrap.ndjson';
if(!fs.existsSync(fixture)){
  throw new Error('missing generated Lean.MetavarContext fixture: '+fixture);
}
const preludeFixture='oracle/fixtures/lean434-init-prelude.ndjson';
if(!fs.existsSync(preludeFixture)){
  throw new Error('missing pinned Lean 4.34 Init.Prelude fixture');
}

const prelude=new Lean4ExportReplay();
prelude.replay(fs.readFileSync(preludeFixture,'utf8'));
const replay=new Lean4ExportReplay(prelude.env);
const delta=fs.readFileSync(fixture,'utf8');
const stats=replay.replay(delta);
console.log(JSON.stringify({
  phase:'metavar-context-delta-replay',
  declarations:stats.declarations,
  environmentConstants:replay.env.size,
  bytes:Buffer.byteLength(delta),
}));

const evaluator=new Lean434Evaluator(
  replay.env,
  {maxSteps:250_000},
);

const mvarName=numName(strName(anonymous,'_m'),7n);
const mvarId=lean434RuntimeMVarId(mvarName);
const valueExpr=natLit(42n);
const runtimeExpr=kernelExprToLean434Runtime(valueExpr);
const empty=emptyLean434MetavarContext();

let getAssignment=evaluator.evaluate(
  constant(nameFromDotted('Lean.MetavarContext.getExprAssignmentExp')),
);
getAssignment=evaluator.applyRuntimeValue(getAssignment,empty);
let before=evaluator.applyRuntimeValue(getAssignment,mvarId);
if(lean434RuntimeOptionValue(before)!==undefined){
  throw new Error(
    'empty Lean.MetavarContext unexpectedly contained an expression assignment',
  );
}

let assign=evaluator.evaluate(
  constant(nameFromDotted('Lean.MetavarContext.assignExp')),
);
assign=evaluator.applyRuntimeValue(assign,empty);
assign=evaluator.applyRuntimeValue(assign,mvarId);
const assigned=evaluator.applyRuntimeValue(assign,runtimeExpr);

let getAfter=evaluator.evaluate(
  constant(nameFromDotted('Lean.MetavarContext.getExprAssignmentExp')),
);
getAfter=evaluator.applyRuntimeValue(getAfter,assigned);
const queried=evaluator.applyRuntimeValue(getAfter,mvarId);
const runtimeAssigned=lean434RuntimeOptionValue(queried);
if(runtimeAssigned===undefined){
  throw new Error(
    'real Lean.MetavarContext.assignExp did not persist the assignment',
  );
}
const actual=lean434RuntimeExprToKernel(runtimeAssigned);
if(!exprEq(actual,valueExpr)){
  throw new Error(
    'real Lean.MetavarContext.getExprAssignmentExp returned the wrong expression',
  );
}

let getOriginal=evaluator.evaluate(
  constant(nameFromDotted('Lean.MetavarContext.getExprAssignmentExp')),
);
getOriginal=evaluator.applyRuntimeValue(getOriginal,empty);
const originalStillEmpty=evaluator.applyRuntimeValue(getOriginal,mvarId);
if(lean434RuntimeOptionValue(originalStillEmpty)!==undefined){
  throw new Error(
    'Lean persistent MetavarContext assignment mutated the original context',
  );
}

console.log(
  'ok - real Lean.MetavarContext.assignExp/getExprAssignmentExp execute in JS',
);
console.log(
  'ok - Lean metavariable assignment preserves PersistentHashMap value semantics',
);
