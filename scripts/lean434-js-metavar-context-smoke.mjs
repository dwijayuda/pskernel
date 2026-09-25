import fs from 'node:fs';
import {
  Lean4ExportReplay,
  anonymous,
  app,
  bvar,
  exprEq,
  fvar,
  forallE,
  lam,
  nameKey,
  nameFromDotted,
  natLit,
  numName,
  strName,
  constant,
  levelEqStructural,
  levelMVar,
  levelMaxRaw,
  levelSucc,
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
  lean434RuntimeLMVarId,
  lean434RuntimeMVarId,
  lean434RuntimeOptionValue,
} from '../packages/runtime/dist/src/lean4-mctx.js';
import {
  kernelLevelToLean434Runtime,
  lean434RuntimeLevelToKernel,
} from '../packages/runtime/dist/src/lean4-level.js';

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
const empty=emptyLean434MetavarContext();

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

{
  const u1=numName(strName(anonymous,'_u'),1n);
  const u2=numName(strName(anonymous,'_u'),2n);
  const lmvar1=lean434RuntimeLMVarId(u1);
  const lmvar2=lean434RuntimeLMVarId(u2);
  const succZero=kernelLevelToLean434Runtime(levelSucc(levelZero));
  const mvar2=kernelLevelToLean434Runtime(levelMVar(u2));

  const assignLevel=(mctx,lmvar,value)=>{
    let fn=evaluator.evaluate(
      constant(nameFromDotted('Lean.assignLevelMVarExp')),
    );
    fn=evaluator.applyRuntimeValue(fn,mctx);
    fn=evaluator.applyRuntimeValue(fn,lmvar);
    return evaluator.applyRuntimeValue(fn,value);
  };
  let levelMctx=assignLevel(empty,lmvar2,succZero);
  levelMctx=assignLevel(levelMctx,lmvar1,mvar2);

  const input=kernelLevelToLean434Runtime(
    levelMaxRaw(
      levelMVar(u1),
      levelSucc(levelMVar(u2)),
    ),
  );
  let instantiate=evaluator.evaluate(
    constant(nameFromDotted('Lean.instantiateLevelMVarsImp')),
  );
  instantiate=evaluator.applyRuntimeValue(instantiate,levelMctx);
  const result=evaluator.applyRuntimeValue(instantiate,input);
  if(
    result?.kind!=='constructor'
    ||result.name!=='Prod.mk'
    ||result.fields.length!==2
  ){
    throw new Error(
      'Lean.instantiateLevelMVarsImp did not return MetavarContext × Level',
    );
  }
  const normalized=lean434RuntimeLevelToKernel(result.fields[1]);
  const expected=levelMaxRaw(
    levelSucc(levelZero),
    levelSucc(levelSucc(levelZero)),
  );
  if(!levelEqStructural(normalized,expected)){
    throw new Error(
      'Lean.instantiateLevelMVarsImp returned the wrong normalized Level',
    );
  }

  let getLevel=evaluator.evaluate(
    constant(nameFromDotted('Lean.getLevelMVarAssignmentExp')),
  );
  getLevel=evaluator.applyRuntimeValue(getLevel,result.fields[0]);
  const u1Assignment=evaluator.applyRuntimeValue(getLevel,lmvar1);
  const u1Runtime=lean434RuntimeOptionValue(u1Assignment);
  if(
    u1Runtime===undefined
    ||!levelEqStructural(
      lean434RuntimeLevelToKernel(u1Runtime),
      levelSucc(levelZero),
    )
  ){
    throw new Error(
      'Lean.instantiateLevelMVarsImp did not write back normalized assignment',
    );
  }
  console.log(
    'ok - native Lean instantiateLevelMVarsImp normalizes and writes back in JS',
  );
}

