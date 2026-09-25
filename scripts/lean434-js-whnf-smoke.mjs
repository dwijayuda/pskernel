import fs from 'node:fs';
import {
  Lean4ExportReplay,
  anonymous,
  app,
  bvar,
  constant,
  exprEq,
  lam,
  nameFromDotted,
  natLit,
  numName,
  strName,
} from '../dist/src/index.js';
import {
  Lean434Evaluator,
} from '../packages/runtime/dist/src/lean4-eval.js';
import {
  kernelExprToLean434Runtime,
  lean434RuntimeExprToKernel,
} from '../packages/runtime/dist/src/lean4-expr.js';
import {
  Lean434InitializerRunner,
} from '../packages/runtime/dist/src/lean4-init.js';
import {
  Lean434RuntimeMetadataIndex,
  parseLean434RuntimeMetadata,
} from '../packages/runtime/dist/src/lean4-metadata.js';
import {
  emptyLean434MetavarContext,
  lean434RuntimeMVarId,
  lean434RuntimeOptionValue,
} from '../packages/runtime/dist/src/lean4-mctx.js';

const fixture=process.argv[2]??'lean434-whnf-bootstrap.ndjson';
const metadataFixture=
  process.argv[3]??'lean434-whnf-runtime-metadata.json';
if(!fs.existsSync(fixture)){
  throw new Error('missing generated Lean.Meta.whnf fixture: '+fixture);
}
if(!fs.existsSync(metadataFixture)){
  throw new Error('missing Lean.Meta.whnf runtime metadata: '+metadataFixture);
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
  phase:'whnf-delta-replay-start',
  bytes:Buffer.byteLength(delta),
}));
const replayStats=replay.replay(delta,{
  every:500,
  onProgress:(stats)=>console.log(JSON.stringify({
    phase:'whnf-delta-replay-progress',
    ...stats,
  })),
});
console.log(JSON.stringify({
  phase:'whnf-delta-replay-complete',
  declarations:replayStats.declarations,
  environmentConstants:replay.env.size,
  bytes:Buffer.byteLength(delta),
}));

const document=parseLean434RuntimeMetadata(
  JSON.parse(fs.readFileSync(metadataFixture,'utf8')),
);
const importingRefEntry=document.initializers.find(
  (entry)=>entry.declaration.includes('ImportingFlag')
    &&entry.declaration.endsWith('.importingRef'),
);
const envRefEntry=document.initializers.find(
  (entry)=>entry.declaration.includes('EnvExtension.envExtensionsRef'),
);
if(!importingRefEntry||!envRefEntry){
  throw new Error(
    'Lean.Meta.whnf metadata is missing importingRef/envExtensionsRef initializers',
  );
}

const selectedInitializers=[importingRefEntry,envRefEntry];
const metadata=new Lean434RuntimeMetadataIndex({
  ...document,
  initializers:selectedInitializers,
});

const makeWhnfEvaluator=()=>{
  // Each WHNF scenario gets the same strict evaluator budget.  Re-running the
  // two foundational Environment initializers avoids coupling independent
  // semantic cases through accumulated interpreter steps.
  const evaluator=new Lean434Evaluator(
    replay.env,
    {metadata,maxSteps:250_000},
  );
  const runner=new Lean434InitializerRunner(evaluator,metadata);
  const init=runner.runAll();
  if(init.executed.length!==2||init.skipped.length!==0){
    throw new Error(
      'expected exactly importingRef/envExtensionsRef to initialize for WHNF',
    );
  }
  return evaluator;
};

const runWhnf=(expr)=>{
  const evaluator=makeWhnfEvaluator();

  let action=evaluator.evaluate(
    constant(
      nameFromDotted(
        'ProofScript.RuntimeProbe.whnfWithEmptyEnv',
      ),
    ),
  );
  action=evaluator.applyRuntimeValue(
    action,
    kernelExprToLean434Runtime(expr),
  );
  const result=evaluator.runIOAction(action).value;
  return lean434RuntimeExprToKernel(result);
};

