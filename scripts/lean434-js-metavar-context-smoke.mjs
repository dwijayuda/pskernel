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
console.log(JSON.stringify({
  phase:'metavar-context-delta-replay-start',
  bytes:Buffer.byteLength(delta),
}));
const stats=replay.replay(delta,{
  every:500,
  onProgress:(progress)=>console.log(JSON.stringify({
    phase:'metavar-context-delta-replay-progress',
    ...progress,
  })),
});
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

{
  let modify=evaluator.evaluate(
    constant(nameFromDotted('Array.modify')),
  );
  modify=evaluator.applyRuntimeValue(
    modify,
    evaluator.evaluate(constant(nameFromDotted('Nat'))),
  );
  modify=evaluator.applyRuntimeValue(modify,[1n,2n,3n]);
  modify=evaluator.applyRuntimeValue(modify,1n);
  modify=evaluator.applyRuntimeValue(
    modify,
    evaluator.evaluate(constant(nameFromDotted('Nat.succ'))),
  );
  const modified=evaluator.applyRuntimeValue(
    modify,
    evaluator.evaluate(constant(nameFromDotted('Nat.zero'))),
  );
  if(
    !Array.isArray(modified)
    ||modified.length!==3
    ||modified[0]!==1n
    ||modified[1]!==3n
    ||modified[2]!==3n
  ){
    throw new Error(
      'real Lean Array.modify did not update a JS-backed Lean array: '+
      JSON.stringify(modified,(_,v)=>typeof v==='bigint'?String(v)+'n':v),
    );
  }
  console.log(
    'ok - real Lean Array.modify updates through Array.set JS primitive',
  );
}

const mvarName=numName(strName(anonymous,'_m'),7n);
const mvarId=lean434RuntimeMVarId(mvarName);
const valueExpr=natLit(42n);
const runtimeExpr=kernelExprToLean434Runtime(valueExpr);
const empty=emptyLean434MetavarContext();

console.log(JSON.stringify({phase:'metavar-context-initial-lookup-start'}));
let getAssignment=evaluator.evaluate(
  constant(nameFromDotted('Lean.MetavarContext.getExprAssignmentExp')),
);
getAssignment=evaluator.applyRuntimeValue(getAssignment,empty);
let before=evaluator.applyRuntimeValue(getAssignment,mvarId);
console.log(JSON.stringify({phase:'metavar-context-initial-lookup-complete'}));
if(lean434RuntimeOptionValue(before)!==undefined){
  throw new Error(
    'empty Lean.MetavarContext unexpectedly contained an expression assignment',
  );
}

console.log(JSON.stringify({phase:'metavar-context-assign-start'}));
let assign=evaluator.evaluate(
  constant(nameFromDotted('Lean.assignExp')),
);
assign=evaluator.applyRuntimeValue(assign,empty);
assign=evaluator.applyRuntimeValue(assign,mvarId);
const assigned=evaluator.applyRuntimeValue(assign,runtimeExpr);
console.log(JSON.stringify({phase:'metavar-context-assign-complete'}));

{
  let nameBeq=evaluator.evaluate(
    constant(nameFromDotted('Lean.Name.beq')),
  );
  nameBeq=evaluator.applyRuntimeValue(nameBeq,mvarId.fields[0]);
  const sameName=evaluator.applyRuntimeValue(nameBeq,mvarId.fields[0]);
  console.log(JSON.stringify({
    phase:'metavar-context-name-beq',
    sameName,
  }));

  const eAssignment=assigned?.kind==='constructor'
    ?assigned.fields[8]
    :undefined;
  const root=
    eAssignment?.kind==='constructor'
      ?eAssignment.fields[0]
      :undefined;
  const entries=
    root?.kind==='constructor'
      &&root.name==='Lean.PersistentHashMap.Node.entries'
      &&Array.isArray(root.fields[0])
        ?root.fields[0]
        :undefined;
  const occupied=entries===undefined
    ?[]
    :entries.flatMap((entry,index)=>
      entry?.kind==='constructor'
      &&entry.name!=='Lean.PersistentHashMap.Entry.null'
        ?[{index,name:entry.name,fields:entry.fields.length}]
        :[]
    );
  console.log(JSON.stringify({
    phase:'metavar-context-map-shape',
    assignedKind:assigned?.kind,
    assignedFields:assigned?.kind==='constructor'
      ?assigned.fields.length
      :undefined,
    eAssignmentKind:eAssignment?.kind,
    eAssignmentName:eAssignment?.kind==='constructor'
      ?eAssignment.name
      :undefined,
    rootKind:root?.kind,
    rootName:root?.kind==='constructor'?root.name:undefined,
    entries:entries?.length,
    occupied,
  }));
}

console.log(JSON.stringify({phase:'metavar-context-post-lookup-start'}));
let getAfter=evaluator.evaluate(
  constant(nameFromDotted('Lean.MetavarContext.getExprAssignmentExp')),
);
getAfter=evaluator.applyRuntimeValue(getAfter,assigned);
const queried=evaluator.applyRuntimeValue(getAfter,mvarId);
const runtimeAssigned=lean434RuntimeOptionValue(queried);
console.log(JSON.stringify({phase:'metavar-context-post-lookup-complete'}));
if(runtimeAssigned===undefined){
  throw new Error(
    'real Lean.assignExp did not persist the assignment',
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
  'ok - real Lean.assignExp/getExprAssignmentExp execute in JS',
);
console.log(
  'ok - Lean metavariable assignment preserves PersistentHashMap value semantics',
);