{
  const mvarName1=numName(strName(anonymous,'_m'),8n);
  const mvarName2=numName(strName(anonymous,'_m'),9n);
  const mvarId1=lean434RuntimeMVarId(mvarName1);
  const mvarId2=lean434RuntimeMVarId(mvarName2);
  const mvarExpr2={
    kind:'constructor',
    name:'Lean.Expr.mvar',
    fields:[mvarId2],
  };
  const value=kernelExprToLean434Runtime(natLit(42n));

  let assign=evaluator.evaluate(
    constant(nameFromDotted('Lean.assignExp')),
  );
  assign=evaluator.applyRuntimeValue(assign,empty);
  assign=evaluator.applyRuntimeValue(assign,mvarId2);
  let chainMctx=evaluator.applyRuntimeValue(assign,value);

  assign=evaluator.evaluate(
    constant(nameFromDotted('Lean.assignExp')),
  );
  assign=evaluator.applyRuntimeValue(assign,chainMctx);
  assign=evaluator.applyRuntimeValue(assign,mvarId1);
  chainMctx=evaluator.applyRuntimeValue(assign,mvarExpr2);

  const target={
    kind:'constructor',
    name:'Lean.Expr.app',
    fields:[
      kernelExprToLean434Runtime(
        constant(nameFromDotted('Nat.succ')),
      ),
      {
        kind:'constructor',
        name:'Lean.Expr.mvar',
        fields:[mvarId1],
      },
    ],
  };

  let instantiate=evaluator.evaluate(
    constant(nameFromDotted('Lean.instantiateExprMVarsImp')),
  );
  instantiate=evaluator.applyRuntimeValue(instantiate,chainMctx);
  const result=evaluator.applyRuntimeValue(instantiate,target);
  if(
    result?.kind!=='constructor'
    ||result.name!=='Prod.mk'
    ||result.fields.length!==2
  ){
    throw new Error(
      'Lean.instantiateExprMVarsImp did not return MetavarContext × Expr',
    );
  }
  const normalized=lean434RuntimeExprToKernel(result.fields[1]);
  const expected=app(
    constant(nameFromDotted('Nat.succ')),
    natLit(42n),
  );
  if(!exprEq(normalized,expected)){
    throw new Error(
      'Lean.instantiateExprMVarsImp returned the wrong normalized Expr',
    );
  }

  let get=evaluator.evaluate(
    constant(nameFromDotted('Lean.MetavarContext.getExprAssignmentExp')),
  );
  get=evaluator.applyRuntimeValue(get,result.fields[0]);
  const mvar1Assignment=evaluator.applyRuntimeValue(get,mvarId1);
  const mvar1Runtime=lean434RuntimeOptionValue(mvar1Assignment);
  if(
    mvar1Runtime===undefined
    ||!exprEq(
      lean434RuntimeExprToKernel(mvar1Runtime),
      natLit(42n),
    )
  ){
    throw new Error(
      'Lean.instantiateExprMVarsImp did not write back normalized assignment',
    );
  }
  console.log(
    'ok - native Lean instantiateExprMVarsImp resolves direct mvar chains in JS',
  );

  {
    const betaName=numName(strName(anonymous,'_m'),10n);
    const betaId=lean434RuntimeMVarId(betaName);
    const betaValue=kernelExprToLean434Runtime(
      lam(
        nameFromDotted('x'),
        constant(nameFromDotted('Nat')),
        bvar(0),
      ),
    );
    let betaAssign=evaluator.evaluate(
      constant(nameFromDotted('Lean.assignExp')),
    );
    betaAssign=evaluator.applyRuntimeValue(betaAssign,empty);
    betaAssign=evaluator.applyRuntimeValue(betaAssign,betaId);
    const betaMctx=evaluator.applyRuntimeValue(betaAssign,betaValue);
    const betaTarget={
      kind:'constructor',
      name:'Lean.Expr.app',
      fields:[
        {
          kind:'constructor',
          name:'Lean.Expr.mvar',
          fields:[betaId],
        },
        kernelExprToLean434Runtime(natLit(42n)),
      ],
    };
    let betaInstantiate=evaluator.evaluate(
      constant(nameFromDotted('Lean.instantiateExprMVarsImp')),
    );
    betaInstantiate=evaluator.applyRuntimeValue(betaInstantiate,betaMctx);
    const betaResult=evaluator.applyRuntimeValue(
      betaInstantiate,
      betaTarget,
    );
    if(
      betaResult?.kind!=='constructor'
      ||betaResult.name!=='Prod.mk'
      ||betaResult.fields.length!==2
      ||!exprEq(
        lean434RuntimeExprToKernel(betaResult.fields[1]),
        natLit(42n),
      )
    ){
      throw new Error(
        'Lean.instantiateExprMVarsImp did not beta-reduce assigned mvar application',
      );
    }
    console.log(
      'ok - native Lean instantiateExprMVarsImp beta-reduces assigned mvar applications',
    );
  }

  {
    const zetaName=numName(strName(anonymous,'_m'),13n);
    const zetaId=lean434RuntimeMVarId(zetaName);
    const natType=constant(nameFromDotted('Nat'));
    const fnType=forallE(
      nameFromDotted('x'),
      natType,
      natType,
    );
    const letFunction={
      kind:'let',
      name:nameFromDotted('f'),
      type:fnType,
      value:lam(
        nameFromDotted('x'),
        natType,
        bvar(0),
      ),
      body:bvar(0),
      nondep:false,
    };

    let zetaAssign=evaluator.evaluate(
      constant(nameFromDotted('Lean.assignExp')),
    );
    zetaAssign=evaluator.applyRuntimeValue(zetaAssign,empty);
    zetaAssign=evaluator.applyRuntimeValue(zetaAssign,zetaId);
    const zetaMctx=evaluator.applyRuntimeValue(
      zetaAssign,
      kernelExprToLean434Runtime(letFunction),
    );
    const zetaTarget={
      kind:'constructor',
      name:'Lean.Expr.app',
      fields:[
        {
          kind:'constructor',
          name:'Lean.Expr.mvar',
          fields:[zetaId],
        },
        kernelExprToLean434Runtime(natLit(42n)),
      ],
    };

    let instantiateZeta=evaluator.evaluate(
      constant(nameFromDotted('Lean.instantiateExprMVarsImp')),
    );
    instantiateZeta=evaluator.applyRuntimeValue(
      instantiateZeta,
      zetaMctx,
    );
    const zetaResult=evaluator.applyRuntimeValue(
      instantiateZeta,
      zetaTarget,
    );
    if(
      zetaResult?.kind!=='constructor'
      ||zetaResult.name!=='Prod.mk'
      ||zetaResult.fields.length!==2
      ||!exprEq(
        lean434RuntimeExprToKernel(zetaResult.fields[1]),
        natLit(42n),
      )
    ){
      throw new Error(
        'Lean.instantiateExprMVarsImp did not zeta-reduce a let-bound assigned function',
      );
    }
    console.log(
      'ok - native Lean instantiateExprMVarsImp matches apply_beta zeta semantics',
    );
  }

  {
    const delayedName=numName(strName(anonymous,'_m'),11n);
    const pendingName=numName(strName(anonymous,'_m'),12n);
    const fvarName=numName(strName(anonymous,'_f'),1n);
    const delayedId=lean434RuntimeMVarId(delayedName);
    const pendingId=lean434RuntimeMVarId(pendingName);
    const runtimeFVar=kernelExprToLean434Runtime(
      fvar(nameKey(fvarName)),
    );

    let insertDelayed=evaluator.evaluate(
      constant(
        nameFromDotted(
          'ProofScript.RuntimeProbe.insertDelayedExprAssignment',
        ),
      ),
    );
    insertDelayed=evaluator.applyRuntimeValue(insertDelayed,empty);
    insertDelayed=evaluator.applyRuntimeValue(
      insertDelayed,
      delayedId,
    );
    insertDelayed=evaluator.applyRuntimeValue(
      insertDelayed,
      [runtimeFVar],
    );
    let delayedMctx=evaluator.applyRuntimeValue(
      insertDelayed,
      pendingId,
    );

    let assignPending=evaluator.evaluate(
      constant(nameFromDotted('Lean.assignExp')),
    );
    assignPending=evaluator.applyRuntimeValue(
      assignPending,
      delayedMctx,
    );
    assignPending=evaluator.applyRuntimeValue(
      assignPending,
      pendingId,
    );
    delayedMctx=evaluator.applyRuntimeValue(
      assignPending,
      runtimeFVar,
    );

    const delayedTarget={
      kind:'constructor',
      name:'Lean.Expr.app',
      fields:[
        {
          kind:'constructor',
          name:'Lean.Expr.mvar',
          fields:[delayedId],
        },
        kernelExprToLean434Runtime(natLit(42n)),
      ],
    };
    let instantiateDelayed=evaluator.evaluate(
      constant(nameFromDotted('Lean.instantiateExprMVarsImp')),
    );
    instantiateDelayed=evaluator.applyRuntimeValue(
      instantiateDelayed,
      delayedMctx,
    );
    const delayedResult=evaluator.applyRuntimeValue(
      instantiateDelayed,
      delayedTarget,
    );
    if(
      delayedResult?.kind!=='constructor'
      ||delayedResult.name!=='Prod.mk'
      ||delayedResult.fields.length!==2
      ||!exprEq(
        lean434RuntimeExprToKernel(delayedResult.fields[1]),
        natLit(42n),
      )
    ){
      throw new Error(
        'Lean.instantiateExprMVarsImp did not resolve delayed fvar substitution',
      );
    }
    console.log(
      'ok - native Lean instantiateExprMVarsImp resolves a delayed fvar assignment',
    );
  }

  {
    // Small source-derived nested-delayed case.  This exercises the same
    // substitution composition that Lean's instantiateMVarsShadow test relies
    // on, without pulling the whole MetaM test harness into this bootstrap
    // fixture:
    //
    //   ?inner [x] := Nat.succ x
    //   ?outer [x] := ?inner (Nat.succ x)
    //   ?outer 40  ==> Nat.succ (Nat.succ 40)
    const fvarName=numName(strName(anonymous,'_f'),2n);
    const runtimeFVar=kernelExprToLean434Runtime(
      fvar(nameKey(fvarName)),
    );
    const innerDelayedId=lean434RuntimeMVarId(
      numName(strName(anonymous,'_m'),14n),
    );
    const innerPendingId=lean434RuntimeMVarId(
      numName(strName(anonymous,'_m'),15n),
    );
    const outerDelayedId=lean434RuntimeMVarId(
      numName(strName(anonymous,'_m'),16n),
    );
    const outerPendingId=lean434RuntimeMVarId(
      numName(strName(anonymous,'_m'),17n),
    );

    const insertDelayed=(mctx,id,pending)=>{
      let fn=evaluator.evaluate(
        constant(
          nameFromDotted(
            'ProofScript.RuntimeProbe.insertDelayedExprAssignment',
          ),
        ),
      );
      fn=evaluator.applyRuntimeValue(fn,mctx);
      fn=evaluator.applyRuntimeValue(fn,id);
      fn=evaluator.applyRuntimeValue(fn,[runtimeFVar]);
      return evaluator.applyRuntimeValue(fn,pending);
    };
    const assignRuntime=(mctx,id,value)=>{
      let fn=evaluator.evaluate(
        constant(nameFromDotted('Lean.assignExp')),
      );
      fn=evaluator.applyRuntimeValue(fn,mctx);
      fn=evaluator.applyRuntimeValue(fn,id);
      return evaluator.applyRuntimeValue(fn,value);
    };

    let nestedMctx=insertDelayed(
      empty,
      innerDelayedId,
      innerPendingId,
    );
    nestedMctx=assignRuntime(
      nestedMctx,
      innerPendingId,
      {
        kind:'constructor',
        name:'Lean.Expr.app',
        fields:[
          kernelExprToLean434Runtime(
            constant(nameFromDotted('Nat.succ')),
          ),
          runtimeFVar,
        ],
      },
    );
    nestedMctx=insertDelayed(
      nestedMctx,
      outerDelayedId,
      outerPendingId,
    );
    const succFVar={
      kind:'constructor',
      name:'Lean.Expr.app',
      fields:[
        kernelExprToLean434Runtime(
          constant(nameFromDotted('Nat.succ')),
        ),
        runtimeFVar,
      ],
    };
    nestedMctx=assignRuntime(
      nestedMctx,
      outerPendingId,
      {
        kind:'constructor',
        name:'Lean.Expr.app',
        fields:[
          {
            kind:'constructor',
            name:'Lean.Expr.mvar',
            fields:[innerDelayedId],
          },
          succFVar,
        ],
      },
    );

    const nestedTarget={
      kind:'constructor',
      name:'Lean.Expr.app',
      fields:[
        {
          kind:'constructor',
          name:'Lean.Expr.mvar',
          fields:[outerDelayedId],
        },
        kernelExprToLean434Runtime(natLit(40n)),
      ],
    };
    let instantiateNested=evaluator.evaluate(
      constant(nameFromDotted('Lean.instantiateExprMVarsImp')),
    );
    instantiateNested=evaluator.applyRuntimeValue(
      instantiateNested,
      nestedMctx,
    );
    const nestedResult=evaluator.applyRuntimeValue(
      instantiateNested,
      nestedTarget,
    );
    const nestedExpected=app(
      constant(nameFromDotted('Nat.succ')),
      app(
        constant(nameFromDotted('Nat.succ')),
        natLit(40n),
      ),
    );
    if(
      nestedResult?.kind!=='constructor'
      ||nestedResult.name!=='Prod.mk'
      ||nestedResult.fields.length!==2
      ||!exprEq(
        lean434RuntimeExprToKernel(nestedResult.fields[1]),
        nestedExpected,
      )
    ){
      throw new Error(
        'Lean.instantiateExprMVarsImp did not compose nested delayed substitutions',
      );
    }
    console.log(
      'ok - native Lean instantiateExprMVarsImp composes nested delayed substitutions',
    );
  }

  const coreEvaluator=new Lean434Evaluator(
    replay.env,
    {maxSteps:250_000,metadata},
  );
  let core=coreEvaluator.evaluate(
    constant(nameFromDotted('Lean.instantiateMVarsCore')),
  );
  core=coreEvaluator.applyRuntimeValue(core,chainMctx);
  const coreResult=coreEvaluator.applyRuntimeValue(core,target);
  if(
    coreResult?.kind!=='constructor'
    ||coreResult.name!=='Prod.mk'
    ||coreResult.fields.length!==2
  ){
    throw new Error(
      'Lean.instantiateMVarsCore did not return Expr × MetavarContext',
    );
  }
  if(
    !exprEq(
      lean434RuntimeExprToKernel(coreResult.fields[0]),
      expected,
    )
  ){
    throw new Error(
      'real Lean instantiateMVarsCore returned the wrong normalized Expr',
    );
  }
  let getCore=coreEvaluator.evaluate(
    constant(nameFromDotted('Lean.MetavarContext.getExprAssignmentExp')),
  );
  getCore=coreEvaluator.applyRuntimeValue(getCore,coreResult.fields[1]);
  const coreAssignment=coreEvaluator.applyRuntimeValue(getCore,mvarId1);
  const coreRuntime=lean434RuntimeOptionValue(coreAssignment);
  if(
    coreRuntime===undefined
    ||!exprEq(
      lean434RuntimeExprToKernel(coreRuntime),
      natLit(42n),
    )
  ){
    throw new Error(
      'real Lean instantiateMVarsCore did not preserve normalized mctx state',
    );
  }
  console.log(
    'ok - real Lean instantiateMVarsCore executes through ST/StateRefT in JS',
  );
}

const mvarName=numName(strName(anonymous,'_m'),7n);
const mvarId=lean434RuntimeMVarId(mvarName);
const valueExpr=natLit(42n);
const runtimeExpr=kernelExprToLean434Runtime(valueExpr);
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
