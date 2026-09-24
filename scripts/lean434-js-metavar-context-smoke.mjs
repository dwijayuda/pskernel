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
  levelZero,
} from '../dist/src/index.js';
import {
  Lean434Evaluator,
} from '../packages/runtime/dist/src/lean4-eval.js';
import {
  Lean434RuntimeMetadataIndex,
  parseLean434RuntimeMetadata,
} from '../packages/runtime/dist/src/lean4-metadata.js';
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
const metadataFixture=
  process.argv[3]??'lean434-metavar-context-runtime-metadata.json';
if(!fs.existsSync(fixture)){
  throw new Error('missing generated Lean.MetavarContext fixture: '+fixture);
}
if(!fs.existsSync(metadataFixture)){
  throw new Error(
    'missing Lean.MetavarContext runtime metadata: '+metadataFixture,
  );
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

const metadata=new Lean434RuntimeMetadataIndex(
  parseLean434RuntimeMetadata(
    JSON.parse(fs.readFileSync(metadataFixture,'utf8')),
  ),
);
const insertAuxImplementedBy=
  metadata.implementedByFor('Lean.PersistentHashMap.insertAux');
const insertAuxRuntimeTarget=
  metadata.runtimeTargetFor('Lean.PersistentHashMap.insertAux');
console.log(JSON.stringify({
  phase:'metavar-context-runtime-metadata',
  insertAuxImplementedBy:insertAuxImplementedBy?.implementation??null,
  insertAuxRuntimeTarget:insertAuxRuntimeTarget??null,
}));
const evaluator=new Lean434Evaluator(
  replay.env,
  {maxSteps:250_000,metadata},
);

{
  let modify=evaluator.evaluate(
    constant(nameFromDotted('Array.modify'),[levelZero]),
  );
  modify=evaluator.applyRuntimeValue(
    modify,
    evaluator.evaluate(constant(nameFromDotted('Nat'))),
  );
  modify=evaluator.applyRuntimeValue(modify,[1n,2n,3n]);
  modify=evaluator.applyRuntimeValue(modify,1n);
  const modified=evaluator.applyRuntimeValue(
    modify,
    evaluator.evaluate(constant(nameFromDotted('Nat.succ'))),
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

const emptyExprMap=
  empty.kind==='constructor'?empty.fields[8]:undefined;
if(
  emptyExprMap?.kind!=='constructor'
  ||emptyExprMap.name!=='Lean.PersistentHashMap.mk'
){
  throw new Error('empty MetavarContext eAssignment is not a PersistentHashMap');
}

let firstBucket=evaluator.evaluate(
  constant(nameFromDotted('ProofScript.RuntimeProbe.firstBucketIndex')),
);
const bucket=evaluator.applyRuntimeValue(firstBucket,mvarId);
if(typeof bucket!=='bigint'||bucket<0n||bucket>=32n){
  throw new Error(
    'real Lean PersistentHashMap produced invalid first bucket: '+String(bucket),
  );
}
console.log(JSON.stringify({
  phase:'metavar-context-map-bucket',
  bucket:String(bucket),
}));

const emptyRoot=emptyExprMap.fields[0];
if(
  emptyRoot?.kind!=='constructor'
  ||emptyRoot.name!=='Lean.PersistentHashMap.Node.entries'
  ||!Array.isArray(emptyRoot.fields[0])
){
  throw new Error('empty expression map root is not an entries node');
}
const emptyEntries=emptyRoot.fields[0];

let replaceNull=evaluator.evaluate(
  constant(nameFromDotted('ProofScript.RuntimeProbe.replaceNullEntry')),
);
replaceNull=evaluator.applyRuntimeValue(replaceNull,emptyEntries);
replaceNull=evaluator.applyRuntimeValue(replaceNull,bucket);
replaceNull=evaluator.applyRuntimeValue(replaceNull,mvarId);
const replacedEntries=evaluator.applyRuntimeValue(replaceNull,runtimeExpr);
const replacedEntry=replacedEntries[Number(bucket)];
if(
  replacedEntry?.kind!=='constructor'
  ||replacedEntry.name!=='Lean.PersistentHashMap.Entry.entry'
){
  throw new Error(
    'real Lean Entry.null match/Array.modify did not produce Entry.entry',
  );
}
console.log(
  'ok - real Lean Entry.null match updates the expected hash-map bucket',
);

let insertMap=evaluator.evaluate(
  constant(nameFromDotted('ProofScript.RuntimeProbe.insertExprMap')),
);
insertMap=evaluator.applyRuntimeValue(insertMap,emptyExprMap);
insertMap=evaluator.applyRuntimeValue(insertMap,mvarId);
const directlyInserted=evaluator.applyRuntimeValue(insertMap,runtimeExpr);
const directRoot=
  directlyInserted?.kind==='constructor'
    ?directlyInserted.fields[0]
    :undefined;
const directEntries=
  directRoot?.kind==='constructor'
  &&directRoot.name==='Lean.PersistentHashMap.Node.entries'
  &&Array.isArray(directRoot.fields[0])
    ?directRoot.fields[0]
    :undefined;
const directEntry=directEntries?.[Number(bucket)];
console.log(JSON.stringify({
  phase:'metavar-context-direct-map-insert',
  rootName:directRoot?.kind==='constructor'?directRoot.name:undefined,
  bucket:String(bucket),
  entryName:directEntry?.kind==='constructor'?directEntry.name:undefined,
}));
if(
  directEntry?.kind!=='constructor'
  ||directEntry.name!=='Lean.PersistentHashMap.Entry.entry'
){
  throw new Error(
    'real Lean PersistentHashMap.insert did not populate its computed bucket',
  );
}

let findMap=evaluator.evaluate(
  constant(nameFromDotted('ProofScript.RuntimeProbe.findExprMap?')),
);
findMap=evaluator.applyRuntimeValue(findMap,directlyInserted);
const directFound=evaluator.applyRuntimeValue(findMap,mvarId);
if(lean434RuntimeOptionValue(directFound)===undefined){
  throw new Error(
    'real Lean PersistentHashMap.find? missed a directly inserted key',
  );
}
console.log('ok - real Lean PersistentHashMap insert/find? round-trip in JS');

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
    constant(nameFromDotted('Name.beq')),
  );
  nameBeq=evaluator.applyRuntimeValue(nameBeq,mvarId.fields[0]);
  const sameName=evaluator.applyRuntimeValue(nameBeq,mvarId.fields[0]);
  console.log(JSON.stringify({
    phase:'metavar-context-name-beq',
    sameName,
  }));

  const summarizeMap=(value)=>{
    const root=value?.kind==='constructor'
      &&value.name==='Lean.PersistentHashMap.mk'
        ?value.fields[0]
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
    return {
      valueKind:value?.kind,
      valueName:value?.kind==='constructor'?value.name:undefined,
      rootKind:root?.kind,
      rootName:root?.kind==='constructor'?root.name:undefined,
      entries:entries?.length,
      occupied,
      samples:entries?.slice(0,4).map((entry)=>(
        entry?.kind==='constructor'
          ?{kind:entry.kind,name:entry.name,fields:entry.fields.length}
          :{kind:typeof entry}
      )),
    };
  };
  const mapFields=[4,5,6,7,8,9].map((index)=>({
    index,
    before:summarizeMap(
      empty?.kind==='constructor'?empty.fields[index]:undefined,
    ),
    after:summarizeMap(
      assigned?.kind==='constructor'?assigned.fields[index]:undefined,
    ),
  }));
  console.log(JSON.stringify({
    phase:'metavar-context-map-shape',
    assignedKind:assigned?.kind,
    assignedFields:assigned?.kind==='constructor'
      ?assigned.fields.length
      :undefined,
    mapFields,
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