{
  const x=nameFromDotted('x');
  const natType=constant(nameFromDotted('Nat'));
  const input={
    kind:'let',
    name:x,
    type:natType,
    value:natLit(7n),
    body:bvar(0),
    nondep:false,
  };
  const actual=runWhnf(input);
  if(!exprEq(actual,natLit(7n))){
    throw new Error(
      'real Lean.Meta.whnfImp did not zeta-reduce a closed let expression',
    );
  }
  console.log(
    'ok - real Lean.Meta.whnfImp zeta-reduces a closed let in JavaScript',
  );
}

{
  const x=nameFromDotted('x');
  const natType=constant(nameFromDotted('Nat'));
  const input=app(
    lam(x,natType,bvar(0)),
    natLit(9n),
  );
  const actual=runWhnf(input);
  if(!exprEq(actual,natLit(9n))){
    throw new Error(
      'real Lean.Meta.whnfImp did not beta-reduce a closed application',
    );
  }
  console.log(
    'ok - real Lean.Meta.whnfImp beta-reduces a closed application in JavaScript',
  );
}

{
  const input=app(
    app(
      constant(nameFromDotted('Nat.add')),
      natLit(20n),
    ),
    natLit(22n),
  );
  const actual=runWhnf(input);
  if(!exprEq(actual,natLit(42n))){
    throw new Error(
      'real Lean.Meta.whnfImp did not reduce closed Nat.add literals',
    );
  }
  console.log(
    'ok - real Lean.Meta.whnfImp executes reduceNat? for closed Nat.add in JavaScript',
  );
}

{
  const mvarName=numName(strName(anonymous,'_m'),21n);
  const mvarId=lean434RuntimeMVarId(mvarName);
  const assignedValue=kernelExprToLean434Runtime(natLit(33n));

  // Keep assignment construction under an independent strict budget.  The
  // resulting logical MetavarContext value is then passed to a fresh WHNF
  // evaluator, just as Lean threads MetaM state between operations.
  const assignmentEvaluator=new Lean434Evaluator(
    replay.env,
    {metadata,maxSteps:250_000},
  );
  let assign=assignmentEvaluator.evaluate(
    constant(nameFromDotted('Lean.assignExp')),
  );
  assign=assignmentEvaluator.applyRuntimeValue(
    assign,
    emptyLean434MetavarContext(),
  );
  assign=assignmentEvaluator.applyRuntimeValue(assign,mvarId);
  const assignedMctx=assignmentEvaluator.applyRuntimeValue(
    assign,
    assignedValue,
  );

  const evaluator=makeWhnfEvaluator();
  const runtimeMVar={
    kind:'constructor',
    name:'Lean.Expr.mvar',
    fields:[mvarId],
  };
  let action=evaluator.evaluate(
    constant(
      nameFromDotted(
        'ProofScript.RuntimeProbe.whnfWithEmptyEnvAndMCtx',
      ),
    ),
  );
  action=evaluator.applyRuntimeValue(action,assignedMctx);
  action=evaluator.applyRuntimeValue(action,runtimeMVar);
  const result=evaluator.runIOAction(action).value;
  if(
    result?.kind!=='constructor'
    ||result.name!=='Prod.mk'
    ||result.fields.length!==2
  ){
    throw new Error(
      'real Lean.Meta.whnfImp mctx probe did not return Expr × MetavarContext',
    );
  }
  if(
    !exprEq(
      lean434RuntimeExprToKernel(result.fields[0]),
      natLit(33n),
    )
  ){
    throw new Error(
      'real Lean.Meta.whnfImp did not resolve an assigned expression metavariable',
    );
  }

  let getAssignment=evaluator.evaluate(
    constant(nameFromDotted('Lean.MetavarContext.getExprAssignmentExp')),
  );
  getAssignment=evaluator.applyRuntimeValue(
    getAssignment,
    result.fields[1],
  );
  const stored=evaluator.applyRuntimeValue(getAssignment,mvarId);
  const storedRuntime=lean434RuntimeOptionValue(stored);
  if(
    storedRuntime===undefined
    ||!exprEq(
      lean434RuntimeExprToKernel(storedRuntime),
      natLit(33n),
    )
  ){
    throw new Error(
      'real Lean.Meta.whnfImp did not preserve the threaded MetavarContext',
    );
  }
  console.log(
    'ok - real Lean.Meta.whnfImp resolves assigned mvars and preserves MetaM state in JavaScript',
  );
}
